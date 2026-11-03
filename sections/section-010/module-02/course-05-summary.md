# Summary

The `harbor` command-line tool works on the content of a registry as well as on projects and users. This module showed how to name what you act on, how to read a complete list and how to change tags and read scan results in a way that survives a second run.

## What you learned

A project is created with `harbor project create`, which needs `--storage-limit` to avoid an interactive form and creates a private project unless `--public` is set. `harbor project list` filters on the server with `--name`, `--public`, `--private`, `--match`, `--fuzzy` and `--range`, and `--page-size 0` fetches every project. `harbor project view` exits with `0` only when the project exists, `harbor project summary` shows counts and quota use, and `harbor project delete` refuses a project that still has repositories unless `--force` is given.

A repository is named `<project>/<repository>`. `harbor repo list` and `harbor artifact list` default to a page size of 10, so a script sets `--page-size` and loops over `--page`. Commands that act on one artifact take `<project>/<repository>/<reference>`, where the reference is a tag or a digest. `harbor artifact view` takes `<project>/<repository>:<tag>` instead. A digest names one artifact for ever, while a tag can move.

Adding a tag that exists, or deleting one that does not, fails, so a script lists the tags with `harbor artifact tags list -o json`, tests the exact `name` with `jq -e`, and changes only when needed. Tag retention rules delete or keep tags by pattern and should be run as a dry run first. Immutable tag rules stop a tag from being overwritten, moved or deleted, so a pipeline that uses them tags every build uniquely.

`harbor artifact scan start` returns when Harbor accepts the request, and the scan runs in the background. A script waits with a limit and reads the scan status before it trusts the count. `harbor vulnerability list` filters findings on the server, and `harbor vulnerability summary` totals them. A gate fails the pipeline on a rule written in advance, such as any fixable critical finding. The key facts to remember are these:

- Give `--storage-limit` when you create a project and `--page-size` when you list repositories or artifacts.
- Name an artifact as `<project>/<repository>/<reference>`; use the digest when the artifact must not change.
- Check a tag before you add or remove it, and use `if`, not `&&`, under `set -e`.
- A scan result is only meaningful after the scan finished.

<!-- astrona:playground:destroy -->
