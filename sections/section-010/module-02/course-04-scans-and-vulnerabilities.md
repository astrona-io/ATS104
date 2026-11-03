# Scans And Vulnerabilities

A registry that only stores artifacts cannot tell you whether they are safe to deploy. Harbor can scan an artifact with a vulnerability scanner and keep the result next to it. In Harbor 2.15.4 the default scanner is Trivy, which runs as an adapter beside Harbor. A pipeline uses the result to decide whether to continue: it starts a scan, waits for it to finish, reads the findings and stops when a finding is too serious. This part shows the CLI commands for each step and what a script can and cannot rely on.

## What can be scanned

Trivy scans container images. It reads the packages inside an image and compares them with its vulnerability database. The artifacts in the playground are small text files pushed with `oras`. They contain no packages, so a scan has nothing to report on them, and Harbor reports that it cannot scan this artifact type. This is the correct behaviour, not a failure of the scanner. To see real findings you need an image, for example one copied into the project with `regctl image copy` from a registry your playground can reach.

The scanner itself is configured by the administrator. `harbor scanner list` shows the registered scanners and which one is the default for new projects. A project can also scan every pushed artifact automatically, which is a project setting called automatically scan on push.

## Starting a scan

`harbor artifact scan start` takes the artifact in the path form `<project>/<repository>/<reference>`:

```sh
ws harbor artifact scan start inventory/app/build-1 </dev/null
```

The command returns as soon as Harbor has accepted the request. The scan itself runs in the background and takes from a few seconds to a few minutes. The command `harbor artifact scan stop` stops a scan that is running. Starting a scan does not tell you the result, so a script has to look again.

## Waiting for the result

The artifact list shows the vulnerability count, and the JSON form holds the status of the scan. A script that must wait loops: ask for the artifact, check whether the status is a final one, and sleep when it is not. A final status is one of `Success`, `Error` or `Stopped`. The loop needs a limit, because a scan that never ends would otherwise hold the pipeline for ever:

```sh
for attempt in 1 2 3 4 5 6 7 8 9 10 11 12; do
  status="$(harbor artifact list inventory/app --page-size 100 -o json </dev/null \
    | jq -r '[.. | objects | select(.scan_overview?) | .scan_overview[]?.scan_status][0] // "none"')"
  case "$status" in Success|Error|Stopped) break ;; esac
  sleep 5
done
echo "scan status: $status"
```

The filter reads the scan overview of the first artifact that has one. Harbor keys the overview by the report format, so the filter does not name the key. A script for production reads the overview of the one artifact it started a scan for. The REST API module shows how to ask for exactly that artifact by digest.

## Reading the vulnerabilities

The Security Hub gives a view across all projects, and the CLI reads it with `harbor vulnerability list`. It filters on the server:

```sh
wst harbor vulnerability list --project-name inventory --severity Critical
wst harbor vulnerability list --repository app --fixable
wst harbor vulnerability list --cve-id CVE-2024-0001
```

The filters are `--project-name`, `--repository`, `--tag`, `--digest`, `--package`, `--cve-id`, `--severity`, `--cvss-score` (an exact score such as `7.0`, or a range such as `7.0~10.0`) and `--fixable` for findings that have a fixed version. `--exclude` takes a query that removes rows. The list has a default page size of 10; `--page-size` and `--page` change that, and `--all` shows up to 1000 findings.

`harbor vulnerability summary` prints totals by severity across Harbor. Adding `--artifact` shows the five most dangerous artifacts, and `--cve` shows the five most widespread CVEs. The summary answers the question of how bad the whole registry is, and the list answers which artifact and which package.

## Turning a result into a pass or fail

A pipeline gate is a script that exits with a non-zero code when the result is not acceptable. A gate needs a rule written down before the first scan. A common rule is to fail on any critical finding that has a fix, because the team can act on it at once:

```sh
count="$(harbor vulnerability list --project-name inventory --repository app --tag build-1 \
  --severity Critical --fixable --page-size 100 -o json </dev/null \
  | jq '[.. | objects | select(has("cve_id"))] | length')"
[ "$count" -eq 0 ] || { echo "blocked: $count fixable critical findings"; exit 1; }
```

The filter counts objects that have a field `cve_id`. If the Security Hub has no data for the artifact, the count is `0` and the gate passes, so a gate must also check that the scan finished. A scan that did not run is not the same as a scan that found nothing.

Two other controls work at the project level rather than in a script. A project can block pulls of an artifact above a chosen severity, which stops a vulnerable image from being deployed. And an allowlist of CVEs lets a team accept a finding for a time. Use these controls together with the gate: the gate keeps vulnerable builds out of the release tags, and the project setting is the last stop at pull time.

## Scanning everything

`harbor scan-all run` starts a scan of every artifact in the registry, and `harbor scan-all update-schedule` sets a recurring one. Run it after the vulnerability database has updated, so old artifacts are checked against the new findings. A registry with many artifacts needs time and CPU for this, so it belongs in a quiet hour.

You now know how to start a scan, wait for it with a limit, read findings with filters and turn them into a gate. This module showed that every content command needs the artifact named exactly, a page size set explicitly, and a check before each change.

## Common pitfalls

> [!WARNING]
> - **Treating "no findings" as "scanned".** An artifact that was never scanned also has no findings. Check the scan status before you read the count.
> - **Waiting without a limit.** Give the loop a number of attempts, and fail the pipeline when it runs out.
> - **Expecting findings for a file artifact.** Trivy scans images. A plain file has nothing to scan.
> - **Reading only the first 10 findings.** Set `--page-size` or `--all`, or the gate sees part of the list.
