# System Information, Quotas, Audit Logs And Garbage Collection

The endpoints in this part are about the registry as a whole instead of one artifact. A script uses them before it starts work (is Harbor up), while it works (is there space left) and afterwards (who changed what). Most of them are read-only. One of them, garbage collection, changes the registry and is explained with the safe way to try it.

## System information and health

Two endpoints need no sign-in and answer a script's first question:

```sh
ws sh -c 'curl -s "$HARBOR_URL/api/v2.0/health" | jq'
ws sh -c 'curl -s "$HARBOR_URL/api/v2.0/systeminfo" | jq "{harbor_version, auth_mode, registry_url}"'
```

`/health` lists each component (core, database, registry, job service, Redis and others) with a status of `healthy` or `unhealthy`. A script that must not start while a component is down checks all of them with `jq -e 'all(.components[]; .status == "healthy")'`. `/systeminfo` returns the Harbor version, the authentication mode and the registry address, which a script can compare with what it expects.

## Statistics and search

`/statistics` returns counts for the user who asks: the number of public and private projects and repositories, and the totals Harbor can see for that user. An administrator sees the whole registry.

```sh
api /statistics
```

`/search` finds projects and repositories by a name fragment, and the answer has two lists, one for each type:

```sh
api '/search?q=frontend'
```

Search shows only what the user may see, so a robot account with access to one project finds only that project. This is a good check for least privilege.

## Quotas

A project can have a storage limit. The quota endpoints show the limit and the use for each project:

```sh
api /quotas
```

Each entry names a reference (the project), the hard limit in `hard.storage` and the use in `used.storage`, both in bytes. A limit of `-1` means no limit. A job that pushes a large image can compare the two numbers before it pushes, and it can fail early with a clear message instead of failing in the middle of the upload with a quota error. To change a limit, send a `PUT` to `/quotas/{id}` with the new `hard` object.

## The audit log

Harbor records who did what. The audit log endpoint returns events with the time, the user, the operation, the resource type and the resource name:

```sh
api '/audit-logs?page_size=5&sort=-op_time'
```

The `sort=-op_time` puts the newest first, and `q` filters by field, for example `q=operation%3Ddelete` for deletions. For the history of one project, `/projects/{project_name}/logs` gives the same kind of events. The audit log answers questions such as "who deleted this tag" and "which robot account pushed this image". It is also the first place to look when a repository changes and nobody knows why. A script that audits deletions reads the log with a filter and a page size, and loops over the pages with the rules from the first module.

## Garbage collection

A delete removes the name of an artifact. The data stays on disk until a garbage collection (GC) finds blobs that no artifact uses and removes them. A registry that deletes images and never runs GC keeps growing.

GC is started with a `POST` to the schedule endpoint. The `Manual` type runs it once now. The `dry_run` parameter makes it report what it would remove without removing it:

```sh
ws sh -c 'curl -s -w "HTTP %{http_code}\n" -u admin:Harbor12345 -X POST -H "Content-Type: application/json" -d "{\"schedule\":{\"type\":\"Manual\"},\"parameters\":{\"delete_untagged\":true,\"dry_run\":true}}" "$HARBOR_URL/api/v2.0/system/gc/schedule"'
```

The answer is `201`, and the run happens in the background. Its result is in the history:

```sh
api /system/gc | jq '.[0] | {id, job_status, job_name}'
```

Each history entry has a status. The log of one run is at `/system/gc/{gc_id}/log`. Always run the dry run first and read the log, and start a real run only when the dry run shows what you expect. `delete_untagged` also removes artifacts that have no tag, which includes artifacts that were only referenced by a tag you removed. Make sure nothing needs them by digest.

Only an administrator can use the GC endpoints, so a project robot cannot run GC. A real run needs care in a live registry. Modern Harbor does not put the registry in read-only mode for GC, but a long run still loads the storage, so schedule it for a quiet time.

## Your mission: Tag An Artifact With Python

You can now address an artifact, encode a repository name with a slash, change tags with the right status codes, read scans and read the registry-wide endpoints. The graded lab asks you to write `tag_artifact.py`, a Python script that adds a tag to the artifact behind a given reference for a repository that may contain a slash, prints a JSON report, and succeeds when the artifact already has the tag.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-104-playground-020-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-020/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-104-lab-020-02
astrona start ats-104-playground-020-02
```

## Common pitfalls

> [!WARNING]
> - **Running a real GC first.** Do the dry run and read its log before a real run.
> - **Expecting a delete to free space.** The space returns only after GC.
> - **Checking `/health` only once at the start of a long job.** Components can fail later. Check again before the steps that matter.
> - **Pushing without looking at the quota.** A push over the limit fails late. Compare `used.storage` with `hard.storage` before the push.
> - **Using `delete_untagged` without thinking about digests.** Anything referenced only by digest is removed with it.
