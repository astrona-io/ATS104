# Solution: Tag An Artifact With Python

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the script keeps TLS verification on and holds no password, a run for `web/frontend` adds the tag, a second run succeeds, and a run for `web/backend` prints the right report. Each check runs the script in the python-runner pod with a time limit.

## Step 1: Look at the starting state

Define the helpers and read the repositories of `inventory`:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/repositories" | jq -r ".[].name"'
```

The names are `inventory/web/backend` and `inventory/web/frontend`. In the API path, the repository name is written without the project: `web/backend`.

## Step 2: Find out why the path fails

Ask for the artifacts with the slash as it is, and then with the slash encoded twice:

```sh
ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/repositories/web/backend/artifacts"'
ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/repositories/web%252Fbackend/artifacts"'
```

The first answers `404`, because the extra slash makes it a different path. The second answers `200`. Harbor wants the slash encoded twice: once to `%2F`, and then the percent sign itself to `%25`, which gives `%252F`.

## Step 3: Plan the script

| Need | How |
| --- | --- |
| Read the artifact | `GET /projects/{project}/repositories/{repository}/artifacts/{reference}?with_tag=true` |
| Check the tags | Compare the exact `name` of each item in `tags` with the new tag |
| Add the tag | `POST .../artifacts/{digest}/tags` with `{"name": "<tag>"}`; `201` means created |
| Encode the repository | `urllib.parse.quote(urllib.parse.quote(name, safe=""), safe="")` |
| Keep TLS on | `ssl.create_default_context(cafile=os.environ["HARBOR_CA"])` |

The script adds the tag only when it is missing, so a second run sends no `POST`. It posts to the digest, so the artifact cannot change between the read and the write.

## Step 4: Write the script

Write the file with the pattern from the first module of this section: a `call` function that does not raise on an HTTP error but returns the status and the body, and a `main` function that stops with a message on any status it did not expect.

```sh
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
```

The script reads the artifact first with `with_tag=true`, compares the exact tag names, and posts only when the tag is missing. It exits with a message on any status it did not expect, so a wrong password or a wrong repository name stops it at once.

## Step 5: Run it twice

```sh
py python3 /work/tag_artifact.py inventory web/frontend v1 release
py python3 /work/tag_artifact.py inventory web/frontend v1 release
```

Both runs print the same JSON, with the tags `release` and `v1`.

## Step 6: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Encode the repository name once | The path contains `%2F`, which many proxies decode before Harbor sees it, and Harbor answers `404` |
| Post the tag and accept every error | A `401` from a wrong password or a `404` from a wrong repository looks like success |
| Turn off TLS verification | The grader rejects `CERT_NONE` and unverified contexts |
| Print a fixed list of tags | The report must show the real tags of the artifact |

## Common mistakes

- Using `web/frontend` or `inventory/web/frontend` in the path instead of `web%252Ffrontend`.
- Treating `409` on the tag as a failure, or as success without checking which tag exists.
- Writing `HARBOR_PASSWORD` into the file instead of reading it.

## Practice on your own

- Accept a list of tags and add each one that is missing.
- Add a `--remove` option that deletes a tag with `DELETE .../tags/{tag_name}` when the artifact has it.
