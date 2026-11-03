# Section 040: Webhooks For Pipelines

A pipeline that deploys a new image should start when the image arrives, not on a timer that checks every few minutes. Harbor can send that start signal itself: a webhook, an HTTP request to an address you choose, sent when something happens in a project. The pipeline receives the request, reads which artifact was pushed, and starts.

This section teaches webhooks the way a pipeline depends on them. You create a webhook policy, choose its events and payload format, protect it with an auth header, follow its delivery through Harbor's job service, and connect it to CI systems.

**Topic covered:** Webhooks for pipelines

## What you will learn

- What a webhook policy holds: events, an endpoint, a notify type, a payload format and an auth header.
- The event types, such as `PUSH_ARTIFACT` and `SCANNING_COMPLETED`, and their CloudEvents names.
- The difference between the Default and CloudEvents payloads.
- How `jobservice` delivers webhooks, retries failures, and logs each attempt.
- Why an HTTPS endpoint with a certificate Harbor does not trust fails, and what to do about it.
- How GitHub Actions and Jenkins receive Harbor's webhooks.
- Event types, managing policies through the REST API, writing a receiver, and troubleshooting a webhook that does not arrive.

## The learning path

Each module has a landing page, four parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster where you can explore freely.

### 1. Trigger Pipelines With Harbor Webhooks

The playground holds Harbor with the project `inventory` and a webhook receiver, `echo`, in the namespace `hooks`, which writes every request it gets to its log.

1. Webhook Policies And The Default Payload, followed by the lab **Notify A Pipeline When An Artifact Is Pushed**
2. The CloudEvents Payload
3. Reading A Failed Delivery
4. Retries, Receivers And CI Systems
5. Summary

### 2. Receivers, Events And Troubleshooting

The playground for module 2 holds Harbor with the project `inventory` and the webhook receiver `echo` in the namespace `hooks`.

1. Event Types And Policy Design
2. Managing Policies With The REST API
3. Writing A Receiver
4. Troubleshooting A Webhook That Does Not Arrive, followed by the lab **Audit Deleted Artifacts With A CloudEvents Webhook**
5. Summary

## Section capstone: Bootstrap A CI Project End To End

A new CI project was set up in a hurry: the CI robot cannot push, and the pipeline never hears about pushes because the webhook is off, listens for the wrong event, and points at an endpoint Harbor cannot verify. Make a push by the CI robot reach the pipeline as a CloudEvent, without recreating the robot or the policy. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-104-capstone-040
```
