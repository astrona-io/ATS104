# Projects, Repositories And Artifacts With The CLI

A pipeline does more with Harbor than create projects and users. It looks up which repositories a project holds, finds the artifact a build produced, adds a tag when a build passes, removes a tag when it is no longer needed, starts a scan and reads the result. The `harbor` command-line tool (CLI) has a command for each of these. This module covers the commands that work on the content of a registry, and how to use them in a script that must run twice with the same result.

Keep one sentence in mind: **a tag points to one artifact, an artifact can have many tags, and a command that changes a tag fails when the change is already made, so the script asks first.**

The module has four parts. **Projects With The CLI** covers creating, listing, filtering, viewing, summarising and deleting projects, and the storage limit. **Repositories And Artifacts** covers how to name an artifact in a command, how to list repositories and artifacts without losing rows to the default page size, and how to delete them. **Tags, Retention And Immutable Tags** covers adding and removing tags safely, and the two project rules that keep a registry tidy and safe. **Scans And Vulnerabilities** covers starting a scan, reading the result and turning it into a pass or fail for a pipeline. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Create, list, filter, view and delete projects with the CLI, and set a storage limit when you create one.
- Name an artifact the way each CLI command expects: by project, repository and tag or digest.
- List repositories and artifacts completely by setting the page size.
- Add and remove a tag only when the change is needed, so a script can run again.
- Create a tag retention rule and an immutable tag rule, and explain what each does to a push.
- Start a scan and read the vulnerabilities of an artifact or a project with the CLI.

## Before you start

You should have finished the module on scripting Harbor with the CLI: contexts, `-o json`, exit codes and `</dev/null`. You need to know what a Harbor project, a repository, an artifact and a tag are. This module does not teach how images are built; it works with the small artifacts that `oras` pushes.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. You work in the **`workstation`** pod in the namespace `workstation`. It has the `harbor` CLI v0.0.27, `oras`, `curl` and `jq`, and it trusts Harbor's certificate. The CLI is already signed in as the lab-only administrator `admin` (password `Harbor12345`).

| In Harbor | What it is |
| --- | --- |
| Project `inventory` | A private project with the repository `notes` (tags `v1` and `v2`) and the repository `app` (tags `build-1`, `build-2` and `tmp`, where `tmp` is on the same artifact as `build-2`) |
| Project `scratch` | An empty private project |
| User `demo-dev` | A local Harbor user who is not a member of any project |

Every command runs in the workstation pod. The CLI draws lists and views as a table only on a terminal, so define two helpers once in each terminal:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
