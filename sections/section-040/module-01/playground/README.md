# Trigger Pipelines With Harbor Webhooks — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-104-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

> **Not yet run.** This playground was written from the Harbor 2.15
> documentation and has not been started on a cluster yet.

A sandbox with Harbor 2.15.4 on `kind`, the workstation pod with the client
tools, the python-runner pod and the webhook receiver. It stays running so you
can explore the module's topic. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-104-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-104-playground-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Installs Harbor and the pods, then seeds the starting state (generated) |
| `manifests/` | Harbor Helm values, workstation and receiver, python-runner (generated) |
| `docs/overview.md` | What the environment contains and ideas to try |
