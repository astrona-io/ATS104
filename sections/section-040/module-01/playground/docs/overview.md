# Overview: Trigger Pipelines With Harbor Webhooks (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Harbor, the pods the course uses and a webhook receiver, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. The lab-only administrator is `admin` with the password `Harbor12345`.
- The **`workstation`** pod (namespace `workstation`) with the `harbor` CLI and `oras`, both signed in as `admin`, plus `curl` and `jq`.
- The webhook receiver **`echo`** in the namespace `hooks`: `http://echo.hooks.svc.cluster.local:8080`, and HTTPS with a self-signed certificate on port `8443`. It answers every request with `200` and logs the method, path, headers and body.
- In Harbor: the project `inventory` with the artifact `inventory/notes:v1`, and no webhook policies.

## Helpers

Paste these once in each new terminal. `ws` runs a command in the workstation pod. `push_test` pushes a tiny artifact into `inventory` under the tag you give. `receiver_log` prints the receiver's recent log. `policies` lists the webhook policies of `inventory`.

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
push_test() { ws sh -c "cd /tmp && echo '$1' > test.txt && oras push harbor.localtest.me:8443/inventory/webhook-test:$1 test.txt >/dev/null && echo pushed $1"; }
receiver_log() { kubectl -n hooks logs deploy/echo --since=10m; }
policies() { ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies" | jq'; }
```

Use them like this: `push_test t1`, then `receiver_log | tail -n 60`.

## Practice tasks

- Create a policy with `harbor webhook create` for `PUSH_ARTIFACT`, push, and find the request and its `authorization` header in the receiver log.
- Create a second policy with the CloudEvents format and compare the two bodies for the same push.
- Add `DELETE_ARTIFACT` to a policy, delete an artifact, and read the event.
- Point a policy at the HTTPS port with certificate verification on, and read the failed task's log through the API.
- Turn a policy off with `"enabled": false` in a `PUT`, push, and confirm nothing arrives.
