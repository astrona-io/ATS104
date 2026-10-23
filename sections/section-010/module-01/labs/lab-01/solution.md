# Solution: Write An Idempotent Onboarding Script

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the script exists and uses the CLI, a first run for `team-blue` creates everything, a second run succeeds without duplicates, and a run for the existing `team-red` succeeds. It runs the script with no terminal, standard input from `/dev/null` and a time limit.

## Step 1: Look at the starting state

Define the helper and look at what exists:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws harbor project list </dev/null
ws harbor project member list team-red </dev/null
```

The project list shows `library`, `team-red` and no `team-blue`. The members of `team-red` are the administrator and `red-dev` with the role Developer. A script that creates blindly would fail for `team-red` at the first step.

## Step 2: Decide how to check each object

Each of the three objects needs a check that a script can trust:

| Object | Check | Create |
| --- | --- | --- |
| Project | exit code of `harbor project view <project> -o json` (without `-o json` the CLI draws a table and fails without a terminal) | `harbor project create <project> --storage-limit -1` (private without `--public`; without `--storage-limit` the CLI opens its interactive form) |
| User | `harbor user list --page-size 0 -o json`, then `jq -e` on the field `username` | `harbor user create --username ... --email ... --realname ... --password "$ONBOARD_PASSWORD"` |
| Membership | `harbor project member list <project> -o json`, then `jq -e` on the field `entity_name` | `harbor project member create <project> --username ... --roleid 2` |

The list commands succeed whether or not the name is there, so their JSON is the answer, not their exit code. `--page-size 0` makes `harbor user list` return every user, not only the first page.

## Step 3: Write the script

Save this as `onboard.sh` on your machine:

```sh
#!/bin/sh
# onboard.sh PROJECT USERNAME EMAIL
# Creates a private project, a local user and a Developer membership, each
# only if it does not exist yet, so the script can run again safely.
# The new user's password comes from the variable ONBOARD_PASSWORD.
set -eu
project="$1"
username="$2"
email="$3"
: "${ONBOARD_PASSWORD:?set ONBOARD_PASSWORD to the password for the new user}"

if harbor project view "$project" -o json </dev/null >/dev/null 2>&1; then
  echo "project $project exists"
else
  harbor project create "$project" --storage-limit -1 </dev/null
  echo "project $project created"
fi

if harbor user list --page-size 0 -o json </dev/null \
    | jq -e --arg u "$username" '[.. | objects | select(.username? == $u)] | length > 0' >/dev/null; then
  echo "user $username exists"
else
  harbor user create --username "$username" --email "$email" --realname "$username" \
    --password "$ONBOARD_PASSWORD" </dev/null
  echo "user $username created"
fi

if harbor project member list "$project" --page-size 100 -o json </dev/null \
    | jq -e --arg u "$username" '[.. | objects | select(.entity_name? == $u)] | length > 0' >/dev/null; then
  echo "$username is already a member of $project"
else
  harbor project member create "$project" --username "$username" --roleid 2 </dev/null
  echo "$username added to $project as Developer"
fi
```

The password reaches `harbor user create` through the variable `ONBOARD_PASSWORD`, which the pipeline fills from its secret store; the script itself holds no password. `: "${ONBOARD_PASSWORD:?...}"` stops the script with a clear message when the variable is missing.

Copy it into the workstation pod:

```sh
ws sh -c 'cat > /work/onboard.sh' < onboard.sh
```

## Step 4: Run it twice, the way the pipeline does

Run it for the new team, with no terminal:

```sh
ws sh -c 'ONBOARD_PASSWORD=Blue-Team-2026 sh /work/onboard.sh team-blue blue-dev blue-dev@example.com </dev/null'; echo "exit $?"
```

The script prints that it created the project, the user and the membership, and the exit code is `0`. Run exactly the same command again: it prints that each object exists, and the exit code is still `0`. Then run it for the team that was onboarded by hand:

```sh
ws sh -c 'ONBOARD_PASSWORD=Red-Team-2026 sh /work/onboard.sh team-red red-dev red-dev@example.com </dev/null'; echo "exit $?"
```

It finds everything and exits with `0`. Check that nothing was doubled:

```sh
ws harbor project member list team-blue </dev/null
ws harbor project member list team-red </dev/null
```

Each list shows its developer once, with the role Developer.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create everything and add `|| true` | Real errors (a wrong role name, a password Harbor refuses) are hidden too, and the script reports success |
| Check the exit code of `member list` or `user list` | They succeed either way, so the script always skips or always creates |
| Match names with `grep` | `red-dev` also matches `red-dev2`; compare the exact field with `jq` |
| Use `curl` against the API | The task asks for the CLI; the grader rejects `curl` |

## Common mistakes

- Leaving out an argument, so a command opens its interactive form and the run times out.
- Writing the password into the script instead of reading `ONBOARD_PASSWORD`.
- Forgetting `--page-size 0` on `user list`, so a user on the second page looks missing and the script tries to create it again.

## Practice on your own

- Add an optional fourth argument for the role, and refuse any value that is not one of the CLI's role names.
- Make the script print one JSON line per object (`created` or `exists`) so a pipeline can log it.
