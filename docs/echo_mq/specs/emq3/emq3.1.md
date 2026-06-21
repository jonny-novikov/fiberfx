# EMQ3.1 · S1 the writer (part 1) — the stream verbs on the connector (EchoMQ 3.0, the Stream Tier, the founding rung)

> **Status: ✅ BUILT + SHIPPED (2026-06-22) — all four forks RULED as the recommended arms below (3.1-A
> ride-generic · 3.1-B braced §6 type +1 · 3.1-C `2.6.0` · 3.1-D non-blocking); the ledger
> [`../progress/emq3-1.progress.md`](../progress/emq3-1.progress.md) records D-1..D-4 + Y-1 BUILD-GRADE + Z-1 —
> Conformance 73→74, label `echomq:2.6.0`, `echo_wire` UNTOUCHED, zero defects.** This body is forward-tense ("emq3.1 builds…") for everything the
> rung adds; surfaces that already ship are cited present-tense against the re-probed `echo_wire`/`echo_mq` tree
> (the lag-1 law). The **FIRST rung of EchoMQ 3.0 — the Stream Tier** ([`../../emq.streams.md`](../../emq.streams.md)),
> just re-sequenced to ACTIVE (Operator-ruled 2026-06-22): the Stream Tier hard-gates on `emq.0` ONLY (met), so it
> opens unblocked ahead of the remaining 2.x families (emq.6/7/8, parked behind it). emq3.1 builds the **verb
> plumbing**: the five stream verbs (`XADD` · `XRANGE` · `XREADGROUP` · `XACK` · `XAUTOCLAIM`) reachable on the
> certified connector, round-tripped and proven push-safe under RESP3 — the floor every later Stream rung stands
> on. The writer LAW (the `EchoMQ.Stream` module, hash-tagged stream keys, branded record ids, append == mint) is
> **emq3.2, NOT this rung** — emq3.1 is the verb reach, not the writer surface.
>
> **The recommended arms (the forks the Operator rules — see "The rung's forks").** FORK 3.1-A → **ride the
> existing generic command path** (`EchoMQ.Connector.command/3` + `EchoWire.Pipe.command/2`, ZERO `echo_wire`
> edit — the reconcile proves the connector is already a generic RESP client); FORK 3.1-B → **`emq:{q}:stream:<name>`
> as a NEW §6 braced key type** (declared-keys + hash-tag implications named); FORK 3.1-C → **the rung label steps
> a MINOR `2.5.2` → `2.6.0`** (opening the Stream Tier family resets the patch, the position-encoded convention);
> FORK 3.1-D → **scope to non-blocking round-trips, DEFER blocking consumer-group reads (`BLOCK`) to emq3.3** (the
> single-owner socket honesty). The recommended arms are the strawman the body is authored TO; each fork's
> alternative is surfaced, none is decided here.
>
> **Risk: NORMAL (on the recommended FORK 3.1-A arm).** The reconcile proves the as-built `EchoMQ.Connector` is
> already a generic RESP client — `command/3` takes `(conn, [parts], timeout)` and `RESP.encode/1` encodes any
> `[verb | args]` list as a RESP array of bulk strings (verb-agnostic, no command whitelist; `connector.ex:47-54`,
> `resp.ex:20-28`). So `XADD foo * field val` is just another `parts` list — emq3.1 rides the shipped path with
> **ZERO frozen-line touch**. No new script · no destructive at-rest op · no new process · no wire break · the
> `@wire_version` stays FROZEN at `echomq:2.4.2`. **IF the Operator rules FORK 3.1-A the other way** (extend the
> connector with stream-verb support — unnecessary on the evidence) the rung becomes a FROZEN-LINE TOUCH → **HIGH**.
> Determinism posture: a verb-plumbing rung mints no branded id and starts no process in the verb path — the
> honest posture is a **multi-seed sweep**, NOT the ≥100 loop (stated honestly at "The rung's forks").

## 0 · The slice — what emq3.1 builds, and why the verb floor first

The tier ([`../../emq.streams.md`](../../emq.streams.md)) ships **event streams on the certified wire under the v2
laws, no second protocol**. Its three milestones are **S1 the writer** (emq3.1–3.2) → **S2 the readers**
(emq3.3–3.4) → **S3 the memory** (emq3.5–3.6). emq3.1 is the FIRST rung of S1: the **verb plumbing** beneath the
writer law.

The split is deliberate (the tier ladder, [`../../emq.streams.md`](../../emq.streams.md) §The ladder): emq3.1
makes the five stream verbs **reachable and proven on the connector** — round-trips, a pipelined `XADD` batch, and
push-safety under RESP3. emq3.2 then builds the writer LAW on top: `EchoMQ.Stream` (per-key hash-tagged streams,
branded record ids, append == mint order). Keeping the verb reach in its own rung lands the floor cleanly: the
later writer/reader/retention rungs all assume the verbs already round-trip, so proving them once — against the
certified connector, push-safe — is the cheapest place to gate the plumbing.

The verbs are **reachable, not invented** — the connector is ALREADY a generic RESP client (the reconcile, below).
The just-shipped `EchoMQ.Events` (`events.ex`) names this rung's successor in committed code: it is the EPHEMERAL
pub/sub seam (sharded pub/sub deferred to the cache rung, `events.ex:13`) and explicitly defers the durable
replayable stream — *"the durable replayable receipt is emq3.2's `EchoMQ.Stream`, not this"* (`events.ex:36`). So
emq3.1's `XADD`/`XRANGE` verbs are the plumbing BENEATH that named-but-unbuilt `EchoMQ.Stream`; the forward
references already live in the shipped tree.

What emq3.1 stands on (all SHIPPED, present-tense — cited by re-probe, the lag-1 law):

- `EchoMQ.Connector.command/3` (`connector.ex:47-54`) — the generic command path: `command(conn, parts, timeout)`
  where `parts` is `[binary() | integer() | atom()]`; it is `pipeline(conn, [parts], timeout)` of one, returning
  `{:ok, RESP.reply()}` | `{:error, term()}`. The moduledoc is explicit (`connector.ex:2-10`): *"a purpose-built
  Valkey client on raw `:gen_tcp` and the RESP2 codec … pipelining as the primitive (`command/2` is a pipeline of
  one)."* No command whitelist — any verb is a `parts` list.
- `EchoMQ.Connector.pipeline/3` (`connector.ex:56-60`) — the FIFO-ordered batch path: a list of command-lists →
  `{:ok, [reply]}` in call order. A pipelined `XADD` batch is a list of `["XADD", key, "*", …]` lists.
- `EchoMQ.RESP.encode/1` (`resp.ex:20-28`) — encodes `[verb | args]` as `*N\r\n` + a `$len\r\n<bytes>\r\n` bulk
  per element, `bulk/1` over binary/integer/atom/iodata. **Verb-agnostic by construction** — it never inspects the
  verb; `XADD` encodes exactly as `SET` does.
- `EchoMQ.RESP.parse/1` (`resp.ex:45-87`) — the one-pass RESP2/RESP3 decoder: arrays (`*`) → lists (an `XRANGE`
  reply is a nested array), maps (`%`), the null array (`*-1` → `nil`), error replies as values (`{:error_reply,
  msg}`), and **push frames (`>`) → `{:push, […]}`** routed out of band, never into the reply FIFO (`resp.ex:60`,
  the moduledoc `resp.ex:13-15`).
- `EchoMQ.Connector.push_command/3` (`connector.ex:99-102`) — *"Send a command whose replies arrive out of band —
  the SUBSCRIBE family. Nothing is enqueued on the FIFO … Requires a RESP3 connection."* The precedent for any
  verb whose replies are out-of-band pushes (the push-safety boundary FORK 3.1-D names).
- `EchoWire` (`echo_wire.ex`) — the facade: `defdelegate command(conn, parts, timeout)` / `pipeline/3` /
  `push_command/3` to `Connector` (`echo_wire.ex:20-25`). The forward-facing name for the same generic path.
- `EchoWire.Pipe` (`pipe.ex`) — threaded `|>` pipeline construction; `command/2` (`pipe.ex:496-497`) appends a raw
  command-list verbatim — *"Any command not curated … is reachable through `command/2`"* (`pipe.ex:39-43`). The
  ewr.1.2 escape hatch — `XADD` is "a different family" reachable here, replies one-to-one with the appended
  commands.
- `EchoMQ.Keyspace.queue_key/2` (`keyspace.ex:13-15`) — `emq:{q}:<type>` for ANY `<type>` string, the hash applied
  transparently so every key of one queue lands on one slot. A stream key type (`stream:<name>`) rides this grammar
  with NO key-builder change (FORK 3.1-B).
- `EchoMQ.Conformance` (`conformance.ex` — `scenarios/0` + `run/2`) — the additive-minor harness, **73** scenarios
  live (`conformance_run_test.exs:58` `{:ok, 73}`; `conformance_scenarios_test.exs` `@run_order`).

## Goal

emq3.1 builds, inside `echo/apps/echo_mq` (riding the shipped `echo_wire` connector — ZERO `echo_wire` edit on the
recommended FORK 3.1-A arm), the **stream-verb floor**:

1. **The five stream verbs reachable + proven on the connector** — `XADD` · `XRANGE` · `XREADGROUP` · `XACK` ·
   `XAUTOCLAIM`, each issued through the shipped generic command path (`Connector.command/3` / `EchoWire.command/3`,
   the FORK 3.1-A recommended arm) and round-tripped against Valkey on 6390. The verbs are NOT wrapped in a new
   module surface (that is emq3.2's `EchoMQ.Stream`) — emq3.1 proves the PLUMBING: a `parts` list reaches the wire,
   the reply parses, the family works end-to-end on the certified connector.
2. **A pipelined `XADD` batch** — N `["XADD", key, "*", field, value, …]` command-lists through the shipped
   `Connector.pipeline/3` (or `EchoWire.Pipe` with `command/2`, the ewr.1.2 escape hatch), returning `{:ok,
   [reply]}` in call order — proving the stream-append path pipelines exactly as the shipped command families do
   (the connector is the sole owner of the wire; no second pipelining mechanism).
3. **Push-safety under RESP3** — `XADD`/`XRANGE`/`XACK` are in-band request/reply (their replies arrive on the
   FIFO); the rung proves they round-trip on a RESP3 connection WITHOUT disturbing the out-of-band push routing
   (the `EchoMQ.Events` pub/sub seam, `events.ex`, which shares the wire via `{:push, …}` frames). The non-blocking
   `XREADGROUP`/`XAUTOCLAIM` forms (NO `BLOCK` argument — FORK 3.1-D) return immediately on the FIFO; the BLOCKING
   `XREADGROUP BLOCK` form is DEFERRED to emq3.3 (the readers), where the consumer-group blocking-read posture is
   designed against the single-owner socket.
4. **The stream key type** — `emq:{q}:stream:<name>` as a NEW §6 braced key type (FORK 3.1-B recommended arm),
   built through the shipped `Keyspace.queue_key(q, "stream:" <> name)` (NO grammar edit — `queue_key/2` is total
   over `<type>`). The declared-keys consequence is named: a stream key shares the `{q}` hashtag slot, so a later
   script touching `emq:{q}:stream:<name>` alongside `emq:{q}:pending` is slot-sound by the braces. The branded
   record id (`XADD <key> <id>` with a caller-supplied branded id, append == mint) is **emq3.2's writer law**, NOT
   this rung — emq3.1 proves the key type reaches the wire (`XADD key * …` with the server-minted `*` id is
   sufficient to gate the plumbing; the branded-id discipline lands with the writer).
5. The **conformance scenario(s)** — additive minor, the prior **73** byte-unchanged → the new total (the count
   delta is FORK 3.1-B's companion decision; see the forks); the proof (the `:valkey` suite + a **multi-seed
   sweep** — a verb-plumbing rung mints no id and starts no process in the verb path, so NOT the ≥100 loop, stated
   honestly) + the wire-law confirmations (the §6 grammar unedited on the recommended arm; `{emq}:version` reads
   `echomq:2.4.2`).

All under the v2 master invariant: braced `emq:{q}:` keyspace · branded `JOB` ids gated at the key builder (the
stream is a NEW key TYPE, not a new id position — the branded record-id law is emq3.2) · every Lua key in `KEYS[]`
or derived from a declared `KEYS[n]` root by the A-1 grammar (emq3.1 adds NO new script on the recommended arm — it
is verb plumbing, not a script rung) · the server clock where leases are touched (no lease is touched — the stream
verbs carry no `emq:{q}:` lease) · inline `Script.new/2` (never `priv/`; emq3.1 adds no script) · additive-minor
conformance growth · additive registration is a protocol MINOR, no wire break.

## Rationale (5W)

- **Why** — every later Stream rung (the writer law emq3.2, the readers emq3.3, retention emq3.4, the archive
  emq3.5, time-travel emq3.6) assumes the stream verbs already round-trip on the certified connector. Proving that
  ONCE — the five verbs reachable, a pipelined append, push-safe under RESP3 — is the cheapest place to gate the
  plumbing, and it isolates the question the reconcile answers: **can the as-built connector send an arbitrary RESP
  command without a frozen-line edit?** The reconcile proves YES (the connector is a generic RESP client by
  construction), so emq3.1 lands the floor with zero wire risk and the writer law (emq3.2) starts from a proven
  verb reach. The verbs are the design's certified-wire posture: *"event streams on the certified wire under the v2
  laws, no second protocol"* ([`../../emq.streams.md`](../../emq.streams.md)).
- **What** — emq3.1 builds: (1) the five stream verbs reachable + proven on the shipped generic command path (the
  FORK 3.1-A recommended arm: `Connector.command/3`, ZERO `echo_wire` edit); (2) a pipelined `XADD` batch through
  the shipped `pipeline/3` / `EchoWire.Pipe.command/2`; (3) push-safety under RESP3 (in-band `XADD`/`XRANGE`/`XACK`
  round-trip without disturbing the out-of-band push routing; the blocking `XREADGROUP BLOCK` DEFERRED to emq3.3,
  FORK 3.1-D); (4) the `emq:{q}:stream:<name>` key type (a NEW §6 braced type via the total `queue_key/2`, FORK
  3.1-B); (5) the conformance scenario(s) (additive minor — the prior 73 byte-unchanged → the new total) + the
  `:valkey` proof + a multi-seed sweep (NOT the ≥100 loop — no id mint, no process in the verb path).
- **Who** — the program (the rung that founds the Stream Tier verb floor); **event-stream consumers** (the game-dev
  recorded-event-stream demand the tier carries, [`../../emq.streams.md`](../../emq.streams.md) §The needs); the
  conformance harness, which grows by the stream-verb scenario(s). The shipped `EchoMQ.Events` pub/sub seam
  (`events.ex`) is the precedent the rung does NOT disturb (push-safety, FORK 3.1-D). **Apollo** — the rung is
  verb plumbing on the recommended arm (no shipped-script edit, no new process), so Apollo is an OPTIONAL
  fast-finisher (closure + stories), NOT a ship precondition. IF FORK 3.1-A is ruled the frozen-touch arm (a
  connector edit), the rung becomes HIGH and **Apollo is mandatory** (a frozen-line touch — see the forks).
- **When** — EchoMQ 3.0, the Stream Tier, the **founding** rung (the FIRST of S1 the writer; everything in the tier
  rides the proven verb floor). The forks (FORK 3.1-A the verb-landing mechanism; FORK 3.1-B the stream keyspace;
  FORK 3.1-C the version label; FORK 3.1-D the push-safety / blocking-read boundary — see "The rung's forks") are
  RULED by the Operator at the pre-build reconcile (the Director routes via `AskUserQuestion`) BEFORE Mars builds.
- **Where** — `echo/apps/echo_mq` only (on the recommended FORK 3.1-A arm): `conformance.ex` (the stream-verb
  scenario(s) + the count re-pin), the `:valkey` proof (a new or extended test exercising the five verbs +
  pipelined append + push-safety), the two pinning tests (`conformance_run_test.exs` `{:ok, <new>}` +
  `conformance_scenarios_test.exs` `@run_order`), `mix.exs` (the rung label — `2.6.0` on the recommended FORK 3.1-C
  arm, opening the Stream Tier family). **`echo_wire` is UNTOUCHED** on the recommended arm (the stream verbs ride
  the shipped connector `command/3`/`pipeline/3`/`push_command/3`; `@wire_version` stays `echomq:2.4.2`). **IF FORK
  3.1-A is ruled the frozen-touch arm**, `echo/apps/echo_wire/lib/echo_mq/connector.ex` is the one named seam (a
  HIGH-risk frozen-line touch). `apps/echomq` is **untouched** (the capability reference). The §6 grammar in
  `keyspace.ex` is **unedited** — the stream key type rides the total `queue_key/2` (FORK 3.1-B; the grammar is the
  registry of `<type>` strings, and `queue_key/2` builds any of them — adding `stream:<name>` to the registry is a
  documentation act in the design §6, not a code edit, unless a key-validation gate is added, which this rung does
  not).

## Scope

- **In** — the stream-verb floor: (1) the five stream verbs (`XADD` · `XRANGE` · `XREADGROUP` · `XACK` ·
  `XAUTOCLAIM`) reachable + proven on the shipped generic command path (FORK 3.1-A recommended: `Connector.command/3`,
  ZERO `echo_wire` edit); (2) a pipelined `XADD` batch through the shipped `pipeline/3` / `EchoWire.Pipe.command/2`;
  (3) push-safety under RESP3 (in-band round-trip without disturbing the out-of-band push routing; non-blocking
  verb forms only — `BLOCK` deferred, FORK 3.1-D); (4) the `emq:{q}:stream:<name>` §6 braced key type via the total
  `queue_key/2` (FORK 3.1-B); (5) the conformance scenario(s) (additive minor — the prior 73 byte-unchanged → the
  new total) + the `:valkey` proof + a multi-seed sweep.
- **Out** — the **writer LAW** (`EchoMQ.Stream` — the per-key hash-tagged stream module, branded record ids, append
  == mint order, wrong-kind refused at the door — emq3.2; emq3.1 is the verb reach, NOT the writer surface); the
  **branded record-id discipline** (`XADD <key> <branded-id>` with the order theorem extended to the log — emq3.2;
  emq3.1 may append with the server-minted `*` id to prove the plumbing); **consumer groups + the polyglot seam** (a
  BEAM consumer + a non-BEAM reader on one group, at-least-once, crash → `XAUTOCLAIM` re-delivery — emq3.3; emq3.1
  proves the verbs reach the wire, NOT the group lifecycle); the **blocking consumer-group read** (`XREADGROUP
  BLOCK` on the single-owner socket — emq3.3, FORK 3.1-D — emq3.1 scopes to non-blocking round-trips); **retention
  as policy** (`MAXLEN`/`MINID` windows — emq3.4); the **archive** (segments folded to the `Graft` engine —
  emq3.5); **time-travel + hydration** (mint-instant → `XRANGE` bounds — emq3.6); any **new inline `Script.new/2`**
  (emq3.1 is verb plumbing — no new script on the recommended arm; the verbs are issued direct, not via Lua); any
  **edit to a shipped script** (every shipped script byte-frozen — emq3.1 adds none); any **`echo_wire`/transport
  change** (UNTOUCHED on the recommended FORK 3.1-A arm; the one named connector seam is touched ONLY if FORK 3.1-A
  is ruled the frozen-touch arm); any **edit to the frozen v1 line** (`apps/echomq`).

## Invariants (the runnable checks emq3.1 carries)

- **EMQ3.1-INV1 — the verbs ride the shipped generic command path (the FORK 3.1-A recommended arm), no `echo_wire`
  edit.** The five stream verbs are issued through `EchoMQ.Connector.command/3` (`connector.ex:47-54`) /
  `EchoWire.command/3` (`echo_wire.ex:20`) / `EchoMQ.Connector.pipeline/3` (`connector.ex:56-60`) — the shipped
  generic RESP path, verb-agnostic by `RESP.encode/1` (`resp.ex:20-28`). emq3.1 adds NO connector surface, NO new
  command-dispatch code, NO `echo_wire` edit (the recommended arm). *Check:* the `:valkey` proof issues each verb
  as a `parts` list through the shipped `command/3`/`pipeline/3`; a `git diff` of `echo/apps/echo_wire/` is EMPTY
  (zero lines — the connector is untouched); `{emq}:version` reads `echomq:2.4.2` (the `@wire_version` constant,
  `connector.ex:35`, byte-unchanged). [On the frozen-touch arm this INV flips to "the one named connector seam is
  the only `echo_wire` edit" — surfaced at FORK 3.1-A.]
- **EMQ3.1-INV2 — every stream verb round-trips end-to-end on the certified connector.** Each of `XADD` · `XRANGE`
  · `XREADGROUP` · `XACK` · `XAUTOCLAIM` issued as a `parts` list reaches Valkey on 6390 and its reply parses
  through `RESP.parse/1` (`resp.ex:45-87`): `XADD` → a bulk entry-id string; `XRANGE` → a nested array of `[id,
  [field, value, …]]` entries (parsed by the array branch `resp.ex:59`); `XREADGROUP` (non-blocking) → the
  stream→entries map/array; `XACK` → an integer count; `XAUTOCLAIM` → the `[cursor, claimed-entries, deleted-ids]`
  triple. *Check:* the `:valkey` proof appends with `XADD`, reads back the exact entry with `XRANGE`, creates a
  group + reads with `XREADGROUP` (no `BLOCK`), acks with `XACK`, and re-claims a pending entry with `XAUTOCLAIM` —
  each reply asserted against the appended data (a POSITIVE proof, no vacuous round-trip).
- **EMQ3.1-INV3 — the pipelined `XADD` batch returns replies in call order.** N `["XADD", key, "*", field, value]`
  command-lists through the shipped `Connector.pipeline/3` (`connector.ex:56-60`) return `{:ok, [id1, id2, …,
  idN]}` — N entry-ids, one per appended entry, in call order (the FIFO pairing, `connector.ex` moduledoc
  `:6-10`). No second pipelining mechanism — `exec/1` on an `EchoWire.Pipe` is literally one `pipeline/3` call
  (`pipe.ex:16-22`). *Check:* the proof appends N entries in one pipeline, asserts N ids returned in order, and
  reads them back with `XRANGE` confirming N entries in mint order (the server `*` ids are monotonic).
- **EMQ3.1-INV4 — push-safety: in-band stream verbs do not disturb the out-of-band push routing.** `XADD`/`XRANGE`/
  `XACK` are in-band request/reply (their replies arrive on the FIFO via `command/3`); they round-trip on a RESP3
  connection WITHOUT corrupting the `{:push, …}` routing the `EchoMQ.Events` pub/sub seam (`events.ex`) depends on
  (push frames `>` parse to `{:push, […]}` and route out of band, never into the reply FIFO — `resp.ex:60`, the
  moduledoc `resp.ex:13-15`). The non-blocking `XREADGROUP`/`XAUTOCLAIM` forms (NO `BLOCK`) return on the FIFO; the
  blocking form is DEFERRED (FORK 3.1-D — `XREADGROUP BLOCK` would hold the single-owner socket, so it lands at
  emq3.3 with the readers' blocking-read design). *Check:* the proof subscribes to a channel (the `Events` seam),
  appends + reads a stream in-band, and asserts BOTH the stream replies are correct AND a concurrent push is still
  delivered out of band (the FIFO stays aligned); no stream verb issued in the proof carries a `BLOCK` argument.
- **EMQ3.1-INV5 — the stream key is a braced §6 type on the `{q}` slot (FORK 3.1-B).** A stream key is
  `emq:{q}:stream:<name>` built by the shipped `Keyspace.queue_key(q, "stream:" <> name)` (`keyspace.ex:13-15`) —
  the braced grammar, the hash applied transparently, so the stream shares the `{q}` hashtag slot with that queue's
  `pending`/`active`/`job:` keys (a later script touching the stream alongside a queue set is slot-sound by the
  braces). NO grammar edit — `queue_key/2` is total over `<type>`; the §6 registry gains `stream:<name>` as a
  documentation act, not a code edit. The branded record id (`XADD key <branded-id>`) is emq3.2's law — emq3.1 may
  use the server `*` id to prove the key reaches the wire. *Check:* `Keyspace.queue_key(q, "stream:s")` returns
  `"emq:{" <> q <> "}:stream:s"` and `Keyspace.slot/1` of it equals the slot of `queue_key(q, "pending")` (same
  hashtag, same slot); the §6 grammar in `keyspace.ex` is unedited (`git diff keyspace.ex` empty); no new
  key-validation gate is added.
- **EMQ3.1-INV6 — additive registration is a protocol MINOR, the wire unbroken.** The stream verbs are additive
  registrations (the conformance set grows with the new scenario(s) + their probes in the same change); they break
  NO wire contract — the `@wire_version` boot fence (`connector.ex:35`, `echomq:2.4.2`) is byte-unchanged, the
  five-code fence union stands unextended, no `EMQKIND`/`EMQSTALE` class is added (a stream verb is not a job-kind
  refusal). The rung label may step a MINOR (FORK 3.1-C — opening the family resets the patch), but the WIRE is
  frozen. *Check:* `{emq}:version` reads `echomq:2.4.2`; a `git diff` of `connector.ex` shows no `@wire_version`
  change; the closed wire-class registry (`EMQKIND`/`EMQSTALE`) is byte-unchanged; the new conformance scenario(s)
  are registered WITH their probes in the same change.
- **EMQ3.1-INV7 — the additive-minor conformance law.** The stream-verb scenario(s) are registered in
  `scenarios/0` **with their probes in the same change**; the prior **73** scenarios pass **byte-unchanged** (name
  + contract + verdict-body identical, git-verified); the count re-pins **73 → the new total** in **both** pinning
  tests (`conformance_run_test.exs` `{:ok, <new>}` + `conformance_scenarios_test.exs` `@run_order`). The exact count
  delta is FORK 3.1-B's companion decision (one scenario for the verb floor, or a decomposition — see the forks).
  *Check:* the git-diff of `scenarios/0` shows only the addition(s); both count assertions updated; `Conformance.run/2`
  prints the new total of lines and returns `{:ok, <new>}` against the truth row (Valkey on 6390).
- **EMQ3.1-INV8 — the determinism posture is HONEST to a verb-plumbing rung (a multi-seed sweep, NOT the ≥100
  loop).** emq3.1's verb path mints NO branded id (the stream append uses the server `*` id, or — at emq3.2 — a
  caller-supplied branded id; emq3.1 mints none) and starts NO process (it is a host fn over the shipped
  connector). So the same-millisecond branded-id mint hazard the ≥100 loop owns is ABSENT — the honest posture is a
  **multi-seed sweep** + an explicit determinism statement, NOT the ≥100 loop. *Check:* the proof runs under a
  multi-seed sweep (several `--seed` values) green; the determinism posture is stated in the stories (the verb path
  mints no id and starts no process — the loop is not the proof here); IF the proof is later found to mint a
  branded id (it should not — that is emq3.2), the posture flips to the ≥100 loop (stated honestly, the escalation
  named).

## Closed error set (the typed surfaces emq3.1 may meet — grounded, no new wire class)

emq3.1 introduces **NO new `EMQ*` wire class** — it is verb plumbing over the shipped connector, not a new job
transition. The surfaces it may meet (each grounded against the as-built connector):

- **`{:error_reply, msg}`** — a server-side stream error (e.g. `XADD` to a key holding a non-stream type, or
  `XREADGROUP` against a missing group) arrives as a RESP error VALUE (`resp.ex:47`, `{:error_reply, msg}`), not a
  connector failure — the caller decides its severity (the shipped convention, `resp.ex:6-8`). emq3.1 surfaces the
  server's error verbatim; it adds no typed refusal here.
- **`{:error, :overloaded}`** — the connector's bounded in-flight depth (`max_pending`, `connector.ex` moduledoc
  `:20-22`) answers `:overloaded` rather than buffering without bound — the shipped backpressure, inherited
  unchanged by a pipelined `XADD` batch.
- **`{:error, :disconnected}` / `:closed`** — an in-flight stream command on a socket loss is failed
  `:disconnected` (never replayed — the connector cannot know what is idempotent, `connector.ex` moduledoc
  `:23-25`); a graceful shutdown answers `:closed`. The shipped socket-loss discipline, inherited unchanged.
- **An ill-formed queue name** — `Keyspace.queue_key/2` builds the braced key; an ill-formed queue raises at the
  key builder before any wire (the shipped keyspace gate, wellformedness only). The stream key type inherits this
  gate; emq3.1 adds no new refusal.

There is **NO new typed refusal** for a stream verb — the family is issued through the generic command path and the
server's reply (a value, an error value, or a connector transport error) is surfaced as-is. The branded record-id
refusal (a non-branded `XADD` id) is **emq3.2's writer-law door**, NOT this rung (emq3.1 proves the verb reaches
the wire; the writer law gates the id).

## The rung's forks — OPEN (the Operator's pre-build decisions; the recommended arm is the strawman)

> Four forks. Each is surfaced four-part — **Rationale** (what is at stake) · **5W** (the decision's shape) ·
> **Steelman** (the strongest case for the NON-recommended arm) · **Steward** (the recommendation + the trade-off).
> Venus surfaces; the Operator rules (the Director routes via `AskUserQuestion`). The body above is authored TO the
> recommended arm of each; a different ruling re-derives the affected sections at the post-build reconcile.

### FORK 3.1-A — the verb-landing mechanism — RECOMMEND: ride the existing generic command path (NORMAL)

- **Rationale.** This is THE fork — it decides the rung's risk tier. Either emq3.1 rides the as-built generic
  command path (ZERO `echo_wire` edit, NORMAL) or it extends the connector with stream-verb support (a frozen-line
  touch, HIGH). The reconcile answers the load-bearing question: **the as-built `EchoMQ.Connector` is ALREADY a
  generic RESP client.** `command/3` (`connector.ex:47-54`) takes `(conn, [parts], timeout)`; `RESP.encode/1`
  (`resp.ex:20-28`) encodes any `[verb | args]` list as a RESP array of bulk strings — verb-agnostic, no command
  whitelist (`bulk/1` handles binary/integer/atom/iodata). `XADD foo * field val` is just another `parts` list. The
  facade `EchoWire.command/3` (`echo_wire.ex:20`) and the ewr.1.2 escape hatch `EchoWire.Pipe.command/2`
  (`pipe.ex:496-497`, *"Any command not curated … is reachable through `command/2`"*) both expose the same generic
  path. The connector's own moduledoc names the posture: *"a purpose-built Valkey client … pipelining as the
  primitive"* (`connector.ex:2-10`).
- **5W.** *What:* whether emq3.1 issues the stream verbs through the shipped `command/3`/`pipeline/3` (no new
  surface) or adds connector code (new dispatch / a stream-verb API). *Who:* the connector (frozen-named by
  committed records — `EchoMQ.Connector`/`RESP`/`Script`, `echo_wire.ex:11-14`); every later Stream rung (which
  assumes the verb reach). *When:* the founding rung — the decision fixes the whole tier's wire posture. *Where:*
  `echo/apps/echo_mq` only (recommended arm) vs. `echo/apps/echo_wire/lib/echo_mq/connector.ex` (the frozen-touch
  arm). *Why:* the connector is the single owner of the wire — touching it is the master-invariant's most fenced
  act.
- **Steelman (the frozen-touch arm).** A dedicated stream-verb surface on the connector (e.g. typed `xadd/4` /
  `xrange/4` helpers) would give the later writer law (emq3.2) a typed seam to build on, rather than raw `parts`
  lists — arguably cleaner ergonomics, and a place to centralize stream-verb encoding quirks. **But** the reconcile
  shows the generic path already encodes every verb correctly (RESP is verb-agnostic), the typed ergonomics belong
  in emq3.2's `EchoMQ.Stream` module (ABOVE the connector, not IN it), and touching the frozen connector for
  ergonomics the generic path already delivers is the master-invariant's highest-cost edit for zero plumbing gain —
  it converts a NORMAL rung to HIGH (a frozen-line touch → Apollo-mandatory) with no capability the generic path
  lacks.
- **Steward — RECOMMEND: ride the existing generic command path (NORMAL).** The evidence is decisive: the connector
  is a generic RESP client by construction, the verbs round-trip through `command/3`/`pipeline/3` with no edit, and
  the typed surface (if ever wanted) is emq3.2's module-level concern ABOVE the wire. *Trade-off:* emq3.1 issues
  raw `parts` lists (no typed `xadd/4`) — accepted, because the typed ergonomics are emq3.2's `EchoMQ.Stream`
  surface, and keeping the connector frozen holds the rung at NORMAL with zero wire risk. **The risk tier is NORMAL
  on this arm; the frozen-touch arm is HIGH (Apollo-mandatory).**

### FORK 3.1-B — the stream keyspace + the conformance count delta — RECOMMEND: `emq:{q}:stream:<name>` as a new §6 type, +1 scenario

- **Rationale.** The stream needs a key, and the v2 keyspace is a closed braced registry (§6). The reconcile shows
  `Keyspace.queue_key/2` (`keyspace.ex:13-15`) is **total** over `<type>` — it builds `emq:{q}:<type>` for any
  string, the hash applied transparently. So `emq:{q}:stream:<name>` is a NEW §6 braced type that rides the shipped
  builder with NO grammar edit. The declared-keys consequence: a stream key shares the `{q}` hashtag slot, so a
  later script (emq3.2's writer, emq3.3's group reader) touching the stream alongside `emq:{q}:pending` is
  slot-sound by the braces (the A-1 law). The companion decision is the conformance count delta (one scenario for
  the verb floor, or a decomposition).
- **5W.** *What:* the stream key grammar (`emq:{q}:stream:<name>` as a new §6 type) + how many conformance
  scenarios the verb floor registers. *Who:* the §6 grammar (the closed braced registry); the conformance harness
  (73 → the new total). *When:* the founding rung — the key type the whole tier appends to. *Where:* the design §6
  (a documentation act — adding `stream:<name>` to the registry) + `conformance.ex` (the new scenario(s)). *Why:*
  the key type fixes the hashtag slot the tier's streams live on; the count delta is the additive-minor bookkeeping.
- **Steelman (an unbraced / alternative grammar, or a richer decomposition).** A non-braced stream key (e.g. a
  global `{emq}:stream:<name>` in the deployment reserve) would let a stream span queues rather than bind to one
  queue's slot — arguably right if streams are cross-queue by nature. And a richer conformance decomposition (a
  scenario per verb, +5) would gate each verb's round-trip independently. **But** the tier's design is *per-key
  hash-tagged streams* ([`../../emq.streams.md`](../../emq.streams.md) §The ladder, emq3.2 "per-key hash-tagged
  streams") — a stream binds to a queue's slot by design (the branded record id IS the stream position, minted in
  that queue's universe), so the braced `emq:{q}:stream:<name>` is the correct grammar; a cross-queue stream is a
  log-tier-exit concern (the seam, [`../../emq.streams.md`](../../emq.streams.md) §Seams), not the founding rung.
  And a per-verb decomposition (+5) over-counts the verb FLOOR — emq3.1 proves the family reaches the wire as one
  capability (the five verbs are one plumbing surface); the per-verb behavior (group lifecycle, retention) is gated
  at the rungs that BUILD those behaviors (emq3.3/3.4), not at the verb-reach floor.
- **Steward — RECOMMEND: `emq:{q}:stream:<name>` as a new §6 braced type (via the total `queue_key/2`, no grammar
  edit), +1 conformance scenario (`stream_verbs`).** The braced per-queue grammar matches the tier's per-key
  hash-tagged design and keeps the stream slot-sound with the queue's other keys; one scenario gates the verb floor
  as one capability (the five verbs round-trip + pipelined append + push-safe), with the per-behavior scenarios
  landing at the rungs that build them. *Trade-off:* a per-verb decomposition would gate each verb's round-trip
  separately — accepted against, because the verb FLOOR is one plumbing capability and over-decomposing the floor
  inflates the count without proving more than "the family reaches the wire." **The count steps 73 → 74 on this
  arm.** (If the Operator prefers the decomposition, the count steps 73 → 78 and the body's INV7 / the stories
  re-derive — surfaced.)

### FORK 3.1-C — the version label — RECOMMEND: a MINOR step `2.5.2` → `2.6.0` (open the family)

- **Rationale.** The position-encoded label convention (the implementor skill; the as-built precedent) resets the
  patch when a family opens: opening the emq.5 batches family stepped `echomq:2.4.4` → `2.5.0` (the changelog,
  `emq.5.1` row). emq3.1 opens the **Stream Tier** — a new milestone family — so by the same convention the rung
  label steps a MINOR `2.5.2` → `2.6.0` (the family-opening reset). The WIRE is unaffected either way (the
  `@wire_version` is frozen at `echomq:2.4.2`, the deferred cutover — FORK 3.1-A/INV6); this is the `mix.exs` rung
  LABEL plane only (read by nobody at runtime — the two-planes model, emq.4.3 D-4).
- **5W.** *What:* the `mix.exs` rung label — a MINOR step (`2.6.0`, open the family) or a patch step (`2.5.3`,
  within the 2.5.x line). *Who:* the `mix.exs` version field (the rung label, runtime-irrelevant); the changelog
  lineage. *When:* the founding rung of the Stream Tier. *Where:* `mix.exs:7` (the label) + the changelog row.
  *Why:* the label encodes the rung's place in the ladder; a family-opening is a MINOR by the convention.
- **Steelman (stay within 2.5.x — a patch step `2.5.3`).** The Stream Tier ships ADDITIVE-MINOR like every 2.x
  rung, and the `echomq:3.0.0` MAJOR is DEFERRED — so one could argue the label should stay in the 2.5.x line until
  the cutover, treating emq3.1 as just the next additive patch. **But** the convention is position-encoded — a
  family-OPENING resets the patch (emq.5.1's `2.5.0` is the precedent: it opened a family and reset the patch even
  though it too was additive-minor over a frozen wire). The Stream Tier is unambiguously a new milestone family (a
  new canon `emq.streams.md`, a new specs home `specs/emq3/`, six rungs), so the MINOR step `2.6.0` is the
  convention applied, not a new rule.
- **Steward — RECOMMEND: a MINOR step `2.5.2` → `2.6.0` (open the Stream Tier family).** The convention resets the
  patch on a family-opening, and emq3.1 unambiguously opens the Stream Tier (a new milestone family). *Trade-off:*
  the implementor skill says label-derivation is the Director's discretion when unambiguous — and this IS
  unambiguous (a family-opening) — but a tier-OPENING is a visible lineage marker, so it warrants an explicit
  Operator ruling rather than a silent default. **The label steps `2.6.0` on this arm; the `@wire_version` stays
  `echomq:2.4.2` (the deferred cutover) either way.**

### FORK 3.1-D — push-safety / blocking reads — RECOMMEND: non-blocking round-trips only, DEFER `XREADGROUP BLOCK` to emq3.3

- **Rationale.** `XREADGROUP` and `XAUTOCLAIM` can BLOCK (the `BLOCK <ms>` argument) or push on the single-owner
  socket. The connector is a single-owner socket with a FIFO pairing each in-flight command to its caller
  (`connector.ex` moduledoc `:6-10`); a `BLOCK` command would HOLD that socket for the block duration, stalling
  every other caller behind it (or forcing the out-of-band `push_command/3` path — the SUBSCRIBE-family precedent,
  `connector.ex:99-102`). The honest bound: emq3.1 scopes the verbs to NON-blocking round-trips (no `BLOCK`
  argument — `XREADGROUP`/`XAUTOCLAIM` return immediately on the FIFO), and DEFERS the blocking consumer-group read
  to emq3.3 (the readers), where the blocking-read posture is designed against the single-owner socket (e.g. a
  dedicated connection, or the `push_command/3` out-of-band path, or the emq.4.3 metronome's single-`BLPOP`-owner
  pattern as the precedent).
- **5W.** *What:* whether emq3.1 handles the BLOCKING `XREADGROUP BLOCK` form now, or scopes to non-blocking
  round-trips and defers blocking to emq3.3. *Who:* the single-owner connector socket (the FIFO); the readers
  (emq3.3, which owns the consumer-group lifecycle). *When:* the founding verb-floor rung. *Where:* the `:valkey`
  proof (which verb forms it exercises) + the emq3.3 readers' design (where blocking lands). *Why:* a `BLOCK`
  command on the single-owner socket stalls every caller behind it — a real posture decision, not a default.
- **Steelman (handle blocking now).** A blocking `XREADGROUP BLOCK` is the natural consumer-group read (a consumer
  waits for new entries rather than polling), so handling it at the verb floor would land the whole verb family
  complete in one rung. **But** the blocking read is meaningless without the consumer-group LIFECYCLE (group
  creation, member tracking, crash re-delivery) — which is emq3.3 by the tier ladder; and the single-owner socket
  makes a naive `BLOCK` a wire hazard (it stalls every other caller). The blocking-read posture is a DESIGN problem
  (a dedicated connection vs. the out-of-band path vs. the metronome precedent), and designing it at the verb floor
  — before the reader lifecycle that gives it meaning — couples emq3.1 to emq3.3 and risks a wire hazard in the
  founding rung.
- **Steward — RECOMMEND: non-blocking round-trips only; DEFER `XREADGROUP BLOCK` to emq3.3.** The verb floor proves
  the family REACHES the wire (the non-blocking forms round-trip on the FIFO, push-safe); the blocking read is a
  reader-lifecycle concern with a real single-owner-socket design, so it lands at emq3.3 where the consumer group
  gives it meaning and the blocking-read posture is designed. *Trade-off:* emq3.1's `XREADGROUP`/`XAUTOCLAIM`
  proofs use the non-blocking form (no `BLOCK`) — accepted, because the blocking read without the group lifecycle is
  premature, and the single-owner-socket design is emq3.3's to make. **This is the honest bound: emq3.1 is the
  verb reach (non-blocking), emq3.3 is the readers (blocking + the group lifecycle).**

> **No new key family beyond the named §6 stream type any fork** (FORK 3.1-B's `emq:{q}:stream:<name>` rides the
> total `queue_key/2` — no grammar edit); no fork adds a new script (emq3.1 is verb plumbing — the verbs are issued
> direct, not via Lua, INV1); no fork touches the wire `@wire_version` (frozen at `echomq:2.4.2` — the deferred
> cutover, INV6). The ONLY fork that changes the risk tier is FORK 3.1-A (the recommended arm is NORMAL; the
> frozen-touch arm is HIGH, Apollo-mandatory).

## Definition of Done

- [ ] **FORK 3.1-A** (the verb-landing mechanism), **FORK 3.1-B** (the stream keyspace + the count delta), **FORK
      3.1-C** (the version label), and **FORK 3.1-D** (the push-safety / blocking-read boundary) surfaced four-part
      with the recommended arm + the steelman + the trade-off; the Operator ruled each (the Director routes via
      `AskUserQuestion`); the body re-derived to the rulings at the post-build reconcile (Stage-5).
- [ ] **The five stream verbs reachable + proven** (`XADD` · `XRANGE` · `XREADGROUP` · `XACK` · `XAUTOCLAIM`) on
      the shipped generic command path (the ruled FORK 3.1-A arm) — each round-trips end-to-end on Valkey 6390, its
      reply parsed and asserted against the appended data (a POSITIVE proof, no vacuous round-trip).
- [ ] **A pipelined `XADD` batch** through the shipped `Connector.pipeline/3` / `EchoWire.Pipe.command/2` — N
      entries appended in one pipeline, N entry-ids returned in call order, read back with `XRANGE` in mint order.
- [ ] **Push-safety under RESP3** proven — in-band `XADD`/`XRANGE`/`XACK` round-trip without disturbing the
      out-of-band push routing (the `EchoMQ.Events` seam); no proof verb carries a `BLOCK` argument (the blocking
      `XREADGROUP BLOCK` form DEFERRED to emq3.3, the ruled FORK 3.1-D).
- [ ] **The `emq:{q}:stream:<name>` §6 key type** (the ruled FORK 3.1-B arm) built via the total `queue_key/2` —
      the stream shares the `{q}` hashtag slot (slot-sound with the queue's keys); the §6 grammar in `keyspace.ex`
      unedited (`git diff` empty).
- [ ] **The conformance scenario(s)** registered (additive minor — the prior **73** byte-unchanged; the count
      re-pinned **73 → the ruled total** in both pinning tests, FORK 3.1-B's companion decision). A present
      precondition (a live stream) runs the verb round-trips with a positive proof; a vacuous pass is a LOUD failure.
- [ ] The proof: the `:valkey` stream-verb suite green per-app; a **multi-seed sweep** green (a verb-plumbing rung
      mints no id and starts no process in the verb path — NOT the ≥100 loop, the honest posture); the `echo_wire`
      `git diff` EMPTY (the recommended FORK 3.1-A arm — the connector untouched); `{emq}:version` =
      `echomq:2.4.2`; honest-row reporting (Valkey on 6390).
- [ ] INV1–INV8 verified as runnable checks; the tier contract ([`../../emq.streams.md`](../../emq.streams.md))
      remains the carve authority; this body is authoritative (synced to the as-built post-build, Stage-5).
      **Apollo** is an optional fast-finisher on the recommended FORK 3.1-A arm (verb plumbing, no shipped-script
      edit), MANDATORY iff FORK 3.1-A is ruled the frozen-touch arm.

Tier: [`../../emq.streams.md`](../../emq.streams.md) (the Stream Tier contract, the ladder, the seams — the carve
authority) · Rung stories + brief: [`emq3.1.stories.md`](emq3.1.stories.md) · [`emq3.1.llms.md`](emq3.1.llms.md) ·
Runbook: [`emq3.1.prompt.md`](emq3.1.prompt.md) · The generic command path it rides (SHIPPED): `echo/apps/echo_wire/lib/echo_mq/connector.ex`
— `command/3` (`:47-54`) + `pipeline/3` (`:56-60`) + `push_command/3` (`:99-102`) · the verb-agnostic codec
`echo/apps/echo_wire/lib/echo_mq/resp.ex` — `encode/1` (`:20-28`) + `parse/1` (`:45-87`) · the facade + escape
hatch `echo/apps/echo_wire/lib/echo_wire.ex` (`:20-25`) + `echo/apps/echo_wire/lib/echo_wire/pipe.ex` `command/2`
(`:496-497`) · the braced grammar `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — `queue_key/2` (`:13-15`) · the
ephemeral pub/sub seam the rung does not disturb `echo/apps/echo_mq/lib/echo_mq/events.ex` · The v2 laws: §6 (the
braced keyspace) · S-6 (the declared-keys A-1 law) · S-3/§5 (the additive-minor / additive-registration-is-a-minor
law) · The design canon: [`../../emq.design.md`](../../emq.design.md) (§6 grammar · §10 seams · §12 engine-feature
ADRs) · Roadmap: [`../../emq.roadmap.md`](../../emq.roadmap.md) (the EchoMQ 3.0 row · the Stream Tier) · Approach:
[`../../../elixir/specs/specs.approach.md`](../../../elixir/specs/specs.approach.md)
