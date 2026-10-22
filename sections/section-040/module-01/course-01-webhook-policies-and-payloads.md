# Webhook Policies And Payloads

A pipeline that should react to a push needs three things from Harbor: a request at the right moment, at the right address, with enough information to act on. A webhook policy decides all three. This part creates a policy, pushes an artifact, and reads the request Harbor sends, first in Harbor's own payload format and then in the CloudEvents format.

## What a webhook policy holds

A webhook policy belongs to one project. It has a name, an on or off switch, a list of **event types** that trigger it, and a **target**: where and how to send the request. The target has these fields:

| Field | Meaning |
| --- | --- |
| Notify type | `http` sends a JSON POST to any endpoint; `slack` posts a formatted message to a Slack incoming webhook URL |
| Endpoint | The address Harbor sends the request to |
| Auth header | A fixed value Harbor sends in the `Authorization` header, so the receiver can check that the request comes from Harbor |
| Verify remote certificate | For an HTTPS endpoint, whether Harbor checks its certificate |
| Payload format | `Default` (Harbor's own JSON) or `CloudEvents`, for HTTP targets only |

The event types cover the life of an artifact and of a project:

| Event (Default name) | CloudEvents type | When it fires |
| --- | --- | --- |
| `PUSH_ARTIFACT` | `harbor.artifact.pushed` | An artifact is pushed |
| `PULL_ARTIFACT` | `harbor.artifact.pulled` | An artifact is pulled |
| `DELETE_ARTIFACT` | `harbor.artifact.deleted` | An artifact is deleted |
| `SCANNING_COMPLETED` | `harbor.scan.completed` | A vulnerability scan finished |
| `SCANNING_FAILED` / `SCANNING_STOPPED` | `harbor.scan.failed` / `harbor.scan.stopped` | A scan failed or was stopped |
| `QUOTA_EXCEED` / `QUOTA_WARNING` | `harbor.quota.exceeded` / `harbor.quota.warned` | The project's storage quota is full or nearly full |
| `REPLICATION` | `harbor.replication.status.changed` | A replication changed status |
| `TAG_RETENTION` | `harbor.tag_retention.finished` | A tag retention run finished |

A system administrator can also turn webhooks off for the whole Harbor under **Configuration > System Settings**. Then no policy sends anything, whatever its own switch says.

## Create a policy with the CLI

`harbor webhook create` takes the policy name as its argument and everything else as flags. Without the flags it opens an interactive form, so a script gives all of them. Create a policy that sends `PUSH_ARTIFACT` events from `inventory` to the receiver, in the Default format, with an auth header:

<!-- astrona:playground:renew -->

```sh
ws harbor webhook create notify-default --project inventory --notify-type http \
  --event-type PUSH_ARTIFACT --endpoint-url http://echo.hooks.svc.cluster.local:8080/harbor \
  --payload-format Default --auth-header 'Bearer demo-token' \
  --description 'Push events in the Default format' </dev/null
```

List the project's policies as JSON to check what Harbor stored:

```sh
ws sh -c 'harbor webhook list inventory -o json </dev/null | jq'
```

The policy `notify-default` is enabled, with the event type `PUSH_ARTIFACT` and one target of type `http` with the endpoint, the auth header and the payload format `Default`.

## Push and read the request

Push a small artifact into `inventory`. `oras` in the workstation is signed in as the administrator:

```sh
ws sh -c 'cd /tmp && echo hello > hello.txt && oras push harbor.localtest.me:8443/inventory/hello:v1 hello.txt'
```

Harbor's `jobservice` sends the webhook a moment later, in the background. Read the receiver's log:

```sh
receiver_log | tail -n 80
```

The end of the log shows the last request: a `POST` to the path `/harbor` with the header `authorization: Bearer demo-token` and a JSON body. If the log is empty, wait a few seconds and run it again. The body is the **Default** payload:

| Field | Value in this request |
| --- | --- |
| `type` | `PUSH_ARTIFACT` |
| `occur_at` | The time of the push, as a Unix timestamp |
| `operator` | Who caused the event; for a push, the user who pushed, here `admin` |
| `event_data.resources[]` | The pushed artifact: `digest`, `tag` (`v1`) and `resource_url` (`harbor.localtest.me:8443/inventory/hello:v1`) |
| `event_data.repository` | `name` (`hello`), `namespace` (`inventory`), `repo_full_name` (`inventory/hello`) and `repo_type` (`private`) |

A pipeline needs `resource_url` or the repository name plus the digest; that is enough to deploy exactly the artifact that was pushed.

## The CloudEvents format

**CloudEvents** is a CNCF specification for describing events in one common shape, so tools that consume events from many sources can read them all the same way. Harbor's CloudEvents payload puts the event's metadata in standard fields and the Default payload's `event_data` in `data`.

The CLI sets the payload format when it creates a policy; to see both side by side, create a second policy through the REST API. Save this as `webhook-policy-cloudevents.json` on your machine:

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

The `POST` to the policies endpoint returns `201`. Find the request to the path `/cloudevents` near the end of the log. Its body has the CloudEvents fields `specversion`, `id`, `requestid`, `source`, `type` (`harbor.artifact.pushed`), `datacontenttype`, `time` and `operator`, and `data` holds the same `resources` and `repository` as before. The push to `v2` also sent a Default request to `/harbor`, because both policies listen for `PUSH_ARTIFACT`.

You can now create a webhook policy, choose its events, read both payload formats, and recognise the auth header in the request. The open question is what happens when the receiver is down or unreachable, and how to find out why a webhook never arrived.

## Common pitfalls

> [!WARNING]
> - **Reading only the policy to check a webhook.** A policy can be correct and still fail to deliver. Watch the request arrive.
> - **Not checking the auth header in the receiver.** Without that check, anyone who can reach the endpoint can start your pipeline.
> - **Expecting the Default `type` in a CloudEvents consumer.** The event is `harbor.artifact.pushed` there, not `PUSH_ARTIFACT`.
> - **Leaving out flags on `harbor webhook create`.** It opens its interactive form and a script hangs.
> - **Forgetting the system-wide switch.** If webhooks are turned off in the system settings, no project policy sends anything.
