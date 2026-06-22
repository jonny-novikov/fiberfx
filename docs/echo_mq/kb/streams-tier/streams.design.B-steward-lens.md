# EchoMQ 3.0 — The Stream Tier (emq3.3 → emq3.6) — Design-ahead, Lens B

> **Lens B — the spec-steward / invariants lens.** Every fork below is argued from the view of the
> maintainer who FREEZES and TESTS this surface for years. The weights are fixed: a public function is a
> multi-year liability; the order theorem (stream order == id sort == mint order) must extend to grouped
> reads or its boundary must be NAMED; every new Lua key declared-or-rooted; the `EchoStore.Graft` engine
> consumed UNTOUCHED across the COEXIST boundary; conformance grows by additive minor only. Where a fork
> trades consumer-ease for invariant-soundness or a smaller frozen surface, soundness wins — but the
> Steelman honors the consumer's real need, and each arm pre-empts the strongest objection the
> consumer/operability lens (Lens A) will raise.
>
> This is a **DESIGN-AHEAD for independent Operator review**, not a build. **emq3.3 is build-ready** (its
> public surface freezes now and must be forward-compatible with emq3.5's fold and emq3.6's hydration);
> emq3.4–3.6 are shaped to the horizon, not over-specified. Forks are SURFACED, never decided. Companion
> doc: Lens A (consumer/operability). The Director synthesizes; the Operator rules.

---

## §0 Context

**The tier.** EchoMQ 3.0 puts append-only event streams on the certified wire under the v2 laws — no second
protocol. The needs (from [`emq.streams.md`](../../emq.streams.md)) claim their small end explicitly: event
streams, bounded retention, a handful of consumer groups per stream, deep history without resident memory,
time-travel by mint instant, and a polyglot seam. The six-rung ladder is three milestones: **S1 the writer**
(emq3.1–3.2, SHIPPED) · **S2 the readers** (emq3.3–3.4) · **S3 the memory** (emq3.5–3.6).

**What S1 shipped (the floor every later rung stands on).**

- **emq3.1 — the verb floor.** `XADD` / `XRANGE` / `XREADGROUP` / `XACK` / `XAUTOCLAIM` / `XGROUP` ride the
  GENERIC `EchoMQ.Connector.command/3` + `pipeline/3` path — the connector is already a verb-agnostic RESP
  client, so the stream verbs reach the wire with NO connector edit and NO new `Script.new/2`
  ([`test/stream_verbs_test.exs`](../../../../echo/apps/echo_mq/test/stream_verbs_test.exs)). The stream key is
  the braced `emq:{q}:stream:<name>` via `EchoMQ.Keyspace.queue_key(q, "stream:" <> name)` — a new §6 key type
  on the queue's hashtag slot, no grammar edit.
- **emq3.2 — the writer law (`EchoMQ.Stream`).** `append/4` mints an `EVT`-branded record id host-side,
  derives the explicit XADD id by the A1 field correspondence (`<ms>-<tail22>`,
  [`stream/id.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/stream/id.ex)), and stores the 14-byte branded
  string as the `id` FIELD; `read/3..6` is the un-grouped `XRANGE` read-back → `{branded, fields_map}` tuples
  in mint order. The order theorem — **stream order == id sort == mint order** — is proven BY CONSTRUCTION in
  `EchoMQ.Stream.Id` for a single writer per stream of one namespace; multi-writer surfaces
  `{:error, :nonmonotonic}` honestly. The A1 `<ms>` is **real Unix-ms** (`Snowflake.unix_ms/1`,
  `snowflake.ex:107`) — forward-compatible with emq3.6's wall-clock `XRANGE` bounds, decided already.

**The one question the WHOLE tier must answer well, from this lens.**

> Does at-least-once GROUPED delivery — the consumer group, the crash re-claim, the trimmed-segment archive,
> the time-travel read — preserve the order theorem the writer earned BY CONSTRUCTION, AND grow the frozen
> public surface and the Lua keyspace by the smallest sound increment?

The writer's order theorem is a single-writer-per-stream property over `XADD`. A consumer GROUP introduces a
second ordering axis the writer never had: **per-consumer delivery order under re-claim** (the PEL — the
Pending Entries List). The steward's job across S2–S3 is to state EXACTLY where the writer's
mint-order==id-order guarantee continues to hold (the stream IS still ordered; `XRANGE`/`XREADGROUP … >`
still hand entries in id order) and where it CANNOT (a re-claimed entry returns to a consumer out of
real-time delivery order — the at-least-once posture's honest cost). A spec that asserts "order preserved"
without naming the PEL re-claim exception is the false-green this lens exists to catch.

---

## §1 — emq3.3 (S2 the readers): groups + the polyglot seam — BUILD-READY

**The rung's job.** A BEAM consumer group beside one non-BEAM reader on the same group: at-least-once
delivery with idempotent handlers; crash → `XAUTOCLAIM` re-delivery; the stored `id` field proven to be the
canonical receipt a polyglot client redeems. This is the rung whose public surface freezes NOW — every fork
below is weighed for a multi-year hold.

### Settled this session (carried as GIVEN — designed to, never re-litigated)

- **S-1 · The consumer is a NEW SIBLING module `EchoMQ.StreamConsumer`**, beside `EchoMQ.Consumer`, holding
  a private connector lane, reading via `XREADGROUP GROUP … >`. NOT an extension of the job `Consumer`. (The
  sibling precedent is `EchoMQ.BatchConsumer`,
  [`batch_consumer.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex) — a different claim path
  and a different handler contract earn a sibling, not a mode.)
- **S-2 · Crash re-delivery is FOLDED INTO the consumer's own beat** — each `StreamConsumer` reclaims entries
  idle past a min-idle threshold via `XAUTOCLAIM` on its cadence, mirroring the job `Consumer`'s
  reap-expired-leases beat (`consumer.ex:114-121`, the `loop/1` reap→promote→drain→park shape). NO separate
  sweep module. (This SETTLES the `EchoMQ.Stalled` separate-sweep question against the fold — see the
  steward note under F3.3-B.)
- **S-3 · The polyglot seam is proven by a RAW-CONNECTOR PARITY TEST in-suite** — read the same group with
  raw `XREADGROUP`/`XRANGE` through the bare `EchoMQ.Connector` (no `EchoMQ.Stream` helpers), asserting the
  stored `id` field is the canonical receipt a non-BEAM client redeems.

These three settle the SHAPE. The forks below settle the CONTRACT the shape freezes.

### F3.3-A — the XGROUP lifecycle: lazy ensure-on-start vs an explicit `EchoMQ.Stream.group_create`

**Arm A1 — lazy ensure-on-`StreamConsumer`-start.** On `start_link`, the consumer issues
`XGROUP CREATE <key> <group> $ MKSTREAM` (or `0` for replay-from-head) and swallows the `BUSYGROUP` reply, so
the group exists by the time the first `XREADGROUP` runs. No new public function on `EchoMQ.Stream`.

- **Rationale.** The group's existence is a precondition of the consumer reading it; the consumer is the only
  caller that needs it; co-locating the ensure with the reader means there is no lifecycle step a caller can
  forget. `MKSTREAM` covers the empty-stream-not-yet-written race.
- **5W.** *Why* — a group must exist before `XREADGROUP … >`; lazy ensure removes a setup call. *What* — an
  idempotent `XGROUP CREATE … MKSTREAM` swallowing `BUSYGROUP`, internal to `StreamConsumer.start_link`.
  *Who* — operated by the consumer process; no consumer-facing surface. *When* — emq3.3, at consumer start.
  *Where* — a private `defp ensure_group/_` inside `echo/apps/echo_mq/lib/echo_mq/stream_consumer.ex`
  (forward-tense — the rung builds it; no file link, the surface is unbuilt).
- **Steelman.** ZERO new frozen public surface — the steward's first preference. The verb already
  round-trips on the generic connector (emq3.1's `stream_verbs_test.exs` proves `XGROUP CREATE … "0"` →
  `{:ok, "OK"}` and that `BUSYGROUP` is the only collision). Idempotency is structural: `BUSYGROUP`-swallow
  makes a double-start a no-op, so restart-storms and supervisor churn never error. The lifecycle lives in
  exactly one place (One authority) and ages with the consumer, not as an independently-frozen function.
- **Steward.** The cost is a hidden policy decision: the START position (`$` = new-only vs `0` = replay) and
  whether to swallow ONLY `BUSYGROUP` (not, e.g., a `WRONGTYPE` from a name collision with a non-stream key)
  must be specced as an explicit option on `start_link`, or the lazy ensure papers over a real fault. Named
  honestly, this is a small, well-bounded internal — it adds no frozen function and no Lua key. Ages well.

**Arm A2 — an explicit `EchoMQ.Stream.group_create/4` (+ `group_destroy`) declared surface.**

- **Rationale.** Group lifecycle is an operation distinct from reading — an operator may want to declare a
  group, set its start position, or tear it down independently of any running consumer (provisioning,
  replay-from-a-chosen-point, test setup).
- **5W.** *Why* — make group lifecycle a first-class, inspectable operation. *What* — `group_create(conn, q,
  name, group, opts)` wrapping `XGROUP CREATE`, plus `group_destroy/4` (`XGROUP DESTROY`). *Who* — operators,
  test harnesses, and `StreamConsumer` (which would call it rather than inline). *When* — emq3.3. *Where* —
  new public functions on `EchoMQ.Stream` ([`stream.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/stream.ex)).
- **Steelman.** A declared surface is testable in isolation, documents the start-position choice as a typed
  option, and gives the polyglot story a symmetric Elixir-side verb (a non-BEAM client runs `XGROUP CREATE`
  directly; the BEAM gets the same as a named function). It removes the "swallow only the right error" subtlety
  from a hot path into a deliberate, doctested function.
- **Steward.** Two new public functions frozen for years to wrap one-line verbs that ALREADY round-trip on
  the generic connector — the multi-year liability the steward weighs heaviest. `XGROUP DESTROY` is a
  DESTRUCTIVE at-rest op (it drops the PEL and the group's read cursor): introducing it on `EchoMQ.Stream` at
  the readers' rung pulls a blast-radius surface forward of any demand for it, and a destructive verb is a
  high-risk freeze (the emq.4.1 `drain/3` precedent — a destructive surface earned HIGH risk and a
  blast-radius mutation battery). Thin-but-robust says: do not freeze a destructive public verb before a
  consumer needs it.

**Ranked recommendation (Lens B): A1 (lazy ensure-on-start), strongly.** Zero new frozen surface, structural
idempotency, the lifecycle in one authority co-located with its only caller — and it defers the destructive
`group_destroy` freeze until a rung actually needs it (it routes to the retention/lifecycle horizon, where a
trim/destroy family belongs together). The START-position policy is the one thing A1 must spec explicitly as a
`start_link` option, and the `BUSYGROUP`-only swallow must be a NAMED invariant (a `WRONGTYPE` is a LOUD
failure, never swallowed) — the gate-liveness discipline.

**Pre-empted Lens-A objection.** *"Lazy ensure hides the start-position decision and gives operators no way to
provision or replay a group without booting a consumer."* Answer: A1 specs the start position as an explicit
`start_link` option (`:group_start` ∈ `{:new, :head}` → `$`/`0`), so the decision is declared, not hidden; and
provisioning-without-a-consumer is exactly the explicit-verb demand that, when a real consumer presents it,
opens `group_create` as an ADDITIVE minor at its own rung — the surface stays forward-compatible because A1
adds nothing that A2 would have to contradict. The steward does not refuse the verb; it refuses to FREEZE it
before its demand exists.

### F3.3-B — the (re)start read mode + the handler contract

**The two sub-questions, argued together because they share one invariant (portability of a handler).**

**(i) On (re)start, does the consumer drain its own PEL (`XREADGROUP … 0`, the un-acked backlog) before
reading new (`>`)?**

- **Arm B-i-1 — drain-PEL-first.** On start, read `XREADGROUP GROUP g c 0` (the consumer's own pending
  backlog) to exhaustion, settle each, THEN switch to `>` (new entries). *Rationale* — a consumer that
  crashed mid-handle left entries in its PEL; at-least-once REQUIRES they be re-delivered, and the consumer's
  own PEL is the cheapest, most-local source (no idle-time threshold, no `XAUTOCLAIM` round-trip). *Steward* —
  this is the at-least-once guarantee made structural at the consumer's own boundary: without it, a
  crash-restart that beats the idle threshold could let a same-named consumer skip its own un-acked entries
  until the `XAUTOCLAIM` beat catches them, widening the re-delivery window. The PEL drain is the honest
  realization of "crash → re-delivery"; it composes cleanly with S-2's `XAUTOCLAIM` beat (the beat handles
  entries stuck on a DEAD consumer that never restarts; the PEL-drain handles a consumer that DID restart).
  Two complementary mechanisms, each with a named job — name both, or the spec under-specifies recovery.
- **Arm B-i-2 — read-`>`-only, rely on the `XAUTOCLAIM` beat for all re-delivery.** *Rationale* — one read
  mode is simpler; the settled `XAUTOCLAIM`-on-beat (S-2) already re-claims idle entries, so a restarted
  consumer's old PEL entries get re-delivered when the beat reclaims them (to itself or a sibling). *Steward* —
  fewer moving parts, but it makes re-delivery latency a function of the min-idle threshold even for the
  consumer's OWN backlog, and it leans entirely on `XAUTOCLAIM` correctness for the common case (a fast
  restart). It also blurs WHERE the recovery guarantee lives — a reviewer cannot point at one line and say
  "this is why no entry is lost."

**(ii) Does the handler contract mirror the job `Consumer`'s `%{id, payload, attempts, group}` → `:ok` |
`{:error, reason}` EXACTLY?**

- **Arm B-ii-1 — exact mirror.** The `StreamConsumer` handler takes `%{id:, payload:, attempts:, group:}` and
  answers `:ok` | `{:error, reason}`, identical to `EchoMQ.Consumer` (`consumer.ex:147`,
  `s.handler.(%{id:, payload:, attempts:, group:})`). *Rationale* — a handler portable across the job queue and
  the stream is one mental model, one test surface, one freeze. *Steelman* — this is the One-authority value
  applied to the consumer contract: the job `Consumer`, the `BatchConsumer`, and the `StreamConsumer` all
  speak the same per-item verdict shape, so a team writes ONE handler discipline and the raise→retry semantics
  (`consumer.ex:148-153` rescue/catch) are identical everywhere. The steward freezes ONE handler shape across
  three consumers instead of three. *Steward* — the cost is honesty about the FIELD SEMANTICS: `attempts` and
  `group` mean subtly different things on a stream. On the job queue `attempts` is the row's attempt counter; on
  a stream it is the PEL **delivery-count** (`XPENDING`'s per-entry delivery count) — the same TYPE
  (non-negative integer) and the same ROLE (how many times has this item been handed out), but the steward must
  SPEC that mapping so the field's meaning is declared, not assumed. `group` is the consumer-group name (a clean
  fit). With the mapping named, the mirror holds soundly.
- **Arm B-ii-2 — a stream-specific handler shape** (e.g. `%{id:, fields:, delivery_count:}`). *Rationale* —
  name the stream's own semantics precisely (`fields` not `payload`; `delivery_count` not `attempts`). *Steward*
  — precise, but it forks the handler contract into two frozen shapes, doubling the surface a team learns and
  the steward maintains, and forecloses the portable-handler story the settled sibling design implies.

**Ranked recommendation (Lens B).** **B-i-1 (drain-PEL-first) + B-ii-1 (exact mirror with a NAMED
`attempts` ↔ delivery-count mapping).** Drain-PEL-first because it makes the at-least-once guarantee
structural at the consumer's own boundary and gives a reviewer one line to point at; the exact mirror because
one frozen handler shape across three consumers is the One-authority win, PROVIDED the `attempts`↔
delivery-count semantics are specced as a named invariant (not discovered later). The settled S-2 fold and
B-i-1 are complementary, not redundant — the spec must name both jobs.

**Pre-empted Lens-A objection.** *"Drain-PEL-first adds startup latency and a second read mode; and forcing the
job handler's `attempts` name onto a stream's delivery-count is a leaky abstraction that will confuse handler
authors."* Answer on latency: the PEL drain runs only over the consumer's OWN un-acked backlog (typically
empty on a clean start, bounded by `COUNT` on a crash-restart), and it REPLACES, not adds to, the idle-window
wait B-i-2 would impose on that same backlog — it is faster for the common recovery case, not slower. Answer on
the name: the steward's mirror is a deliberate trade — `attempts` is documented as "delivery attempts" in BOTH
consumers (the field already means "how many times handed out"), so the name is honest across both, and a
handler that only reads `id`+`payload` (the idempotent-handler norm) never touches the field at all. The
portability win for the 95% handler outweighs the precision loss for the 5% that inspects the count — and the
mapping is NAMED, so nothing is hidden.

### F3.3-C — the conformance grain (+1 capability vs +N decomposition)

**Arm C1 — +1 capability scenario, deep proofs ride property/loop.** Add ONE new conformance scenario
(`stream_group`, the at-least-once-grouped-delivery capability) to
`EchoMQ.Conformance.scenarios/0`; the crash→`XAUTOCLAIM` re-delivery, the PEL-drain, and the polyglot parity
are proven in the rung's OWN suite (the raw-connector parity test S-3, an `XAUTOCLAIM` re-delivery test, a
restart-PEL-drain test) — not as four separate conformance rows.

- **Rationale.** Conformance is the WIRE-LEVEL invariant registry, not the test count; one capability =
  one scenario, with the depth carried where depth belongs. This mirrors emq3.2's D-3 (+1 conformance,
  property/loop carries the order proof) and emq.5.1's D-3 reasoning (the capability is the scenario; the
  isolation depth rides the suite).
- **5W.** *Why* — keep the conformance set a registry of distinct WIRE capabilities, not a test ledger.
  *What* — `scenarios/0` grows by exactly 1 (current count re-probed at reconcile — program-law records 18 as
  the founding+emq.1 floor; the live count climbs with each shipped Movement-II/Stream rung and MUST be
  re-probed against `conformance.ex` at the rung's reconcile, never asserted from this doc). *Who* —
  Apollo/Director verify the count is the prior N byte-unchanged + 1 probe-registered. *When* — emq3.3, with
  the scenario landed in the same change as its probe. *Where* —
  [`conformance.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/conformance.ex) `scenarios/0` + both pinning
  tests re-pinned.
- **Steelman.** The additive-minor law is exactly this: extend `scenarios/0` with the new scenario, register
  its probe in the SAME change, keep every prior scenario byte-unchanged (git-verified). +1 keeps the
  registry legible — a reader sees one row per wire capability, and the count is a meaningful number, not a
  proxy for test effort. The deep proofs (re-claim, PEL-drain, parity) are exercised where they can be
  exercised richly (a live suite with crash injection), which a single conformance row cannot host anyway.
- **Steward.** The discipline the steward must enforce: the ONE scenario must itself be liveness-honest — a
  `stream_group` scenario that appends, reads via `XREADGROUP`, and `XACK`s WITHOUT ever asserting a
  re-delivery (a crash path that actually re-hands an entry) is a no-op that satisfies its own letter while
  proving nothing (the TRD.9.1 false-green class). So C1's acceptance must require the scenario's positive
  proof: an un-acked entry, an idle-window elapse (or a forced `XAUTOCLAIM`), and an assertion the SAME entry
  returns. With that, +1 is sound.

**Arm C2 — +N decomposition (one scenario per proof: group-lifecycle, at-least-once-ack, crash-re-delivery,
polyglot-parity → +4).** *Rationale* — each invariant gets its own named, independently-pinned conformance
row, maximally legible at the registry. *Steward* — four new frozen scenarios for one capability inflates the
registry, couples the count to a single rung's internal proof structure, and sets a precedent (every future
rung adds N) the conformance set cannot sustainably carry. It also duplicates into the registry what the rung
suite already proves richly — a DRY violation across two test surfaces.

**Ranked recommendation (Lens B): C1 (+1), strongly** — with the named liveness requirement that the single
scenario POSITIVELY proves re-delivery (not a no-op). One wire capability, one registry row, the depth where
depth belongs.

**Pre-empted Lens-A objection.** *"+1 hides the crash-re-delivery and polyglot proofs from the canonical
conformance run — an operator reading `run/2` output won't see them and won't trust them."* Answer: the
canonical conformance run is the cross-RUNTIME wire contract (what a polyglot client can rely on at the
protocol boundary), not the BEAM consumer's recovery test ledger — crash-injection and process-restart are
BEAM-suite concerns by nature (a conformance scenario is a wire round-trip, not a process kill). The single
`stream_group` scenario DOES carry the load-bearing wire fact an operator needs to trust — that an un-acked
entry is re-deliverable through the group — with a positive assertion; the richer recovery proofs live in the
rung suite where they belong and where the Director re-runs them at review. Legibility is served by naming, not
by count inflation.

---

## §2 — emq3.4 (S2 the readers): retention as policy

**The rung's job.** Per-stream bounded retention declared as policy — `MAXLEN` (approx) and mint-time
`MINID` windows — that the trim provably honors: a read inside the window never misses; outside, it answers
truthfully. (Shaped to the horizon; emq3.3's frozen surface must not foreclose it — see §5.)

### F3.4-A — WHERE the trim lives

- **Arm A1 — trim-on-append (the writer trims each `XADD` with `MAXLEN ~`/`MINID`).** *Rationale* — Valkey's
  `XADD … MAXLEN ~ <n>` trims in the same round-trip as the append, the cheapest possible trim (no extra
  command, no separate process). *Steward* — the steward's caution: trim-on-append couples retention POLICY to
  the WRITE path, so a policy change requires the writer to carry the policy, and `append/4`'s signature (today
  `append(conn, queue, name, fields)`) would grow a retention argument or read a policy — a change to a FROZEN
  emq3.2 public function. That is the freeze-cost the steward weighs heaviest. It also makes the order theorem's
  audit harder: trimming during append is fine for `MAXLEN ~` (approx, never drops below the cap), but a wrong
  `MINID` policy fed through the writer could silently drop entries inside a window the reader expects.
- **Arm A2 — a dedicated `EchoMQ.Stream.trim/_` retention surface (an explicit call or a registered policy
  the trim consults).** *Rationale* — retention is an operation distinct from append; a dedicated surface
  decouples policy from the write path and keeps `append/4` frozen. *Steward* — a NEW public function frozen
  for years, but it is the One-authority home for retention (a policy declared once, applied by one verb), and
  it leaves the emq3.2 writer untouched (Do-no-harm to the frozen surface). The steward's preferred shape: a
  thin `trim(conn, q, name, policy)` over `XTRIM`, with the POLICY a declared value (F3.4-B), not a default.
- **Arm A3 — the `StreamConsumer`'s beat trims.** *Rationale* — the consumer already beats; folding the trim
  into the beat (like the `XAUTOCLAIM` reap) costs no new process. *Steward* — this couples retention to the
  PRESENCE of a consumer (a stream with no running `StreamConsumer` would never trim), which makes the
  retention guarantee conditional on an operational fact — exactly the silent-no-op class the steward refuses.
  Retention is a property of the STREAM, not of whether a consumer happens to run.

**Ranked recommendation (Lens B): A2 (a dedicated trim surface consuming a declared policy)** — it keeps the
frozen `append/4` untouched (Do-no-harm), homes retention in One authority, and does not make the guarantee
conditional on a consumer running. A1's trim-on-append is the operability-cheapest and may win on Lens A's
latency argument; the steward's counter is that it mutates a frozen public surface and couples policy to the
write path. **This is a fork I expect to DIVERGE on** — surfaced for the Operator.

**Pre-empted Lens-A objection.** *"A dedicated trim surface needs someone to CALL it — a stream nobody trims
grows unbounded, whereas trim-on-append is automatic and free."* Answer: the steward's A2 does not preclude
automatic trimming — the dedicated `trim/_` is the MECHANISM; the cadence that calls it is a separate, named
decision (an opt-in cadence child on the `EchoMQ.Pump` precedent, or the `StreamConsumer` beat calling the
public `trim/_` when a policy is registered). A2 separates "how to trim" (frozen, tested once) from "when to
trim" (an operational policy), so the automatic case is available WITHOUT baking the policy into the writer's
frozen signature. The freeze-cost asymmetry decides it for this lens: a new dedicated verb is additive; a
changed `append/4` is a frozen-surface mutation.

### F3.4-B — the policy DECLARATION surface ("declared not defaulted")

- **Arm B1 — a call argument** (`trim(conn, q, name, {:maxlen_approx, n})` / `{:minid_instant, dt}`).
  *Steward* — the policy is explicit at every call site and never hidden, but a long-lived stream's retention
  is then re-stated at each call (a DRY risk if multiple call sites trim one stream).
- **Arm B2 — a registered policy map** (a per-stream policy registered once, the trim verb consults it).
  *Steward* — One authority for a stream's retention (declared once, consulted by the trim), the steward's
  preference for a long-lived property; the cost is a new registry surface to freeze and a lookup the trim
  depends on.
- **Arm B3 — a Keyspace-side policy key** (`emq:{q}:stream:<name>:retention`, a hash the trim reads).
  *Steward* — this puts retention policy IN the keyspace under the braced grammar (declared-keys clean — it
  shares the `{q}` slot), inspectable by a polyglot reader, and durable across BEAM restarts. The cost: a NEW
  §6 subkey type, which (per the architect skill's subkey-cleanup law) MUST name its cleanup disposition — what
  retires `…:retention` when the stream is destroyed. An un-named cleanup is a silent at-rest leak. With the
  cleanup NAMED (the stream-destroy/obliterate path enumerates it), B3 is sound and gives the polyglot seam a
  policy it can read.

`MAXLEN` **approx (`~`)** vs exact: approx is the steward's default — `~` lets Valkey trim at macro-node
boundaries (cheaper, never drops below the cap), and "a read inside the window never misses" holds for approx
(it keeps AT LEAST the cap). Exact `MAXLEN` is a stricter, costlier trim reserved for a named compliance need.
`MINID` by **mint-instant** leans directly on the A1 real-Unix-ms mapping (emq3.2, already decided) — a
`DateTime` → `MINID` bound is the same map emq3.6's time-travel uses, so B and emq3.6 share one conversion.

**Ranked recommendation (Lens B): B2 (registered policy) for the BEAM-only case, B3 (keyspace policy key) if
the polyglot reader must SEE the retention policy** — both declare-not-default; the choice turns on whether
policy visibility crosses the polyglot seam, which is the Operator's call. Approx `MAXLEN`, mint-instant
`MINID`.

**Pre-empted Lens-A objection.** *"A registered/keyspace policy is ceremony — most consumers just want
`MAXLEN 10000` and move on."* Answer: the call-arg arm B1 IS available for the simple case and the steward
does not refuse it; the registered/keyspace arms exist for the LONG-LIVED stream whose retention is a stable
property (the DRY win), and "declared not defaulted" is the tier's own stated requirement, not steward
ceremony — a defaulted retention is exactly the silent policy this lens refuses.

---

## §3 — emq3.5 (S3 the memory): the archive — HIGHEST stakes, the COEXIST boundary

**The rung's job.** Fold trimmed stream segments into the native `EchoStore.Graft` engine (CubDB → Tigris);
deep reads = segment (Graft/Tigris) + live-tail (stream) merged with NO gap and NO overlap. **The COEXIST
law is absolute: the native `EchoStore.Graft.*` engine is CANONICAL and UNTOUCHED — the fold CONSUMES it as a
peer, never edits it** (`store.design.md` §0; the engine modules
[`echo_store/lib/echo_store/graft/`](../../../../echo/apps/echo_store/lib/echo_store/graft/) — `VolumeServer`,
`Streamer`, `Sync`, `Segment`, `Reader` — are read-only to this rung).

### F3.5-A — the fold mechanism

- **Arm A1 — a DEDICATED `StreamConsumer` instance folding trimmed segments into the Graft engine.** A
  consumer group reads the stream, and as the retention window advances, the about-to-be-trimmed slice is
  handed to the Graft engine via its EXISTING public surface (`EchoStore.Graft.VolumeServer.commit/3`,
  `volume_server.ex:50` — the single-writer mailbox; the engine then streams pages to Tigris via its own
  `Streamer`, `streamer.ex`, and announces on its own `graft:<vol>:commits` feed, `sync.ex:41`). The fold is a
  CONSUMER of the engine; it issues no edit to any `EchoStore.Graft.*` module.
  - *Rationale* — the fold is a reader-and-writer-elsewhere: it reads the stream slice and writes it to the
    engine through the engine's own front door. A consumer instance is the natural home (it already holds a
    lane, beats, and acks).
  - *Steelman.* This is the COEXIST law realized literally: the engine stays canonical and untouched, the fold
    rides its committed public surface (`commit/3` is the engine's documented write path; the `Streamer` and
    `Sync` are the engine's own, already shipped). The order theorem extends cleanly — the segment is a stream
    SLICE in id order, committed as one Graft commit, so the archived order == the stream order == mint order,
    BY CONSTRUCTION (the same proof S1 earned, carried to the archive). The fold being a property of an engine
    already in place is what makes the archive nearly free (the tier's own claim).
  - *Steward.* The steward's load-bearing concern is the WATERMARK contract (F3.5-B): the fold must commit
    EXACTLY the slice that trim removes — no entry archived twice, none dropped between the fold and the trim.
    This forces an ORDERING invariant: **fold-before-trim** (archive the slice, confirm the Graft commit, THEN
    `XTRIM` past it), so a crash between fold and trim re-archives an already-archived slice (idempotent —
    safe, the Graft commit is keyed by segment id) rather than trimming an un-archived slice (lossy —
    forbidden). Named that way, A1 is sound and touches no engine code. The `open_volume/2` facade named in
    `store.design.md` §3 is the design-§ surface for opening a Volume with `remote_cfg`; the as-built
    write path is `VolumeServer.commit/3` (`volume_server.ex:50`) — the spec must cite the as-built `commit/3`
    and treat `open_volume/2` as the design-doc facade name (re-probe at the rung's reconcile; do not assert
    its arity from this doc).
- **Arm A2 — the trim path emits segments directly** (the `EchoMQ.Stream.trim/_` surface, on trimming, hands
  the trimmed bytes to the engine inline). *Rationale* — fewer processes; the trim already touches the exact
  slice being removed, so it is the natural emit point. *Steward* — this couples the archive to the trim verb
  and pulls a cross-app dependency (echo_mq → echo_store's Graft engine) INTO the trim path, widening the
  boundary the steward guards (a bus rung reaching into the store engine inline is a diff that crosses two
  apps in one hot path). It also makes the fold-before-trim ordering a SINGLE-verb atomicity problem (commit
  to Graft AND trim must both succeed or neither) — harder to make crash-safe than A1's separable
  fold-then-trim.

**Ranked recommendation (Lens B): A1 (a dedicated fold consumer over the engine's public surface)** — it
honors COEXIST literally (no engine edit, the engine's own `commit/3`/`Streamer`/`Sync` do the durable work),
it makes the watermark contract a separable fold-before-trim ordering (crash-safe by idempotent re-archive),
and it keeps the boundary clean (the fold consumer is the one place echo_mq meets the Graft engine, through
the front door). **This is the highest-stakes fork and one I expect to DIVERGE on** — Lens A may prefer A2's
fewer-processes inline emit.

**Pre-empted Lens-A objection.** *"A dedicated fold consumer is another process to run and monitor, and
reading-then-committing is two round-trips where the trim already has the bytes."* Answer: the fold consumer
is the SAME `StreamConsumer` shape already shipped at emq3.3 (no new process TYPE, just an instance with a
fold handler), and the two-step fold-then-trim is not overhead — it is the crash-safety REQUIREMENT: the
archive MUST be durable before the trim removes the only other copy, which an inline single-verb emit cannot
guarantee atomically across two systems (the bus stream and the Graft/Tigris engine). The steward trades one
monitored process for a recovery guarantee a reviewer can state in one sentence ("nothing is trimmed until
its segment is committed"). Cross-app boundary integrity and crash-safety outweigh a saved process.

### F3.5-B — the merge-read (segment + live-tail, no gap, no overlap)

The deep read answers a range that spans archived segments (in Graft/Tigris) and the live tail (still in the
stream). The steward's whole concern here is the WATERMARK — the single value that says "everything strictly
below this id is in a segment; everything at-or-above is in the live stream."

- **The invariant (this lens's contract).** Let `W` be the trim watermark (the highest mint-id whose segment
  is committed AND whose entry is trimmed from the live stream). The merge-read of range `[lo, hi]` is:
  `segment_read([lo, min(hi, W)])` ++ `live_read([max(lo, W⁺), hi])`, where `W⁺` is the next id above `W`.
  Because A1 enforces fold-before-trim, every id `≤ W` is in a segment (no gap) and no id `> W` is in a
  segment (no overlap) — the merge is a clean concatenation at `W`, and because both halves are read in id
  order and `W` is a clean cut, the merged result is in mint order END-TO-END (the order theorem extended
  across the archive boundary). The watermark `W` is itself a branded id, so it sorts with everything else —
  no second index, no separate clock.
- **Where `W` lives.** Two sub-arms: (1) `W` is the Graft engine's own high-water (the last committed
  segment's top id) READ from the engine (no new bus state — the steward's preference, One authority for the
  archive's extent lives with the archive); (2) `W` is a bus-side keyspace watermark
  (`emq:{q}:stream:<name>:archived`, a string) the fold updates and the merge-read consults (visible to a
  polyglot reader, but a NEW §6 subkey that must name its cleanup, the subkey-leak law). The steward leans (1)
  for soundness (the archive's extent is the archive's truth — deriving it from the engine cannot drift from
  the engine) but surfaces (2) as the polyglot-visibility arm.

**Ranked recommendation (Lens B): the watermark-cut merge with `W` derived from the Graft engine's committed
extent (sub-arm 1)** — it makes the no-gap/no-overlap property a CONSEQUENCE of fold-before-trim rather than a
second invariant to maintain, and it keeps the archive's extent in One authority (the engine). Surface (2) for
the Operator if the polyglot reader must compute the merge cut itself.

**Pre-empted Lens-A objection.** *"Reading the watermark from the Graft engine on every deep read is a
cross-app round-trip in the read path — a bus-side cached watermark key is faster."* Answer: the watermark is
read ONCE per deep-read (not per entry), and the read-path cost is dominated by the segment fetch from
Tigris/CubDB anyway; the soundness win (the cut cannot drift from the archive's true extent) is worth one
small read. If measurement shows the watermark read is hot, sub-arm (2)'s cached keyspace value is the
additive optimization — but the steward refuses to make a polyglot-visible bus key the SOURCE OF TRUTH for the
engine's extent (two authorities for one fact is the drift surface). Cache it, derive it, but the engine owns it.

---

## §4 — emq3.6 (S3 the memory): time-travel + hydration

**The rung's job.** Mint-instant → `XRANGE` bounds (leaning on emq3.2's real-Unix-ms, already decided); and
Table hydration from a stream tail (the changelog read, latest-per-key, no compactor). Shaped to the horizon.

### F3.6-A — the time-travel API surface

- **Arm A1 — `read_since(conn, q, name, dt)` / `read_between(conn, q, name, dt1, dt2)`** on `EchoMQ.Stream`.
  *Rationale* — a `DateTime` maps to a `MINID`/`XRANGE` bound by `DateTime.to_unix(dt, :millisecond)` →
  the A1 `<ms>` field (emq3.2's real-Unix-ms is exactly what makes this land on the right entries,
  `stream/id.ex` moduledoc — "load-bearing for emq3.6's wall-clock `XRANGE`"). *Steelman* — two thin, named,
  total functions over `XRANGE` with a documented `DateTime`→bound conversion; the conversion is ALREADY
  proven sound by the A1 construction (the ms field is true Unix-ms), so the freeze rests on a property S1
  already earned. The steward freezes a small, sound surface whose correctness is a corollary of an existing
  theorem. *Steward* — the one subtlety to spec: a `DateTime`→ms bound is a HALF-OPEN interval question
  (`read_between` inclusive/exclusive at each end) and a precision question (ms granularity — two mints in the
  same ms differ only in the tail), so the surface must name its interval semantics and that sub-ms ordering
  ties break by the full branded id, not by `dt`. Named, the surface is sound and ages well.
- **Arm A2 — a single `read_range(conn, q, name, bound, bound)` taking a polymorphic bound** (a `DateTime` OR
  a branded id OR `-`/`+`). *Rationale* — one function, fewer frozen names. *Steward* — fewer names, but a
  polymorphic bound argument is a typing liability (the function's contract is a union the caller must read
  carefully) and blurs the `DateTime`-specific interval/precision semantics A1 names explicitly. The steward
  prefers two named functions with clear semantics over one polymorphic function with a union contract.

**Ranked recommendation (Lens B): A1 (named `read_since`/`read_between` with explicit interval + tie-break
semantics)** — small, sound, its correctness a corollary of A1's existing theorem; named semantics over a
polymorphic union.

**Pre-empted Lens-A objection.** *"Two functions where one polymorphic `read_range` would do is more surface
to learn."* Answer: the two functions encode the two ACTUAL use shapes (everything since a time; everything
between two times) with names that read at the call site, and the `DateTime`-interval semantics differ enough
from a branded-id bound that folding them into one polymorphic argument hides exactly the precision subtlety
the steward must spec. Two clear names cost less over years than one union the caller must decode.

### F3.6-B — Table hydration from a stream tail

- **Arm B1 — a changelog read (latest-per-key) feeding an `EchoStore.Table`,** with the "hydrate-then-fence
  equals loader truth" gate. The stream tail is read in mint order; the latest entry per key wins (newer-wins
  by mint order — the staleness fence's law, BCS 4.2); the resulting latest-per-key set hydrates a Table via
  its EXISTING public surface (`EchoStore.Table.put/4` with the 14-byte version, `table.ex:97`, or
  `apply_batch/2`, `table.ex:152`). *Rationale* — the tier already has changelog semantics for free (versioned
  claims + Tables, newer-wins by mint order); hydration is reading the tail and applying latest-per-key.
  *Steelman.* This consumes the Table's committed surface (COEXIST with the store, same discipline as the
  Graft fold) and leans on the ALREADY-LAW newer-wins admission — no compactor, no new merge logic. The gate
  is sharp and falsifiable: hydrate from the tail, then apply the live fence, and assert the Table equals the
  loader's direct truth (the same value a cold loader would compute). The order theorem makes
  latest-per-key well-defined (mint order IS the version order), so "latest" is unambiguous. *Steward* — the
  contract to name: hydration reads the tail UP TO a point and the live fence takes over above it — the
  hand-off point is a watermark (same shape as F3.5-B's `W`), and the gate must prove the hand-off has no gap
  (an entry between the hydration cut and the fence start is neither hydrated nor fenced = lost). With the
  hand-off watermark named and gated, B1 is sound and edits no store code.
- **Arm B2 — hydration as a store-side concern** (the Table pulls its own tail). *Steward* — this would push
  stream-reading logic INTO `EchoStore.Table`, crossing the boundary the wrong way (the store consuming the
  bus's read semantics), and risks editing the canonical Table surface. The steward refuses a hydration that
  edits the store; the bus-side fold (B1) consuming the Table's public `put/4`/`apply_batch/2` is the COEXIST-
  clean shape.

**Ranked recommendation (Lens B): B1 (a bus-side changelog read feeding the Table's public surface), with a
NAMED hand-off watermark and the no-gap hydrate-then-fence gate** — it consumes the Table untouched, leans on
the already-law newer-wins, and the order theorem makes latest-per-key well-defined.

**Pre-empted Lens-A objection.** *"Hydration that stops at a watermark and hands off to the live fence is a
two-mechanism dance — simpler to just replay the whole tail every boot."* Answer: replay-the-whole-tail is
exactly what the bounded-retention + archive tier is built to AVOID (the tail is bounded; old state lives in
the archive); hydration reads the live tail's latest-per-key and the fence carries forward — the watermark
hand-off is the same `W`-cut discipline F3.5-B already establishes, so it is ONE mechanism the tier uses
twice, not a new dance. And the gate (hydrate-then-fence == loader truth) makes the hand-off correctness
falsifiable, which a "replay everything" approach cannot cheaply prove for a bounded stream.

---

## §5 — The forward-compatibility thread (why this is designed-ahead)

emq3.3 freezes a public surface NOW. The load-bearing reason to design emq3.4–3.6 first is to prove that
frozen surface does not have to be BROKEN later. The thread, fork-by-fork:

1. **`StreamConsumer`'s handler contract (F3.3-B-ii) must be the fold's and the hydration's handler too.**
   emq3.5's fold consumer (F3.5-A, A1) and emq3.6's hydration (F3.6-B) are BOTH `StreamConsumer` instances
   with a specific handler. If emq3.3 freezes the handler as `%{id, payload, attempts, group}` → `:ok` |
   `{:error, reason}` (B-ii-1), the fold handler ("commit this slice to Graft, ack on success") and the
   hydration handler ("apply latest-per-key to the Table") are ordinary handlers of that frozen shape — no
   new consumer contract at emq3.5/3.6. A stream-specific handler (B-ii-2) that emq3.5 then had to EXTEND
   would be a frozen-surface break. **B-ii-1 is the forward-compatible freeze.**

2. **The XGROUP lifecycle (F3.3-A) must not freeze a destructive verb the fold/retention rungs will own.**
   `group_destroy`/`XGROUP DESTROY` is a DESTRUCTIVE at-rest op that belongs with the retention/archive
   family (emq3.4–3.5), not the readers' rung. A1 (lazy ensure, no `group_destroy` at emq3.3) keeps the
   destructive surface UNFROZEN until the rung that owns destruction can spec it with a blast-radius gate
   (the emq.4.1 `drain/3` precedent). Freezing `group_destroy` at emq3.3 (A2) would commit a destructive
   contract before its owning rung exists.

3. **The watermark shape (`W`) is ONE concept used by emq3.5 (the archive cut) AND emq3.6 (the hydration
   hand-off).** Designing both ahead reveals they are the SAME branded-id cut — a single watermark
   discipline (everything strictly below is elsewhere; everything at-or-above is live), not two. emq3.3 must
   leave the stream's id-ordering and the stored `id`-field receipt UNTOUCHED so a watermark cut is always a
   clean branded-id comparison (which the order theorem guarantees). emq3.3 freezes nothing that would
   prevent a `W`-cut.

4. **The A1 real-Unix-ms (emq3.2, shipped) is the shared conversion for emq3.4's `MINID` mint-instant AND
   emq3.6's time-travel bounds.** Already decided and shipped — the forward thread here is to NOT introduce
   any emq3.3 surface that re-derives time differently; the one `DateTime`→ms map serves retention and
   time-travel both. emq3.3 introduces no time-based read, so it cannot fork the conversion.

5. **The retention trim home (F3.4-A) must not force a change to the FROZEN emq3.2 `append/4`.** The
   steward's A2 (a dedicated `trim/_` surface) keeps `append/4` frozen; A1 (trim-on-append) would mutate it.
   Designing emq3.4 ahead surfaces that emq3.3 should freeze NO retention behavior into the writer or
   consumer, leaving retention a clean additive surface — so whichever trim home the Operator rules, emq3.3
   has foreclosed nothing.

6. **The conformance grain (F3.3-C) sets the precedent for emq3.4/3.5/3.6.** +1-per-capability (C1) means each
   later Stream rung adds ONE scenario (retention, archive-merge, time-travel) — a sustainable registry. +N
   (C2) at emq3.3 would set a precedent the registry cannot carry across four more rungs. C1 is the
   forward-compatible conformance discipline.

**The one-line thesis.** Freeze at emq3.3: the sibling `StreamConsumer`, the mirrored `%{id, payload,
attempts, group}` handler, the lazy-ensure group lifecycle (no destructive verb), the +1 conformance grain,
and the untouched stream id-ordering. Every emq3.4–3.6 surface above is then ADDITIVE over that freeze — no
later Stream rung re-breaks emq3.3's public contract, exactly as the master invariant demands of the wire.

---

## §6 — Fork ledger (Lens B ranked arm + one-line reason)

| Fork | Ranked arm (Lens B) | One-line reason |
|---|---|---|
| **F3.3-A** XGROUP lifecycle | **A1** lazy ensure-on-start | Zero new frozen surface; idempotent by `BUSYGROUP`-swallow; defers the destructive `group_destroy` freeze. |
| **F3.3-B-i** (re)start read mode | **B-i-1** drain-PEL-first | At-least-once made structural at the consumer's own boundary; complements (not duplicates) the settled `XAUTOCLAIM` beat. |
| **F3.3-B-ii** handler contract | **B-ii-1** exact mirror | One frozen handler shape across three consumers; forward-compatible with the emq3.5 fold + emq3.6 hydration handlers — IF `attempts`↔delivery-count is NAMED. |
| **F3.3-C** conformance grain | **C1** +1 capability | One wire capability = one registry row; depth rides the suite; +1 is the sustainable additive-minor precedent — IF the scenario positively proves re-delivery. |
| **F3.4-A** trim home | **A2** dedicated `trim/_` surface | Keeps frozen `append/4` untouched (Do-no-harm); retention in One authority; not conditional on a consumer running. **(Expect divergence.)** |
| **F3.4-B** policy declaration | **B2** registered map (or **B3** keyspace key if polyglot-visible) | Declare-not-default for a long-lived stream property; approx `MAXLEN`, mint-instant `MINID`. |
| **F3.5-A** fold mechanism | **A1** dedicated fold consumer over the engine's public `commit/3` | COEXIST honored literally (no engine edit); fold-before-trim is crash-safe by idempotent re-archive. **(Highest stakes; expect divergence.)** |
| **F3.5-B** merge-read watermark | **watermark-cut, `W` derived from the Graft engine extent** | No-gap/no-overlap is a CONSEQUENCE of fold-before-trim, not a second invariant; the engine owns its own extent (One authority). |
| **F3.6-A** time-travel surface | **A1** `read_since`/`read_between` | Small, sound; correctness a corollary of A1's shipped theorem; named interval/tie-break over a polymorphic union. |
| **F3.6-B** Table hydration | **B1** bus-side changelog → Table's public `put/4`/`apply_batch/2` | Consumes the Table untouched (COEXIST); leans on already-law newer-wins; the order theorem makes latest-per-key well-defined. |

---

## §7 — What I deliberately did NOT decide (the discipline)

Every fork above is SURFACED with a ranked recommendation and a pre-empted opposing objection — none is
decided. The discipline:

- **Every fork is the Operator's.** Each row of §6 is a recommendation with its one reason; the choice belongs
  to the Operator after the Director synthesizes Lens A against Lens B. An architect that picks the winner has
  stopped being a steward.
- **The three forks I most expect to DIVERGE from Lens A** — flagged for the Director: **F3.4-A** (trim home:
  the steward's dedicated `trim/_` vs Lens A's likely trim-on-append for latency), **F3.5-A** (fold mechanism:
  the steward's dedicated fold consumer vs Lens A's likely inline trim-emit for fewer processes), and
  **F3.3-A** (XGROUP lifecycle: the steward's no-destructive-verb-yet vs Lens A's likely explicit
  `group_create`/`group_destroy` for operability). These are where a genuine divergence is the most useful
  signal the Operator receives.
- **No canon edit.** This is design-ahead. `emq.streams.md`, `emq.design.md`, and `store.design.md` are
  reconcile-only here — no body of any of them is redesigned. Where this doc's recommendation would change a
  canon body (e.g. naming the PEL re-claim exception to the order theorem in `emq.streams.md`), that is itself
  a Venus surface for the Operator, not an edit I make.
- **No engine edit, no code, no git, no build/test.** The COEXIST boundary is absolute: every `EchoStore.Graft.*`
  surface cited is read-only. This doc touches exactly one file (itself).
- **The far rungs are shaped, not over-specified.** emq3.4–3.6 are argued to the depth needed to PROVE emq3.3's
  freeze is forward-compatible (§5) — not to the build-ready depth emq3.3 carries. Their triads are authored at
  their own rungs, against the as-built code that exists then.

---

## §8 — Surface citations (every named surface grounded)

**As-built (verified at source this session):**

- `EchoMQ.Stream.append/4`, `append_id/5`, `append_batch/4`, `read/3..6`, `stream_key/2` —
  [`echo/apps/echo_mq/lib/echo_mq/stream.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/stream.ex).
- `EchoMQ.Stream.Id.xadd_id/1` (A1 map, `<ms>-<tail22>`), `evt?/1`, `kind/0`; the order theorem proof; the
  `<ms>` = real Unix-ms (`Snowflake.unix_ms/1`) —
  [`echo/apps/echo_mq/lib/echo_mq/stream/id.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/stream/id.ex).
- `EchoMQ.Connector.command/3` (`connector.ex:49`), `pipeline/3` (`:58`), `eval/5` (`:65`), `subscribe/2`
  (`:111`); `@wire_version "echomq:2.4.2"` (`connector.ex:35`) —
  [`echo/apps/echo_wire/lib/echo_mq/connector.ex`](../../../../echo/apps/echo_wire/lib/echo_mq/connector.ex).
- `EchoMQ.Keyspace.queue_key/2` (the braced `emq:{q}:<type>`, `keyspace.ex:14`), `job_key/2` (the branded
  gate) — [`echo/apps/echo_mq/lib/echo_mq/keyspace.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/keyspace.ex).
- `EchoMQ.Consumer` — the `loop/1` reap→promote→drain→park beat (`consumer.ex:114`), the
  `%{id, payload, attempts, group}` → `:ok` | `{:error, reason}` handler (`consumer.ex:147`), the rescue/catch
  raise→retry (`consumer.ex:148-153`), `stop/2`, the `:metronome` mode —
  [`echo/apps/echo_mq/lib/echo_mq/consumer.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/consumer.ex).
- `EchoMQ.BatchConsumer` — the SIBLING precedent (a different claim path + handler shape earns a sibling,
  emq.5.2-D1), the watch-depth cadence, the per-member verdict-map handler, the settle-points control
  discipline — [`echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/batch_consumer.ex).
- `EchoMQ.Stalled` — the EXPLICIT separate-sweep precedent (weighed against the settled fold-into-beat, S-2);
  server `TIME` in-script, declared-keys —
  [`echo/apps/echo_mq/lib/echo_mq/stalled.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/stalled.ex).
- The emq3.1 verb floor — `XADD`/`XRANGE`/`XREADGROUP`/`XGROUP CREATE`/`XACK`/`XAUTOCLAIM` round-trip on the
  generic connector; `XGROUP CREATE … "0"` → `{:ok, "OK"}`; `BUSYGROUP` the collision; push-safety —
  [`echo/apps/echo_mq/test/stream_verbs_test.exs`](../../../../echo/apps/echo_mq/test/stream_verbs_test.exs).
- `EchoMQ.Conformance.scenarios/0` + `run/2` (the additive-minor registry; live count re-probed at reconcile)
  — [`echo/apps/echo_mq/lib/echo_mq/conformance.ex`](../../../../echo/apps/echo_mq/lib/echo_mq/conformance.ex).
- The native `EchoStore.Graft.*` engine (COEXIST, UNTOUCHED, read-only to every Stream rung):
  `VolumeServer.commit/3` (`volume_server.ex:50`, the single-writer mailbox), `Streamer.commit_ready/2`
  (`streamer.ex:34`, → Tigris), `Sync.publish`/`subscribe_commits` over the `graft:<vol>:commits` feed
  (`sync.ex:21,30,41`), `Segment.build/3` + `remote_key/1` → `segments/<id>` (`segment.ex:35,75`) —
  [`echo/apps/echo_store/lib/echo_store/graft/`](../../../../echo/apps/echo_store/lib/echo_store/graft/).
- `EchoStore.Table.fetch/3` (`table.ex:63`), `put/3` (`:90`), `put/4` with the 14-byte version (`:97`),
  `apply_coherence/4` (`:115`), `apply_batch/2` (`:152`) — the hydration target, COEXIST/untouched —
  [`echo/apps/echo_store/lib/echo_store/table.ex`](../../../../echo/apps/echo_store/lib/echo_store/table.ex).

**Forward-tense (surface a Stream rung BUILDS — not yet on disk; named here for the design only):**

- `EchoMQ.StreamConsumer` (emq3.3 builds it — the BEAM consumer-group sibling; `start_link`, the private
  connector lane, the `XREADGROUP … >` beat with the folded `XAUTOCLAIM` re-claim, the PEL-drain-on-start, the
  mirrored handler) — `echo/apps/echo_mq/lib/echo_mq/stream_consumer.ex` (forward-tense).
- `EchoMQ.Stream.group_create/4` / `group_destroy/4` (F3.3-A arm A2, NOT recommended; named for the fork only).
- `EchoMQ.Stream.trim/_` (emq3.4 builds it — the dedicated retention surface, F3.4-A arm A2, recommended);
  `read_since/4` / `read_between/5` (emq3.6 builds them — F3.6-A arm A1, recommended) — all forward-tense on
  `EchoMQ.Stream`.

**Design-§ grounded (named in canon, arity to be re-probed at the owning rung's reconcile, not asserted here):**

- `EchoStore.Graft.open_volume/2` with `remote_cfg` — named in `store.design.md` §3 as the Volume-open facade;
  the as-built write path this doc cites is `VolumeServer.commit/3` (re-probe `open_volume` at emq3.5's
  reconcile; do not assert its arity from this doc) —
  [`store.design.md`](../../store/design/store.design.md) §0, §3.
- The retention requirement (`MAXLEN ~` approx / mint-time `MINID`), the archive answer (fold trimmed segments
  to the Graft engine, deep reads = segment + live-tail merge), the time-travel and hydration gates — all named
  in [`emq.streams.md`](../../emq.streams.md) (the ladder, "the durable-archive answer", the milestones).
- The v2 laws (braced keyspace, branded ids at the builder, declared Lua keys, server clock, additive-minor
  conformance), the master invariant, the subkey-cleanup law —
  [`.claude/skills/echo-mq-program.md`](../../../../.claude/skills/echo-mq-program.md);
  [`emq.design.md`](../../emq.design.md) (S-1..S-7, §6 grammar, §10 seams).

---

*Lens B — the spec-steward / invariants lens. Authored independently; the sibling Lens A draft was not read.
Convergence is confidence; divergence is the signal. The Director synthesizes; the Operator rules.*
