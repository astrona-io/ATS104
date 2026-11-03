# Section 030: Robot Accounts For CI

A pipeline that pushes images needs credentials. Using a person's account for that is the most common mistake: the pipeline gets everything the person can do, the password changes when the person leaves, and the audit log cannot tell the person from the job. Harbor's answer is the robot account, a non-human account with a secret and a fixed list of permissions.

This section teaches robot accounts the way a platform team uses them. You create project robots and system robots, give each one only what its job needs, store the secret in Kubernetes, and rotate it when it leaks.

**Topic covered:** Robot accounts for CI

## What you will learn

- The difference between a project robot and a system robot, and the `robot$` name format.
- Permissions as a resource and an action, and why push must come with pull.
- Creating a robot with the `harbor` CLI and with the REST API, and saving its secret the one time Harbor shows it.
- Expiry, disabling, and refreshing a secret.
- Storing a robot's name and secret in a Kubernetes Secret and using them with `oras`.
- System robots across projects, the robot lifecycle, auditing a robot, and Kubernetes image pull secrets.

## The learning path

Each module has a landing page, four parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster where you can explore freely.

### 1. Give CI Its Own Credentials With Robot Accounts

The playground holds Harbor with two projects: `ci`, which is empty, and `inventory`, with one artifact.

1. Robot Names, Permissions And Creation
2. Using A Robot
3. Least Privilege, Expiry And Secret Storage, followed by the lab **Create A Push-Only Robot For CI**
4. Rotating A Robot Secret
5. Summary

### 2. System Robots, Lifecycle And Auditing

The playground for module 2 holds Harbor with the projects `team-red`, `team-blue` and `team-green`, each with one artifact.

1. System Robots And Their Permissions
2. The Lifecycle Of A Robot
3. Auditing What A Robot Did
4. Robots In Pipelines And Kubernetes Pull Secrets, followed by the lab **Create A System Robot For Two Teams**
5. Summary

## Section capstone: Rotate A Leaked Robot Secret

A deploy robot's secret was found in a ConfigMap that half the company can read, and the robot can push and delete as well as pull. Revoke the leaked secret, cut the robot down to what deploying needs, and give it an expiry, without breaking the deploy jobs' reference to the robot. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS104.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-104-capstone-030
```
