# Solution: Notify A Pipeline When An Artifact Is Pushed

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the policy's settings, and a real delivery. It pushes an artifact with a fresh tag and waits up to two minutes for the receiver to log that tag together with `PUSH_ARTIFACT` and the auth header.

## Step 1: Create the policy

With the `harbor` CLI, give every flag so the command does not open its form:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws harbor webhook create notify-ci --project inventory --notify-type http \
  --event-type PUSH_ARTIFACT --endpoint-url http://echo.hooks.svc.cluster.local:8080/harbor \
  --payload-format Default --auth-header 'Bearer pipeline-token-123' \
  --description 'Tell the CI pipeline about new artifacts' </dev/null
```

The same policy through the REST API is a `POST` to `/api/v2.0/projects/inventory/webhook/policies` with `name`, `enabled`, `event_types` and one entry in `targets` with `type`, `address`, `auth_header`, `skip_cert_verify` and `payload_format`. The reference solution uses that form.

## Step 2: Check what Harbor stored

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies"' \
  | ws jq '.[] | select(.name == "notify-ci") | {enabled, event_types, targets}'
```

The policy is enabled, `event_types` is `["PUSH_ARTIFACT"]`, and the one target has type `http`, the endpoint, the auth header and the payload format `Default`.

## Step 3: Prove the delivery

Push a small artifact and read the receiver's log:

```sh
ws sh -c 'cd /tmp && echo deploy-me > app.txt && oras push harbor.localtest.me:8443/inventory/app:release-1 app.txt'
kubectl -n hooks logs deploy/echo --since=5m | tail -n 80
```

The last request is a `POST` to `/harbor` with the header `authorization: Bearer pipeline-token-123`, and its body has `type` `PUSH_ARTIFACT` and a resource with the tag `release-1` in the repository `inventory/app`. If nothing is there yet, wait a few seconds: `jobservice` sends webhooks in the background.

## Step 4: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Select every event type | The pipeline starts on pulls and scans too; the grader accepts `PUSH_ARTIFACT` only |
| Leave out the auth header | The pipeline rejects the request; anyone could start it otherwise |
| CloudEvents payload | The pipeline expects the Default format in this task |
| Check only the policy | A correct policy can still fail to deliver; the grader pushes and watches |

## Common mistakes

- A typo in the endpoint, such as `echo.hook` or port `8443`, so the task log shows a connection error.
- Forgetting `--payload-format`, then checking which format Harbor chose by default.
- Reading the receiver log once, right after the push, before `jobservice` has sent anything.
