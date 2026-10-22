# Prerequisites

Before starting this lab you should be able to:

- Create objects through the Harbor REST API or the `harbor` CLI.
- Push an artifact with `oras`.
- Read a pod's log with `kubectl logs`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` / `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `harbor`, `oras`, `regctl`, `cosign`, `curl` and `jq`, and Harbor's certificate authority (CA) trusted. Run a command there with `kubectl -n workstation exec -i deploy/workstation -- <command>`.
- The workstation pod with `harbor`, `oras`, `curl` and `jq`, signed in as the administrator.
- The project `inventory` with one artifact.
- The webhook receiver `echo` in the namespace `hooks`, at `http://echo.hooks.svc.cluster.local:8080`. It writes every request it gets to its log.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Harbor and the cluster, so leave your fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Keep TLS verification on. Every tool in the environment already trusts Harbor's CA.
