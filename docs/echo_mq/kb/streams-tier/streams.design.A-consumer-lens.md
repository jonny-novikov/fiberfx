# EchoMQ 3.0 — The Stream Tier (emq3.3 → emq3.6) · Design-Ahead — Lens A: Consumer / Operability

> **Lens A — the CONSUMER / OPERABILITY view.** This design argues every fork from the runtime that
> OPERATES and CONSUMES the tier: the codemojex game consumer (mints branded ids, drains per-player
> `EchoMQ.Lanes`, scores under one authority, publishes `EchoMQ.Events`), the polyglot reader (a non-BEAM
> Redis client), and the bus operator. The priorities, in order: at-least-once delivery ergonomics; the
> `StreamConsumer`'s runtime behavior under crash/restart (does a restart lose or double-deliver?); retention
> as an operator-facing knob; the merge-read's latency and correctness for a LIVE consumer; hydration DX. This
> doc CHAMPIONS thin-but-robust + DX-simplicity FOR THE CONSUMER, and honors the Steward part of each arm
> honestly — an arm favored here still carries its true multi-year keep-cost. Each fork pre-empts the
> spec-steward lens's strongest objection.
>
> This is a DESIGN-AHEAD for independent Operator review, authored independently of the sibling lens (it was
> not read). **emq3.3 is the near-term build — its design is build-ready; emq3.4–3.6 shape the horizon** so
> emq3.3's frozen public surface stays forward-compatible. Forks are SURFACED, never decided. NO-INVENT holds:
> every named surface is verified at its source (cited) or written forward-tense for unbuilt surface.

---

## §0 · Context

**What the tier is.** EchoMQ 3.0 — the Stream Tier — adds append-only event streams to the certified wire
under the v2 laws, with no second protocol (`docs/echo_mq/emq.streams.md`). The named demand is small and
explicit: *recorded event streams, a handful of consumer groups per stream, bounded retention, and a polyglot
seam* — game development replays run-window event streams, a non-BEAM client reads the same group, and an
archive carries walk-forward depth. Nothing demands partition fleets, multi-team years-deep retention, or
keyed compaction — this architecture keeps its databases (Tables, the journal, Postgres) *beside* the log
(`emq.streams.md` §"The needs, derived"). The contract is **at-least-once with idempotent handlers** —
exactly-once is NOT claimed (`emq.streams.md` §Seams). Payloads stay **claims-only** so a non-BEAM reader's
codec is trivial.

**What S1 shipped (what emq3.3 stands on, verified as-built).**

- **emq3.1 — the stream-verb floor.** XADD / XRANGE / XREADGROUP / XACK / XAUTOCLAIM (and XGROUP) ride the
  GENERIC `EchoMQ.Connector.command/3` + `pipeline/3` path — the connector is already a verb-agnostic RESP
  client (`echo/apps/echo_mq/test/stream_verbs_test.exs:13`), so the verbs reach the wire with NO connector
  edit and NO new `Script.new/2`. Push-safety is proven only for NON-blocking round-trips: the test carries
  **NO XREADGROUP BLOCK** — the blocking consumer-group read holds the single-owner socket and is explicitly
  deferred to emq3.3 (`stream_verbs_test.exs:22-24`).
- **emq3.2 — the writer law.** `EchoMQ.Stream` (`echo/apps/echo_mq/lib/echo_mq/stream.ex`): `append/4` mints
  an `EVT`-branded record id host-side (`EchoData.Snowflake.next_branded("EVT")`, `stream.ex:79`), stores the
  14-byte branded string as the stream **`id` FIELD** (`stream.ex:100`), and returns `{:ok, branded}` — the
  branded id IS the receipt. `read/3..6` is the minimal un-grouped XRANGE read-back parsing
  `{branded, fields_map}` in mint order (`stream.ex:154-165`). The key is `emq:{q}:stream:<name>` via the
  total `EchoMQ.Keyspace.queue_key(q, "stream:" <> name)` (`stream.ex:172-174`, `keyspace.ex:13-15`).
- **The order theorem (load-bearing for the whole tier).** Stream order == id sort == mint order, proven by
  construction in `EchoMQ.Stream.Id` (`echo/apps/echo_mq/lib/echo_mq/stream/id.ex:28-49`). The A1 mapping
  `xadd_id = "<ms>-<tail22>"` carries the **REAL Unix-ms** (`Snowflake.unix_ms/1`, `snowflake.ex:107`), NOT
  the epoch-relative ts — this is what makes emq3.6's wall-clock `XRANGE` land on the right entries
  (`id.ex:18-22`). The kind door (`Stream.Id.evt?/1`, one brand `EVT`) keeps byte-order ≡ snowflake-order
  sound. **This forward-compatibility was bought at emq3.2 and is the reason emq3.6 is nearly free.**

**The one question the WHOLE tier must answer well, from this lens:**

> When a `StreamConsumer` crashes mid-handler and its supervisor restarts it, does the consumer re-deliver the
> un-acked work it held — exactly once more, never zero, never twice-plus the new tail — without the operator
> wiring a second sweep, a second key, or a second mental model? And does a polyglot reader, holding only the
> branded `id` field and a stock Redis client, see the same group state the BEAM consumer sees?

Every fork below is ranked by how cleanly its winning arm answers that question for the runtime that operates
the tier — at-least-once that is *boring to operate*, crash recovery that is *automatic and visible*, and a
polyglot seam that is *a stock client away*. The settled emq3.3 decisions (a NEW sibling `StreamConsumer`,
crash re-delivery folded into the beat, a raw-connector parity test) are exactly the answers this lens would
have argued for — this design builds to them.

---

## §emq3.3 · S2 the readers — the BEAM consumer group + the polyglot seam (BUILD-READY)

**The rung's job.** Ship a BEAM consumer group beside a non-BEAM reader on the same group: at-least-once
delivery with idempotent handlers, crash → `XAUTOCLAIM` re-delivery, and a proven polyglot seam. This is the
near-term build; its public surface freezes here and must anticipate emq3.5's fold and emq3.6's hydration.

**The SETTLED decisions this rung carries (Operator-ruled this session — GIVEN, not re-litigated; the design
builds to them):**

1. **S-1 — the consumer is a NEW SIBLING module `EchoMQ.StreamConsumer`** (beside `EchoMQ.Consumer`, holding
   a private connector lane, reading via `XREADGROUP GROUP … >`). NOT an extension of the job `Consumer`. This
   mirrors the shipped sibling precedent `EchoMQ.BatchConsumer` (`batch_consumer.ex:10-16`: a DIFFERENT claim
   path and handler contract earns a sibling, not a mode).
2. **S-2 — crash re-delivery is FOLDED INTO the consumer's own beat.** Each `StreamConsumer` reclaims entries
   idle past a min-idle threshold via `XAUTOCLAIM` on its cadence — mirroring the job `Consumer`'s
   reap-expired-leases beat (`consumer.ex:116`, `Jobs.reap`). No separate sweep module. (This GIVEN settles
   F-old "fold-vs-separate-sweep" — the `EchoMQ.Stalled` separate-sweep precedent, `stalled.ex`, is
   weighed-against and NOT taken for the stream consumer.)
3. **S-3 — the polyglot seam is proven by a RAW-CONNECTOR PARITY TEST in-suite:** read the same group with raw
   `XREADGROUP`/`XRANGE` through the bare `Connector` (no `EchoMQ.Stream` helpers), asserting the stored `id`
   field is the canonical receipt a non-BEAM client redeems.

These three GIVENs answer the tier's load-bearing question structurally. The open forks below decide HOW the
sibling behaves at its edges.

### F3.3-A — the XGROUP lifecycle: lazy ensure-on-start vs an explicit `group_create` surface

**Arm A1 — lazy ensure-on-StreamConsumer-start.** On `StreamConsumer.start_link`, the consumer issues
`XGROUP CREATE <key> <group> $ MKSTREAM` (or `0` for from-the-start) and swallows the `BUSYGROUP` reply, so a
group exists by the time the first `XREADGROUP` runs — no separate declare call.

- *Rationale.* The consumer is the only thing that needs the group to exist; binding group creation to its
  own start makes the group a property of "a consumer is running," which is exactly when it matters. The
  operator wires one thing (start the consumer) and the group is there.
- *5W.* **Why** — a group that must be declared before a consumer starts is a second wiring step the operator
  forgets, and the failure (an `XREADGROUP` against a missing group) is a runtime error, not a start error.
  **What** — an idempotent `XGROUP CREATE … MKSTREAM` swallowing `BUSYGROUP`, run once at consumer start.
  **Who** — the bus operator and the codemojex consumer author, who start a consumer and expect it to work.
  **When** — emq3.3, at `start_link`. **Where** — inside `EchoMQ.StreamConsumer.init/start_link`
  (forward-tense; the module does not yet exist), riding `Connector.command/3` (the generic path,
  `stream_verbs_test.exs:13`).
- *Steelman.* The shipped consumers already self-provision their runtime preconditions: `EchoMQ.Consumer`
  self-starts its connector lane when given `:connector` opts (`consumer.ex:64-67`); `EchoMQ.BatchConsumer`
  does the same (`batch_consumer.ex:101-104`). Lazy-ensure extends that "the process owns its preconditions"
  discipline to the group. `MKSTREAM` means the consumer works against a stream that does not yet exist (the
  game starts the reader before the first event is appended) — a real ordering the consumer author hits on day
  one. `BUSYGROUP` is a documented, swallow-able idempotency signal (valkey.io XGROUP), so re-start is safe by
  construction. The operator's mental model collapses to one verb: *run a StreamConsumer on a group name*.
- *Steward.* The keep-cost: the swallow is a string-match on the `BUSYGROUP` reply (the same shape
  `EchoMQ.Stream` already maintains for the `:nonmonotonic` `@id_too_small` match, `stream.ex:61`) — one
  fragile-on-engine-message-text surface to freeze and re-verify on a Valkey line bump. It hides the
  from-where decision (`$` vs `0`) inside start opts, which must be specced as a declared option, not a
  default, or two consumers on one group silently disagree on the start position. It composes cleanly with the
  frozen wire (no new key, no Lua, no grammar edit — the group lives with the stream the §6 braced key already
  founds, `stream.ex:42`).

**Arm A2 — an explicit `group_create/…` surface on `EchoMQ.Stream`.** `EchoMQ.Stream.group_create(conn,
queue, name, group, opts)` is a first-class declare verb; the consumer assumes the group already exists and
errors loudly if not.

- *Rationale.* Group creation is a deliberate administrative act with a from-where decision (`0` vs `$` vs an
  explicit id); making it an explicit surface puts that decision where the operator can see and review it,
  rather than buried in consumer start opts.
- *5W.* **Why** — the start position of a group is a correctness decision (replay-from-zero vs tail-only) that
  deserves a named home, not a default. **What** — a `group_create/5` writer-side verb on `EchoMQ.Stream`
  (forward-tense), symmetric with `append/4`. **Who** — the operator who provisions a stream's groups before
  any consumer runs; an ops runbook. **When** — emq3.3. **Where** — `EchoMQ.Stream` (`stream.ex`), beside
  `append`/`read`.
- *Steelman.* The from-where decision is load-bearing and irreversible per-group: a group created at `$`
  silently skips all history before its creation, which for a replay-oriented game consumer is a data-loss
  footgun the lazy arm hides in an option default. An explicit surface forces the author to state it. It also
  gives the polyglot side a named Elixir-side counterpart to point documentation at (the non-BEAM reader does
  `XGROUP CREATE` raw; the BEAM side has the same verb spelled out). It keeps the consumer's `start_link`
  smaller — the consumer reads, it does not provision.
- *Steward.* The keep-cost is a public verb frozen forever, plus the operator-burden of remembering to call it
  before the consumer (the exact second-wiring-step that A1 removes). It splits "run a consumer" into two
  acts, and the failure mode of forgetting act one is a runtime `NOGROUP` error against a live consumer — the
  worst time to discover it. It does compose well with emq3.5 (the archive fold is itself a consumer that
  needs a group; an explicit verb gives the fold a clean provisioning call).

**Ranked recommendation (Lens A): A1 (lazy ensure-on-start), with the from-where as a DECLARED, non-defaulted
start option.** For the runtime that operates the tier, one wiring step that cannot be forgotten beats a named
verb that can. The game consumer's day-one experience is "start a StreamConsumer on a group name and it
works, before or after the first event" — `MKSTREAM` + `BUSYGROUP`-swallow delivers exactly that. The
from-where footgun the A2 steelman raises is real, so this lens does NOT take A1's convenience as license to
default it: the start position is specced as a **declared option** (`:from`, no default — the consumer
`raise`s at start if it is absent), so the correctness decision is forced into the open WITHOUT a second
verb. A1's per-consumer ensure is also strictly better for emq3.5: the archive fold (itself a consumer) gets
its group for free at its own start, with no provisioning order to coordinate.

> **Pre-empted spec-steward objection:** *"Lazy-ensure puts a one-time administrative side effect (group
> creation) inside a hot start path, and the `BUSYGROUP` string-swallow is a frozen-forever brittleness on
> engine message text — an explicit verb keeps the side effect out of the consumer and the contract clean."*
> Answer: the side effect is idempotent and runs exactly once per consumer start (not per beat), so it is not
> a hot path; and the brittle-string surface is identical in COUNT either way (raw `XGROUP CREATE` returns
> `BUSYGROUP` whether a verb or the consumer issues it) — A1 does not ADD a frozen string, it co-locates the
> one that already exists with the only caller that needs it. The "declared `:from` option" requirement
> imports the steward's correctness concern into A1 without importing A2's second wiring step.

### F3.3-B — the (re)start read mode + the handler contract

**Arm B1 — drain own PEL first (`XREADGROUP … 0`), THEN read new (`>`); handler contract mirrors the job
`Consumer` EXACTLY.** On (re)start, the consumer first reads its own Pending Entries List with
`XREADGROUP GROUP g c 0` (the un-acked backlog it held when it died), settles each, and only then switches to
`>` for new entries. The handler is `fun(%{id, payload, attempts, group}) :: :ok | {:error, reason}` —
byte-identical to the job `Consumer`'s contract (`consumer.ex:40-41`, `consumer.ex:147`).

- *Rationale.* A crashed consumer's un-acked entries sit in its PEL keyed to its consumer NAME; on restart
  with the same name, `XREADGROUP … 0` returns exactly that backlog. Draining it FIRST is what makes crash
  re-delivery *immediate and local* — the consumer recovers its own work before it touches new work, the same
  shape the job `Consumer` recovers leases on its beat (`consumer.ex:116`).
- *5W.* **Why** — at-least-once means the entries a consumer held when it died MUST be re-delivered; the PEL
  is where they live, and `0` is how a stock client reads them. **What** — a PEL-first then tail read mode
  on (re)start; a handler contract identical to the job consumer's. **Who** — the codemojex consumer author,
  who writes ONE handler shape and runs it under both the job loop and the stream loop. **When** — emq3.3,
  every start (a fresh start has an empty PEL → `0` returns nothing → straight to `>`, so the same code path
  covers cold start and crash restart). **Where** — `EchoMQ.StreamConsumer` loop (forward-tense), mirroring
  `EchoMQ.Consumer.drain/1` (`consumer.ex:137-165`).
- *Steelman.* This is the single most consumer-friendly decision in the tier. **PEL-first** makes crash
  recovery automatic and complete on the consumer's OWN beat with no separate sweep (it directly realizes
  settled-decision S-2's spirit at the read-mode level, complementing the `XAUTOCLAIM` reclaim of OTHER dead
  consumers' entries). **Handler-identical** means a game handler written once — `fn %{id:, payload:,
  attempts:, group:} -> :ok end` — runs unchanged whether the work arrives as a job or a stream entry; the
  rescue/catch discipline that converts a raise to `{:error, reason}` and survives the loop is already proven
  in `consumer.ex:147-153` and `batch_consumer.ex:225-233`. The `attempts` field maps cleanly to the entry's
  XPENDING delivery-count (the number of times this entry has been delivered), so the handler's
  poison-detection logic ("attempts ≥ N → route elsewhere") is portable verbatim from the job side. For a
  polyglot reader, PEL-first is the natural stock-client recovery idiom (`XREADGROUP … 0` then `>`), so the
  BEAM and non-BEAM sides recover identically — which is exactly what S-3's parity test asserts.
- *Steward.* The keep-cost is a frozen handler contract shared across two consumers — a real liability, since
  a future change to the job consumer's handler map (a new field) now ripples to the stream consumer or
  forks the two. But the field set is small and stable (`id`/`payload`/`attempts`/`group`), and sharing it is
  cheaper to keep than two divergent contracts the consumer author must hold in mind. PEL-first adds a
  two-phase read on every start; the cost is one extra round-trip at start (negligible — start is rare). The
  `attempts`-from-delivery-count mapping must be specced precisely (XPENDING's count is delivery count, not
  handler-failure count — they differ when a handler acks-then-the-process-dies; the spec must state which
  the `attempts` field carries, or the poison threshold is mis-calibrated). It composes cleanly with the
  frozen wire (no new key — the PEL is the group's own state, server-side).

**Arm B2 — tail-only on (re)start (`>` always); lean on `XAUTOCLAIM` for ALL re-delivery; a stream-specific
handler contract.** The consumer always reads `>`; un-acked entries (its own included) are recovered ONLY by
the `XAUTOCLAIM` reclaim beat (S-2). The handler may carry stream-specific fields (e.g. the raw `xadd_id`, the
group name as a richer struct) rather than mirroring the job consumer.

- *Rationale.* One read mode (`>`) is simpler to reason about than two; `XAUTOCLAIM` already must exist for
  recovering OTHER dead consumers' entries (S-2), so routing a consumer's OWN backlog through the same
  mechanism collapses re-delivery to one path.
- *5W.* **Why** — a single recovery mechanism (the reclaim beat) is one thing to test and operate, not two
  (PEL-drain + reclaim). **What** — always-`>` reads; recovery solely via `XAUTOCLAIM`; a handler contract
  free to diverge toward stream-native fields. **Who** — the bus operator who wants one recovery story.
  **When** — emq3.3. **Where** — `EchoMQ.StreamConsumer` (forward-tense).
- *Steelman.* Collapsing all re-delivery to `XAUTOCLAIM` means crash recovery has exactly ONE code path,
  exercised by both self-crash and peer-crash — a smaller surface to gate, and the min-idle threshold becomes
  the single tunable for "how fast is re-delivery." A stream-native handler can expose the raw `xadd_id` (the
  wire position) which a stream-aware consumer may want for cursor bookkeeping, unconstrained by the job
  consumer's legacy map.
- *Steward.* The keep-cost is a RE-DELIVERY LATENCY the operator must reason about: a consumer's own backlog
  is now invisible until min-idle elapses AND a reclaim beat fires, so a fast crash-restart cycle re-delivers
  its own held work strictly LATER than B1 (which drains it at start). For a low-latency game consumer that
  restarts in milliseconds, B2 holds the player's un-scored events hostage to the idle threshold — the exact
  operability cost this lens weights against. A divergent handler contract is a permanent DX tax: the consumer
  author now writes two handler shapes and cannot port one to the other, doubling the surface every future
  field-add must touch.

**Ranked recommendation (Lens A): B1 (PEL-first, handler-identical) — decisively.** This is the fork where
this lens diverges hardest toward the consumer. PEL-first makes a consumer recover its OWN un-acked work
*the instant it restarts*, not "eventually, after min-idle + a beat" — for a game consumer that crash-restarts
fast, that is the difference between a player's events being re-scored in milliseconds versus seconds.
Handler-identical means ONE handler shape across job and stream consumers, the single biggest DX multiplier in
the tier: a codemojex author's existing `fn %{id:, payload:, attempts:, group:} -> … end` runs unchanged.
`XAUTOCLAIM` still does its job (S-2) for entries held by OTHER dead consumers — B1 and the reclaim beat are
complementary, not alternatives: PEL-first recovers SELF, the reclaim beat recovers PEERS.

> **Pre-empted spec-steward objection:** *"A handler contract shared across two consumers is a freeze that
> ages badly — the job consumer and the stream consumer have genuinely different lifecycle semantics
> (a job has a lease and a retry count; a stream entry has a delivery count and an ack), and forcing one map
> over both invites a leaky abstraction where `attempts` means different things on each side."* Answer: this
> is the one place the steward objection has real teeth, and the spec must answer it precisely rather than
> waving it away — the `.md` body fixes that `attempts` carries the **XPENDING delivery count** on the stream
> side (named, not assumed), and an invariant asserts the two consumers' handler maps are byte-identical in
> SHAPE while documented as semantically-aligned-not-identical in the `attempts` field. The DX win of one
> portable handler is worth pinning the one field whose meaning differs; the alternative (B2's divergence)
> pays the leaky-abstraction cost in full AND loses portability. The contract is frozen either way — B1
> freezes the GOOD one.

### F3.3-C — the conformance grain: +1 capability vs +N decomposition

**Arm C1 — +1 conformance scenario (`stream_group`), deep proofs ride property/loop tests.** Add ONE
conformance scenario covering the group capability at the contract level (append → group read → ack →
re-deliver), and prove the depth (at-least-once exactness, crash→reclaim, PEL-first, polyglot parity) in
dedicated property and integration tests OUTSIDE the conformance set.

- *Rationale.* Conformance is the wire-contract registry, not the test suite; one scenario asserting "a
  consumer group on this wire delivers at-least-once and re-claims on crash" is the additive registration the
  S-3 law wants, and the exhaustive proofs belong in tests that can loop and generate without bloating the
  frozen registry. This mirrors emq3.2's D-3 ("+1, deep proofs ride property/loop").
- *5W.* **Why** — the conformance count is a frozen-forever contract surface (`conformance.ex`, 18 as-built
  per `.claude/skills/echo-mq-program.md`; the live count must be re-probed at the reconcile); each scenario
  is a permanent keep-cost, so granularity should match wire CAPABILITIES, not test cases. **What** — one new
  scenario `stream_group` (or similar), probe-registered, prior set byte-unchanged, count re-pinned in both
  pinning tests. **Who** — the conformance maintainer and any polyglot implementer reading the registry as the
  capability list. **When** — emq3.3. **Where** — `EchoMQ.Conformance.scenarios/0` (`conformance.ex`).
- *Steelman.* The shipped precedent is consistent and deliberate: capability-grained additive scenarios
  (emq.5.1's D-3 added +3 for THREE distinct capabilities — batch_claim, batch_claim_short,
  batch_partial_failure — each a separate wire-observable behavior, per the program memory). One stream-group
  capability → one scenario keeps the registry a clean capability map a polyglot author can read as "what this
  wire promises." The deep at-least-once and crash proofs are property-shaped (generate N entries, kill at
  random points, assert every entry delivered ≥1 time) and loop-shaped (≥100 for the process/lease hazard) —
  forms conformance scenarios cannot take. Keeping them OUT of conformance keeps the registry small and the
  proofs strong.
- *Steward.* The keep-cost is one scenario, the cheapest arm. The risk: under-granularity could hide a real
  sub-capability the polyglot side needs to see registered (e.g. if "crash re-delivery" is a distinct wire
  promise a non-BEAM reader must rely on, it may deserve its own registered scenario so the registry documents
  it). The arm must name WHICH behaviors are deep-proof-only vs registry-visible, or a polyglot implementer
  reads an incomplete contract.

**Arm C2 — +N decomposition (group-lifecycle, at-least-once-ack, crash→reclaim, polyglot-parity each a
scenario).** Add a scenario per behavior, so the conformance registry enumerates every stream-group promise.

- *Rationale.* Each behavior is a distinct wire-observable promise a polyglot reader relies on; registering
  each makes the contract self-documenting and gives every behavior a named gate.
- *5W.* **Why** — a polyglot implementer trusts the conformance registry as the spec of the wire; four
  promises → four entries leaves nothing implicit. **What** — +4 scenarios. **Who** — the polyglot
  implementer. **When** — emq3.3. **Where** — `conformance.ex`.
- *Steelman.* Maximum legibility: crash→reclaim re-delivery is exactly the kind of cross-runtime promise a
  non-BEAM reader builds on, and a registered scenario is the contract that promise lives in. Decomposition
  front-loads the documentation cost where it is cheapest (at authoring) rather than leaving a polyglot author
  to infer behaviors from property tests they cannot see.
- *Steward.* +4 frozen scenarios is +4 permanent keep-costs, each byte-frozen forever and re-pinned on every
  future count change. It risks conformance bloat — scenarios that restate what one capability scenario plus a
  property test already prove, paying registry weight for documentation that a `.stories.md` could carry more
  cheaply. The grain drifts from "capabilities" toward "test cases," which the emq.5.1/emq3.2 precedent
  deliberately avoided.

**Ranked recommendation (Lens A): C1 (+1 capability, deep proofs ride property/loop) — with the deep-proof
manifest explicit.** The consumer that READS the registry is the polyglot implementer, and a clean
capability-grained registry serves that reader better than a bloated case-grained one: "this wire offers a
consumer group with at-least-once and crash re-delivery" is one promise to read and implement against. The
exhaustive proofs (every-entry-delivered-≥1, PEL-first recovery, ≥100 process loop) are property/loop-shaped
and belong outside the frozen registry. To answer C2's real concern, the rung's `.stories.md` names the
deep-proof manifest (which property/integration test proves which behavior), so a polyglot author has a
documented map even though the registry stays +1. Re-probe the live conformance count at the reconcile before
pinning (the as-built count drifts; `.claude/skills/echo-mq-program.md` flags it as 18, but the emq3 rungs
may have grown it — verify against `conformance.ex`).

> **Pre-empted spec-steward objection:** *"Crash re-delivery and polyglot parity are CROSS-RUNTIME wire
> promises — exactly the contracts conformance exists to freeze; burying them in property tests a non-BEAM
> implementer cannot run leaves the wire under-specified at the registry level."* Answer: agreed that the
> PROMISE must be registry-visible — C1 registers it (the one `stream_group` scenario asserts at-least-once +
> reclaim at the contract level, so the registry DOES document the cross-runtime promise). What rides
> property/loop tests is the EXHAUSTIVE PROOF of that promise (kill-at-random-point, ≥100 determinism), which
> is a stronger form than a single scenario and is not something a polyglot implementer re-runs anyway — they
> implement against the registered promise + the `.stories.md` Given/When/Then, both of which C1 keeps
> complete. The grain is "one capability, one scenario, deep proof beside it" — the precedent the program
> already chose twice.

---

## §emq3.4 · Retention as policy — declared, not defaulted

**The rung's job.** Per-stream `MAXLEN` (approx) and mint-time `MINID` retention windows, declared not
defaulted; a read inside the window never misses, outside it answers truthfully (`emq.streams.md` ladder
row emq3.4). This is the operator-facing knob the tier promises.

### F3.4-A — WHERE the trim lives: trim-on-append vs a dedicated retention surface vs the consumer's beat

**Arm A1 — trim-on-append (the writer trims each `XADD` with `MAXLEN ~`).** `EchoMQ.Stream.append/4` gains an
optional retention policy; each `XADD` carries `MAXLEN ~ <n>` (or `MINID ~ <id>`), so the stream self-bounds
on every write.

- *Rationale.* The cheapest correct retention is the one the engine applies at write time: `XADD … MAXLEN ~`
  trims inline with no extra round-trip and no separate process, and the stream is never larger than its
  window for more than one entry.
- *5W.* **Why** — retention that rides the write needs no second mechanism to schedule, supervise, or fail.
  **What** — an optional `MAXLEN ~`/`MINID ~` argument threaded into the `append` XADD parts
  (`stream.ex:100`, forward-tense extension). **Who** — the writer (the codemojex producer) declares the
  window once at the append site; the operator reads it there. **When** — emq3.4. **Where** —
  `EchoMQ.Stream.append/4`/`append_batch/4` (`stream.ex`).
- *Steelman.* For the operator, trim-on-append is the most boring retention possible: no Streamer to crash, no
  beat to tune, no key to GC — the window is a property of the write and is enforced continuously, so the
  stream's resident memory is bounded by construction at all times (not "eventually, after the next sweep").
  `MAXLEN ~` (approximate) is the documented cheap form (valkey.io XADD — approximate trimming bounds work to
  whole macro-nodes), so the cost is near-zero per append. It composes perfectly with the order theorem: trim
  drops the OLDEST entries (lowest ids), which are exactly the ones already folded to the archive in emq3.5,
  so the trim watermark and the fold watermark are the same monotone id frontier.
- *Steward.* The keep-cost: the policy now lives at every append site, so it can be declared inconsistently
  (two writers to one stream with different `MAXLEN` values fight). The spec must make the policy a per-STREAM
  declared fact, not a per-CALL argument, or the window is non-deterministic (this is exactly F3.4-B). It also
  couples the writer to retention — `EchoMQ.Stream` was deliberately a thin no-trim router at emq3.2
  (`stream.ex:50-52` states "`append/_` does not trim"), so this arm reverses a stated emq3.2 boundary, which
  the spec must own explicitly.

**Arm A2 — a dedicated `EchoMQ.Stream` trim/retention surface (`trim/4`).** A first-class
`EchoMQ.Stream.trim(conn, queue, name, policy)` verb the operator (or a scheduled process) calls; `append`
stays trim-free.

- *Rationale.* Trimming is an operational act distinct from appending; a named verb gives the operator an
  explicit, callable, reviewable retention surface and keeps the writer the thin router emq3.2 froze.
- *5W.* **Why** — retention is the operator's knob, and a knob deserves a named verb the operator turns, not a
  side effect of someone else's write. **What** — `EchoMQ.Stream.trim/4` wrapping `XTRIM <key> MAXLEN ~ <n>`
  / `MINID ~ <id>` (forward-tense). **Who** — the bus operator, an ops runbook, or a scheduled trim process.
  **When** — emq3.4. **Where** — `EchoMQ.Stream` (`stream.ex`), beside `append`/`read`.
- *Steelman.* Keeps emq3.2's writer boundary intact (`append/_` does not trim, byte-frozen). Gives the
  operator a one-shot manual retention act for incident response ("trim this runaway stream now") that
  trim-on-append cannot offer. The `XTRIM` verb is the natural home for `MINID` by mint-instant (the operator
  trims "everything before this DateTime" by mapping the instant to a `MINID` via `Snowflake.min_for/1`,
  `snowflake.ex:116` — a real surface). It composes with emq3.5's fold as the SAME verb the fold path calls
  after a segment is durably folded.
- *Steward.* The keep-cost is a public verb PLUS the unsolved scheduling question: a manual `trim` verb that
  nobody calls on a cadence does not bound memory — so this arm alone needs a SECOND decision (who calls it,
  how often), which is the consumer-beat arm A3 or an operator's cron. It risks the worst operability outcome:
  a retention surface that EXISTS but is not WIRED, so the operator believes retention is on when nothing
  enforces it. The spec must pair the verb with a wired caller or the window is a promise nothing keeps.

**Arm A3 — the consumer's beat trims.** A `StreamConsumer` (or the archive-fold consumer) trims on its
cadence, after folding/acking, the same way the job `Consumer` reaps on its beat (`consumer.ex:116`).

- *Rationale.* A consumer already runs a beat and already knows the stream's progress (what it has acked /
  folded); folding the trim into that beat means retention rides the process that is already running and
  already at the right watermark, with no new process.
- *5W.* **Why** — the consumer's beat is the natural cadence for "drop what is past the window AND already
  consumed," and it is the watermark-aware caller emq3.5's fold needs. **What** — a trim step in the
  `StreamConsumer` / archive-fold beat (forward-tense), gated on the declared policy. **Who** — the operator
  who runs a consumer; the trim is automatic. **When** — emq3.4 (the trim step) coordinated with emq3.5 (the
  fold-then-trim watermark). **Where** — `EchoMQ.StreamConsumer` beat (forward-tense).
- *Steelman.* This is the arm that makes retention AND the archive fold ONE coherent operation: the fold
  consumer folds a segment to Graft, confirms it durable, THEN trims exactly that slice (`MINID` = the
  fold watermark) — so the trim can NEVER outrun the fold, closing the emq3.5 gap-or-overlap question by
  construction (this is the load-bearing forward link to F3.5-B). It rides the beat the consumer already
  runs (no new process, the `Consumer.reap`-on-beat shape), and the watermark is the consumer's own acked/
  folded frontier, so the trim is watermark-correct without a separate bookkeeping key.
- *Steward.* The keep-cost: retention is now coupled to a consumer RUNNING — a stream with no consumer (a
  pure fire-and-forget event log nobody drains) never trims, which for some operator use cases is a
  surprise (the trim-on-append arm bounds even an un-consumed stream). The spec must name that coupling: "a
  retention window is enforced by a running consumer; an un-consumed stream is bounded only by trim-on-append
  or a manual trim." It composes best of all three with emq3.5 but worst with the un-consumed-stream case.

**Ranked recommendation (Lens A): A3 (consumer-beat trim) as the PRIMARY mechanism, with A2 (`trim/4` verb)
as the operator's manual escape hatch — and A1 weighed-against for un-consumed streams.** From the operability
lens, the winning property is that retention and the archive fold are ONE watermark-correct operation: the
fold consumer folds, confirms durability, then trims exactly the folded slice, so retention can never drop
un-archived data (the emq3.5 safety the operator most needs). A3 delivers that. A2's `trim/4` verb ships
alongside as the manual incident-response surface (the operator's "trim now" button) AND as the exact verb
A3's beat calls internally — so A2 is not an alternative but the public face of A3's mechanism. A1
(trim-on-append) is the right answer for a stream NO consumer drains, but it reverses emq3.2's frozen writer
boundary and risks dropping data ahead of the fold — so this lens parks it as an explicit OPT-IN for the
un-consumed-stream case, named in the spec, not a default. **This is a fork where this lens expects to
diverge:** a spec-steward lens may prefer A1's by-construction continuous bound (simpler invariant, no
process-coupling) over A3's beat-coupled enforcement.

> **Pre-empted spec-steward objection:** *"Consumer-beat trimming couples a SAFETY property (bounded memory)
> to a LIVENESS property (a consumer running) — a frozen invariant should not depend on a process being up;
> trim-on-append bounds the stream by construction with no liveness dependency and a smaller invariant
> surface."* Answer: the coupling is precisely what makes the fold safe (the trim cannot outrun the fold
> because the same beat does both, in order) — decoupling them (A1 trims on append, the fold runs separately)
> reintroduces the gap/overlap race emq3.5 must avoid, trading a clean invariant for a data-loss window. The
> spec answers the steward's liveness concern by NAMING the un-consumed-stream case (A1 as a declared opt-in
> for streams with no draining consumer), so the bounded-by-construction property is available where it is
> actually needed WITHOUT defaulting every consumed stream to a fold-racing trim. The invariant is "a folded
> slice is trimmed only after it is durable" — which is a SAFETY invariant A3 keeps and A1 cannot state.

### F3.4-B — the policy DECLARATION surface + approx vs exact

**Arm B1 — a registered per-stream policy map (declared at stream first-use / consumer start).** Retention is
a per-stream policy registered once (a `%{maxlen: n}` / `%{minid_age: duration}` map), keyed by stream name,
read by whatever applies the trim — `MAXLEN ~` approximate by default.

- *Rationale.* "Declared not defaulted" (`emq.streams.md` emq3.4 row) means the window is a named per-stream
  fact, registered in one place, not re-stated at every call — one authority for the window, read consistently
  by the writer, the trim verb, and the fold.
- *5W.* **Why** — a window declared once per stream cannot be declared inconsistently by two callers (the
  F3.4-A/A1 footgun). **What** — a per-stream policy registry (forward-tense; an Elixir-side map or a Keyspace
  policy key); `MAXLEN ~` approx the documented default, exact (`MAXLEN` without `~`) an opt-in. **Who** — the
  operator declares it; every trim caller reads it. **When** — emq3.4. **Where** — a new policy surface on
  `EchoMQ.Stream` (forward-tense).
- *Steelman.* One authority for the window is the DRY discipline the whole program holds (`venus.md`: "the
  duplicate is the drift surface"). For the operator, one place to read and change retention beats hunting
  every append site. `MAXLEN ~` approximate as the default is the right operability choice: it bounds work to
  whole macro-nodes (valkey.io XADD/XTRIM — approximate trimming is the documented cheap form), so trimming
  never spikes latency on a hot stream; the operator opts into exact only when a compliance window demands
  the precise boundary. `MINID` by mint-instant rides `Snowflake.min_for/1` directly (`snowflake.ex:116`,
  verified) — the operator declares "keep 7 days" and the trim maps `now - 7d` to a `MINID` bound.
- *Steward.* The keep-cost is a new policy surface frozen forever, plus the where-does-it-live question (an
  Elixir-side ETS/registry map is lost on restart; a Keyspace policy key, `emq:{q}:stream:<name>:policy`,
  outlives restart but adds a §6 subkey whose CLEANUP disposition must be named — per the architect skill's
  subkey-cleanup law, a new subkey absent from `obliterate`'s fixed list leaks at rest). The spec MUST name
  the policy key's cleanup. Approx-by-default means a read just inside the window can occasionally see a few
  entries the operator expected trimmed (approximation slack) — honest, and the `.stories.md` must state "the
  window is approximate; a read inside it never MISSES, a read just outside may briefly still SEE" so the
  operator's expectation is calibrated.

**Arm B2 — a per-call argument (the policy is an argument to `append`/`trim`).** The window is passed at each
trim/append call; no registry.

- *Rationale.* The simplest mechanism — no new state, no policy key, the caller states the window where it
  acts.
- *5W.* **Why** — no registry is no new frozen surface and no subkey-cleanup question. **What** — a `policy`
  argument on the trim/append verb. **Who** — the caller. **When** — emq3.4. **Where** — the verb's args.
- *Steelman.* Zero new persistent surface, nothing to GC, nothing to keep coherent across restart — the
  policy is wherever the call is. For a single-writer stream (the order theorem's posture — one writer per
  stream, `stream.ex:30`), there is exactly one append site, so "declared at the call" IS "declared once."
- *Steward.* The keep-cost is the inconsistency footgun the whole "declared not defaulted" requirement exists
  to avoid: nothing stops two callers (the writer's append, the operator's manual trim, the fold's trim) from
  passing different windows, and the resulting window is the last-writer's — non-deterministic and
  un-reviewable. It violates One authority directly. For the operator, there is no single place to READ the
  current retention of a stream — it is scattered across call sites.

**Ranked recommendation (Lens A): B1 (registered per-stream policy), `MAXLEN ~` approx default, exact
opt-in, `MINID`-by-mint-instant via `Snowflake.min_for/1` — with the policy persisted in a Keyspace policy
key whose cleanup is named.** The operator needs ONE place to read and change a stream's retention; a
per-stream registry is that place, and approx-by-default keeps trimming cheap on hot streams (the right
operability default). The `.stories.md` calibrates the approximation honestly ("never misses inside, may
briefly still see just outside"). Per the architect skill's subkey-cleanup law, the policy key's retirement is
NAMED in the spec (folded into `obliterate`'s enumeration, or a stated deferral), not discovered as an at-rest
leak.

> **Pre-empted spec-steward objection:** *"A per-stream policy KEY is a new §6 subkey that outlives its
> primary entity and adds an at-rest cleanup obligation the gate cannot catch — a per-call argument adds no
> persistent surface at all, and for a single-writer stream it is already declared-once."* Answer: the
> single-writer posture covers the APPEND site, but emq3.4–3.5 add OTHER trim callers (the manual `trim/4`
> verb, the fold's beat), so "one append site" stops being "one policy site" the moment retention has more
> than one enforcer — which it does by emq3.5. A registry is the only One-authority answer once trimming has
> multiple callers. The subkey-cleanup concern is real and is exactly why this recommendation NAMES the
> policy key's retirement in the spec (the architect-skill discipline) rather than discovering it — the
> steward's own at-rest-leak rule is satisfied by construction, not waved away.

---

## §emq3.5 · The archive — fold trimmed segments into the native Graft engine (HIGHEST stakes)

**The rung's job.** A group consumer folds trimmed stream segments into the native `EchoStore.Graft` engine
(CubDB → Tigris); deep reads = segment + live-tail merge (`emq.streams.md` emq3.5 row). **The COEXIST law
binds: the native `EchoStore.Graft.*` engine is the CANONICAL engine and is UNTOUCHED — the fold CONSUMES it
as a peer, never edits it** (`docs/echo_mq/store/design/store.design.md` §0; the cross-runtime COEXIST ruling
in the program memory).

**The COEXIST surface (verified, the fold consumes these as a peer):** `EchoStore.Graft.open_volume/2`
(`graft.ex:30`), `EchoStore.Graft.read/2` + `read_at/3` (lock-free reads, `graft.ex:47-56`),
`EchoStore.Graft.VolumeServer.begin/1` → `commit/3` (the single-writer mailbox write path — a page map,
`volume_server.ex:40-50`), the `Streamer` Tigris push (`streamer.ex`, real-time upload per
`store.design.md` §3), the `EchoData.Graft.Segment` struct (`segment.ex:20`, fields
`id/lsn/pages/directory/frames`). The fold path calls these; it adds NO method to any of them.

### F3.5-A — the fold mechanism: a dedicated fold-consumer vs the trim path emitting segments directly

**Arm A1 — a DEDICATED `StreamConsumer` instance folds trimmed segments into Graft.** A purpose-configured
`StreamConsumer` (the emq3.3 sibling, in a fold mode) reads the stream on its beat, batches entries into a
segment, commits the segment to a Graft Volume via `VolumeServer.commit/3`, confirms durability, THEN trims
that slice (the F3.4-A/A3 fold-then-trim coupling).

- *Rationale.* The archive is just another consumer of the stream — folding is "read a slice, write it
  durably, then drop it from the hot log," which is exactly the consume-settle-advance shape the emq3.3
  `StreamConsumer` already is. Reusing the consumer means the fold inherits crash recovery, at-least-once,
  and the beat for free.
- *5W.* **Why** — the fold is a consumer; building it AS a consumer reuses the whole emq3.3 recovery and
  cadence story rather than inventing a second one. **What** — a `StreamConsumer` configured to fold its
  served slice into a Graft Volume (forward-tense), reusing `VolumeServer.commit/3` (`volume_server.ex:50`).
  **Who** — the bus operator runs it as a supervised child like any consumer; the codemojex consumer never
  touches it. **When** — emq3.5. **Where** — `EchoMQ.StreamConsumer` in a fold configuration (forward-tense),
  consuming the COEXIST `EchoStore.Graft` surface.
- *Steelman.* For the operator, the archive becomes "another StreamConsumer on a fold group" — the SAME
  supervision shape, the SAME crash recovery (if the fold consumer dies mid-segment, its PEL holds the
  un-folded entries and PEL-first re-delivers them on restart, so a folded-but-not-trimmed slice is re-folded
  idempotently, never lost), the SAME beat. At-least-once on the fold means a crash re-folds the boundary
  slice; Graft's commit is the dedup point (the same LSN/page is an idempotent overwrite, `volume_server.ex`
  commit semantics). The COEXIST law is honored cleanly: the fold consumer is a CLIENT of
  `VolumeServer.commit/3`, adding nothing to the engine. The fold-then-trim order (the consumer folds, the
  `Streamer` confirms the segment durable to Tigris, THEN the consumer trims that slice via the F3.4 policy)
  makes the trim watermark == the fold watermark by construction — closing F3.5-B's gap/overlap question in
  the SAME process.
- *Steward.* The keep-cost: the fold consumer is a long-lived operational process with a durability
  dependency (Graft + Tigris), so its failure modes are richer than a pure stream consumer's (Tigris
  unreachable, a commit conflict). The spec must name the fold consumer's behavior when Graft is unavailable
  (does it PARK the trim until the fold confirms? — yes, by the fold-then-trim safety invariant, so an
  unreachable Tigris stalls retention rather than dropping un-archived data, which is the correct, if
  memory-growing, failure mode). It adds a cross-app runtime coupling (echo_mq's consumer reaching into
  echo_store's Graft) — but as a CONSUMER of a public facade, not a boundary violation, since echo_store
  already depends on echo_mq (`echo/CLAUDE.md` §1 dependency table) and the fold rides that existing direction
  inverted via the public `EchoStore.Graft` facade. The spec must state the dependency direction explicitly.

**Arm A2 — the trim path EMITS segments directly (the trim hands its slice to Graft inline).** When the
retention trim drops a slice, the trim path itself constructs a segment from the dropped entries and commits
it to Graft, with no dedicated consumer.

- *Rationale.* The slice being trimmed IS the slice to archive; emitting it at the trim moment means there is
  exactly one place where "drop from hot log" and "write to cold store" happen, atomically adjacent.
- *5W.* **Why** — coupling archive to trim at one site removes the "did the fold keep up with the trim?"
  coordination entirely. **What** — the trim verb reads the slice it is about to drop, commits it to Graft,
  then trims (forward-tense). **Who** — whatever calls trim (the operator's `trim/4`, a cron). **When** —
  emq3.5. **Where** — the trim path (`EchoMQ.Stream.trim` or the F3.4-A mechanism).
- *Steelman.* The tightest possible fold-then-trim coupling — the same call reads, archives, trims, so the
  watermark is trivially consistent. No second process to supervise or crash-recover.
- *Steward.* The keep-cost is severe for operability: the trim path now carries a durability side effect, so a
  trim BLOCKS on a Graft/Tigris commit — a slow or unreachable archive stalls the trim (and thus retention)
  inside whatever called it (the operator's `trim/4`, or worse, an append if F3.4-A/A1). It has NO crash
  recovery story of its own (if the process dies between commit and trim, or between read and commit, recovery
  is ad-hoc), where A1 inherits the consumer's PEL-first recovery. It conflates two concerns (retention and
  archival) the operator may want to reason about separately (trim aggressively, archive lazily). And it
  spreads Graft-commit calls across every trim caller rather than one fold consumer, multiplying the
  COEXIST-surface call sites.

**Ranked recommendation (Lens A): A1 (a dedicated fold-consumer), decisively — it inherits emq3.3's crash
recovery and makes the archive "just another StreamConsumer."** From the operability lens, the fold consumer
reusing the emq3.3 sibling's PEL-first recovery is the whole game: a fold consumer that crashes mid-segment
re-folds its boundary slice idempotently on restart (PEL-first), so the archive is at-least-once with the
SAME recovery the operator already understands from the job and stream consumers — one mental model, not
three. A2's inline emit has no recovery story and stalls retention on a durability commit. A1 honors COEXIST
cleanly (the fold consumer is a CLIENT of `EchoStore.Graft.VolumeServer.commit/3`, adding nothing). The
fold-then-trim order makes the trim watermark == the fold watermark in one process, which is the safety the
archive most needs.

> **Pre-empted spec-steward objection:** *"A dedicated fold consumer adds a long-lived cross-app process with
> a durability dependency and a richer failure surface; it inverts the echo_mq→echo_store dependency and must
> not let the COEXIST boundary blur — emitting segments at the trim site is a smaller, more contained
> surface."* Answer: the cross-app reach is through the PUBLIC `EchoStore.Graft` facade (`graft.ex`,
> `volume_server.ex` — verified public specs), the same way any consumer of a facade reaches it, so the
> COEXIST law (engine untouched, consumed as a peer) is satisfied by the fold adding zero engine methods. The
> dependency direction is stated explicitly in the spec. The "smaller surface" of A2 is illusory: it trades a
> contained, supervised, crash-recoverable consumer for a durability side effect smeared across every trim
> caller with NO recovery — a larger operational surface, not a smaller one. The richer failure modes A1
> carries are exactly the modes the archive HAS regardless of mechanism; A1 gives them a supervised home, A2
> leaves them ad-hoc.

### F3.5-B — the merge-read: tracking the watermark so the merge has no gap and no overlap

**Arm B1 — the watermark IS the trim boundary (segment fold == stream slice, by the fold-then-trim order).**
A deep read = the live-tail (XRANGE on the hot stream) ∪ the archived segments (Graft `read`/`read_at`), where
the boundary between them is the single trim watermark id: every id `≥ watermark` is in the live stream, every
id `< watermark` is in a folded segment, and because the fold-then-trim order (F3.5-A/A1) trims a slice ONLY
after it is folded, the watermark is the exact, unique boundary — no id is in both (no overlap), no id is in
neither (no gap).

- *Rationale.* The order theorem makes the branded id a total monotone order over the whole log; a single id
  watermark cleanly partitions "archived" from "live," and the fold-then-trim order makes that partition
  exact. One value (the watermark id) is the entire merge contract.
- *5W.* **Why** — a merge-read for a LIVE consumer must be correct (no missing event) and cheap (one boundary
  to check); a single monotone id watermark is both. **What** — a deep-read surface (forward-tense,
  `read_deep`/`read_since` on `EchoMQ.Stream`) that reads segments below the watermark from Graft and the tail
  above it from the stream, concatenating in id order. **Who** — the codemojex consumer doing a walk-forward
  replay; the operator doing an audit read. **When** — emq3.5. **Where** — a deep-read surface on
  `EchoMQ.Stream` (forward-tense) over the COEXIST `EchoStore.Graft.read`/`read_at` (`graft.ex:47-56`).
- *Steelman.* For a live consumer, the merge is correct by the order theorem (the same property that makes
  stream position == id sort, `id.ex:28-49`, now spanning archived + live): read segments below the watermark
  in id order, then the live tail above it in id order, and the concatenation IS the full log in mint order
  with no de-dup needed — because the fold-then-trim coupling guarantees the watermark is a clean cut. The
  watermark is a single monotone id, so the merge boundary is one comparison, not a join. The latency is
  bounded: the live tail is in-memory Valkey (fast), the segments are Graft's lock-free reads (L1 → CubDB →
  lazy Tigris fetch, `store.design.md` §3 reads row) — so a deep read pays Tigris latency ONLY for segments
  not resident, and a recent-window read (the common game case) is entirely live-tail (zero archive hit). This
  is the merge-read latency property the operator needs: cheap for the hot window, correct for the deep one.
- *Steward.* The keep-cost: the watermark must be TRACKED somewhere durable across restart (the same policy/
  state-key question as F3.4-B — a `emq:{q}:stream:<name>:watermark` subkey whose cleanup must be named, OR
  derived from Graft's own head LSN / highest folded id so no new key is needed). Deriving it from Graft's
  folded frontier (the highest id in the latest segment) is the cleaner, no-new-subkey form and should be the
  recommendation — the watermark is then a READ of the archive's own state, not a separately-maintained key
  that can drift from the fold. The merge must handle the approximation slack of `MAXLEN ~` (the trim is
  approximate, so the boundary is fuzzy by a few entries — the merge must tolerate a small overlap window and
  de-dup by id there, which the order theorem makes trivial: identical ids are identical entries). The spec
  must state the merge de-dups the approximation-slack overlap by id.

**Arm B2 — a separately-maintained merge cursor / index.** A dedicated cursor structure tracks, per stream,
which id ranges are archived vs live, maintained as a side index the merge-read consults.

- *Rationale.* An explicit index of archived ranges makes the merge a lookup rather than a watermark
  comparison, robust to non-contiguous archival (if segments are folded out of order, or some slice is
  archived twice).
- *5W.* **Why** — if archival is ever non-contiguous, a single watermark cannot describe it; an index can.
  **What** — a per-stream archived-ranges index (forward-tense). **Who** — the merge-read path. **When** —
  emq3.5. **Where** — a new index surface (forward-tense).
- *Steelman.* Handles a future where archival is non-contiguous (partial re-folds, out-of-order segments)
  without the merge silently dropping a gap. More descriptive than a scalar watermark.
- *Steward.* The keep-cost is a whole new index surface to build, persist, keep coherent with BOTH the stream
  and Graft, and crash-recover — a second source of truth about "what is archived" that can DRIFT from the
  actual Graft contents (the worst failure: the index says archived, Graft does not have it, the merge drops
  the slice). It pays for a non-contiguity that the fold-then-trim order (A1) makes impossible BY
  CONSTRUCTION: the fold is strictly monotone (it folds the oldest un-folded slice, in id order, because the
  order theorem orders the whole log), so archival IS contiguous and a scalar watermark fully describes it.
  B2 solves a problem A1 does not have, at the cost of a drift-prone second index — the opposite of One
  authority.

**Ranked recommendation (Lens A): B1 (the trim watermark IS the merge boundary), with the watermark DERIVED
from Graft's folded frontier (no new subkey), and the merge de-dups the `MAXLEN ~` approximation slack by
id.** The order theorem already gives a total monotone order over the whole log; the fold-then-trim coupling
(F3.5-A/A1) makes the trim a clean monotone cut; so a single watermark id fully and correctly partitions
archived from live, and the merge is correct by construction with one comparison. Deriving the watermark from
the archive's own folded frontier (rather than a separately-maintained key) makes the archive the One
authority for "what is archived" — no drift-prone side index. The merge is cheap for the hot window
(live-tail only, zero archive hit) and correct for the deep window (segments in id order), which is the
latency+correctness property a live consumer needs. The approximation-slack overlap de-dups trivially by id
(identical ids are identical entries — the order theorem).

> **Pre-empted spec-steward objection:** *"A scalar watermark assumes archival is forever contiguous and
> monotone; the instant a re-fold, a partial restore, or an out-of-order segment happens, the watermark
> silently mis-describes the boundary and the merge drops or doubles a slice — a real index is the robust
> contract."* Answer: contiguity is not an assumption, it is a CONSEQUENCE of the fold-then-trim order plus
> the order theorem — the fold consumer (F3.5-A/A1) folds the oldest un-folded slice in strict id order and
> trims only after durability, so a gap or an out-of-order segment cannot arise without a bug that an index
> would equally mis-describe. The index B2 proposes is a SECOND source of truth that can drift from Graft's
> actual contents (the genuinely dangerous failure — believing a slice archived when it is not); deriving the
> watermark FROM Graft's folded frontier makes the engine the single authority and makes drift structurally
> impossible. The robustness B2 buys is against a non-contiguity the design forecloses; the drift it
> introduces is against a coherence the design needs. One authority wins.

---

## §emq3.6 · Time-travel + hydration — the changelog read, no compactor

**The rung's job.** Time-travel (mint-instant → `XRANGE` bounds) and Table hydration from a stream tail (the
changelog read, no compactor); a mint-time window read equals the id-filtered truth, hydrate-then-fence equals
loader truth (`emq.streams.md` emq3.6 row). The forward-compatibility for this rung was bought at emq3.2 (the
A1 id carries real Unix-ms, `id.ex:18-22`).

### F3.6-A — the time-travel API surface shape

**Arm A1 — `read_since(dt)` / `read_between(dt1, dt2)` — DateTime-bounded reads mapping to `XRANGE` bounds via
`Snowflake.min_for/1`.** A reader passes a `DateTime`; the surface maps it to a `MINID`/`XRANGE` bound via the
verified `Snowflake.min_for/1` (`snowflake.ex:116`: "Smallest snowflake mintable at or after the instant; for
half-open time-range scans") and reads the matching slice — spanning live + archive via the F3.5-B merge.

- *Rationale.* The most direct consumer surface for time-travel is "give me events since/between these
  wall-clock instants" — the reader thinks in DateTimes (a backtest window, an audit range), and the surface
  maps that to the id-ordered bounds the wire compares. The real-Unix-ms id (bought at emq3.2) makes the
  mapping exact.
- *5W.* **Why** — backtests, audit, and debugging are all wall-clock-window queries; the consumer wants to
  ask in DateTimes, not branded ids. **What** — `read_since/read_between` on `EchoMQ.Stream` (forward-tense),
  mapping the DateTime to a snowflake bound via `Snowflake.min_for/1` (`snowflake.ex:116`, verified), then
  reading the slice over the F3.5-B merge. **Who** — the codemojex consumer doing a backtest; the operator
  doing an audit. **When** — emq3.6. **Where** — `EchoMQ.Stream` (forward-tense), over `Snowflake.min_for/1`
  and the emq3.5 deep-read.
- *Steelman.* This is the surface the whole tier's forward-compatibility was designed FOR: emq3.2 deliberately
  carried real Unix-ms in the A1 id (`id.ex:18-22`, stated load-bearing for "emq3.6's wall-clock XRANGE"), and
  `Snowflake.min_for/1` is the verified, already-shipped function that maps a `DateTime` to the smallest
  snowflake at-or-after it — so `read_since(dt)` is a thin, correct composition over a surface that already
  exists, not a new mechanism. For the consumer, a DateTime-bounded read is the natural query shape (a
  backtest is "replay 2026-06-01 to 2026-06-02"), and because the bound maps to an id and the id orders the
  whole log (live + archive), the same DateTime read spans the merge transparently — the consumer never sees
  the archive boundary. The gate is exact: a mint-time window read equals the id-filtered truth (the order
  theorem makes the DateTime bound and the id bound the same cut).
- *Steward.* The keep-cost: a half-open vs closed interval convention must be fixed and frozen (`min_for` is
  "at or after" — half-open `[dt1, dt2)` is the natural convention and must be stated, or off-by-one-ms
  errors creep into audit reads). The DateTime→id mapping is exact only for the namespace whose mint-instant
  the id carries (the `EVT` brand — the kind door keeps this sound, `id.ex:47-49`); the spec must state
  time-travel is per-stream (per-namespace), not cross-stream. It composes cleanly with emq3.5 (the merge is
  transparent under the DateTime read) and adds no new key.

**Arm A2 — id-bounded reads only (`read_between(id1, id2)`); the DateTime→id mapping is the caller's job.** The
surface takes branded ids (or raw `XRANGE` bounds); a consumer wanting a DateTime range maps it themselves via
`Snowflake.min_for/1`.

- *Rationale.* The wire compares ids; exposing id bounds keeps the surface minimal and the DateTime
  convenience optional, letting the consumer own the interval convention.
- *5W.* **Why** — the smallest surface is id-bounded; DateTime is sugar a consumer can add. **What** — id/
  raw-bound reads. **Who** — a consumer comfortable mapping DateTimes. **When** — emq3.6. **Where** —
  `EchoMQ.Stream`.
- *Steelman.* Minimal frozen surface; the consumer controls the interval semantics. The DateTime mapping is a
  one-liner (`Snowflake.min_for/1`) the consumer can call, so no expressiveness is lost.
- *Steward.* The keep-cost is a DX tax pushed onto every consumer: every backtest author re-derives the
  DateTime→id mapping and re-decides the interval convention, so the off-by-one risk is distributed and
  inconsistent across call sites rather than fixed once. For the operability lens this is the wrong trade — it
  saves the maintainer one thin function at the cost of every consumer re-implementing it.

**Ranked recommendation (Lens A): A1 (`read_since`/`read_between` DateTime-bounded), half-open `[dt1, dt2)`
convention fixed, per-stream, over the verified `Snowflake.min_for/1`.** The consumer thinks in wall-clock
windows; giving them a DateTime-bounded read that maps exactly (because emq3.2 bought the real-Unix-ms id) and
spans the archive transparently (the F3.5-B merge) is the surface the whole tier's forward-compatibility was
built to enable. A2's id-only minimalism pushes the mapping and the interval convention onto every consumer —
the wrong trade for a lens that weights consumer-ease. (A1 can still expose an id-bounded `read_between(id1,
id2)` as the primitive underneath — the DateTime form is the consumer face, the id form the composition
point.)

> **Pre-empted spec-steward objection:** *"A DateTime-bounded read freezes an interval convention and a
> DateTime→id mapping into a public surface forever; the mapping is exact only under the EVT namespace and
> the half-open boundary is an off-by-one trap — an id-bounded primitive freezes less and lets the
> convention live where the consumer owns it."* Answer: freezing the convention ONCE, correctly, in the
> surface is precisely better than freezing it implicitly N times across every consumer's hand-rolled
> mapping — the off-by-one trap is MORE dangerous distributed (A2) than fixed once (A1), where it is stated,
> tested by the "mint-time window equals id-filtered truth" gate, and reviewable. The namespace exactness is
> handled by the kind door already (`id.ex:47-49`); the spec states time-travel is per-stream. A1 exposes the
> id-bounded form as the primitive, so the steward's minimal surface still exists underneath — A1 ADDS the
> consumer face without REMOVING the primitive.

### F3.6-B — Table hydration from a stream tail (the changelog read)

**Arm B1 — hydrate via a latest-per-key read over the stream tail, feeding `EchoStore.Table`; the gate is
"hydrate-then-fence equals loader truth."** A hydration surface reads the stream tail, reduces to
latest-value-per-key (newer id wins, by the order theorem), and writes each into an `EchoStore.Table` via
`Table.put/4` (the 14-byte version arg, `table.ex:97`), so the Table is hydrated from the changelog with no
compactor — then the staleness fence (BCS 4.2) takes over for live coherence.

- *Rationale.* The stream IS a changelog (append-only, id-ordered); the latest entry per key is the current
  value, and the order theorem makes "latest" a trivial id-max reduction. Feeding that into a Table hydrates
  it from history with no compactor — exactly the "changelog reads are already law" property
  (`emq.streams.md` §"Latest-value-per-key reads").
- *5W.* **Why** — a service restarting needs its Table warm (config, positions); replaying the stream tail to
  latest-per-key is how it warms from the log without a separate snapshot. **What** — a hydrate surface
  (forward-tense) that reduces the stream tail to latest-per-key and writes via `EchoStore.Table.put/4`
  (`table.ex:97`, verified — takes a 14-byte version). **Who** — a service that hydrates a Table on boot (the
  config/positions case); the codemojex consumer warming player state. **When** — emq3.6. **Where** — a
  hydrate surface bridging `EchoMQ.Stream` and `EchoStore.Table` (forward-tense; the COEXIST/cross-app
  consume pattern, the same direction as emq3.5).
- *Steelman.* The mechanism is already law — newer-wins by mint order is the staleness fence's admission
  rule (`emq.streams.md` §"Two committed mechanics"; Chapters 4.1–4.2), and `EchoStore.Table.put/4` takes a
  14-byte version arg (`table.ex:97`, verified) which IS the branded id, so hydration writes each latest
  value with its branded version and the fence's newer-wins admission keeps it coherent thereafter. The gate
  is clean and operationally meaningful: hydrate-then-fence equals loader truth means a Table warmed from the
  stream tail, then fed live by the fence, holds exactly what a from-scratch loader would — so the operator
  can trust a hydrated service as equivalent to a cold-loaded one. The latest-per-key reduction is the order
  theorem applied (id-max per key), no compactor, no second mechanism. It composes with the time-travel read
  (A1): hydrate-as-of a DateTime is `read_since(epoch)` reduced to latest-per-key as-of that instant — a
  point-in-time Table rebuild for debugging.
- *Steward.* The keep-cost: hydration is a cross-app bridge (echo_mq's stream → echo_store's Table), which the
  spec must state as a consume-the-public-facade direction (echo_store already depends on echo_mq, so the
  bridge rides the existing dependency via the public `EchoStore.Table` facade). The latest-per-key reduction
  over a long tail can be expensive (a full-tail scan); the spec should bound it (hydrate from the trim
  watermark forward, since older state is in the archive — composing with F3.5-B's watermark). The "version"
  written to the Table must be the branded id (the 14-byte arg, `table.ex:97`), and the spec must assert the
  fence's newer-wins admission and the stream's mint-order are the SAME order (they are — both are the branded
  id's byte order), or hydrate-then-fence does NOT equal loader truth.

**Arm B2 — hydration is out of scope for emq3.6; time-travel only.** emq3.6 ships only the time-travel read
(F3.6-A); Table hydration from a stream is deferred to a later rung or left to the consumer.

- *Rationale.* Time-travel and hydration are separable; shipping the smaller, verified time-travel surface
  first de-risks the rung and lets hydration's cross-app bridge be designed deliberately.
- *5W.* **Why** — a smaller rung ships sooner and with less cross-app surface. **What** — time-travel only.
  **Who** — the consumer (who hydrates by hand if needed). **When** — emq3.6 (time-travel), hydration later.
  **Where** — `EchoMQ.Stream` time-travel only.
- *Steelman.* De-risks the rung — the cross-app hydration bridge is the riskier half, and decoupling it lets
  time-travel ship on the verified `Snowflake.min_for/1` alone.
- *Steward.* The keep-cost is a HALF-DELIVERED tier promise: `emq.streams.md` names hydration as a tier need
  ("Latest-value-per-key reads (config, positions, hydration)") and the emq3.6 gate explicitly includes
  "hydrate-then-fence equals loader truth" — dropping it leaves the changelog-read value unrealized and pushes
  every consumer to hand-roll the latest-per-key reduction (the same DX tax as F3.6-A/A2). It defers the
  cross-app bridge rather than designing it, which risks a later ad-hoc hydration that does NOT compose with
  the fence.

**Ranked recommendation (Lens A): B1 (hydrate via latest-per-key over the stream tail into `EchoStore.Table`),
bounded to hydrate-from-the-watermark-forward, with the branded id as the Table version.** The hydration DX is
the consumer payoff of the whole changelog-read property: a service warms its Table from the stream tail with
no compactor and no hand-rolled reduction, then the fence keeps it coherent — "hydrate-then-fence equals
loader truth" is the operator's guarantee that a warmed service is a real service. The mechanism is already
law (newer-wins by mint order = the fence's admission = the stream's order, all the branded id's byte order),
and `EchoStore.Table.put/4`'s 14-byte version arg (`table.ex:97`, verified) IS the branded id — so the bridge
is a thin composition, not a new mechanism. Bounding the reduction to the trim-watermark-forward (older state
is archived, F3.5-B) keeps it cheap. B2's defer leaves a named tier promise half-kept and pushes the reduction
onto every consumer.

> **Pre-empted spec-steward objection:** *"Hydration is a cross-app bridge (echo_mq stream → echo_store Table)
> that the order theorem alone does not make safe — the claim 'the fence's newer-wins order equals the
> stream's mint order' is an ASSERTION across two subsystems that must be proven, not assumed, and a wrong
> assumption makes hydrate-then-fence silently NOT equal loader truth."* Answer: this is the one assertion the
> rung MUST prove rather than assert, and the spec makes it a gated invariant, not prose — the gate
> "hydrate-then-fence equals loader truth" is exactly the proof that the two orders coincide (a Table hydrated
> from the tail, then fed live by the fence, is byte-equal to a from-scratch loader's Table). The orders DO
> coincide by construction (both the fence's version arg and the stream's id are the SAME branded id's byte
> order — `table.ex:97` takes the 14-byte branded version, the stream stores the branded id field), but the
> rung proves it empirically with the loader-truth gate rather than resting on the construction argument
> alone. The cross-app direction is the existing echo_store→echo_mq dependency consumed via the public Table
> facade, stated in the spec — not a new edge.

---

## §The forward-compatibility thread — why this is designed-ahead

The load-bearing reason this is one design doc and not four sequential rungs: **emq3.3's frozen public surface
must anticipate emq3.5's fold and emq3.6's hydration, or it freezes the wrong contract.** The thread:

1. **The handler contract (F3.3-B/B1) is the fold consumer's contract too.** emq3.5's fold-consumer (F3.5-A/A1)
   IS a `StreamConsumer` in a fold mode — so the handler map `%{id, payload, attempts, group}` frozen at
   emq3.3 must already be the shape the fold's per-slice handler reads. Freezing a stream-divergent handler
   (B2) at emq3.3 would force the fold consumer to either fork the contract or carry a map that does not fit
   the archive's per-segment shape. **emq3.3 must freeze the job-identical handler so the fold reuses it.**

2. **PEL-first recovery (F3.3-B/B1) is the fold's at-least-once guarantee.** emq3.5's fold is at-least-once
   ONLY because the fold-consumer inherits emq3.3's PEL-first restart (a crash mid-fold re-delivers the
   un-folded boundary slice). If emq3.3 freezes tail-only recovery (B2), the fold's own backlog is recovered
   only via `XAUTOCLAIM` latency, weakening the archive's recovery to "eventually." **emq3.3's recovery mode
   is the archive's recovery mode.**

3. **The retention watermark (F3.4) is the merge boundary (F3.5-B) is the hydration bound (F3.6-B).** The
   single trim watermark id, set by the fold-then-trim coupling (F3.4-A/A3 + F3.5-A/A1), is the SAME value
   that partitions the merge-read (F3.5-B/B1) and bounds the hydration reduction (F3.6-B). One monotone id
   frontier serves retention, archive, merge, and hydration — but ONLY if emq3.4's retention is consumer-beat
   driven (A3) so the trim cannot outrun the fold. If emq3.4 freezes trim-on-append (A1) as the default, the
   trim and fold watermarks diverge and the merge gains a gap. **emq3.4's trim mechanism must be the fold's
   watermark source.**

4. **The real-Unix-ms id (already bought at emq3.2) is emq3.6's time-travel mapping.** This forward-compat was
   purchased two rungs early (`id.ex:18-22`) — emq3.6's `read_since(dt)` (F3.6-A/A1) maps a DateTime to a
   bound via `Snowflake.min_for/1` (`snowflake.ex:116`, verified) ONLY because the A1 id carries true
   Unix-ms. This thread is already woven; emq3.3–3.5 must not break it (no rung may store a non-real-ms id).

5. **The branded id IS the Table version (F3.6-B) is the receipt (emq3.2) is the merge sort key (F3.5-B) is
   the position (the order theorem).** One value — the 14-byte branded `EVT` id — is the stream position, the
   sort key, the receipt, the archive segment's contained id, the merge watermark, and the Table hydration
   version (`table.ex:97` takes the 14-byte version). emq3.3 freezing the branded `id` FIELD as the canonical
   receipt (the S-3 parity test) is what lets every later rung use that one value everywhere. **emq3.3 must
   freeze the branded id as the cross-rung thread.**

The discipline: emq3.3's surface (the handler contract, PEL-first recovery, the branded-id receipt) is frozen
KNOWING it must serve the fold and the hydration. The far rungs are NOT over-specified — their forks stay open
— but emq3.3's freeze is chosen to keep them buildable.

---

## §Fork ledger (Lens A ranked arms — for the Director's cross-lens diff)

| Fork | Lens-A ranked arm | One-line reason (consumer/operability) |
|---|---|---|
| **F3.3-A** XGROUP lifecycle | **A1** lazy ensure-on-start, `:from` declared | One wiring step that cannot be forgotten; `MKSTREAM`+`BUSYGROUP`-swallow works before/after first event |
| **F3.3-B** restart read mode + handler | **B1** PEL-first, handler-identical | Self-recovers un-acked work AT restart (not after min-idle); ONE handler shape across job+stream — the biggest DX multiplier |
| **F3.3-C** conformance grain | **C1** +1 capability, deep proofs ride property/loop | A clean capability-grained registry serves the polyglot reader; exhaustive proofs are property/loop-shaped, beside it |
| **F3.4-A** WHERE trim lives | **A3** consumer-beat (+A2 as manual verb; A1 opt-in for un-consumed) | Fold-then-trim in one beat makes trim-watermark == fold-watermark — retention never drops un-archived data |
| **F3.4-B** policy declaration | **B1** registered per-stream, `MAXLEN ~` approx, `MINID` via `min_for/1` | One place to read/change retention; approx keeps hot-stream trim cheap; cleanup named per subkey law |
| **F3.5-A** fold mechanism | **A1** dedicated fold-consumer | Inherits emq3.3 PEL-first recovery — archive is "just another StreamConsumer," one mental model; COEXIST-clean (consumes `VolumeServer.commit/3`) |
| **F3.5-B** merge-read watermark | **B1** watermark IS trim boundary, derived from Graft frontier | Order theorem + fold-then-trim makes a scalar id a clean cut — no gap, no overlap, no drift-prone side index |
| **F3.6-A** time-travel surface | **A1** `read_since`/`read_between` DateTime, half-open, over `min_for/1` | Consumer thinks in wall-clock; maps exact (emq3.2's real-Unix-ms id); spans archive transparently |
| **F3.6-B** Table hydration | **B1** latest-per-key tail → `Table.put/4`, watermark-bounded | Warms a Table from the changelog with no compactor; branded id IS the version; "hydrate-then-fence = loader truth" |

**Where this lens most expects to DIVERGE from a spec-steward lens** (the highest-value signals for the
Operator):

1. **F3.4-A (WHERE trim lives) — A3 consumer-beat vs the steward's likely A1 trim-on-append.** This lens
   weights fold-safety (trim can never outrun the fold) over invariant-simplicity (bound-by-construction with
   no process-coupling). A genuine divergence on a SAFETY-vs-SIMPLICITY axis.
2. **F3.3-B (handler contract) — B1 handler-identical vs the steward's likely concern about a shared frozen
   contract aging into a leaky abstraction.** This lens weights the one-handler-shape DX multiplier; the
   steward weights the freeze-cost of a contract whose `attempts` field means subtly different things on each
   side. The divergence is on whether the DX win is worth pinning the one differing field.
3. **F3.5-B (merge watermark) — B1 scalar-watermark vs a steward's possible preference for an explicit index.**
   This lens argues contiguity is a CONSEQUENCE (order theorem + fold-then-trim), so a scalar suffices and an
   index introduces drift; a steward may weight robustness-against-future-non-contiguity over the no-drift
   property. A divergence on whether to engineer for a non-contiguity the design forecloses.

---

## §What I deliberately did NOT decide (the discipline)

- **Every fork above is SURFACED, not ruled.** The ranked arm is a recommendation with its one carrying
  reason; the choice is the Operator's. An architect that picks the winner has stopped being a steward.
- **The `echomq:3.0.0` cutover ratification.** The tier ships additive-minor (`emq.streams.md` §Version
  plane); WHEN the deferred `3.0.0` MAJOR cutover is declared (the defer-the-fence-cutover pattern) is the
  Operator's ratification, not this design's — named, parked.
- **The store.design.md §4 Graft forks** (segment key layout, one-writer-or-many, the journal's future, the
  page-set substrate, pull cadence, SigV4) are echo_store's open forks; emq3.5 CONSUMES the engine as a peer
  and does not touch them. Out of this tier's scope by the COEXIST law.
- **Object payloads on streams** (`emq.streams.md` §Seams) — claims-only is the law; an object topic's codec
  is a decision at its rung, not designed here.
- **The log-tier exit** (`emq.streams.md` §Seams) — if a real consumer ever presents large-end demand, the
  log tier moves; that reopening edits `emq.streams.md` first and is not pre-decided here.
- **Exactly-once** — not claimed; at-least-once with idempotent handlers is the gated posture
  (`emq.streams.md` §Seams), carried unchanged.
- **The exact conformance count** — re-probed at the rung's reconcile against `conformance.ex` before any
  pinning (the as-built count drifts; this design names the GRAIN, not the number).

---

## §Surface citations (NO-INVENT — every named surface grounded)

**Verified as-built (real `module/file`):**

- `EchoMQ.Stream.append/4` / `append_id/5` / `append_batch/4` / `read/3..6` / `stream_key/2` — `echo/apps/echo_mq/lib/echo_mq/stream.ex` (the writer law, emq3.2). The branded `id` FIELD stored at `stream.ex:100`; the `:nonmonotonic` map at `stream.ex:61,104`; "`append/_` does not trim" boundary at `stream.ex:50-52`.
- `EchoMQ.Stream.Id.xadd_id/1` / `evt?/1` / `kind/0` — `echo/apps/echo_mq/lib/echo_mq/stream/id.ex`. The order theorem at `id.ex:28-49`; the real-Unix-ms forward-compat note at `id.ex:18-22`.
- `EchoMQ.Keyspace.queue_key/2` / `job_key/2` — `echo/apps/echo_mq/lib/echo_mq/keyspace.ex:13-24`. The braced `emq:{q}:<type>` grammar; the stream key `emq:{q}:stream:<name>` (`stream.ex:172-174`).
- `EchoMQ.Consumer` — `echo/apps/echo_mq/lib/echo_mq/consumer.ex`: the handler map `%{id, payload, attempts, group}` (`consumer.ex:40-41,147`); the reap-on-beat (`consumer.ex:116`); the rescue/catch survive-the-loop discipline (`consumer.ex:147-153`); `drain/1` settle (`consumer.ex:137-165`); `stop/2` drain (`consumer.ex:101-112`).
- `EchoMQ.BatchConsumer` — `echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex`: the SIBLING-not-mode precedent (`batch_consumer.ex:10-16`); self-started connector lane (`batch_consumer.ex:101-104`); the per-member verdict + survive-the-loop generalization (`batch_consumer.ex:225-233`).
- `EchoMQ.Stalled` — `echo/apps/echo_mq/lib/echo_mq/stalled.ex`: the separate-sweep precedent (weighed-against, NOT taken for the stream consumer per settled-decision S-2); server-`TIME` clock; declared-keys-only.
- `EchoMQ.Events.publish/_` / channel — `echo/apps/echo_mq/lib/echo_mq/events.ex`: the per-queue lifecycle pub/sub seam (at-most-once; the durable replayable receipt is the Stream).
- `EchoMQ.Connector.command/3` / `pipeline/3` — the generic verb-agnostic RESP path (`echo/apps/echo_mq/test/stream_verbs_test.exs:13`); the stream verbs ride it with no connector edit. Push-safety scoped to non-blocking; XREADGROUP BLOCK deferred to emq3.3 (`stream_verbs_test.exs:22-24`).
- `EchoMQ.Conformance.scenarios/0` / `run/2` — `echo/apps/echo_mq/lib/echo_mq/conformance.ex` (re-probe the live count at reconcile; the program law flags 18 as the floor, the emq3 rungs may have grown it).
- `EchoData.Snowflake.next_branded/1` (`snowflake.ex:104`); `unix_ms/1` (`snowflake.ex:107`); `min_for/1` ("Smallest snowflake mintable at or after the instant; for half-open time-range scans", `snowflake.ex:116`) — the verified DateTime→bound surface for emq3.6.
- `EchoData.BrandedId.parse/1` / `valid?/1` / `encode!/2` — `echo/apps/echo_data/lib/echo_data/branded_id.ex:27,95`.
- `EchoStore.Graft.open_volume/2` (`graft.ex:30`) / `read/2` (`graft.ex:47`) / `read_at/3` (`graft.ex:54`) / `new_volume_id/0` (`graft.ex:37`); `EchoStore.Graft.VolumeServer.begin/1` → `commit/3` (the single-writer mailbox write path, `volume_server.ex:40-50`); `EchoStore.Graft.Streamer.commit_ready/2` (the Tigris push, `streamer.ex:33-34`) — the COEXIST engine surface emq3.5's fold CONSUMES as a peer (UNTOUCHED, per `store.design.md` §0).
- `EchoData.Graft.Segment` struct (fields `id/lsn/pages/directory/frames`, `echo/apps/echo_data/lib/echo_data/graft/segment.ex:20`).
- `EchoStore.Table.put/4` (the 14-byte version arg, `table.ex:97`) / `fetch/3` (`table.ex:63`) — the emq3.6 hydration target (the version IS the branded id).
- `EchoStore.Graft.Sync` commit feed `graft:<volume_id>:commits` (`echo/apps/echo_store/lib/echo_store/graft/sync.ex:41`).

**Forward-tense (surface this design proposes a rung BUILDS — not yet on disk):**

- `EchoMQ.StreamConsumer` (emq3.3 — the NEW sibling consumer; `start_link`, the PEL-first/`>` loop, the `XAUTOCLAIM` reclaim beat, the fold mode for emq3.5). Does NOT exist (verified: only `stream.ex` + `stream/id.ex` are present).
- `EchoMQ.Stream.group_create/5` (F3.3-A/A2 alternative — surfaced, not chosen by this lens).
- `EchoMQ.Stream.trim/4` (F3.4-A/A2 — the manual retention verb / the consumer-beat's public face).
- The per-stream retention policy surface (F3.4-B/B1) and its Keyspace policy key (cleanup-named).
- The emq3.5 deep-read / merge surface (`read_deep`/the F3.5-B merge) and the watermark (derived from Graft's folded frontier).
- `EchoMQ.Stream.read_since/2` / `read_between/3` (F3.6-A/A1 — DateTime-bounded, over `Snowflake.min_for/1`).
- The emq3.6 Table-hydration bridge (latest-per-key tail → `EchoStore.Table.put/4`).

**Canon / design cited (NOT a code surface):** `docs/echo_mq/emq.streams.md` (the tier ladder, the needs, the
durable-archive answer, the seams, the version plane); `docs/echo_mq/store/design/store.design.md` (the Graft
engine architecture §0, the dev↔prod knob §3, the Venus-surfaces forks §4 — out of this tier's scope by
COEXIST); `docs/echo_mq/emq.design.md` (S-1..S-7, the v2 laws); `.claude/skills/echo-mq-program.md` (the
gate ladder, the conformance additive-minor law, the master invariant).
