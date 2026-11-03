# Receivers, Events And Troubleshooting

The first module of this section created webhook policies, compared the Default and CloudEvents payloads, read a failed delivery and looked at retries. This module goes further on three fronts: which events a policy should listen for, how to manage policies once they exist, and how to write and debug the receiver on the other side.

Keep one sentence in mind: **a webhook has two ends, and most failures are on the end Harbor cannot see.**

The module has four parts. **Event Types And Policy Design** lists the events a project can send and how to choose them. **Managing Policies With The REST API** lists, tests, updates, disables and deletes policies and reads the last trigger of each event. **Writing A Receiver** builds a small receiver in Python that checks the auth header, answers fast and ignores duplicates. **Troubleshooting A Webhook That Does Not Arrive** follows a checklist from the event to the receiver. A graded lab follows the last part.

## Learning objectives

After this module you can:

- Name the events a Harbor project can send and choose the smallest set for a job.
- Read the supported events and notify types from the API.
- List, test, update, disable and delete a policy through the REST API.
- Read the last trigger time of each event type.
- Write a receiver that checks the auth header, answers with a `2xx` status before it works, and ignores a repeated event.
- Walk a missing webhook through a checklist and find the cause.

## Before you start

You should have finished the first module of this section: policies, targets, the Default and CloudEvents payloads, executions and task logs, and retries.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. You work in the **`workstation`** pod in the namespace `workstation`. A receiver, `echo` in the namespace `hooks`, answers every request with `200` and logs it.

| In Harbor | What it is |
| --- | --- |
| Project `inventory` | Holds the artifact `inventory/notes:v1` |
| Receiver `echo` | `http://echo.hooks.svc.cluster.local:8080` |

Define the helpers once in each terminal:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
receiver_log() { kubectl -n hooks logs deploy/echo --since=10m; }
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
