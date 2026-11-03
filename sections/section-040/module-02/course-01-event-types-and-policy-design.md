# Event Types And Policy Design

A policy that listens to every event sends a lot of requests that nobody reads. A policy that listens to the wrong event sends nothing when it matters. This part lists the events, asks Harbor which ones the project supports, and gives a way to choose.

## The events of a project

Each event type has a name for the policy and a `type` value in the CloudEvents payload.

| Event type in a policy | CloudEvents `type` | When it fires |
| --- | --- | --- |
| `PUSH_ARTIFACT` | `harbor.artifact.pushed` | An artifact is pushed |
| `PULL_ARTIFACT` | `harbor.artifact.pulled` | An artifact is pulled |
| `DELETE_ARTIFACT` | `harbor.artifact.deleted` | An artifact is deleted |
| `SCANNING_COMPLETED` | `harbor.scan.completed` | A scan finishes |
| `SCANNING_FAILED` | `harbor.scan.failed` | A scan fails |
| `QUOTA_EXCEED` | `harbor.quota.exceeded` | A push would exceed the project quota |
| `QUOTA_WARNING` | `harbor.quota.warning` | The use of the quota nears its limit |
| `REPLICATION` | `harbor.replication.status.changed` | A replication finishes |
| `TAG_RETENTION` | `harbor.tag.retention` | A retention run finishes |

Ask Harbor which events and notify types your version supports instead of trusting a table from a document:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/webhook/events" | jq'
```

The answer holds `event_type` values and `notify_type` values, such as `http` and `slack`. The list depends on the version, so a script that builds policies reads it first.

## Choosing events for a job

Start from the question the receiver must answer.

| The receiver must know | Events |
| --- | --- |
| A new build exists | `PUSH_ARTIFACT` |
| The build is safe to deploy | `SCANNING_COMPLETED`, and `SCANNING_FAILED` for the alert |
| Something was removed | `DELETE_ARTIFACT` |
| The project is running out of space | `QUOTA_WARNING`, `QUOTA_EXCEED` |
| A copy reached another registry | `REPLICATION` |

`PULL_ARTIFACT` fires for every pull, and a busy cluster pulls all day. Choose it only when a receiver really needs each pull, for example for usage counting, and give that receiver its own policy so a flood does not hide the other events.

## One policy or several

A policy can hold several event types and several targets. A single policy for a single purpose is easier to read, disable and delete. Name the policy for its purpose, such as `notify-ci` or `audit-deletes`, and put the owner and the reason in the description. Use a second policy when the target, the auth header or the payload format differs, because those belong to the target and not to the event.

Harbor does not limit the policies of a project to a small number in ordinary use, but each policy adds a delivery for every matching event. Ten policies on `PUSH_ARTIFACT` mean ten requests for every push.

## Scope

A policy belongs to one project. An event in another project never reaches it. To get events from many projects, create a policy in each, and do it in a script, so that a new project is not forgotten. Harbor also has a system-level setting for some notifications, but the project policy is the one a team controls.

## The two notify types

The `http` type sends the payload to an address, with an optional auth header and the choice of Default or CloudEvents. The `slack` type sends a message to a Slack incoming webhook address. Slack has its own format, so the payload format choice does not apply to it. Use `http` for a service and `slack` for a person.

You can now choose events and see which ones your Harbor supports. The next part manages the policies after they are created.

## Common pitfalls

> [!WARNING]
> - **Selecting every event.** The receiver gets requests it never reads. Select what the job needs.
> - **Putting `PULL_ARTIFACT` in a shared policy.** One busy cluster can bury the rest. Give it a policy of its own.
> - **Copying the event table from an old document.** Read `/webhook/events` for the version you run.
> - **Forgetting new projects.** A policy covers its own project only. Create policies in a script.
