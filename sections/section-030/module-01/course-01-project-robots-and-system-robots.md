# Project Robots And System Robots

A pipeline needs an identity that is not a person: one that does not leave the company, has no portal password, and can do only its job. Harbor gives it a robot account. This part explains the two kinds of robot, how Harbor names them, how their permissions are written, and how to create one and catch its secret the only time Harbor shows it.

## Two kinds of robot

Harbor has two kinds of robot account, and the difference is how far their permissions can reach:

| Kind | Who creates it | Reach | Name |
| --- | --- | --- | --- |
| Project robot | A project administrator or a system administrator | One project | `robot$<project>+<name>`, for example `robot$ci+builder` |
| System robot | A system administrator | Several projects, plus some system-level resources | `robot$<name>`, for example `robot$nightly-scan` |

The prefix `robot$` is the default. A system administrator can change it under **Configuration > System Settings**, and the change applies to both kinds. Since Harbor 2.12, a robot can hold almost any permission except the configuration ones, but never more than the person who creates it.

A robot cannot sign in to the portal. It authenticates like a user, with its full name and its secret, in two places: the registry (`docker login`, `oras login`) and the REST API (basic authentication). The `$` and `+` in the name are ordinary characters for Harbor but special characters for a shell, so a script always puts the name in single quotes: `'robot$ci+builder'`.

## Permissions: a resource and an action

A robot's permissions are a list of pairs: a **resource**, the kind of object, and an **action**, what the robot may do to it. For a project robot they all belong to one project. The pairs a pipeline uses most often are these:

| Resource | Actions | What it allows |
| --- | --- | --- |
| `repository` | `pull`, `push`, `delete`, `list` | Pull and push artifacts, delete a repository, list repositories |
| `artifact` | `read`, `list`, `delete` | Read artifact details, list artifacts, delete an artifact |
| `tag` | `create`, `delete`, `list` | Add, remove and list tags |
| `scan` | `create`, `stop`, `read` | Start and stop a vulnerability scan, read the report |

Harbor's documentation adds one rule: the push permission must be given together with the pull permission. A registry client pulls layer information while it pushes, so a push-only robot fails.

## Creating a robot through the API

`POST /api/v2.0/robots` creates a robot. The request body says the robot's `name`, its `level` (`project` or `system`), its `duration` in days (`-1` means it never expires), and its `permissions`: a list of entries with `kind` (`project`), `namespace` (the project name) and `access`, the list of resource and action pairs.

Create a robot that can only pull from `inventory`, for a reporting job, valid for seven days. Save this as `robot-reader.json` on your machine:

<!-- astrona:playground:renew -->

```json
{
  "name": "reader",
  "description": "Reads inventory for the nightly report",
  "level": "project",
  "duration": 7,
  "permissions": [
    {
      "kind": "project",
      "namespace": "inventory",
      "access": [
        {"resource": "repository", "action": "pull"}
      ]
    }
  ]
}
```

Send it, and keep the response in a shell variable on your machine:

```sh
RESPONSE="$(ws sh -c 'curl -s -u admin:Harbor12345 -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/robots"' < robot-reader.json)"
printf '%s' "$RESPONSE" | ws jq '{id, name, expires_at}'
```

The response holds the robot's `id`, its full `name`, `robot$inventory+reader`, the time it expires as a Unix timestamp in `expires_at`, and its `secret`. **Harbor shows the secret only in this response.** It does not store it in a form it can show again; if you lose it, you can only refresh it. Keep it in a variable for now:

```sh
READER_SECRET="$(printf '%s' "$RESPONSE" | ws jq -r '.secret')"
```

## Using the robot

Sign `oras` in as the robot with a separate configuration file, so the administrator's sign-in in the workstation stays as it is, and read the manifest of the artifact in `inventory`:

```sh
printf '%s' "$READER_SECRET" | ws oras login --registry-config /tmp/reader.json -u 'robot$inventory+reader' --password-stdin harbor.localtest.me:8443
ws oras manifest fetch --registry-config /tmp/reader.json harbor.localtest.me:8443/inventory/notes:v1
```

The login succeeds and the manifest prints as JSON. The robot did what its permission allows. Now try to pull from the project `ci`, where it has no permission:

```sh
ws oras manifest fetch --registry-config /tmp/reader.json harbor.localtest.me:8443/ci/app:latest
```

`oras` reports that the request was refused as unauthorized. Harbor's token service gave the robot no access to `ci`, so it does not even learn whether `ci/app` exists. The robot's reach ends at its project.

## The same with the harbor CLI

The `harbor` CLI creates project robots with `harbor project robot create`. Without flags it opens an interactive form. For a script, it reads the same information from a YAML or JSON file given with `--robot-config-file`:

```yaml
name: reader
description: Reads inventory for the nightly report
duration: 7
project: inventory
permissions:
  - resource: repository
    actions: ["pull"]
```

The CLI also offers `--all-permission`, which gives the robot every permission in the project. That flag is the opposite of what a pipeline needs. `harbor project robot list` and `harbor project robot view` show existing robots, and `harbor robot create` makes system robots.

You can now tell project robots from system robots, read a robot's name, write its permissions as resource and action pairs, create one, and catch its secret. The open question is how to choose the permissions, how long a robot should live, and what to do when its secret leaks.

## Common pitfalls

> [!WARNING]
> - **Losing the secret.** Harbor shows it once. Store it as soon as you create the robot, or you will have to refresh it.
> - **Unquoted robot names in a shell.** `robot$ci+builder` becomes `robot+builder` because the shell expands `$ci`. Always use single quotes.
> - **Push without pull.** A push-only robot fails; give `repository` `pull` with `push`.
> - **Using `--all-permission` "for now".** It stays that way. Write the permissions the job needs.
> - **Signing a tool in as the robot in its default configuration.** It replaces the sign-in other commands rely on. Use a separate configuration file, such as `oras --registry-config`.
