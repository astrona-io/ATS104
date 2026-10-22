#!/usr/bin/env bash
# Creates the starting state for ats-104-capstone-020: Pushes tagged and untagged artifacts into inventory and archive, and writes the broken /work/cleanup.py.
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

echo "[seed] Pushing twelve builds of inventory/app:latest; only the last keeps the tag..."
create_project inventory
for n in 01 02 03 04 05 06 07 08 09 10 11 12; do
  push_note "inventory/app:latest" "app build $n"
done
push_note "inventory/app:v1" "app release 1"
push_note "inventory/app:v2" "app release 2"
push_note "inventory/docs:latest" "docs build 1"
push_note "inventory/docs:latest" "docs build 2"
create_project archive
push_note "archive/old:latest" "old build 1"
push_note "archive/old:latest" "old build 2"
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
import urllib.request

HARBOR_URL = os.environ["HARBOR_URL"].rstrip("/")
AUTH = "Basic " + base64.b64encode(
    f'{os.environ["HARBOR_USERNAME"]}:{os.environ["HARBOR_PASSWORD"]}'.encode()
).decode()
TLS = ssl._create_unverified_context()


def call(method, path):
    request = urllib.request.Request(
        f"{HARBOR_URL}/api/v2.0{path}", method=method,
        headers={"Authorization": AUTH, "Accept": "application/json"},
    )
    with urllib.request.urlopen(request, context=TLS) as response:
        body = response.read()
        return json.loads(body) if body else None


def main():
    project = sys.argv[1]
    print(f"cleaning {project}")
    for each_project in call("GET", "/projects"):
        name = each_project["name"]
        for repository in call("GET", f"/projects/{name}/repositories"):
            repository_name = repository["name"].split("/", 1)[1]
            artifacts = call("GET", f"/projects/{name}/repositories/{repository_name}/artifacts?with_tag=true")
            for artifact in artifacts:
                if artifact.get("tags") == []:
                    call("DELETE", f"/projects/{name}/repositories/{repository_name}/artifacts/{artifact['digest']}")
                    print(f"deleted {name}/{repository_name}@{artifact['digest']}")


if __name__ == "__main__":
    main()
SCRIPT

echo "[lab] Starting state ready."
