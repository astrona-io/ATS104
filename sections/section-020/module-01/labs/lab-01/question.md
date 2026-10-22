# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** The Harbor REST API v2.0

## Scenario

The platform team wants a nightly report of how much each project holds. The report runs in a minimal Python image where nothing can be installed. A first attempt reported ten repositories for the project `inventory`; the team counted twelve in the portal.

The python-runner pod has Python 3.13 with only the standard library, and these environment variables: `HARBOR_URL`, `HARBOR_USERNAME`, `HARBOR_PASSWORD` and `HARBOR_CA` (the file of the certificate authority that signed Harbor's certificate). Run commands there with:

```sh
kubectl -n workstation exec -i deploy/python-runner -- <command>
```

## Your task

Write the script `/work/report.py` in the python-runner pod. Called as `python3 /work/report.py <project>`, it prints one JSON object to standard output:

```json
{
  "project": "inventory",
  "repository_count": 12,
  "artifact_count": 13,
  "repositories": [
    {"name": "inventory/notes-01", "artifact_count": 1},
    {"name": "inventory/notes-02", "artifact_count": 1}
  ]
}
```

- `repositories` lists **every** repository of the project, sorted by `name`, each with its `artifact_count`. (The example shows only the first two.)
- `repository_count` is the number of repositories, and `artifact_count` the sum of their artifact counts.

## Constraints

- **Standard library only.** No `pip install`.
- **Keep TLS verification on.** Use the CA file in `HARBOR_CA`; do not create an unverified context or set `CERT_NONE`.
- Do not write the password into the script; read the credentials from the environment.
- Do not change anything in Harbor.

## Done when

- `python3 /work/report.py inventory` reports `12` repositories and `13` artifacts, and its `repositories` list matches what the API says, repository by repository.
- `python3 /work/report.py archive` reports `2` repositories.
- The script keeps TLS verification on and holds no password.
