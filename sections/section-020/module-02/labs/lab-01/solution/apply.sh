#!/usr/bin/env bash
# Reference solution for ats-104-lab-020-02; used by `astrona test`, never shown to the learner.
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

py sh -c 'cat > /work/tag_artifact.py' <<'SCRIPT'
"""tag_artifact.py PROJECT REPOSITORY REFERENCE TAG

Adds TAG to the artifact that REFERENCE (a tag or a digest) points to, unless it
already has the tag, and prints a JSON report. Standard library only. Reads
HARBOR_URL, HARBOR_USERNAME, HARBOR_PASSWORD and HARBOR_CA from the environment.
"""
import base64
import json
import os
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request

HARBOR_URL = os.environ["HARBOR_URL"].rstrip("/")
AUTH = "Basic " + base64.b64encode(
    f'{os.environ["HARBOR_USERNAME"]}:{os.environ["HARBOR_PASSWORD"]}'.encode()
).decode()
TLS = ssl.create_default_context(cafile=os.environ.get("HARBOR_CA"))


def encode(value):
    """Encodes a repository name that may contain a slash twice, as Harbor asks."""
    return urllib.parse.quote(urllib.parse.quote(value, safe=""), safe="")


def call(method, path, body=None):
    data = None if body is None else json.dumps(body).encode()
    headers = {"Authorization": AUTH, "Accept": "application/json"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(f"{HARBOR_URL}/api/v2.0{path}", data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request, context=TLS) as response:
            raw = response.read()
            return response.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        return error.code, error.read().decode()


def main():
    project, repository, reference, tag = sys.argv[1:5]
    base = f"/projects/{urllib.parse.quote(project, safe='')}/repositories/{encode(repository)}/artifacts"
    status, artifact = call("GET", f"{base}/{urllib.parse.quote(reference, safe='')}?with_tag=true")
    if status != 200:
        sys.exit(f"cannot read the artifact: HTTP {status} {artifact}")
    names = [t["name"] for t in artifact.get("tags") or []]
    if tag not in names:
        status, body = call("POST", f"{base}/{artifact['digest']}/tags", {"name": tag})
        if status != 201:
            sys.exit(f"cannot create the tag: HTTP {status} {body}")
        names.append(tag)
    print(json.dumps({"repository": repository, "digest": artifact["digest"], "tags": sorted(names)}, indent=2))


if __name__ == "__main__":
    main()
SCRIPT
py python3 /work/tag_artifact.py inventory web/frontend v1 release
py python3 /work/tag_artifact.py inventory web/frontend v1 release
