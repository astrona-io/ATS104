# Summary: System Robots, Lifecycle And Auditing

This module moved from one project robot to the whole life of robot accounts: a robot across projects, its lifecycle, its trail and its use in a cluster.

## What to remember

- A system robot has `"level": "system"`, a name without a project part such as `robot$puller`, and a list of permissions with one entry for each project. Only a system administrator creates one.
- The namespace `*` grants access in every project, including future ones. Name the projects instead.
- Read the full name from the creation response. The `robot$` prefix can be changed by an administrator.
- `GET /robots` lists system robots. Compare `expires_at` with the time to warn before expiry. A `duration` of `-1` never expires.
- Disable first with `PUT` and `disable` set to true, and delete later. A `PUT` replaces the whole definition, so read, edit and send. A `PATCH` with a secret changes only the secret.
- `/audit-logs` is the system-wide trail and `/projects/{name}/logs` is the project's. Filter with `q`, and encode `$` as `%24` and `=` as `%3D`.
- A cluster pulls with a `kubernetes.io/dockerconfigjson` Secret in each namespace that needs it, named in `imagePullSecrets`. The server name must match the image host.
- An expired secret stops only new pulls. Check with a fresh pod after any refresh.

## Commands you should know

| Task | Command |
| --- | --- |
| Create a robot | `POST /robots` with a JSON definition |
| List system robots | `GET /robots?page_size=100` |
| Disable or change a robot | `PUT /robots/{id}` with the whole object |
| Refresh the secret | `PATCH /robots/{id}` with `{"secret": "..."}` |
| Delete a robot | `DELETE /robots/{id}` |
| Read events of one account | `GET /audit-logs?q=username%3Drobot%24puller` |
| Create a pull Secret | `kubectl create secret docker-registry harbor-pull --docker-server=... --docker-username=... --docker-password=...` |

## Clean up

If you started the playground for this module, you can remove it now:

<!-- astrona:playground:destroy -->
