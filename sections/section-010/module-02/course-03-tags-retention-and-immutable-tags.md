# Tags, Retention And Immutable Tags

A tag is the name people use for an artifact: `build-42`, `v1.2.0`, `stable`. Pipelines move through a registry by changing tags. A build gets a tag when it is pushed, a second tag when it passes its tests, and a third when it is released. This part shows how to list, add and remove tags with the CLI so that a script can run twice. It then covers two project rules that act on tags without a script: tag retention, which deletes old tags, and immutable tags, which keep a tag from being overwritten.

## Listing tags

The command `harbor artifact tags list` takes the artifact as `<project>/<repository>/<reference>` and prints its tags:

```sh
wst harbor artifact tags list inventory/app/build-2
```

The artifact `inventory/app/build-2` has two tags in the playground: `build-2` and `tmp`. In a script, ask for JSON and test for a name with `jq -e`, which exits with `0` only when the filter is true:

```sh
ws harbor artifact tags list inventory/app/build-2 -o json </dev/null \
  | jq -e '[.. | objects | select(.name? == "tmp")] | length > 0' >/dev/null && echo "has tmp"
```

The filter looks at every object in the output for one whose `name` is `tmp`, so it works whatever way the CLI wraps the list. Compare the exact field. A text search for `tmp` would also match `tmp-old`.

## Adding and removing a tag

The two commands that change tags take the artifact in the same path form, followed by the tag name:

```sh
ws harbor artifact tags create inventory/app/build-2 stable </dev/null
ws harbor artifact tags delete inventory/app/build-2 tmp </dev/null
```

Run the first command a second time and Harbor answers that the tag exists, which makes the command exit with an error. The second command fails when the tag does not exist. Neither command is safe to run twice. The pattern for a script is the same as for an onboarding script: check, then change.

```sh
ref=inventory/app/build-2
has_tag() {
  harbor artifact tags list "$ref" -o json </dev/null \
    | jq -e --arg t "$1" '[.. | objects | select(.name? == $t)] | length > 0' >/dev/null
}
has_tag stable || harbor artifact tags create "$ref" stable </dev/null
has_tag tmp && harbor artifact tags delete "$ref" tmp </dev/null
```

Under `set -e`, the last line needs care: when `has_tag tmp` is false, the `&&` list returns a non-zero status and the shell may stop the script. Write it as an `if` statement, as the lab solution does, so that the script exits with `0` when there is nothing to do.

## One tag, one artifact

A tag points to a single artifact in a repository. When a build pushes the tag `latest` for a new image, the tag moves from the old artifact to the new one, and the old artifact stays in the repository without that name. Adding a tag that already points to a different artifact is a different case from adding one the artifact already has, and a script that promotes a build to `stable` has to decide what happens to the previous holder of `stable`. The safe pattern is to remove the old tag and add the new one in a fixed order that leaves a window as short as possible, or to push the tag from the registry client, which moves it in one step.

## Tag retention

A registry fills up. Every build adds an artifact, and nobody deletes the old ones. A tag retention rule deletes or keeps tags by a rule. It belongs to a project and runs on a schedule or on demand. The CLI creates a rule with `harbor tag retention create`:

```sh
ws harbor tag retention create --level project --action retain --taglist 'release-*' -p inventory </dev/null
```

The flags are `--level` (`project` or `repository`), `--action` (`retain` or `delete`), `--taglist` for tag patterns, `--repolist` for repository patterns, `--tagdecoration` and `--repodecoration` to say whether a list includes or excludes, `--algorithm` to combine rules with `or` or `and`, and `-p` for the project name. A project can have up to 15 retention rules. List them with `harbor tag retention list`.

Retention is destructive, so the useful habit is a dry run. The portal and the REST API can run a rule as a dry run that reports what would be deleted without deleting anything. Run that first, read the result, and only then run the rule for real.

## Immutable tags

An immutable tag rule makes a tag that matches a pattern permanent: after the first push, the tag cannot be pushed again, moved or deleted. This protects tags that other systems rely on, such as `v1.2.0`. The CLI creates one with `harbor tag immutable create`:

```sh
wst harbor tag immutable create --tag-list 'v*'
```

The flags are `--tag-list`, `--tag-decoration`, `--repo-list` and `--repo-decoration`. The decoration says whether the list includes or excludes the matching names. The command has no flag for the project, so in CLI v0.0.27 it asks which project to use in an interactive form. That makes it a command for a person at a terminal, which is why this example runs through `wst`. A script that must create the rule uses the REST API instead. List the rules with `harbor tag immutable list` and delete one with `harbor tag immutable delete`.

An immutable rule has a side effect a script must expect. A push of an immutable tag that already exists fails, and so does an attempt to add that tag to another artifact with `harbor artifact tags create`. A pipeline that retries a push after a failure then gets an error on the second attempt, because the first attempt already stored the tag. Pipelines that use immutable tags should tag with a unique value, such as the build number.

## Your mission: Promote A Build With Tags

You can now list, add and remove tags without failing on a second run. The graded lab asks you to write `promote.sh`, which gives the artifact behind a build tag the tag `stable` and removes the temporary tag `tmp`, for two different repositories, and which must succeed when there is nothing left to do.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-104-playground-010-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-010/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-104-lab-010-02
astrona start ats-104-playground-010-02
```

## Common pitfalls

> [!WARNING]
> - **Adding a tag the artifact already has, or removing one it does not have.** Both fail. Check with `tags list` and `jq -e` first.
> - **Ending a script with `check && change`.** Under `set -e`, a false check makes the last status non-zero. Use `if`.
> - **Running a retention rule without a dry run.** Deleted artifacts cannot be recovered. Read the dry run first.
> - **Retrying a push of an immutable tag.** The second attempt fails because the first one stored the tag. Tag each build uniquely.
