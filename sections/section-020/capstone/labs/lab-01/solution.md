# Solution: Remove Untagged Artifacts Through The API

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the script keeps TLS verification on and holds no password, `inventory` has no untagged artifacts while every tag survives, `archive/old` still has two artifacts, and a second run succeeds.

## Step 1: Look at the data the script works on

Define the helpers and look at one repository's artifacts with their tags:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
ws sh -c 'curl -s -D - -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/repositories/app/artifacts?with_tag=true" -o /tmp/page1.json | grep -i "^x-total-count:"; jq -c ".[] | {digest: .digest[0:19], tags: .tags}" /tmp/page1.json'
```

`X-Total-Count` is `14`: twelve builds of `latest`, plus `v1` and `v2`. The first page shows ten artifacts. The tagged ones have a `tags` list with one entry. The untagged ones have `tags` set to `null`, not to an empty list.

## Step 2: Read the script and list every fault

```sh
py cat /work/cleanup.py
```

| Code | Fault | Effect |
| --- | --- | --- |
| `ssl._create_unverified_context()` | TLS verification off | The credentials go to any server that answers |
| `for each_project in call("GET", "/projects")` | Ignores its argument | Once the tag test is fixed, it would also delete the untagged builds in `archive` |
| `call("GET", ...artifacts?with_tag=true)` | First page only | `app` has fourteen artifacts; four are never seen |
| `if artifact.get("tags") == []` | Wrong test for "untagged" | Harbor sends `null`, so the test is never true and nothing is deleted |

The tag test hides the other faults: as long as it never matches, the script cannot delete anything, so it looks harmless. Fixing only that line would delete untagged artifacts in `archive` too.

## Step 3: Fix the script

Save this as `cleanup.py` on your machine:

```python
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
```

Each fault has its fix. `TLS` trusts the CA in `HARBOR_CA`. The loop works only on the project from the argument. `get_all` reads every page with `X-Total-Count`. `not a.get("tags")` is true for both `null` and an empty list. The script collects the untagged artifacts of a repository first and deletes them afterwards. Deleting while paging would shift the later pages, and the script would skip artifacts. The repository name in the path is encoded twice, as Harbor requires for names with a slash.

Copy it into the pod and run it:

```sh
py sh -c 'cat > /work/cleanup.py' < cleanup.py
py python3 /work/cleanup.py inventory
```

The script prints one `deleted` line for each untagged artifact: eleven in `app` and one in `docs`.

## Step 4: Check the result

```sh
ws sh -c 'for r in app docs; do curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/repositories/$r/artifacts?with_tag=true&page_size=100" | jq -c --arg r "$r" "{repository: \$r, artifacts: length, tags: [.[].tags[]?.name]}"; done'
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/archive/repositories/old/artifacts" | jq length'
```

`app` has three artifacts, tagged `latest`, `v1` and `v2`, and `docs` has one, tagged `latest`. `archive/old` still has two. Run the script once more: it prints `cleaning inventory` and deletes nothing.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Fix only the tag test | The script then deletes the untagged builds in `archive` too |
| Delete while paging | Every deletion shifts the later pages, so some artifacts are skipped |
| Delete by tag instead of digest | Untagged artifacts have no tag; only the digest names them |
| Keep the unverified context because "it is only a lab" | The grader rejects it, and in a pipeline it leaks the credentials |

## Common mistakes

- Using `== []` or `is None` instead of `not tags`, so one of the two forms is missed.
- Forgetting `with_tag=true`, so the `tags` field is missing and every artifact looks untagged.
- Running the script for every project "to be thorough".
