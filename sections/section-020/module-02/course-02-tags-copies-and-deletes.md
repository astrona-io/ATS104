# Tags, Copies And Deletes

A script that works with artifacts spends most of its time on three actions: adding or removing a tag, copying an artifact to another repository, and deleting what is no longer needed. Each action is one request, each returns a status code that tells the script what happened, and each can be repeated by mistake. This part shows the requests, their status codes, and how to make them safe to run twice.

## Reading the tags of an artifact

The tags of an artifact have their own collection under its address:

```sh
api /projects/inventory/repositories/web%252Ffrontend/artifacts/v1/tags
```

The answer is a list of tag objects with `name`, `id`, `push_time` and `pull_time`. A script that wants to know whether an artifact has the tag `release` reads the list and compares the exact `name`. A `jq` expression does it in one line: `jq -e 'any(.[]; .name == "release")'` exits with `0` when it is there.

## Adding a tag

A tag is created with a `POST` to the collection. The body is a JSON object with the name:

```sh
ws sh -c 'curl -s -w "HTTP %{http_code}\n" -u admin:Harbor12345 -X POST -H "Content-Type: application/json" -d "{\"name\":\"release\"}" "$HARBOR_URL/api/v2.0/projects/inventory/repositories/web%252Ffrontend/artifacts/v1/tags"'
```

A new tag answers `201`. The same request a second time answers `409`, with an error body that says the tag exists. A script that must run twice has two safe choices. It can read the tags first and post only when the tag is missing. Or it can post and accept `409` as success. The first costs one more request but also tells the script the real state. The second is shorter, but it treats a `409` for another reason, such as an immutable rule, as success too. Prefer the first when the script reports what it did.

Keep in mind how Harbor handles a tag that another artifact already holds. Within a repository, a tag names one artifact. The repository also holds the artifacts whose tags were taken by a newer push, and they still exist, but without that name. Read the tag first when the script moves a tag such as `latest`, so the log shows which digest held it before.

## Removing a tag

A tag has its own address, which is the collection plus the tag name:

```sh
ws sh -c 'curl -s -w "HTTP %{http_code}\n" -u admin:Harbor12345 -X DELETE "$HARBOR_URL/api/v2.0/projects/inventory/repositories/web%252Ffrontend/artifacts/v1/tags/release"'
```

A removed tag answers `200`. Removing a tag that does not exist answers `404`. This is the opposite of the create case: a `404` on a delete means the object is already gone, which is the state the script wanted, so a script may accept `404` here. It must still stop on any other status.

A tag is not an artifact. Removing the tag `release` leaves the artifact and its other tags in place. If the artifact had only that tag, it stays in the repository as an untagged artifact, which a garbage collection with the option to delete untagged artifacts removes later.

## Copying an artifact

Copy an artifact into another repository with a `POST` to the artifacts collection of the target. The source goes into the query parameter `from`, written as `project/repository:tag` or `project/repository@digest`:

```sh
ws sh -c 'curl -s -w "HTTP %{http_code}\n" -u admin:Harbor12345 -X POST "$HARBOR_URL/api/v2.0/projects/archive/repositories/frontend-copy/artifacts?from=inventory/web/frontend:v1"'
```

A successful copy answers `201`. The target repository `frontend-copy` is created if it does not exist, and the copy keeps the same digest, because the content is the same. In the `from` parameter the source repository is written with its slashes as they are, since it is a value in the query string and not a path segment. If the target already holds the artifact, the copy is not an error for most content types, but the response tells the script nothing about a change, so a script that must report one reads the target afterwards.

A copy is a registry-side operation. No data passes through the script, which makes it a good way to promote a build from a staging project to a production project.

## Deleting an artifact

`DELETE` on the address of the artifact removes it with all its tags:

```sh
ws sh -c 'curl -s -w "HTTP %{http_code}\n" -u admin:Harbor12345 -X DELETE "$HARBOR_URL/api/v2.0/projects/archive/repositories/frontend-copy/artifacts/v1"'
```

The answer is `200`. A second delete answers `404`. Deleting a tag only removes a name, and deleting the artifact removes the content from the project. The disk space returns only after a garbage collection, which a later part covers. If an immutable tag rule protects a tag of the artifact, the delete is refused.

## Status codes at a glance

| Request | New or changed | Already in that state | Wrong path or name |
| --- | --- | --- | --- |
| Create a tag | `201` | `409` | `404` |
| Remove a tag | `200` | `404` | `404` |
| Copy an artifact | `201` | Check the target | `404` for a missing source |
| Delete an artifact | `200` | `404` | `404` |

A `404` is both an answer and a warning. On a delete it can mean "already gone", and it can mean the path is wrong, for example a repository name encoded once. The script cannot tell the difference from the status alone, which is why it reads the object first when the difference matters.

## Common pitfalls

> [!WARNING]
> - **Treating `409` on a create as success without a reason.** It can mean the tag exists, or it can mean a rule blocked the request. Read the tags first when the difference matters.
> - **Treating every `404` on a delete as success.** A wrongly encoded repository name also answers `404`.
> - **Deleting an artifact to remove a tag.** The artifact and every tag on it are gone.
> - **Expecting disk space back at once.** A delete frees the space only after a garbage collection.
