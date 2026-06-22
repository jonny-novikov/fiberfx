# EMQ3.2 — the Mars brief (S1 the writer, part 2 — THE WRITER LAW: `EchoMQ.Stream`, append == mint order)

> The compact build brief. The body [`emq3.2.md`](emq3.2.md) is authoritative; the acceptance is
> [`emq3.2.stories.md`](emq3.2.stories.md); the run scope is [`emq3.2.prompt.md`](emq3.2.prompt.md). Build ONLY
> inside `echo/apps/echo_mq` (the writer rides the shipped `echo_wire` connector `command/3`/`pipeline/3` — NO
> `echo_wire` edit). Cite the spec line for every public call; the append is `XADD` issued direct as a `parts`
> list (NO new `Script.new/2` — emq3.2 is a no-new-Lua rung); the conformance additive-minor mechanics (74→75).
> **The forks are RULED (the design-phase consensus — D-1..D-4 + ADR-3/ADR-4); build to the consensus.**
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software (components read, compute, refuse, return); no first-person
> narration. Bind this same clause in any sub-brief.

## References (read first — the exact upstream, links/paths first)

1. **The body** — [`emq3.2.md`](emq3.2.md): Goal · §1 the order theorem (the proof, D-1/A1) · Scope · INV1–8 · the
   closed error set · the forks RULED · DoD. The forks are the design-phase consensus: D-1 A1 id mapping · D-2
   host-raise kind door (brand `EVT`) · D-3 `+1 stream_append` (74→75) · D-4 `2.6.1` label, NORMAL+ · ADR-3 the key
   via `queue_key/2` · ADR-4 the `EchoMQ.Stream` router over the pure `Stream.Id`.
2. **The tier contract** — [`../../emq.streams.md`](../../emq.streams.md): the Stream Tier ladder (emq3.1–3.6), the
   three milestones (S1 writer · S2 readers · S3 memory), the tier's economy (`:44-48` *"the sequence is already
   minted … one value, no second index"*), the seams (`:84-91` — multi-writer-per-stream is the parked
   log-tier-exit). emq3.2 is the writer LAW of S1; the readers are emq3.3.
3. **The prior rung (the verb floor it stands on, SHIPPED `7b44dc97`)** — [`emq3.1.md`](emq3.1.md) +
   `echo/apps/echo_mq/test/stream_verbs_test.exs`: the five verbs round-trip on the connector; `XADD … *` answers a
   `<ms>-<seq>` bulk id (`stream_verbs_test.exs:77-84`); the pipelined batch returns ids in call order
   (`:144-167`); the braced stream key idiom `Keyspace.queue_key(q, "stream:" <> name)` (`:69`). emq3.1 appended
   with `*`; emq3.2 appends with the EXPLICIT A1 id.
4. **The generic command path to RIDE (SHIPPED — NO edit)** — `echo/apps/echo_wire/lib/echo_mq/connector.ex`:
   - `command/3` (`connector.ex:47-54`) — `command(conn, parts, timeout \\ 5_000)`, `parts` is `[binary() |
     integer() | atom()]`; `pipeline(conn, [parts], timeout)` of one → `{:ok, RESP.reply()}` | `{:error, term()}`.
     **The writer's `XADD`/`XRANGE` ride THIS** — `command(conn, ["XADD", key, id, "id", branded, k, v, …])`.
   - `pipeline/3` (`connector.ex:56-60`) — `pipeline(conn, cmds, timeout)`, `cmds` a list of command-lists → `{:ok,
     [reply]}` in call order. The optional `append_batch/4` rides THIS.
   - `@wire_version "echomq:2.4.2"` (`connector.ex:35`) — the boot fence constant; **byte-unchanged** (INV4/INV8).
     The `echo_wire` diff MUST be EMPTY.
5. **The verb-agnostic codec (SHIPPED, NO edit)** — `echo/apps/echo_wire/lib/echo_mq/resp.ex`: `parse/1`
   (`resp.ex:45-87`) — an `XRANGE` reply is a nested array `[[id, [field, value, …]], …]` (the array branch
   `resp.ex:59`; the shape `stream_verbs_test.exs:83` asserts). `read/_` parses THIS into `{branded, fields}`.
6. **The braced grammar (SHIPPED, NO edit)** — `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`:
   - `queue_key/2` (`keyspace.ex:14-15`) — `emq:{q}:<type>` for ANY `<type>` (the hash transparent). The stream key
     rides `queue_key(q, "stream:" <> name)` — **NO grammar edit** (ADR-3/INV6).
   - `job_key/2` (`keyspace.ex:18-24`) — gates `BrandedId.valid?/1` and **RAISES** before any wire (`:22`). **The
     ADR-2 kind-door precedent** — the writer's host raise extends this from "is it branded?" to "is it `EVT`?".
   - `slot/1` (`keyspace.ex:44`) + `hashtag/1` (`:47-54`) — the CRC16 over the hashtag; `slot(stream key) ==
     slot(pending key)` (INV6).
7. **The substrate — the id math (SHIPPED, the A1 mapping source)** —
   `echo/apps/echo_data/lib/echo_data/snowflake.ex`:
   - `unix_ms/1` (`snowflake.ex:107`) = `(snowflake >>> 22) + @epoch_ms` (`@epoch_ms = 1_704_067_200_000`, `:32`)
     — the **real Unix-ms** of the mint, the A1 ms field. **NOT the raw `ts` field** (which is epoch-relative) —
     load-bearing for emq3.6's wall-clock `XRANGE`.
   - `next/0` (`:63`) + `next/1` (`:74`, a per-call node id over the SAME cell) — the lock-free mint; ts+seq from
     ONE strictly-monotone `:atomics` CAS (`advance/2`, `:91-99`) → successive mints strictly increasing (the
     single-writer order guarantee; `next/1` with distinct node ids forces same-ms mints for the property test).
   - `min_for/1` (`:116`) — the mint-instant→bound seed (emq3.6; emq3.2 MAY land `min_id_for` riding this, defers
     the windowed read).
   - the layout `ts(41)<<<22 | node(10)<<<12 | seq(12)` (`snowflake.ex:3`) — so `snow &&& 0x3FFFFF` = the 22-bit
     `node|seq` tail, the A1 seq field.
8. **The substrate — the branded codec (SHIPPED)** — `echo/apps/echo_data/lib/echo_data/branded_id.ex`: `decode/1`
   (`:55-57`) → `{:ok, snow}` | `:error`; `valid?/1` (`:95`); `namespace/1` (`:97`) → the 3-byte brand; `is_branded/1`
   (`:23`, the 14-byte guard); `encode!/2` (`:85`) / `Snowflake.next_branded/1` (`snowflake.ex:104`, mint+brand). And
   `echo/apps/echo_data/lib/echo_data/base62.ex` (`:5`) — the **order-preserving** fixed-11 codec (lexicographic ==
   numeric; alphabet `0-9A-Za-z` ascending) — the proof that branded byte order == snowflake int order within one NS.
9. **The conformance harness (SHIPPED — extend additively)** — `echo/apps/echo_mq/lib/echo_mq/conformance.ex`:
   `scenarios/0` (`:101`) — the registered list (74 live); `run/2` → `{:ok, n}`. The pins:
   `echo/apps/echo_mq/test/conformance_run_test.exs:61` `{:ok, 74}` → `{:ok, 75}`;
   `echo/apps/echo_mq/test/conformance_scenarios_test.exs:38` `@run_order` gains `stream_append`.
10. **The pub/sub seam the rung does NOT disturb (SHIPPED)** — `echo/apps/echo_mq/lib/echo_mq/events.ex`:
    `channel/1` (`:106`); the `{:emq_push, …}` frame (`:205`). emq3.2 does not touch it.
11. **The engine (cited valkey.io, NEVER memory)** — `valkey.io/commands/xadd`: entry id `<ms>-<seq>`, **both
    64-bit**; explicit ids allowed (*"specify a well-formed ID"*); `<ms>-*` auto-seq form; XADD rejects an id ≤ the
    stream top. `valkey.io/topics/streams-intro`: the verbatim rejection error `ERR The ID specified in XADD is
    equal or smaller than the target stream top item`; entries stored in increasing-ID order; max id
    `18446744073709551615-18446744073709551615`.
12. **The program law** — `.claude/skills/echo-mq-program.md` (the v2 laws, the gate ladder, the additive-minor
    conformance law, the ≥100 determinism loop) + the as-built map `.claude/skills/echo-mq-surface.md`.

## Requirements (numbered; each traced back to a story and forward to an invariant)

1. **The pure `EchoMQ.Stream.Id` core (the A1 mapping).** A NEW pure module `lib/echo_mq/stream/id.ex` (no process,
   no IO) carrying `xadd_id/1`: decode the branded id (`BrandedId.decode/1`), return `"#{Snowflake.unix_ms(snow)}-#{snow
   &&& 0x3FFFFF}"` (D-1, A1). Doctested (a known branded id → its `<ms>-<tail22>` form) + property-tested (the order
   theorem over many sequences). MAY also carry the namespace check (the kind predicate) for the writer to call.
   *(US1, US5 → INV1, INV5.)*
2. **The `EchoMQ.Stream` writer (`append/4`).** A NEW module `lib/echo_mq/stream.ex` — `append(conn, queue, name,
   fields)`: (a) MINT the EVT-branded record id host-side (`Snowflake.next_branded("EVT")` or the equivalent — the
   writer owns the mint; D-2 "append mints the brand → nothing to spoof"); (b) host-RAISE if the id is malformed or
   not `EVT` (INV2 — symmetric with `job_key/2`; the mint makes a wrong-kind a programming error); (c) derive the
   XADD id via `Stream.Id.xadd_id/1`; (d) issue `XADD <key> <id> id <branded> <fields…>` via `Connector.command/3`
   (the 14-byte branded string stored as the `id` field); (e) return `{:ok, branded}` (the receipt); (f) map XADD's
   `id≤top` rejection to `{:error, :nonmonotonic}` (INV3 — NEVER swallowed, NEVER retried with `*`). *(US1, US3 →
   INV1, INV3.)*
3. **The kind door (one brand `EVT`, host raise, no new wire class).** The writer admits ONE brand per stream
   (`EVT`); a non-`EVT` or malformed record id RAISES before any wire (INV2). One brand per stream is REQUIRED (it
   keeps INV1's step-1 sound — base62 byte order == int order only within one NS prefix, F-E). NO new `EMQ*` wire
   class — the closed registry `{EMQKIND, EMQSTALE}` is byte-unchanged (the stream has no script to issue a wire
   class). *(US2 → INV2.)*
4. **The minimal un-grouped `read/3..6` (the order-theorem proof surface).** `read(conn, queue, name, from \\ "-", to
   \\ "+", count \\ nil)` — wrap `XRANGE` via `Connector.command/3`, parse the nested-array reply into `{branded_id,
   fields}` tuples IN MINT ORDER (the branded id from the stored `id` field). NOT a consumer group (emq3.3 — no
   `XREADGROUP`/`XACK`/`XAUTOCLAIM`). Optional `append_batch/4` (the pipelined writer riding `pipeline/3`). *(US4 →
   INV1, INV4.)*
5. **The `emq:{q}:stream:<name>` key (no grammar edit).** Build via the shipped total `Keyspace.queue_key(queue,
   "stream:" <> name)` — NO grammar edit (`git diff keyspace.ex` empty); the stream shares the `{q}` slot. emq3.2
   adds NO new Lua → declared-keys VACUOUS; record the slot-soundness lemma for emq3.3/3.5. *(US6 → INV6.)*
6. **The conformance scenario (`+1 stream_append`, 74→75).** Register `stream_append` in `scenarios/0` with its
   probe in the same change; the prior 74 byte-unchanged; re-pin 74→75 in BOTH pinning tests. The scenario is a
   POSITIVE proof: append N EVT records, read back in mint order, AND a wrong-kind id raises. *(US5 → INV7, INV1,
   INV2.)*
7. **Byte-freeze + the label.** `echo_wire` UNTOUCHED (`git diff` empty); NO new/edited Lua (`grep -c redis.call` on
   the `lib/` diff = 0; every shipped `Script.new/2` byte-identical); `@wire_version` frozen `echomq:2.4.2`;
   `mix.exs:7` `version: "2.6.0"` → `"2.6.1"` (a within-family patch). *(US6 → INV4, INV6, INV8.)*
8. **The order theorem proven THREE ways + the ≥100 loop.** (a) the in-scenario read-back (the `stream_append`
   scenario); (b) the order-theorem property test — a **deterministic ExUnit enumeration** over many mint sequences
   INCLUDING forced same-ms (via `Snowflake.next/1` with distinct node ids), asserting `branded_a < branded_b ⇔
   Stream.Id.xadd_id(a) compares < Stream.Id.xadd_id(b)` (**NO new dep** — see the dependency note); (c) the **≥100
   determinism loop** (MANDATORY — the rung mints branded ids). *(US1, EMQ3.2-US-GATE → INV1.)*

> **Dependency note (a reconcile finding — do NOT add a dep silently).** `stream_data 1.3.0` is in `mix.lock` but
> **NOT in echo_mq's `mix.exs` `deps/0`** (`mix.exs:28-32` = only `echo_data` + `echo_wire`); no echo_mq test uses
> `ExUnitProperties` (re-probed). The dep-graph-visibility rule: a transitively-locked module is NOT
> compile-visible without the edge. So Requirement 8b is a **deterministic ExUnit enumeration** (no new dep) by
> default. IF the Operator accepts the richer StreamData arm, it needs the one-line add `{:stream_data, "~> 1.3",
> only: :test}` to `mix.exs` `deps/0` — surface it, do not add it silently. The property is the same either way.

## Execution topology (the runtime shape, the build-order DAG, the EXACT files touched)

**Runtime shape.** `EchoMQ.Stream` is a host module (functions over the shipped connector — NO process, NO
GenServer, NO supervision child); `EchoMQ.Stream.Id` is a pure module (no runtime presence). The writer mints the
branded id host-side, derives the explicit XADD id, and issues `XADD`/`XRANGE` through `Connector.command/3` — the
same single-owner socket the bus already uses. No lease, no `TIME`, no script.

**Build-order DAG (each step gated before the next):**

1. **The pure core** — `lib/echo_mq/stream/id.ex` (`Stream.Id.xadd_id/1` + the namespace predicate). Doctest it.
   *(Gate: `mix compile --warnings-as-errors` clean; doctests green.)*
2. **The pure-core proof** — `test/stream_id_test.exs` (doctests + the order-theorem property test, the
   deterministic enumeration over many sequences incl. forced same-ms). *(Gate: the property test green — a
   non-order-preserving mapping would fail.)*
3. **The writer** — `lib/echo_mq/stream.ex` (`append/4` + the host-raise kind door + the `:nonmonotonic` mapping +
   the branded receipt; `read/3..6`; optional `append_batch/4`). *(Gate: `mix compile --warnings-as-errors` clean.)*
4. **The `:valkey` writer proof** — `test/stream_test.exs` (the writer round-trip: append N EVT records → read back
   in mint order; the kind raise with NO key written; the `:nonmonotonic` liveness on a contrived out-of-order
   append; optional the pipelined batch). The `on_exit` per-queue purge (the `stream_verbs_test.exs:60-65` idiom —
   a disposable connection sweeps `emq:{q}:*`). *(Gate: `mix test --include valkey` green.)*
5. **The conformance scenario** — add `stream_append` to `conformance.ex` `scenarios/0` with its probe; re-pin
   `conformance_run_test.exs:61` `{:ok, 74}` → `{:ok, 75}` + `conformance_scenarios_test.exs:38` `@run_order`.
   *(Gate: `Conformance.run/2` → `{:ok, 75}`; both pins green; the prior 74 byte-unchanged, git-verified.)*
6. **The label** — `mix.exs:7` `version: "2.6.0"` → `"2.6.1"`. *(Gate: the label reads `2.6.1`; `@wire_version`
   frozen `echomq:2.4.2`.)*
7. **The full gate ladder + the ≥100 loop** — `mix compile --warnings-as-errors` + `mix test --include valkey` +
   `Conformance.run/2 → {:ok, 75}` + the **≥100 determinism loop** + the byte-freeze checks (`echo_wire` diff
   empty, `grep -c redis.call` on the `lib/` diff = 0, `keyspace.ex` diff empty).

**Files touched (the complete set):**

| File | Change |
|---|---|
| `echo/apps/echo_mq/lib/echo_mq/stream/id.ex` | **NEW** — the pure A1 mapping core (`xadd_id/1` + the namespace predicate); doctested |
| `echo/apps/echo_mq/lib/echo_mq/stream.ex` | **NEW** — the `EchoMQ.Stream` writer (`append/4`, `read/3..6`, optional `append_batch/4`) |
| `echo/apps/echo_mq/test/stream_id_test.exs` | **NEW** — the pure-core proof (doctests + the order-theorem property test) |
| `echo/apps/echo_mq/test/stream_test.exs` | **NEW** — the `:valkey` writer proof (round-trip + kind raise + `:nonmonotonic`) |
| `echo/apps/echo_mq/lib/echo_mq/conformance.ex` | the `stream_append` scenario + its probe (additive; the prior 74 byte-unchanged) |
| `echo/apps/echo_mq/test/conformance_run_test.exs` | re-pin `{:ok, 74}` → `{:ok, 75}` (`:61`) |
| `echo/apps/echo_mq/test/conformance_scenarios_test.exs` | `@run_order` gains `stream_append` (`:38`) |
| `echo/apps/echo_mq/mix.exs` | the label `version: "2.6.0"` → `"2.6.1"` (`:7`) |

**UNTOUCHED (load-bearing):** `echo/apps/echo_wire/**` (the connector — the writer rides the shipped path);
`echo/apps/echo_mq/lib/echo_mq/keyspace.ex` (the stream key rides the total `queue_key/2`); every shipped
`Script.new/2` (no new/edited Lua); `apps/echomq` (the frozen v1 reference); `mix.lock` (no dep moved — UNLESS the
Operator accepts the StreamData arm, which is the one named exception, a one-line `deps/0` add).

## Agent stories (each a Directive + an Acceptance gate — the contract IS the acceptance criterion)

- **AS-1 · the pure A1 core.** *Directive:* build `EchoMQ.Stream.Id` (pure, no process/IO) — `xadd_id(branded) ::
  {:ok, binary} | {:error, :kind | :malformed}` returning `"#{Snowflake.unix_ms(snow)}-#{snow &&& 0x3FFFFF}"` (D-1,
  cite `snowflake.ex:107`/`:3`); doctest it. *Acceptance gate:* a known branded id → its exact `<ms>-<tail22>` form
  in a doctest; `mix compile --warnings-as-errors` clean; no `Connector`/process/IO in the module (INV5).
- **AS-2 · the order-theorem property.** *Directive:* build `test/stream_id_test.exs` — doctests + a property test
  over many mint sequences (a deterministic ExUnit enumeration; force same-ms via `Snowflake.next/1` with distinct
  node ids) asserting `branded_a < branded_b ⇔ xadd_id(a) parts compare < xadd_id(b)`. NO new dep (the dependency
  note). *Acceptance gate:* the property green over enough sequences (incl. same-ms) that a non-order-preserving
  mapping would fail (INV1b); the enumeration is deterministic (re-runnable) (INV5).
- **AS-3 · the writer + the kind door.** *Directive:* build `EchoMQ.Stream.append/4` — mint the EVT id host-side,
  RAISE on malformed/wrong-kind before any wire (INV2, symmetric with `job_key/2` `keyspace.ex:22`), derive the
  XADD id, issue `XADD <key> <id> id <branded> <fields>` via `Connector.command/3`, return `{:ok, branded}`, map
  `id≤top` to `{:error, :nonmonotonic}` (INV3, never swallowed). *Acceptance gate:* a malformed/wrong-kind append
  RAISES with the stream key ABSENT (a probe confirms); a valid append returns `{:ok, branded}` and the record is
  on the wire under the explicit A1 id with the branded `id` field; no new `EMQ*` class (the registry
  byte-unchanged).
- **AS-4 · the read-back + the order proof.** *Directive:* build `EchoMQ.Stream.read/3..6` (wrap `XRANGE`, parse to
  `{branded, fields}` in mint order; NOT a consumer group) + optional `append_batch/4` (riding `pipeline/3`); build
  `test/stream_test.exs` — append N ≥ 2 EVT records, read back, assert read order == mint order against the
  appended data; the `:nonmonotonic` liveness on a contrived out-of-order append. *Acceptance gate:* `mix test
  --include valkey` green; the read-back order proof is POSITIVE (N ≥ 2, asserted against the appended data — not a
  vacuous `XRANGE`); the `:nonmonotonic` case returns `{:error, :nonmonotonic}` (surfaced, not swallowed) (INV1,
  INV3, INV4).
- **AS-5 · the conformance scenario + the count.** *Directive:* add `stream_append` to `conformance.ex`
  `scenarios/0` with its probe (the prior 74 byte-unchanged); re-pin 74→75 in both pinning tests. *Acceptance
  gate:* `Conformance.run/2` → `{:ok, 75}` on Valkey 6390; the git-diff of `scenarios/0` shows only the addition;
  both pins green; the scenario asserts the append-order theorem + a wrong-kind raise (a positive proof) (INV7).
- **AS-6 · byte-freeze + the label + the ≥100 loop.** *Directive:* step `mix.exs:7` to `"2.6.1"`; run the full
  gate ladder + the ≥100 determinism loop. *Acceptance gate:* `git diff echo/apps/echo_wire/` EMPTY; `grep -c
  redis.call` on the `lib/` diff = 0; every shipped `Script.new/2` byte-identical; `git diff keyspace.ex` EMPTY;
  `@wire_version` `echomq:2.4.2`; `mix.exs:7` `2.6.1`; the ≥100 loop green owning the machine (INV4, INV6, INV8,
  INV1c).

## The short comprehensive prompt (no decision the spec has not fixed)

Build the EchoMQ 3.0 Stream Tier **writer law** inside `echo/apps/echo_mq` to the RULED consensus (D-1..D-4 +
ADR-3/ADR-4). Add a NEW pure `EchoMQ.Stream.Id` (the A1 id mapping `"#{Snowflake.unix_ms(snow)}-#{snow &&&
0x3FFFFF}"` — doctested + property-tested, the order theorem IS its property) and a NEW thin `EchoMQ.Stream` writer
over it + the shipped connector: `append/4` mints the EVT-branded id host-side, RAISES on wrong-kind before any
wire (the host-side kind door, symmetric with `job_key/2`), issues `XADD <key> <id> id <branded> <fields>` (the
branded string as the `id` field), returns `{:ok, branded}`, and maps XADD's `id≤top` rejection to `{:error,
:nonmonotonic}` (NEVER swallowed — the F-A liveness check); `read/3..6` is the minimal un-grouped `XRANGE`
read-back (`{branded, fields}` in mint order — the order-theorem proof surface; the consumer group is emq3.3);
optional `append_batch/4` rides the emq3.1-certified `pipeline/3`. The stream key is `emq:{q}:stream:<name>` via
the shipped total `queue_key/2` (NO grammar edit). Add `+1 stream_append` to conformance (74→75, the prior 74
byte-unchanged, both pins re-pinned). NO new Lua (the append is `XADD` direct — `grep -c redis.call` on the `lib/`
diff = 0; `echo_wire` UNTOUCHED; every shipped `Script.new/2` byte-identical; `@wire_version` frozen
`echomq:2.4.2`). Step `mix.exs:7` to `2.6.1`. Gate: per-app `compile --warnings-as-errors` + `test --include
valkey` + `Conformance.run/2 → {:ok, 75}` + the **≥100 determinism loop** (MANDATORY — the rung MINTS branded ids)
+ the byte-freeze checks. Cite the spec line for every public call; invent nothing (the substrate is `Snowflake`/
`BrandedId`/`Base62`/`Keyspace`; the engine is cited valkey.io); do NOT add the StreamData dep silently (surface
the one-line `deps/0` add if the richer property arm is wanted — the default is a deterministic ExUnit
enumeration). Risk NORMAL+; Apollo OPTIONAL (the Operator may upgrade it).
