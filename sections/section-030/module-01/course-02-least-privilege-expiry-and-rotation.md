# Least Privilege, Expiry And Rotation

A robot secret ends up in many places: a CI variable, a Kubernetes Secret, sometimes by mistake in a build log or a ConfigMap. Sooner or later one leaks. What the leak costs depends on three choices made when the robot was created: what it may do, how long it lives, and how fast its secret can be replaced. This part makes those three choices on purpose.

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

## Rotate the secret

**Rotating** a secret means replacing it with a new one so the old one stops working. Harbor calls this refreshing. `PATCH /api/v2.0/robots/<id>` with a body `{"secret": "<new secret>"}` sets a new secret you choose; it must be 8 to 128 characters with an uppercase letter, a lowercase letter and a digit. The `harbor` CLI does the same with `harbor project robot refresh <id>`, which lets Harbor generate a random secret, or takes yours with `--secret-stdin`.

Find the robot's ID, and refresh its secret:

```sh
ROBOT_ID="$(ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/robots?page_size=100"' | ws jq -r '.[] | select(.name == "robot$inventory+reporter") | .id')"
ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X PATCH -H 'Content-Type: application/json' -d '{\"secret\":\"Reporter-Rotated-2026\"}' \"\$HARBOR_URL/api/v2.0/robots/$ROBOT_ID\""
```

The `PATCH` returns `200`. The old secret, still in the Secret `inventory-reporter` and in `$ROBOT_SECRET`, now fails:

```sh
printf '%s' "$ROBOT_SECRET" | ws oras login --registry-config /tmp/old.json -u "$ROBOT_NAME" --password-stdin harbor.localtest.me:8443 || echo "old secret: refused"
```

The login fails and prints `old secret: refused`. The robot kept its ID, name and permissions; only the secret changed. The last step of every rotation is to update every place that holds the secret, here the Kubernetes Secret:

```sh
kubectl -n workstation create secret generic inventory-reporter \
  --from-literal=username="$ROBOT_NAME" --from-literal=password='Reporter-Rotated-2026' \
  --dry-run=client -o yaml | kubectl apply -f -
```

Changing a robot's permissions or duration goes through `PUT /api/v2.0/robots/<id>` with the whole robot object: read it with `GET`, change `permissions` or `duration`, and send it back. Harbor replaces the robot's settings with what you send, so a `PUT` with a partial object can remove what you left out.

You can now choose a robot's permissions from its job, give it a lifetime, store its secret in Kubernetes, and rotate it in place. Together these keep the cost of a leaked secret small and the response to it fast.

## Common pitfalls

> [!WARNING]
> - **Deleting and recreating a robot to "rotate" it.** Its ID changes, and audit history and any automation that refers to the ID break. Refresh the secret instead.
> - **Rotating without updating the stores.** Every job that holds the old secret fails. List where the secret lives before you rotate.
> - **Printing secrets to the terminal or CI log.** Pipe them straight into the Secret, as above.
> - **Sending a partial object with `PUT`.** Fields you leave out can be reset. Always start from the `GET` response.
> - **Robots that never expire.** A `duration` of `-1` keeps a leaked secret useful forever.

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
