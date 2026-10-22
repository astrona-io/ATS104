# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Robot accounts for CI

## Scenario

The deploy jobs pull artifacts from the project `inventory` with the robot account `robot$inventory+deployer`. During an audit, its name and secret turned up in the ConfigMap `leaked-credentials` in the namespace `workstation`, which many teams can read. The audit also found that the robot can push and delete as well as pull, and that it never expires.

The deploy jobs refer to the robot by its name and its ID, so the robot must stay the same account.

The workstation pod has the `harbor` CLI (signed in as the administrator), `oras`, `curl` and `jq`. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

## Your task

1. Make the leaked secret stop working.
2. Cut the robot's permissions down to what deploying needs: `repository` `pull` on `inventory`, and nothing else.
3. Make the robot expire after **90 days**.
4. Store the robot's full name and its new secret in a new Kubernetes Secret `deployer-robot` in the namespace `workstation`, with the keys `username` and `password`.

## Constraints

- **Do not delete and recreate the robot.** Its ID must stay the same.
- Do not give the robot any permission outside `inventory`.
- Leave the ConfigMap `leaked-credentials` in place; the security team wants to keep it as evidence.

## Done when

- `robot$inventory+deployer` has its original ID.
- Its only permission is `repository` `pull` on `inventory`, and its duration is 90 days.
- The secret in `leaked-credentials` no longer signs in.
- The credentials in `deployer-robot` pull `inventory/notes:v1`, and a push to `inventory` with them is refused.
