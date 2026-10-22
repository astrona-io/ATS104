# Give CI Its Own Credentials With Robot Accounts

A CI job that pushes to the project `ci` with the administrator's password can also delete every project in Harbor. If that password leaks from a build log, the whole registry is open. The job needed one thing, to push to one project, and it was given everything.

A **robot account** is a non-human Harbor account for scripts and pipelines. It has a name, a secret that acts as its password, a lifetime, and a list of permissions. It cannot sign in to the portal. This module is about creating robots that hold exactly what their job needs. Keep one sentence in mind: **a robot's permissions are the damage its secret can do when it leaks.**

The module has two parts. **Project Robots And System Robots** explains the two kinds of robot, their names, and how permissions are written, and creates a robot with the CLI and with the REST API. **Least Privilege, Expiry And Rotation** cuts a robot down to what its job needs, stores its secret in Kubernetes, uses it with `oras`, and refreshes the secret. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain the difference between a project robot and a system robot, and read a name such as `robot$ci+builder`.
- Describe a robot's permissions as resources and actions.
- Create a project robot with the `harbor` CLI and with the REST API, and save the secret Harbor shows once.
- Choose the smallest set of permissions for a job, and an expiry.
- Store a robot's name and secret in a Kubernetes Secret and use them to push or pull with `oras`.
- Refresh a robot's secret, and prove the old one stops working.

## Before you start

You need to know what a Harbor project and repository are, how to create a Kubernetes Secret, and how to call the Harbor REST API with `curl`. You also need to know what push and pull mean for a registry.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. You work in the **`workstation`** pod in the namespace `workstation`, which has the `harbor` CLI (signed in as the lab-only administrator `admin`, password `Harbor12345`), `oras`, `curl` and `jq`, and trusts Harbor's certificate.

| In Harbor | What it is |
| --- | --- |
| Project `ci` | Empty; the CI pipeline pushes here |
| Project `inventory` | Holds the artifact `inventory/notes:v1` |

Define this helper once in each terminal:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
