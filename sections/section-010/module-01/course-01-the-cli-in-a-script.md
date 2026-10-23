# The harbor CLI In A Script

A command you type yourself can ask you a question, and you answer it. A command in a pipeline cannot: there is no person and no terminal, so a question either hangs the job until it times out or fails it with an error that is hard to read. This part shows how the `harbor` command-line tool (CLI) keeps its sign-in, why a script should use a saved sign-in instead of signing in itself, and how a script reads the answers the CLI gives back.

## Where the CLI keeps its sign-in

The CLI does not ask for a password on every command. It signs in once and saves the result as a **context**: a name, the Harbor server address, the user name and the password. All contexts live in one configuration file, by default `~/.config/harbor-cli/config.yaml`, and one of them is the current context that every command uses.

The workstation pod already has one context, called `admin`, that the bootstrap created. List the contexts the CLI knows:

<!-- astrona:playground:renew -->

```sh
ws harbor context list
```

The list shows the context `admin` for the user `admin` at `https://harbor.localtest.me:8443`, marked as the current one. Now look at the file behind it:

```sh
ws cat /root/.config/harbor-cli/config.yaml
```

The file has the key `current-credential-name` and a list `credentials`, with one entry holding `name`, `username`, `password` and `serveraddress`. The password is not readable: it is a Base64 string of encrypted bytes. The CLI encrypts saved passwords with AES-GCM, a standard encryption algorithm, and it needs a key to do so.

## The encryption key in a container

The CLI looks for that key in three places, in this order. First it reads the environment variable `HARBOR_ENCRYPTION_KEY`. If that is not set, it uses the operating system's keyring, the protected store for secrets that macOS, Windows and Linux desktops provide. A container has no such keyring, so without the variable the CLI falls back to a key file under `~/.harbor/keyring/` and prints a warning; the CLI documentation calls this fallback less secure. For containers and CI jobs, set `HARBOR_ENCRYPTION_KEY`.

The workstation pod gets its key from the Kubernetes Secret `harbor-cli-key`, which the bootstrap filled with 32 random bytes. Check that the variable is set, without printing it:

```sh
ws sh -c 'test -n "$HARBOR_ENCRYPTION_KEY" && echo "HARBOR_ENCRYPTION_KEY is set"'
```

The command prints the confirmation line. This is the pattern for a pipeline: the key comes from the CI system's secret store, so the configuration file on the runner is useless to anyone who copies it without the key.

```mermaid
flowchart LR
    S["Secret: harbor-cli-key"] -->|"env"| C["harbor CLI"]
    P["password typed at a prompt"] --> C
    C -->|"AES-GCM"| F["config.yaml"]
    C -->|"REST API"| H["Harbor core"]
```

The diagram shows the CLI taking the password from a person at a prompt and the key from the environment, writing only the encrypted password to its configuration file, and then calling Harbor's API.

## Signing in once, at a terminal

`harbor login` takes the server address as its argument, the user name with `-u` and the context name with `-n`. It gets the password in one of two ways. The flag `-p` takes the password on the command line. The flag `--password-stdin` makes the CLI print `Password:` and wait for you to type it, without showing what you type.

The name `--password-stdin` is misleading in CLI v0.0.27. Other tools such as `docker login` and `oras login` read a password that another command pipes in. The `harbor` CLI does not: it reads the password from a terminal only, so a piped password fails with the error `failed to read password from stdin: inappropriate ioctl for device`. A pipeline has no terminal, and the CLI has no environment variable for the password either.

So a script does not sign in at all. A person signs in once at a terminal and the CLI saves the context. The script then only selects that context with `harbor context switch`, which needs no password and no terminal.

Sign in as the user `demo-dev` (lab-only password `Demo-Dev-2026`) into a new context. The `-t` flag of `kubectl exec` gives the command in the pod a terminal, so the prompt works. Type the password when the CLI asks for it:

```sh
kubectl -n workstation exec -it deploy/workstation -- harbor login https://harbor.localtest.me:8443 -u demo-dev --password-stdin -n demo-dev
```

`harbor login` checks the user name and password against Harbor before it saves anything, so a wrong password fails here and not three commands later. The new context `demo-dev` is now the current one.

Now act as a script. The next command has no terminal and gets an empty standard input. It first makes `admin` current, so that the script part must select `demo-dev` itself. Then it selects the saved context `demo-dev`, lists the projects as that user, and switches back to `admin`:

```sh
ws sh -c 'harbor context switch admin </dev/null; harbor context switch demo-dev </dev/null && harbor project list </dev/null; harbor context switch admin </dev/null'
```

As `demo-dev`, the list shows only `library`, the public project every new Harbor has. `inventory` is missing, because it is private and `demo-dev` is not a member. No password was needed: the CLI decrypted the saved one with `HARBOR_ENCRYPTION_KEY`. Every command you run from here on uses the `admin` context again.

The `-p` flag has a place too, but only for a sign-in you do once by hand. It puts the password in the command line, so your shell history and the process list can show it while the command runs. If a CI job must create its context itself, its setup step has no terminal, and `-p` with the password from the CI secret store is the only way in v0.0.27. Keep that one line in the setup step, not in the script that does the work.

A second way is to sign in once at a terminal with the same `HARBOR_ENCRYPTION_KEY` that the CI job uses, and store the resulting configuration file in the CI secret store. The job then writes the file back before the script runs, and nobody types or passes a password in the job at all.

## Commands that wait for input

Many CLI commands have an interactive mode. If you leave out an argument the command needs, for example the project name of `harbor project member list` or the flags of `harbor webhook create`, the CLI opens a form and waits for you to choose. In a terminal that is helpful. In a pipeline the command either waits forever or stops with an error about the missing terminal.

Two habits keep a script safe. First, always give every argument and flag the command needs. Second, give each command an empty standard input with `</dev/null`, so a prompt fails at once instead of waiting:

```sh
ws sh -c 'harbor project member list inventory </dev/null'
```

The command lists the members of `inventory`, which is only the administrator. The `</dev/null` changes nothing when the command has what it needs; it only matters when it does not.

## Reading the answers: JSON and exit codes

A script has two ways to learn what happened: the output and the exit code. The global flag `-o json` (`--output-format`) makes a command print JSON instead of a table, and `jq` reads it. Ask for the projects as JSON and pick out their names:

```sh
ws sh -c 'harbor project list -o json </dev/null | jq -r ".. | objects | select(has(\"name\") and has(\"project_id\")) | .name"'
```

The output is the project names, one per line: `library` (the project every new Harbor has) and `inventory`. The filter uses `..` to search the whole JSON document for objects that look like projects, so it does not depend on how the CLI wraps the list.

The exit code is the second answer. A command that succeeds exits with `0`, and one that fails exits with another number. `kubectl exec` passes the exit code of the command in the pod back to your shell, so you can test it directly:

```sh
ws harbor project view inventory </dev/null >/dev/null 2>&1; echo "inventory: exit $?"
ws harbor project view no-such-project </dev/null >/dev/null 2>&1; echo "no-such-project: exit $?"
```

The first line prints exit `0` and the second a non-zero exit code. That is all a script needs to decide whether to create the project.

You now know where the CLI keeps its sign-in, why a script selects a saved context with `harbor context switch` instead of calling `harbor login`, why a container needs `HARBOR_ENCRYPTION_KEY`, and how to read a command's JSON and exit code. The open question is how to combine these into a script that creates only what is missing, so that running it twice is safe.

## Common pitfalls

> [!WARNING]
> - **Piping a password into `harbor login --password-stdin`.** In CLI v0.0.27 the flag opens a hidden prompt on a terminal and does not read a pipe. Without a terminal it fails with `inappropriate ioctl for device`. Sign in once at a terminal, and let the script run `harbor context switch`.
> - **Calling `harbor login` in the script.** The script then needs the password, and with `-p` the password ends up in the script, the process list or the CI log. The script should only select a context that already exists.
> - **Leaving out an argument.** The command opens an interactive form and the pipeline hangs. Give every argument and flag, and add `</dev/null`.
> - **Running the CLI in a container without `HARBOR_ENCRYPTION_KEY`.** The CLI falls back to a key file under `~/.harbor/keyring/` and prints a warning. Inject the key from a secret store instead.
> - **Parsing the table output with `grep` or `awk`.** Tables change between releases. Use `-o json` and `jq`.
> - **Forgetting which context is current.** A login switches the current context. Run `harbor context list` when a command answers as the wrong user.
