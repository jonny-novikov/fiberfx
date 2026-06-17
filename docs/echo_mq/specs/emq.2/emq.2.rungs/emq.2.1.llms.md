# EMQ.2.1 · the agent brief (LLM build brief)

> The build-grade brief emq.2.1 was built from and the Operator/verifier accepts against. Derived from
> [`./emq.2.1.md`](emq.2.1.md) (the spec body — **authoritative**; this brief and the stories may lag
> it, and when they disagree the body wins) and the carve [`./emq.2.design.md`](../emq.2.design.md).
> **Status: BUILT** — the read plane shipped as `EchoMQ.Metrics`; this brief is reconciled to the as-built
> surface (the design-make rulings resolved, the two realization-over-literal deviations recorded). Framing:
> no gendered pronouns for agents; no perceptual or interior-state verbs for agents or software (components
> read, compute, refuse, return); no first-person narration. Enforce these same rules in any downstream
> prompt.
>
> **As-built resolution (the open rulings the brief left to D1, now settled):** placement = a new
> `EchoMQ.Metrics` (not folded onto `Jobs`/`Lanes`); the metrics-counter write **landed here** (the minimal
> `HINCRBY` in `@complete`/`@retry`, not flagged to emq.2.2); the rate class = `EMQRATE`; the gate ships as a
> pure-read primitive (claim-side wiring → emq.2.2); the `:data` rolling series deferred (count-only read,
> series honest-0 → emq.8). The as-built verbs (all `conn`-first): `get_counts/3` · `get_job/3` ·
> `get_job_state/3` · `get_metrics/3` · `get_deduplication_job_id/3` · `get_rate_limit_ttl/3` ·
> `get_global_rate_limit/2` · `is_maxed/2` · `lane_depth/3` · `lane_depths/3`. Conformance: **24** scenarios
> (18 prior byte-unchanged + 6 new).

## References (read first, in order)

1. **The carve + the ADRs** — [`./emq.2.design.md`](../emq.2.design.md): ADR-0 (no migration — built
   fresh), ADR-1 (the carve: emq.2.1 = the read plane, first because the later rungs read through it),
   ADR-2 (the parity/family boundary — emq.2.1 ships the read floor, NOT the deepened families).
2. **The spec body** — [`./emq.2.1.md`](emq.2.1.md): Goal · 5W · Scope · D1–D8 · INV1–INV7 · DoD.
3. **The as-built floor (the structures emq.2.1 reads)** — RE-PROBE each at build time (the lag-1 law;
   earlier emq.* builds move the surface):
   - `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — the three-field row (`HSET … 'state','attempts','payload'`,
     `jobs.ex:20`), the four sets `pending`/`active`/`schedule`/`dead`. Completion-deletes: `complete/4`
     retires the row everywhere — **there is no `completed` set**.
   - `echo/apps/echo_mq/lib/echo_mq/keyspace.ex` — `queue_key/2` (`emq:{q}:<type>`), `job_key/2` (gated by
     `BrandedId.valid?/1`, `keyspace.ex:18-24`), `reserve/1`, the §6 grammar.
   - `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — `depth/2` (`lanes.ex:182`), the per-group structures the
     per-lane introspection builds on.
   - `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — the 18 prior scenarios (`scenarios/0`); the 6 new read
     scenarios (`counts`/`state`/`metrics`/`dedup`/`rate`/`lane_depth`) registered beside them, the 18 prior
     byte-unchanged → **24** total (`run/2 → {:ok, 24}`).
   - `echo/apps/echo_wire/lib/echo_wire.ex` — the facade (`eval`/`command`/`pipeline`); the read scripts
     run through `Connector.eval` / `Pool.eval`.
4. **The capability reference (the v1 read API to port — NEVER migrated from, NEVER literally copied)** —
   `echo/apps/echomq/lib/echomq/queue.ex` (the read verbs: `get_counts`/`get_job`/`get_job_state`/
   `get_jobs`/`get_metrics`/`get_rate_limit_ttl`/`get_global_rate_limit`/`get_deduplication_job_id`) +
   `echo/apps/echomq/priv/scripts/{getCounts-1,getState-8,getMetrics-2,getRateLimitTtl-2,isMaxed-2}.lua`.
   **These read v1-shaped state types** (`wait`/`prioritized`/`waiting-children`/`completed`-set) — emq.2.1
   re-derives the *capability* against `echo_mq`'s real four sets, it does NOT port the v1 state list.
5. **The canon** — [`../emq.design.md`](../../../emq.design.md): §6 (the grammar + the `metrics:`/`de:` suffixes),
   §5 (the closed wire-class registry — the rate gate's `EMQ*` class is an additive minor with a probe),
   §2 (the branded id gated at the key builder), S-4 (Valkey the gate), §11.11 (the no-release ground).
6. **The shape precedent** — [`./emq.1.md`](../../emq.1.md) + [`./emq.1.llms.md`](../../emq.1.llms.md) +
   [`./emq.1.prompt.md`](../../emq.1/emq.1.prompt.md) (the triad + brief + runbook shape; the inline-`Script.new/2`
   convention; the design-make-as-relocated-gate).

## Requirements (each traced back to a story, forward to an invariant/check)

| # | Requirement | From | To |
| --- | --- | --- | --- |
| R1 | A counts-by-state read over the as-built four sets + registered metrics counter; an unregistered state name errors; "completed" answers from the metrics counter, not a set | US1 | INV2, INV3, INV4 · the counts scenario |
| R2 | `get_job/3` reads the three-field row (id gated by `BrandedId.valid?/1`); `get_job_state/3` answers by which set holds the id; a missing job answers a typed absent shape | US2 | INV2, INV5, INV3 · the state scenario |
| R3 | `get_metrics/3` reads the `metrics:completed`/`metrics:failed` `count`; the minimal counter write landed here (`HINCRBY` in `@complete`/`@retry`); no metric read that is not written (the `:data` series unwritten → honest-0, deferred to emq.8) | US3 | INV2, INV1, INV4 · the metrics scenario |
| R4 | `get_deduplication_job_id/3` reads `emq:{q}:de:<dedupId>`; a read only | US4 | INV2, INV4 |
| R5 | `get_rate_limit_ttl/3` + `get_global_rate_limit/2` read the limiter/meta; the at-ceiling gate `is_maxed/2` refuses with `EMQRATE` mapped to `{:error, :rate}` (a pure-read primitive — claim-side wiring → emq.2.2); the five-code union stands | US5 | INV6, INV2 · the rate scenario |
| R6 | Per-lane introspection (counts/depth per group) over `Lanes.depth/2`; a pure read, no rotation/recovery change | US6 | INV2, INV3 |
| R7 | The read-plane design recorded first: module placement (≥2 steelmanned alternatives) + the counts contract (the as-built state set, NOT the v1 list); every read key against §6 | US7 | INV7, INV4 · the ledger |
| R8 | Every read declares its keys or grammar-derives them; the conformance registry grows additively; the 18 prior scenarios byte-unchanged; honest-row reporting | US8 | INV1, INV3, INV4 · the conformance run |

## Execution topology

**Runtime shape.** A read module above the wire — either a new `EchoMQ.Metrics` (the recommended
placement: a cohesive read surface) or read verbs folded onto `EchoMQ.Jobs`/`EchoMQ.Lanes` (the
alternative: reads live with the structure they read). The reads run inline-`Script.new/2` scripts through
`Connector.eval`/`Pool.eval` (the as-built transport); each script declares its structure keys in `KEYS[]`.
**No new process** (reads are synchronous verbs); **no state transition** (the state machine is emq.1's).

**Build-order task DAG.**
1. **D1 design-make (gate)** — adopt the carve (ADR-1); rule the module placement + the counts contract
   (the as-built state set); spell every read key against §6; rule the metrics-counter write (does a
   completion/dead transition already maintain a counter? if not, the minimal additive write lands here or
   flags to emq.2.2 — INV2's no-phantom-counter). Log each as a `tool_x_decision`.
2. **D2 counts** → the counts read + script (depends on D1's contract).
3. **D3 job & state lookup** → `get_job`/`get_job_state` (depends on the row + the four sets; independent
   of D2).
4. **D4 metrics** → `get_metrics` + (if ruled in D1) the minimal counter write (depends on D1's ruling).
5. **D5 dedup read** → `get_deduplication_job_id` (independent).
6. **D6 rate plane** → `get_rate_limit_ttl`/`get_global_rate_limit` + the `EMQ*`-classed gate (depends on
   D1's class word; registers the §5 class + its probe).
7. **D7 per-lane introspection** → counts/depth per group (depends on `Lanes.depth/2`).
8. **D8 proof** → the conformance scenarios + probes for each verb; pure + `:valkey` suites; the 18 prior
   byte-unchanged.

**Exact files touched** (as-built — the touch-set is exactly six `echo_mq` files):
- `echo/apps/echo_mq/lib/echo_mq/metrics.ex` — **NEW**: `EchoMQ.Metrics`, the 10 read verbs (`get_job`/
  `get_job_state` placed here as pure reads, NOT on `Jobs` — `Jobs` stays transition-only) + the inline read
  scripts (`@counts`/`@state_lookup`/`@rate_ttl`/`@is_maxed`/`@lane_counts`).
- `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — the two metrics-counter `HINCRBY`s only (`@complete` →
  `metrics:completed`, `@retry` dead arm → `metrics:failed`); no other change to the state machine.
- `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — the 6 new read scenarios registered in `scenarios/0`.
- `echo/apps/echo_mq/test/metrics_test.exs` — **NEW**: the per-verb `:valkey` suite (20 tests).
- `echo/apps/echo_mq/test/conformance_scenarios_test.exs` + `conformance_run_test.exs` — re-pinned 18→24.
- **`echo/apps/echo_wire` untouched** (no facade delegate needed — the reads run through the existing
  `Connector.eval`/`command`). **`apps/echomq` untouched** (the capability reference). No third app touched.
  `echo/mix.lock` unchanged (emq.2.1 adds no dependency).

## Agent stories (Directive + Acceptance gate — contracts, not tasks)

- **AS-1 — the design-make (the relocated gate).** *Directive:* adopt the carve (ADR-1); rule the module
  placement + the counts contract (the as-built four-set names, NOT the v1 list) + the metrics-counter
  write, each a `tool_x_decision` citing the design §; spell every read key against §6. *Acceptance gate:*
  the placement is recorded with ≥2 steelmanned alternatives; the counts contract names
  `pending`/`active`/`schedule`/`dead` (+ the metrics counter for "completed"), never a v1 state; no
  `.ex`/Lua artifact predates the ledger entry (INV7).
- **AS-2 — counts.** *Directive:* build the counts read over the as-built sets via one inline script
  declaring exactly the sets it counts; an unregistered state name errors. *Acceptance gate:* a queue with
  N pending / M active / K scheduled / J dead answers exactly those cardinalities; "completed" reads the
  metrics counter; the read mutates nothing (INV2, INV3, INV4); a counts scenario passes.
- **AS-3 — job & state lookup.** *Directive:* `get_job/3` reads the three-field row (id gated by
  `BrandedId.valid?/1`); `get_job_state/3` answers by which set holds the id; a missing job answers a typed
  absent shape. *Acceptance gate:* a claimed job reads `active`; a scheduled job reads `scheduled`; an
  ill-formed id raises at the key builder; a state scenario passes (INV2, INV5, INV3).
- **AS-4 — metrics.** *Directive:* `get_metrics/3` reads `metrics:completed`/`metrics:failed`; build the
  minimal counter write ONLY if D1 ruled it here; read no metric that is not written. *Acceptance gate:* a
  completed job increments the completed metric and `get_metrics` reads it; no phantom counter is read;
  a metrics scenario passes (INV2, INV1).
- **AS-5 — dedup read.** *Directive:* `get_deduplication_job_id/3` reads `emq:{q}:de:<dedupId>`. *Acceptance
  gate:* a parked dedup id reads back its branded id; an absent one answers typed-absent; no mutation (INV2).
- **AS-6 — the rate plane.** *Directive:* read the limiter TTL + the configured limit; the at-ceiling gate
  refuses with an `EMQ*` class via `redis.error_reply`, mapped client-side to `{:error, :rate}`; register
  the §5 class + its probe; leave the five-code fence union unextended. *Acceptance gate:* a rate-limited
  queue answers a positive TTL; an over-ceiling claim refuses with the class; an unrecognized `EMQ*` passes
  through untyped; a rate scenario passes (INV6, INV2).
- **AS-7 — per-lane introspection.** *Directive:* counts/depth per group over `Lanes.depth/2`; a pure read.
  *Acceptance gate:* two lanes answer their separate backlogs; no rotation/recovery state changes (INV2,
  INV3).
- **AS-8 — proof.** *Directive:* register a conformance scenario + probe for every read verb; run pure +
  `:valkey` suites; keep the 18 prior scenarios byte-unchanged; report honest-row. *Acceptance gate:*
  `EchoMQ.Conformance.run/2` answers `{:ok, n}` with the grown n, the 18 prior verdicts identical; Valkey
  on 6390 the truth row (INV1, INV3).

## The comprehensive prompt (leaves no decision the spec has not fixed)

Build emq.2.1 — the bus's **read plane** — inside `echo/apps/echo_mq`, to [`./emq.2.1.md`](emq.2.1.md)
(authoritative) and the carve [`./emq.2.design.md`](../emq.2.design.md), under the v2 master invariant
(braced `emq:{q}:` · branded `JOB` ids gated at the key builder · every Lua key declared-or-rooted ·
server clock where a lease is touched — emq.2.1 touches none · honest-row conformance · additive-minor
protocol). FIRST run the design-make (AS-1): rule the module placement (recommended: a new `EchoMQ.Metrics`)
and the counts contract — the read answers `echo_mq`'s **as-built** state set
(`pending`/`active`/`schedule`/`dead`), NOT the v1 `getCounts` list (`wait`/`prioritized`/…), because the
bus has those four sets and completion-deletes leave **no `completed` set** (so "completed" reads the
metrics counter). The v1 `echomq` read API + scripts are the **capability reference** — what to port —
never a literal copy and never a thing migrated from. Build the verbs as **pure reads** (the rate gate is a
read-and-refuse): counts (D2), job + state lookup gated by `BrandedId.valid?/1` (D3), the metrics read with
no phantom counter (D4), the dedup read (D5), the rate-limit read + the `EMQ*`-classed gate registering the
§5 class + its probe (D6), per-lane introspection over `Lanes.depth/2` (D7). New scripts follow the inline
`Script.new/2` convention (there is **no `priv/`** in `echo_mq`). Register a conformance scenario + probe
for every read in the same change (the additive-minor law); the **18 prior scenarios pass byte-unchanged**.
Compile clean (`--warnings-as-errors`, per-app); pure + `:valkey` suites green (`TMPDIR=/tmp`, Valkey 6390
PONG first); honest-row reporting. Keep the diff inside `echo_mq` (+ a facade delegate only if needed);
`apps/echomq` is untouched. Cite the spec/design line for every public call; invent no read surface,
no state name, no metrics key the design §6 grammar does not register; report any realization-over-literal
deviation. Author DOCS-free code (the spec is the doc); run no git.

---
The contract: [`./emq.2.1.md`](emq.2.1.md). The stories: [`./emq.2.1.stories.md`](emq.2.1.stories.md).
The runbook: [`./emq.2.1.prompt.md`](emq.2.1.prompt.md). The carve: [`./emq.2.design.md`](../emq.2.design.md).
The canon: [`../emq.design.md`](../../../emq.design.md). The capability reference:
`echo/apps/echomq/lib/echomq/queue.ex` + the read scripts. The as-built floor:
`echo/apps/echo_mq/lib/echo_mq/{jobs,lanes,keyspace,conformance}.ex`.
