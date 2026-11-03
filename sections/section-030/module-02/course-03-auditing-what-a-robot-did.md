# Auditing What A Robot Did

When an image disappears or a tag moves, the question is who did it. Harbor records the answer. A robot that is disabled or deleted does not erase the trail, and the trail is how you tell a leaked secret from a pipeline mistake.

## The audit log

The audit log is at `/audit-logs`. It lists events with the time, the user, the operation, the resource type and the resource. Sort newest first and keep the page small:

```sh
api '/audit-logs?page_size=10&sort=-op_time'
```

Each event has `username`, `operation` (for example `create`, `delete`, `pull`), `resource_type` (for example `artifact`, `repository`, `project`) and `resource`. The log shows the robot by its full name, so a filter on the username finds everything one robot did:

```sh
api '/audit-logs?q=username%3Drobot%24puller&page_size=20&sort=-op_time'
```

The `q` value is `username=robot$puller` with the equals sign written as `%3D` and the dollar sign as `%24`. Without the encoding the shell or the server can read the `$` as something else.

## Which operations are recorded

Harbor records the changes to artifacts, repositories, projects, robots, users and other objects. Pulls and pushes of artifacts are recorded as events of the artifact. The set of events the log keeps can be limited by the administrator, and the log can be forwarded to an external endpoint, so for a long-term trail forward it rather than relying on the database alone. Check what your installation keeps before you rely on it in an investigation.

## The project log

Each project has its own log, which a project administrator can read without system rights:

```sh
api '/projects/team-red/logs?page_size=10'
```

It lists the operations on that project: who pushed, who pulled, who deleted a tag. It is the right place for a team to answer a question about its own repositories. The audit log is the system-wide view that an administrator uses.

## A short investigation

A tag `release` in `team-red/notes` points to the wrong artifact. Work in this order:

1. Read the project log for the repository and find the push or tag event close to the time of the change.
2. Note the `username` of the event. A name that starts with `robot$` is a robot.
3. Read the robot with `GET /robots` and look at its description, expiry and permissions.
4. Decide: a known pipeline made a mistake, or the secret is in the wrong hands. In the second case disable the robot at once and refresh the secret.
5. Search the audit log for every other event of that username after the first suspicious time.

The robot's permissions limit how far step 5 can go. A pull-only robot that appears in a delete event means the event belongs to another account. This is another reason to keep each robot narrow.

## Reading events in a script

A script reads the log with the paging rules of the REST API: a page size, the `X-Total-Count` header and a loop over `page`. It filters with `q` and uses `jq` to reduce each event to the fields it needs:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/audit-logs?q=operation%3Ddelete&page_size=50&sort=-op_time" | jq -r ".[] | [.op_time, .username, .resource_type, .resource] | @tsv"'
```

The output has one line for each delete, with a tab between the fields, which is easy to send to a chat channel or a file.

## Common pitfalls

> [!WARNING]
> - **Leaving `$` unencoded in a filter.** Write `robot%24puller` in the query string.
> - **Assuming every event is kept.** Check which events your installation records and for how long.
> - **Investigating only the first event.** Look for everything the account did afterwards.
> - **Deleting a robot before reading its trail.** Read the events first, then delete.
