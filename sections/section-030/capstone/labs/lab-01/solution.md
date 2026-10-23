# Solution: Rotate A Leaked Robot Secret

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: the robot kept its ID, its permissions and duration, that the leaked secret is dead, and that the new secret pulls but cannot push.

## Step 1: Look at the robot and the leak

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ROBOT="$(ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/robots?page_size=100&q=Level=project,ProjectID=$(curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory" | jq .project_id)"' | ws jq -c '.[] | select(.name == "robot$inventory+deployer")')"
printf '%s' "$ROBOT" | ws jq '{id, name, duration, access: [.permissions[] | .namespace as $p | .access[] | "\($p) \(.resource):\(.action)"]}'
ROBOT_ID="$(printf '%s' "$ROBOT" | ws jq -r '.id')"
```

The robot has duration `-1` (it never expires) and four permissions in `inventory`: `repository` push, pull and delete, and `artifact` delete. Deploying needs only `repository` pull.

## Step 2: Revoke the leaked secret first

A leak is an incident, so the first action is the one that stops the damage: refresh the secret. A new secret you choose must be 8 to 128 characters with an uppercase letter, a lowercase letter and a digit:

```sh
ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X PATCH -H 'Content-Type: application/json' -d '{\"secret\":\"Deployer-Rotated-2026\"}' \"\$HARBOR_URL/api/v2.0/robots/$ROBOT_ID\""
```

The request returns `200`. From this moment, the secret in `leaked-credentials` is useless. The `harbor` CLI does the same with `harbor project robot refresh <id>`, where Harbor generates the secret.

## Step 3: Cut the permissions and set an expiry

`PUT /api/v2.0/robots/<id>` replaces the robot's settings with the object you send, so start from the full object that `GET` returns and change only `permissions` and `duration`:

```sh
ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0/robots/$ROBOT_ID\"" \
  | ws jq -c '.duration = 90 | .permissions = [{"kind":"project","namespace":"inventory","access":[{"resource":"repository","action":"pull"}]}]' \
  | ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X PUT -H 'Content-Type: application/json' --data-binary @- \"\$HARBOR_URL/api/v2.0/robots/$ROBOT_ID\""
```

The request returns `200`. The robot keeps its ID and name.

## Step 4: Store the new secret

```sh
kubectl -n workstation create secret generic deployer-robot \
  --from-literal=username='robot$inventory+deployer' --from-literal=password='Deployer-Rotated-2026'
```

The name is in single quotes, so the shell does not expand `$inventory`.

## Step 5: Prove the result

```sh
OLD_SECRET="$(kubectl -n workstation get configmap leaked-credentials -o jsonpath='{.data.password}')"
printf '%s' "$OLD_SECRET" | ws oras login --registry-config /tmp/old.json -u 'robot$inventory+deployer' --password-stdin harbor.localtest.me:8443 || echo "leaked secret: refused"
printf '%s' 'Deployer-Rotated-2026' | ws oras login --registry-config /tmp/new.json -u 'robot$inventory+deployer' --password-stdin harbor.localtest.me:8443
ws oras manifest fetch --registry-config /tmp/new.json harbor.localtest.me:8443/inventory/notes:v1 >/dev/null && echo "pull: allowed"
ws sh -c 'cd /tmp && echo x > x.txt && oras push --registry-config /tmp/new.json harbor.localtest.me:8443/inventory/notes:x x.txt' || echo "push: refused"
```

The output is `leaked secret: refused`, a successful login, `pull: allowed` and `push: refused`.

## Step 6: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the robot and create a new `deployer` | The ID changes, and the deploy jobs that refer to it break; the grader rejects it |
| Cut the permissions but keep the secret | Whoever read the ConfigMap can still pull every artifact in `inventory` |
| Delete the ConfigMap and call it done | The secret is still valid wherever it was copied |
| `PUT` with only `{"permissions": [...]}` | Fields you leave out can be reset; always start from the `GET` response |

## Common mistakes

- Refreshing the secret last, so the leaked one stays valid while you work.
- Keeping `repository` `push` "for redeploys"; deploying only pulls.
- Leaving `duration` at `-1`.
