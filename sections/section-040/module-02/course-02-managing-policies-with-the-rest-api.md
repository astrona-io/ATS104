# Managing Policies With The REST API

Creating a policy is half the work. A policy has to be found, tested, changed, switched off and removed, and a script should do those things the same way every time. This part shows the requests. All of them are under `/api/v2.0/projects/{project}/webhook`.

## List and read

```sh
api() { ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0$1\" | jq"; }
api /projects/inventory/webhook/policies
```

The answer is a list of policies. Each has an `id`, `name`, `enabled`, `event_types`, `targets` and the times of creation and update. A policy is read alone at `/webhook/policies/{id}`. Find the ID of a policy by its name with `jq`:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies" | jq -r ".[] | select(.name == \"audit-deletes\") | .id"'
```

The same filter by name is the idempotent way to create: read first, create only when the name is missing.

## Create

A `POST` to `/webhook/policies` with the policy body answers `201`. A second `POST` with the same name answers `409`, as with other objects. The body is the one the first module used: `name`, `enabled`, `event_types` and `targets`.

## Test a target

Before a policy goes live, check that Harbor can reach the target and that the receiver accepts the request. The test endpoint sends a sample request to the targets you give it:

```sh
ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -u admin:Harbor12345 -H "Content-Type: application/json" -d "{\"targets\":[{\"type\":\"http\",\"address\":\"http://echo.hooks.svc.cluster.local:8080/test\",\"auth_header\":\"Bearer test\",\"skip_cert_verify\":false}]}" "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies/test"'
```

A `200` answer means the receiver accepted the test request. Read the receiver log to see what arrived. A failure answer carries the reason, for example a connection error or a TLS error, which is faster than waiting for a real event.

## Update, disable and delete

A policy is changed with `PUT /webhook/policies/{id}` and the whole policy body, as for robots: read the policy, edit that copy and send it back. To disable a policy, set `enabled` to false:

```sh
ID=<policy id>
ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies/$ID\"" \
  | ws jq '.enabled = false' \
  | ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -u admin:Harbor12345 -X PUT -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/projects/inventory/webhook/policies/'$ID'"'
```

A disabled policy sends nothing and keeps its settings, which makes it the right switch for a receiver that is down for maintenance. Delete with `DELETE /webhook/policies/{id}`. A delete answers `200`, and a second one answers `404`.

## When did an event last fire

```sh
api /projects/inventory/webhook/lasttrigger
```

The answer lists each event type with the policy that handles it, whether the policy is enabled, and the time of the last trigger. It answers "has this ever fired" without reading logs. An event type with no last trigger time has not fired since the policy was created.

## Executions and tasks

Every delivery is an execution of the policy, and each execution has tasks, as the first module showed. Use the executions to see the status of the latest deliveries after you change a policy. A script that waits for a delivery reads `/webhook/policies/{id}/executions` and stops when the newest status is not `Running`.

## The same with the CLI

The `harbor` CLI has `harbor webhook` commands for policies: `list`, `create`, `update`, `delete` and a way to read executions. Check `harbor webhook --help` for the version you run before you use a flag from an older example. For scripts, the REST API above is the stable choice, since the same calls work from any language.

## Common pitfalls

> [!WARNING]
> - **Sending a partial body with `PUT`.** Fields you leave out are cleared. Read, edit, send.
> - **Creating a policy without reading first.** A second run answers `409`. Look up the name.
> - **Skipping the test.** A policy that has never reached its target fails on the first real event.
> - **Deleting a policy to pause it.** Set `enabled` to false so the settings remain.
