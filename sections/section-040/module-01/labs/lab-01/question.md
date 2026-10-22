# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Webhooks for pipelines

## Scenario

The deploy pipeline should start as soon as a new artifact lands in the project `inventory`, instead of checking Harbor every few minutes. The pipeline listens at `http://echo.hooks.svc.cluster.local:8080/harbor`, and it accepts only requests with the header `Authorization: Bearer pipeline-token-123`. In this lab, the receiver `echo` in the namespace `hooks` stands in for the pipeline and logs every request it gets.

The workstation pod has the `harbor` CLI and `oras`, both signed in as the administrator, plus `curl` and `jq`. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

## Your task

Create a webhook policy named `notify-ci` in the project `inventory` that:

1. Is enabled and fires on **`PUSH_ARTIFACT`** only.
2. Uses the notify type `http` and the endpoint `http://echo.hooks.svc.cluster.local:8080/harbor`.
3. Sends the auth header `Bearer pipeline-token-123`.
4. Uses the **Default** payload format.

Then push an artifact into `inventory` and confirm the receiver got the event.

## Constraints

- One policy named `notify-ci` with one target.
- Do not change the receiver or the system-wide webhook setting.

## Done when

- The policy `notify-ci` matches every point above.
- When an artifact is pushed into `inventory`, the receiver logs a `PUSH_ARTIFACT` event for it with the auth header.
