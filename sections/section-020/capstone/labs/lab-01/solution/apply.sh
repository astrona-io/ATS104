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
# (for example robot$ci+builder), or nothing.
robot_by_name() {
  api GET "/robots?page_size=100" | ws jq -c --arg n "$1" '.[] | select(.name == $n)'
}
# --------------------------------------------------------------------------

py sh -c 'cat > /work/cleanup.py' <<'SCRIPT'
"""cleanup.py PROJECT: deletes every untagged artifact in one Harbor project.

Standard library only. Reads HARBOR_URL, HARBOR_USERNAME, HARBOR_PASSWORD and
HARBOR_CA from the environment.
"""
import base64
import json
import os
import ssl
import sys
import urllib.parse
import urllib.request

HARBOR_URL = os.environ["HARBOR_URL"].rstrip("/")
AUTH = "Basic " + base64.b64encode(
    f'{os.environ["HARBOR_USERNAME"]}:{os.environ["HARBOR_PASSWORD"]}'.encode()
).decode()
TLS = ssl.create_default_context(cafile=os.environ.get("HARBOR_CA"))


def call(method, path):
    request = urllib.request.Request(
        f"{HARBOR_URL}/api/v2.0{path}", method=method,
        headers={"Authorization": AUTH, "Accept": "application/json"},
    )
    with urllib.request.urlopen(request, context=TLS) as response:
        body = response.read()
        return response.headers, (json.loads(body) if body else None)


def get_all(path, extra=""):
    """Returns every item of a list endpoint, one page at a time."""
    items, page = [], 1
    while True:
        headers, batch = call("GET", f"{path}?page={page}&page_size=10{extra}")
        items.extend(batch)
        total = int(headers.get("X-Total-Count", len(items)))
        if not batch or len(items) >= total:
            return items
        page += 1


def main():
    project = sys.argv[1]
    print(f"cleaning {project}")
    for repository in get_all(f"/projects/{urllib.parse.quote(project)}/repositories"):
        repository_name = repository["name"].split("/", 1)[1]
        # A repository name with a slash must be URL-encoded twice in the path.
        encoded = urllib.parse.quote(urllib.parse.quote(repository_name, safe=""), safe="")
        path = f"/projects/{urllib.parse.quote(project)}/repositories/{encoded}/artifacts"
        # Collect first, delete after: deleting while paging shifts the pages.
        untagged = [a for a in get_all(path, "&with_tag=true") if not a.get("tags")]
        for artifact in untagged:
            call("DELETE", f"{path}/{artifact['digest']}")
            print(f"deleted {project}/{repository_name}@{artifact['digest']}")


if __name__ == "__main__":
    main()
SCRIPT
py python3 /work/cleanup.py inventory
