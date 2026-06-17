# EMQ.1 · The scheduler + the retry vocabulary — Movement I opens
> **Status: BUILT** (design-gate adopted, built, hardened, and gated PASS in the emq-1 run; this body is
> the post-build reconcile against the as-built tree, the spec authoritative as the contract). emq.1
> builds, inside `echo/apps/echo_mq` under the v2 laws, the time-and-retry vocabulary the drop's own
> roadmap names thin and the Exchange platform records as its input — designed A-1-compatible FIRST (the
> opening design gate, [`./emq.1.design.md`](emq.1.design.md), adopted-as-built), then built. The six
> design forks settled (the relocated EMQ.1-D1 gate's decisions — recorded in the design doc §8 and the
> run ledger D-1..D-7); the surfaces below are real, named at their as-built `file:line`.

## Goal

emq.1 builds the bus's time vocabulary for its named consumer: scheduled enqueue (run-at / run-in as a
visibility fence over the schedule set — never a new queue), repeatable jobs (each occurrence a fresh
branded `JOB` mint, so mint-ordered ids stay the sort key), the attempts-with-backoff retry vocabulary
above the wire with the poison-job drill closing the max-attempts blind spot, a supervised promote pump
(the cadence that releases due work through the existing `promote` verb), and connector auto-resubscribe
after reconnect — all additive on the v2 wire (declared keys, branded identity, conformance probes
registered with every addition), opened by an Operator-gated A-1-compatible scheduler design.

## Rationale (5W)

- **Why** — three sources name the same gap. The drop's ROADMAP 2.1 calls it "the vocabulary the referee
  found thin": the retry vocabulary ("attempts-with-backoff on the lease/reap base; the max-attempts blind
  spot … closes here, gated by a poison-job drill"), scheduled and repeatable jobs (with the stated design
  constraint: "mint-ordered ids stay the sort key; a delay is a visibility fence, not a new queue"), and
  connector auto-resubscribe ("today the table's restart is the resubscription"). The Exchange platform —
  the program's named consumer — records its needs against exactly that row: "scheduled and repeatable
  jobs remain the EchoMQ roadmap's 2.1 row, with this platform's needs recorded there as an input"
  (`docs/exchange/exchange.specs.md` §Jobs; the same trace in `docs/exchange/exchange.roadmap.md`
  §Dependencies). And the design defers the scheduler script family typed-never-silent with the open
  problem named: the v1 family's forms "root key operands in data values, structurally inexpressible under
  the declared-keys invariant"; "an A-1-compatible flow design is real design work for the family rungs"
  ([`../emq.design.md`](../../emq.design.md) §11.10) — that design work opens this rung.
- **What** — emq.1 builds: a scheduled-enqueue verb family `EchoMQ.Jobs.enqueue_at/5` + `enqueue_in/5`
  (`jobs.ex:67`/`:78`) over the existing schedule set, both served by ONE inline `@schedule` script
  (`jobs.ex:38-56`) that branches on an `ARGV` mode flag — `'at'` takes the caller's absolute run-at
  millisecond as the score, `'in'` computes the score wire-side from `TIME` (the server-clock law);
  repeatable-job registration (`EchoMQ.Repeat`) whose every occurrence is a fresh `JOB` mint; a host-side
  backoff vocabulary (`EchoMQ.Backoff.delay_ms/2`, `backoff.ex:46`) feeding the as-built
  `EchoMQ.Jobs.retry/7` (`jobs.ex:298` — the wire half already answers `:scheduled | :dead` with
  `last_error` kept); the poison-job drill (a persistently failing handler dead-letters at max attempts,
  browsable in the morgue); a supervised, opt-in promote pump (`EchoMQ.Pump`, pure core `EchoMQ.Pump.Core`)
  over the as-built `EchoMQ.Jobs.promote/3` (`jobs.ex:324`), sweeping both promote and the repeat
  registry each tick; and `EchoMQ.Connector` re-issuing its recorded subscription set after `:reconnect`
  (the re-issue at `connector.ex:606`, called in the `:reconnect` success arm `connector.ex:334`;
  `subscribe/2` at `connector.ex:109`, the companion `unsubscribe/2` at `connector.ex:119`).
- **Who** — the Exchange platform's Jobs surface: "Settlement, notifications, end-of-day reporting,
  reconciliation: `EchoMQ.Jobs` with branded job ids, drained by `EchoMQ.Consumer`, shaped by
  `EchoMQ.Lanes` with one group per venue" (`exchange.specs.md` §Jobs); the batched settlement trigger
  TRD.3's feedback asks about ("per-fill or batched" — `exchange.roadmap.md`); the OMS's "periodic sweep"
  reconciliation consumer (`exchange.strategies.md` Pattern IV); the claims-bus subscribers that must
  survive a reconnect (the auto-resubscribe consumer). Plus every umbrella consumer of the bus.
- **When** — Movement I's opening rung, after emq.0 closes; SPECCED in the emq-0 run, BUILT next run; the
  A-1 scheduler design gate settles with the Operator BEFORE the build starts.
- **Where** — `echo/apps/echo_mq` (the verb family on `EchoMQ.Jobs`, `EchoMQ.Repeat`, `EchoMQ.Backoff`,
  `EchoMQ.Pump` + `EchoMQ.Pump.Core`; the new Lua is INLINE `Script.new/2` module attributes per the
  as-built convention — `@schedule` in `jobs.ex`, `@register`/`@cancel`/`@advance` in `repeat.ex` — not
  `priv/` files; no `echo_mq/priv/` directory exists, and every key is declared in `KEYS[]` per the
  declared-keys law either way) and `echo/apps/echo_wire` (the connector resubscribe in
  `lib/echo_mq/connector.ex`; the `EchoWire` facade extended by the one `unsubscribe/2` defdelegate).
  `apps/echomq` untouched and frozen.

## Scope

- **In** — the A-1-compatible scheduler design (the gate); the four capability clusters above; the
  conformance-scenario and probe additions that register every new surface; pure + `:valkey` suites; the
  poison-job drill as a recorded check.
- **Out** — per-instrument stream lanes (`XADD`, consumer groups — TRD.6's recorded dependency on
  conn.1–conn.2 of the connector's forward specification, its own ladder, never this rung); batched
  settlement shaping (the batches family, emq.5 — the Exchange spec maps batched settlement to the as-built
  one-flush pipeline posture "until a batching rung earns its own record"); groups deepening (emq.4); the
  parent/flow family (emq.3 — §11.10's other half); any wire break (additions ride protocol minors — the
  program's master invariant); any edit to the frozen v1 line.

## Deliverables

emq.1 builds (each now realized; the as-built surface is named):

- **EMQ.1-D1** — **the design gate (FIRST):** the A-1-compatible scheduler design — how every
  schedule/repeat key is declared in `KEYS[]` or grammar-derived (the §11.10 problem), with ≥2 steelmanned
  alternatives (incl. the do-nothing baseline) and the ADR; honors the 2.1 constraint verbatim (a delay is
  a visibility fence, not a new queue; mint-ordered ids stay the sort key); adopted as the six settled
  forks ([`./emq.1.design.md`](emq.1.design.md) §8 → adopted-as-built; run ledger D-1..D-7) before any
  build story ran.
- **EMQ.1-D2** — scheduled enqueue: `enqueue_at/5` (caller's absolute run-at ms) and `enqueue_in/5`
  (delay computed wire-side from `TIME`) mint branded `JOB` ids at enqueue, parked on the schedule set
  until due; ONE inline `@schedule` script serves both via an `ARGV` mode flag (`'at'`/`'in'`); the
  existing `promote` path releases them, adding no new release machinery.
- **EMQ.1-D3** — repeatable jobs: `EchoMQ.Repeat` — `register`/`cancel`/`due`/`advance`/`count` over
  `emq:{q}:repeat` (the registry zset) + `emq:{q}:repeat:<name>` (the per-registration record hash),
  whose every occurrence is a FRESH branded mint (the order theorem holds per occurrence); both keys
  declared.
- **EMQ.1-D4** — the retry vocabulary: `EchoMQ.Backoff.delay_ms/2` — a host-side pure module computing
  `delay_ms` (policies `{:fixed, ms}` / `{:exponential, base, cap}` / `{:jitter, inner}`) for
  `Jobs.retry/7` (backoff stays ABOVE the wire — the design §4 row-30 HOLD); max-attempts honored
  end-to-end; the poison-job drill (a persistently raising handler dead-letters with `last_error` after
  exactly max attempts, browsable in the morgue).
- **EMQ.1-D5** — the promote pump: `EchoMQ.Pump` — a supervised, opt-in cadence process with a pure
  decision core (`EchoMQ.Pump.Core`), sweeping due schedule entries through `Jobs.promote/3` AND firing
  due repeatables each tick; `:transient` restart semantics stated in `child_spec/1`.
- **EMQ.1-D6** — connector auto-resubscribe: the Connector records its subscription set and re-issues it
  after `:reconnect`; the companion `unsubscribe/2` keeps the set truthful; additive on the `EchoWire`
  facade (one `defdelegate`).
- **EMQ.1-D7** — proof: four conformance scenarios (`schedule`, `repeat`, `backoff`, `resubscribe`) +
  probes registered for the additions (the additive-minor law — design §5; the registry grows 14 → 18,
  the prior 14 byte-unchanged); pure + `:valkey` suites; the drill recorded.

## Invariants

- **EMQ.1-INV1** — the wire law: zero wire breaks; every addition is an additive protocol minor
  registered with its conformance probe in the same change. As built: the registry grew from 14 to 18
  scenarios (`schedule`/`repeat`/`backoff`/`resubscribe` added), and the prior 14 pass byte-unchanged in
  contract (`EchoMQ.Conformance.run/2` → `{:ok, 18}`).
- **EMQ.1-INV2** — declared keys: every new Lua key is declared in `KEYS[]` or derived from a declared
  root by the registered grammar (design §1 S-6); no exemption mechanism at any grain.
- **EMQ.1-INV3** — identity: every scheduled or repeated occurrence is a fresh branded `JOB` mint;
  mint-ordered ids stay the sort key; a delay is a visibility fence, never a new queue (the 2.1
  constraint, verbatim).
- **EMQ.1-INV4** — backoff above the wire: policy computes host-side; the wire takes literal delays
  (design §4 row 30).
- **EMQ.1-INV5** — process shape: the pump is a supervised, OPT-IN child with stated restart semantics
  and a pure decision core (the program's thin-but-robust law); a worker started without it is the v2
  core worker, unchanged.
- **EMQ.1-INV6** — the fences carried from emq.0: `apps/echomq` untouched; per-app testing only;
  agents run no git; the lock delta law holds.
- **EMQ.1-INV7** — the gate order (honored): no build artifact predated EMQ.1-D1's design; the design
  was adopted as the six settled forks, then the build stories ran (run ledger D-1..D-7 → Y-1 → Y-4).
  This body is now the post-build reconcile — the surfaces it names are real, at their as-built
  `file:line`; the body stays authoritative as the contract.

## Definition of Done

- [x] EMQ.1-D1 design + ADR adopted (the six settled forks; [`./emq.1.design.md`](emq.1.design.md) §8,
      adopted-as-built; run ledger D-1..D-7) before any build story ran.
- [x] D2–D6 built with every new Lua key declared in `KEYS[]` (INV2) and every addition registered with
      its probe (INV1).
- [x] The poison-job drill recorded: dead-letter at exactly max attempts with `last_error` browsable (the
      `backoff` conformance scenario + `jobs_test.exs`).
- [x] Pure + `:valkey` suites green per-app (echo_data 65 + 3 properties, echo_wire 18, echo_mq 94 + 4
      doctests, 0 failures); the prior 14 conformance scenarios byte-unchanged and green; the four new
      scenarios green (`EchoMQ.Conformance.run/2` → `{:ok, 18}`).
- [x] The reconnect drill: a subscribed connector loses its socket, reconnects, and its subscriptions
      answer again without a caller restart (`resubscribe_test.exs` + the `resubscribe` scenario).
- [x] The emq.0 gate ladder still green end-to-end (no regression — the `echo/rungs/` bus 3_1..3_5 +
      cache 4_1..4_4 + shadow ran at their tails; the Director re-ran them at the Stage-3 gate); the
      spec body remains authoritative and this reconcile syncs it post-build.

Stories: [`./emq.1.stories.md`](../../epics/emq.epic.1/emq.1.stories.md) · Agent brief: [`./emq.1.llms.md`](emq.1.llms.md) ·
Roadmap: [`../emq.roadmap.md`](../../emq.roadmap.md) · Design: [`../emq.design.md`](../../emq.design.md) §5,
§11.10, §4 row 30 · Consumer: `docs/exchange/exchange.specs.md` §Jobs, `docs/exchange/exchange.roadmap.md`
§Dependencies · The 2.1 row: `docs/echo/code/ROADMAP.md` ·
Approach: [`../../elixir/specs/specs.approach.md`](../../../elixir/specs/specs.approach.md)
