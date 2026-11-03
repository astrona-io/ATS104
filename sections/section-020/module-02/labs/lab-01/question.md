# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** The Harbor REST API v2.0

## Scenario

A release job runs in a minimal Python image where nothing can be installed. When a build passes its tests, the job must mark the artifact as a release by adding the tag `release` to it. The repositories of the project `inventory` are named `web/frontend` and `web/backend`, so the repository names contain a slash. A first attempt used the name `web/frontend` in the request path and got a `404`. The job can be retried, so a second run must not fail.

The python-runner pod has Python 3.13 with only the standard library, and these environment variables: `HARBOR_URL`, `HARBOR_USERNAME`, `HARBOR_PASSWORD` and `HARBOR_CA` (the file of the certificate authority that signed Harbor's certificate). Run commands there with:

```sh
kubectl -n workstation exec -i deploy/python-runner -- <command>
```

## Your task

Write the script `/work/tag_artifact.py` in the python-runner pod. Called as

```sh
python3 /work/tag_artifact.py <project> <repository> <reference> <tag>
```

it must:

1. Find the artifact that `<reference>` (a tag or a digest) points to in `<project>/<repository>`. The repository name may contain a slash.
2. Add `<tag>` to that artifact, if the artifact does not have the tag yet.
3. Print one JSON object to standard output and exit with `0`:

```json
{
  "repository": "web/backend",
  "digest": "sha256:...",
  "tags": ["release", "v1"]
}
```

`tags` lists every tag of the artifact after the change, sorted.

## Constraints

- **Standard library only.** No `pip install`.
- **Keep TLS verification on.** Use the CA file in `HARBOR_CA`; do not create an unverified context or set `CERT_NONE`.
- Do not write the password into the script; read the credentials from the environment.
- Do not delete or change anything else in Harbor.

## Done when

- `python3 /work/tag_artifact.py inventory web/frontend v1 release` exits with `0`, and the artifact of `web/frontend:v1` has the tags `release` and `v1`.
- Running the same command a second time also exits with `0`.
- `python3 /work/tag_artifact.py inventory web/backend v1 release` prints the repository, the digest and the sorted tags of that artifact.
- The script keeps TLS verification on and holds no password.
