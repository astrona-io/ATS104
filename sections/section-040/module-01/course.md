# Trigger Pipelines With Harbor Webhooks

A deploy pipeline that checks Harbor for new images every five minutes is slow, and it asks Harbor the same question thousands of times a day. Harbor can instead tell the pipeline the moment an artifact is pushed, scanned or deleted. It sends an HTTP POST with a JSON description of the event to an address the pipeline listens on.

That request is a **webhook**, and the project setting that decides when and where to send it is a **webhook policy**. This module is about policies that a pipeline can rely on. Keep one sentence in mind: **Harbor's `jobservice` sends webhooks in the background, so you prove one works by watching it arrive, not by reading the policy.**

The module has two parts. **Webhook Policies And Payloads** creates a policy, pushes an artifact, and reads the request in the receiver's log in both payload formats. **Delivery, Retries And CI Integration** follows a webhook through `jobservice`, reads the execution log of a failed delivery, and connects Harbor to GitHub Actions and Jenkins. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Create a webhook policy with the `harbor` CLI and with the REST API.
- Choose event types, and name the CloudEvents type of each.
- Choose between the Default and CloudEvents payloads, and read the fields of each.
- Protect a webhook with an auth header, and explain what the receiver must check.
- Find out why a webhook did not arrive from the policy's executions and task logs.
- Explain how Harbor's webhooks reach a GitHub Actions workflow or a Jenkins job.

## Before you start

You need to know HTTP basics (methods, headers, status codes), JSON, and how to read a pod's log with `kubectl logs`. You need to know what pushing an artifact means.

Your playground is a single-node `kind` cluster with **Harbor 2.15.4** at `https://harbor.localtest.me:8443`. You work in the **`workstation`** pod (namespace `workstation`), which has the `harbor` CLI (signed in as the lab-only administrator `admin`, password `Harbor12345`), `oras` (signed in as `admin`), `curl` and `jq`.

| Name | What it is |
| --- | --- |
| Project `inventory` | Holds the artifact `inventory/notes:v1` |
| `echo` (namespace `hooks`) | The webhook receiver. It answers every request with `200` and writes the method, path, headers and body to its log. HTTP on `http://echo.hooks.svc.cluster.local:8080`, HTTPS with a self-signed certificate on port `8443` |

Define these helpers once in each terminal:

```sh
ws() { kubectl -n workstation exec -i deploy/workstation -- "$@"; }
receiver_log() { kubectl -n hooks logs deploy/echo --since=10m; }
```

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
