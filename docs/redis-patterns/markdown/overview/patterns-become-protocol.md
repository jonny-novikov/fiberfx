# Patterns become protocol

> Route: `/redis-patterns/overview/patterns-become-protocol` · Module R0.3 (hub) · Grounding:
> `docs/echo/bcs/content/bcs3.1.md` · `bcs3.2.md` · `bcs3.3.md` · `bcsA.md` ·
> `docs/echo_mq/emq.design.md` — every figure verbatim from a committed record. Reframed under
> [`specs/reframe-echomq/`](../../specs/reframe-echomq/reframe-echomq.md).

A handful of Redis patterns, owned the right way, stop being one library's habits and become a protocol the bus
itself declares: a closed key grammar, a three-field job hash, four sorted sets, eight verbs over six scripts —
versioned, fenced, and backed by Valkey. R0.2 fixed *where* Redis sits in the BCS build. This module answers
*why* the worked examples in this course hold for any runtime that connects: the patterns are not language code.
They are **EchoMQ's owned protocol** — a declared data convention plus the atomic Lua scripts that change it,
with the boundary held by a version fence rather than by anyone's upstream.

## §1 · From patterns to an owned protocol

A protocol here is not a network wire format. It is a **declared Redis data convention** joined to a set of
**atomic Lua scripts** — a written agreement about which key holds which structure, what the row's fields are,
and which script makes each state change. EchoMQ owns that agreement outright. The grammar is closed: every
per-queue key parses as `emq:{q}:<type>`, the job position is gated to branded ids, and the braced `{emq}:`
reserve holds the deployment's own facts. The job row is a hash of exactly three fields — `state`, `attempts`,
`payload` — and deliberately nothing more: no `enqueued_at`, because mint time already lives inside the id.
Four sorted sets carry the lifecycle (`pending` score-zero, `active` lease-scored, `schedule` run-at-scored,
`dead`), and eight verbs over six scripts move work between them.

Stack the machine as five layers, engine up:

- **L0 — Valkey.** The engine. External — and an enforced conformance gate: the truth row runs on
  Valkey, current stable line.
- **L1 — the grammar and the sets.** `emq:{q}:<type>`, the gated `job:` position, the `{emq}:` reserve; the
  three-field hash; the four sorted sets. Owned.
- **L2 — the versioned bundle.** Six Lua scripts carrying every state transition, every key declared in
  `KEYS[]` or derived from a declared root. Owned.
- **L3 — the connector.** RESP encoding, pipelining, EVALSHA-first dispatch with exactly one `NOSCRIPT` load —
  and the fence read at every connect. Varies per runtime.
- **L4 — the runtime API.** The eight verbs a caller uses — `enqueue`, `browse`, `pending_size`, `claim`,
  `complete`, `retry`, `promote`, `reap`. Varies per runtime.

L1 and L2 are the protocol. They are owned and versioned — not frozen by pinning someone else's commit, but
governed by written change rules behind a version fence.

## §2 · The boundary is a fence, not a pin

The boundary between L2 and L3 is the line between the owned protocol and the runtime's own code. What holds
the line is not a pinned commit. It is the **version fence**: at every connect — first boot and every reconnect —
the connector reads `{emq}:version`, claims it on a fresh keyspace, and refuses to start on any other value
with a typed error. The committed line from `bcs3.1` reads:
`GET {emq}:version answers echomq:3.0.0 through the fenced connector itself`.

```text
L4  runtime API     — varies per runtime: EchoMQ.Jobs in Elixir; a Go loop around the same calls
L3  the connector   — varies per runtime: RESP, pipelining, EVALSHA-first dispatch
——— the boundary — held by the version fence: a mismatch is a typed boot refusal ———
L2  the bundle      # six Lua scripts, eight verbs; every key declared or root-derived
L1  the grammar     # emq:{q}:<type> · the three-field hash · the four sorted sets
L0  Valkey    # the engine — external, and an enforced conformance gate
```

The connector that holds this boundary is gated against live Valkey, and the gate record is committed
(`bcsA`): the fence claimed the wire version, EVALSHA dispatch recorded `script_loads=1`, pipelined EVALSHA ran
at `161192 ops/s`, and the record ends `PASS 8/8`.

## §3 · The three dives

Each dive takes one part of the story, in the arc *the layers → the owned core → the door*:

- **R0.3.1 · The four layers** — L0 Valkey to L4 runtime API; the claim script quoted verbatim; why the script
  is the contract: same bytes, same SHA1, same semantics.
- **R0.3.2 · The immutable core** — the closed grammar, the `{emq}:` reserve of exactly four members, the
  three-field hash, the four sets — and the governance that keeps the core stable: the two-way typed fence, the
  written change rules, the wire classes `EMQKIND` and `EMQSTALE`.
- **R0.3.3 · The door to EchoMQ** — the contract retold: the script is the contract, the branded id is the wire
  form, one queue answers one slot by grammar — and the live route doors to `/echomq` and `/bcs`.

**The pattern → its EchoMQ application.** Take the patterns a queue needs — atomic moves, leases, schedules, a
morgue — write them down as a grammar plus scripts, version the result, and fence the boot. That is EchoMQ: the
closed `emq:{q}:<type>` grammar, the three-field hash, the four sorted sets, eight verbs over six scripts —
owned, versioned, and backed by Valkey. After R0.3, the Overview chapter is complete and the pattern chapters
begin.

## References

### Sources
- [Valkey — Topics](https://valkey.io/topics/) — the engine the connector is gated against.
- [Valkey — Programmability](https://valkey.io/topics/programmability/) — atomic script execution, the basis of every transition in the bundle.
- [Redis — Documentation](https://redis.io/docs/) — the command and data-type reference behind the catalog.
- [llmstxt.org — The llms.txt convention](https://llmstxt.org/) — the machine-readable map format the course follows.

### Related in this course
- [R0.3.1 · The four layers](/redis-patterns/overview/patterns-become-protocol/the-four-layers) — the stack, L0 to L4.
- [R0.3.2 · The immutable core](/redis-patterns/overview/patterns-become-protocol/the-immutable-core) — the owned core and its governance.
- [R0.3.3 · The door to EchoMQ](/redis-patterns/overview/patterns-become-protocol/the-door-to-echomq) — the contract, and the doors.
- [R0.2 · Valkey under codemojex](/redis-patterns/overview/redis-under-game) — where Valkey sits.
- [R0 · Overview](/redis-patterns/overview) — the chapter.
- [/echomq](/echomq) — the protocol in depth, rung by rung.
