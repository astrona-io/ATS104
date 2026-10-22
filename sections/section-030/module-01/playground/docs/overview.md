# Overview: Give CI Its Own Credentials With Robot Accounts (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and the pods the course uses, creates two projects, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod (namespace `workstation`) with the `harbor` CLI (signed in as `admin`), `oras` (signed in as `admin` in its default configuration), `curl` and `jq`, and Harbor's certificate authority trusted.
- In Harbor: the empty project `ci`, and the project `inventory` with the artifact `inventory/notes:v1`.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `robots` lists every robot with its ID, name, duration and permissions. `as_robot` runs an `oras` command signed in as a robot, using a separate configuration file so the administrator's sign-in is untouched.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
robots() { ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/robots?page_size=100" | jq "[.[] | {id, name, duration, access: [.permissions[] | .namespace as \$p | .access[] | \"\(\$p) \(.resource):\(.action)\"]}]"'; }
as_robot() { local name="$1" secret="$2"; shift 2; printf '%s' "$secret" | ws oras login --registry-config /tmp/robot.json -u "$name" --password-stdin harbor.localtest.me:8443 >/dev/null && ws oras "$@" --registry-config /tmp/robot.json; }
```

Use them like this: `robots`, and `as_robot 'robot$ci+builder' "$SECRET" manifest fetch harbor.localtest.me:8443/inventory/notes:v1`.

## Practice tasks

- Create a pull-only robot for `inventory` through the API and prove it can pull but not push.
- Try to create a robot with only `repository` `push`, and see what Harbor answers.
- Create a robot with `harbor project robot create --robot-config-file` from a YAML file, then list it with `harbor project robot list`.
- Refresh a robot's secret and prove the old one stops working.
- Disable a robot with `PUT /robots/<id>` and `"disable": true`, then enable it again, and watch its secret stop and start working.
