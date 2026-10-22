# Prerequisites

Before starting this lab you should be able to:

- Write and debug a POSIX shell script that runs without a terminal.
- Use the `harbor` CLI to create projects, users and project members.
- Read JSON with `jq`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` / `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `harbor`, `oras`, `regctl`, `cosign`, `curl` and `jq`, and Harbor's certificate authority (CA) trusted. Run a command there with `kubectl -n workstation exec -i deploy/workstation -- <command>`.
- The `harbor` CLI v0.0.27 in the workstation pod, signed in as the administrator in the context `admin`.
- `/work/teams.csv` and the script `/work/onboard-teams.sh` in the workstation pod.
- The project `team-red` with the user `red-dev` as a Developer.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Harbor and the cluster, so leave your fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Keep TLS verification on. Every tool in the environment already trusts Harbor's CA.
