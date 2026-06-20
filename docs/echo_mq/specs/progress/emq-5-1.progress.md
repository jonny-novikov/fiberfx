# emq-5-1 — the batch-claim spine · run ledger (Flat-L2, Director-supervised)

> The audit trail for the `/echo-mq-ship emq.5 foundation and emq.5.1` run. The aaw MCP (`tool_x_*` /
> `agent_register`) and msh MCP are disconnected this session, so the **T/D/V/Y/Z entries are kept here as
> markdown** in place of the structured ledger; the peers are real `Agent`-tool spawns (`venus` / `mars`),
> Director-supervised. The discipline is unchanged — the v2 laws, the gate ladder, the LAW-4 pathspec commit.

**Scope.** (a) the emq.5 family **foundation** — reconcile the carve (`emq.5.md`) + author the emq.5.1 triad; and
(b) **BUILD emq.5.1** — the batch-claim spine.
**Mode:** Flat-L2. **Engine:** Valkey 6390 (`PONG`). **Toolchain:** Elixir 1.18.4 / Erlang 28.5.0.1
(`echo/.tool-versions`). **Conformance floor:** 61 (`conformance_run_test.exs:48`).
**Risk:** **NORMAL + the ≥100 determinism loop** — a new mint/lease surface, but additive Lua with `@claim`
byte-frozen; no destructive at-rest op, no frozen-line edit, no new process (the carve's tier).

## T-1 — the §0 derivation (Director)

**5W.** A batch consumer fetches up to *N* pending jobs in **one atomic claim** instead of *N* round-trips,
amortizing the per-job wire + lease bookkeeping across the batch. The **produce half ships** (`enqueue_many/3`);
emq.5.1 builds the **consume spine**: `@bclaim` (count-variant `ZPOPMIN` **inside** the claim script) +
`Jobs.claim_batch/4` (the manual-pull host API) — the **non-grouped generalization of the shipped `@gwclaim`
multi-pop loop** (lanes.ex:87). Where: `echo/apps/echo_mq/lib/echo_mq/jobs.ex` (beside `@claim`/`claim/3`); no
echo_wire seam (rides `Connector.eval`); no new process. When: now — emq.4 CLOSED (conf 61), the spine 5.2/5.3/5.4
build on.

**Solution space (incl. do-nothing).**
- *Do-nothing:* host loops `claim/3` ×N — N round-trips, N separate leases, no atomic batch. Rejected: amortization
  + one batch deadline is the whole point.
- *Client-side `LMPOP`/`ZMPOP`:* **forbidden by design §6.2** (emq.design.md:457–463) — a client pop bypasses the
  script layer's atomic event/bookkeeping path. Rejected at the design layer.
- *Count-variant `ZPOPMIN` inside `@bclaim`:* the **reserved §6.2 surface** (emq.design.md:464). The mechanism. ✓
  - **FORK 5.1-A (to rule):** native `ZPOPMIN key count` (one call) **vs** a `ZPOPMIN key` loop ×N (the `@gwclaim`
    shape — per-member attempts increment + per-member lease entry in the loop). *Lean: the loop* (per-member
    fencing token + symmetry with `@gwclaim`).

**Invariants as runnable checks (the v2 master invariant on the NEW `@bclaim`).**
1. **Declared keys** — every `@bclaim` key is in `KEYS[]` or derived from a declared `KEYS[n]` root, never an ARGV
   base (the F-1 rule). *Probe:* grep the body; every `redis.call` key operand traces to `KEYS[n]`.
2. **Braced keyspace** — `emq:{q}:pending` / `emq:{q}:active` / `emq:{q}:job:<branded>` share the `{q}` slot.
3. **Server clock** — the batch lease deadline is `TIME` read **once inside** the script, applied to every member's
   active-set score. *Probe:* `@bclaim` body has `redis.call('TIME')`, no host timestamp in the lease.
4. **Branded JOB + the order theorem** — members are branded job ids; a batch of K popped by `ZPOPMIN` over the
   mint-scored pending zset is the **K oldest in mint order** (byte = mint).
5. **Attempts as the fencing token** — each member's attempts increment on claim (the `@claim` convention).
6. **Additive minor** — `@claim` **byte-UNCHANGED** (grep `redis.call` on the jobs.ex diff = only the new
   `@bclaim` adds lines); the new conformance scenario(s) registered with their probe in the same change; the count
   re-pinned 61→61+k in **both** pinning tests.
7. **Partial-failure isolation** — a batch resolves per-member via the shipped **byte-frozen** `@complete`/`@retry`
   (a *tested property*, not new Lua); one poison member's retry never touches its siblings' leases.

**Smallest change that preserves correctness.** ONE new inline `Script.new(:bclaim, …)` attr in jobs.ex (the
count-variant `ZPOPMIN` loop, one `TIME`, one batch deadline, per-member attempts) + ONE new `claim_batch/4` host
fn (eval `@bclaim`, decode the K-member list — this *is* the manual pull) + the conformance scenario(s) + tests +
the ≥100 loop. No new key TYPE (reuses pending/active/job), no new process, no echo_wire touch, `@claim` frozen.

## D — the forks ruled (Operator-confirmed via `AskUserQuestion`)

- **D-1 (FORK 5.1-A — count mechanism):** `@bclaim` = **`ZPOPMIN` loop ×N** (the shipped `@gwclaim` shape) —
  pop one-at-a-time K times under ONE server `TIME`, each member its own `HINCRBY attempts` + `HSET state` +
  `ZADD active <deadline>`; the per-member fencing token preserved. NOT the native `ZPOPMIN key count`.
- **D-2 (FORK 5.1-C — under-fill):** **return the short batch M** — request `size` N, M<N pending → return the M
  available; **M=0 (or paused) → `:empty`**; oversized request (N > depth) returns depth. Non-blocking spine; the
  `min_size`/`timeout` blocking cadence stays emq.5.2's. Matches `claim/3` + the `@gwclaim` `k=min` clamp.
- **D-3 (FORK 5.1-B — conformance scope):** **+3 → 64** (Operator chose granular, over the recommended +2→63).
  Three new honest rows: `batch_claim` (full claim, one batch lease, attempts incremented) · `batch_claim_short`
  (under-fill / oversized-request → short batch; empty → `:empty`) · `batch_partial_failure` (per-member isolation
  over byte-frozen `@complete`/`@retry`). Prior 61 byte-unchanged; re-pin **61→64** in BOTH pinning tests
  (`conformance_scenarios_test.exs` @run_order + `conformance_run_test.exs:48`) + sync the stale prose.
- **D-4 (the rung label):** `mix.exs` version → **2.5.0** (opens the emq.5 batches family). The wire
  `@wire_version` stays **frozen at `echomq:2.4.2`** — NOT touched (label plane only; the bench-roadmap
  defer-the-fence lesson).

## L — findings (carried to the Stage-5 reconcile / Apollo)

- **L-1 (declared-keys framing — precision, not a blocker).** The triad's INV3 (`emq.5.1.md:162-163`) + the
  Stage-2 probe-6 note (`emq.5.1.prompt.md:148`) call the `@claim` row-key's ARGV base "a declared root by the A-1
  rule." The program-law / F-1 rule (`.claude/skills/echo-mq-program.md` + the echo-mq-ship A-1 clause) is explicit
  that **an ARGV base is NOT a declared root** — what makes `@claim` (and so `@bclaim`) slot-sound is that it
  **declares real braced `KEYS[]` entries (`pending`, `active`) that PIN the `{q}` slot**, and the ARGV-derived row
  key `ARGV[1]..id` shares that pinned slot. The as-built `@claim` is SOUND (it declares `KEYS[1]/KEYS[2]`); only
  the PROSE is loose. Carried (a) into Mars's brief as a precision correction (`@bclaim` = `KEYS=[pending,active]`
  pinning the slot, the `@claim` structure looped) and (b) to the Stage-5 reconcile (tighten INV3's wording).
  **F-1 is gate-invisible on single-node Valkey** — the ONLY defense is the Director's manual declared-keys review
  at Stage 2 (probe #6).

## V-1 — the Director's Stage-3 verify (a REAL independent pass, not a glance)

**STATIC (read the as-built, not Mars's paste):**
- **Byte-freeze ✓** — `jobs.ex` diff = **94 insertions / 0 deletions** (`@claim` :165-176 byte-unchanged); `git diff`
  removed `redis.call` lines in jobs.ex = **0**; `lanes.ex` (every `@g*`) + `keyspace.ex` (§6 grammar) **untouched**.
  `@bclaim` is the ONLY new `redis.call`-bearing script.
- **Additive-minor ✓** — the only removed scenario-key line is `starvation_drill` (verdict string **byte-identical**,
  trailing-comma-only reflow, lines 36→37); +3 new scenario-keys (`batch_claim`/`batch_claim_short`/`batch_partial_failure`);
  re-pinned **61→64** in BOTH pins (`conformance_run_test.exs:50` `{:ok, 64}` + `conformance_scenarios_test.exs`
  `@run_order`). Prior 61 byte-unchanged.
- **`@bclaim` F-1 ✓** — `KEYS[1]=pending` / `KEYS[2]=active` are real braced keys that PIN the `{q}` slot; the row
  `jk = ARGV[1]..id` (`ARGV[1]=emq:{q}:job:`) rides that slot. **The as-built code comment (jobs.ex:192-196) states
  the F-1 precision CORRECTLY** (the L-1 correction landed in the code, not just the brief). No `LMPOP`/`ZMPOP` in
  the body.
- **Server clock ✓** — `@bclaim`'s `TIME`→ms arithmetic (`now = t[1]*1000 + math.floor(t[2]/1000)`, lease `now +
  ARGV[2]`) is **BYTE-IDENTICAL** to `@claim`'s (jobs.ex:173 vs :206) — one `TIME` read, one batch deadline; no
  unit drift between batch and single-claim leases.
- **`claim_batch/4` ✓** — guards (`size>0 and lease_ms>0`), `paused?/2` FIRST → `:empty` (pending untouched), keys
  `[pending, active]`, argv `[job:, lease_ms, size]`, decode `{:ok,[]}→:empty` / `{:ok,members}→{:ok,[tuples]}`.
- **Test rigor ✓** — `batch_claim_test.exs` no-op-defeaters are REAL: US1 `size=4`/`k=10` asserts exact count +
  mint-order equality + the **shared-lease `uniq==1`** (INV4) + pending/active `ZCARD`; US2 under-fill/empty/paused;
  US3 a real poison `retry`+`complete` partition with post-promote re-claim + `EMQSTALE`; US4 structural body grep.

**DYNAMIC (independent gate re-run on Valkey 6390):**
- `compile --warnings-as-errors` → **exit 0**, zero `echo_mq`-file warnings (the 2 log warnings are `echo_data`'s,
  a dep outside the boundary — pre-existing).
- Full per-app suite `--include valkey` → **7 doctests, 422 tests, 0 failures** (independently re-run).
- **Director's net-zero mutation spot-check (LAW-1a):** `ZPOPMIN→ZPOPMAX` in `@bclaim` (the order theorem, INV5 —
  a mutation Mars did NOT run) → **caught 6 ways** (US1/US2/US3 mint-order equalities + the US4 structural grep);
  reverted by **inverse Edit** (never `git checkout`) → 8/0 green, **0 `ZPOPMAX` residue, jobs.ex back to 94 ins/0
  del** (net-zero confirmed).
- **The ≥100 determinism loop** (the ship gate, a mint/lease surface) → **PASS 100/100, FAIL 0** (background
  `b7dcfv71y`, exit 0; 100× `batch_claim_test`+`conformance_run`+story, `SCRIPT FLUSH` each iter for the cold-cache
  EVALSHA path). Mars independently reported 100/0 on its own broader suite mix — **two independent ≥100 loops**
  over the mint/lease surface, different load shapes, both green.

**VERDICT:** BUILD **ship-grade**. **Zero code remediation items.** One finding (L-1 — INV3 prose) routes to the
Stage-5 spec reconcile (the code comment is already correct). **Mars-2 COLLAPSES** to a no-op (conditional on the
≥100 loop landing green — the Director already ran the full gate + mutation that Mars-2 would re-run; right-size:
rigor constant, ceremony dropped).

## Stage tracker
- [x] **0 Bootstrap** — context read; engine/toolchain probed; as-built claim surface grounded (`@claim`
  jobs.ex:165, `@gwclaim` lanes.ex:87; no `@bclaim`/`claim_batch` yet); conf floor 61 pinned.
- [x] **1 Venus** — BUILD-GRADE. Authored the emq.5.1 triad (`emq.5.1.{md,stories.md,llms.md,prompt.md}` under
  `specs/emq2/emq.5/emq.5.rungs/`) + one reconcile edit to `emq.5.md:33` (pinned `claim/3` return + jobs.ex
  anchors). Pinned anchors: `claim/3` @ jobs.ex:418 → `{:ok,{id,payload,att}}` | `:empty`; `@claim` :165;
  `@gwclaim` :87 (clamp :91-104, one TIME :110-111, loop :113-121); `@complete` :214 / `@retry` :291 byte-frozen;
  `enqueue_many` :124; conf **61** confirmed. Risk declared NORMAL + ≥100 loop. Contradiction: none blocking
  (one cosmetic `conformance.ex` prose drift flagged for a Mars prose-sync). Surfaced 3 forks + 1 label choice.
- [x] **D — forks ruled** — D-1 loop · D-2 return-M · D-3 +3→64 · D-4 label 2.5.0 (see the D section above).
- [x] **2 Mars-1** — BUILD ship-grade. `@bclaim` (loop ×N) + `claim_batch/4` + 3 scenarios (→64) + `batch_claim_test`
  (8 tests) + story test; gates green (422/0, conf 64, 100/0 loop). Boundary held (echo_mq only).
- [x] **3 Director verify** — static ✓ + dynamic ✓ (compile exit0 · 422/0 · mutation `ZPOPMIN→ZPOPMAX` caught 6×,
  net-zero · the ≥100 loop **100/100 FAIL 0**, `b7dcfv71y` exit 0). Verdict: **ship-grade, zero remediation items**.
- [x] **4 Mars-2** — COLLAPSED (zero code remediation; the Director already ran the full gate + mutation + ≥100 loop
  Mars-2 would re-run). L-1 → Stage-5 spec reconcile.
- [x] **5 Venus Stage-5 reconcile** — DONE (4 triad files + carve synced; forks → RULED, L-1 folded in INV3 +
  probe-6, stale-state sweep clean, the 5.2–5.4 carve preserved). Director spot-check ✓.
- [🔨] **6 Director ship** — Stage-6 roadmap/progress fold ✓; two scoped pathspec commits (foundation + rung).

## Z-1 — closure (Director)

**emq.5.1 — the batch-claim spine — SHIPPED.** The emq.5 batches family spine landed: `@bclaim` (the count-variant
`ZPOPMIN emq:{q}:pending` loop, the non-grouped generalization of `@gwclaim`) + `Jobs.claim_batch/4` (the
manual-pull host API) + partial-failure isolation as a *tested property* over the byte-frozen `@complete`/`@retry`.
Conformance **61 → 64** (additive minor, prior byte-unchanged); rung label **`2.5.0`** (the batches family opens);
the wire `@wire_version` frozen at `echomq:2.4.2`. The rulings: **D-1** loop · **D-2** short-batch · **D-3** +3→64 ·
**D-4** label 2.5.0. The full Director verify passed (byte-freeze · F-1 declared-keys by hand · the order theorem ·
a net-zero `ZPOPMIN→ZPOPMAX` mutation caught 6× · **two independent ≥100 loops**, 100/0 each). The one craft
finding (**L-1**, the INV3 "declared root" prose) folded into the spec at Stage 5. **5.2/5.3/5.4 now ride `@bclaim`.**

**Ship (LAW-4 — two scoped pathspec commits; the tree de-entangled, the Operator having committed the prior emq.4
fold out-of-band):**
- **Commit A (foundation):** `emq.5.md` (carve reconcile) + the `emq.5.rungs/` triad.
- **Commit B (rung):** `echo/apps/echo_mq/**` (code + 2 new tests) + this ledger + the roadmap/progress Stage-6 fold.

**Next: emq.5.2** — `min_size`/`timeout` shaping (a batch-aware Consumer over `@bclaim`; a right-size-collapse
candidate — no new Lua/lease).
