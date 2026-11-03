# Retries, Receivers And CI Systems

A webhook is delivered at least once, not exactly once. When the receiver is slow or fails, `jobservice` sends the request again, and the same event can reach the pipeline twice. A receiver that starts a build for every request then starts it twice. This part explains the retry settings, shows how to write a receiver that tolerates repeats, and connects Harbor to Jenkins and GitHub Actions.

## Retries and timeouts

`jobservice` retries a failed webhook a limited number of times, with a timeout for each request. Both are set when Harbor is installed. With the `harbor-helm` chart they are `jobservice.notification.webhook_job_max_retry` and `jobservice.notification.webhook_job_http_client_timeout` (in seconds); with the Docker Compose installer they sit under `notification:` in `harbor.yml`. The documentation's example uses 3 retries and a 3-second timeout. More retries mean more load on the job queue, and a slow receiver should answer at once and do its work afterwards instead of raising the timeout.

## What a good receiver does

A receiver has four jobs, and the order matters. First it checks the `Authorization` header against the value stored in the policy, and answers `401` when it does not match, so a stranger cannot start the pipeline. Second it answers with a `2xx` status at once, before it does any work, so `jobservice` sees a success and does not retry. Third it puts the work on a queue or starts the build in the background. Fourth it ignores events it has already handled.

The fourth job needs a key that identifies an event. For a Default payload, the pushed artifact's `digest` together with the repository name is a good key. In a CloudEvents payload, the field `id` identifies the event. A receiver that remembers recent keys can drop a repeat. Without it, one lost response can start the same deployment twice.

## Connecting to CI systems

A CI system receives Harbor's webhook in one of two ways.

Jenkins, with the Generic Webhook Trigger plugin, accepts any JSON POST at `/generic-webhook-trigger/invoke` and maps fields of the body into job variables with JSONPath expressions, for example `$.event_data.resources[0].resource_url` from a Default payload. A token in the URL or a header selects the job. Harbor's endpoint is then the Jenkins URL, and the auth header can carry the token.

GitHub Actions starts a workflow on a `repository_dispatch` event, which GitHub accepts only in its own format, `{"event_type": "...", "client_payload": {...}}`, with a GitHub token. Harbor's payload does not have that shape, so a small relay sits between them: it receives Harbor's webhook, checks the auth header, and calls GitHub's API with the artifact's details in `client_payload`. The workflow then reads them:

```yaml
on:
  repository_dispatch:
    types: [harbor-artifact-pushed]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying ${{ github.event.client_payload.resource_url }}"
```

The same relay pattern works for any system that wants its own request format: Harbor sends one well-known payload, and a small piece of code translates it.

You now know how many times `jobservice` tries and why a receiver must answer first and work afterwards, how it can drop repeated events, and how Jenkins and GitHub Actions receive the call, either directly or through a relay.

## Common pitfalls

> [!WARNING]
> - **A receiver that does its work before answering.** It times out, `jobservice` retries, and the pipeline starts twice. Answer at once, then work.
> - **Treating every request as a new event.** Retries repeat events. Keep a key for each handled event and drop repeats.
> - **Pointing Harbor straight at GitHub's dispatch API.** The payload has the wrong shape. Use a relay.
> - **Raising the timeout to fix a slow receiver.** It only moves the problem. Make the receiver answer faster.
