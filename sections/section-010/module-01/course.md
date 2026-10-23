# Script Harbor With The harbor CLI

A pipeline that creates a Harbor project for every new team needs three things from Harbor: a project, a user and a membership that gives the user a role in the project. The portal does this in ten clicks. A script does it in three commands, but only if the commands never stop to ask a question and the script does not fail when the project already exists.

The `harbor` command-line tool (CLI) is the official client for Harbor's REST API, the HTTP interface every Harbor feature is built on. It runs on a laptop, in a container or in a CI job. This module is about using it in a script. Keep one sentence in mind: **a command in a script must get every answer from its arguments, and the script must check before it creates.**

The module has two parts. **The harbor CLI In A Script** shows how the CLI saves its sign-in as a context, how it encrypts the password in a container, why a script selects a saved context instead of signing in, and how to read JSON output and exit codes. **An Onboarding Script That Can Run Twice** builds a script that creates a project, a user and a Developer membership only when each is missing. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Sign the `harbor` CLI in once at a terminal, explain where it keeps the server, the user name and the password, and let a script select that context with `harbor context switch`.
- Explain why the CLI needs `HARBOR_ENCRYPTION_KEY` in a container, and where the key should come from.
- Explain when a CLI command waits for input, and keep it from doing so in a script.
- Read a command's `-o json` output with `jq`, and use an exit code to decide what to do next.
- Write a shell script that creates a project, a user and a membership only when they are missing.
- Prove a script is idempotent by running it twice without a terminal.

## Before you start

You need to be comfortable in a terminal: shell variables, `if`, exit codes, pipes and `jq`. You need to know what a Harbor project is. This module does not teach Harbor's permission model; it teaches how to drive Harbor from a script.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. You work in the **`workstation`** pod in the namespace `workstation`. It has the `harbor` CLI v0.0.27, `curl` and `jq`, and it trusts Harbor's certificate. The CLI is already signed in as the lab-only administrator `admin` (password `Harbor12345`).

| In Harbor | What it is |
| --- | --- |
| Project `inventory` | A private project with one small artifact, `inventory/notes:v1` |
| User `demo-dev` | A local Harbor user who is not a member of any project yet |

Every command runs in the workstation pod. Define this helper once in each terminal:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
