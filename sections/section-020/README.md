# Section 020: The Harbor REST API v2.0

Everything Harbor does goes through one HTTP interface: the REST API under `/api/v2.0`. The web portal calls it, the `harbor` CLI calls it, and a script that needs something the CLI does not offer can call it directly. Knowing the API also explains the CLI's behaviour, because every CLI command is one or more API calls.

This section teaches the API the way a script uses it. You authenticate, read errors, page through long lists, filter and sort on the server, and write a Python script with only the standard library that keeps TLS verification on.

**Topic covered:** The Harbor REST API v2.0

## What you will learn

- The base path `/api/v2.0`, basic authentication, and where the description of every endpoint lives.
- Harbor's error format, and what `401`, `403`, `404` and `409` mean for a script.
- Pages and page sizes, and the response headers `X-Total-Count` and `Link`.
- The `q` filter (exact, fuzzy and range) and the `sort` parameter.
- A Python script that pages through a list with `urllib`, with Harbor's certificate authority (CA) trusted instead of verification turned off.

## The learning path

The module has a landing page, three parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Call The Harbor REST API

The playground holds Harbor with the project `inventory` (twelve small repositories) and the project `archive` (two repositories). You call the API from the workstation pod with `curl` and from the python-runner pod with Python.

1. Base Path, Authentication And Errors
2. Pages, Filters And Sorting
3. A Python Script With The Standard Library, followed by the lab **Report Every Repository In A Project**
4. Summary

## Section capstone: Remove Untagged Artifacts Through The API

A cleanup script should delete every untagged artifact in one project. It runs without an error and deletes nothing. Fix it so it deletes exactly what it should, in the project it is given and nowhere else, without turning TLS verification off. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-104-capstone-020
```
