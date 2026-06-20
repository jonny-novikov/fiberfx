# EMQ.5.1 · the build orchestration runbook — the batch-claim spine (`@bclaim` + `claim_batch/4`)

> The authoritative run scope for shipping emq.5.1 via `/echo-mq-ship` (Flat-L2, Director-supervised). The body
> ([`emq.5.1.md`](emq.5.1.md)) is the contract; the acceptance is [`emq.5.1.stories.md`](emq.5.1.stories.md); the
> Mars brief is [`emq.5.1.llms.md`](emq.5.1.llms.md). This runbook binds them to the pipeline stages + the gate
> ladder + the risk tier. **No decision the body has fixed is left open here — EXCEPT the three forks (5.1-A the
> count mechanism, 5.1-B the conformance decomposition, 5.1-C the empty/under-fill semantics), which the Operator
> rules at the pre-build reconcile (the Director routes via AskUserQuestion). None of the three changes the risk
> tier** (all of 5.1-A's arms are the NEW `@bclaim` body — additive; 5.1-B is conformance bookkeeping; 5.1-C's
> lean is non-blocking — only a ruled BLOCK would tighten the posture, and the lean + the spine contract is the
> short batch).
>
> **Framing law (propagated).** Third person for any agent; no gendered pronouns for agents; no perceptual or
> interior-state verbs for agents or software; no first-person narration. Bind this same clause in any sub-brief.

## The family in one paragraph

emq.5 builds the **batch CONSUME** family across four dependency-ordered sub-rungs ([`../emq.5.md`](../emq.5.md),
the Operator-blessed carve): **emq.5.1** the batch-claim spine (`@bclaim` + `claim_batch/4` — fetch up to N jobs
in one atomic claim) — THIS rung, the SPINE; **emq.5.2** `min_size`/`timeout` shaping (a batch-aware Consumer
that waits for ≥ `min_size` OR until `timeout`); **emq.5.3** group affinity + batch concurrency (`@gbclaim`, a
homogeneous lane-scoped batch — Apollo recommended); **emq.5.4** the partitioned finish (a batch resolves as a
partition + dynamic delay). The PRODUCE half already ships (`Jobs.enqueue_many/3`, `jobs.ex:124`) and is NOT
re-built. 5.1 must land FIRST — 5.2/5.3/5.4 each ride `@bclaim`. Each ships independently; nothing in the family
is a wire break.

## The rung in one paragraph

emq.5.1 builds the **batch-claim spine**: a single atomic claim that leases up to `size` jobs at once, amortizing
the per-job round-trip + the per-job lease bookkeeping across the batch. The mechanism is the design's reserved
§6.2 count-variant pop — a `ZPOPMIN emq:{q}:pending` loop INSIDE the claim script, never a client-side
`LMPOP`/`ZMPOP` (which bypasses the script layer's bookkeeping). The shape is **already proven** by the just-shipped
`@gwclaim` (emq.4.4, `lanes.ex:87-129`): it loops `ZPOPMIN lane` K times under one server-clock `TIME`, leasing
the whole batch on one deadline, per-member `HINCRBY attempts`. `@bclaim` is the **non-grouped generalization**
over the flat `emq:{q}:pending` set, returning a list of `{id, payload, attempts}` (no group field). The shipped
`@claim` (`jobs.ex:165`) is **byte-frozen** (the single-pop path coexists). All under the v2 master invariant
(braced keyspace · branded `JOB` ids gated · declared keys A-1 · server clock on the batch lease · inline
`Script.new/2` · additive-minor conformance).

## Mode

**Flat-L2, Director-supervised.** Venus (reconcile/author the triad — DONE; loads `echo-mq-architect`) → Mars-1
(build to the brief — `echo-mq-implementor`) → Director solo review (independent gate re-run on Valkey 6390 + an
adversarial probe + a net-zero mutation spot-check) → Mars-2 (remediate + harden) → Director ship (one LAW-4
pathspec commit). **Apollo (`echo-mq-evaluator`) is an OPTIONAL fast-finisher** (closure + stories) — this rung
edits NO shipped script (`@bclaim` is additive), so Apollo is NOT a ship precondition; the ≥100 determinism loop
is the Director's verify, run by the Director (and Mars), not an Apollo mandate.

## The forks are RULED — the Operator's pre-build decisions (SHIPPED, Director-verified PASS)

> **All three forks are settled; the rulings below are the as-built facts (they SUPERSEDE the pre-build "lean"
> framing). NONE changed the risk tier.** Venus surfaced each re-grounded against the re-probed `@gwclaim`
> (`lanes.ex:87-129`) + the shipped `@claim`/`claim/3` (`jobs.ex:165,418`); the Operator ruled:
>
> - **FORK 5.1-A — the count mechanism → RULED: the LOOP** (a `ZPOPMIN` loop ×N, over the native count-pop). As
>   built (`jobs.ex:200-219`): `ZCARD` clamp `k = min(size, depth)`, ONE `redis.call('TIME')`, then the `@claim`
>   per-member transitions in a loop (`ZPOPMIN` → `HINCRBY attempts` → `HSET state active` → `ZADD active` on the
>   one shared deadline). Both arms were INSIDE the script (INV1 held either way).
> - **FORK 5.1-B — the conformance decomposition → RULED: THREE scenarios, +3 → 64** (the Operator chose granular
>   over the two-scenario draft lean): `batch_claim` (full) · `batch_claim_short` (under-fill / oversized-clamp /
>   empty / paused) · `batch_partial_failure` (isolation). Both pinning tests pin **64**
>   (`conformance_run_test.exs:50`, `conformance_scenarios_test.exs` `@run_order`).
> - **FORK 5.1-C — the empty/under-fill semantics → RULED: return the short batch M** (non-blocking, over
>   BLOCK/wait-for-N). As built (`claim_batch/4`, `jobs.ex:520-539`): M<N → M; oversized (N>depth) → depth;
>   M=0/paused → `:empty` (the `paused?/2` gate FIRST, pending untouched). The blocking `min_size`/`timeout`
>   cadence is emq.5.2's job, NOT the spine's.
>
> **The label:** the rung stepped to **`2.5.0`** (`mix.exs:7`, opening the batches family); the wire
> `@wire_version` stays FROZEN at `echomq:2.4.2` (the two-planes model). The risk tier held: **NORMAL + the ≥100
> determinism loop** (the loop owned the proof, 100/0 — a mint/lease surface).

## The as-built floor (re-probed at Venus's reconcile, this run — Mars RE-PROBES each at Stage-0; the lag-1 law)

- **Toolchain:** Erlang 28.5.0.1 / Elixir 1.18.4 (`echo/.tool-versions`, re-probe `asdf current` from the app
  dir). Valkey on **6390** → PONG. `{emq}:version` = `echomq:2.4.2` == `@wire_version` (the boot fence passes).
- **`@gwclaim` (lanes.ex:87-129) — the count-variant multi-pop to PORT (SHIPPED, byte-frozen):** `ZCARD lane`
  depth clamp `k = min(weight, depth, headroom)` :91-104 (never over-pops) · ONE `redis.call('TIME')` :110-111 ·
  `for _ = 1, k do ZPOPMIN lane; HINCRBY <row> attempts 1; HSET <row> state active; ZADD active now+lease id end`
  :113-121 · the nested-array return :120,128. `@bclaim` is the NON-GROUPED isomorph (flat `pending`, no
  `g:`-segment/`gactive`/ring; `{id, payload, att}` without the group field).
- **`@claim` (jobs.ex:165-176) — the single-pop spine to GENERALIZE + BYTE-FREEZE:** `ZPOPMIN KEYS[1]` :166 ·
  `if #popped == 0 then return {} end` :167 · `jk = ARGV[1] .. id` :169 (the A-1 ARGV-base row-key root) ·
  `HINCRBY jk attempts 1` :170 · `HSET jk state active` :171 · `TIME` :172-173 → `ZADD KEYS[2] now+ARGV[2] id`
  :174 · `return {id, HGET jk payload, att}` :175. **BYTE-FROZEN by this rung** (`@bclaim` is additive).
- **`claim/3` (jobs.ex:418-431) — the arity + return + pause-first shape `claim_batch/4` generalizes:**
  `claim(conn, queue, lease_ms) when is_integer(lease_ms) and lease_ms > 0` :418 · `if paused?(conn, queue) ->
  :empty` :419 (pause honored FIRST) · keys `[queue_key(q,"pending"), queue_key(q,"active")]` :422 · argv
  `[queue_key(q,"job:"), Integer.to_string(lease_ms)]` :423 · `{:ok, []} -> :empty`, `{:ok, [id, payload, att]}
  -> {:ok, {id, payload, att}}` :426-427. `claim_batch/4` = arity 4 (the extra arg `size`), returns a LIST.
- **`paused?/2` (jobs.ex:439):** the queue-wide pause gate (`HGET emq:{q}:meta paused`) `claim_batch/4` calls
  FIRST.
- **`@complete` (jobs.ex:214) + `@retry` (jobs.ex:291):** BYTE-FROZEN; the per-member resolution the
  partial-failure isolation rides (no new resolution Lua).
- **The keyspace (keyspace.ex):** `queue_key/2` builds `emq:{q}:<type>`; `job_key/2` gates `BrandedId.valid?/1`.
  **No grammar edit** — `@bclaim` rides the shipped `pending`/`active` sets. No `@bclaim`/`claim_batch` exists yet
  (`grep claim_batch|bclaim` = 0, greenfield).
- **Conformance = 61 (LIVE):** `conformance_run_test.exs:48` `{:ok, 61}`; `conformance_scenarios_test.exs`
  `@run_order` = 61 names :28-90 (the module-doc prose says "fifty-five/sixty-one" in places — STALE prose, the
  61-name `@run_order` + the `{:ok, 61}` pin are authoritative; a Mars Stage-5 may sync the prose, not load-bearing
  for the gate).
- **The version model (two-planes, emq.4.3 D-4) — as built:** `mix.exs` version "2.5.0" = the rung LABEL read by nobody at
  runtime; `@wire_version` "echomq:2.4.2" = the wire constant, frozen by committed records. The rung label
  stepped to **2.5.0** (RULED — opening the batches family; the Operator's pre-build call, a label-only decision,
  no wire impact). Conformance went **61 → 64** (FORK 5.1-B RULED THREE).

## The pipeline — the stages

### Stage 0/1 — Venus (architect): the triad + the pre-build reconcile + the forks surfaced — DONE
The triad is authored ([`emq.5.1.md`](emq.5.1.md) body authoritative; [`emq.5.1.stories.md`](emq.5.1.stories.md)
+ [`emq.5.1.llms.md`](emq.5.1.llms.md) derived) with the reconcile deltas carried (the 61 count, the byte-freeze
universe = every shipped script, the re-probed `@gwclaim`/`@claim` anchors, the §6.2 reservation, the `pending`/
`active` home, the two-planes version) and the [WITHHELD] count-pop mechanism + scenario set + under-fill
semantics pinned at the three forks. **Director gate:** read the body + this runbook (the files, not the report);
route FORK 5.1-A/B/C to the Operator (AskUserQuestion); record the rulings; then release Mars.

### Stage 1 — Mars-1 (implementor): build to the ruled arms
Re-probe the floor (Stage-0, the lag-1 law — every anchor above). Build **R1** (the NEW `@bclaim` — the ruled
FORK 5.1-A mechanism: the loop, or native count-pop + the per-member loop), **R2** (`claim_batch/4` — the host
API, pause-first), **R3** (the under-fill semantics — the ruled FORK 5.1-C: the short batch), **R4** (the
partial-failure isolation proof over the byte-frozen `@complete`/`@retry`), **R5** (the byte-freeze + wire-law
grep battery), **R6** (the three conformance scenarios — FORK 5.1-B RULED THREE + the 61→64 re-pin in both pins),
and self-verify the per-app gate ladder + the **≥100 determinism loop** (a mint/lease surface). **Stories:** Mars
writes/extends the `:valkey` proof to US1 (the batch claim, a POSITIVE proof — `size` members served from a
flooded set, mint-ordered, one shared lease) + US3 (the partial-failure isolation, one member retried, the rest
completed). Cite the spec line for every public call; inline `Script.new/2` (NEVER `priv/`); declared keys A-1;
the server clock on the batch lease; the conformance additive-minor mechanics. Report the gate results before
going idle (an interim if the loop is mid-run).

### Stage 2 — Director: solo review (a REAL pass)
Independent gate re-run on Valkey 6390 (not Mars's word): `compile --warnings-as-errors`, `mix test --include
valkey`, `Conformance.run/2 → {:ok, 64}`. The adversarial probes:
1. **The batch-claim no-op-defeater** — claim `size` from a flooded pending set → assert EXACTLY `size` members
   served, mint-ordered, each at attempts 1, on ONE shared lease deadline; mutate the loop to a single pop → the
   batch must under-serve (US1 RED). A `size`-1 test proves nothing — confirm the proof uses `size >= 2`, K >
   size.
2. **The shared-lease probe** — assert every served member carries the SAME active-set deadline (one `TIME`
   read); a per-member `TIME` re-read is a regression the probe catches.
3. **The under-fill / pause probe** — claim N from M<N pending → exactly M served (FORK 5.1-C); claim from a
   paused queue → `:empty`, pending UNTOUCHED (the pause honored FIRST).
4. **The partial-failure isolation probe** — claim N, retry member k, complete the rest → k `scheduled`
   (last_error kept), the rest retired, a fresh post-promote claim finds only k at attempts 2; a stale-token
   resolution → `EMQSTALE`.
5. **The byte-freeze grep** — `grep redis.call` on every shipped script body in the lib diff = 0 (`@claim` + every
   `jobs.ex` script + every `@g*`); `@bclaim` is the ONLY new `redis.call`-bearing script.
6. **Declared-keys A-1** over `@bclaim` — `pending`/`active` are passed as **real braced `KEYS[]`** that PIN the
   `{q}` slot; the row `jk = ARGV[1] .. id` is **slot-sound because it shares the `{q}` hashtag `KEYS[1]`/`KEYS[2]`
   pin — NOT because the ARGV base is a declared root** (an ARGV-passed base is expressly NOT a declared root under
   the F-1 rule; the as-built comment `jobs.ex:192-196` states this exactly). A reviewer names the braced `KEYS[]`
   that pin every key's slot; a grep for a key outside `pending`/`active`/`job:<id>` is empty; the §6 grammar
   unedited; no client-side `LMPOP`/`ZMPOP`; no new key family.
7. **A net-zero mutation spot-check** — two distinct load-bearing tests proven to BITE (the batch-claim count +
   the partial-failure isolation), reverted net-zero.

The **≥100 determinism loop is a ship gate** (a mint/lease surface): the Director runs it FOREGROUND, owning the
machine (no concurrent liveness server, no sibling heavy I/O — a load-gated pre-existing test forges a failure the
rung did not cause), timeout-bounded chunks driven to an accumulated count.

### Stage 3 — Mars-2 (implementor): remediate + harden + the full gate ladder
Apply the Director's findings. Run the FULL per-app gate ladder + the **≥100 FOREGROUND determinism loop** (owning
the machine — a mint/lease surface). Byte-freeze + boundary + FROZEN-WIRE confirmations. Report (an interim before
idle — silence reads as a stall, emq.4.3 L-2).

### Stage 4 — Apollo (evaluator): OPTIONAL fast-finisher (NOT a gate — `@bclaim` is additive)
If run: the post-build reconcile (does the as-built code satisfy the spec's promises?); the §11.2-charter
adversarial verification (the order theorem / declared-keys / no-client-pop probes applied to the batch claim);
re-run the per-app gate ladder + the ≥100 determinism loop independently; re-verify the conformance count is
byte-unchanged with each new scenario probe-registered; sync the spec to what shipped; the mentoring loop. This
rung edits no shipped script, so Apollo is an optional fast-finisher (closure + stories), NOT a ship precondition.

### Stage 5 — Venus (architect): the post-build reconcile
Sync the triad to what shipped — the ruled count-pop mechanism, the scenario set + the final count N, the
under-fill semantics, the byte-freeze set actually frozen, the `@wire_version` disposition (frozen), the rung
label. Surgical sync, body authoritative. (The `emq.5.1.md` body is edited at THIS stage — the as-built reconcile
syncs the seed POST-build, never pre-build.)

### Stage 6 — Director: closure + ONE LAW-4 commit
One Director pathspec commit of the rung's measured surface (the code + the triad + the `emq-5-1` ledger).
Re-verify `git diff --cached --name-only` is purely the rung before committing (the Operator pre-stages
out-of-band — exclude `AM`-status files); split an entangled tree into separate scoped commits per concern. Mark
emq.5.1 SHIPPED in the roadmap/progress, note the batches family spine landed (5.2/5.3/5.4 now ride `@bclaim`). No
push unless asked.

## Risk tier — NORMAL + the ≥100 determinism loop

| Dimension | Grade |
|---|---|
| **Risk** | **NORMAL** — additive Lua (a NEW `@bclaim`), `@claim` + every shipped script byte-frozen, no destructive at-rest op, no frozen-line edit, no new process, no wire break. NOT HIGH (no shipped-script edit, no destructive op, no new process/lease *surface* beyond the additive claim). |
| **Apollo** | **Optional fast-finisher** (closure + stories) — NOT a ship precondition (no shipped-script edit). |
| **Determinism** | **The ≥100 determinism loop** — REQUIRED. `@bclaim` HINCRBYs attempts + leases on the server clock, and the proof mints branded JOB-ids to flood the pending set → a **mint/lease surface** (the same-millisecond branded-`JOB` mint hazard the loop owns). NOT a multi-seed sweep (unlike emq.4.4, which minted no id in the claim). FOREGROUND, owning the machine, timeout-bounded chunks to an accumulated count. |
| **Byte-freeze set** | EVERY shipped script — `@claim` + every `jobs.ex` script (`@enqueue`/`@schedule`/`@complete`/`@retry`/`@promote`/`@reap`/`@update_data`/`@update_progress`/`@add_log`/`@remove_job`/`@reprocess`/`@extend_lock`/`@extend_locks`) + every `@g*` in `lanes.ex`. `@bclaim` is the ONLY new script. |
| **Wire** | `@wire_version` UNCHANGED at `echomq:2.4.2` (additive — `@bclaim` is a NEW script, not a wire edit); `mix.exs` rung label → **2.5.0** (RULED, opening the batches family, label-only). |

The grade is stated forward so the build runs at the right rigor the instant the Operator rules the three forks.

## Acceptance — "shipped" means

- FORK 5.1-A/B/C ruled (the Operator's mechanism + scenario-set + under-fill calls recorded); the [WITHHELD]
  count-pop mechanism + scenario set + under-fill semantics pinned to the ruled arms; the triad re-derived to them
  (Stage-5).
- R1–R7 built and green: `@bclaim` (the count-variant `ZPOPMIN emq:{q}:pending` loop — inside the script, one
  `TIME`, one batch lease, per-member attempts, a list return); `claim_batch/4` (the manual-pull host API,
  pause-first, `{:ok, [members]}` | `:empty`); the under-fill short batch (the ruled FORK 5.1-C); partial-failure
  isolation (a tested property over the byte-frozen `@complete`/`@retry`); the conformance scenario(s) (additive
  minor — prior 61 byte-unchanged, re-pinned 61→64 in both pins); the byte-freeze grep = 0 over every shipped
  script.
- The proof: the `:valkey` batch suite green per-app; the **≥100 determinism loop** green (FOREGROUND, owning the
  machine — a mint/lease surface); honest-row (Valkey 6390). Apollo an optional fast-finisher.
- INV1–8 verified as runnable checks; the body remains authoritative; the as-built reconcile syncs the seed
  post-build (Stage-5); one LAW-4 pathspec commit (Stage-6); the batches family spine landed (5.2/5.3/5.4 ride
  `@bclaim`).

## The Stage-6 commit pathspec (Director-only — the emq.5.1 BUILD; adjust to the ruled touch-set)

```bash
# THE CODE (the additive touch-set):
#   echo/apps/echo_mq/lib/echo_mq/jobs.ex          (the NEW @bclaim script + claim_batch/4; @claim + every shipped script BYTE-FROZEN)
#   echo/apps/echo_mq/lib/echo_mq/conformance.ex   (the batch-claim scenario(s) + the count prose)
#   echo/apps/echo_mq/test/<batch_or_jobs>_test.exs  (the :valkey batch proof — NEW or EDIT; US1 + US3)
#   echo/apps/echo_mq/test/conformance_run_test.exs       (re-pin {:ok, 64})
#   echo/apps/echo_mq/test/conformance_scenarios_test.exs (re-pin @run_order → 64 names)
#   echo/apps/echo_mq/mix.exs                       (the rung label — 2.5.0, RULED)
# THE DOCS:
#   docs/echo_mq/specs/emq2/emq.5/emq.5.rungs/emq.5.1.{md,stories.md,llms.md,prompt.md}
#   docs/echo_mq/specs/emq2/emq.5/emq.5.md          (IFF a Stage-5 carve sync is needed — the spine SHIPPED note)
#   docs/echo_mq/specs/progress/emq-5-1.progress.md  (+ the registry)
# EXCLUDED: keyspace.ex (no grammar edit), lanes.ex (every @g* byte-frozen — @bclaim is in jobs.ex),
#   stalled.ex/admin.ex (byte-unchanged), echo_wire/* (untouched — @wire_version frozen), apps/echomq,
#   mix.lock (no real dep moved), the .claude/ calibration diffs (harness-fenced), any AM-status out-of-band file.
```
