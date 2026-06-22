# EMQ3.2 · S1 the writer (part 2) — THE WRITER LAW: `EchoMQ.Stream`, branded record ids, append == mint order (EchoMQ 3.0, the Stream Tier)

> **Status: ✅ BUILT + SHIPPED (2026-06-22) — conf 74→75, label `echomq:2.6.1`, `echo_wire` UNTOUCHED, the ≥100 determinism loop 100/100; BUILD-GRADE, zero defects (see [`../progress/emq3-2.progress.md`](../progress/emq3-2.progress.md) Y-1/Z-1).** The dual-architect design phase is closed; the Operator
> ruled the forks (the consensus below, D-1..D-4 + ADR-3/ADR-4). This body is forward-tense ("emq3.2 builds…")
> for everything the rung adds; surfaces that already ship are cited present-tense against the re-probed
> `echo_wire`/`echo_mq` tree (the lag-1 law). The **SECOND rung of EchoMQ 3.0 — the Stream Tier**
> ([`../../emq.streams.md`](../../emq.streams.md)), the WRITER LAW above the verb floor: emq3.1 (SHIPPED
> `7b44dc97`, conf **74**, label `echomq:2.6.0`) made the five stream verbs round-trip on the certified
> connector; emq3.2 builds the **`EchoMQ.Stream` writer** — per-key hash-tagged streams, branded record ids
> appended in mint order, wrong-kind refused at the door. The readers (consumer groups, `XREADGROUP`/`XACK`/
> `XAUTOCLAIM`) are **emq3.3, NOT this rung** — emq3.2 is the writer surface + the minimal un-grouped read-back
> that GATES the order theorem.
>
> **The forks, RULED (the design phase's consensus — the body is authored to these).** **D-1 · the id mapping
> = A1** (`xadd_id = "#{Snowflake.unix_ms(snow)}-#{snow &&& 0x3FFFFF}"` — the real Unix-ms via `unix_ms`, the
> 22-bit `node|seq` tail as the seq; the 14-byte branded string stored as the `id` field; the order theorem holds
> by construction, single-writer every time, multi-writer answers `{:error, :nonmonotonic}` on XADD's `id≤top`
> rejection). **D-2 · the kind door = host-side RAISE, brand `EVT`** (one brand per stream, refused host-side by a
> raise before any wire — symmetric with `Keyspace.job_key/2`; no new script, the `EMQKIND`/`EMQSTALE` registry
> unextended). **D-3 · conformance = +1 `stream_append`, 74→75** (mint + the kind door + the append-order theorem
> as one verb-floor capability; the deep proof rides the property test + the ≥100 loop). **D-4 · label
> `echomq:2.6.1`** (a within-family patch; `@wire_version` FROZEN `echomq:2.4.2`); **risk NORMAL+** (a mint
> surface). **ADR-3 · the key** = `emq:{q}:stream:<name>` via the shipped total `Keyspace.queue_key/2` — no
> grammar edit, declared-keys vacuous (no new Lua). **ADR-4 · the surface** = a thin `EchoMQ.Stream` router over a
> **pure `EchoMQ.Stream.Id`** core (the A1 mapping; doctested + property-tested — the order theorem IS its
> property).
>
> **Risk: NORMAL+ (a MINT surface).** emq3.2 MINTS branded record ids (the append's whole point) — so unlike
> emq3.1 (which minted nothing → a multi-seed sweep), emq3.2's determinism posture is the **≥100 determinism
> loop, MANDATORY** (the same-millisecond branded-id mint hazard). But it touches **no frozen line** (ZERO
> `echo_wire` edit — rides the shipped connector, inheriting emq3.1's FORK-3.1-A ground), adds **no new script**
> (the append is `XADD` issued direct, not via Lua — byte-freeze trivially held), performs **no destructive
> at-rest op** (append-only; retention is emq3.4), and adds **no new wire class** (the kind door is a host raise,
> the closed registry stands). The gate is the **order-theorem property test + the ≥100 loop**, not the
> blast-radius mutation battery (no destructive op) and not the frozen-touch HIGH (no frozen line). **Apollo is an
> OPTIONAL fast-finisher** (closure + stories) — NOT mandatory: emq3.2 is not a new process/lease surface (no
> process — a host fn over the connector; no lease — no `TIME`, no fencing token), not a destructive at-rest op,
> not a frozen-line touch. *(The Operator MAY upgrade Apollo to mandatory given ADR-1's correctness is the rung's
> whole risk — a reasonable call, surfaced.)*

## 0 · The slice — what emq3.2 builds, and why the writer law after the verb floor

The tier ([`../../emq.streams.md`](../../emq.streams.md)) ships **event streams on the certified wire under the v2
laws, no second protocol**. Its three milestones are **S1 the writer** (emq3.1–3.2) → **S2 the readers**
(emq3.3–3.4) → **S3 the memory** (emq3.5–3.6). emq3.2 is the SECOND rung of S1: the **writer LAW** above the verb
floor.

emq3.1 proved the **plumbing** — the five stream verbs (`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`) reach the
certified connector as raw `parts` lists, round-trip on Valkey 6390, pipeline in call order, push-safe under RESP3
(`stream_verbs_test.exs`). emq3.1 appended with the **server-minted `*` id** (sufficient to prove the plumbing) and
minted NO branded id (`emq3.1.md:19-22`). emq3.2 builds the **writer surface on top**: the `EchoMQ.Stream` module
(which does NOT yet exist — re-probed, `find stream*.ex` empty; `events.ex:35-36` names it forward as its
successor in committed code: *"the durable replayable receipt is emq3.2's `EchoMQ.Stream`, not this"*).

The split is the tier ladder (`emq.streams.md` §The ladder): emq3.1 = the verbs reach the wire; emq3.2 = the
**writer law** — `EchoMQ.Stream` (per-key hash-tagged streams, branded record ids, append == mint order). Keeping
the writer in its own rung lands the order theorem cleanly: emq3.1's floor proved the verbs round-trip, so emq3.2
builds the id discipline on a proven verb reach and the readers (emq3.3) build the consumer-group lifecycle on a
proven writer.

**The crux — the carry-fact (`emq.streams.md:57`) reasoned to the ground.** The tier's economy ASSERTS *"the
branded id IS the stream position — append == mint order, the order theorem extended to the log, no second
index."* emq3.2 PROVES it: the **order theorem requires three orders to coincide, every time** — branded-string
byte order ≡ snowflake-integer order ≡ XADD-entry-id order. The proof and the ruled mapping (D-1, A1) are §1.

What emq3.2 stands on (all SHIPPED, present-tense — cited by re-probe, the lag-1 law):

- `EchoMQ.Connector.command/3` (`echo_wire/.../connector.ex:47-54`) + `pipeline/3` (`:56-60`) — the generic command
  path the writer's `XADD` rides (emq3.1 INV1/INV3 proved it verb-agnostic, ZERO `echo_wire` edit).
- `EchoMQ.RESP.parse/1` (`echo_wire/.../resp.ex:45-87`) — the one-pass decoder; an `XRANGE` reply is a nested array
  of `[id, [field, value, …]]` (the shape `stream_verbs_test.exs:83` already asserts).
- `EchoMQ.Keyspace.queue_key/2` (`keyspace.ex:14-15`) — `emq:{q}:<type>` for any `<type>`, the hash applied
  transparently; `EchoMQ.Keyspace.job_key/2` (`keyspace.ex:18-24`) — the only as-built id-shape gate, which
  **raises** before any wire (the ADR-2 kind-door precedent); `slot/1`+`hashtag/1` (`:44-54`).
- `EchoData.Snowflake.unix_ms/1` (`snowflake.ex:107`) = `(snowflake >>> 22) + @epoch_ms` (`@epoch_ms =
  1_704_067_200_000`, `:32`) — the real Unix-ms of the mint, the A1 ms field; `Snowflake.next/0`+`next/1`
  (`:63`/`:74`) — the lock-free mint over the shared `:atomics` cell (strictly monotone ts+seq, the order-theorem
  guarantee); `Snowflake.min_for/1` (`:116`) — the mint-instant→bound seed (emq3.6).
- `EchoData.BrandedId.decode/1` (`branded_id.ex:55-57`) → `{:ok, snow}`; `valid?/1` (`:95`); `namespace/1`
  (`:97`); `encode!/2` (`:85`); `is_branded/1` (`:23`, the 14-byte guard). `EchoData.Base62` —
  **order-preserving** fixed-width-11 (`base62.ex:5`: *"Lexicographic order equals numeric order"*; alphabet
  `0-9A-Za-z`, ascending bytes) — the proof that branded byte order == snowflake int order WITHIN one namespace.
- `EchoMQ.Conformance` (`conformance.ex` — `scenarios/0` + `run/2`) — the additive-minor harness, **74** scenarios
  live (`conformance_run_test.exs:61` `{:ok, 74}`; `conformance_scenarios_test.exs:38` `@run_order`).
- `EchoMQ.Events` (`events.ex`) — the ephemeral pub/sub seam the writer does not disturb (`channel/1` → `:106`;
  the `{:emq_push, …}` frame → `:205`); the precedent emq3.2 inherits but does not touch.

## Goal

emq3.2 builds, inside `echo/apps/echo_mq` (riding the shipped `echo_wire` connector — ZERO `echo_wire` edit), the
**writer LAW** of the Stream Tier:

1. **The pure `EchoMQ.Stream.Id` core — the A1 id mapping (D-1).** A pure, doctested, property-tested module
   carrying the branded-record-id ↔ XADD-entry-id correspondence: `xadd_id/1` decodes a branded id and returns
   `"#{Snowflake.unix_ms(snow)}-#{snow &&& 0x3FFFFF}"` (the real Unix-ms field + the 22-bit `node|seq` tail as the
   seq field). **The order theorem (stream order == id sort == mint order) IS this module's property** — proven by
   doctests + a property test over many mint sequences (including forced same-ms). The core is exhaustive + total
   over its input; no process, no IO (the architect-skill verdict-surface law — the order math is the un-spoofable
   pure core, the precedents `BatchShaper.Core`/`BatchFinish.partition`).
2. **The `EchoMQ.Stream` writer — a thin router over the pure core + the connector (D-1, D-2, ADR-4).**
   `append/4` refuses wrong-kind host-side (a RAISE, D-2), derives the XADD id from `Stream.Id`, and issues `XADD
   <key> <id> id <branded> <fields…>` through the shipped `Connector.command/3` (the 14-byte branded string stored
   as the `id` field — the claims-only contract, so a polyglot reader gets the canonical id without re-encoding).
   The append returns the branded id as the receipt; XADD's `id≤top` rejection maps to `{:error, :nonmonotonic}`
   (the F-A liveness check, **never swallowed**).
3. **The kind door — wrong-kind refused at the writer's FIRST act, host-side (D-2).** One brand per stream (`EVT`);
   a non-`EVT` or malformed record id **raises before any wire** (symmetric with `Keyspace.job_key/2`'s
   wellformedness raise) — *policy before existence before write*, in the host where the JOB law honors it in the
   script. One brand per stream is REQUIRED: it keeps the byte-order ≡ snowflake-order step of the theorem sound
   (base62 byte order == int order only within ONE namespace prefix). **No new wire class** — the stream has no
   script to issue `EMQKIND`, so the closed registry stays `{EMQKIND, EMQSTALE}`.
4. **The minimal read-back — the order-theorem proof surface (ADR-4).** `read/3..6` wraps `XRANGE` and parses the
   reply into `{branded_id, fields}` tuples **in mint order** (the branded id recovered from the stored `id`
   field). This is NOT the consumer group (emq3.3) — it is the un-grouped range read that GATES "stream order ==
   id sort" by reading appended records back and asserting their order equals their mint order. Optional:
   `append_batch/4` (the pipelined writer riding the emq3.1-certified `pipeline/3`).
5. **The `emq:{q}:stream:<name>` key (ADR-3).** The writer addresses the stream via the shipped total
   `Keyspace.queue_key(queue, "stream:" <> name)` — the §6 braced type emq3.1 founded (no grammar edit; `git diff
   keyspace.ex` empty). The stream shares the `{q}` hashtag slot with that queue's keys. emq3.2 adds NO new Lua →
   declared-keys (S-6) is VACUOUS this rung; the slot-soundness lemma (a later multi-key script touching the
   stream alongside a queue set is A-1-sound by the braces) is recorded for the script rungs (emq3.3/3.5).
6. **The conformance scenario (D-3).** `+1 stream_append` (the writer law: mint + the kind door + the append-order
   theorem as one capability) — the prior **74** byte-unchanged → **75**, probe-registered, both pinning tests
   re-pinned (`conformance_run_test.exs:61` `{:ok, 74}` → `{:ok, 75}` + `conformance_scenarios_test.exs:38`
   `@run_order`). The DEEP order proof rides the property test + the ≥100 loop, not extra example scenarios.

All under the v2 master invariant: braced `emq:{q}:` keyspace · branded ids gated at the key builder (the stream
record id is gated host-side at the writer's door — wellformedness AND kind, D-2) · every Lua key in `KEYS[]` or
derived from a declared `KEYS[n]` root (emq3.2 adds NO new script — declared-keys vacuous) · the server clock where
leases are touched (no lease — the writer carries no `emq:{q}:` lease, no `TIME`) · inline `Script.new/2` (never
`priv/`; emq3.2 adds no script) · additive-minor conformance growth (74→75) · additive registration is a protocol
MINOR, no wire break (`@wire_version` FROZEN `echomq:2.4.2`).

## 1 · The order theorem — append == mint order, reasoned to the ground (D-1, the rung's crux)

The carry-fact (`emq.streams.md:57`) is an ASSERTION until the **branded-record-id ↔ XADD-entry-id mapping** is
reasoned rigorously. It is the entire risk of the rung, because the two id systems have **different shapes and
different native sort orders**:

| | The branded record id | The XADD entry id |
|---|---|---|
| Shape | 14 bytes: `3×[A-Z]` namespace ++ 11-char base62 payload (`branded_id.ex:3-4`) | `<ms>-<seq>`, two **64-bit** numbers (valkey.io/commands/xadd: *"Both quantities are 64-bit numbers"*) |
| Underlying value | a 63-bit snowflake `ts(41)<<<22 \| node(10)<<<12 \| seq(12)` (`snowflake.ex:3`, epoch 2024-01-01) | a `(ms, seq)` pair the stream stores in increasing order |
| Sort order | byte order of the 14-byte string | `(ms, seq)` lexicographic on the pair |
| Mint authority | host-side, coordination-free — *mint on any node, no registry* (the BCS law) | server-side under `*`; or caller-supplied explicit `<ms>-<seq>` |

The order theorem requires **THREE orders to coincide, every time**: branded-string byte order ≡ snowflake integer
order ≡ XADD entry-id order.

### 1.1 · The ruled mapping (D-1, A1): field correspondence

emq3.2 appends with an **EXPLICIT XADD id derived from the branded record id by field correspondence**:

```
{:ok, snow} = EchoData.BrandedId.decode(branded_id)      # the 63-bit snowflake
xadd_id     = "#{EchoData.Snowflake.unix_ms(snow)}-#{snow &&& 0x3FFFFF}"
#              └─ the REAL Unix-ms = (snow>>>22)+@epoch_ms ─┘ └─ the 22-bit node|seq tail ─┘
```

- the **ms field** is `Snowflake.unix_ms(snow)` (`snowflake.ex:107`) — the **real Unix-ms** of the mint, NOT the
  raw epoch-relative `ts` field. This is load-bearing for emq3.6: a reader maps a wall-clock `DateTime` to a stream
  bound via `DateTime.to_unix(dt, :millisecond)`, which only lands on the right entries if the XADD ms field is
  true Unix-ms (`Snowflake.min_for/1`, `snowflake.ex:116`, computes exactly this bound).
- the **seq field** is `snow &&& 0x3FFFFF` — the full 22-bit `node<<<12 | seq` tail (node in bits 12–21, seq in
  bits 0–11). Carrying the **node** into the seq is what keeps the coordination-free "mint on any node" law
  collision-free on the wire (§1.3).
- the **14-byte branded string** is stored as the stream **`id` field** (`XADD <key> <id> id <branded> <fields…>`)
  — the claims-only contract (`emq.streams.md:42`), so a polyglot reader gets the canonical id without re-encoding.

### 1.2 · The proof (two stacked facts — the theorem holds BY CONSTRUCTION)

The theorem needs `byte(branded_a) < byte(branded_b)  ⇔  xadd_id(a) < xadd_id(b)`, for every pair.

1. **Branded byte order == snowflake integer order.** The branded id is `ns ++ base62₁₁(snowflake)`. Base62 here
   is the order-preserving fixed-width-11 codec — *"Lexicographic order equals numeric order"* (`base62.ex:5`),
   alphabet `0-9A-Za-z` whose bytes are themselves ascending (`0`(0x30) < `9` < `A`(0x41) < `Z` < `a`(0x61) < `z`).
   So for a **fixed namespace** (D-2: one brand per stream — every record shares `EVT`), byte order of the 14-byte
   string == numeric order of the snowflake. *(Cross-namespace ordering is NOT required and NOT sound — D-2's kind
   door refuses a foreign brand precisely so step 1 holds; §1.4.)*

2. **A1's XADD id is an order-preserving image of the snowflake integer.** Write `s = ms_part<<<22 | tail22` where
   `ms_part = s >>> 22` and `tail22 = s &&& 0x3FFFFF`. A1 emits the pair `(M, T) = (ms_part + epoch_in_ms, tail22)`.
   Because the snowflake packs the timestamp in the HIGH bits and the tail in the LOW 22 bits **with no overlap**,
   `s_a < s_b  ⇔  (ms_part_a, tail22_a) < (ms_part_b, tail22_b)` lexicographically — which is exactly the pair XADD
   compares (XADD orders by `(ms, seq)`, and A1's seq IS `tail22`). The `+@epoch_ms` is a constant monotone shift
   on the first component, order-preserving. **∴ `s_a < s_b ⇔ xadd_id(a) < xadd_id(b)`. QED.**

The Director verified this order-preserving on disk (`base62.ex:3` lexicographic==numeric; `snowflake.ex:3/107`
the layout + `unix_ms`). It holds **by construction**, not by example.

### 1.3 · Single-writer holds every time; multi-writer surfaces the truth (D-1, the F-A liveness check)

- **Single-writer-per-stream** (the ruled posture; the multi-writer-per-stream case is the parked log-tier-exit
  seam, `emq.streams.md` §Seams): a stream's records are minted by one writer over the shared lock-free
  `:atomics` cell (`Snowflake.next/0`/`next/1`, `snowflake.ex:63/74`; the `advance/2` CAS, `:91-99`). The cell is
  **strictly monotone** in ts+seq (each mint takes `max(now, last+1)`, `:93`), so successive mints are strictly
  increasing snowflakes → strictly increasing A1 ids → **the order theorem holds EVERY TIME, no XADD rejection
  possible** (the next id always exceeds the stream top).
- **Multi-writer** (two writers minting into one stream — the parked seam, or a misconfiguration): two snowflakes
  can interleave such that a later XADD carries an id ≤ the stream's current top (the second writer's mint raced
  behind the first's append). XADD then **rejects** it: `ERR The ID specified in XADD is equal or smaller than the
  target stream top item` (verbatim, valkey.io/topics/streams-intro). emq3.2 surfaces this as **`{:error,
  :nonmonotonic}`**, **NEVER swallowed** — it is the wire telling the truth that an upstream mint-order violation
  happened (the F-A liveness check). A writer that silently retried (e.g. with `*`) would paper over a broken
  theorem; surfacing it is the design's honesty.

### 1.4 · The named failure modes (each → an INV or a closed-error surface)

- **F-A · `id ≤ stream top` rejection** → `{:error, :nonmonotonic}` (§1.3; INV3). The load-bearing liveness check.
- **F-B · same-ms seq exhaustion within a writer.** The snowflake seq is 12-bit (4096/ms). Beyond 4096 same-ms
  mints the generator's carry borrows into the timestamp (`snowflake.ex:11-13`), so the snowflake (and thus
  `unix_ms`) advances a few ms ahead — A1 stays monotone (the ms component increments), no XADD collision. **The
  substrate already preserves strict monotonicity; no special handling.** (Documented so a reviewer does not
  re-derive it.)
- **F-C · tail22 width vs the 64-bit XADD seq.** `tail22 ≤ 0x3FFFFF` (≈ 4.19M) ≪ the XADD seq ceiling
  `18446744073709551615` (valkey.io: 64-bit). **No overflow, ~42 bits of headroom.**
- **F-D · clock skew across nodes.** Two nodes with skewed clocks can mint ids whose ms ordering disagrees with
  true wall-time. This is a property of the BRANDED ID, not of A1 — A1 maps faithfully whatever the snowflake
  says. The theorem is "stream order == MINT order" (the snowflake's own order), **not** "== global wall-time
  order" (the latter is not claimed, and cannot be — coordination-free). Stated honestly; no new exposure.
- **F-E · cross-namespace appends to one stream** → closed by D-2's kind door (INV2). Two namespaces (`EVT…` and
  `ORD…`) would compare the namespace bytes FIRST, breaking step 1 of the proof. One brand per stream keeps it
  sound by construction. **ADR-1 and ADR-2 are JOINED: the kind door is what makes the theorem hold.**

### 1.5 · Why not the alternatives (the design-phase record, for the reconcile)

The dual-architect phase reasoned three rejected mappings (the live probe `order_probe.exs` is the evidence; the
Operator ruled A1):
- **`ms-seq12`** (the 12-bit seq only, node dropped): two writers minting in the same ms with the same seq produce
  the SAME XADD id → the 2nd append rejected. A1 keeps them distinct by the node field. RULED OUT.
- **`<whole-snowflake>-0`** (the snowflake int in the ms field): monotone but the ms field is no longer a real
  Unix-ms → emq3.6's wall-clock `XRANGE` breaks. RULED OUT.
- **server `*` + branded-id-as-a-field**: the server orders by ITS clock + arrival, not mint order → forfeits the
  theorem, forces a second index, breaks emq3.6. Forfeits the tier's entire thesis (*"the sequence is already
  minted … one value, no second index"*, `emq.streams.md:44`). RULED OUT.

## Rationale (5W)

- **Why** — the order theorem (`emq.streams.md:57`) is the tier's reason to exist HERE rather than on a generic
  broker: *"two committed mechanics make this tier cheaper here than anywhere else — the sequence is already
  minted … stream position, sort key, claim, and cache key stay one value"* (`emq.streams.md:44-48`). emq3.2 is
  where that economy is PROVEN: the branded id maps to an explicit XADD id (D-1, A1) so stream order == id sort ==
  mint order, no second index, and emq3.6's time-travel is free (the ms field is the real Unix-ms). The writer law
  is the founding id contract every later Stream rung (the readers emq3.3, retention emq3.4, the archive emq3.5,
  time-travel emq3.6) builds on.
- **What** — emq3.2 builds: (1) the pure `EchoMQ.Stream.Id` core (the A1 mapping; doctested + property-tested —
  the order theorem IS its property); (2) the `EchoMQ.Stream` writer (`append/4` host-raises wrong-kind, derives
  the XADD id, issues `XADD <key> <id> id <branded> <fields>`, returns the branded receipt, maps `id≤top` to
  `{:error, :nonmonotonic}`); (3) the kind door (one brand `EVT`, host raise, no new wire class); (4) the minimal
  un-grouped `read/3..6` read-back (the order-theorem proof surface) + optional `append_batch/4`; (5) the
  `emq:{q}:stream:<name>` key via the shipped `queue_key/2` (no grammar edit); (6) the `+1 stream_append`
  conformance scenario (74→75).
- **Who** — the program (the rung that founds the writer law of the Stream Tier); **event-stream consumers** (the
  game-dev recorded-event-stream demand the tier carries, `emq.streams.md` §The needs); the conformance harness
  (74→75); every polyglot reader (the branded id in the `id` field is the canonical id they sort/range by). The
  shipped `EchoMQ.Events` pub/sub seam (`events.ex`) is the precedent the rung does NOT disturb. **Apollo** — an
  OPTIONAL fast-finisher on the ruled NORMAL+ arm (a mint surface, no process/lease/destructive/frozen trigger);
  the Operator MAY upgrade Apollo to mandatory given ADR-1's stakes.
- **When** — EchoMQ 3.0, the Stream Tier, the SECOND rung (the writer law of S1; the readers emq3.3 build on the
  proven writer). The forks are RULED (the design-phase consensus, D-1..D-4 + ADR-3/ADR-4) — the body is authored
  to them.
- **Where** — `echo/apps/echo_mq` only: `lib/echo_mq/stream.ex` (NEW — the writer) + `lib/echo_mq/stream/id.ex`
  (NEW — the pure id core), `lib/echo_mq/conformance.ex` (the `stream_append` scenario + the count re-pin), the
  `:valkey` proof (`test/stream_test.exs` NEW — the writer round-trip + the order-theorem read-back + the kind
  raise + the `:nonmonotonic` liveness), the pure-core proof (`test/stream_id_test.exs` NEW — doctests + the
  order-theorem property test), the two pinning tests (`conformance_run_test.exs` `{:ok, 75}` +
  `conformance_scenarios_test.exs` `@run_order`), `mix.exs` (the label `2.6.0` → `2.6.1`). **`echo_wire` is
  UNTOUCHED** (the writer rides the shipped connector `command/3`/`pipeline/3`; `@wire_version` stays
  `echomq:2.4.2`). The §6 grammar in `keyspace.ex` is **unedited** (the stream key rides the total `queue_key/2`).
  `apps/echomq` is **untouched** (the capability reference). **The dependency note (a reconcile finding, §Scope):
  a StreamData property test would need a one-line `mix.exs` dep add (`stream_data` is NOT in echo_mq's `deps/0`)
  — the body specs the order-theorem property as a deterministic ExUnit enumeration to avoid the dep edge, with
  the StreamData arm named.**

## Scope

- **In** — the writer law: (1) the pure `EchoMQ.Stream.Id` core (the A1 mapping, doctested + property-tested);
  (2) the `EchoMQ.Stream` writer (`append/4` + the host-raise kind door + the `:nonmonotonic` liveness mapping +
  the branded receipt); (3) the minimal un-grouped `read/3..6` read-back (the order-theorem proof surface);
  (4) optional `append_batch/4` (the pipelined writer, riding the emq3.1-certified `pipeline/3`); (5) the
  `emq:{q}:stream:<name>` key via the shipped total `queue_key/2` (no grammar edit); (6) the `+1 stream_append`
  conformance scenario (74→75) + the `:valkey` proof + the order-theorem property test + the **≥100 determinism
  loop** (MANDATORY — the rung mints branded ids).
- **Out** — **consumer groups + the polyglot seam** (a BEAM consumer + a non-BEAM reader on one group,
  at-least-once, crash → `XAUTOCLAIM` re-delivery, `XREADGROUP`/`XACK`/`XAUTOCLAIM` wrappers — emq3.3; emq3.2's
  `read/_` is the un-grouped range read, NOT a group consumer); **retention as policy** (`MAXLEN`/`MINID` windows
  — emq3.4; `append/_` does not trim); **windowed time-travel** (the mint-instant→`XRANGE`-bounds read — emq3.6;
  emq3.2 MAY land `min_id_for` as the seed since `Snowflake.min_for/1` is free, but defers the windowed read);
  **multi-writer-per-stream** (the parked log-tier-exit seam, `emq.streams.md` §Seams — emq3.2's posture is
  single-writer; multi-writer surfaces `{:error, :nonmonotonic}` honestly, it is not BUILT for); **object/
  non-trivial payloads** (claims-only is the law — `fields` are flat string pairs); any **new inline
  `Script.new/2`** (emq3.2 is a no-new-Lua rung — the append is `XADD` issued direct); any **edit to a shipped
  script** (every shipped script byte-frozen — `grep redis.call` on the lib diff = 0); any **`echo_wire`/transport
  change** (UNTOUCHED); any **new `EMQ*` wire class** (the kind door is a host raise — the closed registry stands);
  any **edit to the frozen v1 line** (`apps/echomq`).
- **Reconcile finding — the StreamData dependency (named, not discovered).** `stream_data 1.3.0` is locked in
  `mix.lock:20` but **NOT in echo_mq's own `mix.exs` `deps/0`** (`mix.exs:28-32` declares only `echo_data` +
  `echo_wire`); no echo_mq test uses `ExUnitProperties` (re-probed). The dep-graph-visibility rule (the Venus
  charter, F6.7): a transitively-locked module is NOT compile-visible to an app whose `deps/0` lacks the edge. So
  emq3.2 specs the order-theorem property as a **deterministic generative ExUnit enumeration** (forced same-ms
  sequences via `Snowflake.next/1`, many randomized-but-seeded mint orders) — needing **NO new dep edge**. The
  richer StreamData arm (`use ExUnitProperties` + `check all`) is named as requiring the one-line `mix.exs` add
  `{:stream_data, "~> 1.3", only: :test}` — the Operator's call; the property is the same either way (the order
  theorem over many sequences), only the generator differs.

## Invariants (the runnable checks emq3.2 carries)

- **EMQ3.2-INV1 — the order theorem (stream order == id sort == mint order).** The pure `Stream.Id.xadd_id/1` is
  an order-preserving image of the branded record id (§1.2); the writer appends N branded records in mint order
  and a read-back reads them in that order. *Check (three ways):* (a) **in-scenario read-back** — `append` N
  records, `read` them, assert the read order == the mint order == the id-sort order (a positive proof, the
  `stream_append` conformance scenario); (b) **the order-theorem property test** — over many mint sequences
  (including FORCED same-ms via `Snowflake.next/1` with distinct node ids), assert
  `branded_a < branded_b ⇔ Stream.Id.xadd_id(a) compares < Stream.Id.xadd_id(b)` (a deterministic ExUnit
  enumeration — no new dep; OR `check all` under StreamData if the Operator accepts the dep add); (c) **the ≥100
  determinism loop** — `for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done` green
  (MANDATORY — the rung MINTS branded ids; the same-ms mint hazard flakes only across runs). The loop must own the
  machine (no concurrent liveness server).
- **EMQ3.2-INV2 — the kind RAISE (wrong-kind refused host-side, before any wire).** A record id that is not a
  wellformed branded id OR not of the admitted stream namespace (`EVT`) **raises** (an `ArgumentError`/equivalent)
  at the writer's FIRST act, before any `XADD` reaches the wire — symmetric with `Keyspace.job_key/2`
  (`keyspace.ex:18-24`, the as-built precedent that raises on a non-branded id). One brand per stream is what keeps
  INV1's step-1 sound (F-E). *Check:* `append` with a malformed id raises; `append` with a wrong-namespace id
  (e.g. an `ORD…` id) raises; the raise occurs with NO key written (a probe confirms the stream key is absent
  after a raised append). NO new `EMQ*` wire class is added (the closed registry `{EMQKIND, EMQSTALE}` is
  byte-unchanged — the stream has no script to issue a wire class).
- **EMQ3.2-INV3 — the `:nonmonotonic` liveness (the `id≤top` rejection surfaced, never swallowed).** An `XADD`
  whose explicit id is ≤ the stream's current top is rejected by Valkey (`ERR The ID specified in XADD is equal or
  smaller than the target stream top item`, verbatim valkey.io); the writer maps this to `{:error,
  :nonmonotonic}`, **never swallows it, never retries with `*`** (the F-A liveness check — the wire telling the
  truth that an upstream mint-order violation happened). *Check:* a contrived append of an explicit id ≤ the top
  (a stale branded id appended after a newer one already landed) returns `{:error, :nonmonotonic}`; the proof
  asserts the writer surfaces it (not a silent success, not a swallowed retry). Under the single-writer posture
  (INV1) this never fires; the check uses a deliberately out-of-order append to exercise the surface.
- **EMQ3.2-INV4 — byte-freeze: `echo_wire` UNTOUCHED + no new/edited Lua (a no-new-script rung).** The writer
  rides the shipped `Connector.command/3`/`pipeline/3` — `git diff echo/apps/echo_wire/` is EMPTY (the connector
  untouched); `{emq}:version` reads `echomq:2.4.2` (the `@wire_version` constant byte-unchanged). emq3.2 adds NO
  inline `Script.new/2` and edits NO shipped script — `grep redis.call` on the `lib/` diff = **0** (the append is
  `XADD` issued direct, not via Lua). *Check:* the `echo_wire` diff is empty; the `lib/` diff's `grep -c
  redis.call` is 0; every shipped `Script.new/2` body is byte-identical to HEAD (the as-built `@enqueue`/`@claim`/
  `@complete`/… constants unchanged).
- **EMQ3.2-INV5 — the pure `Stream.Id` core (a doctested + property-tested pure module, NOT a process `defp`).**
  The order math lives in `EchoMQ.Stream.Id` — pure, total over its input, doctested, property-tested (the
  architect-skill verdict-surface law: a verdict/shaping surface is specced as a pure peer, exhaustive + disjoint,
  un-spoofable; the precedents `BatchShaper.Core`/`BatchFinish.partition`). The `EchoMQ.Stream` writer is a thin
  router over it (the XADD-issuing IO stays in the writer; the id math stays in the core). *Check:* `Stream.Id` has
  no process, no IO, no `Connector` call; `xadd_id/1` is doctested (a known branded id → its `<ms>-<tail22>` form)
  and property-tested (INV1b); `EchoMQ.Stream.append/4` calls `Stream.Id.xadd_id/1` for the id (the router is
  thin).
- **EMQ3.2-INV6 — declared-keys VACUOUS + no grammar edit.** emq3.2 adds NO new Lua script → the declared-keys
  law (S-6) has no script keys to satisfy (vacuously held). The stream key is `emq:{q}:stream:<name>` via the
  shipped total `queue_key/2` — NO grammar edit (`git diff keyspace.ex` empty). The slot-soundness lemma (a later
  multi-key script touching the stream alongside `emq:{q}:pending` is A-1-sound by the braces — same `{q}` slot) is
  RECORDED for emq3.3/3.5, asserted by no script here. *Check:* `git diff keyspace.ex` is empty;
  `Keyspace.slot(queue_key(q, "stream:s")) == Keyspace.slot(queue_key(q, "pending"))` (same hashtag → same slot);
  no new `Script.new/2` in the diff (INV4).
- **EMQ3.2-INV7 — the additive-minor conformance law (+1, 74→75).** The `stream_append` scenario is registered in
  `scenarios/0` **with its probe in the same change**; the prior **74** scenarios pass **byte-unchanged** (name +
  contract + verdict-body identical, git-verified); the count re-pins **74 → 75** in **both** pinning tests
  (`conformance_run_test.exs:61` `{:ok, 74}` → `{:ok, 75}` + `conformance_scenarios_test.exs:38` `@run_order` gains
  `stream_append`). *Check:* the git-diff of `scenarios/0` shows only the `stream_append` addition; both count
  assertions updated; `Conformance.run/2` prints 75 lines and returns `{:ok, 75}` against the truth row (Valkey on
  6390). The scenario runs the writer round-trip with a POSITIVE proof (append → read-back in mint order + a
  wrong-kind raise); a vacuous pass is a LOUD failure.
- **EMQ3.2-INV8 — the label steps a within-family PATCH; the wire is frozen.** The `mix.exs` rung label steps
  `2.6.0` → **`2.6.1`** (a within-family patch — emq3.1 opened the Stream Tier family with the `2.6.0` MINOR;
  emq3.2 is the second rung, so it patches; the position-encoded convention, the precedent emq.5.2/5.3 patching
  within the emq.5 family). The wire `@wire_version` stays FROZEN `echomq:2.4.2` (the deferred cutover,
  `emq.streams.md:13`). *Check:* `mix.exs:7` reads `version: "2.6.1"`; `{emq}:version` reads `echomq:2.4.2`; the
  `@wire_version` constant is byte-unchanged.

## Closed error set (the typed surfaces emq3.2 may meet — grounded, ONE new typed result)

- **`{:error, :nonmonotonic}`** — the ONE typed result emq3.2 adds (INV3): an `XADD` whose explicit id is ≤ the
  stream top is rejected by Valkey, and the writer maps that rejection to `{:error, :nonmonotonic}`, never
  swallowed. This is a host-side mapping of a server reply, NOT a new `EMQ*` wire class (the closed wire-class
  registry `{EMQKIND, EMQSTALE}` is unextended — there is no script to issue a wire class).
- **a RAISE (wrong-kind / malformed record id)** — a non-`EVT` or non-branded record id raises host-side before
  any wire (INV2), symmetric with `Keyspace.job_key/2`'s wellformedness raise (`keyspace.ex:22`). A programming
  error (a producer minting the wrong kind) raises; a runtime condition (`:nonmonotonic`) returns typed — the
  principled split (D-2).
- **`{:error_reply, msg}`** — any OTHER server-side stream error (e.g. `XADD` to a key holding a non-stream type)
  arrives as a RESP error VALUE (`resp.ex:47`), surfaced verbatim; the caller decides severity (the shipped
  convention). emq3.2 adds no typed refusal beyond `:nonmonotonic`.
- **`{:error, :overloaded}` / `:disconnected` / `:closed`** — the connector's shipped backpressure + socket-loss
  discipline (`connector.ex` moduledoc), inherited unchanged by the writer's `XADD`/`pipeline`.
- **An ill-formed queue name** — `Keyspace.queue_key/2` builds the braced key; an ill-formed queue raises at the
  key builder (the shipped keyspace gate, wellformedness only). The stream key inherits this gate.

There is **NO new `EMQ*` wire class** — `:nonmonotonic` is a host-side mapping of a server reply, and the
wrong-kind refusal is a host raise (no script to issue a wire class). The closed registry stands `{EMQKIND,
EMQSTALE}` (`emq.design.md:275-279`).

## Definition of Done

- [ ] **The forks RULED** (D-1 the A1 id mapping · D-2 the host-raise kind door, brand `EVT` · D-3 the `+1
      stream_append` count · D-4 the `2.6.1` label, NORMAL+ risk · ADR-3 the key via `queue_key/2` · ADR-4 the
      `EchoMQ.Stream` router over the pure `Stream.Id`) — the body authored to the consensus; the design-phase
      record (the rejected mappings) carried for the reconcile (§1.5).
- [ ] **The pure `EchoMQ.Stream.Id` core** (NEW) — `xadd_id/1` returns `"#{Snowflake.unix_ms(snow)}-#{snow &&&
      0x3FFFFF}"` (D-1); doctested (a known branded id → its `<ms>-<tail22>` form) + property-tested (the order
      theorem over many sequences incl. forced same-ms — INV1b/INV5). No process, no IO.
- [ ] **The `EchoMQ.Stream` writer** (NEW) — `append/4` host-raises wrong-kind (INV2), derives the XADD id from
      `Stream.Id`, issues `XADD <key> <id> id <branded> <fields>` via `Connector.command/3`, returns the branded
      receipt, maps `id≤top` to `{:error, :nonmonotonic}` (INV3, never swallowed). `read/3..6` (the minimal
      un-grouped read-back — `{branded, fields}` in mint order, the order-theorem proof surface). Optional
      `append_batch/4` (the pipelined writer riding `pipeline/3`).
- [ ] **The order theorem proven THREE ways** (INV1) — the in-scenario read-back (the `stream_append` scenario) +
      the order-theorem property test (a deterministic ExUnit enumeration, no new dep; StreamData named as the
      Operator-optional richer arm) + the **≥100 determinism loop** (MANDATORY — the rung mints branded ids).
- [ ] **The kind door** (INV2) — a malformed or wrong-namespace record id raises before any wire, with NO key
      written; the closed wire-class registry `{EMQKIND, EMQSTALE}` byte-unchanged.
- [ ] **Byte-freeze** (INV4) — `git diff echo/apps/echo_wire/` EMPTY; `grep -c redis.call` on the `lib/` diff = 0
      (no new/edited Lua); every shipped `Script.new/2` byte-identical to HEAD; `{emq}:version` = `echomq:2.4.2`.
- [ ] **The `emq:{q}:stream:<name>` key** (INV6) via the shipped total `queue_key/2` — `git diff keyspace.ex`
      EMPTY; the stream shares the `{q}` slot (`slot(stream key) == slot(pending key)`); declared-keys vacuous (no
      new script); the slot-soundness lemma recorded for emq3.3/3.5.
- [ ] **The conformance scenario** (INV7) — `+1 stream_append` registered with its probe; the prior **74**
      byte-unchanged; the count re-pinned **74 → 75** in both pinning tests; `Conformance.run/2` → `{:ok, 75}` on
      the truth row. A present precondition (a live stream) runs the writer round-trip with a positive proof; a
      vacuous pass is a LOUD failure.
- [ ] **The label** (INV8) — `mix.exs:7` `version: "2.6.1"` (a within-family patch); `@wire_version` frozen
      `echomq:2.4.2`.
- [ ] The proof: the `:valkey` stream suite green per-app (`TMPDIR=/tmp mix test --include valkey`); the pure-core
      suite green (doctests + the property test); the **≥100 determinism loop** green (the rung mints branded
      ids); the `echo_wire` `git diff` EMPTY; honest-row reporting (Valkey on 6390).
- [ ] INV1–INV8 verified as runnable checks; the tier contract ([`../../emq.streams.md`](../../emq.streams.md))
      remains the carve authority; this body is authoritative (synced to the as-built post-build). **Apollo** is an
      optional fast-finisher on the ruled NORMAL+ arm (the Operator MAY upgrade it to mandatory given ADR-1's
      stakes).

Tier: [`../../emq.streams.md`](../../emq.streams.md) (the Stream Tier contract, the ladder, the seams — the carve
authority) · Rung stories + brief: [`emq3.2.stories.md`](emq3.2.stories.md) · [`emq3.2.llms.md`](emq3.2.llms.md) ·
Runbook: [`emq3.2.prompt.md`](emq3.2.prompt.md) · The prior rung (the verb floor it stands on, SHIPPED):
[`emq3.1.md`](emq3.1.md) · The generic command path it rides (SHIPPED):
`echo/apps/echo_wire/lib/echo_mq/connector.ex` — `command/3` (`:47-54`) + `pipeline/3` (`:56-60`) · the
verb-agnostic codec `echo/apps/echo_wire/lib/echo_mq/resp.ex` — `parse/1` (`:45-87`) · the braced grammar
`echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — `queue_key/2` (`:14-15`) + `job_key/2` (`:18-24`, the kind-door
precedent) + `slot/1` (`:44`) · the substrate `echo/apps/echo_data/lib/echo_data/snowflake.ex` — `unix_ms/1`
(`:107`) + `next/0`,`next/1` (`:63`,`:74`) + `min_for/1` (`:116`) · `echo/apps/echo_data/lib/echo_data/branded_id.ex`
— `decode/1` (`:55`) + `valid?/1` (`:95`) + `namespace/1` (`:97`) · `echo/apps/echo_data/lib/echo_data/base62.ex`
(the order-preserving codec, `:5`) · the ephemeral pub/sub seam the rung does not disturb
`echo/apps/echo_mq/lib/echo_mq/events.ex` · The v2 laws: §6 (the braced keyspace) · S-6 (the declared-keys A-1 law,
vacuous here) · S-3/§5 (the additive-minor / additive-registration-is-a-minor law) · §2 (the kind-law division) ·
The design canon: [`../../emq.design.md`](../../emq.design.md) (§0/§2 the order theorem · §6 grammar · §12 engine
ADRs) · Roadmap: [`../../emq.roadmap.md`](../../emq.roadmap.md) (the EchoMQ 3.0 row · the Stream Tier) · Approach:
[`../../../elixir/specs/specs.approach.md`](../../../elixir/specs/specs.approach.md) · The engine (cited
valkey.io): `valkey.io/commands/xadd` (the `<ms>-<seq>` form, both 64-bit; explicit ids; the `id≤top` rejection) ·
`valkey.io/topics/streams-intro` (the verbatim rejection error; entries stored in increasing-ID order).
