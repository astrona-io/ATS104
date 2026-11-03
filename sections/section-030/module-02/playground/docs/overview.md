# Overview: System Robots, Lifecycle And Auditing (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor and the workstation pod, creates three projects, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod (namespace `workstation`) with the `harbor` CLI (signed in as `admin`), `oras`, `curl` and `jq`, and Harbor's certificate authority trusted.
- In Harbor: the projects `team-red`, `team-blue` and `team-green`, each with the artifact `notes:v1`. No robot exists yet.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `api` calls the API as the administrator and pretty-prints the JSON. `as_robot` runs an `oras` command signed in as a robot, using a separate configuration file so the administrator's sign-in is untouched.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
api() { ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0$1\" | jq"; }
as_robot() { local name="$1" secret="$2"; shift 2; printf '%s' "$secret" | ws oras login --registry-config /tmp/robot.json -u "$name" --password-stdin harbor.localtest.me:8443 >/dev/null && ws oras "$@" --registry-config /tmp/robot.json; }
```

Use them like this: `api '/robots?page_size=100'`, and `as_robot 'robot$puller' "$SECRET" manifest fetch harbor.localtest.me:8443/team-red/notes:v1`.

## Practice tasks

- Create a system robot with pull access to two projects, and compare its name with a project robot's name.
- Create a system robot with the namespace `*` and see which projects it can read.
- Disable a robot with `PUT /robots/<id>` and `"disable": true`, then enable it again, and watch pulls stop and start.
- Replace a robot's permissions with a `PUT` and check that the old access is gone.
- Delete a robot and read the audit log at `/audit-logs?page_size=10&sort=-op_time`.
- Read the project log at `/projects/team-red/logs` after a pull and a failed pull.
- Create a Kubernetes image pull Secret of type `kubernetes.io/dockerconfigjson` from the robot's credentials.
