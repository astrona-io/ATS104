# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Automating Harbor with the harbor CLI

## Scenario

Every new team gets a Harbor project, a user for its developer, and a Developer membership. The platform team wants a script for this that the onboarding pipeline can run as often as it likes. Last month the team `team-red` was onboarded by hand: the project `team-red` and the user `red-dev` already exist, and `red-dev` is a Developer in `team-red`.

The CLI in the workstation pod is signed in as the administrator. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

## Your task

Write the script `/work/onboard.sh` in the workstation pod. It is called like this:

```sh
ONBOARD_PASSWORD='<password>' sh /work/onboard.sh <project> <username> <email>
```

and it must:

1. Create the project `<project>` as a **private** project, if it does not exist.
2. Create the local user `<username>` with the email `<email>` and the password from the environment variable `ONBOARD_PASSWORD`, if the user does not exist.
3. Add `<username>` to `<project>` with the role **Developer**, if the user is not a member yet.
4. Exit with code `0` when everything already exists, without creating anything twice.

## Constraints

- **Use the `harbor` CLI**, not `curl` or the REST API directly.
- The pipeline runs the script with no terminal and with standard input from `/dev/null`. No command may wait for input.
- Do not write any password into the script.
- Do not change `team-red` or `red-dev` by hand.

## Done when

- `ONBOARD_PASSWORD=Blue-Team-2026 sh /work/onboard.sh team-blue blue-dev blue-dev@example.com` exits with `0` and creates the private project `team-blue`, the user `blue-dev` and a Developer membership.
- Running the same command a second time also exits with `0`, and `blue-dev` is still a member of `team-blue` exactly once.
- Running the script for `team-red red-dev red-dev@example.com` exits with `0` and leaves `red-dev` a member of `team-red` exactly once.
