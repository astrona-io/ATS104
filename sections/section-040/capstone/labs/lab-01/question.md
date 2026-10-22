# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** Webhooks for pipelines

## Scenario

A new CI project `ci` was set up in a hurry before a release. Two things are supposed to work and neither does:

- The CI job pushes to `ci` with the robot account `robot$ci+builder`, whose credentials are in the Kubernetes Secret `ci-robot` in the namespace `workstation`. Its pushes are refused.
- The webhook policy `notify-ci` in `ci` should tell the pipeline about every push. The pipeline never hears anything.

The pipeline listens at the receiver `echo` in the namespace `hooks` (HTTP on `http://echo.hooks.svc.cluster.local:8080`, HTTPS with a self-signed certificate on port `8443`). It accepts only requests with the header `Authorization: Bearer pipeline-token-123`, and it reads **CloudEvents**.

The workstation pod has the `harbor` CLI and `oras` (both signed in as the administrator), `curl` and `jq`. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

## Your task

Make a push to `ci` by `robot$ci+builder`, with the credentials in `ci-robot`, succeed and reach the pipeline as a CloudEvent with the auth header.

## Constraints

- **Do not delete and recreate** the robot `robot$ci+builder` or the policy `notify-ci`; change them in place. Other jobs refer to their IDs.
- Give the robot only what pushing needs: `repository` push and pull on `ci`.
- The policy fires on `PUSH_ARTIFACT` only and uses the CloudEvents format.
- Keep the robot's secret as it is, so the Secret `ci-robot` stays valid.

## Done when

- `robot$ci+builder` and `notify-ci` have their original IDs.
- `notify-ci` is enabled, fires on `PUSH_ARTIFACT` only, and uses the CloudEvents payload with the auth header.
- A push to `ci` with the credentials in `ci-robot` succeeds, and the receiver logs a `harbor.artifact.pushed` event for it with the auth header.
