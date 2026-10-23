# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS104 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Harbor CLI Automation, REST API & Webhooks**
  domain of the **Harbor** training path (`ATP020`). It is 15% of the path.
  There is no official Harbor certification exam; the path's domains and
  weights are Astrona's own, set in `ATP020/path.yaml`.
- **What the domain really tests:** making Harbor part of a pipeline, not
  clicking in the portal. The student must *do* things: write a script that
  can run twice, page through the REST API, give CI a robot account with the
  smallest set of permissions, rotate a leaked secret, and make Harbor call a
  pipeline when an artifact arrives. Every fix is proved by running the script
  or the push again and checking the result in Harbor or in the receiver log.
- **The four topics:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Automating Harbor With The harbor CLI | CLI automation |
  | 020 | The Harbor REST API v2.0 | REST API |
  | 030 | Robot Accounts For CI | Robot accounts |
  | 040 | Webhooks For Pipelines | Webhooks |

- **The versions:** **Harbor v2.15.4** (chart `harbor-helm` 1.19.4, Helm
  3.22.1) on a single-node `kind` cluster; the **`harbor` CLI v0.0.27**;
  `oras` 1.3.5, `regctl` 0.11.7, `cosign` 3.1.4; Python 3.13 (standard library
  only); the webhook receiver `mendhak/http-https-echo:42`. The Harbor
  documentation set is 2.15.0. The REST API reference is the `swagger.yaml`
  of Harbor v2.15.4 (`api/v2.0/swagger.yaml` in `goharbor/harbor`).
- **The main sources:** <https://goharbor.io/docs/2.15.0/>, the CLI command
  pages in `doc/cli-docs/` of `goharbor/harbor-cli` at tag `v0.0.27`, and the
  Swagger file above. Check every page against them.

### Status: built, not yet run

The first version of this repository was written from the Harbor 2.15
documentation, the CLI v0.0.27 command pages and the v2.15.4 Swagger file
**without a live run**. No playground or lab has been started, and no
`astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

Check these first, in this order:

1. **`harbor` CLI behaviour without a terminal.** The scripts assume that a
   command given its argument and flags never prompts, that `harbor project
   view` exits non-zero for a missing project, that `harbor project create
   <name> --storage-limit -1` without `--public` makes a private project
   without a prompt, and that `-o json` prints JSON that `jq` can search for
   `username` and `entity_name` fields (the scripts search with `..`, so the
   exact nesting does not matter).
2. **The saved context `ci`** (capstone 010): the learner signs in once at a
   terminal, the script only runs `harbor context switch ci`, and the graders
   read `harbor context list -o json` (Go field names such as
   `CurrentCredentialName` and `Credentials[].Name`; the v0.0.27 source has no
   JSON tags on that struct). `harbor login` with an existing `-n` name
   updates the saved credential (source: `RunLogin` in `login.go`).
3. **`oras push` of an unknown artifact type** (`application/vnd.astrona.note.v1`)
   into Harbor, and `oras login --registry-config` for robot accounts.
4. **The receiver log.** Graders search `kubectl -n hooks logs deploy/echo`
   for the tag, the event type and the auth header value. Check that
   `http-https-echo` logs request headers and the body.
5. **Robot updates.** `PUT /robots/{id}` with the object from `GET` plus new
   `permissions` and `duration`, and `PATCH /robots/{id}` with
   `{"secret": "..."}` to refresh a secret.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| REST API v2.0 | Harbor's HTTP interface under `/api/v2.0`; the portal and the `harbor` CLI both use it |
| Swagger / OpenAPI file | The machine-readable description of every API path, parameter and response; Harbor serves an API explorer in the portal |
| Basic authentication | Sending `user:password` Base64-encoded in the `Authorization` header with every request |
| Pagination | Splitting a long list into pages: `page` and `page_size` (default 10, at most 100) in the request, `X-Total-Count` and `Link` in the response |
| `q` query | Harbor's filter parameter: `q=name=foo` (exact), `q=name=~foo` (fuzzy), `q=size=[1~100]` (range) |
| Idempotent script | A script that gives the same result when it runs twice: it creates only what is missing |
| Context (CLI) | A saved server address, user name and encrypted password in the CLI configuration file; `harbor context list` and `harbor context switch` |
| `HARBOR_ENCRYPTION_KEY` | The key the CLI uses to encrypt saved passwords. The CLI reads it first, then the system keyring, then a key file under `~/.harbor/keyring/` (with a warning); a container or CI job sets it from a secret |
| Robot account | A non-human Harbor account with a secret and a limited set of permissions; it cannot sign in to the portal |
| Project robot / system robot | A robot limited to one project, named `robot$<project>+<name>` / a robot created by an administrator that can cover several projects, named `robot$<name>` |
| Permission (robot) | A resource and an action, for example `repository` `push`; push must come with pull |
| Robot secret | The robot's password, shown once when it is created or refreshed |
| Webhook policy | A project setting that sends an HTTP POST to an endpoint when chosen events happen |
| Event type | The event that triggers a webhook, for example `PUSH_ARTIFACT` (`harbor.artifact.pushed` in CloudEvents) |
| Payload format | `Default` (Harbor's own JSON) or `CloudEvents` (the CNCF CloudEvents specification) |
| Auth header | A fixed `Authorization` header value Harbor sends with every webhook, so the receiver can check the sender |
| `jobservice` | The Harbor component that delivers webhooks in the background and retries failed ones |

### The example workloads

| Name | What it is |
| --- | --- |
| Harbor (namespace `harbor`, Helm release `harbor`) | Harbor 2.15.4 at `https://harbor.localtest.me:8443`, no persistence |
| Administrator `admin` | Password `Harbor12345`. Lab-only credentials; say so when a page uses them |
| `workstation` (namespace `workstation`) | `harbor`, `oras`, `regctl`, `cosign`, `curl`, `jq`; Harbor's CA trusted; `HARBOR_ENCRYPTION_KEY` from the Secret `harbor-cli-key`; the CLI signed in as `admin` in the context `admin`; `oras` signed in as `admin`; scratch folder `/work` |
| `python-runner` (namespace `workstation`) | `python:3.13-alpine`, standard library only; `HARBOR_URL`, `HARBOR_CA` (`/etc/harbor-ca/ca.crt` from the ConfigMap `harbor-ca`), `HARBOR_USERNAME` and `HARBOR_PASSWORD` (from the Secret `harbor-api`); scratch folder `/work` |
| `echo` (namespace `hooks`) | `mendhak/http-https-echo:42`, the webhook receiver. HTTP on `8080`, HTTPS with a self-signed certificate on `8443`. Logs every request |
| Projects | `inventory` (most modules), `archive`, `ci`, `team-red`, `team-blue`, `team-green`, `team-gold` |
| Repositories | Small text-file OCI artifacts pushed with `oras` (`inventory/notes-01` … `notes-12`, `inventory/app`, `ci/app`) |

Pages define the helpers they need once, with these names:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
wst() { kubectl -n workstation exec -it deploy/workstation -- "$@"; }
py() { kubectl -n workstation exec -i deploy/python-runner -- "$@"; }
```

`wst` adds a terminal (`-t`) and is only for `harbor` list and view commands
without `-o json|yaml`: CLI v0.0.27 draws their table with bubbletea, which
fails without a terminal. Scripts and `ws sh -c` use `-o json`.

A script the reader writes on their machine goes into a pod with
`ws sh -c 'cat > /work/onboard.sh' < onboard.sh` (or `py ...` for Python).
That is the "Save this as" step for scripts.

### Environment facts the text must respect

- **Harbor images are amd64 only (seen on a live run, 2026-10-23).** On an
  arm64 machine (Apple silicon) every `goharbor/*` image runs under
  emulation. The bundled Valkey (Redis) crashes there with a segmentation
  fault, so every values file replaces it with the multi-architecture
  `docker.io/valkey/valkey:8.1.10-alpine` (`redis.internal.image`). Keep
  that override in every new values file; the other components work under
  emulation. Upgrades must keep it too: use `--reuse-values` or a values
  file that contains it.
- **One address everywhere:** `https://harbor.localtest.me:8443`, through the
  CoreDNS `rewrite stop` block (answer name rewritten back) inside the
  cluster, and `kubectl -n harbor port-forward svc/harbor 8443:8443` on the
  reader's machine for the portal. Never the one-line `rewrite name` form.
- **TLS stays on.** The workstation trusts Harbor's CA; Python uses
  `ssl.create_default_context(cafile=os.environ["HARBOR_CA"])`. Never teach
  `--insecure`, `-k`, `verify=False` or `ssl._create_unverified_context()`
  except as the fault in a lab.
- **Robot names contain `$` and `+`.** In shell, always put them in single
  quotes (`'robot$ci+builder'`); in a URL query, encode them (`%24`, `%2B`).
- **Repository names with a slash** must be URL-encoded twice in API paths
  (`a%252Fb`). The example repositories avoid slashes; pages say the rule once.
- **Webhooks are asynchronous.** `jobservice` sends them in the background;
  pages and graders wait and retry instead of reading the receiver log once.
- **Internet is needed** for the chart images, the client tools from GitHub
  and `python:3.13-alpine`. Allow about 4 GiB of memory and up to 15 minutes
  for the first start.
- **Many environments start broken on purpose** (a non-idempotent script, a
  script that turns TLS verification off, an over-privileged robot, a disabled
  webhook). The fault is the material. Never "fix" it in the bootstrap.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`), labs
(`config.yaml`, `README.md`, `prerequisites.md`, `question.md`,
`solution.md`, `bootstrap/01-install-harbor.sh`, `bootstrap/02-seed-state.sh`,
`manifests/`, `solution/apply.sh`, `testing/wait-for-harbor.sh`,
`validation/validate-*.sh`) and one capstone per section.

Everything in an environment except `question.md`, `solution.md` and
`docs/overview.md` was produced by one generator, so the shared parts (the
helper block at the top of every script, the install script, the manifests)
are identical. When you change a shared part, change it in every environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS104`, domain `Harbor CLI Automation, REST API &
Webhooks`, weight `15`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `cli-automation`, `rest-api`, `robot-accounts`,
  `webhooks`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `harbor-cli`, `cli-context`,
  `output-json`, `idempotency`, `ci-without-tty`,
  `users`, `project-members`, `rest-api`, `basic-auth`, `pagination`,
  `query-filter`, `python-urllib`, `tls-verification`, `untagged-artifacts`,
  `robot-account`, `project-robot`, `robot-permissions`, `secret-rotation`,
  `least-privilege`, `kubernetes-secret`, `oras`, `webhook-policy`,
  `push-artifact`, `payload-format`, `cloudevents`, `auth-header`,
  `jobservice`.
- `resources`: 1 to 4 pages on `goharbor.io` (or the CLI command pages on
  GitHub). The only place outside links are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-010/module-01/playground
astrona destroy ats-104-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-104-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-104-playground-<section>-<module>`, `ats-104-lab-<section>-<module>`,
`ats-104-capstone-<section>`. Graders check **behaviour**: they run the
learner's script (twice where idempotency matters, without a terminal and
with a time limit), push with the robot's credentials, and wait for the
webhook in the receiver log. They reject the plausible but wrong fix: turning
TLS verification off, a hard-coded password, an over-privileged robot,
deleting and recreating a robot or webhook policy instead of changing it.
A lab's `question.md` and `solution.md` must match what its `validation/`
scripts check.

### Where to find trusted sources

- **CLI:** [Harbor CLI documentation](https://goharbor.io/cli-docs/),
  [CLI config management](https://goharbor.io/cli-docs/cli-config/),
  `doc/cli-docs/` and `doc/cli-encryption/` in `goharbor/harbor-cli` at
  `v0.0.27`
- **API:** `api/v2.0/swagger.yaml` in `goharbor/harbor` at `v2.15.4`
- **Robot accounts:** [robot accounts](https://goharbor.io/docs/2.15.0/administration/robot-accounts/),
  [project robot accounts](https://goharbor.io/docs/2.15.0/working-with-projects/project-configuration/create-robot-accounts/)
- **Webhooks:** [configure webhooks](https://goharbor.io/docs/2.15.0/working-with-projects/project-configuration/configure-webhooks/)
- **The landscape:** <https://www.cncf.io/projects/harbor/> (graduated).

### Harbor CLI v0.0.27 facts that differ from the CLI website

Checked against the v0.0.27 command pages. The page
<https://goharbor.io/cli-docs/cli-config/> still describes older behaviour.

- `harbor login <server-url> -u <user> -n <context-name>` with
  `--password-stdin` (at a terminal) or `-p <password>`: the context name flag
  is `-n` / `--context-name`, not `--name`.
- `--password-stdin` does **not** read a pipe. In v0.0.27 it prints
  `Password:` and calls `term.ReadPassword` on stdin (`cmd/harbor/root/login.go`),
  so it works only on a terminal; a piped password fails with `failed to read
  password from stdin: inappropriate ioctl for device` (seen on a live run,
  2026-10-23; upstream issue goharbor/harbor-cli#943 closed as wontfix). There
  is no password environment variable. Teach "sign in once": a person signs in
  at a terminal, and scripts run `harbor context switch <name>`. Bootstraps and
  `solution/apply.sh` have no terminal and use `-p`.
- `harbor project create <name>` opens its interactive form unless it gets
  both the name and `--storage-limit` (`create.go`); scripts pass
  `--storage-limit -1` (no limit).
- Contexts are managed with `harbor context list|switch|get|update|delete`.
- `harbor config` manages Harbor's **server-side** configuration
  (`get|update|view|apply`), not CLI credentials. Never use it for contexts.
- The encryption key comes from `HARBOR_ENCRYPTION_KEY`, then the system
  keyring, then `~/.harbor/keyring/` (with a warning).
