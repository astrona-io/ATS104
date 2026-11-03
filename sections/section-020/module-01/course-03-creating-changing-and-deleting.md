# Creating, Changing And Deleting

Reading data is safe. A script that creates, changes or deletes data must also handle the cases where the request is repeated, where the object is already there, and where the object is gone. This part sends the write methods of the REST API (POST, PUT and DELETE) for projects and tags, and shows how the status code tells a script what happened, so that a retried job does not fail or damage anything.

## The methods and what they mean

HTTP defines a method for each kind of action. `POST` creates an object in a collection. `PUT` replaces or updates an object at a known address. `DELETE` removes it. `GET` and `HEAD` only read. Harbor follows these rules for most endpoints, and the Swagger file lists the method, the body and the possible status codes of each path.

A request that carries a body must also say what the body is. The header `Content-Type: application/json` tells Harbor to read the body as JSON. Without it, Harbor rejects the request with a client error.

## Create a project with POST

`POST /api/v2.0/projects` creates a project. The body is a JSON object with the field `project_name` and, optionally, a `metadata` object. In `metadata`, the value `public` is the string `"true"` or `"false"`, not a JSON boolean. Create a private project called `scratch` and print the status code after the body:

<!-- astrona:playground:renew -->

```sh
ws sh -c 'curl -s -u admin:Harbor12345 -w "\nHTTP %{http_code}\n" -X POST -H "Content-Type: application/json" -d "{\"project_name\":\"scratch\",\"metadata\":{\"public\":\"false\"}}" "$HARBOR_URL/api/v2.0/projects"'
```

The status code is `201`, and the body is empty. A `201` answer means the object was created, and its `Location` header names it. Run the same command again:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 -w "\nHTTP %{http_code}\n" -X POST -H "Content-Type: application/json" -d "{\"project_name\":\"scratch\",\"metadata\":{\"public\":\"false\"}}" "$HARBOR_URL/api/v2.0/projects"'
```

This time the status code is `409` (conflict), and the error body says that the project already exists. That is the answer an idempotent script needs: a `409` on a create means the object is already there, which is the state the script wanted.

## Two ways to make a create idempotent

A script has two safe choices. The first is to ask before it creates: `HEAD /projects?project_name=scratch` returns `200` or `404`, and the script posts only on `404`. The second is to post and accept `409` as success. The second needs one request instead of two, and it avoids a race when two jobs run at the same time: both ask, both see `404`, and the slower post fails. With the second choice, the slower job gets a `409` and carries on.

Accept only the status code that you expect. A script that treats every error as success hides a `401` from a wrong password or a `400` from a bad body. Compare the code to `201` and `409`, and stop on anything else.

## Change an object with PUT

`PUT /api/v2.0/projects/{project_name_or_id}` updates a project. The path accepts the project name or the numeric ID. The body holds the fields to change. Make `scratch` public by sending the new metadata:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 -w "HTTP %{http_code}\n" -X PUT -H "Content-Type: application/json" -d "{\"metadata\":{\"public\":\"true\"}}" "$HARBOR_URL/api/v2.0/projects/scratch"'
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/scratch"' | jq '.metadata.public'
```

The update returns a `200` status, and the check prints `"true"`. A `PUT` is naturally idempotent: sending the same body twice leaves the same state. That makes it a good tool for a script that must bring an object to a known state.

## Tags are objects too

An artifact can have several tags, and each tag is created and deleted on its own address. Add the tag `stable` to the artifact `v2` of the repository `notes-03` in the project `inventory`, then read the tags of that artifact:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 -w "HTTP %{http_code}\n" -X POST -H "Content-Type: application/json" -d "{\"name\":\"stable\"}" "$HARBOR_URL/api/v2.0/projects/inventory/repositories/notes-03/artifacts/v2/tags"'
ws sh -c 'curl -s -u admin:Harbor12345 "$HARBOR_URL/api/v2.0/projects/inventory/repositories/notes-03/artifacts/v2/tags"' | jq -r '.[].name'
```

The create returns `201`, and the list shows both `v2` and `stable`. The artifact is addressed by a reference, which is either a tag or a digest. A tag can move: creating `stable` on a different artifact moves it, so the old artifact loses that tag.

## Delete with DELETE

`DELETE` removes an object. Remove the tag, then the project:

```sh
ws sh -c 'curl -s -u admin:Harbor12345 -w "HTTP %{http_code}\n" -X DELETE "$HARBOR_URL/api/v2.0/projects/inventory/repositories/notes-03/artifacts/v2/tags/stable"'
ws sh -c 'curl -s -u admin:Harbor12345 -w "HTTP %{http_code}\n" -X DELETE "$HARBOR_URL/api/v2.0/projects/scratch"'
```

Both requests succeed with a `2xx` status. Run the project delete again and Harbor answers `404`, because the project is gone. A cleanup script treats `404` on a delete the same way a create script treats `409`: the object is already in the wanted state. Delete is also where mistakes cost the most. The project delete only works when the project holds no repositories, so Harbor refuses it with a client error until the artifacts are removed first.

You can now create, update and remove projects and tags with the REST API, and you know that the status code (`201`, `409`, `404`) tells a script whether a repeated request needs any more work. The open question is how to write this logic once in Python, with the standard library, together with the paging loop.

## Common pitfalls

> [!WARNING]
> - **Treating every non-`2xx` status as success to make a script idempotent.** Only `409` on a create and `404` on a delete mean "already done". A `401`, `403` or `400` is a real failure.
> - **Sending `public` as a JSON boolean.** The project metadata values are strings: `"true"` and `"false"`.
> - **Forgetting the `Content-Type: application/json` header.** Harbor then does not read the body as JSON.
> - **Deleting by a name that you did not check.** A wrong variable in a delete URL removes the wrong object. Print the URL first when you write the script.
