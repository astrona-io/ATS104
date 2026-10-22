# Call The Harbor REST API

A report of every repository in a project sounds like one request. With the defaults, it is not: Harbor answers a list request with the first ten items, and a script that reads only that answer reports ten repositories when there are twelve. Nothing in the response body says that more exist. The answer is in the response headers.

The REST API is Harbor's HTTP interface under `/api/v2.0`. The portal and the `harbor` command-line tool are both clients of it. This module teaches it the way a script uses it. Keep one sentence in mind: **a list endpoint returns one page, and the headers say how many items there are in total.**

The module has three parts. **Base Path, Authentication And Errors** sends the first requests with `curl`, with and without credentials, and reads Harbor's error format. **Pages, Filters And Sorting** reads the `X-Total-Count` and `Link` headers, changes the page size, and filters and sorts on the server. **A Python Script With The Standard Library** turns that into a script that reads every page with TLS verification on. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Call the Harbor REST API with basic authentication from `curl` and from Python.
- Read Harbor's error response and say what `401`, `403`, `404` and `409` mean for a script.
- Read every page of a list endpoint with `page`, `page_size` and `X-Total-Count`.
- Filter a list with the `q` parameter and order it with `sort`.
- Trust Harbor's certificate authority in Python instead of turning verification off.
- Write a Python script that reports on a project using only the standard library.

## Before you start

You need to know HTTP basics (methods, status codes, headers), `curl`, JSON and `jq`, and enough Python 3 to read a short script. You need to know what a Harbor project, repository and artifact are.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. You work in two pods in the namespace `workstation`:

| Pod | What it has |
| --- | --- |
| `workstation` | `curl`, `jq`, `oras` and the `harbor` CLI, with Harbor's CA trusted. The variable `HARBOR_URL` holds Harbor's address |
| `python-runner` | Python 3.13 with only the standard library. `HARBOR_URL`, `HARBOR_CA` (the CA file), `HARBOR_USERNAME` and `HARBOR_PASSWORD` are set from Kubernetes objects |

In Harbor, the project `inventory` holds twelve repositories, `inventory/notes-01` to `inventory/notes-12`, and `notes-03` has two artifacts. The project `archive` holds two repositories. The lab-only administrator is `admin` with the password `Harbor12345`.

Define these helpers once in each terminal:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
