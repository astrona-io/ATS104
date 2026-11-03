# Using A Robot From Registry Clients And The CLI

A robot is useful only when a client signs in with it, and a robot that can reach more than its job needs is a risk. This part signs a registry client in as a robot, shows that the robot's reach ends at its own project, and then creates a robot with the `harbor` CLI from a configuration file, which is the form a pipeline uses.

## Using the robot

The commands below need the secret of the robot `robot$inventory+reader` in the shell variable `READER_SECRET`. If your terminal no longer has it, set it again from the secret that Harbor showed when the robot was created. Then sign `oras` in as the robot with a separate configuration file, so the administrator's sign-in in the workstation stays as it is, and read the manifest of the artifact in `inventory`:

<!-- astrona:playground:renew -->

```sh
printf '%s' "$READER_SECRET" | ws oras login --registry-config /tmp/reader.json -u 'robot$inventory+reader' --password-stdin harbor.localtest.me:8443
ws oras manifest fetch --registry-config /tmp/reader.json harbor.localtest.me:8443/inventory/notes:v1
```

The login succeeds and the manifest prints as JSON. The robot did what its permission allows. Now try to pull from the project `ci`, where it has no permission:

```sh
ws oras manifest fetch --registry-config /tmp/reader.json harbor.localtest.me:8443/ci/app:latest
```

`oras` reports that the request was refused as unauthorized. Harbor's token service gave the robot no access to `ci`, so it does not even learn whether `ci/app` exists. The robot's reach ends at its project.


## The same with the harbor CLI

The `harbor` CLI creates project robots with `harbor project robot create`. Without flags it opens an interactive form. For a script, it reads the same information from a YAML or JSON file given with `--robot-config-file`:

```yaml
name: reader
description: Reads inventory for the nightly report
duration: 7
project: inventory
permissions:
  - resource: repository
    actions: ["pull"]
```

The CLI also offers `--all-permission`, which gives the robot every permission in the project. That flag is the opposite of what a pipeline needs. `harbor project robot list` and `harbor project robot view` show existing robots, and `harbor robot create` makes system robots.


You now know how a registry client signs in as a robot, that a robot's reach ends at its own project, and how the `harbor` CLI creates a robot from a file. The open question is how to choose the permissions, how long a robot should live, and what to do when its secret leaks.

## Common pitfalls

> [!WARNING]
> - **Signing a tool in as the robot in its default configuration.** It replaces the sign-in other commands rely on. Use a separate configuration file, such as `oras --registry-config`.
> - **Using `--all-permission`.** The flag gives the robot every permission in the project. Write the permissions the job needs instead.
> - **Expecting the CLI to ask for missing values in a pipeline.** Without a configuration file or flags, `harbor project robot create` opens an interactive form.
