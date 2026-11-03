# Solution: Audit Deleted Artifacts With A CloudEvents Webhook

Work the task yourself first. Running `astrona submit -c sections/section-040/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks two things: the policy has the right event type, target and payload format, and a real delete in `inventory` reaches the receiver with the auth header. Each check runs against the final state.

## Step 1: Look at the starting state

Define the helpers and list the policies of `inventory`:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
receiver_log() { kubectl -n hooks logs deploy/echo --since=10m; }
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies" | jq'
```

The answer is an empty list, so no policy exists yet.

## Step 2: Write the policy

A policy has a name, a list of event types, and a list of targets. The target holds the type, the address, the auth header and the payload format. Save this as `webhook-audit.json` on your machine:

```json
{
  "name": "audit-deletes",
  "description": "Tell the audit service about deleted artifacts",
  "enabled": true,
  "event_types": ["DELETE_ARTIFACT"],
  "targets": [
    {
      "type": "http",
      "address": "http://echo.hooks.svc.cluster.local:8080/audit",
      "auth_header": "Bearer audit-token-456",
      "skip_cert_verify": false,
      "payload_format": "CloudEvents"
    }
  ]
}
```

## Step 3: Create it

```sh
ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -u admin:Harbor12345 -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies"' < webhook-audit.json
```

The answer is `201`. Read the policy back to check the event type and the format.

## Step 4: Trigger it

Push an artifact and delete it:

```sh
ws sh -c "cd /tmp && echo test > test.txt && oras push harbor.localtest.me:8443/inventory/webhook-test:t1 test.txt >/dev/null"
ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -u admin:Harbor12345 -X DELETE "$HARBOR_URL/api/v2.0/projects/inventory/repositories/webhook-test/artifacts/t1"'
```

The delete answers `200`.

## Step 5: Read the receiver log

```sh
receiver_log | grep -A 30 "/audit"
```

Look for a request to `/audit` whose body has `"type": "harbor.artifact.deleted"` and whose headers include `Authorization: Bearer audit-token-456`. The push did not trigger the policy, because the policy lists only the delete event.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Select every event type | The receiver gets pushes and pulls too, and the check on the event types fails |
| Leave the payload format on Default | The event type is `DELETE_ARTIFACT` and not `harbor.artifact.deleted`, so the delivery check fails |
| Use the endpoint `/harbor` | The grader looks for the path `/audit` |
| Delete the artifact before the policy exists | No event is sent for the past |

## Common mistakes

- Writing `harbor.artifact.deleted` as the event type of the policy. The policy uses `DELETE_ARTIFACT`; the CloudEvents `type` carries the other name.
- Forgetting `payload_format` and getting the Default format.
- Typing the auth header without the word `Bearer`.

## Practice on your own

- Add a second policy for `SCANNING_FAILED` that goes to a different path of the receiver.
- Disable the policy, delete an artifact, and check that nothing arrives.
- Read the executions of the policy and find the task log of the delivery.
