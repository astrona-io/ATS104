# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** The Harbor REST API v2.0

## Scenario

Every CI build pushes `inventory/app:latest`. The tag moves to the new artifact, and the old one stays in the repository without a tag. A storage review found many such untagged artifacts. The script `/work/cleanup.py` in the python-runner pod was meant to delete them. It runs without an error, prints `cleaning inventory`, and deletes nothing. A colleague also noticed that it connects without checking Harbor's certificate.

The project `archive` holds old builds that must be kept, untagged ones included, until an audit is done.

The python-runner pod has Python 3.13 with only the standard library, and the variables `HARBOR_URL`, `HARBOR_USERNAME`, `HARBOR_PASSWORD` and `HARBOR_CA`. Run commands there with:

```sh
kubectl -n workstation exec -i deploy/python-runner -- <command>
```

## Your task

Fix `/work/cleanup.py` so that `python3 /work/cleanup.py inventory` deletes **every untagged artifact** in the project `inventory`, in every repository, and nothing else. Then run it.

## Constraints

- **Delete only untagged artifacts, only in the project given as the argument.** Every tagged artifact stays.
- **Keep TLS verification on.** Use the CA file in `HARBOR_CA`.
- Standard library only, and no password in the script.
- Do not delete artifacts by hand in the portal or with `curl`; the script must do it.

## Done when

- The repositories `inventory/app` and `inventory/docs` have no untagged artifacts.
- `inventory/app:latest`, `inventory/app:v1`, `inventory/app:v2` and `inventory/docs:latest` still exist.
- `archive/old` still has both of its artifacts.
- The script keeps TLS verification on, holds no password, and a second run succeeds.
