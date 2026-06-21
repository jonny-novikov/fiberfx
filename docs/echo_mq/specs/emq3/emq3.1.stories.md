# EMQ3.1 — stories (S1 the writer, part 1 — the stream verbs on the connector)

> The acceptance face of [`emq3.1.md`](emq3.1.md) (the body is authoritative — if a story disagrees with the body,
> the body wins). Every Deliverable becomes a Connextra user story with concrete Given/When/Then acceptance
> (Gherkin/BDD); each names the invariant(s) it exercises; the Coverage map at the foot proves every Deliverable
> traces to a story. **STRAWMAN — the four forks are OPEN; the stories are authored to the RECOMMENDED arm of each
> (FORK 3.1-A ride the generic path · 3.1-B the `emq:{q}:stream:<name>` type +1 scenario · 3.1-C the `2.6.0` label
> · 3.1-D non-blocking only). A different ruling re-derives the affected stories at the post-build reconcile.**
>
> **The standing liveness law (the gate-must-exercise-its-outcome rule).** Each round-trip story is a POSITIVE
> proof: a present precondition (a live stream / a created group / a pending entry) MUST run the verb and assert the
> reply against the appended data — a vacuous pass (a round-trip that asserts nothing about the reply, or an
> `XRANGE` over an empty stream proving nothing about the append) is a LOUD failure, never a silent green. US3's
> push-safety MUST actually deliver a concurrent push out of band while a stream verb round-trips in band — a
> push-safety proof with no concurrent push proves nothing and fails its own letter.
>
> **The forks are OPEN (the recommended arms the stories assume).** US1/US2/US3 are authored to the OBSERVABLE
> outcome — the verbs round-trip on the certified connector, push-safe — which holds for BOTH arms of FORK 3.1-A
> (the verbs reach the wire whether through the generic path or a typed seam); the recommended arm is **ride the
> generic command path** (`Connector.command/3`, ZERO `echo_wire` edit). The count is **74** (FORK 3.1-B recommended
> +1 — `stream_verbs`). The label is **`2.6.0`** (FORK 3.1-C recommended — open the family). The blocking-read bound
> is **non-blocking only** (FORK 3.1-D recommended — `XREADGROUP BLOCK` deferred to emq3.3).

---

## US1 — The five stream verbs round-trip on the certified connector

**As an** event-stream consumer, **I want** the five stream verbs (`XADD` · `XRANGE` · `XREADGROUP` · `XACK` ·
`XAUTOCLAIM`) to round-trip end-to-end on the certified connector, **so that** every later Stream rung (the writer
law, the readers, retention) stands on a proven verb floor — the family reaches the wire, the replies parse, no new
wire surface required.

- **Exercises:** EMQ3.1-INV1 (the verbs ride the shipped generic command path, no `echo_wire` edit), EMQ3.1-INV2
  (every verb round-trips end-to-end), EMQ3.1-INV5 (the braced `emq:{q}:stream:<name>` key on the `{q}` slot),
  EMQ3.1-INV6 (additive registration, the wire unbroken).

```gherkin
Given a RESP3 connection to Valkey on 6390 and a stream key emq:{q}:stream:s built by Keyspace.queue_key(q, "stream:s")
When each stream verb is issued as a parts list through the shipped Connector.command/3 (the FORK 3.1-A generic path)
Then XADD emq:{q}:stream:s * field value answers a bulk entry-id string (the appended entry's id)
  And XRANGE emq:{q}:stream:s - + reads back the EXACT appended entry as [id, [field, value]] (a nested array, parsed by RESP.parse/1)
  And XGROUP CREATE + XREADGROUP GROUP g c COUNT n STREAMS emq:{q}:stream:s > (NO BLOCK) returns the stream's entries for the group
  And XACK emq:{q}:stream:s g <id> answers the integer count of acked entries (1)
  And XAUTOCLAIM emq:{q}:stream:s g c2 0 0 answers the [cursor, claimed-entries, deleted-ids] triple
  And every verb reaches the wire through the shipped generic command path — no echo_wire edit (git diff echo_wire = empty)
  And {emq}:version reads echomq:2.4.2 (the @wire_version unchanged — additive registration, no wire break)
```

- **Liveness (no vacuous pass):** each verb MUST be asserted against the APPENDED data — `XRANGE` reads back the
  exact `[id, [field, value]]` appended by `XADD` (not merely "a non-error reply"); `XREADGROUP` returns the entry
  the group has not yet seen; `XACK` returns `1` for a genuinely-pending entry; `XAUTOCLAIM` re-claims a
  genuinely-pending entry. A round-trip that asserts nothing about the reply, or an `XRANGE` over an empty stream,
  is a LOUD failure (the verb proved nothing).
- **Fork note (the observable outcome):** US1's outcome — the five verbs round-trip on the certified connector —
  holds for BOTH arms of FORK 3.1-A (the verbs reach the wire whether through the generic path or a typed connector
  seam); the recommended arm is **ride the generic command path** (`Connector.command/3`, `connector.ex:47-54`,
  ZERO `echo_wire` edit). The empty-`echo_wire`-diff assertion is load-bearing on the recommended arm (it proves
  the connector is untouched); on the frozen-touch arm it relaxes to "the one named connector seam is the only
  `echo_wire` edit."

---

## US2 — The pipelined `XADD` batch (N entries, one round-trip, replies in order)

**As a** high-throughput event producer, **I want** to append N entries to a stream in one pipeline, **so that** I
amortize the per-entry round-trip across the batch — N entry-ids back in call order, read back in mint order, the
connector the sole owner of the wire (no second pipelining mechanism).

- **Exercises:** EMQ3.1-INV3 (the pipelined `XADD` batch returns replies in call order), EMQ3.1-INV2 (the entries
  round-trip), EMQ3.1-INV5 (the braced stream key).

```gherkin
Given a RESP3 connection and a stream key emq:{q}:stream:s
When N command-lists ["XADD", "emq:{q}:stream:s", "*", "field", "v1".."vN"] are issued through the shipped Connector.pipeline/3
       (or an EchoWire.Pipe threaded with command/2, the ewr.1.2 escape hatch — exec/1 is literally one pipeline/3 call)
Then it answers {:ok, [id1, id2, ..., idN]} with exactly N entry-ids, one per appended entry, in call order
  And a subsequent XRANGE emq:{q}:stream:s - + reads back exactly N entries in mint order (the server * ids are monotonic)
  And the connector remains the sole owner of the wire (no second pipelining mechanism — exec/1 = one pipeline/3 call, pipe.ex:16-22)
```

- **Liveness:** the pipeline MUST append N >= 2 entries (a 1-entry "pipeline" proves nothing about batching) and
  assert exactly N ids returned in order AND N entries read back in mint order; a batch that returns fewer than N
  ids, or entries out of mint order, is a LOUD failure (the append path regressed).
- **As recommended:** the batch rides the shipped `Connector.pipeline/3` (`connector.ex:56-60`) or `EchoWire.Pipe`
  with the `command/2` escape hatch (`pipe.ex:496-497`); emq3.1 adds no pipelining mechanism (FORK 3.1-A — the
  connector is the sole owner).

---

## US3 — Push-safety: in-band stream verbs do not disturb the out-of-band push routing

**As a** consumer running both a stream and the lifecycle-event pub/sub on one RESP3 connection, **I want** the
in-band stream verbs (`XADD`/`XRANGE`/`XACK`) to round-trip WITHOUT corrupting the out-of-band `{:push, …}` routing
the `EchoMQ.Events` seam depends on, **so that** a stream and the event feed share one wire without ambiguity — the
RESP3 push/in-band separation the connector already guarantees.

- **Exercises:** EMQ3.1-INV4 (push-safety — in-band stream verbs do not disturb the out-of-band push routing),
  EMQ3.1-INV2 (the stream verbs round-trip).

```gherkin
Given a RESP3 connection subscribed to a channel (the EchoMQ.Events pub/sub seam — push frames arrive out of band as {:push, …})
When an in-band XADD + XRANGE + XACK sequence round-trips on the SAME connection while a push is published to the channel
Then the stream replies are correct (XADD → an id, XRANGE → the appended entry, XACK → the count) — the FIFO stays aligned
  And the concurrent push is STILL delivered out of band (a {:push, …} frame, never enqueued on the reply FIFO — resp.ex:60)
  And NO stream verb issued in the proof carries a BLOCK argument (the blocking XREADGROUP BLOCK form is DEFERRED to emq3.3, FORK 3.1-D)
  And the non-blocking XREADGROUP / XAUTOCLAIM forms (no BLOCK) return immediately on the FIFO
```

- **Liveness (no vacuous pass):** the proof MUST actually deliver a concurrent push out of band WHILE a stream verb
  round-trips in band — a push-safety proof with no concurrent push, or one where the push is enqueued on the reply
  FIFO (corrupting it), is a LOUD failure. The "no `BLOCK`" assertion is load-bearing: a grep of the proof's verb
  forms MUST find no `BLOCK` argument (the blocking read is emq3.3's, FORK 3.1-D — a `BLOCK` on the single-owner
  socket stalls every caller behind it).
- **The honest bound (FORK 3.1-D):** emq3.1 scopes to non-blocking round-trips; the blocking consumer-group read
  (`XREADGROUP BLOCK`) lands at emq3.3 (the readers), where the blocking-read posture is designed against the
  single-owner socket (the `push_command/3` out-of-band precedent, `connector.ex:99-102`, or the emq.4.3 metronome
  single-`BLPOP`-owner pattern).

---

## US4 — The wire stays frozen (additive registration is a protocol minor)

**As a** maintainer of the frozen wire, **I want** the stream verbs to land as an additive registration — the
`@wire_version` byte-unchanged, no new wire class, no new script — **so that** the Stream Tier opens without
re-breaking the wire (the master invariant: the fork happened once, every later rung is additive).

- **Exercises:** EMQ3.1-INV1 (no `echo_wire` edit on the recommended arm), EMQ3.1-INV6 (additive registration, the
  wire unbroken), EMQ3.1-INV5 (the §6 grammar unedited).

```gherkin
Given the frozen wire — @wire_version "echomq:2.4.2" (connector.ex:35), the five-code fence union, the closed EMQKIND/EMQSTALE registry
When emq3.1 lands the stream-verb floor (the recommended FORK 3.1-A arm — the verbs ride the shipped generic command path)
Then the echo_wire git diff is EMPTY (the connector is untouched — the verbs are parts lists through the shipped command/3)
  And {emq}:version reads echomq:2.4.2 (the @wire_version byte-unchanged — additive registration, no wire break)
  And NO new inline Script.new/2 is added (emq3.1 is verb plumbing — the verbs are issued direct, not via Lua)
  And the §6 grammar in keyspace.ex is unedited (the stream key type rides the total queue_key/2 — no grammar edit)
  And the closed wire-class registry (EMQKIND/EMQSTALE) is byte-unchanged (a stream verb is not a job-kind refusal)
```

- **Liveness:** the `echo_wire` empty-diff is run over the ACTUAL `git diff` against HEAD and asserted empty on the
  recommended arm; a non-empty `echo_wire` diff on the recommended arm is a LOUD failure (an unintended wire touch
  — the rung would have become HIGH without the ruling). On the frozen-touch arm (FORK 3.1-A ruled the other way)
  this relaxes to "the one named connector seam is the only `echo_wire` edit, and Apollo is mandatory."

---

## US5 — Additive-minor conformance growth (the count re-pin)

**As a** keeper of the conformance harness, **I want** the stream-verb scenario(s) registered with their probes in
the same change and the prior set kept byte-unchanged, **so that** the bus contract grows only by additive minor —
the Stream Tier opens by additive registration, a port still conforms by translation.

- **Exercises:** EMQ3.1-INV7 (the additive-minor conformance law), EMQ3.1-INV2 (the scenario exercises the verb
  round-trips).

```gherkin
Given the live conformance set is 73 scenarios (conformance_run_test.exs asserts {:ok, 73} at :58;
       conformance_scenarios_test.exs @run_order = 73 names — the prior set, byte-unchanged contract)
When emq3.1 registers the stream-verb scenario(s) in scenarios/0 (FORK 3.1-B recommended +1 — stream_verbs:
       the five verbs round-trip + a pipelined XADD batch + push-safe under RESP3, one capability)
Then the git-diff of scenarios/0 shows ONLY the addition(s) (the prior 73 names + contracts + verdict bodies byte-unchanged, git-verified)
  And each new scenario's probe is registered in the SAME change (a present precondition — a live stream — runs the verb round-trips with a positive proof)
  And the count re-pins 73 -> 74 (the recommended FORK 3.1-B +1) in BOTH pinning tests
       (conformance_run_test.exs {:ok, 74} + conformance_scenarios_test.exs @run_order)
  And Conformance.run/2 prints the new total of lines and returns {:ok, 74} against the truth row (Valkey on 6390)
```

- **Liveness:** the new scenario is not vacuous — `stream_verbs` asserts the served replies against the appended
  data (US1) + the pipelined-batch order (US2) + the push-safety (US3); a scenario that issues the verbs and
  asserts nothing about the replies fails its own letter (the gate-must-exercise-its-outcome rule).
- **Fork note:** the count is **74** on the recommended FORK 3.1-B arm (+1, `stream_verbs` as one verb-floor
  capability). If the Operator rules the per-verb decomposition, the count steps **73 → 78** (+5) and this story +
  INV7 re-derive — surfaced.

---

## US6 — Honest-row proof + the determinism posture (a multi-seed sweep, NOT the ≥100 loop)

**As an** evaluator (Apollo, an optional fast-finisher on the recommended FORK 3.1-A arm — verb plumbing, no
shipped-script edit), **I want** the proof run against the truth row with the determinism posture HONEST to a
verb-plumbing rung, **so that** a green board reflects the real engine and the real (absent) mint hazard — never a
host that lacks Valkey, and never a ≥100 loop claimed where no id is minted.

- **Exercises:** the honest-row law (S-4), EMQ3.1-INV8 (the determinism posture — a multi-seed sweep, the verb path
  mints no id and starts no process); closes the rung's proof.

```gherkin
Given the live engine is Valkey on port 6390 (valkey-cli -p 6390 ping -> PONG)
When the per-app gate ladder runs inside echo/apps/echo_mq (TMPDIR=/tmp, --include valkey)
Then compile --warnings-as-errors is clean (exit 0), the :valkey stream-verb suite is green, Conformance.run/2 -> {:ok, 74}
  And the determinism proof is a MULTI-SEED SWEEP (several --seed values green) — NOT the >=100 loop
       (the verb path mints no branded id and starts no process: the same-millisecond mint hazard the loop owns is ABSENT)
  And the echo_wire git diff is EMPTY (the recommended FORK 3.1-A arm — the connector untouched)
  And the claims are phrased against Valkey, current stable line (a host without Valkey runs the probes elsewhere and reports them as that row, never the truth row)
```

- **Determinism rationale:** unlike the emq.5.1 batch-claim spine (which minted branded JOB-ids to flood the
  pending set and leased on the server clock → a mint/lease surface → the ≥100 loop REQUIRED), emq3.1's verb path
  mints no id (the stream append uses the server `*` id; the branded record id is emq3.2's writer law) and starts no
  process (it is a host fn over the shipped connector) — so the honest posture is a multi-seed sweep + the explicit
  statement, NOT the ≥100 loop. IF the proof is later found to mint a branded id (it should not — that is emq3.2's
  law), the posture flips to the ≥100 loop (the escalation named, INV8).

---

## US-GATE — the standing conformance gate (every emq.* rung)

**As the** program, **I want** the full conformance harness green against the truth row at the rung's close, **so
that** the bus contract is provably whole after the verb floor lands.

```gherkin
Given Valkey on 6390 is up (PONG) and the fence reads the live @wire_version (echomq:2.4.2)
When EchoMQ.Conformance.run/2 runs over a live connection at the rung's close
Then it prints one line per scenario and returns {:ok, 74} (the re-pinned total — 73 + the FORK-3.1-B +1 stream_verbs scenario)
  And both pinning tests pass (the pure registry test + the wire run test, count re-pinned to 74)
```

---

## Coverage map (every Deliverable → its story)

| Deliverable (from [`emq3.1.md`](emq3.1.md) Goal/Scope/DoD) | Story | Invariant(s) |
|---|---|---|
| The five stream verbs reachable + proven on the generic command path (FORK 3.1-A recommend: ride the path) | US1 | INV1, INV2, INV5, INV6 |
| A pipelined `XADD` batch (N entries, replies in call order) | US2 | INV3, INV2, INV5 |
| Push-safety under RESP3 (in-band verbs do not disturb the out-of-band push routing; no `BLOCK` — FORK 3.1-D) | US3 | INV4, INV2 |
| The `emq:{q}:stream:<name>` §6 braced key type (FORK 3.1-B recommend, via the total `queue_key/2`) | US1, US2 | INV5 |
| The wire stays frozen — no `echo_wire` edit, no new script, no new wire class (FORK 3.1-A recommend) | US4 | INV1, INV6, INV5 |
| The prior conformance scenarios byte-unchanged + the count re-pin 73 → 74 (FORK 3.1-B recommend +1) | US4, US5, US-GATE | INV6, INV7 |
| The `stream_verbs` conformance scenario (additive minor — the verb floor as one capability) | US1, US2, US3, US5 | INV2, INV7 |
| The `:valkey` stream-verb suite + a multi-seed sweep + honest-row (NOT the ≥100 loop — no id mint) | US6 | S-4, INV8 |
| The conformance harness green (`{:ok, 74}`) at the rung's close | US-GATE | INV7 |

**Traceability note (correct by definition):** every Deliverable in the body maps to at least one story above, and
every story names the invariant(s) it exercises; completion is provable from this text — a Deliverable with no
green story is not done. US1/US2/US3 are authored to the OBSERVABLE outcome (the verbs round-trip on the certified
connector, push-safe) — which holds for both FORK 3.1-A arms; the recommended ruling (ride the generic path) pins
the empty-`echo_wire`-diff assertion without changing what US1/US2/US3 assert. The count is **74** (FORK 3.1-B
recommend +1), the label is **`2.6.0`** (FORK 3.1-C recommend), and the blocking-read bound is **non-blocking only**
(FORK 3.1-D recommend); US5/US-GATE/US3 are pinned to those recommended values, re-derived at the post-build
reconcile if the Operator rules otherwise.
