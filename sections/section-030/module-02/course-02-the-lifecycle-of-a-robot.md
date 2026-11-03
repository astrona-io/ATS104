# The Lifecycle Of A Robot

A robot is created, used, renewed and in the end removed. Most security problems with robots come from the end of this list: a robot that nobody remembers, still valid, still with its permissions. This part shows how to find robots, stop one without deleting it, change one, and remove one.

## Listing robots

System robots are listed at `/robots`. Project robots need a filter for the level and the project ID, as the first module showed:

```sh
api '/robots?page_size=100'
```

Each robot has an `id`, `name`, `level`, `duration` in days, `expires_at`, `disable`, `creation_time` and its `permissions`. To find the robots that expire soon, compare `expires_at` with the current time. A weekly job that lists the robots and warns about each one that expires within 14 days prevents the surprise of a pipeline that stops on a Monday morning.

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/robots?page_size=100" | jq -r --argjson soon "$(( $(date +%s) + 14*86400 ))" ".[] | select(.expires_at > 0 and .expires_at < \$soon) | .name"'
```

A robot with `duration` `-1` has an `expires_at` of `-1`, which the filter skips on purpose. Such robots are the ones to review by hand.

## Disabling and enabling

Disabling stops every use of the secret at once and keeps the robot. It is the first response to a suspected leak, because it can be undone. Read the robot, set `disable` and send the whole object back with `PUT`:

```sh
ID=<robot id>
ws sh -c "curl -s -u admin:Harbor12345 \"\$HARBOR_URL/api/v2.0/robots/$ID\"" | ws jq '.disable = true' | ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -u admin:Harbor12345 -X PUT -H "Content-Type: application/json" --data-binary @- "$HARBOR_URL/api/v2.0/robots/'$ID'"'
```

The answer is `200`. A pull with the robot's secret now fails with an authentication error. Set `disable` to `false` the same way and the secret works again.

## Replacing the definition

`PUT /robots/{id}` replaces the robot's settings with what you send: the description, the duration, the permissions and the disable flag. A body with a shorter permission list removes the missing entries, so read the robot first and edit that copy instead of writing a body from memory. The secret does not change with a `PUT`. A `PATCH` with a new secret changes the secret and nothing else.

The duration counts from the creation time of the robot. To extend a robot, send a larger `duration`, and check `expires_at` afterwards. To renew without extending beyond a policy, create a new robot, switch the pipeline, and delete the old one.

## Deleting a robot

```sh
ws sh -c "curl -s -o /dev/null -w '%{http_code}\n' -u admin:Harbor12345 -X DELETE \"\$HARBOR_URL/api/v2.0/robots/$ID\""
```

A delete answers `200`, and a second one answers `404`. The secret stops working at once, and the robot cannot be restored. A new robot with the same name gets a new ID and a new secret. Disable first, wait until nothing complains, then delete. That order catches the job nobody knew used the robot.

## A simple lifecycle policy

| Stage | Rule |
| --- | --- |
| Creation | One robot per job, a named owner in the description, a duration of 90 days or less |
| Use | Credentials only in a Kubernetes Secret or the pipeline's secret store |
| Renewal | Warn 14 days before `expires_at`, then refresh or replace |
| Suspicion | Disable at once, then refresh the secret, then enable |
| Retirement | Disable, wait one release cycle, then delete |

Put the owner in the `description`. Harbor shows it in the list, and it answers "who do I ask" at the moment it matters.

## Common pitfalls

> [!WARNING]
> - **Sending a partial body with `PUT`.** The permissions you leave out are removed. Read, edit, send.
> - **Deleting before disabling.** A job you did not know about fails with no warning. Disable first.
> - **Using `-1` as a duration.** The robot never expires. Use it only with a written reason.
> - **Forgetting the owner.** A robot without a description is the one nobody dares to delete.
