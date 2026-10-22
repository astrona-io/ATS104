# Welcome To The Course

This course trains you for the **Harbor CLI Automation, REST API & Webhooks** part of the Astrona **Harbor** training path. That part is 15% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You can work in a terminal: you write small shell scripts, you read JSON with `jq`, and you call an HTTP API with `curl`. You know what a container image, a tag and a digest are, and you have pushed and pulled an image before. You know enough Kubernetes to run `kubectl exec` and create a Secret. A little Python helps for one module. You do not need to be a Harbor expert; each new idea is explained the first time it appears.

## What you can do at the end

A registry in a pipeline is driven by scripts, not by clicks. So this course does not ask you to remember the portal's menus. It asks you to write and repair the scripts and settings a pipeline depends on, and to prove they work by running them again. The course has four topics.

The first topic is **the `harbor` command-line tool in scripts**. You will learn to:

- Sign the CLI in without a prompt, and keep its saved password safe in a container.
- Read a command's JSON output and exit code to decide what to do next.
- Write an onboarding script that creates only what is missing, so it can run twice.

The CLI is a client of Harbor's REST API, so the second topic is **the REST API v2.0**. You will learn to:

- Call the API with basic authentication and TLS verification on.
- Read every page of a long list, and filter and sort it on the server.
- Write a Python script with the standard library that reports on, or cleans up, a project.

A pipeline needs its own credentials, so the third topic is **robot accounts**. You will learn to:

- Create a project robot with the smallest set of permissions that works.
- Store its secret in a Kubernetes Secret, and rotate the secret when it leaks.

The last topic is **webhooks**. You will learn to:

- Make Harbor send an HTTP request to a pipeline when an artifact is pushed.
- Choose between the Default and CloudEvents payloads, protect the call with an auth header, and debug a webhook that never arrives.

Everything is written for **Harbor v2.15.4** and the **Harbor CLI v0.0.27**.

## The words this course uses

The pages use Harbor's, the CLI's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **project** is Harbor's unit of access control: every repository lives in one project, and users get a role in a project. A **repository** holds the versions of one artifact, and an **artifact** is one stored item, such as a container image, identified by its **digest**. The **REST API** is Harbor's HTTP interface under `/api/v2.0`; the web portal and the `harbor` CLI both use it. A **robot account** is a non-human account for scripts and pipelines. A **webhook** is an HTTP request Harbor sends to another system when something happens in a project.

| Harbor component | What it does in this course |
| --- | --- |
| `core` | Answers every REST API call and checks who you are |
| `registry` | Stores the artifacts you push and pull |
| `jobservice` | Sends webhooks in the background and retries failed ones |
| `portal` | The web interface; you can use it to look, but every task is done from the terminal |

## The example setup in your playground

Every playground and lab runs the same setup. Harbor runs in the namespace `harbor`, at `https://harbor.localtest.me:8443`. You do your work in two pods in the namespace `workstation`. The `workstation` pod has the `harbor` CLI, `oras` (a client that pushes and pulls any OCI artifact), `curl` and `jq`, and it already trusts Harbor's certificate. The `python-runner` pod has Python 3.13 with only the standard library. A third pod, `echo` in the namespace `hooks`, receives webhooks and writes every request it gets to its log.

The artifacts in the examples are tiny text files pushed with `oras`, so pushes take a second. The lab-only administrator is `admin` with the password `Harbor12345`. A real installation uses its own password. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with a script that talks to Harbor, goes down to the API under it, then to the credentials a pipeline should use, and ends with the call Harbor makes back to the pipeline.

| Section | What it covers |
| --- | --- |
| 010 | Automating Harbor With The harbor CLI |
| 020 | The Harbor REST API v2.0 |
| 030 | Robot Accounts For CI |
| 040 | Webhooks For Pipelines |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
