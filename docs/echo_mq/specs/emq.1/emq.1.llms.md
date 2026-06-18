# EMQ.1 · agent brief (llms)
> **Status: BUILT** — the emq-1 run adopted the design gate (the six settled forks), built D2–D6,
> hardened, and gated PASS; this brief is reconciled to the as-built surface. It was design-gated: the
> first story was the A-1-compatible scheduler design (adopted as the six forks), and no build story ran
> before that gate. Pairs with [`./emq.1.md`](emq.1.md) and [`./emq.1.stories.md`](../../epics/emq.epic.1/emq.1.stories.md).
> Framing clause (propagates into every derived prompt): third person for any agent reference; no gendered
> pronouns for agents; no perceptual or interior-state verbs for agents or software; components read,
> compute, refuse, return.

## References

- [`./emq.1.md`](emq.1.md) — the contract (D1–D7, INV1–INV7); the spec body is authoritative.
- [`./emq.1.stories.md`](../../epics/emq.epic.1/emq.1.stories.md) — acceptance (US1–US7, incl. the standing EMQ.1-US-GATE).
- The worked consumer (no-invent applies to its real surface exactly as to this code):
  `echo/apps/codemojex` — guesses enqueued on per-player `EchoMQ.Lanes`, drained by two `EchoMQ.Consumer`
  instances (score + settle), scored under a single authority, prizes settled on a second queue
  (move-then-settle), `EchoMQ.Events` published. Forward, echo_bot (`echo/apps/echo_bot`) will reach for
  this vocabulary to fan Telegram notifications at scale (today a direct synchronous `sendMessage`, no bus
  coupling). The capability row anchors the scheduled/repeatable/retry shape, with retriable follow-ups
  and a periodic sweep consumer as honest uses.
- The capability row: `docs/echo/code/ROADMAP.md` §2.1 (retry vocabulary + poison-job drill;
  scheduled/repeatable with the visibility-fence constraint; connector auto-resubscribe).
- The design law: [`../emq.design.md`](../../emq.design.md) §11.10 (the scheduler family deferral — "root key
  operands in data values, structurally inexpressible under the declared-keys invariant"; "an
  A-1-compatible flow design is real design work for the family rungs") · §1 S-6 (declared keys) · §5
  (wire classes; additive-minor growth WITH probes) · §4 row 30 (backoff above the wire — HOLDS) · §6
  (the grammar any new key must satisfy).
- As-built anchors (re-pinned at the Stage-4 reconcile against the as-built tree):
  `EchoMQ.Jobs.retry/7` (`echo/apps/echo_mq/lib/echo_mq/jobs.ex:298` — answers `:scheduled | :dead`,
  `last_error` kept) · `EchoMQ.Jobs.promote/3` (`jobs.ex:324`) · the new `enqueue_at/5` (`jobs.ex:67`) +
  `enqueue_in/5` (`jobs.ex:78`) over the inline `@schedule` script (`jobs.ex:38-56`) · `EchoMQ.Repeat`
  (`repeat.ex`) · `EchoMQ.Backoff.delay_ms/2` (`backoff.ex:46`) · `EchoMQ.Pump` + `EchoMQ.Pump.Core`
  (`pump.ex`, `pump/core.ex`) · the schedule-and-release behavior the conformance scenarios assert
  (`conformance.ex` — `scenarios/0` is 18) · `EchoMQ.Connector.subscribe/2` (`connector.ex:109`) +
  `unsubscribe/2` (`:119`) + the recorded subscription set (`:158`) re-issued by `resubscribe/1`
  (`:606`) in the `:reconnect` success arm (`:334`) · the `EchoWire` facade
  (`echo/apps/echo_wire/lib/echo_wire.ex`, the `unsubscribe/2` defdelegate added).
- Upstream rung: [`./emq.0.md`](../emq.0/emq.0.md) — the gate ladder this rung must keep green.

## Requirements

- **EMQ.1-R1** — the design gate: the A-1-compatible scheduler/repeat key design, ≥2 steelmanned
  alternatives + ADR, every key spelled against the design §6 grammar, Operator approval recorded BEFORE
  any build artifact. [US: EMQ.1-US6]
- **EMQ.1-R2** — run-at/run-in scheduled enqueue: fresh branded `JOB` mints, parked on the schedule set,
  invisible to claim until due, released by promotion; no new structure outside the declared grammar.
  [US: EMQ.1-US1]
- **EMQ.1-R3** — repeatables: register/cancel verbs; each occurrence a fresh mint; declared keys.
  [US: EMQ.1-US2]
- **EMQ.1-R4** — the backoff vocabulary: host-side policy computing `delay_ms` for `Jobs.retry/7`;
  max-attempts honored; the poison-job drill recorded (dead-letter at exactly the cap, `last_error`
  browsable). [US: EMQ.1-US3]
- **EMQ.1-R5** — the promote pump: supervised, opt-in, pure decision core, stated restart semantics;
  sweeps via `Jobs.promote/3` only. [US: EMQ.1-US4]
- **EMQ.1-R6** — connector auto-resubscribe: the subscription set re-issues after `:reconnect`; the
  facade extended additively if at all. [US: EMQ.1-US5]
- **EMQ.1-R7** — proof: every addition registered with a conformance scenario/probe (the registry grows
  14 → 18 — `schedule`/`repeat`/`backoff`/`resubscribe`); the prior 14 scenarios byte-unchanged and
  green; pure + `:valkey` suites per app; the emq.0 ladder still green. [US: EMQ.1-US7]
- **EMQ.1-R8** — the carried laws: per-app testing only + `TMPDIR=/tmp`; toolchain re-probed, never
  hardcoded; Valkey 6390 PONG precondition; `apps/echomq` untouched; no agent git; lock-delta law;
  every surface written "emq.1 builds" until the build ships. [US: all]

## Execution topology

Runtime (the shape emq.1 builds — forward-named):

```text
echo_mq:    the scheduler verb family (EchoMQ.Jobs.enqueue_at/5 + enqueue_in/5) + the repeat surface
            (EchoMQ.Repeat) = modules composing Connector calls (the Jobs pattern); the backoff vocabulary
            (EchoMQ.Backoff) = a pure module (policy → delay_ms); the promote pump (EchoMQ.Pump) = ONE
            supervised, opt-in GenServer with a pure decision core (EchoMQ.Pump.Core; cadence → promote/3
            + the repeat sweep; :transient restart) — the first process the bus app owns, still
            caller/owner-started (library law: no mod:).
echo_wire:  the Connector keeps its shape; the :reconnect path re-issues the recorded subscription set
            (a MapSet in connector state, added on subscribe/2, removed on unsubscribe/2); the EchoWire
            facade gains one unsubscribe/2 defdelegate.
New Lua:    INLINE Script.new/2 module attributes per the as-built convention (NOT priv/) — @schedule in
            jobs.ex, @register/@cancel/@advance in repeat.ex; every key declared in KEYS[] (INV2); each
            addition registered with its conformance scenario (the additive-minor law, design §5).
```

Tasks (the build run's DAG — D1 gates everything):

```text
B0 pre-build reconcile (lag-1: pin the schedule-set/registry anchors against the as-landed tree)
→ B1 EMQ.1-AS1 the design gate (ADR; STOP for Operator approval)
→ B2 AS2 scheduled enqueue → B3 AS3 repeatables → B4 AS4 backoff + the drill
→ B5 AS5 the pump → B6 AS6 resubscribe → B7 AS7 conformance additions + the full ladder
```

Touched files (as built): `echo/apps/echo_mq/lib/echo_mq/{jobs.ex, repeat.ex, backoff.ex, pump.ex,
pump/core.ex, conformance.ex}` (the new surfaces + the conformance registry; the scripts are INLINE in
`jobs.ex`/`repeat.ex`, no `priv/`), `echo/apps/echo_wire/lib/echo_mq/connector.ex` (the resubscribe seam)
+ `echo/apps/echo_wire/lib/echo_wire.ex` (the `unsubscribe/2` defdelegate), the two apps' test trees.
Nothing in `apps/echomq`; nothing in any other app; `mix.lock` unchanged (INV6).

## Agent stories

- **EMQ.1-AS1** [implements EMQ.1-US6] — Directive: author the A-1-compatible scheduler design (the key
  shapes for schedule + repeat under the §6 grammar; ≥2 steelmanned alternatives incl. the do-nothing
  baseline; the ADR), then STOP and surface it for the Operator's ruling. Acceptance gate: the approval is
  recorded in the run's ledger; no build artifact predates it.
- **EMQ.1-AS2** [implements EMQ.1-US1] — Directive: build run-at/run-in per the approved design.
  Acceptance gate: the `:valkey` suite proves park-until-due + release-by-promotion + fresh mints; the
  declared-keys analysis passes.
- **EMQ.1-AS3** [implements EMQ.1-US2] — Directive: build the repeat surface per the approved design.
  Acceptance gate: two occurrences carry different fresh ids in mint order; cancel removes the
  registration; the analysis passes.
- **EMQ.1-AS4** [implements EMQ.1-US3] — Directive: build the backoff vocabulary over `Jobs.retry/7` +
  the poison-job drill. Acceptance gate: the drill records dead-letter at exactly max attempts with
  `last_error` browsable; `retry`'s wire surface unchanged.
- **EMQ.1-AS5** [implements EMQ.1-US4] — Directive: build the supervised opt-in pump over
  `Jobs.promote/3`. Acceptance gate: due entries claimable within one cadence; a worker without the pump
  unchanged; the crash-restart check holds.
- **EMQ.1-AS6** [implements EMQ.1-US5] — Directive: build the reconnect re-issue in the Connector.
  Acceptance gate: the socket-kill drill — prior subscriptions answer after reconnect without a caller
  restart.
- **EMQ.1-AS7** [implements EMQ.1-US7] — Directive: register every addition's conformance scenario/probe;
  run the full proof. Acceptance gate: the prior 14 scenarios byte-unchanged and green; the new scenarios
  green; the emq.0 gate ladder green end-to-end.

## Execution plan — first two stories

1. **EMQ.1-AS1 — the design gate.** Read the §11.10 deferral + the §6 grammar + the as-landed keyspace
   module; author the ADR (alternatives: extend the closed type registry with a schedule/repeat member vs
   ride the existing schedule set with registered subkeys vs the do-nothing baseline — each spelled byte
   by byte against the grammar); STOP for the Operator.
2. **EMQ.1-AS2 — scheduled enqueue.** Only after the ruling: build the verb family per the approved
   shapes; gate: the park/release `:valkey` suite + the declared-keys analysis.

## Comprehensive implementation prompt

```text
ROLE: the emq.1 build seats (Venus authored EMQ.1-AS1, the design gate, adopted as the six settled forks;
Mars built AS2–AS7 after the design was adopted). The spec body docs/echo_mq/specs/emq.1.md is
authoritative; this brief derives from it. THIS RUNG IS BUILT — the surfaces below are real; this prompt
is retained as the build directive Mars built from, anchors re-pinned to as-built at the Stage-4 reconcile.
FRAMING: third person for agents; no gendered pronouns; no perceptual/interior-state verbs for agents or
software; components read, compute, refuse, return.

THE GATE (inviolable): EMQ.1-AS1 first — the A-1-compatible scheduler design. The v1 scheduler family is
deferred precisely because its forms root key operands in data values (design §11.10); the design must
spell EVERY schedule/repeat key against the §6 grammar (declared in KEYS[] or derived from a declared
root), with >= 2 steelmanned alternatives + the ADR, honoring the 2.1 constraint verbatim: mint-ordered
ids stay the sort key; a delay is a visibility fence, not a new queue. STOP after the ADR; the Operator
rules; only then do build stories run.

LAWS (carried from emq.0 + the design):
- B0 pre-build reconcile first: pin every key/registry anchor against the AS-LANDED tree (post-emq.0);
  the as-built anchors (re-pinned at Stage-4) are Jobs.retry/7 (jobs.ex:298), Jobs.promote/3 (jobs.ex:324),
  Connector.subscribe/2 (connector.ex:109) + unsubscribe/2 (:119), the :reconnect re-issue resubscribe/1
  (:606) called in the success arm (:334).
- Additive minors only: every new scenario/probe registers in the same change (design §5); the registry
  grows 14 → 18, the prior 14 conformance scenarios stay byte-unchanged and green (INV1).
- Declared keys everywhere; no exemption at any grain (S-6; INV2).
- Backoff computes host-side; the wire takes literal delays (INV4). Fresh branded JOB mint per
  occurrence; no second ordering scheme (INV3).
- The pump is supervised, OPT-IN, pure-cored, with stated restart semantics (INV5).
- Per-app tests only + TMPDIR=/tmp; toolchain re-probed (asdf current erlang), never hardcoded; Valkey
  6390 PONG before wire steps; apps/echomq untouched; no agent git; the lock-delta law (INV6).
- The consumer's needs are codemojex's REAL ones (`echo/apps/codemojex` — guesses on per-player lanes, a
  single scoring authority, prize settlement on a second queue) — cite the real surface, never invent
  consumer requirements; keep echo_bot's notification reach forward-tense.

BUILD ORDER: B0 reconcile → B1 design+STOP → B2 run-at/run-in → B3 repeatables → B4 backoff+drill →
B5 the pump → B6 resubscribe → B7 conformance additions + the emq.0 ladder end-to-end.

REPORT: the ADR + ruling reference; per-story acceptance-gate outputs (the park/release suite, the
occurrence mints, the drill's exact-cap dead-letter, the cadence check, the socket-kill drill); the
declared-keys analysis result; the conformance tallies (14 prior + the additions); the full ladder tails;
the INV checks. Completion claim only when every DoD box in emq.1.md is checkable from the outputs.
```
