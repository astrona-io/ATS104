# Artifacts, Scans And The System API

The first module of this section read projects and repositories and wrote a few objects. The work a pipeline does in a registry happens one level lower, on artifacts: it finds the artifact a build produced, tags it, copies it between repositories, scans it and reads the result. Around that sit the endpoints for the registry as a whole: health, statistics, quotas, the audit log and garbage collection. This module covers both groups with `curl` and with Python.

Keep one sentence in mind: **a repository name with a slash in it must be encoded twice in the path, and an action such as a scan or a garbage collection is a request that returns at once while the work runs in the background.**

The module has four parts. **Artifact Paths And Double Encoding** shows how to address an artifact and why a repository name that contains a slash needs special care. **Tags, Copies And Deletes** changes tags, copies an artifact and deletes it, with the status codes a script must expect. **Scans And Vulnerability Reports** starts a scan and reads its status and findings. **System Information, Quotas, Audit Logs And Garbage Collection** reads the registry-wide endpoints. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Build the path of an artifact from a project, a repository and a reference, and encode a repository name that contains a slash.
- Ask for the tags, scan overview and labels of an artifact with the `with_*` parameters.
- Add and remove a tag and copy an artifact, and name the status code each request returns.
- Start a scan, wait for it with a limit and read the vulnerability summary.
- Read the system information, health, statistics, search results and quotas.
- Read the audit log with a filter, and start a garbage collection dry run.

## Before you start

You should have finished the first module of this section: base path, basic authentication, errors, pages, filters, and a Python script with `urllib`. You need to know what a Harbor project, repository, artifact and tag are.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. You work in two pods in the namespace `workstation`:

| Pod | What it has |
| --- | --- |
| `workstation` | `curl`, `jq`, `oras` and the `harbor` CLI, with Harbor's CA trusted. The variable `HARBOR_URL` holds Harbor's address |
| `python-runner` | Python 3.13 with only the standard library. `HARBOR_URL`, `HARBOR_CA` (the CA file), `HARBOR_USERNAME` and `HARBOR_PASSWORD` are set |

| In Harbor | What it is |
| --- | --- |
| Project `inventory` | Two repositories with a slash in the name: `web/frontend` (tags `v1` and `v2`) and `web/backend` (tag `v1`) |
| Project `archive` | One repository, `old-notes`, with the tag `v1` |

Define the helpers once in each terminal. `api` prints a response as JSON, and `api_code` prints only the status code:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
api() { ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0$1\" | jq"; }
api_code() { ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X ${2:-GET} \"\$HARBOR_URL/api/v2.0$1\""; }
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
