# Projects With The CLI

Everything in Harbor lives in a project. A project holds repositories, has its own members, its own robot accounts, its own webhooks and its own rules. The CLI has one group of commands for projects, and a pipeline uses four of them all the time: `create`, `list`, `view` and `delete`. This part shows what each command needs so it never waits for input, how to filter a list on the server, and how to read the size and counts of a project.

## Creating a project

The command `harbor project create` takes the project name and a few flags. Without a flag that sets the storage limit, the CLI opens an interactive form, so a script always gives that flag:

```sh
ws harbor project create scratch-a --storage-limit -1 </dev/null
```

The value `-1` means no storage limit. A project is private unless you add `--public`. A public project can be pulled from without signing in, so a script that creates projects for teams should never add `--public` by habit. Two more flags exist for special cases. `--proxy-cache` makes the project a pull-through cache of another registry, and it needs `--registry-id` with the ID of that registry.

A project name must be unique, lower case, and may contain letters, digits, dots, dashes and underscores. Creating a project that exists fails. A script that must run twice checks first, with the exit code of `harbor project view`, which was covered in the previous module.

## Listing and filtering projects

The command `harbor project list` shows the projects the signed-in user can see. The flags do the filtering on the server, so the script does not have to:

```sh
wst harbor project list --private
wst harbor project list --name inventory
wst harbor project list --public
```

`--private` and `--public` select by visibility. `--name` selects projects by name. Three more flags take a `key=value` pair for a finer filter: `--match` for an exact match, `--fuzzy` for a partial match, and `--range` for a range written as `key=min~max`. The key is a field of the project, such as `name`. An example of a partial match is:

```sh
wst harbor project list --fuzzy name=inv
```

A list command returns one page. For `harbor project list` the default page size shows the first rows only, and `--page-size 0` fetches every project, which is what a script wants. In JSON the same call looks like this:

```sh
ws harbor project list --page-size 0 -o json </dev/null | jq -r '.. | objects | select(has("name")) | .name'
```

The `jq` filter walks every object and prints the `name` field, so it keeps working if the CLI wraps the list differently in another release.

## Viewing a project and its summary

Two commands show one project in detail. `harbor project view` prints the project's settings, such as visibility and creation time, and it exits with `0` only when the project exists. `harbor project summary` prints the counts that Harbor keeps for the project: the number of repositories, the member counts by role and the quota that is used.

```sh
wst harbor project view inventory
wst harbor project summary inventory
```

Both accept a name, or a number when you add `--id`. A pipeline that has to stop when a project is nearly full reads the summary in JSON and compares the used storage with the limit.

## The storage limit

Every project has a quota for storage. The administrator can change it with `harbor quota update`, which takes the quota number or, more conveniently, the project name, together with a size such as `50GiB`:

```sh
ws harbor quota update --project-name scratch-a --storage 2GiB </dev/null
```

When a project is over its quota, a push is refused. The REST API module covers the quota endpoints. For now, remember that `--storage-limit -1` at creation means there is no limit, and a size such as `2GiB` limits the project.

## Searching and the audit trail

Two more commands help in a script that has to find things. `harbor project search` searches projects by name. `harbor project logs` shows the audit log of the project you select: who pushed, pulled or deleted what, with a time. Both take `--page-size`, `--page` and, for the logs, a query with `-q` and a sort with `--sort`:

```sh
wst harbor project logs inventory --page-size 20
```

The audit log is how you answer the question of who deleted an artifact.

## Deleting a project

`harbor project delete` takes one or more project names. A project that still has repositories cannot be deleted, and Harbor refuses. The flag `--force` deletes every repository, artifact and policy in the project first. That is irreversible, so a script that uses `--force` should check the project name against a list it expects:

```sh
ws harbor project delete scratch-a --force </dev/null
```

Without a name the command prompts for one, which is another reason to give the argument and `</dev/null`. The flag `--project-id` selects the project by number instead of by name.

You now know how to create a project without the interactive form, how to filter the project list on the server, how to read a project's summary and how to delete a project. The next question is what is inside a project: its repositories and artifacts, and how a command names one of them.

## Common pitfalls

> [!WARNING]
> - **Creating a project without `--storage-limit`.** The command opens an interactive form and waits. Always give the flag in a script.
> - **Adding `--public` out of habit.** A public project can be pulled from by anyone who reaches Harbor. Leave the flag out unless the project is meant to be public.
> - **Reading only the first page of `harbor project list`.** Use `--page-size 0`, or the script works on part of the projects.
> - **Using `--force` on a name that came from user input.** It deletes everything in the project and cannot be undone.
