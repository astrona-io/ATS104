# Solution: Bootstrap A CI Project End To End

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the robot and the policy kept their IDs, the policy's settings, and a real push by the robot that reaches the receiver as a CloudEvent with the auth header.

## Step 1: Reproduce both failures

Read the robot's credentials and try the CI push:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
ROBOT_NAME="$(kubectl -n workstation get secret ci-robot -o jsonpath='{.data.username}' | base64 -d)"
ROBOT_SECRET="$(kubectl -n workstation get secret ci-robot -o jsonpath='{.data.password}' | base64 -d)"
printf '%s' "$ROBOT_SECRET" | ws oras login --registry-config /tmp/builder.json -u "$ROBOT_NAME" --password-stdin harbor.localtest.me:8443
ws sh -c 'cd /tmp && echo build > build.txt && oras push --registry-config /tmp/builder.json harbor.localtest.me:8443/ci/app:build-1 build.txt' || echo "push: refused"
```

The login works, so the secret is fine, but the push is refused. Look at the robot and the policy:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/robots?page_size=100"' \
  | ws jq '.[] | select(.name == "robot$ci+builder") | {id, access: [.permissions[].access[] | "\(.resource):\(.action)"]}'
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/ci/webhook/policies"' \
  | ws jq '.[] | select(.name == "notify-ci")'
```

## Step 2: List every fault

| Object | Fault | Effect |
| --- | --- | --- |
| Robot | Only `repository:pull` | The push is refused |
| Policy | `enabled: false` | Nothing is ever sent |
| Policy | `event_types: ["DELETE_ARTIFACT"]` | Pushes do not match the policy |
| Policy target | `https://...:8443` with certificate verification on | The receiver's self-signed certificate fails the TLS handshake |
| Policy target | `payload_format: Default` | The pipeline reads CloudEvents |

## Step 3: Fix the robot in place

Start from the full robot object, change only its permissions, and send it back with `PUT`. The secret does not change:

```sh
ROBOT_ID="$(ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/robots?page_size=100"' | ws jq -r '.[] | select(.name == "robot$ci+builder") | .id')"
ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0/robots/$ROBOT_ID\"" \
  | ws jq -c '.permissions = [{"kind":"project","namespace":"ci","access":[{"resource":"repository","action":"push"},{"resource":"repository","action":"pull"}]}]' \
  | ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X PUT -H 'Content-Type: application/json' --data-binary @- \"\$HARBOR_URL/api/v2.0/robots/$ROBOT_ID\""
```

The request returns `200`.

## Step 4: Fix the policy in place

Start from the full policy and change the switch, the event, the endpoint and the format. Inside the cluster, the plain HTTP endpoint on port `8080` is the right choice: the receiver's certificate is not trusted, and turning verification off would send the auth header to whoever answers at that address.

```sh
POLICY_ID="$(ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/ci/webhook/policies"' | ws jq -r '.[] | select(.name == "notify-ci") | .id')"
ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0/projects/ci/webhook/policies/$POLICY_ID\"" \
  | ws jq -c '.enabled = true | .event_types = ["PUSH_ARTIFACT"] | .targets = [{"type":"http","address":"http://echo.hooks.svc.cluster.local:8080/harbor","auth_header":"Bearer pipeline-token-123","skip_cert_verify":false,"payload_format":"CloudEvents"}]' \
  | ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X PUT -H 'Content-Type: application/json' --data-binary @- \"\$HARBOR_URL/api/v2.0/projects/ci/webhook/policies/$POLICY_ID\""
```

The request returns `200`.

## Step 5: Prove the whole path

Push as the robot again, and read the receiver's log:

```sh
ws sh -c 'cd /tmp && oras push --registry-config /tmp/builder.json harbor.localtest.me:8443/ci/app:build-2 build.txt'
kubectl -n hooks logs deploy/echo --since=5m | tail -n 80
```

The push succeeds. A few seconds later the receiver logs a `POST` to `/harbor` with `authorization: Bearer pipeline-token-123`, and a body with `specversion`, `type` `harbor.artifact.pushed`, and `data` naming `ci/app` with the tag `build-2`.

## Step 6: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete and recreate the robot with the right permissions | The ID changes and the secret changes, so `ci-robot` is stale too; the grader rejects it |
| Delete and recreate the policy | Its ID changes; the grader rejects it |
| `skip_cert_verify: true` on the HTTPS endpoint | Delivery works, but the auth header goes to whoever answers at that address; prefer the internal HTTP endpoint or a trusted certificate |
| `--all-permission` on the robot | It can delete in `ci`; pushing needs push and pull only |

## Common mistakes

- Fixing the event type but not the switch, or the switch but not the endpoint, and testing only once.
- Sending a partial object with `PUT`, which can reset fields you left out.
- Reading the policy instead of watching the receiver; a policy can look right and still fail to deliver.
