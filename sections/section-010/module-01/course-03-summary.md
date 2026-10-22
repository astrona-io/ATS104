# Summary

The `harbor` command-line tool is the client a pipeline uses to talk to Harbor. This module showed how to make it safe and predictable inside a script.

## What you learned

The CLI signs in once and saves the result as a context: a name, the server address, the user name and an encrypted password, in `~/.config/harbor-cli/config.yaml`. One context is current, and `harbor context list` and `harbor context switch` show and change it. The CLI encrypts saved passwords with AES-GCM. It reads the key from `HARBOR_ENCRYPTION_KEY` first, then from the system keyring, and last from a key file under `~/.harbor/keyring/`, with a warning. In a container or a CI job, `HARBOR_ENCRYPTION_KEY` should come from a secret store.

`harbor login` should get its password from `--password-stdin`, never from `-p`, which leaves the password in the shell history and the process list. A command that misses an argument opens an interactive form and waits, so a script gives every argument and flag, and gives each command `</dev/null` as its input so a prompt fails at once.

A script learns what happened from exit codes and JSON. `harbor project view` exits with `0` only when the project exists. List commands such as `harbor project member list` and `harbor user list` succeed either way, so the script reads their `-o json` output with `jq -e` and compares exact fields, `entity_name` for members and `username` for users.

A script is idempotent when a second run gives the same result as the first. For a script that creates objects, that means checking each object and creating it only when it is missing, with `set -eu` so a failed command stops the script. The proof is always two runs in a row, both with exit code `0`. The key facts to remember are these:

- Contexts live in the CLI configuration file; the password in it is encrypted.
- In a container, set `HARBOR_ENCRYPTION_KEY` from a secret.
- Sign in with `--password-stdin`; give every argument; add `</dev/null`.
- Exit codes answer "does this one object exist"; JSON answers "is this name in the list".
- Run a script twice before you trust it.

<!-- astrona:playground:destroy -->
