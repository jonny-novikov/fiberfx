# BCS · Chapter 3.1 — The fence and the keyspace

<show-structure depth="2"/>

Part III opens by walking its own floor. The connector shipped in [Appendix A](bcsA.md) with its record frozen — the ordered ten-thousand-command pipeline, the EVALSHA-first dispatch, the typed fence refusal — and this chapter consolidates that substrate into the part's working vocabulary: every key shape asserted byte for byte, the gate at the job position exercised before any wire is touched, the fence read back live through the fenced connector itself, binary discipline proven through real job keys, and the co-location law that keeps every future multi-key script legal on a cluster this part does not yet run. The rung is `bcs_rung_3_1_check.exs`, committed record ending `PASS 5/5`.

## Why

A queue's correctness starts below the queue. Key grammar, wire discipline, and version agreement are the three places where bus bugs are born and surface later as ghosts — a job row written under a hand-built key, a payload mangled by a line-oriented client, a consumer running last month's bundle against this month's keys. The part's answer is to name every shape exactly once, gate it, and have every later chapter cite this vocabulary rather than redefine it. The trading frame makes the stakes plain: the keys built here will carry orders.

## What

**The map.** F1 asserts the grammar shape by shape: per-queue keys are `emq:{q}:<type>`, job rows compose with the identity canon, and the braced base is reserved for cross-queue facts — the committed line reads `emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs | {emq}:version | {emq}:locks -- 17 bytes before the payload`. Two design facts live in that line. The branded payload is the long part of a job key by construction — seventeen bytes of grammar, fourteen of identity — which is Chapter 1.3's economy carried onto the bus. And the version fence lives under `{emq}:` precisely because it is the one fact that is *about* the deployment rather than about any queue.

**The gate at the key.** F2 proves the job position refuses before the wire exists: `a fourteen-byte decimal and a fourteen-byte slug both raise before any wire is touched`. The division of labor is stated here so no later chapter blurs it: the key function owns *wellformedness* — fourteen bytes that parse as an identity — while *kind policy* (which namespaces a queue admits) belongs to the enqueue script, because keys are grammar and scripts are law. Chapter 3.2 collects that obligation.

**The fence, live.** F3 performs the part's second law on a running wire and lets the proof be self-referential: `GET {emq}:version answers echomq:2.0.0 through the fenced connector itself` — the read that confirms the fence travels through a connection that could not exist had the fence not held. The negative path is inherited, not re-run: the appendix's frozen record holds the typed refusal of a bogus version and the re-fence after supervised restart, and the part's evidence policy reads records rather than repeating them.

**Binary discipline through the queue's own keys.** Payloads will be serialized terms, and serialized terms contain everything a line-oriented protocol fears. F4 writes five hundred jobs whose bodies embed CRLF and NUL through real job keys and reads them back: `binary payloads with embedded CRLF and NUL survive 500/500 round trips through job keys in two pipelines` — the length-prefixed bulk strings of the protocol [1] doing exactly the work they were designed for, exercised in the very shapes this part will use.

**The co-location law.** F5 is the chapter's theorem. The hashtag *is* the queue name, so every key of one queue answers one slot: `pending, active, meta, and the job row of {orders} all answer slot 105; {fills} answers 4165` — and slot 105 is the same figure the appendix froze for the same hashtag, continuity across rungs by arithmetic rather than by intention. The consequence is the part's future: hash tags exist to ensure that multiple keys are allocated in the same hash slot [2], which is what makes multi-key operations legal in a cluster — so every transition script this part will write (claim moves a job between pending and active; retry touches the job row and a schedule) stays single-slot legal on the clustered day, by grammar rather than by review. The `vector 12739 holds` for the client-side CRC16, and the slot function stays what the preface said: committed, correct, and parked, because single-instance is the part's stated topology.

## Who

Chapters 3.2 through 3.5, whose scripts will name keys only through this module and whose `KEYS[]` arrays stay in one queue's family by construction. Operators, for whom the grammar is also the inspection language — `emq:{orders}:*` scans one queue and nothing else. And agents writing against the bus, who inherit one rule that prevents the whole category of cross-slot accidents: if a script needs keys from two queues, the design is wrong before the script is.

## When

Add a key *type* — never a key *family*: a new per-queue fact is a new `<type>` under the existing tag, and the grammar stays closed. Reach for the `{emq}:` reserve only for facts about the deployment itself; the version fence is the canonical tenant and loneliness there is a feature. And mind the slot function's two lives: today it is partition arithmetic the connector can run without a round trip; on the clustered day it becomes routing, and the co-location law means the scripts written between now and then need no edits to survive the move.

## Where

The grammar at `runtimes/elixir/lib/echo_mq/keyspace.ex`; the connector, codec, and script modules beside it as Appendix A shipped them; the rung and its committed record with the part's others; the inherited evidence in the appendix's frozen record.

## How — the grammar in Elixir, the shape in Go

**Elixir.** The whole vocabulary is small enough to quote its heart:

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

Grammar above, gate below, and nothing else — policy lives in scripts.

**Go.** The consumer side will speak the same grammar, and the shape ports in a breath, with the same gate in the same position:

```go
func JobKey(queue, id string) (string, error) {
    if _, err := brandedid.Parse(id); err != nil {
        return "", err
    }
    return "emq:{" + queue + "}:job:" + id, nil
}
```

The full Go keyspace rides with the Go substrate follow-on; the law it must satisfy is already written here.

## Decisions

**The grammar is closed.** New per-queue facts are new types under the tag; new top-level families do not happen, and the reserve admits only deployment-scoped tenants.

**Wellformedness at the key, policy at the script.** The key function raises on malformed identity and knows nothing of kinds; the enqueue script owns admission, where refusals can be typed replies instead of exceptions.

**The hashtag is the queue, and the queue is the partition unit.** Per-queue scripts are single-slot legal forever by grammar; cross-queue choreography goes through the application, never through a multi-queue script.

**The slot function is committed and parked.** Client-side CRC16 with its vector on file, used today for partition arithmetic, promoted to routing only when the topology changes — and not a line sooner.

## Boundaries

Single instance, as the preface states: the connector does not speak cluster redirects, and teaching it `MOVED` is the clustered day's rung, not a hidden feature of this one. No scan helpers ship here; the grammar makes patterns obvious and the part will add helpers when a chapter needs them under the usual review gate. The fence's negative path lives in the appendix's frozen record and is cited, not duplicated.

## Companion files

`runtimes/elixir/lib/echo_mq/{keyspace,connector,resp,script}.ex`; `bcs_rung_3_1_check.exs` and its committed record `bcs_rung_3_1_check.out`; the inherited record `emq_connector_check.out` beside [Appendix A](bcsA.md).

## References

1. Valkey documentation — Protocol specification (length-prefixed bulk strings; the binary safety F4 exercises): [valkey.io/topics/protocol](https://valkey.io/topics/protocol/)
2. Valkey documentation — Cluster specification (hash slots, CRC16 modulo 16384, and hash tags as the same-slot mechanism behind the co-location law): [valkey.io/topics/cluster-spec](https://valkey.io/topics/cluster-spec/)
