# System Robots, Lifecycle And Auditing

The first module of this section created a project robot for one job. Real platforms need more: one robot that reads from several projects, a plan for what happens when a robot expires or is no longer needed, a way to see what a robot did, and a way to hand its credentials to a Kubernetes cluster. This module covers those four things.

Keep one sentence in mind: **every robot needs an owner, an expiry and a trail, and a robot that has none of these is a leaked secret that has not been found yet.**

The module has four parts. **System Robots And Their Permissions** creates a robot that spans more than one project and explains the wildcard namespace. **The Lifecycle Of A Robot** lists, disables, replaces, expires and deletes robots. **Auditing What A Robot Did** reads the audit log and the project log to answer who did what. **Robots In Pipelines And Kubernetes Pull Secrets** gives a robot to a cluster as an image pull secret. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Create a system robot with pull access to two projects, and explain why a project robot cannot do it.
- Explain what the namespace `*` grants and why it is rarely the right choice.
- List, disable, enable, replace and delete a robot through the REST API.
- Read a robot's expiry and plan the renewal before it passes.
- Find the events a robot caused in the audit log and in a project's log.
- Build a Kubernetes image pull Secret from a robot's credentials.

## Before you start

You should have finished the first module of this section: project robots, permissions as resources and actions, expiry, Kubernetes Secrets and refreshing a secret.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. You work in the **`workstation`** pod in the namespace `workstation`, which has the `harbor` CLI (signed in as the lab-only administrator `admin`, password `Harbor12345`), `oras`, `curl` and `jq`.

| In Harbor | What it is |
| --- | --- |
| Projects `team-red`, `team-blue`, `team-green` | Each holds the artifact `notes:v1` |

Define the helpers once in each terminal:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
api() { ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0$1\" | jq"; }
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
