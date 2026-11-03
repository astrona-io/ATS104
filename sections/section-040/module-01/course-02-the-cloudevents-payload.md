# The CloudEvents Payload

A pipeline that consumes events from many sources does not want one parser for each source. The CloudEvents specification solves this by describing every event in the same envelope. Harbor can send its webhooks in that envelope instead of its own Default format. This part creates a second policy in the CloudEvents format, pushes an artifact, and compares the two requests field by field.

## What CloudEvents is

**CloudEvents** is a Cloud Native Computing Foundation (CNCF) specification for describing events in one common shape, so tools that consume events from many sources can read them all the same way. Harbor's CloudEvents payload puts the event's metadata in standard fields and the Default payload's `event_data` in the field `data`.

| CloudEvents field | Value for a Harbor push |
| --- | --- |
| `specversion` | The version of the CloudEvents specification |
| `id` | A unique ID for this event |
| `requestid` | The ID of the request that caused the event |
| `source` | Where the event came from, which is Harbor |
| `type` | `harbor.artifact.pushed`, the name from the event table |
| `datacontenttype` | `application/json` |
| `time` | When the event happened |
| `operator` | Who caused the event |
| `data` | The same `resources` and `repository` as the Default payload |

## Create a second policy

The commands below assume that the policy `notify-default` exists on `inventory`: it sends `PUSH_ARTIFACT` events in the Default format to the path `/harbor` of the receiver. The CLI sets the payload format when it creates a policy; to see both side by side, create a second policy through the REST API. Save this as `webhook-policy-cloudevents.json` on your machine:

<!-- astrona:playground:renew -->

```json
{
  "name": "notify-cloudevents",
  "description": "Push events in the CloudEvents format",
  "enabled": true,
  "event_types": ["PUSH_ARTIFACT"],
  "targets": [
    {
      "type": "http",
      "address": "http://echo.hooks.svc.cluster.local:8080/cloudevents",
      "auth_header": "Bearer demo-token",
      "skip_cert_verify": false,
      "payload_format": "CloudEvents"
    }
  ]
}
```

Send it, push a second tag, and read the request that arrives at `/cloudevents`:

```sh
ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -u admin:Harbor12345 -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies"' < webhook-policy-cloudevents.json
ws sh -c 'cd /tmp && oras push harbor.localtest.me:8443/inventory/hello:v2 hello.txt'
receiver_log | tail -n 160
```

The `POST` to the policies endpoint returns `201`. Find the request to the path `/cloudevents` near the end of the log. Its body has the CloudEvents fields from the table above, and `data` holds the same `resources` and `repository` as before. The push to `v2` also sent a Default request to `/harbor`, because both policies listen for `PUSH_ARTIFACT`.

## Which format to choose

Choose `Default` when the receiver is a script that you write for Harbor only: the fields are the ones in the Harbor documentation, and `type` is the event name such as `PUSH_ARTIFACT`. Choose `CloudEvents` when the receiver is a general tool that already understands the envelope, for example an event router that dispatches by `type`. The content is the same in both. Only the envelope and the name of the event type differ, so a receiver that handles both has to map `PUSH_ARTIFACT` to `harbor.artifact.pushed`.

You now know the CloudEvents fields Harbor sends, how to create a policy that uses them, and how to choose between the two formats. The open question is what happens when the receiver is down or unreachable, and how to find out why a webhook never arrived.

## Common pitfalls

> [!WARNING]
> - **Expecting the Default `type` in a CloudEvents consumer.** The event is `harbor.artifact.pushed` there, not `PUSH_ARTIFACT`.
> - **Creating two policies for the same event and the same endpoint.** The receiver then gets the event twice. Give each policy its own path or event.
> - **Looking for the fields at the top level.** In CloudEvents, the artifact details are inside `data`.
