# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** Automating Harbor with the harbor CLI

## Scenario

The release pipeline builds an image for every commit and pushes it with a tag such as `build-42`. During testing the pipeline also adds the tag `tmp`. When a build passes its tests, the pipeline must mark it as the release candidate by adding the tag `stable`, and it must remove the leftover tag `tmp`. The pipeline can retry a failed job, so the step may run several times for the same build.

The project `team-red` is private and has two repositories. `app` holds the builds `build-41` and `build-42`, and `build-42` also carries the tag `tmp`. `api` holds the build `build-7`, which also carries the tag `tmp`.

The CLI in the workstation pod is signed in as the administrator. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

## Your task

Write the script `/work/promote.sh` in the workstation pod. It is called like this:

```sh
sh /work/promote.sh <project>/<repository> <tag>
```

and it must:

1. Add the tag `stable` to the artifact that `<tag>` points to, if that artifact does not have the tag yet.
2. Remove the tag `tmp` from the same artifact, if it has that tag.
3. Exit with code `0` when nothing is left to do.

## Constraints

- **Use the `harbor` CLI**, not `curl` or the REST API directly.
- The pipeline runs the script with no terminal and with standard input from `/dev/null`. No command may wait for input.
- Do not write any password into the script.
- Do not delete artifacts or repositories, and do not change the artifact `build-41`.

## Done when

- `sh /work/promote.sh team-red/app build-42` exits with `0`, and the artifact of `build-42` has the tags `build-42` and `stable` only.
- Running the same command a second time also exits with `0` and changes nothing.
- `sh /work/promote.sh team-red/api build-7` exits with `0`, and the artifact of `build-7` has the tags `build-7` and `stable` only.
- The artifact of `build-41` still has the tag `build-41` only.
