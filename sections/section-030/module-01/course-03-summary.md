# Summary

A pipeline needs its own credentials, and a robot account is Harbor's way to give it some. This module showed how to create robots that can do exactly their job, and how to handle their secrets.

## What you learned

A robot account is a non-human Harbor account with a name, a secret, a lifetime and a list of permissions. It authenticates to the registry and the REST API like a user, but it cannot sign in to the portal. A project robot reaches one project and is named `robot$<project>+<name>`; a system robot, created by a system administrator, can reach several projects and is named `robot$<name>`. The `$` and `+` in the names need single quotes in a shell.

Permissions are pairs of a resource and an action, such as `repository` `pull` or `artifact` `delete`. Push must come with pull. The REST API creates a robot with `POST /api/v2.0/robots` and a body with `name`, `level`, `duration` and `permissions`; the `harbor` CLI does the same with `harbor project robot create --robot-config-file`. Harbor shows the secret only in the creation response, so a script stores it at once, ideally straight into a Kubernetes Secret.

Least privilege means choosing the permissions from the job: a CI job that pushes to one project gets push and pull there, a cluster that pulls gets pull only. A `duration` in days limits how long a leaked secret stays useful; `-1` never expires. Disabling a robot stops its secret at once and keeps its ID.

Rotation replaces a secret in place: `PATCH /api/v2.0/robots/<id>` with a new secret, or `harbor project robot refresh`. The old secret stops working immediately, the robot keeps its ID and permissions, and every store that held the old secret must be updated. Permissions and duration change with `PUT /api/v2.0/robots/<id>`, starting from the full object that `GET` returns. The key facts to remember are these:

- Permissions are the damage a leaked secret can do; give only what the job needs.
- The secret is shown once; store it immediately.
- Give robots a duration; refresh secrets instead of recreating robots.
- After a rotation, update every place that holds the secret.

<!-- astrona:playground:destroy -->
