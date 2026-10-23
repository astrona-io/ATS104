# Section 010: Automating Harbor With The harbor CLI

Clicking through the Harbor portal works for one project. It does not work for fifty teams, and it does not work inside a pipeline, where no person is there to click. The `harbor` command-line tool (CLI) is the official client for Harbor's REST API, and it is what you put in a script. A script that a pipeline runs has two extra requirements: it must never wait for a person to type, and it must give the same result when it runs a second time.

This section turns the CLI into a reliable building block. You sign it in once at a terminal and let scripts reuse that saved sign-in, read its JSON output and exit codes, and write an onboarding script that creates only what is missing.

**Topic covered:** Automating Harbor with the `harbor` CLI

## What you will learn

- How the CLI stores a server, a user name and an encrypted password as a context, and why a container needs `HARBOR_ENCRYPTION_KEY`.
- Signing in once at a terminal and letting a script select the saved context with `harbor context switch`, so no password lands in a script. In CLI v0.0.27, `--password-stdin` is a hidden terminal prompt, not a way to pipe a password in.
- Why a CLI command can wait for input, and how to make sure it never does in a pipeline.
- Reading `-o json` output with `jq`, and using exit codes to decide whether an object exists.
- Writing an idempotent onboarding script: a project, a user and a membership, each created only when missing.

## The learning path

The module has a landing page, two parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster where you can explore freely.

### 1. Script Harbor With The harbor CLI

The playground holds Harbor with the project `inventory`, one artifact in it, and a user `demo-dev`. The CLI in the workstation pod is already signed in as the administrator.

1. The harbor CLI In A Script
2. An Onboarding Script That Can Run Twice, followed by the lab **Write An Idempotent Onboarding Script**
3. Summary

## Section capstone: Repair An Onboarding Script That Breaks In CI

A CI job onboards three teams from a CSV file with a shell script. On a developer's laptop the script seemed to work. In CI it hangs, fails the second time it runs, makes the projects public and holds the administrator password in plain text. Fix the script, not Harbor. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-104-capstone-010
```
