# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Robot accounts for CI

## Scenario

The CI pipeline builds artifacts and pushes them to the project `ci`. Today it signs in as the administrator. The security team wants it to use a robot account that can push to `ci` and do nothing else, and whose secret stops working after a month unless someone renews it. The pipeline reads its registry credentials from a Kubernetes Secret.

The workstation pod has the `harbor` CLI (signed in as the administrator), `oras`, `curl` and `jq`. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

## Your task

1. Create a **project robot** named `builder` in the project `ci`, so its full name is `robot$ci+builder`.
2. Give it exactly these permissions in `ci`: `repository` `push` and `repository` `pull`. Nothing else, and no other project.
3. Make it expire after **30 days**.
4. Create the Kubernetes Secret `ci-robot` in the namespace `workstation`, with the key `username` set to the robot's full name and the key `password` set to its secret.

## Constraints

- Do not use `--all-permission` or give the robot any permission it does not need.
- Do not write the robot's secret anywhere except the Secret `ci-robot`.
- Do not change the projects `ci` or `inventory`.

## Done when

- `robot$ci+builder` is a project robot with only `repository` push and pull on `ci`, a duration of 30 days, and is enabled.
- With the credentials in `ci-robot`, a push to `ci` succeeds.
- With the same credentials, a push to `inventory` is refused.
