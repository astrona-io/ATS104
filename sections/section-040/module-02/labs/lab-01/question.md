# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Webhooks for auditing

## Scenario

The security team keeps an audit service that records every deleted artifact. It already reads events in the CloudEvents format, and it accepts only requests with the header `Authorization: Bearer audit-token-456`. It listens at `http://echo.hooks.svc.cluster.local:8080/audit`. In this lab, the receiver `echo` in the namespace `hooks` stands in for the audit service and logs every request it gets. Harbor should tell it about deletions in the project `inventory` and about nothing else.

The workstation pod has the `harbor` CLI and `oras`, both signed in as the administrator, plus `curl` and `jq`. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

## Your task

Create a webhook policy named `audit-deletes` in the project `inventory` that:

1. Is enabled and fires on **`DELETE_ARTIFACT`** only.
2. Uses the notify type `http` and the endpoint `http://echo.hooks.svc.cluster.local:8080/audit`.
3. Sends the auth header `Bearer audit-token-456`.
4. Uses the **CloudEvents** payload format.

Then push an artifact into `inventory`, delete it, and confirm the receiver got the event.

## Constraints

- Do not change the project or its artifacts, except for the artifacts you push and delete to test.
- Do not add other event types to the policy.
- Leave the policy enabled.

## Done when

- A policy `audit-deletes` exists in `inventory`, is enabled and fires on `DELETE_ARTIFACT` only.
- Its single target is of type `http` with the endpoint above, the auth header above and the CloudEvents payload format.
- Deleting an artifact in `inventory` makes the receiver log a `harbor.artifact.deleted` event that carries the auth header.
