# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Automating Harbor with the harbor CLI

## Scenario

A CI job onboards new teams from the file `/work/teams.csv` with the script `/work/onboard-teams.sh`. Each line of the file is `project,username,email`. A developer wrote the script on a laptop and says it worked there. In CI it hangs until the job times out. When someone fixed that by hand and ran it again, it failed at the first project. The security team also found the administrator password in the script, and the teams' projects came out public.

Both files are in the workstation pod. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

The project `team-red` and its developer `red-dev` were onboarded by hand last month.

## Your task

Fix `/work/onboard-teams.sh` so that the CI job can run it like this, as often as it likes:

```sh
HARBOR_PASSWORD='<admin password>' ONBOARD_PASSWORD='<new user password>' sh /work/onboard-teams.sh </dev/null
```

For every line of `/work/teams.csv`, the script must make sure the project exists and is **private**, the user exists, and the user is a member of the project with the role **Developer**. Then run it.

## Constraints

- Keep the file name `/work/onboard-teams.sh` and keep using the `harbor` CLI.
- **No password in the script.** Sign the CLI in with the administrator password from `HARBOR_PASSWORD`, read through `--password-stdin`. New users get the password from `ONBOARD_PASSWORD`.
- No command may wait for input: the script runs with no terminal.
- Do not change `/work/teams.csv`, and do not create the projects, users or memberships by hand.

## Done when

- `/work/onboard-teams.sh` contains no password and signs in with `--password-stdin`.
- Two runs in a row, with no terminal, both exit with `0`.
- `team-red`, `team-green` and `team-gold` are private projects, and each has its developer as a member exactly once, with the role Developer.
