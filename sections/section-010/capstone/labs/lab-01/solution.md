# Solution: Repair An Onboarding Script That Breaks In CI

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things. First, the script holds no password, does not call `harbor login`, and selects the context `ci` with `harbor context switch`, and that context exists for `admin`. Second, two runs without a terminal and without an administrator password both exit with `0`. Third, all three teams are private projects with one Developer member each.

## Step 1: Read the script and reproduce the failure

Define the helper, read the script and the CSV file:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws cat /work/onboard-teams.sh
ws cat /work/teams.csv
```

Run it once the way CI does, with a time limit so it cannot hang your terminal:

```sh
ws sh -c 'ONBOARD_PASSWORD=Team-Pass-2026 timeout 60 sh /work/onboard-teams.sh </dev/null'; echo "exit $?"
```

It fails at the first line of the CSV, because `harbor project create team-red` refuses a project that exists, and `set -e` stops the script there. Before that, the script's first line signed in with the password written in the script, so the run also left a context `ci` in the CLI configuration file. Step 3 replaces that saved sign-in with one you make yourself.

## Step 2: List every fault before you change anything

Reading the script line by line gives six faults:

| Line | Fault | Effect |
| --- | --- | --- |
| `harbor login ... -p Harbor12345 -n ci` | Password and sign-in in the script | Anyone who reads the repository or the CI log has the administrator password |
| `harbor project create "$project" --public --storage-limit -1` | `--public` | The teams' projects are visible to every user |
| `harbor project create`, `user create`, `member create` | No check before create | The second run fails at the first object that exists |
| `harbor project member create "$project" --role Developers` | No `--username` | The CLI opens its interactive form to ask for the member, which hangs without a terminal |
| `--role Developers` | Role given by name | The CLI (version 0.0.27) ignores `--role` and opens its interactive form; give the role as a number with `--roleid 2` |
| `while read ...; do ... done < /work/teams.csv` | The loop's input is the CSV | Any command in the loop that reads standard input swallows the remaining lines, so later teams are skipped |

The last fault is the hardest to see. Inside the loop, every command inherits the loop's standard input, which is the CSV file. A command that reads its input, such as a CLI prompt, reads the next lines of the file, and the loop never sees them. The fix is to read the CSV on a separate file descriptor and give every command `/dev/null`.

The first fault cannot be fixed inside the script. In CLI v0.0.27, `harbor login --password-stdin` does not read a pipe: it shows a hidden `Password:` prompt and reads from a terminal. Without a terminal it fails with `failed to read password from stdin: inappropriate ioctl for device`. The CLI has no environment variable for the password either. So the sign-in moves out of the script: you sign in once, and the script selects the saved context.

## Step 3: Sign the CLI in once, at a terminal

Sign in as `admin` into the context `ci`. The `-t` flag gives the command a terminal, so the CLI can show its prompt. Type the lab-only password `Harbor12345` when it asks; the CLI does not show what you type:

```sh
kubectl -n workstation exec -it deploy/workstation -- harbor login https://harbor.localtest.me:8443 -u admin --password-stdin -n ci
```

The CLI checks the password against Harbor, encrypts it with `HARBOR_ENCRYPTION_KEY` and saves it under the name `ci`. A context `ci` already exists from Step 1, so the CLI prints a warning that the credentials exist and updates the saved password. Check the result:

```sh
ws harbor context list
```

The list shows `ci` for the user `admin` at `https://harbor.localtest.me:8443`, next to the context `admin`. You could also sign in with `-p Harbor12345` instead of `--password-stdin`. That works without a terminal, but it leaves the password in your shell history and shows it in the process list while the command runs, so keep it for a one-time setup step and never put it in the script.

## Step 4: Write the fixed script

Save this as `onboard-teams.sh` on your machine:

```sh
#!/bin/sh
# onboard-teams.sh: onboards every team listed in /work/teams.csv
# (project,username,email). The CI job runs it with no terminal attached.
# It uses the saved CLI context "ci" (the administrator), which a person
# created once at a terminal; the script itself holds no administrator
# password. ONBOARD_PASSWORD is the password for new users.
# Safe to run again: it creates only what is missing.
set -eu
: "${ONBOARD_PASSWORD:?set ONBOARD_PASSWORD}"

harbor context switch ci </dev/null

# The CSV is read on file descriptor 3, and every harbor command reads
# /dev/null, so no command can swallow the lines that are still to come.
while IFS=, read -r project username email <&3; do
  [ -n "$project" ] || continue
  if ! harbor project view "$project" -o json </dev/null >/dev/null 2>&1; then
    harbor project create "$project" --storage-limit -1 </dev/null
  fi
  if ! harbor user list --page-size 0 -o json </dev/null \
      | jq -e --arg u "$username" '[.. | objects | select(.username? == $u)] | length > 0' >/dev/null; then
    harbor user create --username "$username" --email "$email" --realname "$username" \
      --password "$ONBOARD_PASSWORD" </dev/null
  fi
  if ! harbor project member list "$project" --page-size 100 -o json </dev/null \
      | jq -e --arg u "$username" '[.. | objects | select(.entity_name? == $u)] | length > 0' >/dev/null; then
    harbor project member create "$project" --username "$username" --roleid 2 </dev/null
  fi
  echo "onboarded $project"
done 3< /work/teams.csv
```

`harbor context switch ci` makes `ci` the current context. It needs no password and no terminal, and it fails at once if the context does not exist, so `set -e` stops the script before it does anything as the wrong user. `read ... <&3` and `done 3< /work/teams.csv` read the CSV on file descriptor 3, so no command in the loop can reach it. Every check follows the pattern for an idempotent script: an exit code for the one project, JSON and `jq -e` for the lists. `--storage-limit -1` sets no storage limit; without the flag, `harbor project create` opens its interactive form, which fails without a terminal.

Copy it into the workstation pod:

```sh
ws sh -c 'cat > /work/onboard-teams.sh' < onboard-teams.sh
```

## Step 5: Run it twice and check the result

Make another context current first, so the runs prove that the script selects `ci` itself. Then run the script twice the way CI does:

```sh
ws harbor context switch admin </dev/null
ws sh -c 'ONBOARD_PASSWORD=Team-Pass-2026 sh /work/onboard-teams.sh </dev/null'; echo "exit $?"
ws sh -c 'ONBOARD_PASSWORD=Team-Pass-2026 sh /work/onboard-teams.sh </dev/null'; echo "exit $?"
```

Both runs print `onboarded` for each of the three projects and exit with `0`. No administrator password appears anywhere in these commands. The new users' password is on your command line here only as a stand-in for the CI system's secret store.

Check the projects and members:

```sh
ws harbor project list </dev/null
ws harbor project member list team-gold </dev/null
```

The three team projects show as private, and `gold-dev` is a member of `team-gold` once, with the role Developer. The same holds for the other two teams.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add `|| true` after every create | The second run passes, but a wrong role name or a refused password is hidden too |
| Run the script with `kubectl exec -it` | It works for you, but CI has no terminal; the prompt is still there |
| Pipe `HARBOR_PASSWORD` into `harbor login --password-stdin` in the script | In CLI v0.0.27 the flag reads from a terminal only; without one the login fails with `inappropriate ioctl for device` |
| Keep `harbor login -p "$HARBOR_PASSWORD"` in the script | The password shows in the process list and possibly in the CI log, and every run needs it; the grader rejects any `harbor login` in the script |
| Make the projects private by hand afterwards | The next team the script onboards is public again |

## Common mistakes

- Fixing the role name but not adding `--username`, so the command still opens its form.
- Fixing the checks but not the loop's input, so only some teams are onboarded.
- Leaving `--public` in place because the task's scenario does not repeat it.
- Removing the `harbor login` line but not adding `harbor context switch ci`, so the script runs as whichever context happens to be current.
