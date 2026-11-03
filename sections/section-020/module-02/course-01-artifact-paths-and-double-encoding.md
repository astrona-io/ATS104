# Artifact Paths And Double Encoding

Every request about an artifact names it with a path that has three parts: the project, the repository and the reference. A script that builds this path by joining strings works for a repository called `notes` and fails for a repository called `web/frontend`. This part shows the path, the one encoding rule that causes most of the `404` answers, and the parameters that decide how much of the artifact Harbor returns.

## The path of an artifact

The artifacts of a repository live under this path:

```
/api/v2.0/projects/{project_name}/repositories/{repository_name}/artifacts
```

The repository name in the path is the name without the project. The repository that the portal shows as `inventory/web/frontend` is `web/frontend` inside the project `inventory`. A single artifact adds the reference:

```
/api/v2.0/projects/{project_name}/repositories/{repository_name}/artifacts/{reference}
```

The reference is a tag such as `v1` or a digest such as `sha256:3b1c...`. Both work. The digest names one artifact for ever, and a tag names whichever artifact holds it at the moment.

```sh
api /projects/inventory/repositories/web%252Ffrontend/artifacts/v1
```

The answer is one JSON object with the artifact's `digest`, `type`, `size`, `push_time` and, among others, `tags` and `extra_attrs`. Notice the `%252F` in the command. The next section explains it.

## Double encoding of a slash

A slash in a URL path separates segments. A repository name that contains a slash would turn one segment into two and change the meaning of the path. The usual fix is to encode the slash as `%2F`. Harbor asks for more: the OpenAPI description says that a repository name with a slash must be encoded twice. The first encoding turns `/` into `%2F`. The second turns the `%` into `%25`, which gives `%252F`.

Try the three forms and compare the status codes:

```sh
api_code /projects/inventory/repositories/web/frontend/artifacts
api_code /projects/inventory/repositories/web%2Ffrontend/artifacts
api_code /projects/inventory/repositories/web%252Ffrontend/artifacts
```

The first request answers `404`, because the path has extra segments that match no endpoint. The second answers `404` as well when a proxy or server decodes `%2F` before routing. Harbor sits behind an ingress or proxy in most installations, so the double encoding is the form that works everywhere. The third answers `200`.

In Python, encode the name with `urllib.parse.quote` twice, and tell it that no character is safe, so the slash is encoded too:

```python
import urllib.parse

def encode(name):
    return urllib.parse.quote(urllib.parse.quote(name, safe=""), safe="")

print(encode("web/frontend"))
```

The output is `web%252Ffrontend`. Without `safe=""`, `quote` keeps the slash as it is, which is the default and the cause of the bug. Use the same function for every repository name that comes from data, even when the current names have no slash, because the next repository may.

The project name needs no such care. A project name has no slash, and `quote` leaves its allowed characters alone.

## Asking for more of the artifact

An artifact response is small by default. Query parameters add detail, and each one costs Harbor extra work, so ask only for what the script uses.

| Parameter | What it adds |
| --- | --- |
| `with_tag=true` | The `tags` list of the artifact. For a list of artifacts this is the default |
| `with_label=true` | The labels attached to the artifact |
| `with_scan_overview=true` | A summary of the latest scan, keyed by report format |
| `with_signature=true` | Whether the artifact has a signature |
| `with_immutable_status=true` | Whether the tags are protected by an immutable rule |
| `with_accessory=true` | The accessories attached to the artifact, such as signatures and SBOMs |

```sh
api '/projects/inventory/repositories/web%252Ffrontend/artifacts/v1?with_tag=true&with_label=true'
```

For a name or a field you need again and again, such as the digest of a tag, read it once and keep it in a variable. A script that reads the artifact by a tag and then writes by the same tag can see a different artifact if someone pushes in between. Read the digest first, and use the digest in every later request.

## Listing artifacts

The list endpoint is the same path without the reference. It returns one page, like every list in the API, with the headers `X-Total-Count` and `Link`. The parameters from the first module apply: `page`, `page_size`, `q` and `sort`. Two filters are specific to artifacts. `q=tags=v1` selects the artifacts that have the tag `v1`, and `q=digest=sha256:...` selects one digest. Use the filter instead of reading every page and searching in the script.

```sh
api '/projects/inventory/repositories/web%252Ffrontend/artifacts?q=tags%3Dv1&page_size=10'
```

The characters in the query string are encoded as well, so the equals sign in `tags=v1` becomes `%3D` when it sits in a parameter value. That is a single encoding, because the query string is not a path.

You now know how to address an artifact, why the repository name is encoded twice, and which parameters add detail. The next part uses these paths to change tags, copy an artifact and delete one.

## Common pitfalls

> [!WARNING]
> - **Using the slash as it is.** `web/frontend` in a path answers `404`. Encode it twice to `web%252Ffrontend`.
> - **Encoding only once.** `%2F` works on some paths and fails behind a proxy. Always encode twice.
> - **Including the project in the repository name.** The path already names the project, so `inventory/web/frontend` in the repository segment is a different, wrong name.
> - **Acting on a tag after reading it.** A tag can move between two requests. Read the digest and use it.
> - **Asking for every `with_*` parameter.** Each one adds work. Request only the data the script uses.
