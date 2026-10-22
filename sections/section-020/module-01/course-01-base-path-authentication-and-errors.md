# Base Path, Authentication And Errors

Before a script can do anything useful with Harbor, it must reach the right address, prove who it is, and understand the answer when something goes wrong. This part sends the first requests to the REST API with `curl` and reads both a successful answer and an error, so you know what a script has to handle.

## The base path and the description of every endpoint

Every endpoint of the API starts with the base path `/api/v2.0` on Harbor's address. `GET /api/v2.0/health`, for example, reports the health of each Harbor component. The full list of paths, parameters and response fields is in Harbor's Swagger file, a machine-readable OpenAPI description of the API. The portal's help menu links to an API explorer page, `/devcenter-api-2.0`, built from that file, where you can read every endpoint and try it.

Start with the health endpoint. It needs no credentials, which makes it a good first check that the address and TLS work. The workstation pod trusts Harbor's certificate authority (CA), so `curl` needs no `-k`:

<!-- astrona:playground:renew -->

```sh
ws sh -c 'curl -s "$HARBOR_URL/api/v2.0/health" | jq'
```

The answer is a JSON object with an overall `status` of `healthy` and a list `components`, one entry per Harbor component (`core`, `database`, `jobservice`, `portal`, `redis`, `registry`, `registryctl`, `trivy`), each with its own status. The single quotes around the command matter: they make the workstation pod expand `$HARBOR_URL`, not your machine's shell.

## Basic authentication

Most endpoints need credentials. Harbor's API accepts **basic authentication**: the client sends the user name and password, Base64-encoded, in the `Authorization` header of every request. `curl -u user:password` builds that header. Ask for the projects as the lab-only administrator:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects" | jq -r ".[].name"'
```

The output is the three project names: `archive`, `inventory` and `library`. Without credentials, the same request still succeeds, but the answer contains only the public project `library`. Harbor does not fail an anonymous list request; it filters it to what an anonymous user may see. A script that forgets its credentials gets a short list, not an error.

The portal uses a different way to sign in: a session cookie plus a cross-site request forgery (CSRF) token header that Harbor checks on every change. A script that sends basic authentication with every request does not need either.

## Errors: the status code and the body

When a request fails, Harbor answers with an HTTP status code and a JSON body in one format: an object with a list `errors`, where each error has a `code` and a `message`. Ask for a project that does not exist, and print the status code after the body:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 -w "\nHTTP %{http_code}\n" "$HARBOR_URL/api/v2.0/projects/no-such-project"'
```

The body has one error with the code `NOT_FOUND` and a message that names the project, and the status code is `404`. Now send a request that changes something, with a wrong password:

```sh
ws sh -c 'curl -s -u admin:wrong-password -w "\nHTTP %{http_code}\n" -X POST -H "Content-Type: application/json" -d "{\"project_name\":\"denied\"}" "$HARBOR_URL/api/v2.0/projects"'
```

This time the status is `401` with the error code `UNAUTHORIZED`. The status codes a script meets most often are these:

| Status | Meaning for a script |
| --- | --- |
| `200` / `201` | Success; `201` means something was created, and its `Location` header names it |
| `401` | No valid credentials: wrong password, expired robot secret, or none sent where they are required |
| `403` | Valid credentials, but this user or robot lacks the permission |
| `404` | The object does not exist, or this user may not see it |
| `409` | Conflict: the object already exists, for example a project with that name |
| `412` | A project policy refused the request, for example a pull of an artifact that fails a security rule |

Every response also carries an `X-Request-Id` header. When you report a problem to a Harbor administrator, that ID finds the request in Harbor's logs.

## Checking that a name exists

Some endpoints exist only to answer "does this exist". `HEAD /api/v2.0/projects?project_name=<name>` returns `200` when the project exists and `404` when it does not, with no body. That is cheaper than fetching the project and cleaner than parsing an error:

```sh
ws sh -c 'curl -s -o /dev/null -w "%{http_code}\n" -I -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects?project_name=inventory"'
```

The command prints `200`. Change the name to one that does not exist and it prints `404`.

You can now reach the API, authenticate with every request, and tell success from each kind of failure by its status code and error body. The open question is the one from the start of the module: a list endpoint returns only one page, so how does a script know there is more?

## Common pitfalls

> [!WARNING]
> - **Forgetting the credentials on a list request.** Harbor answers with only the public objects instead of an error. Always send credentials, and treat a suspiciously short list as a warning.
> - **Turning off TLS verification with `curl -k`.** It hides a wrong address as well as a missing CA. Trust the CA instead; the workstation already does.
> - **Ignoring the status code.** `curl` exits with `0` even for a `404` unless you use `-f`. Check `%{http_code}` or use `--fail` in scripts.
> - **Treating `404` as "does not exist" for every user.** A user who may not see a private project gets `404` too.
> - **Expanding `$HARBOR_URL` on your own machine.** Wrap the command in single quotes inside `sh -c`, so the pod expands it.
