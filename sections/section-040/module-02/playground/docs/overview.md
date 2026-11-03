# Overview: Receivers, Events And Troubleshooting (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, the workstation pod and a webhook receiver, creates one project, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod (namespace `workstation`) with the `harbor` CLI (signed in as `admin`), `oras`, `curl` and `jq`, and Harbor's certificate authority trusted.
- The receiver **`echo`** (namespace `hooks`). It answers every request with `200` and writes the method, path, headers and body to its log. Its address is `http://echo.hooks.svc.cluster.local:8080`.
- In Harbor: the project `inventory` with the artifact `inventory/notes:v1`.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `push_test` pushes a tiny artifact into `inventory` under the tag you give. `delete_test` deletes it again. `receiver_log` prints the receiver's recent log. `policies` lists the webhook policies of `inventory`.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
push_test() { ws sh -c "cd /tmp && echo '$1' > test.txt && oras push harbor.localtest.me:8443/inventory/webhook-test:$1 test.txt >/dev/null && echo pushed $1"; }
delete_test() { ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X DELETE \"\$HARBOR_URL/api/v2.0/projects/inventory/repositories/webhook-test/artifacts/$1\""; }
receiver_log() { kubectl -n hooks logs deploy/echo --since=10m; }
policies() { ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies" | jq'; }
```

Use them like this: `push_test t1`, `delete_test t1`, then `receiver_log | tail -n 60`.

## Practice tasks

- Read the list of supported events with `GET /projects/inventory/webhook/events`.
- Create a policy for `DELETE_ARTIFACT` and one for `PUSH_ARTIFACT`, and check which of them fires for a push and which for a delete.
- Send a test request with `POST /projects/inventory/webhook/policies/test` and read the receiver log.
- Read `GET /projects/inventory/webhook/lasttrigger` after a few events.
- Disable a policy with a `PUT`, trigger an event and check that nothing arrives.
- Point a policy at a wrong address and read the execution and the task log of the failed delivery.
