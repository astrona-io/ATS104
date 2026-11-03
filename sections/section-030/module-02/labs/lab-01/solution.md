# Solution: Create A System Robot For Two Teams

Work the task yourself first. Running `astrona submit -c sections/section-030/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the robot exists as a system robot with a 30-day lifetime and pull access to the two projects, the Secret holds working credentials that pull from both, and the robot cannot pull from `team-green` or push. Each check runs against the final state.

## Step 1: Look at the starting state

Define the helper and list the projects:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects" | jq -r ".[].name"'
```

The three team projects are there, and no robot exists yet.

## Step 2: Write the robot definition

A system robot has `"level": "system"`. Its `permissions` list holds one entry for each project, each with `"kind": "project"`, the project name in `namespace`, and the access list. Save this as `robot-puller.json` on your machine:

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

A project robot would be limited to one project. The system level is what allows two projects in one robot.

## Step 3: Create the robot and store the secret

Post the file, and put the name and secret straight into a Kubernetes Secret, so the secret never appears on your screen:

```sh
RESPONSE="$(ws sh -c 'curl -s -u admin:Harbor12345 -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/robots"' < robot-puller.json)"
kubectl -n workstation create secret generic puller-credentials \
  --from-literal=username="$(printf '%s' "$RESPONSE" | ws jq -r '.name')" \
  --from-literal=password="$(printf '%s' "$RESPONSE" | ws jq -r '.secret')"
```

Harbor shows the secret only in this response. Without the Secret, the only way to get a new one is a refresh.

## Step 4: Check the Secret

```sh
kubectl -n workstation get secret puller-credentials -o jsonpath='{.data.username}' | base64 -d; echo
```

The output is `robot$puller`.

## Step 5: Prove the boundaries

Sign in with the credentials and try the three actions. Use a separate registry configuration file, so the administrator's sign-in is untouched:

```sh
ROBOT_NAME="$(kubectl -n workstation get secret puller-credentials -o jsonpath='{.data.username}' | base64 -d)"
ROBOT_SECRET="$(kubectl -n workstation get secret puller-credentials -o jsonpath='{.data.password}' | base64 -d)"
printf '%s' "$ROBOT_SECRET" | ws oras login --registry-config /tmp/robot.json -u "$ROBOT_NAME" --password-stdin harbor.localtest.me:8443
ws oras manifest fetch --registry-config /tmp/robot.json harbor.localtest.me:8443/team-red/notes:v1 >/dev/null && echo "red: ok"
ws oras manifest fetch --registry-config /tmp/robot.json harbor.localtest.me:8443/team-blue/notes:v1 >/dev/null && echo "blue: ok"
ws oras manifest fetch --registry-config /tmp/robot.json harbor.localtest.me:8443/team-green/notes:v1 || echo "green: refused"
```

The first two print `ok`, and the third fails, because the robot has no permission on `team-green`.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create a project robot in `team-red` and another in `team-blue` | Two robots and two secrets; the task asks for one system robot |
| Give the robot push as well | The grader tries a push and fails the check |
| Use a system robot with all projects (`*`) | `team-green` becomes readable, which the task forbids |
| Keep the secret in a file | The task asks for a Kubernetes Secret |

## Common mistakes

- Using `"level": "project"`. A project robot cannot hold permissions for two projects.
- Writing `"namespace": "*"`. That covers every project.
- Forgetting that the robot's full name is `robot$puller` and quoting it so the shell expands `$puller`.

## Practice on your own

- Add `team-green` with a second robot that has a 7-day lifetime.
- Disable the robot with `PUT /robots/<id>` and `"disable": true`, and check that a pull fails.
- Read the audit log for the robot's creation.
