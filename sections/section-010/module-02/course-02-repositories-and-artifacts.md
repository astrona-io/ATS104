# Repositories And Artifacts

A project holds repositories, and a repository holds artifacts. An artifact is the thing a push stores: a container image, a Helm chart or, in this course, a small file pushed with `oras`. Harbor identifies an artifact by its digest, a hash of its content that looks like `sha256:3b1c...`. A tag such as `build-42` is a name that points to one digest. Commands that work on artifacts must therefore say two things: which repository, and which artifact in it. This part shows how the CLI names both, how to list them without losing rows, and how to delete them.

## Repositories

A repository name includes its project: `inventory/app` is the repository `app` in the project `inventory`. The CLI lists the repositories of one project and views one repository:

```sh
wst harbor repo list inventory
wst harbor repo view inventory/app
```

`harbor repo list` shows the repository name, the number of artifacts and the pull count. It takes `--page` and `--page-size`, a query with `-q` and a sort with `--sort`. Its default page size is 10, which is the most common reason for a script that misses repositories. Give the page size in a script:

```sh
ws harbor repo list inventory --page-size 100 -o json </dev/null \
  | jq -r '.. | objects | select(has("name")) | .name'
```

For more than one hundred repositories, loop over `--page` until a page comes back with fewer rows than the page size. The query flag accepts the same filter syntax as the REST API, for example `-q name=~app`, which selects repositories whose name contains `app`. The REST API module explains the query syntax in detail.

## Artifacts and how to name them

`harbor artifact list` takes the repository as `<project>/<repository>`:

```sh
wst harbor artifact list inventory/app
```

The table has one row per artifact with its tags, digest, type, size, vulnerability count and push time. Like the repository list, it has a default page size of 10 and the flags `--page`, `--page-size`, `-q` and `--sort`.

Commands that act on one artifact take a reference in a path form. The CLI documentation shows two shapes, and the difference matters:

| Command | Shape of the argument | Example |
| --- | --- | --- |
| `harbor artifact view` | `<project>/<repository>:<tag>` or `<project>/<repository>@<digest>` | `inventory/app:build-2` |
| `harbor artifact info` | `<project>/<repository>/<reference>` | `inventory/app/build-2` |
| `harbor artifact tags list`, `create`, `delete` | `<project>/<repository>/<reference>` | `inventory/app/build-2` |
| `harbor artifact scan start` | `<project>/<repository>/<reference>` | `inventory/app/build-2` |

The reference is a tag or a digest. A digest always points to exactly one artifact. A tag points to one artifact at a time, but it can be moved to another artifact by a new push. A script that must act on the artifact it just examined should use the digest, because a tag can change between the two commands.

```sh
wst harbor artifact view inventory/app:build-2
wst harbor artifact info inventory/app/build-2
```

When the repository name itself contains a slash, such as `inventory/team/app`, the path form is ambiguous for the commands that use slashes. In that case use the `@<digest>` form where the command supports it, or the REST API, which handles the encoding explicitly.

## Finding the digest of a tag

A script often needs the digest for a tag. Ask for the artifact as JSON and read the field:

```sh
ws harbor artifact list inventory/app --page-size 100 -o json </dev/null \
  | jq -r '.. | objects | select(has("digest")) | "\(.digest)"'
```

Harbor's artifact objects hold the digest in the field `digest` and the tags in a list called `tags`. The filter above prints the digest of every artifact in the repository, and it does not rely on the shape of the wrapper. To pick one artifact by tag, add a condition on its tag names with `jq`, using `select` and `any`.

## Deleting artifacts and repositories

`harbor artifact delete` removes an artifact. `harbor repo delete` removes a repository with everything in it. Both ask for the target as an argument or, without one, open a prompt, so a script gives the argument and `</dev/null`:

```sh
ws harbor artifact delete inventory/app/build-1 </dev/null
```

Deleting an artifact removes all its tags at once. This is different from deleting one tag, which only removes the name. Deleting does not free disk space immediately: Harbor marks the data for removal, and the space returns when garbage collection runs. The REST API module shows how to start it.

A script that deletes should list first and delete only what it listed, and it should never build the target from an unchecked variable. An empty variable in a path form can turn `inventory/app/$ref` into `inventory/app/`, which is a different command than the one you meant.

## Labels

Harbor labels are small coloured names that you attach to artifacts to group them, for example `approved` or `deprecated`. The CLI creates a label with `harbor label create` and attaches one with `harbor artifact label add <project>/<repository>:<reference> <label>`. Use a label when a team wants to mark an artifact without giving it a new tag, because a label does not change what a tag points to.

You now know how a CLI command names an artifact, why the default page size hides rows, and how to delete one safely. The next part uses these names to change tags, and to keep a project tidy with two rules.

## Common pitfalls

> [!WARNING]
> - **Listing repositories or artifacts without `--page-size`.** The default is 10, so a script silently sees part of the data.
> - **Using the wrong separator.** `artifact view` takes `repository:tag`, while `artifact tags` and `artifact scan` take `repository/reference`. Check the example in `--help` for each command.
> - **Acting on a tag after examining it.** A tag can move between the two commands. Use the digest when the script must stay on the same artifact.
> - **Deleting an artifact to remove one tag.** The artifact and all its tags are gone. Delete the tag instead.
