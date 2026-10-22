# Summary

A webhook lets Harbor start a pipeline the moment something happens in a project. This module showed how to set one up and how to prove and debug its delivery.

## What you learned

A webhook policy belongs to one project. It has event types, an on or off switch and a target: a notify type (`http` or `slack`), an endpoint, an optional auth header, a certificate verification switch, and for HTTP a payload format. A system administrator can turn webhooks off for the whole Harbor in the system settings. `harbor webhook create` creates a policy when every flag is given; `POST /api/v2.0/projects/<project>/webhook/policies` does the same through the REST API.

The event types follow the artifact and the project: `PUSH_ARTIFACT`, `PULL_ARTIFACT`, `DELETE_ARTIFACT`, the scan events, the quota events, `REPLICATION` and `TAG_RETENTION`. The Default payload has `type`, `occur_at`, `operator` and `event_data` with the `resources` (digest, tag, `resource_url`) and the `repository`. The CloudEvents payload follows the CNCF CloudEvents specification: `specversion`, `id`, `source`, `type` such as `harbor.artifact.pushed`, `time`, and the same event data under `data`. The auth header is sent as the `Authorization` header so the receiver can check the sender.

`core` records the event and `jobservice` sends the webhook in the background, so a push never fails because of a webhook. `jobservice` retries failed deliveries a limited number of times, set by `webhook_job_max_retry` and `webhook_job_http_client_timeout`. Each attempt is an execution of the policy with a task and a task log, which the project's Webhooks tab and the API show. An HTTPS endpoint with a certificate Harbor does not trust fails in the TLS handshake; the fixes are a trusted certificate or a cluster-internal HTTP endpoint, and skipping verification sends the auth header to whoever answers.

Jenkins can take Harbor's JSON directly through a generic webhook trigger and map fields with JSONPath. GitHub Actions needs a small relay that turns Harbor's payload into a `repository_dispatch` request. The key facts to remember are these:

- Prove a webhook by watching it arrive, not by reading the policy.
- `jobservice` delivers and retries; its execution and task logs say why a delivery failed.
- Default and CloudEvents carry the same event data in different shapes.
- Check the auth header in every receiver.

<!-- astrona:playground:destroy -->
