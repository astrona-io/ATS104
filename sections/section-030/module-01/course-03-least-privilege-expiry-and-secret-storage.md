# Least Privilege, Expiry And Secret Storage

A robot secret ends up in many places: a CI variable, a Kubernetes Secret, sometimes by mistake in a build log or a ConfigMap. Sooner or later one leaks. What the leak costs depends on choices made when the robot was created: what it may do, and how long it lives. This part makes those choices on purpose and stores the secret where a job can read it without anyone seeing it.

## Least privilege: start from the job

**Least privilege** means a credential holds only the permissions its job needs. For a robot, write down the job in one sentence, then pick the resource and action pairs that sentence needs, and nothing else:

| Job | Permissions | Not needed |
| --- | --- | --- |
| CI builds and pushes images to `ci` | `repository` `push` and `pull` in `ci` | delete, any other project |
| A cluster pulls images from `inventory` | `repository` `pull` in `inventory` | push, delete, tag |
| A nightly job reports scan results | `artifact` `read`/`list`, `scan` `read` | push, pull |
| A cleanup job removes old artifacts | `artifact` `list`/`delete` | push |

A robot for a cluster that only pulls does not need push "just in case". If its secret leaks, a pull-only robot lets an attacker read images; a push robot lets them replace the images every pod runs.

## Expiry and disabling

Every robot has a `duration` in days, set when it is created. Harbor's default is 30 days; `-1` means it never expires. When a robot expires, its secret stops working, and the jobs that use it fail. That is the point. A secret that never expires stays useful to an attacker forever, so give long-lived robots a duration and a calendar reminder to refresh them.

A robot can also be disabled without being deleted. Disabling stops every use of the secret at once, which is the fastest response to a suspected leak, and it keeps the robot's ID and history.

## Store the secret in Kubernetes

Create a pull-only robot for a reporting job in `inventory`, valid for 30 days. Save this as `robot-reporter.json` on your machine:

<!-- astrona:playground:renew -->

```json
{
  "name": "reporter",
  "description": "Pulls from inventory for reports",
  "level": "project",
  "duration": 30,
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

Create it, and put its name and secret straight into a Kubernetes Secret, so the secret never appears on your screen:

```sh
RESPONSE="$(ws sh -c 'curl -s -u admin:Harbor12345 -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/robots"' < robot-reporter.json)"
kubectl -n workstation create secret generic inventory-reporter \
  --from-literal=username="$(printf '%s' "$RESPONSE" | ws jq -r '.name')" \
  --from-literal=password="$(printf '%s' "$RESPONSE" | ws jq -r '.secret')"
```

The Secret `inventory-reporter` now holds `username` (`robot$inventory+reporter`) and `password`. A pipeline or a pod reads it from there. For a cluster that pulls images, the same values go into a Secret of type `kubernetes.io/dockerconfigjson` with `kubectl create secret docker-registry`, which the pods name in `imagePullSecrets`.

Read the values back the way a job would, and prove what the robot can and cannot do:

```sh
ROBOT_NAME="$(kubectl -n workstation get secret inventory-reporter -o jsonpath='{.data.username}' | base64 -d)"
ROBOT_SECRET="$(kubectl -n workstation get secret inventory-reporter -o jsonpath='{.data.password}' | base64 -d)"
printf '%s' "$ROBOT_SECRET" | ws oras login --registry-config /tmp/reporter.json -u "$ROBOT_NAME" --password-stdin harbor.localtest.me:8443
ws oras manifest fetch --registry-config /tmp/reporter.json harbor.localtest.me:8443/inventory/notes:v1 >/dev/null && echo "pull: allowed"
ws sh -c 'cd /tmp && echo test > test.txt && oras push --registry-config /tmp/reporter.json harbor.localtest.me:8443/inventory/notes:test test.txt' || echo "push: refused"
```

The login succeeds, the pull prints `pull: allowed`, and the push fails and prints `push: refused`. The variable `$ROBOT_NAME` is in double quotes, so your shell does not expand the `$inventory` inside its value.

You can now choose a robot's permissions from its job, give it a lifetime, and store its secret in Kubernetes without printing it. The open question is what to do when the secret leaks or when its lifetime ends: how to replace it without breaking the robot.

## Common pitfalls

> [!WARNING]
> - **Printing secrets to the terminal or CI log.** Pipe them straight into the Secret, as above.
> - **Robots that never expire.** A `duration` of `-1` keeps a leaked secret useful forever.
> - **Giving a push robot to a cluster that only pulls.** If the secret leaks, an attacker can replace the images every pod runs.

## Your mission: Create A Push-Only Robot For CI

You can now create a robot with exactly the permissions its job needs and store its secret in Kubernetes. The graded lab asks you to give the CI pipeline a project robot `builder` in `ci` that can push and pull there and nothing else, valid for 30 days, with its credentials in the Kubernetes Secret `ci-robot`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-104-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-104-lab-030-01
astrona start ats-104-playground-030-01
```
