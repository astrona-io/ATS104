# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster. Every Harbor command in this course runs through `kubectl exec` in a pod, so you do not need the Harbor tools on your machine.
- **The astrona command-line tool.**
- **A text editor:** you write shell and Python scripts on your machine and copy them into a pod.
- **A web browser (optional):** to look at the Harbor portal through `kubectl port-forward`.

Harbor needs memory. Give your container engine at least **4 GiB**. The playgrounds and labs also need **outbound internet** while they start: they download Harbor's images, Helm, the client tools from GitHub and the Python image. The first start of each environment takes up to fifteen minutes. Without outbound internet, the start fails with download errors that have nothing to do with Harbor.

## How you work in the pods

You run every Harbor command in the `workstation` pod and every Python script in the `python-runner` pod. Two short helpers save typing; define them in each new terminal:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
```

Now `ws harbor project list` runs the `harbor` CLI in the workstation pod. When a page asks you to write a script, you save it on your machine and copy it into the pod with a command like `ws sh -c 'cat > /work/onboard.sh' < onboard.sh`. The pod keeps it in its `/work` folder until the pod restarts.

To look at the web portal, forward its port in a second terminal and open `https://harbor.localtest.me:8443`:

```sh
kubectl -n harbor port-forward svc/harbor 8443:8443
```

The name `harbor.localtest.me` is a public DNS name that points at `127.0.0.1`, your own machine, so the port-forward answers it. Your browser warns about the certificate, because the lab generated its own certificate authority. Some home routers block DNS answers that point at `127.0.0.1`. If the name does not resolve, add this line to `/etc/hosts` on your machine:

```
127.0.0.1 harbor.localtest.me
```

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It runs your scripts again, pushes with your robot account and reads the webhook receiver, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-104-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own Harbor. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start seems stuck, it is usually still installing Harbor, which can take up to fifteen minutes. If it fails while it downloads something, check your network first. If `ws` says the pod is not found, the environment is still starting; wait and try again. With your machine ready and these commands at hand, you can start the first module.
