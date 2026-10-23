#!/usr/bin/env bash
# Runs the script twice the way CI does (no terminal, stdin from /dev/null, no
# administrator password) after making another context current, and checks
# that both runs succeed and that the script left the context ci current.
# Prints PASS or FAIL with the reason, and exits 0 only on PASS.
set -uo pipefail
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

# Make the bootstrap's context admin current, so the runs only pass when the
# script selects its own context.
if ! ws harbor context switch admin </dev/null >/dev/null 2>&1; then
  echo "FAIL: could not make the context admin current in the workstation pod."; exit 1
fi
for run in 1 2; do
  # kubectl exec -i without -t gives the pod no terminal; HARBOR_PASSWORD is
  # unset on purpose, because the script must not need it.
  if ! OUT="$(ws sh -c 'unset HARBOR_PASSWORD; ONBOARD_PASSWORD=Team-Pass-2026 timeout 300 sh /work/onboard-teams.sh </dev/null' </dev/null 2>&1)"; then
    echo "FAIL: run $run of onboard-teams.sh failed:"; echo "$OUT"; exit 1
  fi
done
CURRENT="$(ws harbor context list -o json </dev/null \
  | ws jq -r '.CurrentCredentialName // ."current-credential-name" // empty' 2>/dev/null)"
if [ "$CURRENT" != "ci" ]; then
  echo "FAIL: after the runs the current context is '$CURRENT', not 'ci'; the script must run 'harbor context switch ci'."; exit 1
fi
echo "PASS: two runs without a terminal and without a password both succeed, using the context ci."
