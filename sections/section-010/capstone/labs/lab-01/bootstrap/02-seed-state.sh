#!/usr/bin/env bash
# Creates the starting state for ats-104-capstone-010: Creates team-red and red-dev, and writes /work/teams.csv and the broken /work/onboard-teams.sh.
#
# The fixed state is NOT created here; producing it is the task.
set -euo pipefail

# --- shared helpers (generated; identical in every ATS104 script) ---------
NS_WS="workstation"
HARBOR_URL="https://harbor.localtest.me:8443"
HARBOR_REGISTRY="harbor.localtest.me:8443"
ADMIN_USER="admin"
# Lab-only administrator password (the chart default).
ADMIN_PASSWORD="Harbor12345"

# ws COMMAND...: runs a command in the workstation pod.
ws() { kubectl -n "$NS_WS" exec -i deploy/workstation -- "$@"; }
# py COMMAND...: runs a command in the python-runner pod.
py() { kubectl -n "$NS_WS" exec -i deploy/python-runner -- "$@"; }

# api METHOD PATH [JSON]: calls the Harbor REST API as the administrator
# from the workstation and prints the response body. Fails on HTTP errors.
api() {
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | ws curl -fsS -u "$ADMIN_USER:$ADMIN_PASSWORD" -X "$method" \
      -H 'Content-Type: application/json' --data-binary @- "$HARBOR_URL/api/v2.0$path"
  else
    ws curl -fsS -u "$ADMIN_USER:$ADMIN_PASSWORD" -X "$method" "$HARBOR_URL/api/v2.0$path"
  fi
}

# api_status METHOD PATH: prints only the HTTP status code of an admin call.
api_status() {
  ws curl -s -o /dev/null -w '%{http_code}' -u "$ADMIN_USER:$ADMIN_PASSWORD" -X "$1" "$HARBOR_URL/api/v2.0$2"
}

# push_note REPOSITORY:TAG CONTENT: pushes a tiny OCI artifact (one text
# file) as the administrator with oras. Different CONTENT gives a different digest.
push_note() {
  ws sh -c "mkdir -p /tmp/push && cd /tmp/push && printf '%s\n' '$2' > note.txt && \
    oras push --artifact-type application/vnd.astrona.note.v1 '$HARBOR_REGISTRY/$1' note.txt:text/plain >/dev/null"
}

# create_project NAME [public]: creates a project if it does not exist.
create_project() {
  local public="${2:-false}"
  [ "$(api_status HEAD "/projects?project_name=$1")" = "200" ] && return 0
  api POST /projects "{\"project_name\":\"$1\",\"metadata\":{\"public\":\"$public\"}}" >/dev/null
}

# create_user NAME PASSWORD: creates a local Harbor user if it does not exist.
create_user() {
  if api GET "/users?q=username%3D$1" | grep -q "\"username\":\"$1\""; then return 0; fi
  api POST /users "{\"username\":\"$1\",\"email\":\"$1@example.com\",\"realname\":\"$1\",\"password\":\"$2\"}" >/dev/null
}

# robot_by_name FULL_NAME: prints the JSON of the robot with that full name
# (for example robot$ci+builder), or nothing.
robot_by_name() {
  api GET "/robots?page_size=100" | ws jq -c --arg n "$1" '.[] | select(.name == $n)'
}
# --------------------------------------------------------------------------

create_project team-red
create_user red-dev Red-Team-2026
api POST /projects/team-red/members '{"role_id":2,"member_user":{"username":"red-dev"}}' >/dev/null 2>&1 || true
ws sh -c 'cat > /work/teams.csv' <<'CSV'
team-red,red-dev,red-dev@example.com
team-green,green-dev,green-dev@example.com
team-gold,gold-dev,gold-dev@example.com
CSV
ws sh -c 'cat > /work/onboard-teams.sh' <<'SCRIPT'
#!/bin/sh
# onboard-teams.sh: onboards every team listed in /work/teams.csv
# (project,username,email). The CI job runs it with no terminal attached.
set -eu
harbor login https://harbor.localtest.me:8443 -u admin -p Harbor12345 -n ci
while IFS=, read -r project username email; do
  harbor project create "$project" --public
  harbor user create --username "$username" --email "$email" --realname "$username" --password "$ONBOARD_PASSWORD"
  harbor project member create "$project" --role Developers
done < /work/teams.csv
SCRIPT

echo "[lab] Starting state ready."
