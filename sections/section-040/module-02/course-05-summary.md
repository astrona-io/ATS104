# Summary: Receivers, Events And Troubleshooting

This module chose events, managed policies, wrote a receiver and traced missing webhooks.

## What to remember

- A policy lists event types such as `PUSH_ARTIFACT`, `DELETE_ARTIFACT` and `SCANNING_COMPLETED`. In CloudEvents the same events have names such as `harbor.artifact.deleted`.
- Read `/projects/{p}/webhook/events` to see what your Harbor supports. Choose the smallest set for the job, and keep `PULL_ARTIFACT` in a policy of its own.
- A policy belongs to one project. Create policies in a script so a new project is not forgotten.
- `POST` creates and answers `201`, a repeat answers `409`. `PUT` replaces the whole policy, so read, edit and send. Set `enabled` to false to pause and keep the settings.
- `POST /webhook/policies/test` checks a target before an event happens. `GET /webhook/lasttrigger` shows when each event last fired.
- A receiver checks the auth header, answers `2xx` before it does the work, and ignores a repeated event. Use `401` for a wrong header and `503` for a temporary failure.
- Trace a missing webhook along the path: the event, the policy, the delivery, the network, the receiver.
- The request is sent from the cluster, so test the address from inside it.

## Commands you should know

| Task | Request |
| --- | --- |
| List supported events | `GET /projects/{p}/webhook/events` |
| List policies | `GET /projects/{p}/webhook/policies` |
| Test a target | `POST /projects/{p}/webhook/policies/test` |
| Pause a policy | `PUT /projects/{p}/webhook/policies/{id}` with `enabled` false |
| Read last triggers | `GET /projects/{p}/webhook/lasttrigger` |
| Read deliveries | `GET /projects/{p}/webhook/policies/{id}/executions` |

## Clean up

If you started the playground for this module, you can remove it now:

<!-- astrona:playground:destroy -->
