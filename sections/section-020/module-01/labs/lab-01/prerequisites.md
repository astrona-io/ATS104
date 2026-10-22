# Prerequisites

Before starting this lab you should be able to:

- Call a REST API with `curl` and read its JSON with `jq`.
- Write a short Python 3 script with the standard library (`urllib`, `json`).
- Explain what a page and a page size are in a list API.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` / `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `harbor`, `oras`, `regctl`, `cosign`, `curl` and `jq`, and Harbor's certificate authority (CA) trusted. Run a command there with `kubectl -n workstation exec -i deploy/workstation -- <command>`.
- The `python-runner` pod (Python 3.13, standard library only) with `HARBOR_URL`, `HARBOR_USERNAME`, `HARBOR_PASSWORD` and `HARBOR_CA` set.
- The project `inventory` with twelve repositories, and the project `archive` with two.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Harbor and the cluster, so leave your fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Keep TLS verification on. Every tool in the environment already trusts Harbor's CA.
