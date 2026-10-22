# Prerequisites

Before starting this lab you should be able to:

- Read and update a robot account through the Harbor REST API or the `harbor` CLI.
- Create a Kubernetes Secret with `kubectl create secret generic`.
- Pull and push an artifact with `oras`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`, with the lab-only administrator `admin` / `Harbor12345`.
- The **workstation** pod in the namespace `workstation`, with `harbor`, `oras`, `regctl`, `cosign`, `curl` and `jq`, and Harbor's certificate authority (CA) trusted. Run a command there with `kubectl -n workstation exec -i deploy/workstation -- <command>`.
- The workstation pod with `harbor`, `oras`, `curl` and `jq`, signed in as the administrator.
- The project `inventory` with the artifact `inventory/notes:v1`.
- The robot account `robot$inventory+deployer` and the ConfigMap `leaked-credentials` in the namespace `workstation`.

Nothing the task asks you to create has been created for you.

## Working rules

- Everything is graded on the **final state** of Harbor and the cluster, so leave your fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Keep TLS verification on. Every tool in the environment already trusts Harbor's CA.
