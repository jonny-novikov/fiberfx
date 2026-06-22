# EMQ3.3 — stories (S2 the readers, part 1 — THE READER LAW: `EchoMQ.StreamConsumer`, the BEAM consumer group + the polyglot seam)

> The acceptance face of [`emq3.3.md`](emq3.3.md) (the body is authoritative — if a story disagrees with the body, the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then acceptance (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every Deliverable traces to a story. **The forks are RULED (the design-phase convergence): D-2 the SETTLED sibling shape · D-3 the lazy-ensure group door (`:group_start` declared, no destructive verb) · D-4 drain-PEL-first + the exact-mirror handler + the NAMED `attempts`↔delivery-count invariant · D-5 the `+1 stream_group` count (75→76) · D-6 the order-theorem PEL exception NAMED · D-7 the `2.6.2` label, HIGH risk, Apollo mandatory.** The stories are authored to the convergence.
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule).** Each round-trip story is a POSITIVE proof: a present precondition (a live group / N un-acked entries / a killed-but-not-restarted consumer) MUST run the consumer and assert the OBSERVABLE outcome — re-delivery is asserted by the SAME entry returning (not "a non-error reply"); the polyglot parity is asserted by the raw-connector read recovering the EXACT branded receipt; the PEL-drain is asserted by the recovered entry being the consumer's OWN prior un-acked one. A vacuous pass — a `stream_group` scenario that `XACK`s every entry and never re-delivers, an order assertion that never exercises a re-claim, a "polyglot reads" check that never compares the recovered id to the receipt — is a LOUD failure, never a silent green (the TRD.9.1 false-green class). **Re-delivery (US1) is proven by an un-acked entry actually re-handed** (the `XAUTOCLAIM`/PEL-drain path that re-delivers the SAME branded id), precisely because acking everything proves nothing about at-least-once.
>
> **The determinism posture (the load-bearing difference from emq3.2).** emq3.3 builds a NEW SUPERVISED PROCESS (a `spawn_link` loop holding a private blocking lane + a lease-like PEL recovery) AND mints branded ids in the append path the proofs drive → the **≥100 determinism loop is MANDATORY** (a process + a same-millisecond branded-id mint hazard — one green run is not proof; a same-ms collision or a process-timing race flakes only across runs). The loop OWNS the machine (no concurrent liveness server). Stated in EMQ3.3-US-GATE. **Risk is HIGH; Apollo is MANDATORY** (a new process/lease surface — the post-build reconcile + the §11.2 adversarial verification before the Director ships).

---

## US1 — A consumer group delivers every entry at least once; a crash re-delivers the un-acked work (at-least-once)

**As an** event-stream consumer, **I want** a `StreamConsumer` reading a group to deliver every appended entry to my handler at least once — and to RE-DELIVER any entry whose handling crashed before it acked — **so that** no recorded event is silently dropped when a consumer dies mid-handle (the at-least-once posture the tier promises, `emq.streams.md:32`/`:89`).

- **Exercises:** EMQ3.3-INV1 (at-least-once grouped delivery, crash → re-delivery), EMQ3.3-INV3 (the handler verdict drives ack vs leave-un-acked).

```gherkin
Given a RESP3 connection to Valkey on 6390 and a stream emq:{q}:stream:s with EVT records appended via EchoMQ.Stream.append/4
  And a StreamConsumer started on the group "grp" reading XREADGROUP GROUP grp c ... > on its own blocking lane
When N entries are appended and the consumer drains the group, but one handler returns {:error, reason} (or the consumer is killed mid-handle of one entry)
Then every entry is delivered to the handler AT LEAST ONCE (no entry lost)
  And the :ok entries are XACKed (retired from the PEL); the {:error, reason} / crashed entry is LEFT un-acked (it survives in the PEL)
  And the un-acked entry is RE-DELIVERED — by the consumer's own PEL-drain on restart (SELF) OR by the XAUTOCLAIM beat (a dead PEER)
  And a re-delivery returns the SAME branded id (the entry's stored "id" field), proven by asserting the recovered id == the appended receipt
```

- **Liveness (no vacuous pass):** US1 MUST leave at least one entry un-acked (a `{:error, reason}` verdict or a mid-handle kill) and assert the SAME entry is re-delivered — a scenario that `XACK`s every entry never exercises at-least-once and is a LOUD failure. The deep proof (INV1) appends N entries, crash-injects at deterministic points, and asserts every entry was delivered ≥ 1 time (no entry lost) over the **≥100 determinism loop**.
- **Idempotence precondition (D-6 / INV6):** because a re-claimed entry can arrive out of delivery order, the handler MUST be idempotent — handling the same entry twice, or an older entry after a newer one, is safe (the branded id is the dedup key, the BCS newer-wins discipline). This is the consumer's standing precondition.

## US2 — On (re)start the consumer drains its own un-acked backlog first, then reads new (drain-PEL-first)

**As an** event-stream consumer, **I want** a restarted `StreamConsumer` to recover its OWN un-acked entries the instant it restarts — by draining its PEL (`XREADGROUP … 0`) to exhaustion before reading any new entry — **so that** a fast crash-restart re-handles its held work immediately, not "eventually, after the idle threshold and a reclaim beat" (recovery made structural at the consumer's own boundary).

- **Exercises:** EMQ3.3-INV2 (drain-PEL-first then `>`), EMQ3.3-INV1 (the PEL-drain is one of the two re-delivery mechanisms).

```gherkin
Given a StreamConsumer on group "grp" as consumer "c" that read N entries and was KILLED holding them un-acked (they sit in c's PEL)
When the consumer restarts with the SAME name "c"
Then it FIRST reads its own PEL via XREADGROUP GROUP grp c ... 0 to exhaustion (the un-acked backlog)
  And the FIRST entries it handles are its OWN prior un-acked ones (asserted by their branded ids == the killed-but-not-acked entries)
  And only AFTER the PEL is drained does it switch to > (new entries)
When a consumer starts CLEAN (no prior PEL)
Then the 0 read returns empty and it passes straight to > (one code path covers cold start and crash restart)
  And the XAUTOCLAIM beat is ALSO present (a dead PEER's orphaned backlog is recovered by the beat, NOT by this consumer's PEL-drain)
```

- **Liveness (no vacuous pass):** US2 MUST kill a consumer holding genuinely-un-acked entries and assert the restarted consumer handles THOSE branded ids FIRST (before any new tail entry) — a test that restarts a clean consumer proves nothing about the PEL-drain. Both mechanisms (PEL-drain SELF + `XAUTOCLAIM` PEER) MUST be present — the recovery design names two complementary mechanisms, and naming only one under-specifies recovery (§2).

## US3 — The handler is the portable `%{id, payload, attempts, group}` mirror; `attempts` is the delivery-count (the exact mirror)

**As a** consumer author, **I want** the `StreamConsumer` handler to take the EXACT same `%{id, payload, attempts, group}` → `:ok | {:error, reason}` shape as the job `Consumer` — **so that** I write ONE handler discipline across job and stream consumers, with the one field whose meaning differs (`attempts`) SPECCED, not assumed (the stream-side `attempts` is the `XPENDING` delivery-count).

- **Exercises:** EMQ3.3-INV3 (the exact-mirror handler + the NAMED `attempts`↔delivery-count mapping).

```gherkin
Given a StreamConsumer with a handler fun(%{id, payload, attempts, group}) :: :ok | {:error, reason}
When an entry is delivered to the handler
Then the handler map has EXACTLY the keys {id, payload, attempts, group} (byte-identical in SHAPE to EchoMQ.Consumer's handler, consumer.ex:147)
  And `id` is the stored branded record id, `payload` the entry's fields, `group` the consumer-group name
  And `attempts` carries the XPENDING per-entry DELIVERY-COUNT (how many times THIS entry has been delivered), NOT a handler-failure count
When an entry is re-delivered once (a prior un-acked delivery, then a re-claim)
Then the handler sees attempts == 2 (the delivery-count), proven by reading XPENDING's delivery count and asserting it == the handler's attempts
When the handler returns :ok
Then the entry is XACKed (retired from the PEL)
When the handler returns {:error, reason} OR raises
Then the entry is LEFT un-acked (it survives in the PEL → re-deliverable); a raise converts to {:error, reason} and the loop SURVIVES (consumer.ex:148-153)
```

- **Liveness (no vacuous pass):** US3 MUST assert the handler map's exact key set AND assert a re-delivered entry's `attempts` equals the `XPENDING` delivery count (not merely "attempts is an integer") — the NAMED mapping is the whole point of the steward's catch. The raise→survive path MUST kill a handler with a raise and assert the consumer keeps draining (the loop is not crashed).

## US4 — A polyglot reader sees the same group state; the stored `id` field is the canonical receipt (the polyglot seam)

**As a** non-BEAM (polyglot) reader, **I want** to read the SAME consumer group with a stock Redis client and recover the canonical branded receipt from the stored `id` field — **so that** my non-BEAM runtime, holding only the branded `id` field and a stock client, redeems exactly the id the BEAM writer minted, and the BEAM and non-BEAM sides share one group state.

- **Exercises:** EMQ3.3-INV5 (the polyglot seam — the stored `id` field is the canonical receipt a stock client redeems).

```gherkin
Given a stream emq:{q}:stream:s with an entry appended via EchoMQ.Stream.append/4 returning the branded receipt R
  And a consumer group "grp" on the stream
When the entry is read with RAW XREADGROUP GROUP grp c STREAMS key > through the BARE EchoMQ.Connector (no EchoMQ.Stream/StreamConsumer helpers)
Then the entry's stored "id" field equals R (the branded receipt) — a non-BEAM client recovers the canonical id from a stock read
  And a raw XACK key grp <xadd_id> through the bare Connector settles the entry (the BEAM consumer does not re-deliver it)
  And the BEAM and non-BEAM sides share ONE group state (a raw read sees what the BEAM consumer's read leaves, and vice versa)
```

- **Liveness (no vacuous pass):** US4 MUST compare the raw-read entry's stored `id` field to the EXACT branded receipt `append/4` returned (a "polyglot can read the stream" check that never compares the recovered id to the receipt proves nothing); the raw `XACK` MUST be shown to settle the entry against the SAME group the BEAM consumer reads (one group state, not two).

## US5 — The group door is lazy-ensure-on-start: `BUSYGROUP`-only swallow, the start position declared, no destructive verb

**As a** bus operator, **I want** a `StreamConsumer` to ensure its group exists on start (`XGROUP CREATE … MKSTREAM`, swallowing only `BUSYGROUP`) with the start position a DECLARED option — and NO destructive `group_destroy` verb at this rung — **so that** starting a consumer on a group name "just works" (before or after the first event), a real fault (a `WRONGTYPE` key collision) fails LOUD, the replay-vs-tail decision is forced into the open, and a destructive at-rest op is not frozen before the rung that owns it.

- **Exercises:** EMQ3.3-INV4 (the lazy-ensure group door — `BUSYGROUP`-only swallow, the declared start position, no destructive verb).

```gherkin
Given a StreamConsumer.start_link with :queue, :group, :handler, and a DECLARED :group_start option (:new -> $ / :head -> 0)
When the consumer starts and the group does not yet exist
Then it issues XGROUP CREATE <key> <group> <start> MKSTREAM and the group is created (MKSTREAM covers an empty/not-yet-written stream)
When a SECOND consumer starts on the same group
Then the BUSYGROUP reply is SWALLOWED (an idempotent no-op start; restart-storms never error)
When a consumer starts against a key holding a NON-stream type
Then the WRONGTYPE error is NOT swallowed — the consumer fails LOUD (the gate-liveness discipline; only BUSYGROUP is swallowed)
When start_link is called with NO :group_start (or a malformed value)
Then it RAISES at start (the start position is declared, never defaulted — the replay-vs-tail correctness decision is forced into the open)
Then NO group_destroy / XGROUP DESTROY verb exists on EchoMQ.Stream or EchoMQ.StreamConsumer (grep "XGROUP.*DESTROY|group_destroy" lib/ == 0)
```

- **Liveness (no vacuous pass):** US5 MUST exercise the `WRONGTYPE`-is-LOUD path (a start against a non-stream key fails, not silently passes) and the missing-`:group_start`-raises path (the declared option is enforced, not defaulted) — a "group is created" check that never tests the swallow boundary proves nothing about the door's liveness. The no-destructive-verb check is a `grep` over `lib/`.

## US6 — The order theorem holds for the stream but a re-claim re-orders delivery — named, not papered over (the PEL exception)

**As a** maintainer of the bus protocol, **I want** emq3.3's body to NAME exactly where the order theorem continues to hold (the stream stays id-ordered) and where it CANNOT (a re-claimed entry returns out of real-time delivery order) — **so that** the spec is honest about the at-least-once cost and is not the false-green that asserts "order preserved" under a consumer group.

- **Exercises:** EMQ3.3-INV6 (the order-theorem PEL exception, NAMED), EMQ3.3-INV1 (the re-claim is the at-least-once mechanism whose cost this names).

```gherkin
Given the body §1 (the order theorem under a consumer group)
Then it NAMES that XRANGE / XREADGROUP ... > hand NEW entries in mint order (the writer's theorem is untouched — the consumer reads, it does not re-append)
  And it NAMES that a RE-CLAIMED entry (recovered via XAUTOCLAIM or a PEL-drain after newer entries were delivered) returns OUT of real-time delivery order
  And it states WHY it cannot hold (at-least-once re-delivers an older un-acked entry after newer ones — the irreducible cost; exactly-once is NOT claimed, emq.streams.md:89)
When a re-claimed entry is delivered in an integration test
Then its branded id is LOWER than entries already delivered to the same consumer (delivery out of mint order — the exception EXERCISED, not asserted in prose alone)
  And the handler's required idempotence is the consequence (the branded id is the dedup key — handling the same/older entry twice is safe)
```

- **Liveness (no vacuous pass):** US6 MUST EXERCISE the exception (a positive integration assertion that a re-claimed entry's id is lower than already-delivered entries' ids — delivery out of mint order), not merely assert it in prose. A body that asserts "order preserved" under a group is a LOUD failure.

## US7 — The conformance set grows by one (`stream_group`), the prior set byte-unchanged

**As a** maintainer of the bus protocol, **I want** the reader law gated by exactly one new conformance scenario (`stream_group`) registered with its probe, the prior 75 byte-unchanged and the count re-pinned 75→76 — **so that** the protocol's additive-minor law holds (the consumer group is one additive wire capability, the wire unbroken) and the conformance count stays an honest live total; the deep proofs (every-entry-≥1, PEL-first, the ≥100 loop, the polyglot parity) ride the rung suite where depth belongs.

- **Exercises:** EMQ3.3-INV9 (the additive-minor conformance law, +1, 75→76), EMQ3.3-INV1 (the scenario asserts at-least-once + re-delivery).

```gherkin
Given the as-built conformance set with 75 scenarios (conformance_run_test.exs:65 {:ok, 75}; the moduledoc "seventy-five runnable scenarios")
When emq3.3 registers the stream_group scenario in scenarios/0 with its probe in the same change
Then the prior 75 scenarios are byte-unchanged (name + contract + verdict-body identical, git-verified)
  And the count re-pins 75 -> 76 in BOTH pinning tests (conformance_run_test.exs {:ok, 76} + conformance_scenarios_test.exs @run_order gains stream_group after :stream_append)
  And Conformance.run/2 prints 76 lines and returns {:ok, 76} against the truth row (Valkey on 6390)
  And the stream_group scenario is a POSITIVE proof: append → group read → XACK one, LEAVE one un-acked → an idle-window/forced XAUTOCLAIM → assert the SAME entry returns
  And the deep proofs (every-entry-≥1, PEL-first, the ≥100 loop, the polyglot parity) ride property/integration tests (NOT extra conformance rows — D-5)
```

- **Liveness (no vacuous pass):** the `stream_group` scenario MUST run the group round-trip with a POSITIVE proof of re-delivery (an un-acked entry actually re-handed) — a scenario that `XACK`s every entry and asserts nothing about re-delivery is a LOUD failure (the TRD.9.1 false-green class). The count assertion MUST be re-pinned in BOTH pinning tests (a single re-pin leaves the other test red).

## US8 — The wire stays frozen; the label steps a within-family patch; no new Lua

**As a** maintainer of the wire contract, **I want** emq3.3 to add NO new/edited Lua script and touch NO frozen line — `echo_wire` untouched, every shipped `Script.new/2` byte-identical, `@wire_version` frozen, declared-keys vacuous, no grammar edit — and the label to step a within-family patch (`2.6.1` → `2.6.2`) — **so that** the reader law lands additive over a frozen wire (the master invariant: the fork happened once; no later rung re-breaks it).

- **Exercises:** EMQ3.3-INV7 (byte-freeze, `echo_wire` untouched, no new/edited Lua), EMQ3.3-INV8 (declared-keys vacuous, the group state on the `{q}` slot, no grammar edit), EMQ3.3-INV10 (the within-family patch label, the wire frozen).

```gherkin
Given the shipped echo_wire connector + the frozen v2 scripts + the @wire_version echomq:2.4.2
When emq3.3 builds the EchoMQ.StreamConsumer riding the shipped Connector.command/3 on its own lane
Then git diff echo/apps/echo_wire/ is EMPTY (the connector untouched — the consumer rides the shipped path on a private lane)
  And grep -c redis.call on the lib/ diff is 0 (NO new/edited Lua — the group verbs XGROUP/XREADGROUP/XACK/XAUTOCLAIM are issued DIRECT)
  And every shipped Script.new/2 body is byte-identical to HEAD (the @enqueue/@claim/@complete/@sweep_stalled/... constants unchanged)
  And git diff keyspace.ex is EMPTY (the stream key + its server-side group state ride the total queue_key/2 — no grammar edit; declared-keys vacuous)
  And the consumer-group state is server-side stream state on the {q} slot (no new application subkey, no subkey-cleanup obligation)
  And {emq}:version reads echomq:2.4.2 (the @wire_version unchanged)
  And mix.exs reads version: "2.6.2" (a within-family patch — emq3.1 opened 2.6.0, emq3.2 2.6.1)
```

- **Liveness (no vacuous pass):** the byte-freeze checks are git-verified (an empty `echo_wire` diff, a 0 `grep -c redis.call`, byte-identical script constants, an empty `keyspace.ex` diff) — not asserted from prose. A non-empty `echo_wire` diff, any new `redis.call` in the `lib/` diff, a changed `@wire_version`, or any new application subkey is a LOUD failure.

## EMQ3.3-US-GATE — the standing Valkey gate (the rung is not done until the gate is green)

**As the** Operator, **I want** the rung's gate ladder green on the live engine before acceptance — **so that** "the reader law works" is a closure over checks, not a claim.

```gherkin
Given the echo_mq app dir and Valkey on port 6390 (redis-cli -p 6390 ping -> PONG)
When the gate ladder runs (per-app, TMPDIR=/tmp)
Then asdf current erlang matches .tool-versions (re-probed from the app dir, not hardcoded)
  And TMPDIR=/tmp mix compile --warnings-as-errors is clean (the EchoMQ.StreamConsumer)
  And TMPDIR=/tmp mix test --include valkey is green (the :valkey consumer suite: the group drain, the crash/PEL recovery, the XAUTOCLAIM reclaim, the polyglot parity, the order-theorem PEL exception)
  And EchoMQ.Conformance.run/2 prints 76 lines and returns {:ok, 76} on the truth row
  And the ≥100 determinism loop is green: for i in $(seq 1 100); do TMPDIR=/tmp mix test --include valkey || break; done (MANDATORY — a NEW supervised PROCESS + a same-ms mint hazard)
  And git diff echo/apps/echo_wire/ is EMPTY (the connector untouched)
  And the loop OWNS the machine (no concurrent liveness server — a load-gated test forges a failure the rung did not cause)
  And Apollo (MANDATORY, HIGH risk) ran the post-build reconcile + the §11.2 adversarial verification (the order-theorem PEL-exception probe, the recovery-completeness probe, the polyglot-parity probe) before the Director ships
```

- **The determinism posture is HONEST and load-bearing:** unlike emq3.2 (a host fn over the connector, no process), emq3.3 builds a NEW SUPERVISED PROCESS (a `spawn_link` loop holding a private blocking lane + a lease-like PEL recovery) → both the same-millisecond branded-id mint hazard AND a process-timing race are PRESENT → the **≥100 determinism loop is MANDATORY** (one green run is not proof; a same-ms collision or a process-timing race flakes only across runs). **Risk is HIGH; Apollo is MANDATORY.**

---

## Coverage map (every Deliverable → its story → its invariant)

| Deliverable (emq3.3.md Goal) | Story | Invariant(s) |
|---|---|---|
| 1 · the `EchoMQ.StreamConsumer` supervised sibling | US1, US2 | INV1, INV2 |
| 2 · the lazy-ensure group door (`:group_start` declared, no destructive verb) | US5 | INV4 |
| 3 · the loop (drain-PEL-first → `>` → `XAUTOCLAIM` reclaim on the beat) | US1, US2 | INV1, INV2 |
| 4 · the exact-mirror handler + the NAMED `attempts`↔delivery-count invariant | US3 | INV3 |
| 5 · the raw-connector polyglot parity test | US4 | INV5 |
| 6 · the `+1 stream_group` conformance scenario (75→76) | US7 | INV9, INV1 |
| (the order-theorem PEL exception, NAMED) | US6 | INV6 |
| (the recovery design — two complementary mechanisms) | US2 | INV2, INV1 |
| (byte-freeze: `echo_wire` untouched, no new Lua, declared-keys vacuous, the label) | US8 | INV7, INV8, INV10 |
| (the standing Valkey gate + the ≥100 loop + Apollo mandatory) | EMQ3.3-US-GATE | INV1, INV7, INV9, INV10 |

Every Deliverable traces to a story; every story names the invariant(s) it exercises; the body [`emq3.3.md`](emq3.3.md) is authoritative.
