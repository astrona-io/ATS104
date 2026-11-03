# A Python Script With The Standard Library

`curl` is fine for one request. A report that pages through several lists, combines them and prints a result belongs in a script, and many CI runners have Python but no permission to install packages. This part writes a Python script that uses only the standard library, authenticates with every request, keeps TLS verification on, and reads every page of a list.

## What the script needs from its environment

A script that talks to Harbor needs four values: Harbor's address, a user name, a password, and the certificate authority (CA) file that signed Harbor's certificate. None of them belongs in the script. The python-runner pod gets them as environment variables: `HARBOR_URL`, `HARBOR_USERNAME` and `HARBOR_PASSWORD` from the Kubernetes Secret `harbor-api`, and `HARBOR_CA`, the path of the CA file that the ConfigMap `harbor-ca` mounts into the pod. Check that they are set, without printing the password:

<!-- astrona:playground:renew -->

```sh
py sh -c 'echo "$HARBOR_URL as $HARBOR_USERNAME, CA file $HARBOR_CA"; head -1 "$HARBOR_CA"'
```

The output shows Harbor's address, the user `admin`, the path `/etc/harbor-ca/ca.crt`, and the first line of that file, `-----BEGIN CERTIFICATE-----`.

## Trusting the CA instead of turning verification off

Python's `ssl` module verifies every HTTPS certificate against a list of trusted CAs. Harbor's certificate in this lab is signed by its own CA, which Python does not know. There are two ways to make the request work, and only one is right:

| Approach | What it does |
| --- | --- |
| `ssl.create_default_context(cafile=os.environ["HARBOR_CA"])` | Verifies Harbor's certificate against Harbor's CA. A wrong server or a forged certificate still fails |
| `ssl._create_unverified_context()` | Accepts any certificate from any server. The password goes to whoever answers |

The second one makes the error go away by removing the check. In a pipeline, that sends the administrator password to any machine that can intercept the connection. Always pass the CA.

## The paging loop

The loop from the previous pages becomes a function. It asks for page `1`, adds the items, reads `X-Total-Count` from the response headers, and asks for the next page until it holds that many items. An empty page also ends the loop, so a list that shrinks while the script runs cannot make it loop forever.

## The script

The script below lists every project with the number of repositories it holds. The project objects from `GET /api/v2.0/projects` have the fields `name` and `repo_count`.

Save this as `projects.py` on your machine:

```python
"""projects.py: prints every Harbor project and its repository count as JSON.

Standard library only. Reads HARBOR_URL, HARBOR_USERNAME, HARBOR_PASSWORD and
HARBOR_CA (the CA file that signed Harbor's certificate) from the environment.
"""
import base64
import json
import os
import ssl
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


projects = get_all("/projects", page_size=2)
print(json.dumps(
    [{"name": p["name"], "repo_count": p.get("repo_count", 0)} for p in projects],
    indent=2,
))
```

`base64` builds the basic authentication header once, and every request sends it. `urllib.request.urlopen` raises an `HTTPError` for any status of `400` or higher, so a wrong password stops the script with a clear error instead of an empty report. The script asks for pages of two projects on purpose, so the loop has to work even with only three projects.

Copy the script into the python-runner pod and run it:

```sh
py sh -c 'cat > /work/projects.py' < projects.py
py python3 /work/projects.py
```

The output is a JSON list of three projects: `archive` with `2` repositories, `inventory` with `12`, and `library` with `0`. With a page size of two, the script needed two requests, and the second one returned the last project.

Now see the check you kept. Run the same script with a CA file that did not sign Harbor's certificate, the system's own list:

```sh
py sh -c 'HARBOR_CA=/etc/ssl/certs/ca-certificates.crt python3 /work/projects.py'
```

The script stops with an `ssl.SSLCertVerificationError` that says the certificate could not be verified. That is the error you want to see when a certificate is wrong; with an unverified context, the script would have sent the password anyway.

You can now write a Python script that authenticates, verifies Harbor's certificate, and reads every page of a list. The same function works for any list endpoint, including the repositories of one project, where each repository object carries its `name` and its `artifact_count`.

## Common pitfalls

> [!WARNING]
> - **Turning verification off to "fix" a certificate error.** `ssl._create_unverified_context()` and `CERT_NONE` send credentials to any server. Pass the CA file.
> - **Writing the password into the script.** Read it from the environment, which the pipeline fills from its secret store.
> - **Stopping after the first page.** Use `X-Total-Count` (or `Link`) in a loop, and stop on an empty page too.
> - **Catching every exception and carrying on.** A `401` or `403` must stop the script; an empty report that looks successful is worse than a failure.
> - **Using `requests` in a minimal image.** It is not in the standard library; `urllib.request` is always there.

## Your mission: Report Every Repository In A Project

You can now page through any Harbor list from Python with TLS verification on. The graded lab asks you to write `report.py`, which prints a JSON report of every repository in a project, with the repository count, the artifact count and one entry per repository, for a project that has more repositories than one page holds.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-104-playground-020-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-020/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-104-lab-020-01
astrona start ats-104-playground-020-01
```
