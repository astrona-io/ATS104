# Summary

Harbor's REST API under `/api/v2.0` is the interface every Harbor client uses. This module showed how a script calls it safely and completely.

## What you learned

The base path is `/api/v2.0`, and the Swagger file describes every endpoint, which the portal's API explorer shows. `GET /api/v2.0/health` needs no credentials and reports each component's status. Other endpoints need basic authentication, sent with every request. An anonymous list request does not fail: it returns only public objects, so a script that forgets its credentials gets a short answer instead of an error. The portal's session cookie and CSRF token are only for the browser.

Errors come as a status code plus a JSON body with a list `errors` of `code` and `message`. `401` means no valid credentials, `403` a missing permission, `404` an object that does not exist or cannot be seen, `409` an object that already exists, and `412` a refusal by a project policy. `HEAD /projects?project_name=` answers "does this project exist" with `200` or `404`. The `X-Request-Id` header identifies a request in Harbor's logs.

Every list endpoint returns one page, ten items by default and at most a hundred. The body does not say more exist; the headers do. `X-Total-Count` gives the total and `Link` gives the next page. A script loops until it holds the total or gets an empty page. The `q` parameter filters on the server with exact, fuzzy, range and list patterns, and `sort` orders the list on the server, with a minus sign for descending order. Repository names with a slash are URL-encoded twice in a path.

A Python script needs only the standard library: `urllib.request` for the calls, `base64` for the authentication header, `json` for the bodies and `ssl` for TLS. It reads its address, credentials and CA file from the environment, and it trusts Harbor's CA with `ssl.create_default_context(cafile=...)`. An unverified context makes a certificate error disappear by sending the credentials to whoever answers. The key facts to remember are these:

- Send credentials with every request; check the status code.
- Default page size `10`, maximum `100`; read `X-Total-Count` or `Link`.
- Filter with `q` and order with `sort` on the server.
- Trust the CA; never turn verification off.

<!-- astrona:playground:destroy -->
