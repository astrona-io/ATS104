# Overview: Projects, Repositories And Artifacts With The CLI (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and the pods the course uses, pushes a few tagged artifacts, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod in the namespace `workstation`, with the `harbor` CLI v0.0.27, `oras`, `curl` and `jq`. It trusts Harbor's certificate, and the CLI is signed in as `admin`. Its folder `/work` is free for your scripts.
- In Harbor: the private project `inventory` with the repositories `notes` (tags `v1` and `v2`) and `app` (tags `build-1`, `build-2` and `tmp`, where `tmp` is on the artifact of `build-2`), the empty private project `scratch`, and the user `demo-dev`.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `wst` does the same with a terminal. The `harbor` CLI (version 0.0.27) draws lists and views as a table only on a terminal, so list and view commands run through `wst`.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
```

Use them like this: `wst harbor repo list inventory`, `wst harbor artifact list inventory/app`.

## Practice tasks

- List the projects with `wst harbor project list`, then with `--private`, `--public` and `--name inventory`, and compare.
- Run `wst harbor project summary inventory` and read the counts.
- List the repositories of `inventory` with the default page size and with `--page-size 100`.
- Run `wst harbor artifact list inventory/app` and `wst harbor artifact info inventory/app/build-2`.
- Add the tag `stable` to `build-2`, run the same command again and read the error. Then remove the tag `tmp`.
- Create a tag retention rule for `inventory` and an immutable tag rule for the tag `stable`, then try to push a second artifact with the tag `stable` and read the answer.
- Start a scan of `inventory/app/build-1` and list the vulnerabilities for the project.
- Delete the project `scratch` and read what the CLI asks.
