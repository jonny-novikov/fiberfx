# EMQ3.1 — the Mars brief (S1 the writer, part 1 — the stream verbs on the connector)

> The compact build brief. The body [`emq3.1.md`](emq3.1.md) is authoritative; the acceptance is
> [`emq3.1.stories.md`](emq3.1.stories.md); the run scope is [`emq3.1.prompt.md`](emq3.1.prompt.md). Build ONLY
> inside `echo/apps/echo_mq` on the recommended FORK 3.1-A arm (the stream verbs ride the shipped `echo_wire`
> connector `command/3`/`pipeline/3` — NO `echo_wire` edit). Cite the spec line for every public call; the verbs
> are issued direct as `parts` lists (NO new `Script.new/2` — emq3.1 is verb plumbing, not a script rung); the
> conformance additive-minor mechanics. **The four forks are RULED by the Operator BEFORE you build** (the Director
> routes via `AskUserQuestion`); build to the ruled arms.
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software (components read, compute, refuse, return); no first-person
> narration. Bind this same clause in any sub-brief.

## References (read first — the exact upstream, links/paths first)

1. **The body** — [`emq3.1.md`](emq3.1.md): Goal · Scope · INV1–8 · the closed error set · the forks (3.1-A/B/C/D)
   · DoD. **The forks are RULED by the Operator BEFORE you build**; build to the ruled arms (the recommended arms:
   3.1-A ride the generic path · 3.1-B `emq:{q}:stream:<name>` +1 scenario · 3.1-C `2.6.0` · 3.1-D non-blocking).
2. **The tier contract** — [`../../emq.streams.md`](../../emq.streams.md): the Stream Tier ladder (emq3.1–3.6), the
   three milestones (S1 writer · S2 readers · S3 memory), the version plane (additive-minor, the deferred
   `echomq:3.0.0` cutover), the seams. emq3.1 is S1's verb floor; the writer LAW (`EchoMQ.Stream`) is emq3.2.
3. **The generic command path to RIDE (SHIPPED — the FORK 3.1-A recommended arm, NO edit)** —
   `echo/apps/echo_wire/lib/echo_mq/connector.ex`:
   - `command/3` (`connector.ex:47-54`) — `command(conn, parts, timeout \\ 5_000)` where `parts` is `[binary() |
     integer() | atom()]`; it is `pipeline(conn, [parts], timeout)` of one → `{:ok, RESP.reply()}` | `{:error,
     term()}`. The moduledoc (`connector.ex:2-10`): *"a purpose-built Valkey client … pipelining as the primitive."*
     **The verbs ride THIS** — `command(conn, ["XADD", key, "*", field, value])`. No edit.
   - `pipeline/3` (`connector.ex:56-60`) — `pipeline(conn, cmds, timeout)` where `cmds` is a list of command-lists →
     `{:ok, [reply]}` in call order. The pipelined `XADD` batch rides THIS.
   - `push_command/3` (`connector.ex:99-102`) — *"Send a command whose replies arrive out of band — the SUBSCRIBE
     family … Requires a RESP3 connection."* The precedent for the blocking-read out-of-band path (emq3.3, NOT this
     rung — FORK 3.1-D defers blocking).
   - `@wire_version "echomq:2.4.2"` (`connector.ex:35`) — the boot fence constant; **byte-unchanged** (additive
     registration, no wire break — INV6). The `echo_wire` diff MUST be EMPTY on the recommended arm.
4. **The verb-agnostic codec (SHIPPED)** — `echo/apps/echo_wire/lib/echo_mq/resp.ex`:
   - `encode/1` (`resp.ex:20-28`) — `[verb | args]` → `*N\r\n` + a `$len\r\n<bytes>\r\n` bulk per element; `bulk/1`
     over binary/integer/atom/iodata. **Verb-agnostic by construction** — `XADD` encodes exactly as `SET`. No edit.
   - `parse/1` (`resp.ex:45-87`) — the one-pass RESP2/RESP3 decoder: arrays (`*`, `resp.ex:59`) → lists (`XRANGE` is
     a nested array), maps (`%`, `resp.ex:63`), the null array (`*-1` → `nil`, `resp.ex:120`), error replies as
     values (`{:error_reply, msg}`, `resp.ex:47`), **push frames (`>`) → `{:push, […]}`** out of band (`resp.ex:60`).
5. **The facade + the escape hatch (SHIPPED)** — `echo/apps/echo_wire/lib/echo_wire.ex` (`:20-25` —
   `defdelegate command/3`/`pipeline/3`/`push_command/3` to `Connector`) + `echo/apps/echo_wire/lib/echo_wire/pipe.ex`
   `command/2` (`pipe.ex:496-497` — appends a raw command-list verbatim; *"Any command not curated … is reachable
   through `command/2`"* `pipe.ex:39-43`; `exec/1` = one `pipeline/3` call, `pipe.ex:16-22`). The ewr.1.2 escape
   hatch — `XADD` is reachable here for the pipelined batch (US2).
6. **The braced grammar (SHIPPED, NO edit)** — `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`: `queue_key/2`
   (`keyspace.ex:13-15`) builds `emq:{q}:<type>` for ANY `<type>` (the hash applied transparently); `slot/1`
   (`keyspace.ex:43-44`) the CRC16 over the hashtag; `job_key/2` (`keyspace.ex:17-24`) gates `BrandedId.valid?/1`.
   **No grammar edit** — `emq:{q}:stream:<name>` rides the total `queue_key(q, "stream:" <> name)` (FORK 3.1-B).
7. **The ephemeral pub/sub seam the rung does NOT disturb (SHIPPED)** —
   `echo/apps/echo_mq/lib/echo_mq/events.ex`: the per-queue lifecycle-event pub/sub over `Connector.subscribe/2` +
   the `{:emq_push, …}` push (`events.ex:7-15`); it explicitly defers the durable replayable stream — *"the durable
   replayable receipt is emq3.2's `EchoMQ.Stream`, not this"* (`events.ex:36`). emq3.1's push-safety proof (US3)
   round-trips a stream IN BAND while this seam delivers a push OUT of band — proving the FIFO stays aligned.
8. **The conformance harness (SHIPPED)** — `echo/apps/echo_mq/lib/echo_mq/conformance.ex` (`scenarios/0` + `run/2`)
   + the two pins `test/conformance_run_test.exs` (`{:ok, 73}` at `:58`) + `test/conformance_scenarios_test.exs`
   (`@run_order`, 73 names). The additive-minor law: extend `scenarios/0` with the new scenario(s) + the probe in
   the SAME change, the prior 73 byte-unchanged, re-pin the count in BOTH tests (FORK 3.1-B recommend +1 → 74).
9. **The program law** — `.claude/skills/echo-mq-program.md` (the v2 laws, the gate ladder, the additive-minor /
   additive-registration-is-a-minor law) + the as-built map `.claude/skills/echo-mq-surface.md`. **Re-probe the
   as-built tree at Stage-0** (the lag-1 law — line numbers are hints, grep/Read to confirm).

## Requirements (numbered — each traces to a story + an invariant)

- **R1 — the five stream verbs reachable + proven (FORK 3.1-A RULED: ride the generic path).** Issue each of `XADD`
  · `XRANGE` · `XREADGROUP` (no `BLOCK`) · `XACK` · `XAUTOCLAIM` as a `parts` list through the shipped
  `Connector.command/3` (`connector.ex:47-54`) / `EchoWire.command/3` (`echo_wire.ex:20`); assert each reply against
  the appended data (a POSITIVE proof — `XRANGE` reads back the exact `XADD`-appended entry, etc.). NO connector
  surface added, NO `echo_wire` edit (the recommended arm). → US1; INV1, INV2, INV5, INV6.
- **R2 — the pipelined `XADD` batch.** Append N (>= 2) entries in one pipeline through `Connector.pipeline/3`
  (`connector.ex:56-60`) or an `EchoWire.Pipe` threaded with `command/2` (`pipe.ex:496-497`); assert `{:ok, [id1, …,
  idN]}` (N ids in call order) and read back N entries with `XRANGE` in mint order. → US2; INV3, INV2, INV5.
- **R3 — push-safety under RESP3.** On a RESP3 connection subscribed to a channel (the `EchoMQ.Events` seam,
  `events.ex`), round-trip an in-band `XADD`/`XRANGE`/`XACK` sequence WHILE a push is published; assert BOTH the
  stream replies are correct AND the concurrent push is delivered out of band (a `{:push, …}` frame, never enqueued
  on the reply FIFO — `resp.ex:60`). NO proof verb carries a `BLOCK` argument (the blocking `XREADGROUP BLOCK` form
  DEFERRED to emq3.3 — FORK 3.1-D); the non-blocking `XREADGROUP`/`XAUTOCLAIM` forms return on the FIFO. → US3;
  INV4, INV2.
- **R4 — the `emq:{q}:stream:<name>` §6 key type (FORK 3.1-B RULED: the braced type, +1 scenario).** Build every
  stream key via `Keyspace.queue_key(q, "stream:" <> name)` (`keyspace.ex:13-15`) — the braced grammar, the `{q}`
  hashtag slot; assert `slot/1` of a stream key equals `slot/1` of that queue's `pending` key (same hashtag, same
  slot). NO grammar edit (`git diff keyspace.ex` empty) — the §6 registry gains `stream:<name>` as a documentation
  act, not a code edit; NO new key-validation gate. The branded record id is emq3.2's law — emq3.1 uses the server
  `*` id. → US1, US2; INV5.
- **R5 — the wire stays frozen (additive registration is a protocol minor).** On the recommended FORK 3.1-A arm:
  the `echo_wire` `git diff` against HEAD is EMPTY (the connector untouched); `{emq}:version` reads `echomq:2.4.2`
  (the `@wire_version` byte-unchanged); NO new `Script.new/2` (emq3.1 is verb plumbing — the verbs are issued
  direct, not via Lua); the §6 grammar in `keyspace.ex` unedited; the closed `EMQKIND`/`EMQSTALE` registry
  byte-unchanged. → US4; INV1, INV6, INV5.
- **R6 — the conformance scenario(s) (additive minor — FORK 3.1-B RULED +1).** Register `stream_verbs` (the five
  verbs round-trip + the pipelined `XADD` batch + push-safe under RESP3, ONE verb-floor capability) in `scenarios/0`
  with its probe in the SAME change; the prior **73** byte-unchanged; re-pin **73 → 74** in BOTH pins
  (`conformance_run_test.exs` `{:ok, 74}` + `conformance_scenarios_test.exs` `@run_order`). Write the `:valkey`
  proof to US1 (the five verbs, a POSITIVE proof) + US2 (the pipelined batch) + US3 (push-safety). → US5, US1, US2,
  US3; INV7, INV2.
- **R7 — the proof + determinism posture.** Per-app gate ladder inside `echo/apps/echo_mq` (TMPDIR=/tmp, `--include
  valkey`); `Conformance.run/2 → {:ok, 74}`; a **multi-seed sweep** (several `--seed` values) + the explicit
  determinism statement (the verb path mints no id and starts no process — NOT the ≥100 loop, INV8); honest-row
  (Valkey 6390). → US6; S-4, INV8.

## Execution topology

**Runtime shape.** emq3.1 is a `:valkey` proof + a conformance scenario over the SHIPPED connector `command/3`/
`pipeline/3` — NO new module, NO new process, NO new supervised child, NO `echo_wire` edit (the recommended FORK
3.1-A arm). The stream verbs are `parts` lists; the stream key is `emq:{q}:stream:<name>` (the braced grammar via
the total `queue_key/2`). The verbs round-trip on the certified connector (the FIFO pairing each in-flight command
to its caller); push-safety is the RESP3 push/in-band separation the connector already guarantees. **No id is
minted** (the stream append uses the server `*` id — the branded record-id law is emq3.2); **no lease is touched**
(the stream verbs carry no `emq:{q}:` lease). The rung is verb PLUMBING — the writer law (emq3.2), the readers
(emq3.3), retention (emq3.4) all ride the proven verb floor.

**The build-order task DAG.**
```
R1 the five verbs reachable (parts lists through command/3)  ──►  R2 the pipelined XADD batch (pipeline/3 / Pipe.command/2)
   │                                                              └─► R3 push-safety under RESP3 (in-band verbs + an out-of-band push)
   ├─► R4 the emq:{q}:stream:<name> key type (the total queue_key/2; slot == the queue's pending slot)
   ├─► R5 the wire-frozen battery (echo_wire diff EMPTY; @wire_version 2.4.2; no new script; §6 unedited)
   └─► R6 the stream_verbs conformance scenario + the 73→74 re-pin  ──►  R7 proof (:valkey + a multi-seed sweep)
```

**The EXACT files touched** (the Stage-6 commit pathspec — Director-only; adjust to the ruled touch-set):
```
echo/apps/echo_mq/lib/echo_mq/conformance.ex     (the stream_verbs scenario + the count prose)
echo/apps/echo_mq/test/stream_verbs_test.exs     (the :valkey stream-verb proof — NEW; US1 + US2 + US3)
echo/apps/echo_mq/test/conformance_run_test.exs       (re-pin {:ok, 74})
echo/apps/echo_mq/test/conformance_scenarios_test.exs (re-pin @run_order → 74 names)
echo/apps/echo_mq/mix.exs                        (the rung label — 2.6.0, the recommended FORK 3.1-C arm)
docs/echo_mq/specs/emq3/emq3.1.{md,stories.md,llms.md,prompt.md}  (Stage-5 sync)
docs/echo_mq/specs/progress/emq3-1.progress.md   (+ the registry)
docs/echo_mq/emq.streams.md                      (IFF a Stage-5 tier sync is needed — the emq3.1 SHIPPED note)
```
**EXCLUDED:** `echo_wire/*` (UNTOUCHED on the recommended FORK 3.1-A arm — the `echo_wire` diff MUST be EMPTY; the
connector is the one named seam touched ONLY if FORK 3.1-A is ruled the frozen-touch arm, which the reconcile
argues against), `keyspace.ex` (no grammar edit — the stream key rides the total `queue_key/2`), `jobs.ex`/
`lanes.ex` (no script edit — emq3.1 adds no Lua), `apps/echomq` (the capability reference), `mix.lock` (no real dep
moved), any `AM`-status out-of-band file.

## Agent stories (Directive + Acceptance gate — each a contract at the boundary)

- **AS1 — prove the five verbs reach the wire.** *Directive:* issue each stream verb (`XADD` · `XRANGE` ·
  `XREADGROUP` no `BLOCK` · `XACK` · `XAUTOCLAIM`) as a `parts` list through the shipped `Connector.command/3` (the
  ruled FORK 3.1-A arm), against `emq:{q}:stream:<name>`.
  *Acceptance gate (contract):* **precondition** — a RESP3 connection to Valkey 6390 + a stream key built by
  `queue_key(q, "stream:s")`; **postcondition** — each verb's reply parses and is asserted against the appended
  data (`XADD` → an id; `XRANGE` → the exact appended entry; `XREADGROUP` → the group's entries; `XACK` → the count;
  `XAUTOCLAIM` → the triple); **invariant** — the `echo_wire` `git diff` is EMPTY (no connector edit), `{emq}:version`
  = `echomq:2.4.2` (INV1, INV2, INV6). A round-trip that asserts nothing about the reply is a vacuous pass (LOUD
  failure).
- **AS2 — prove the pipelined `XADD` batch.** *Directive:* append N (>= 2) entries in one pipeline through
  `Connector.pipeline/3` / `EchoWire.Pipe.command/2`. *Acceptance gate:* **precondition** — a stream key + N entries;
  **postcondition** — `{:ok, [id1, …, idN]}` (N ids in call order) + `XRANGE` reads back N entries in mint order;
  **invariant** — the connector is the sole owner of the wire (`exec/1` = one `pipeline/3` call, no second
  pipelining mechanism — INV3). A 1-entry "pipeline" proves nothing (use N >= 2).
- **AS3 — prove push-safety under RESP3.** *Directive:* round-trip an in-band `XADD`/`XRANGE`/`XACK` sequence on a
  RESP3 connection subscribed to a channel (the `Events` seam) WHILE a push is published. *Acceptance gate:*
  **precondition** — a subscribed RESP3 connection + a live stream; **postcondition** — the stream replies are
  correct AND the concurrent push is delivered out of band (the FIFO stays aligned); **invariant** — no proof verb
  carries a `BLOCK` argument (the blocking `XREADGROUP BLOCK` form deferred to emq3.3 — INV4, FORK 3.1-D). A
  push-safety proof with no concurrent push proves nothing (LOUD failure).
- **AS4 — the wire-frozen battery + conformance.** *Directive:* register the `stream_verbs` scenario (FORK 3.1-B
  RULED +1) additive-minor; re-pin 73 → 74 in both pins; run the wire-frozen battery. *Acceptance gate:*
  **postcondition** — `Conformance.run/2 → {:ok, 74}`, both pins pass, the `echo_wire` `git diff` EMPTY, no new
  `Script.new/2`, the §6 grammar unedited; **invariant** — the prior 73 scenarios byte-unchanged (git-verified),
  the new scenario's probe registered in the same change (INV7, INV6, INV5). A scenario that issues the verbs and
  asserts nothing about the replies fails its own letter.
- **AS5 — the proof + the multi-seed sweep.** *Directive:* run the full per-app gate ladder + a multi-seed sweep
  inside `echo/apps/echo_mq`. *Acceptance gate:* **postcondition** — `compile --warnings-as-errors` clean, `mix test
  --include valkey` green, a multi-seed sweep green, honest-row (Valkey 6390); **invariant** — the determinism
  posture is a multi-seed sweep + the explicit statement (NOT the ≥100 loop — the verb path mints no id and starts
  no process; INV8). IF the proof is found to mint a branded id (it should not — that is emq3.2), escalate to the
  ≥100 loop (the posture flip named).

## A short comprehensive prompt (no decision the spec has not fixed — except the ruled forks)

Prove the stream-verb floor inside `echo/apps/echo_mq` to the ruled FORK 3.1-A/B/C/D arms — on the recommended
arms, NO `echo_wire` edit. Issue each of the five stream verbs (`XADD` · `XRANGE` · `XREADGROUP` no `BLOCK` ·
`XACK` · `XAUTOCLAIM`) as a `parts` list through the shipped `Connector.command/3` (`connector.ex:47-54`) — the
connector is ALREADY a generic RESP client (`RESP.encode/1` is verb-agnostic, `resp.ex:20-28`), so the verbs ride
the shipped path with zero connector edit. Build the stream key via the total `Keyspace.queue_key(q, "stream:" <>
name)` (`keyspace.ex:13-15`) — `emq:{q}:stream:<name>`, the braced `{q}` slot, NO grammar edit. Prove a pipelined
`XADD` batch (N >= 2 entries through `Connector.pipeline/3` or `EchoWire.Pipe.command/2`, N ids in call order, read
back in mint order). Prove push-safety under RESP3 (in-band `XADD`/`XRANGE`/`XACK` round-trip without disturbing the
out-of-band push routing the `EchoMQ.Events` seam depends on — `resp.ex:60`; no proof verb carries a `BLOCK`
argument, the blocking read is emq3.3's). Register the `stream_verbs` conformance scenario additive-minor (the prior
73 byte-unchanged; re-pin 73 → 74 in both pins). Run the per-app gate ladder + a multi-seed sweep on Valkey 6390 (a
verb-plumbing rung mints no id and starts no process — NOT the ≥100 loop). The `echo_wire` `git diff` MUST be EMPTY
(`@wire_version` frozen at `echomq:2.4.2`); no new `Script.new/2`; no §6 grammar edit; no new key family beyond the
named `emq:{q}:stream:<name>` type; no client-side blocking read; no git. Report the gate results before going
idle.
