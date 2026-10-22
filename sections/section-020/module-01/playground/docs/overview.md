# Overview: Call The Harbor REST API (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and the pods the course uses, pushes some small repositories, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod (namespace `workstation`) with `curl`, `jq`, `oras` and the `harbor` CLI, Harbor's certificate authority (CA) trusted, and `HARBOR_URL` set.
- The **`python-runner`** pod (namespace `workstation`) with Python 3.13 and only the standard library. `HARBOR_URL`, `HARBOR_USERNAME`, `HARBOR_PASSWORD` and `HARBOR_CA` are set. Its folder `/work` is free for your scripts.
- In Harbor: the project `inventory` with twelve repositories, `inventory/notes-01` to `inventory/notes-12`, where `notes-03` has two artifacts (`v1` and `v2`); and the project `archive` with two repositories.

## Helpers

Paste these once in each new terminal. `ws` and `py` run a command in the two pods. `api` calls the API as the administrator from the workstation and pretty-prints the JSON. `api_headers` prints only the response headers.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
api() { ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0$1\" | jq"; }
api_headers() { ws sh -c "curl -s -D - -o /dev/null -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0$1\""; }
```

Use them like this: `api /projects`, `api_headers '/projects/inventory/repositories?page_size=5'`.

## Practice tasks

- Compare `GET /projects` with and without credentials, and explain the difference.
- Ask for the repositories of `inventory` with `page_size=5` and follow the `Link` header to the last page by hand.
- Filter the repositories with `q=name=~notes-0` and count them. Then sort them with `sort=-name`.
- Ask for `/projects/inventory/repositories/notes-03/artifacts` and read the `tags` of each artifact.
- Write a Python script that prints the names of every repository whose artifact count is more than one.
