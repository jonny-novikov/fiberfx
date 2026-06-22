# EMQ3.2 — stories (S1 the writer, part 2 — THE WRITER LAW: `EchoMQ.Stream`, append == mint order)

> The acceptance face of [`emq3.2.md`](emq3.2.md) (the body is authoritative — if a story disagrees with the body,
> the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then acceptance
> (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every Deliverable
> traces to a story. **The forks are RULED (the design-phase consensus): D-1 the A1 id mapping · D-2 the host-raise
> kind door, brand `EVT` · D-3 the `+1 stream_append` count (74→75) · D-4 the `2.6.1` label, NORMAL+ risk · ADR-3
> the key via the shipped `queue_key/2` · ADR-4 the `EchoMQ.Stream` router over the pure `Stream.Id`.** The stories
> are authored to the consensus.
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule).** Each round-trip story is a POSITIVE
> proof: a present precondition (a live stream / N appended records / a created pending entry) MUST run the writer
> and assert the OBSERVABLE outcome — append → read-back in mint order is asserted against the appended data (not
> "a non-error reply"); the kind raise is asserted to occur with NO key written; the `:nonmonotonic` mapping is
> asserted to be SURFACED (not a silent success, not a swallowed retry). A vacuous pass — an `XRANGE` over an empty
> stream, an order assertion over a single record, a "wrong-kind raised" check that never confirms the key is
> absent — is a LOUD failure, never a silent green. **The order theorem (US1) is proven THREE ways** (the
> in-scenario read-back + the property test over many sequences incl. forced same-ms + the ≥100 determinism loop)
> precisely because one example proves nothing about an order law (US1's property MUST exercise enough sequences,
> including same-ms mints, that a non-order-preserving mapping would fail).
>
> **The determinism posture (the load-bearing difference from emq3.1).** emq3.2 MINTS branded record ids → the
> same-millisecond branded-id mint hazard is PRESENT → the **≥100 determinism loop is MANDATORY** (emq3.1 minted
> nothing, so a multi-seed sweep sufficed; emq3.2 mints, so the loop is the proof). Stated in EMQ3.N-US-GATE.

---

## US1 — Branded records append in mint order; a read-back reads them in that order (the order theorem)

**As an** event-stream consumer, **I want** branded records appended to a stream to land in mint order — so a
read-back reads them in exactly mint order (stream order == id sort == mint order) — **so that** the stream
position, sort key, and id are ONE value with no second index (the tier's economy, `emq.streams.md:44-48`), and a
later time-travel read (emq3.6) maps a mint instant straight to a stream bound.

- **Exercises:** EMQ3.2-INV1 (the order theorem — the in-scenario read-back + the property test + the ≥100 loop),
  EMQ3.2-INV5 (the pure `Stream.Id` core carries the order-preserving mapping).

```gherkin
Given a RESP3 connection to Valkey on 6390 and a stream key emq:{q}:stream:s via Keyspace.queue_key(q, "stream:s")
  And a single writer minting EVT-branded record ids over the shared lock-free Snowflake cell (strictly monotone)
When N branded records are appended via EchoMQ.Stream.append(conn, q, "s", fields) in mint order
Then each append derives the XADD id "#{Snowflake.unix_ms(snow)}-#{snow &&& 0x3FFFFF}" from the branded id (D-1, A1)
  And the 14-byte branded string is stored as the stream "id" field (the claims-only contract)
  And EchoMQ.Stream.read(conn, q, "s") reads back exactly N records as {branded_id, fields} IN MINT ORDER
  And the read-back order == the id-sort order == the mint order (the order theorem holds by construction)
  And under the single-writer posture NO append is ever rejected (the next id always exceeds the stream top)
```

- **Liveness (no vacuous pass):** US1 MUST append **N ≥ 2** records (an order assertion over one record proves
  nothing) and assert the read-back order equals the mint order against the appended data. The **order-theorem
  property** (INV1b) MUST exercise many mint sequences INCLUDING forced same-millisecond mints (via
  `Snowflake.next/1` with distinct node ids) — a property whose generator never produces a same-ms pair would not
  exercise the case A1 was designed to survive. The **≥100 determinism loop** (INV1c) is MANDATORY (the rung mints
  branded ids; a same-ms mint collision flakes only across runs).
- **Pure-core note (ADR-4 / INV5):** the order-preserving mapping lives in the pure `EchoMQ.Stream.Id.xadd_id/1`
  (doctested + property-tested, no process/IO); `EchoMQ.Stream.append/4` is a thin router that calls it for the id.

## US2 — Wrong-kind is refused at the writer's first act, host-side (the kind door)

**As an** event-stream consumer, **I want** a record id that is not a wellformed branded id OR not of the admitted
stream namespace (`EVT`) refused at the writer's FIRST act — a host-side raise before any wire — **so that** one
stream carries one brand (which is what keeps the byte-order ≡ snowflake-order step of the order theorem sound,
F-E), and a producer minting the wrong kind fails fast at the source, not silently mid-stream.

- **Exercises:** EMQ3.2-INV2 (the kind raise, wrong-kind refused host-side, no key written, no new wire class).

```gherkin
Given a stream key emq:{q}:stream:s and the admitted stream namespace EVT (one brand per stream, D-2)
When EchoMQ.Stream.append is called with a record id that is malformed (not a 14-byte branded id)
Then it RAISES (an ArgumentError/equivalent) at the writer's first act, before any XADD reaches the wire
  And the stream key emq:{q}:stream:s is ABSENT after the raised append (no partial write — a probe confirms)
When EchoMQ.Stream.append is called with a wrong-namespace id (e.g. an ORD-branded id, not EVT)
Then it RAISES before any wire (symmetric with Keyspace.job_key/2's wellformedness raise, keyspace.ex:18-24)
  And the closed wire-class registry {EMQKIND, EMQSTALE} is byte-unchanged (no new EMQ* class — the stream has no script)
```

- **Liveness (no vacuous pass):** the "raised" check MUST confirm the stream key is ABSENT after the raised append
  (a raise that left a partial write would break the door's contract); the wrong-namespace case MUST use a
  genuinely-branded-but-wrong-kind id (an `ORD…` id), not merely a malformed string, to prove the KIND check (not
  just the wellformedness check) fires.
- **Principled-split note (D-2):** a programming error (a producer minting the wrong kind) RAISES; a runtime
  condition (`:nonmonotonic`, US3) returns typed — the deliberate split.

## US3 — A non-monotonic append surfaces `{:error, :nonmonotonic}`, never swallowed (the liveness check)

**As an** operator of a stream, **I want** an `XADD` whose explicit id is ≤ the stream's current top to surface as
`{:error, :nonmonotonic}` — never swallowed, never silently retried with `*` — **so that** the wire tells the truth
that an upstream mint-order violation happened (the F-A liveness check), rather than papering over a broken order
theorem.

- **Exercises:** EMQ3.2-INV3 (the `:nonmonotonic` liveness — the `id≤top` rejection surfaced, never swallowed).

```gherkin
Given a stream emq:{q}:stream:s with a record already appended at the current top id
When an append is issued whose explicit XADD id is <= the stream top (a stale branded id, or a contrived out-of-order id)
Then Valkey rejects it: "ERR The ID specified in XADD is equal or smaller than the target stream top item" (verbatim, valkey.io)
  And EchoMQ.Stream maps the rejection to {:error, :nonmonotonic} (a host-side mapping of a server reply)
  And the writer SURFACES it — it does NOT swallow it, does NOT retry with the server * id, does NOT raise
  And under the single-writer posture (US1) this never fires; the proof uses a deliberately out-of-order append to exercise the surface
```

- **Liveness (no vacuous pass):** the proof MUST assert the writer returns `{:error, :nonmonotonic}` (not a silent
  success, not a swallowed retry, not a generic error) for a genuinely-rejected append — exercising the surface
  with a deliberately out-of-order explicit id (the single-writer posture means it never fires naturally, so the
  test contrives it).
- **Scope note:** multi-writer-per-stream (where this fires naturally) is the parked log-tier-exit seam
  (`emq.streams.md` §Seams) — emq3.2's posture is single-writer; the `:nonmonotonic` surface exists so multi-writer
  fails HONESTLY, it is not BUILT for.

## US4 — The minimal un-grouped read-back is the order-theorem proof surface

**As an** event-stream consumer, **I want** a minimal un-grouped range read (`EchoMQ.Stream.read/3..6`) that returns
appended records as `{branded_id, fields}` tuples in mint order — **so that** the order theorem is GATED by reading
records back and asserting their order equals their mint order, without depending on the consumer-group lifecycle
(which is emq3.3).

- **Exercises:** EMQ3.2-INV1 (the read-back is the in-scenario order proof), EMQ3.2-INV4 (the read rides the
  shipped connector — no `echo_wire` edit).

```gherkin
Given a stream emq:{q}:stream:s with N branded records appended in mint order (US1)
When EchoMQ.Stream.read(conn, q, "s", from, to, count) wraps XRANGE through the shipped Connector.command/3
Then it parses the nested-array reply [[id, [field, value, ...]], ...] (the shape RESP.parse/1 already yields)
  And returns N {branded_id, fields} tuples in mint order (the branded id recovered from the stored "id" field)
  And the read is un-grouped (NOT a consumer group — XREADGROUP/XACK/XAUTOCLAIM are emq3.3)
  And no XREADGROUP/XACK/XAUTOCLAIM is issued (the consumer-group lifecycle is deferred)
When N records are appended via the optional EchoMQ.Stream.append_batch/4 through the shipped pipeline/3
Then N branded receipts return in call order, and read/_ reads them back in mint order (the emq3.1-certified pipeline)
```

- **Liveness (no vacuous pass):** `read/_` MUST be exercised over a stream with N ≥ 2 records and assert the
  returned tuples are in mint order against the appended data (an `XRANGE` over an empty stream, or a read that
  asserts nothing about order, proves nothing). The `append_batch/4` story (if built) MUST assert N receipts in
  call order AND the read-back in mint order.

## US5 — The conformance set grows by one (`stream_append`), the prior set byte-unchanged

**As a** maintainer of the bus protocol, **I want** the writer law gated by exactly one new conformance scenario
(`stream_append`) registered with its probe, the prior 74 byte-unchanged and the count re-pinned 74→75 — **so that**
the protocol's additive-minor law holds (the writer is one additive capability, the wire unbroken) and the
conformance count stays an honest live total.

- **Exercises:** EMQ3.2-INV7 (the additive-minor conformance law, +1, 74→75), EMQ3.2-INV2 (the scenario asserts the
  kind door), EMQ3.2-INV1 (the scenario asserts the append-order theorem).

```gherkin
Given the as-built conformance set with 74 scenarios (conformance_run_test.exs:61 {:ok, 74})
When emq3.2 registers the stream_append scenario in scenarios/0 with its probe in the same change
Then the prior 74 scenarios are byte-unchanged (name + contract + verdict-body identical, git-verified)
  And the count re-pins 74 -> 75 in BOTH pinning tests (conformance_run_test.exs {:ok, 75} + conformance_scenarios_test.exs @run_order gains stream_append)
  And Conformance.run/2 prints 75 lines and returns {:ok, 75} against the truth row (Valkey on 6390)
  And the stream_append scenario is a POSITIVE proof: append N EVT records, read back in mint order, AND a wrong-kind id raises
  And the deep order proof rides the property test + the ≥100 loop (NOT extra example scenarios — D-3)
```

- **Liveness (no vacuous pass):** the `stream_append` scenario MUST run the writer round-trip with a positive proof
  (append → read-back in mint order + a wrong-kind raise) — a scenario that asserts nothing about the append order
  or the kind door is a LOUD failure. The count assertion MUST be re-pinned in BOTH pinning tests (a single re-pin
  leaves the other test red).

## US6 — The wire stays frozen; the label steps a within-family patch; no new Lua

**As a** maintainer of the wire contract, **I want** emq3.2 to add NO new/edited Lua script and touch NO frozen
line — `echo_wire` untouched, every shipped `Script.new/2` byte-identical, `@wire_version` frozen — and the label
to step a within-family patch (`2.6.0` → `2.6.1`) — **so that** the writer law lands additive over a frozen wire
(the master invariant: the fork happened once; no later rung re-breaks it).

- **Exercises:** EMQ3.2-INV4 (byte-freeze, `echo_wire` untouched, no new/edited Lua), EMQ3.2-INV6 (declared-keys
  vacuous, no grammar edit), EMQ3.2-INV8 (the within-family patch label, the wire frozen).

```gherkin
Given the shipped echo_wire connector + the frozen v2 scripts + the @wire_version echomq:2.4.2
When emq3.2 builds the EchoMQ.Stream writer riding the shipped Connector.command/3 / pipeline/3
Then git diff echo/apps/echo_wire/ is EMPTY (the connector untouched — the writer rides the shipped path)
  And grep -c redis.call on the lib/ diff is 0 (NO new/edited Lua — the append is XADD issued direct, not via a script)
  And every shipped Script.new/2 body is byte-identical to HEAD (the @enqueue/@claim/@complete/... constants unchanged)
  And git diff keyspace.ex is EMPTY (the stream key rides the total queue_key/2 — no grammar edit; declared-keys vacuous)
  And slot(queue_key(q, "stream:s")) == slot(queue_key(q, "pending")) (the stream shares the {q} slot)
  And {emq}:version reads echomq:2.4.2 (the @wire_version unchanged)
  And mix.exs:7 reads version: "2.6.1" (a within-family patch — emq3.1 opened the family with 2.6.0)
```

- **Liveness (no vacuous pass):** the byte-freeze checks are git-verified (an empty `echo_wire` diff, a 0 `grep -c
  redis.call`, byte-identical script constants) — not asserted from prose. A non-empty `echo_wire` diff, any new
  `redis.call` in the `lib/` diff, or a changed `@wire_version` is a LOUD failure.

## EMQ3.2-US-GATE — the standing Valkey gate (the rung is not done until the gate is green)

**As the** Operator, **I want** the rung's gate ladder green on the live engine before acceptance — **so that** "the
writer law works" is a closure over checks, not a claim.

```gherkin
Given the echo_mq app dir and Valkey on port 6390 (redis-cli -p 6390 ping -> PONG)
When the gate ladder runs (per-app, TMPDIR=/tmp)
Then asdf current erlang matches .tool-versions (re-probed from the app dir, not hardcoded)
  And TMPDIR=/tmp mix compile --warnings-as-errors is clean (the pure Stream.Id + the Stream writer)
  And TMPDIR=/tmp mix test --include valkey is green (the :valkey stream suite + the pure-core suite)
  And the order-theorem property test is green (a deterministic ExUnit enumeration over many sequences incl. forced same-ms)
  And the ≥100 determinism loop is green: for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done (MANDATORY — the rung MINTS branded ids)
  And EchoMQ.Conformance.run/2 prints 75 lines and returns {:ok, 75} on the truth row
  And git diff echo/apps/echo_wire/ is EMPTY (the connector untouched)
  And the loop OWNS the machine (no concurrent liveness server — a load-gated test forges a failure the rung did not cause)
```

- **The determinism posture is HONEST and load-bearing:** unlike emq3.1 (which minted nothing → a multi-seed
  sweep), emq3.2 MINTS branded record ids in the append path → the same-millisecond branded-id mint hazard is
  PRESENT → the **≥100 determinism loop is MANDATORY** (one green run is not proof; a same-ms collision flakes only
  across runs).

---

## Coverage map (every Deliverable → its story → its invariant)

| Deliverable (emq3.2.md Goal) | Story | Invariant(s) |
|---|---|---|
| 1 · the pure `EchoMQ.Stream.Id` core (the A1 mapping) | US1 (+ US5 scenario) | INV1, INV5 |
| 2 · the `EchoMQ.Stream` writer (`append/4`, the branded receipt) | US1, US3 | INV1, INV3 |
| 3 · the kind door (one brand `EVT`, host raise, no new wire class) | US2 | INV2 |
| 4 · the minimal un-grouped `read/3..6` + optional `append_batch/4` | US4 | INV1, INV4 |
| 5 · the `emq:{q}:stream:<name>` key via the shipped `queue_key/2` | US6 | INV6 |
| 6 · the `+1 stream_append` conformance scenario (74→75) | US5 | INV7 |
| (the order theorem proven three ways) | US1 + EMQ3.2-US-GATE | INV1 (a/b/c) |
| (the `:nonmonotonic` liveness, never swallowed) | US3 | INV3 |
| (byte-freeze: `echo_wire` untouched, no new Lua, the label) | US6 | INV4, INV6, INV8 |
| (the standing Valkey gate + the ≥100 loop) | EMQ3.2-US-GATE | INV1c, INV4, INV7, INV8 |

Every Deliverable traces to a story; every story names the invariant(s) it exercises; the body
[`emq3.2.md`](emq3.2.md) is authoritative.
