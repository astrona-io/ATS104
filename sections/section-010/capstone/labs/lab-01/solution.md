# Solution: Repair An Onboarding Script That Breaks In CI

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the script holds no password and signs in with `--password-stdin`, two runs without a terminal both exit with `0`, and all three teams are private projects with one Developer member each.

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

It fails at the first line of the CSV, because `harbor project create team-red` refuses a project that exists, and `set -e` stops the script there.

## Step 2: List every fault before you change anything

Reading the script line by line gives six faults:

| Line | Fault | Effect |
| --- | --- | --- |
| `harbor login ... -p Harbor12345` | Password in the script | Anyone who reads the repository or the CI log has the administrator password |
| `harbor project create "$project" --public` | `--public` | The teams' projects are visible to every user |
| `harbor project create`, `user create`, `member create` | No check before create | The second run fails at the first object that exists |
| `harbor project member create "$project" --role Developers` | No `--username` | The CLI opens its interactive form to ask for the member, which hangs without a terminal |
| `--role Developers` | Wrong role name | The CLI accepts `Developer`, not `Developers` |
| `while read ...; do ... done < /work/teams.csv` | The loop's input is the CSV | Any command in the loop that reads standard input swallows the remaining lines, so later teams are skipped |

The last fault is the hardest to see. Inside the loop, every command inherits the loop's standard input, which is the CSV file. A command that reads its input, such as a CLI prompt, reads the next lines of the file, and the loop never sees them. The fix is to read the CSV on a separate file descriptor and give every command `/dev/null`.

## Step 3: Write the fixed script

Save this as `onboard-teams.sh` on your machine:

```sh
#!/bin/sh
# onboard-teams.sh: onboards every team listed in /work/teams.csv
# (project,username,email). The CI job runs it with no terminal attached.
# HARBOR_PASSWORD is the administrator password, ONBOARD_PASSWORD the
# password for new users. Safe to run again: it creates only what is missing.
set -eu
: "${HARBOR_PASSWORD:?set HARBOR_PASSWORD}"
: "${ONBOARD_PASSWORD:?set ONBOARD_PASSWORD}"

printf '%s' "$HARBOR_PASSWORD" \
  | harbor login https://harbor.localtest.me:8443 -u admin --password-stdin -n ci >/dev/null 2>&1 \
  || harbor context switch ci </dev/null >/dev/null

# The CSV is read on file descriptor 3, and every harbor command reads
# /dev/null, so no command can swallow the lines that are still to come.
while IFS=, read -r project username email <&3; do
  [ -n "$project" ] || continue
  if ! harbor project view "$project" </dev/null >/dev/null 2>&1; then
    harbor project create "$project" </dev/null
  fi
  if ! harbor user list --page-size 0 -o json </dev/null \
      | jq -e --arg u "$username" '[.. | objects | select(.username? == $u)] | length > 0' >/dev/null; then
    harbor user create --username "$username" --email "$email" --realname "$username" \
      --password "$ONBOARD_PASSWORD" </dev/null
  fi
  if ! harbor project member list "$project" --page-size 100 -o json </dev/null \
      | jq -e --arg u "$username" '[.. | objects | select(.entity_name? == $u)] | length > 0' >/dev/null; then
    harbor project member create "$project" --username "$username" --role Developer </dev/null
  fi
  echo "onboarded $project"
done 3< /work/teams.csv
```

`read ... <&3` and `done 3< /work/teams.csv` read the CSV on file descriptor 3, so no command in the loop can reach it. Every check follows the pattern for an idempotent script: an exit code for the one project, JSON and `jq -e` for the lists. The login line falls back to `harbor context switch ci` in case the CLI refuses to log in again into a context name that already exists.

Copy it into the workstation pod:

```sh
ws sh -c 'cat > /work/onboard-teams.sh' < onboard-teams.sh
```

## Step 4: Run it twice and check the result

```sh
ws sh -c 'HARBOR_PASSWORD=Harbor12345 ONBOARD_PASSWORD=Team-Pass-2026 sh /work/onboard-teams.sh </dev/null'; echo "exit $?"
ws sh -c 'HARBOR_PASSWORD=Harbor12345 ONBOARD_PASSWORD=Team-Pass-2026 sh /work/onboard-teams.sh </dev/null'; echo "exit $?"
```

Both runs print `onboarded` for each of the three projects and exit with `0`. The administrator password appears only in your command line here, as a stand-in for the CI system's secret store; it is not in the script.

Check the projects and members:

```sh
ws harbor project list </dev/null
ws harbor project member list team-gold </dev/null
```

The three team projects show as private, and `gold-dev` is a member of `team-gold` once, with the role Developer. The same holds for the other two teams.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Add `|| true` after every create | The second run passes, but a wrong role name or a refused password is hidden too |
| Run the script with `kubectl exec -it` | It works for you, but CI has no terminal; the prompt is still there |
| Keep `-p` but read the password from a variable | The password still appears in the process list and possibly in the CI log; `--password-stdin` does not put it on the command line |
| Make the projects private by hand afterwards | The next team the script onboards is public again |

## Common mistakes

- Fixing the role name but not adding `--username`, so the command still opens its form.
- Fixing the checks but not the loop's input, so only some teams are onboarded.
- Leaving `--public` in place because the task's scenario does not repeat it.
