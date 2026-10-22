#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays in its starting state.
# Taken from solution.md - if one changes, change the other.
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

ws sh -c 'cat > /work/onboard-teams.sh' <<'SCRIPT'
#!/bin/sh
# onboard-teams.sh: onboards every team listed in /work/teams.csv
# (project,username,email). The CI job runs it with no terminal attached.
# HARBOR_PASSWORD is the administrator password, ONBOARD_PASSWORD the
# password for new users. Safe to run again: it creates only what is missing.
set -eu
: "${HARBOR_PASSWORD:?set HARBOR_PASSWORD}"
: "${ONBOARD_PASSWORD:?set ONBOARD_PASSWORD}"

printf '%s' "$HARBOR_PASSWORD" \
  | harbor login https://harbor.localtest.me:8443 -u admin --password-stdin -n ci >/dev/null 2>&1 \
  || harbor context switch ci </dev/null >/dev/null

# The CSV is read on file descriptor 3, and every harbor command reads
# /dev/null, so no command can swallow the lines that are still to come.
while IFS=, read -r project username email <&3; do
  [ -n "$project" ] || continue
  if ! harbor project view "$project" </dev/null >/dev/null 2>&1; then
    harbor project create "$project" </dev/null
  fi
  if ! harbor user list --page-size 0 -o json </dev/null \
      | jq -e --arg u "$username" '[.. | objects | select(.username? == $u)] | length > 0' >/dev/null; then
    harbor user create --username "$username" --email "$email" --realname "$username" \
      --password "$ONBOARD_PASSWORD" </dev/null
  fi
  if ! harbor project member list "$project" --page-size 100 -o json </dev/null \
      | jq -e --arg u "$username" '[.. | objects | select(.entity_name? == $u)] | length > 0' >/dev/null; then
    harbor project member create "$project" --username "$username" --role Developer </dev/null
  fi
  echo "onboarded $project"
done 3< /work/teams.csv
SCRIPT
ws sh -c 'HARBOR_PASSWORD=Harbor12345 ONBOARD_PASSWORD=Team-Pass-2026 sh /work/onboard-teams.sh </dev/null'
