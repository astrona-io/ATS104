# ATS104 — Harbor CLI Automation, REST API & Webhooks (Harbor)

Course material for the **Harbor CLI Automation, REST API & Webhooks** domain
of the Astrona Harbor training path ([ATP020](https://github.com/astrona-io/ATP020)),
which is **15% of the path**. Written for **Harbor v2.15.4** and the
**Harbor CLI v0.0.27**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Harbor 2.15 documentation, the CLI v0.0.27 command pages and the
> v2.15.4 Swagger file. None has been started on a cluster, and no lab has
> passed `astrona test` yet. See `CLAUDE.md` for what to check first.

The course opens with an Introduction in `sections/intro/`. Each section has a
module (landing page, parts, summary), a playground, a graded lab right after
the part it tests, and a capstone.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Automating Harbor With The harbor CLI | 1 | 1 + capstone | CLI automation |
| [020](sections/section-020) | The Harbor REST API v2.0 | 1 | 1 + capstone | REST API |
| [030](sections/section-030) | Robot Accounts For CI | 1 | 1 + capstone | Robot accounts |
| [040](sections/section-040) | Webhooks For Pipelines | 1 | 1 + capstone | Webhooks |

The order follows a pipeline from the inside out: first a script that talks to
Harbor, then the API under the script, then the credentials a pipeline should
use, and last the call Harbor makes back to the pipeline.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Script Harbor With The harbor CLI](sections/section-010/module-01/course.md) | 2 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Call The Harbor REST API](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Give CI Its Own Credentials With Robot Accounts](sections/section-030/module-01/course.md) | 2 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Trigger Pipelines With Harbor Webhooks](sections/section-040/module-01/course.md) | 2 | [lab-01](sections/section-040/module-01/labs/lab-01) |

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair An Onboarding Script That Breaks In CI | hard-coded password, public projects, a prompt without a terminal, an invalid role name, not idempotent, a loop that loses CSV lines |
| [020](sections/section-020/capstone/labs/lab-01) | Remove Untagged Artifacts Through The API | TLS verification off, first page only, `null` against `[]`, every project instead of one |
| [030](sections/section-030/capstone/labs/lab-01) | Rotate A Leaked Robot Secret | leaked secret, too many permissions, no expiry |
| [040](sections/section-040/capstone/labs/lab-01) | Bootstrap A CI Project End To End | pull-only robot, disabled policy, wrong event, unverifiable HTTPS endpoint, Default instead of CloudEvents |

---

## The lab environment

Every playground and lab is a **kind** cluster with Harbor 2.15.4 installed by
the `harbor-helm` chart 1.19.4, reachable as `https://harbor.localtest.me:8443`
inside the cluster through a CoreDNS rewrite. Three pods carry the work:

- `workstation` (namespace `workstation`): `harbor`, `oras`, `regctl`,
  `cosign`, `curl`, `jq`, with Harbor's CA trusted and the CLI signed in as
  `admin`;
- `python-runner` (namespace `workstation`): Python 3.13, standard library
  only, with Harbor's CA and the lab-only API credentials in its environment;
- `echo` (namespace `hooks`): the webhook receiver, which logs every request.

All plumbing (manifests, install and seed scripts, graders) was produced by
one generator, so shared parts are identical across environments.

## Running a playground or a lab

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/<section>/<module>/playground
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** with independent checks. Graders run your
scripts again without a terminal, push with your robot's credentials, and wait
for webhooks in the receiver log. They reject the fix that only hides a
problem: TLS verification off, a hard-coded password, an over-privileged
robot, or a robot or policy deleted and recreated instead of fixed.
