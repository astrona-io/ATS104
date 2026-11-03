# Prerequisites

Before starting this lab you should be able to:

- Run commands in a pod with `kubectl exec`.
- Write a small POSIX shell script with `if`, `set -eu` and command exit codes.
- Read JSON with `jq`.
- Use the `harbor` CLI in a script: `-o json`, exit codes and `</dev/null`.


## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` / `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `harbor`, `oras`, `regctl`, `cosign`, `curl` and `jq`, and Harbor's certificate authority (CA) trusted. Run a command there with `kubectl -n workstation exec -i deploy/workstation -- <command>`.
- The `harbor` CLI v0.0.27 in the workstation pod, signed in as the administrator in the context `admin`.
- The private project `team-red` with two repositories: `app` (tags `build-41`, `build-42` and `tmp`) and `api` (tags `build-7` and `tmp`). The tag `tmp` is on the same artifact as `build-42` and `build-7`.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Harbor and the cluster, so leave your fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Keep TLS verification on. Every tool in the environment already trusts Harbor's CA.
