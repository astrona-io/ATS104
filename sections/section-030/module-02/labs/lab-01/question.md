# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** System robot accounts

## Scenario

A cluster-wide image puller needs to read artifacts from two teams' projects, `team-red` and `team-blue`, and from nothing else. A robot account for each project would mean two secrets to store and rotate. The platform team wants one **system robot** instead. The project `team-green` belongs to a third team and must stay out of reach. The secret should stop working after a month unless someone renews it, and it must be stored in the cluster, not typed into a file.

The workstation pod has the `harbor` CLI (signed in as the administrator), `oras`, `curl` and `jq`. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/workstation -- <command>
```

## Your task

1. Create a **system robot** named `puller` (the full name is `robot$puller`) with a lifetime of **30 days**.
2. Give it **pull** access to the repositories of `team-red` and `team-blue`, and no other permission. It must not be able to push, and it must not reach `team-green`.
3. Store the robot's name and secret in a Kubernetes Secret named `puller-credentials` in the namespace `workstation`, with the keys `username` and `password`.

## Constraints

- Do not use the administrator's credentials for the pulls the grader makes; they use the Secret.
- Do not change the projects or their artifacts.
- Leave the robot enabled.

## Done when

- A system robot `robot$puller` exists, is enabled and has a duration of 30 days.
- Its permissions cover `team-red` and `team-blue` only, each with `repository` `pull` and nothing else.
- The Secret `puller-credentials` holds `username` `robot$puller` and its working secret.
- Signed in with that Secret, `oras pull` of `team-red/notes:v1` and `team-blue/notes:v1` works, `oras pull` of `team-green/notes:v1` fails, and a push to `team-red` fails.
