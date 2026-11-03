# Robots In Pipelines And Kubernetes Pull Secrets

A robot is only useful where its secret can be used. Two places matter: a pipeline that pushes, and a cluster that pulls. For the pipeline, the secret lives in the pipeline's secret store and is passed to `oras login` or `docker login` with `--password-stdin`. For the cluster, the secret becomes a Kubernetes image pull Secret. This part covers the second, which is the one people get wrong.

## The image pull Secret

A pod that uses a private image needs credentials for the registry. Kubernetes keeps them in a Secret of type `kubernetes.io/dockerconfigjson`. Create it with the robot's name and secret taken from the Secret you stored earlier:

```sh
kubectl -n workstation create secret docker-registry harbor-pull \
  --docker-server=harbor.localtest.me:8443 \
  --docker-username="$(kubectl -n workstation get secret puller-credentials -o jsonpath='{.data.username}' | base64 -d)" \
  --docker-password="$(kubectl -n workstation get secret puller-credentials -o jsonpath='{.data.password}' | base64 -d)"
```

The server name must match the registry host in the image reference exactly, port included. The user name contains a `$`, so it stays in double quotes and in a command substitution; a plain string in double quotes would let the shell expand `$puller`.

## Using the Secret

A pod names the Secret in `imagePullSecrets`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: notes-reader
  namespace: workstation
spec:
  imagePullSecrets:
    - name: harbor-pull
  containers:
    - name: reader
      image: harbor.localtest.me:8443/team-red/app:v1
```

To apply the Secret to every pod of a namespace, add it to the service account instead of to each pod:

```sh
kubectl -n workstation patch serviceaccount default -p '{"imagePullSecrets":[{"name":"harbor-pull"}]}'
```

The kubelet pulls the image on the node, so the node must also trust Harbor's certificate authority and reach the registry address. The Secret solves authentication only.

## One Secret for each namespace

An image pull Secret is a namespaced object. A pod can use only Secrets from its own namespace, so the same credentials are copied into every namespace that pulls. Copying means more places to update when the secret is refreshed. Keep the list of namespaces, and refresh them in one script, in the order the first module taught: refresh in Harbor, update every store, check the old secret fails.

## Rotation and expiry in a cluster

A robot that expires makes new pods fail with `ImagePullBackOff` and an authentication error in the pod events. Pods that already run are not affected until they restart, so the failure shows up later and far from its cause. Two habits prevent it:

- Warn 14 days before `expires_at`, with the job from the lifecycle part.
- After a refresh, check a fresh pod can pull: run a small pod that uses the Secret and read its events.

Describe the pod to see the reason:

```sh
kubectl -n workstation describe pod notes-reader | tail -n 15
```

An `unauthorized` message means the secret is wrong or expired. A `denied` message means the robot has no permission on that project. The two need different fixes.

## Pipelines

For a push pipeline, never write the secret into the repository or echo it into a log. Read it from the pipeline's secret store into an environment variable and pass it on standard input:

```sh
printf '%s' "$HARBOR_ROBOT_SECRET" | oras login harbor.localtest.me:8443 -u "$HARBOR_ROBOT_NAME" --password-stdin
```

Mask the variable in the pipeline's log settings, and use a separate robot for each pipeline so that a leak points at one pipeline.

## Your mission: Create A System Robot For Two Teams

You can now create a robot that spans several projects, manage its lifecycle, read its trail and hand its credentials to a cluster. The graded lab asks you to create a system robot `puller` with pull access to `team-red` and `team-blue` only, valid for 30 days, with its credentials in the Kubernetes Secret `puller-credentials`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-104-playground-030-02
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-030/module-02/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-104-lab-030-02
astrona start ats-104-playground-030-02
```

## Common pitfalls

> [!WARNING]
> - **A wrong server name in the pull Secret.** It must match the host and port in the image reference.
> - **Putting the Secret in the wrong namespace.** A pod reads Secrets from its own namespace only.
> - **Forgetting existing pods.** A refreshed or expired secret affects only new pulls, so failures appear on the next restart.
> - **Letting the shell expand the robot name.** `robot$puller` in double quotes loses `$puller`. Use a command substitution or single quotes.
> - **Echoing the secret in a log.** Use `--password-stdin` and mask the variable.
