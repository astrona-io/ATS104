# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Automating Harbor with the harbor CLI

## Scenario

A CI job onboards new teams from the file `/work/teams.csv` with the script `/work/onboard-teams.sh`. Each line of the file is `project,username,email`. A developer wrote the script on a laptop and says it worked there. In CI it hangs until the job times out. When someone fixed that by hand and ran it again, it failed at the first project. The security team also found the administrator password in the script, and the teams' projects came out public.

Both files are in the workstation pod. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

Add `-t` (`kubectl -n workstation exec -it ...`) when a command needs a terminal, for example to type a password at a prompt.

The project `team-red` and its developer `red-dev` were onboarded by hand last month.

## Your task

Fix `/work/onboard-teams.sh` so that the CI job can run it like this, as often as it likes:

```sh
ONBOARD_PASSWORD='<new user password>' sh /work/onboard-teams.sh </dev/null
```

The CI job gives the script no administrator password. The `harbor` CLI in the workstation pod must already hold a saved sign-in (a context) named `ci` for the administrator `admin`, and the script uses that context. In CLI v0.0.27, `harbor login --password-stdin` shows a hidden `Password:` prompt on a terminal and cannot read a password from a pipe, so the sign-in is a step a person does once, not a line in the script.

For every line of `/work/teams.csv`, the script must make sure the project exists and is **private**, the user exists, and the user is a member of the project with the role **Developer**. Then run it.

## Constraints

- Keep the file name `/work/onboard-teams.sh` and keep using the `harbor` CLI.
- **No password and no sign-in in the script.** The script must not call `harbor login`. Sign the CLI in once yourself, at a terminal, as `admin` into the context `ci`. The script selects that context with `harbor context switch ci`. New users get the password from `ONBOARD_PASSWORD`.
- No command may wait for input: the script runs with no terminal.
- Do not change `/work/teams.csv`, and do not create the projects, users or memberships by hand.

## Done when

- `/work/onboard-teams.sh` contains no password, does not call `harbor login`, and runs `harbor context switch ci`.
- The CLI in the workstation pod has a context `ci` for the user `admin`.
- Two runs in a row, with no terminal, no input and no administrator password, both exit with `0`, even when another context is current before the first run.
- `team-red`, `team-green` and `team-gold` are private projects, and each has its developer as a member exactly once, with the role Developer.
