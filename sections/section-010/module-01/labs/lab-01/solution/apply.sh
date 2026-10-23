#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays in its starting state.
# Taken from solution.md - if one changes, change the other.
set -euo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

# --- shared helpers (generated; identical in every ATS104 script) ---------
NS_WS="workstation"
HARBOR_URL="https://harbor.localtest.me:8443"
HARBOR_REGISTRY="harbor.localtest.me:8443"
ADMIN_USER="admin"
# Lab-only administrator password (the chart default).
ADMIN_PASSWORD="Harbor12345"

# ws COMMAND...: runs a command in the workstation pod.
# -c workstation: the pod also has the init container install-tools, and
# without -c kubectl adds "Defaulted container ..." to stderr.
ws() { kubectl -n "$NS_WS" exec -i -c workstation deploy/workstation -- "$@"; }
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
# (for example robot$ci+builder), or nothing. Without a query, GET /robots
# lists only system robots; a project robot needs Level=project and the
# project's ID.
robot_by_name() {
  local project q=""
  case "$1" in
    'robot$'*+*)
      project="${1#robot\$}"; project="${project%%+*}"
      q="&q=Level%3Dproject%2CProjectID%3D$(api GET "/projects/$project" | ws jq -r '.project_id')" ;;
  esac
  api GET "/robots?page_size=100$q" | ws jq -c --arg n "$1" '.[] | select(.name == $n)'
}
# --------------------------------------------------------------------------

ws sh -c 'cat > /work/onboard.sh' <<'SCRIPT'
#!/bin/sh
# onboard.sh PROJECT USERNAME EMAIL
# Creates a private project, a local user and a Developer membership, each
# only if it does not exist yet, so the script can run again safely.
# The new user's password comes from the variable ONBOARD_PASSWORD.
set -eu
project="$1"
username="$2"
email="$3"
: "${ONBOARD_PASSWORD:?set ONBOARD_PASSWORD to the password for the new user}"

if harbor project view "$project" -o json </dev/null >/dev/null 2>&1; then
  echo "project $project exists"
else
  harbor project create "$project" --storage-limit -1 </dev/null
  echo "project $project created"
fi

if harbor user list --page-size 0 -o json </dev/null \
    | jq -e --arg u "$username" '[.. | objects | select(.username? == $u)] | length > 0' >/dev/null; then
  echo "user $username exists"
else
  harbor user create --username "$username" --email "$email" --realname "$username" \
    --password "$ONBOARD_PASSWORD" </dev/null
  echo "user $username created"
fi

if harbor project member list "$project" --page-size 100 -o json </dev/null \
    | jq -e --arg u "$username" '[.. | objects | select(.entity_name? == $u)] | length > 0' >/dev/null; then
  echo "$username is already a member of $project"
else
  harbor project member create "$project" --username "$username" --roleid 1 </dev/null
  echo "$username added to $project as Developer"
fi
SCRIPT
ws sh -c 'ONBOARD_PASSWORD=Blue-Team-2026 sh /work/onboard.sh team-blue blue-dev blue-dev@example.com </dev/null'
