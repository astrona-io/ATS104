# Solution: Promote A Build With Tags

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the script exists and uses the CLI, a run for `team-red/app build-42` leaves the right tags, a second run succeeds and changes nothing, and a run for `team-red/api build-7` works too. It runs the script with no terminal, standard input from `/dev/null` and a time limit.

## Step 1: Look at the starting state

Define the helpers and look at the artifacts:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
wst harbor artifact list team-red/app
wst harbor artifact list team-red/api
```

The `harbor` CLI (version 0.0.27) draws lists as a table only on a terminal, so these commands run through `wst`. The list for `app` shows two artifacts. One has the tags `build-42` and `tmp`, and the other has `build-41`.

## Step 2: Decide how to check each tag

Adding a tag that the artifact already has fails, and so does deleting a tag it does not have. The script therefore checks first:

| Tag | Check | Change |
| --- | --- | --- |
| `stable` | `harbor artifact tags list <project>/<repository>/<tag> -o json`, then `jq -e` on the field `name` | `harbor artifact tags create <project>/<repository>/<tag> stable` |
| `tmp` | the same list | `harbor artifact tags delete <project>/<repository>/<tag> tmp` |

Both commands take the artifact as `<project>/<repository>/<reference>`, and the reference can be any tag the artifact has. Note that the separator before the reference is a slash.

## Step 3: Write the script

```sh
ws sh -c 'cat > /work/promote.sh' <<'SCRIPT'
#!/bin/sh
set -eu
repo="$1"
tag="$2"
ref="$repo/$tag"

has_tag() {
  harbor artifact tags list "$ref" -o json </dev/null \
    | jq -e --arg t "$1" '[.. | objects | select(.name? == $t)] | length > 0' >/dev/null
}

if has_tag stable; then
  echo "$ref already has the tag stable"
else
  harbor artifact tags create "$ref" stable </dev/null
fi

if has_tag tmp; then
  harbor artifact tags delete "$ref" tmp </dev/null
fi
SCRIPT
```

The `jq` filter looks at every object in the output for one whose `name` equals the tag, so it does not depend on how the CLI wraps the list. `</dev/null` makes sure no command waits for input.

## Step 4: Run it twice

```sh
ws sh -c 'sh /work/promote.sh team-red/app build-42 </dev/null'
ws sh -c 'sh /work/promote.sh team-red/app build-42 </dev/null'
wst harbor artifact tags list team-red/app/build-42
```

The second run prints that nothing is left to do. The tag list shows `build-42` and `stable`.

## Step 5: Run it for the other repository

```sh
ws sh -c 'sh /work/promote.sh team-red/api build-7 </dev/null'
wst harbor artifact tags list team-red/api/build-7
```

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create and delete and add `|| true` | Real errors, such as a wrong repository name, are hidden and the script reports success |
| Delete `stable` first and create it again | Between the two commands no artifact has the tag `stable`, which breaks a pipeline that deploys it |
| Match tags with `grep` | `stable` also matches `stable-old`; compare the exact field with `jq` |
| Use `curl` against the API | The task asks for the CLI; the grader rejects `curl` |

## Common mistakes

- Writing `<project>/<repository>:<tag>` for the tag commands. They take a slash before the reference.
- Forgetting `</dev/null`, so a command that lacks an argument opens its interactive form and the run times out.
- Running `harbor artifact list` without `--page-size`, which shows ten rows at most.

## Practice on your own

- Make the tag name `stable` a third argument.
- Refuse to run when the second argument is the tag `tmp` itself.
