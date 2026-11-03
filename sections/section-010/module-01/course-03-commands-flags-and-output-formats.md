# Commands, Flags And Output Formats

A script is only as reliable as the commands it calls. The `harbor` command-line tool (CLI) has dozens of commands, and most of them have flags that change what they return and how much. Two mistakes cause most broken scripts: calling a command with the wrong flags, and reading only the first page of a list. This part shows how to find the right command with the built-in help, which global flags every command accepts, and how page size decides whether a script sees all the data.

## Finding a command with the built-in help

The CLI groups its commands by the thing they manage: `project`, `repo`, `artifact`, `user`, `robot`, `webhook`, `registry`, `replication`, `quota`, `label`, `scanner` and more. Every group has subcommands, and every command has a `--help` page that lists its flags and shows an example. The help text is the reference for the exact CLI version that you run, so check it before you copy a flag from a blog post.

Print the groups, then the flags of one command. Help needs no terminal and no server, so it is safe in a script too.

<!-- astrona:playground:renew -->

```sh
ws harbor --help </dev/null
ws harbor project list --help </dev/null
```

The first command lists the command groups and the global flags. The second lists the flags of `harbor project list`, among them `--name`, `--public`, `--private`, `--page`, `--page-size` and `--sort`. Notice that the same command has a flag for each kind of filter, so the server does the filtering and the script does not have to.

## Global flags that every command accepts

Four flags work on every command. `-o` (`--output-format`) selects `json`, `yaml` or `csv` instead of the default table. `-c` (`--config`) names a configuration file, instead of the default `$HOME/.config/harbor-cli/config.yaml`. `-l` (`--log-format`) switches the CLI's own log lines between `text` and `json`. `-v` (`--verbose`) prints more detail.

The `-c` flag matters for pipelines. A job that works for two Harbor servers can keep one configuration file for each and pick one per command, and the saved contexts of the first file never mix with the second. The `-o` flag matters even more. A table is made for a person. It needs a terminal, its columns change between CLI releases, and a long value can be cut off. JSON keeps every field with its name, and `jq` reads it by name.

Ask for the same list in three formats and compare what each gives a script:

```sh
ws harbor project list -o json </dev/null | head -c 300
ws harbor project list -o yaml </dev/null | head -n 12
ws harbor project list -o csv </dev/null
```

JSON and YAML carry the full project objects. CSV is a flat row for each project, which is handy for a spreadsheet and weak for a script, because a value that contains a comma needs quoting. Use JSON in scripts.

## Health and version checks

Two commands tell a script whether it can start work at all. `harbor health` reports the status of the Harbor components (core, database, registry, job service and the others). `harbor info` shows the Harbor system, its statistics and the CLI's own environment: the signed-in user, the registry address and the CLI version. A pipeline that starts with these two checks fails with a clear message when Harbor is down, instead of failing on the tenth command with a confusing one.

```sh
ws harbor health -o json </dev/null
ws harbor info -o json </dev/null | head -c 400
```

Both print JSON. The health output has one entry for each component with a status, and `info` shows the user the CLI is signed in as, which also settles the question of which context is current.

## Page size decides what the script sees

List commands return one page. The page size defaults differ between commands, and that is a trap. The help pages say it: `harbor project list` and `harbor user list` take `--page-size 0` to fetch everything, while `harbor repo list` and `harbor artifact list` default to a page size of 10. A script that lists repositories without `--page-size` sees at most ten and takes the rest as missing.

Create enough repositories to see the effect. This loop pushes twelve tiny artifacts into the project `inventory`, then lists the repositories twice:

```sh
for number in 1 2 3 4 5 6 7 8 9 10 11 12; do
  ws sh -c "cd /tmp && echo note-$number > note.txt && oras push harbor.localtest.me:8443/inventory/bulk-$number:v1 note.txt >/dev/null"
done
ws harbor repo list inventory -o json </dev/null | jq '[.. | objects | select(has("name"))] | length'
ws harbor repo list inventory --page-size 100 -o json </dev/null | jq '[.. | objects | select(has("name"))] | length'
```

The first count stops at ten, because that is the default page size. The second count is higher, because `--page-size 100` asks for up to one hundred rows. For a project with more than one hundred repositories, the script has to loop over `--page` until a page comes back short. The filter counts the objects that have a `name` field, so it does not depend on how the CLI wraps the list.

You now know how to find a command and its flags with `--help`, which global flags control the format and the configuration file, how to check that Harbor is healthy before a script starts, and why a list command needs an explicit page size. The open question is how to put these pieces together into a script that creates objects and still gives the same result when it runs a second time.

## Common pitfalls

> [!WARNING]
> - **Reading the default page of `harbor repo list` or `harbor artifact list`.** The default page size is 10. Pass `--page-size` and loop over `--page`, or the script silently works on part of the data.
> - **Copying a flag from an older blog post.** Flags change between CLI versions. Run `--help` for the version that you installed.
> - **Using the table or CSV output in a script.** Tables need a terminal and change between releases. Use `-o json` and `jq`.
> - **Starting work without a health check.** When Harbor is down, a script without `harbor health` fails late and with an unclear message.
