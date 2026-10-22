# Overview: Script Harbor With The harbor CLI (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and the pods the course uses, creates a small starting state, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** in the namespace `harbor`, at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod in the namespace `workstation`, with the `harbor` CLI v0.0.27, `oras`, `curl` and `jq`. It trusts Harbor's certificate, and the CLI is signed in as `admin` in the context `admin`. Its folder `/work` is free for your scripts.
- In Harbor: the private project `inventory` with the artifact `inventory/notes:v1`, and the user `demo-dev` (lab-only password `Demo-Dev-2026`), who is not a member of any project.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `members` prints the members of a project as JSON, and `copy_script` copies a script from your machine into `/work`.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
members() { ws sh -c "harbor project member list '$1' --page-size 100 -o json </dev/null"; }
copy_script() { ws sh -c "cat > /work/$1" < "$1"; }
```

Use them like this: `ws harbor project list`, `members inventory`, `copy_script onboard-member.sh`.

## Practice tasks

- Run `ws harbor project list -o json`, `-o yaml` and `-o csv` and compare what each format gives a script.
- Sign in as `demo-dev` into a new context with `--password-stdin`, list the projects, and switch back with `ws harbor context switch admin`. Look at the configuration file after each step.
- Run `ws harbor project member list` without a project name, first with `kubectl exec -it` and then with `</dev/null`, and compare what happens.
- Print the exit code of `harbor project view` for a project that exists and one that does not.
- Write a script that onboards `demo-dev` into `team-demo`, run it twice, and check that the member list shows the user once.
