# B3.1.1 · The Key Grammar

> Dive 1 of B3.1 · route `/bcs/bus/fence-and-keyspace/the-key-grammar` · teaches F1 + F2 of `content/bcs3.1.md`
> (`bcs_rung_3_1_check.out`, `PASS 5/5`).

Keys are grammar, scripts are law.

F1 asserts the part's map shape by shape: per-queue keys are `emq:{q}:<type>`, job rows compose with the
identity canon, and the braced base is reserved for cross-queue facts. F2 proves the job position refuses before
the wire exists. The division of labor is stated here so no later chapter blurs it.

## §1 The transcript

This dive reads F1 and F2 (source: `content/echo_data/runtimes/elixir/bcs_rung_3_1_check.out`, verbatim):

```
F1 map ok -- the part's map: emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs | {emq}:version | {emq}:locks -- 17 bytes before the payload
F2 gate ok -- the job position is gated: a fourteen-byte decimal and a fourteen-byte slug both raise before any wire is touched; kind policy waits for the enqueue script
F3 fence ok -- the fence holds on a live wire: GET {emq}:version answers echomq:2.0.0 through the fenced connector itself
F4 binary ok -- binary payloads with embedded CRLF and NUL survive 500/500 round trips through job keys in two pipelines
F5 slot ok -- co-location law: pending, active, meta, and the job row of {orders} all answer slot 105; {fills} answers 4165 -- multi-key scripts stay legal on the clustered day (vector 12739 holds)
PASS 5/5
```

## §2 F1 — the map

Per-queue keys are `emq:{q}:<type>`, job rows compose with the identity canon, and the braced base is reserved
for cross-queue facts — the committed line reads `emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs |
{emq}:version | {emq}:locks -- 17 bytes before the payload`. Two design facts live in that line. The branded
payload is the long part of a job key by construction — seventeen bytes of grammar, fourteen of identity — which
is Chapter 1.3's economy carried onto the bus. And the version fence lives under `{emq}:` precisely because it
is the one fact that is *about* the deployment rather than about any queue.

The whole vocabulary is small enough to quote its heart (source: `bcs3.1.md` · How,
`runtimes/elixir/lib/echo_mq/keyspace.ex`):

```elixir
def queue_key(queue, type) when is_binary(queue) and is_binary(type),
  do: IO.iodata_to_binary(["emq:{", queue, "}:", type])

def job_key(queue, branded) do
  if EchoData.BrandedId.valid?(branded) do
    queue_key(queue, "job:") <> branded
  else
    raise ArgumentError, "job_key requires a valid branded id"
  end
end
```

Grammar above, gate below, and nothing else — policy lives in scripts. The consumer side will speak the same
grammar, and the shape ports in a breath, with the same gate in the same position:

```go
func JobKey(queue, id string) (string, error) {
    if _, err := brandedid.Parse(id); err != nil {
        return "", err
    }
    return "emq:{" + queue + "}:job:" + id, nil
}
```

The full Go keyspace rides with the Go substrate follow-on; the law it must satisfy is already written here.

The grammar is closed: add a key *type* — never a key *family*. A new per-queue fact is a new `<type>` under the
existing tag. Reach for the `{emq}:` reserve only for facts about the deployment itself; the version fence is
the canonical tenant and loneliness there is a feature. For operators, the grammar is also the inspection
language — `emq:{orders}:*` scans one queue and nothing else.

## §3 F2 — the gate at the job position

F2 proves the job position refuses before the wire exists: `a fourteen-byte decimal and a fourteen-byte slug
both raise before any wire is touched`. The division of labor is stated here so no later chapter blurs it: the
key function owns *wellformedness* — fourteen bytes that parse as an identity — while *kind policy* (which
namespaces a queue admits) belongs to the enqueue script, because keys are grammar and scripts are law.
**B3.2 · Jobs Are Entities** collects that obligation.

The key function raises on malformed identity and carries no kind policy; the enqueue script owns admission,
where refusals can be typed replies instead of exceptions.

## References

Sources:

- Valkey — Cluster specification — https://valkey.io/topics/cluster-spec/ (hash tags — the braced segment the
  grammar builds in by construction)
- Valkey — Protocol specification — https://valkey.io/topics/protocol/ (the wire the composed keys travel;
  length-prefixed bulk strings)

Related:

- /bcs/bus/fence-and-keyspace — B3.1, the module hub; the full rung in context
- /bcs/bus — B3 · The Bus, the chapter landing
- /bcs/bus/jobs-are-entities — B3.2 · Jobs Are Entities, where the enqueue script collects the kind-policy obligation
- /bcs/ideas — B1 · Ideas Behind, the identity canon the job position gates
- /echomq — EchoMQ, the keyspace in rung-level depth
- /redis-patterns — Redis Patterns Applied, the substrate
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus/fence-and-keyspace` · next `/bcs/bus/fence-and-keyspace/the-fence-live`.
