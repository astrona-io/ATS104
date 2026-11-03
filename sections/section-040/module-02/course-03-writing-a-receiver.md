# Writing A Receiver

The receiver is the part of a webhook that you own. Harbor sends a request and waits for an answer, and what the receiver does with the request decides whether the webhook is reliable. This part builds a small receiver in Python with the standard library, and explains the rules it follows.

## What Harbor expects

Harbor sends an HTTP `POST` with a JSON body. It treats a `2xx` answer as success. Any other answer, or no answer in time, is a failure that is retried, as the first module showed. Three rules follow from that.

1. **Check the auth header first.** The header is the only proof that the request came from Harbor.
2. **Answer fast.** Return a `2xx` status as soon as the event is stored, and do the real work after. A receiver that builds an image before it answers will time out.
3. **Expect repeats.** Retries and manual redelivery send the same event more than once, so handling an event twice must be harmless.

## A small receiver

```python
import hmac
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

TOKEN = "Bearer audit-token-456"
SEEN = set()


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        supplied = self.headers.get("Authorization", "")
        if not hmac.compare_digest(supplied, TOKEN):
            self.send_response(401)
            self.end_headers()
            return
        length = int(self.headers.get("Content-Length", 0))
        event = json.loads(self.rfile.read(length) or b"{}")
        event_id = event.get("id") or json.dumps(event, sort_keys=True)
        if event_id not in SEEN:
            SEEN.add(event_id)
            print("event", event.get("type"), flush=True)
        self.send_response(204)
        self.end_headers()

    def log_message(self, *args):
        pass


HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
```

It compares the header with `hmac.compare_digest`, which takes the same time whatever the input, and it answers `401` for a wrong or missing header. It answers `204`, a success with no body, after it records the event. It uses the CloudEvents field `id` to ignore a repeat. The Default payload has no `id`, so for that format the receiver falls back to the whole body, which is not perfect but catches an identical redelivery.

Keep the set of seen identifiers in a store that survives a restart in a real receiver. A set in memory forgets everything when the process restarts.

## Work after the answer

If the work takes long, put the event in a queue and let another process handle it. The receiver's job is to accept and store. A pipeline trigger, for example, can be a single request to the CI system, which is fast enough to do before the answer. A build, a scan wait or a deployment is not.

## Which status to return

| Situation | Status |
| --- | --- |
| Event accepted or already seen | `200` or `204` |
| Wrong or missing auth header | `401` |
| Body is not valid JSON | `400` |
| Receiver cannot store the event right now | `503`, so Harbor tries again |

Return a `4xx` status only for a problem that a retry cannot fix. A temporary problem should return `5xx` so the retry has a chance.

## Slack

For the `slack` notify type, Harbor sends a message to a Slack incoming webhook address. There is no receiver to write and no auth header: the address holds the secret. Treat the address as a secret, store it as one, and do not paste it into a ticket.

## TLS

A receiver on HTTPS needs a certificate that Harbor trusts. With a self-signed certificate the delivery fails unless the target sets `skip_cert_verify` to true, which turns off the check. Use that only in a lab. In production, give the receiver a certificate from an authority that Harbor's jobservice trusts.

## Testing a receiver

Start the receiver and send it a request by hand before you point Harbor at it:

```sh
curl -s -o /dev/null -w '%{http_code}\n' -X POST -H 'Authorization: Bearer audit-token-456' -d '{"id":"1","type":"harbor.artifact.deleted"}' http://localhost:8080/
curl -s -o /dev/null -w '%{http_code}\n' -X POST -d '{}' http://localhost:8080/
```

The first answers `204` and the second answers `401`. Then use the policy test request from the previous part to check the path from Harbor.

## Common pitfalls

> [!WARNING]
> - **Doing the work before the answer.** The request times out and Harbor sends it again.
> - **Comparing the token with `==`.** Use a constant-time comparison.
> - **Returning `400` for a temporary problem.** Harbor may not retry the way you expect. Use `503`.
> - **Keeping seen identifiers in memory only.** A restart forgets them.
> - **Turning off certificate checks outside a lab.**
