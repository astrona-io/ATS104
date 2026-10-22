# Solution: Report Every Repository In A Project

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the script keeps TLS verification on and holds no password, its report for `inventory` matches the API repository by repository, and its report for `archive` lists two repositories.

## Step 1: See why the first attempt counted ten

Define the helpers and ask for the repositories the way the first attempt did:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
ws sh -c 'curl -s -D - -o /dev/null -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/repositories" | grep -iE "^(x-total-count|link):"'
```

`X-Total-Count` is `12`, and `Link` points to a second page. The body of that request held only ten repositories, the default page size. The script must read every page.

## Step 2: Find the fields the report needs

Look at one repository object:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/repositories?page_size=1" | jq ".[0]"'
```

Each repository object has `name` (with the project prefix, for example `inventory/notes-01`) and `artifact_count`. The report needs nothing else, so one paged list of repositories is enough; there is no need to list each repository's artifacts.

## Step 3: Write the script

Save this as `report.py` on your machine:

```python
"""report.py PROJECT: prints a JSON report of every repository in a project.

Standard library only. Reads HARBOR_URL, HARBOR_USERNAME, HARBOR_PASSWORD and
HARBOR_CA (the CA file that signed Harbor's certificate) from the environment.
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


def get_all(path, page_size=10):
    """Returns every item of a list endpoint, one page at a time."""
    items, page = [], 1
    while True:
        query = urllib.parse.urlencode({"page": page, "page_size": page_size})
        request = urllib.request.Request(
            f"{HARBOR_URL}/api/v2.0{path}?{query}",
            headers={"Authorization": AUTH, "Accept": "application/json"},
        )
        with urllib.request.urlopen(request, context=TLS) as response:
            batch = json.load(response)
            total = int(response.headers.get("X-Total-Count", len(batch)))
        items.extend(batch)
        if not batch or len(items) >= total:
            return items
        page += 1


def main():
    project = sys.argv[1]
    repositories = get_all(f"/projects/{urllib.parse.quote(project)}/repositories")
    rows = sorted(
        ({"name": r["name"], "artifact_count": r["artifact_count"]} for r in repositories),
        key=lambda row: row["name"],
    )
    report = {
        "project": project,
        "repository_count": len(rows),
        "artifact_count": sum(row["artifact_count"] for row in rows),
        "repositories": rows,
    }
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
```

`get_all` reads page after page until it holds `X-Total-Count` items or gets an empty page. `TLS` verifies Harbor's certificate against the CA in `HARBOR_CA`. The credentials come from the environment, and `urllib` raises an error for any failed request, so a wrong password stops the script instead of printing an empty report.

Copy it into the pod and run it for both projects:

```sh
py sh -c 'cat > /work/report.py' < report.py
py python3 /work/report.py inventory
py python3 /work/report.py archive
```

The report for `inventory` has `repository_count` `12` and `artifact_count` `13`: twelve repositories with one artifact each, except `notes-03`, which has two. The report for `archive` lists its two repositories.

## Step 4: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set `page_size=100` and make one request | It works for twelve repositories and breaks silently at a hundred and one |
| `ssl._create_unverified_context()` to avoid the certificate error | The grader rejects it; the script would send the password to any server that answers |
| Count artifacts by listing each repository's artifacts | It works, but it costs one more paged list per repository; `artifact_count` is already in the repository object |
| Hard-code `admin:Harbor12345` | The grader rejects it; the pipeline must inject credentials |

## Common mistakes

- Forgetting to sort the `repositories` list by `name`.
- Stripping the project prefix from `name`; the task keeps it (`inventory/notes-01`).
- Reading `X-Total-Count` from the first response only and never asking for page `2`.
