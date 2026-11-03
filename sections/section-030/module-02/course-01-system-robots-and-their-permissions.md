# System Robots And Their Permissions

A project robot belongs to one project. Its name starts with `robot$` followed by the project, a plus sign and the robot name, and it can hold permissions for that project only. Some jobs need more than that: an image puller that reads from several teams' projects, or a backup job that reads every repository. For those jobs Harbor has the **system robot**.

## What makes a robot a system robot

A system robot is created with `"level": "system"`. It does not belong to a project, so its name has no project part. A system robot called `puller` has the full name `robot$puller`. The prefix `robot$` is the default and an administrator can change it in the system configuration, so a script should read the name from the creation response and not build it by hand.

The permissions of a system robot are a list. Each entry names one project in `namespace` and gives the access for that project:

```json
{
  "name": "puller",
  "description": "Pulls from team-red and team-blue",
  "level": "system",
  "duration": 30,
  "permissions": [
    {"kind": "project", "namespace": "team-red",
     "access": [{"resource": "repository", "action": "pull"}]},
    {"kind": "project", "namespace": "team-blue",
     "access": [{"resource": "repository", "action": "pull"}]}
  ]
}
```

The two entries are independent. A robot may have `pull` on one project and `push` and `pull` on another.

## Creating a system robot

Only a system administrator can create a system robot. Save the definition above as `robot-puller.json`, then post it:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/robots"' < robot-puller.json | ws jq '{id, name, secret, expires_at}'
```

The answer holds the `id`, the `name` (`robot$puller`), the `secret` and `expires_at`, a Unix time. The secret appears only in this answer. Store it at once, as the first module showed.

## The wildcard namespace

An entry may use the namespace `*` instead of a project name:

```json
{"kind": "project", "namespace": "*", "access": [{"resource": "repository", "action": "pull"}]}
```

This grants the access in every project, including projects that do not exist yet. It suits a registry-wide backup job or a scanner and it is dangerous for anything else, because a new team's project becomes readable by the robot on the day it is created. Prefer a list of named projects, and review it when a project is added.

Compare the two forms with the same test: create the robot, sign in with it, and try to pull from a project that is not on its list. With named projects the pull is refused. With `*` it works.

## What a system robot cannot do

A robot is not an administrator even when it is a system robot. It has only the resources and actions that were listed. It cannot create projects, change users or read the audit log unless a system-level permission allows it, and a pipeline should never be given those. The least-privilege rule from the first module applies in full: start from the job and add only what it needs.

You can create a robot that spans several projects and you know why `*` needs a good reason. The next part follows a robot through its life.

## Common pitfalls

> [!WARNING]
> - **Using `*` for convenience.** Every project created later becomes readable. Name the projects.
> - **Building the robot's name by hand.** The prefix can be changed. Read `name` from the creation response.
> - **Making one system robot for every job.** A leaked secret then opens everything. Make one robot per job or per team.
> - **Trying to create a system robot as a project administrator.** Only a system administrator can.
