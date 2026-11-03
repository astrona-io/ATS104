# Summary: Artifacts, Scans And The System API

This module moved from projects and repositories to artifacts and to the registry as a whole. It used `curl` for single requests and Python with `urllib` for the script that the lab grades.

## What to remember

- An artifact is addressed as `/projects/{project}/repositories/{repository}/artifacts/{reference}`. The reference is a tag or a digest, and the digest never moves.
- A repository name with a slash is encoded twice in the path: `web/frontend` becomes `web%252Ffrontend`. The project name is not part of the repository name.
- `with_tag`, `with_label`, `with_scan_overview` and the other `with_*` parameters add detail and cost work, so ask only for what the script uses.
- Creating a tag answers `201`, and a repeat answers `409`. Removing a tag or deleting an artifact answers `200`, and a repeat answers `404`. A copy uses `POST` to the target with `from=project/repository:tag` and answers `201`.
- Read the object first when the script must tell "already done" from "wrong path".
- A scan start answers `202` and runs in the background. Wait for `Success`, `Error` or `Stopped` with a deadline, treat `Error` as a failure, and read the findings from `additions/vulnerabilities`.
- `/health` and `/systeminfo` need no sign-in. `/statistics`, `/search`, `/quotas` and `/audit-logs` show what the user is allowed to see.
- A delete frees disk space only after garbage collection. Run a dry run first and read its log.

## Commands you should know

| Task | Request |
| --- | --- |
| Read one artifact | `GET /projects/{p}/repositories/{r}/artifacts/{ref}` |
| Add a tag | `POST .../artifacts/{ref}/tags` with `{"name": "..."}` |
| Remove a tag | `DELETE .../artifacts/{ref}/tags/{tag}` |
| Copy an artifact | `POST /projects/{p}/repositories/{r}/artifacts?from=src-project/src-repo:tag` |
| Delete an artifact | `DELETE .../artifacts/{ref}` |
| Start a scan | `POST .../artifacts/{ref}/scan` |
| Read findings | `GET .../artifacts/{ref}/additions/vulnerabilities` |
| Check health | `GET /health` |
| Read the audit log | `GET /audit-logs?sort=-op_time` |
| Dry-run garbage collection | `POST /system/gc/schedule` with `dry_run` set to true |

## Clean up

If you started the playground for this module, you can remove it now:

<!-- astrona:playground:destroy -->
