# B3.1 · The Fence and the Keyspace

> Module hub · route `/bcs/bus/fence-and-keyspace` · teaches `content/bcs3.1.md` · the rung is
> `bcs_rung_3_1_check.exs`, its committed record `bcs_rung_3_1_check.out` closes `PASS 5/5`.

Seventeen bytes of grammar, fourteen of identity.

Part III opens by walking its own floor. The connector shipped in Appendix A with its record frozen — the
ordered ten-thousand-command pipeline, the EVALSHA-first dispatch, the typed fence refusal — and this chapter
consolidates that substrate into the part's working vocabulary: every key shape asserted byte for byte, the gate
at the job position exercised before any wire is touched, the fence read back live through the fenced connector
itself, binary discipline proven through real job keys, and the co-location law that keeps every multi-key
script legal on a cluster this part does not yet run.

The chapter is `content/bcs3.1.md`; the rung behind it is `bcs_rung_3_1_check.exs`, and its committed transcript
closes `PASS 5/5`. The map, the gate, the fence, the binary discipline, the co-location law — five gates, each
asserted on stage.

## §1 Below the queue

A queue's correctness starts below the queue. Key grammar, wire discipline, and version agreement are the three
places where bus bugs are born and surface later as ghosts — a job row written under a hand-built key, a payload
mangled by a line-oriented client, a consumer running last month's bundle against this month's keys. The part's
answer is to name every shape exactly once, gate it, and have every later chapter cite this vocabulary rather
than redefine it. The trading frame makes the stakes plain: the keys built here will carry orders.

The chapter's four decisions:

- **The grammar is closed.** New per-queue facts are new types under the tag; new top-level families do not
  happen, and the reserve admits only deployment-scoped tenants.
- **Wellformedness at the key, policy at the script.** The key function raises on malformed identity and carries
  no kind policy; the enqueue script owns admission, where refusals can be typed replies instead of exceptions.
- **The hashtag is the queue, and the queue is the partition unit.** Per-queue scripts are single-slot legal
  forever by grammar; cross-queue choreography goes through the application, never through a multi-queue script.
- **The slot function is committed and parked.** Client-side CRC16 with its vector on file, used today for
  partition arithmetic, promoted to routing only when the topology changes — and not a line sooner.

## §2 The proof

The full committed transcript, verbatim (source: `content/echo_data/runtimes/elixir/bcs_rung_3_1_check.out`):

```
F1 map ok -- the part's map: emq:{orders}:pending | emq:{orders}:job:ORD0NgWEfAEJfs | {emq}:version | {emq}:locks -- 17 bytes before the payload
F2 gate ok -- the job position is gated: a fourteen-byte decimal and a fourteen-byte slug both raise before any wire is touched; kind policy waits for the enqueue script
F3 fence ok -- the fence holds on a live wire: GET {emq}:version answers echomq:2.0.0 through the fenced connector itself
F4 binary ok -- binary payloads with embedded CRLF and NUL survive 500/500 round trips through job keys in two pipelines
F5 slot ok -- co-location law: pending, active, meta, and the job row of {orders} all answer slot 105; {fills} answers 4165 -- multi-key scripts stay legal on the clustered day (vector 12739 holds)
PASS 5/5
```

Two design facts live in F1's line. The branded payload is the long part of a job key by construction —
seventeen bytes of grammar, fourteen of identity — which is Chapter 1.3's economy carried onto the bus. And the
version fence lives under `{emq}:` precisely because it is the one fact that is *about* the deployment rather
than about any queue. F3's negative path is inherited, not re-run: the appendix's frozen record holds the typed
refusal of a bogus version and the re-fence after supervised restart, and the part's evidence policy reads
records rather than repeating them.

## §3 The dives

1. **The Key Grammar** (`the-key-grammar`) — F1, the map: per-queue keys are `emq:{q}:<type>`, job rows compose
   with the identity canon, the braced `{emq}:` base is reserved for deployment-scoped facts. F2, the gate at
   the job position: a fourteen-byte decimal and a fourteen-byte slug both raise before any wire is touched;
   kind policy waits for the enqueue script — keys are grammar, scripts are law.
2. **The Fence, Live** (`the-fence-live`) — F3: `GET {emq}:version` answers `echomq:2.0.0` through the fenced
   connector itself — the self-referential proof. F4: binary payloads with embedded CRLF and NUL survive
   `500/500` round trips through job keys in two pipelines.
3. **The Co-location Law** (`the-co-location-law`) — F5: pending, active, meta, and the job row of `{orders}`
   all answer `slot 105`; `{fills}` answers `4165`; `vector 12739 holds` — multi-key scripts stay single-slot
   legal on the clustered day, and the slot function stays committed, correct, and parked.

## References

Sources:

- Valkey — Protocol specification — https://valkey.io/topics/protocol/ (length-prefixed bulk strings; the
  binary safety F4 exercises)
- Valkey — Cluster specification — https://valkey.io/topics/cluster-spec/ (hash slots, CRC16 modulo 16384, and
  hash tags as the same-slot mechanism behind the co-location law)

Related:

- /bcs/bus — B3 · The Bus, the chapter landing; Part III's arc
- /bcs/ideas — B1 · Ideas Behind, the identity canon whose 17/14-byte economy this chapter carries onto the bus
- /echomq — EchoMQ, the keyspace in rung-level depth on the far side of the door
- /redis-patterns — Redis Patterns Applied, the substrate: cluster hash slots, atomic Lua
- /elixir — Functional Programming in Elixir, the umbrella

Pager: previous `/bcs/bus` · next `/bcs/bus/fence-and-keyspace/the-key-grammar`.
