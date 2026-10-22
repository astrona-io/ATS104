# Solution: Create A Push-Only Robot For CI

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the robot's level, duration and permissions; a push to `ci` with the credentials in `ci-robot`; and a refused push to `inventory` with the same credentials.

## Step 1: Write the robot's definition

The job is "push and pull in `ci`". That is two resource and action pairs on one project. Save this as `robot-builder.json` on your machine:

```json
{
  "name": "builder",
  "description": "CI pushes to the project ci",
  "level": "project",
  "duration": 30,
  "permissions": [
    {
      "kind": "project",
      "namespace": "ci",
      "access": [
        {"resource": "repository", "action": "push"},
        {"resource": "repository", "action": "pull"}
      ]
    }
  ]
}
```

`level` `project` and the single `permissions` entry for `ci` make it a project robot, so Harbor names it `robot$ci+builder`. Pull is there because push needs it.

## Step 2: Create the robot and store its secret

Harbor shows the secret once, in the response to the create request. Send the request and put the name and secret straight into the Kubernetes Secret:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
RESPONSE="$(ws sh -c 'curl -s -u admin:Harbor12345 -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/robots"' < robot-builder.json)"
kubectl -n workstation create secret generic ci-robot \
  --from-literal=username="$(printf '%s' "$RESPONSE" | ws jq -r '.name')" \
  --from-literal=password="$(printf '%s' "$RESPONSE" | ws jq -r '.secret')"
```

If the response is an error instead of a robot, print it with `printf '%s' "$RESPONSE"`: a robot with the same name already exists, or the JSON has a typo.

The `harbor` CLI can do the same with `harbor project robot create --robot-config-file` and a YAML file with `name`, `duration`, `project` and `permissions`. Make sure you catch the secret it prints.

## Step 3: Check the robot from Harbor's side

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/robots?page_size=100"' \
  | ws jq '.[] | select(.name == "robot$ci+builder") | {name, level, duration, disable, access: [.permissions[] | .namespace as $p | .access[] | "\($p) \(.resource):\(.action)"]}'
```

The robot is at level `project`, has duration `30`, is not disabled, and has exactly `ci repository:push` and `ci repository:pull`.

## Step 4: Prove what it can and cannot do

Read the credentials back from the Secret, the way the pipeline will, and push to both projects:

```sh
ROBOT_NAME="$(kubectl -n workstation get secret ci-robot -o jsonpath='{.data.username}' | base64 -d)"
ROBOT_SECRET="$(kubectl -n workstation get secret ci-robot -o jsonpath='{.data.password}' | base64 -d)"
printf '%s' "$ROBOT_SECRET" | ws oras login --registry-config /tmp/builder.json -u "$ROBOT_NAME" --password-stdin harbor.localtest.me:8443
ws sh -c 'cd /tmp && echo build > build.txt && oras push --registry-config /tmp/builder.json harbor.localtest.me:8443/ci/app:build-1 build.txt'
ws sh -c 'cd /tmp && oras push --registry-config /tmp/builder.json harbor.localtest.me:8443/inventory/app:build-1 build.txt' || echo "push to inventory: refused"
```

The push to `ci` succeeds and prints the digest. The push to `inventory` fails and prints `push to inventory: refused`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `--all-permission` | The robot can also delete repositories and artifacts in `ci`; the grader accepts push and pull only |
| Push only, no pull | Registry clients fail to push; Harbor's documentation requires pull with push |
| A system robot with access to `ci` | Its name is `robot$builder`, not `robot$ci+builder`, and system robots are for jobs that span projects |
| `duration: -1` | The secret never expires; the task asks for 30 days |

## Common mistakes

- Writing `robot$ci+builder` in double quotes in the shell, so `$ci` expands to nothing.
- Creating the Secret from a value copied off the screen, with a trailing newline or a missing character.
- Signing `oras` in as the robot in its default configuration, which replaces the administrator's sign-in in the workstation.
