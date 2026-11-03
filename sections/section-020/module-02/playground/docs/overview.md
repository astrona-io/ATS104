# Overview: Artifacts, Scans And The System API (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and the pods the course uses, pushes a few repositories, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod (namespace `workstation`) with `curl`, `jq`, `oras` and the `harbor` CLI, Harbor's certificate authority (CA) trusted, and `HARBOR_URL` set.
- The **`python-runner`** pod (namespace `workstation`) with Python 3.13 and only the standard library. `HARBOR_URL`, `HARBOR_USERNAME`, `HARBOR_PASSWORD` and `HARBOR_CA` are set. Its folder `/work` is free for your scripts.
- In Harbor: the project `inventory` with the repositories `web/frontend` (tags `v1` and `v2`) and `web/backend` (tag `v1`), and the project `archive` with the repository `old-notes`.

## Helpers

Paste these once in each new terminal. `ws` and `py` run a command in the two pods. `api` calls the API as the administrator from the workstation and pretty-prints the JSON. `api_code` prints only the HTTP status code.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
api() { ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0$1\" | jq"; }
api_code() { ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X ${2:-GET} \"\$HARBOR_URL/api/v2.0$1\""; }
```

Use them like this: `api /systeminfo`, `api_code /projects/inventory/repositories/web%252Ffrontend/artifacts`.

## Practice tasks

- Ask for `/projects/inventory/repositories/web/frontend/artifacts` and then `/projects/inventory/repositories/web%252Ffrontend/artifacts`, and compare the status codes.
- Read an artifact with `?with_tag=true` and with `?with_scan_overview=true`, and compare the fields.
- Add a tag with `POST .../artifacts/v1/tags`, send the same request again, and read the answer.
- Copy an artifact into another repository with `POST` and the `from` parameter.
- Read `/systeminfo`, `/health` and `/statistics`, and `/search?q=web`.
- Read `/quotas` and the audit log at `/audit-logs?page_size=5`.
- Start a garbage collection dry run with `POST /system/gc/schedule` and read `/system/gc`.
