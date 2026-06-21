# EMQ.5.3 · Brief (llms) — the grounding map for Mars

The build brief for [`emq.5.3.md`](emq.5.3.md) (the body authoritative; this brief DERIVES from it). emq.5.3 built the
**grouped (affinity-respecting) batch claim** — `@gbclaim` + `Lanes.bclaim/3` — composing the SHIPPED flat-batch spine
(emq.5.1) with the CLOSED fair-lanes ring (emq.4). It is **additive over a proven mechanism**: the `@gwclaim` weighted
multi-pop (emq.4.4) is the near-isomorph — the as-built `@gbclaim` re-uses its loop/lease/`gactive`/re-ring body and
**DROPS the `gweight` read**, serving the lane's full serviceable depth (K = `min(lane depth, glimit headroom)`, no
`size`). *This brief is now a post-build record, synced to the as-built (Stage-5).*

**Framing (propagate to every sub-task):** third person for any agent; no gendered pronouns; no perceptual/
interior-state verbs ("sees"/"wants"/"feels") for agents or software — components read, compute, refuse, return; no
first-person narration ("we"/"I think").

**The three forks were RULED to their leans (D-1):** FORK 5.3-A → additive `@gbclaim` (every shipped script
byte-frozen), FORK 5.3-B → reuse `gactive` (no new key), FORK 5.3-C → ring-rotated `bclaim/3` (the rotation picks the
group; no `size`, no caller-named arity). The body + this brief are synced to the rulings.

---

## 1 · References — read these first (the real surface, paths first)

**The near-isomorph (the proven shape `@gbclaim` re-uses — SHIPPED, BYTE-FROZEN by this rung):**
- `echo/apps/echo_mq/lib/echo_mq/lanes.ex` — **`@gwclaim`** (`lanes.ex:87-129`): the weighted multi-pop. One `LMOVE
  KEYS[1] KEYS[1] LEFT RIGHT` ring step; the rotated lane = `ARGV[1] .. 'g:' .. g .. ':pending'`; K = `min(weight,
  ZCARD lane, glimit headroom)`; ONE `redis.call('TIME')` lease for the whole turn; a `for _ = 1, k` loop of
  `ZPOPMIN`/`HINCRBY attempts`/`HSET state active`/`ZADD active`; `gactive += k` (`HINCRBY ARGV[1]..'gactive' g k`);
  the re-ring guard (`if lim and act >= lim then LREM ring` / `elseif ZCARD lane == 0 then LREM ring`); returns a
  NESTED array of `{id, payload, attempts, group}`. **AS BUILT: `@gbclaim` (`lanes.ex:161-200`) IS this body with the
  `gweight` read DROPPED — K = `min(depth, glimit headroom)`, no `size`, no weight; the lane's full serviceable depth.**
- `lanes.ex` — **`wclaim/3`** (`lanes.ex:281-294`): the host verb → `{:ok, [{id, payload, attempts, group}, …]}` |
  `:empty`; honors `EchoMQ.Jobs.paused?/2` FIRST; `keys = [ring, active]`, `argv = [queue_key(queue, ""), lease_ms]`;
  maps the nested array with `Enum.map(served, &List.to_tuple/1)`. **AS BUILT: `bclaim/3` (`lanes.ex:403-416`) mirrors
  this exactly** — `(conn, queue, lease_ms)`, no `group`/`size` argument (FORK 5.3-C RULED ring-rotated).
- `lanes.ex` — **`@gclaim`** (`lanes.ex:37-61`): the single grouped claim (the `TIME` lease pattern `lanes.ex:50-52`,
  the re-ring guard `lanes.ex:53-59`). **`weight/4`** (`lanes.ex:309-317`) + **`limit/4`** (`lanes.ex:349-364`) — the
  dynamic-rate knobs (the gweight share + the glimit ceiling). **`lane_key!/2`** (`lanes.ex:566-572`) — the branded-id
  gate (`EchoData.BrandedId.valid?/1`, raises on an ill-formed group).

**The flat spine it composes with (SHIPPED, BYTE-FROZEN by this rung):**
- `echo/apps/echo_mq/lib/echo_mq/jobs.ex` — **`@bclaim`** (`jobs.ex:200-219`, the flat-set count-variant `ZPOPMIN`
  loop) + **`claim_batch/4`** (`jobs.ex:520-539` → `{:ok, [{id, payload, att}, …]}` | `:empty`, `paused?/2` FIRST,
  non-blocking, `keys = [pending, active]`, `argv = [queue_key(queue, "job:"), lease_ms, size]`). **The flat analog —
  `bclaim/3` is `claim_batch` over a ring-rotated lane instead of the flat set, returning the 4-tuple with `group`;
  unlike `claim_batch/4` it carries NO `size` arg (the lane's serviceable depth IS the batch).**
- `jobs.ex` — the per-member settle the worker rides (BYTE-FROZEN): **`complete/5`** (`jobs.ex:589` — `HINCRBY
  gactive g -1` releases a slot) / **`retry/7`** (`jobs.ex:759`). A batch is a CLAIM unit, not a RESOLUTION unit — one
  poison member retries alone (the emq.5.1 partial-failure model).

**The fairness-witness precedent (SHIPPED — the emq.4.4-L1 pattern, the template to follow under FORK 5.3-C Arm 1):**
- `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — **`:starvation_drill`** (`conformance.ex:1992-2073`): the
  bounded-9-turn early-window `MapSet` interleaving witness + the per-member `ZSCORE active` lease check + the
  terminal-drain liveness floor. **The fairness scenario follows this exact shape.** **`:batch_claim`**
  (`conformance.ex:2084-2130`): the size/mint-order/shared-lease batch template (the `deadlines |> Enum.uniq |>
  length == 1` shared-lease check, the `attempts == [1,1,…]` fencing check). **`:weighted_proportion`**
  (`conformance.ex:1934`) — the proportional-band check.
- The scenario harness: `scenarios/0` (`conformance.ex:87`) is a keyword list `name: "contract description"`,
  run-ordered; `run/2` (`conformance.ex:173`) dispatches `apply_scenario(name, conn, q)`, purges, prints one line,
  returns `{:ok, length}`. A new scenario = a `name: "…"` entry + a `defp apply_scenario(:name, conn, q)` clause.
- The pinning tests: `test/conformance_run_test.exs:56` (`assert Conformance.run(conn, q) == {:ok, 70}`) +
  `test/conformance_scenarios_test.exs` (the `@run_order` list of 70 names + `assert Keyword.keys(scenarios()) ==
  @run_order`). **AS BUILT: BOTH re-pinned 67 → 70** (`grouped_batch_affinity`/`grouped_batch_ceiling`/
  `grouped_batch_fairness`).

**The v2 laws (the program floor):** `.claude/skills/echo-mq-program.md` (the v2 laws table, the gate ladder, the
additive-minor law, NO-INVENT) · the design canon [`../../../../emq.design.md`](../../../../emq.design.md) §6.2
(count-variant pops — the reserved mechanism), §4 (the server clock), S-6 (declared keys — the A-1/L-1 law), S-1/§6
(the braced keyspace) · the sibling [`../../emq.4/emq.4.rungs/emq.4.4.md`](../../emq.4/emq.4.rungs/emq.4.4.md) (the
`@gwclaim` precedent + emq.4.4-L1, the load-bearing interleaving-witness lesson).

---

## 2 · Requirements (numbered; each traced back to a story, forward to an INV/check)

| # | Requirement | Story | INV / check |
|---|---|---|---|
| R1 | Build `@gbclaim` — a NEW inline `Script.new(:gbclaim, …)` in `lanes.ex` BESIDE `@gwclaim`: a homogeneous ring-rotated lane-scoped batch, **K = `min(lane depth, glimit headroom)`** (the `gweight` read DROPPED, no `size`), ONE `redis.call('TIME')` lease, the per-member `ZPOPMIN`/`HINCRBY attempts`/`HSET active`/`ZADD active` loop, `gactive += K`, the `@gwclaim` re-ring guard; returns the nested `{id, payload, attempts, group}` array. *(As built `lanes.ex:161-200`.)* | US-AFFINITY | INV-Affinity, INV-ServerClock |
| R2 | Build `Lanes.bclaim/3` `(conn, queue, lease_ms)` — the host verb (FORK 5.3-C RULED ring-rotated, no `group`/`size`): maps `:empty` (empty ring / paused / no-headroom) + `{:ok, [{id, payload, attempts, group}, …]}`; honors `paused?/2` FIRST (the `wclaim/3` precedent). *(As built `lanes.ex:403-416`.)* | US-AFFINITY | INV-Affinity |
| R3 | Batch concurrency (FORK 5.3-B RULED reuse `gactive`): the served count increments `gactive` by the ACTUAL K; the `glimit` headroom clamp (`K ≤ lim - cur`) guarantees no batch passes `glimit`; a lane at its ceiling is de-ringed (serves `:empty`). *(As built `lanes.ex:193`.)* | US-CEILING | INV-Ceiling |
| R4 | The fairness guarantee (FORK 5.3-C RULED ring-rotated): the batch rides the ring rotation, fairness preserved by construction — witnessed by the bounded-early-window interleaving check (emq.4.4-L1). | US-FAIRNESS | INV-Fairness (emq.4.4-L1) |
| R5 | The dynamic rate rides the shipped floor: the existing `weight/4`/`limit/4` ARE the runtime knobs, ridden unchanged; NO new key. | US-RATE | INV-DeclaredKeys, INV-Frozen |
| R6 | Register the conformance scenarios additively: `grouped_batch_affinity` (every member from the served group + one shared lease), `grouped_batch_ceiling` (the headroom clamp), and `grouped_batch_fairness` (the bounded-early-window interleaving witness, the `starvation_drill` shape). The prior 67 byte-unchanged; re-pin **67 → 70** in BOTH pinning tests. | US-ADDITIVE | INV-Frozen, S-3/§5 |
| R7 | Byte-freeze every shipped `@g*`/`@bclaim`: `grep redis.call` on those in the lib diff = 0; the prior scenarios git-verified unchanged. | US-ADDITIVE, US-GATE | INV-Frozen |
| R8 | Pass the per-app gate ladder on Valkey 6390 + the **≥100 determinism loop** (a mint/lease surface); honest-row reporting; the diff inside `echo/apps/echo_mq`. | US-GATE | INV-Determinism, S-4, every INV |

---

## 3 · Execution topology

**Runtime shape.** `@gbclaim` is one inline Lua script, one atomic turn: `LMOVE` rotate the ring → read `ZCARD` lane
depth → clamp **K = `min(depth, glimit headroom)`** (no `size`, no `gweight` read) → one `TIME` read → a K-iteration
`ZPOPMIN` loop leasing each member on the shared deadline → `gactive += K` → the re-ring guard. No new process, no new
key, no wire change. The host verb `bclaim/3` is the thin `wclaim/3` envelope (paused-first, map the nested array).

**Files touched (the EXACT set — boundary `echo/apps/echo_mq`):**
- `lib/echo_mq/lanes.ex` — ADDED `@gbclaim` (`lanes.ex:161-200`) + `bclaim/3` (`lanes.ex:403-416`). Every other `@g*`
  byte-frozen.
- `lib/echo_mq/conformance.ex` — ADDED `grouped_batch_affinity`/`grouped_batch_ceiling`/`grouped_batch_fairness`
  (`scenarios/0` entries + `apply_scenario` clauses `conformance.ex:2367/2435/2486`). The prior scenarios byte-unchanged.
- `test/conformance_run_test.exs` — re-pinned `{:ok, 67}` → `{:ok, 70}`.
- `test/conformance_scenarios_test.exs` — appended the three names to `@run_order` (67 → 70); count prose updated.
- `mix.exs` — the rung label `2.5.1` (the within-family patch — D-2 corrected a `2.6.0` first cut; the wire
  `@wire_version` stays `echomq:2.4.2`).
- **NOT** `keyspace.ex` (no new key family — `@gbclaim` rides the shipped `g:`-segment + `gactive`/`glimit`).
- **NOT** `echo_wire` (the claim rides the shipped connector `eval`). **NOT** `apps/echomq` (the frozen reference).

**Build-order DAG (as executed):**
```
FORK 5.3-A/B/C RULED (Operator, AskUserQuestion — all to leans, D-1)
   └─► R1  @gbclaim  (the @gwclaim isomorph, gweight DROPPED, K = min(depth, glimit headroom))
         └─► R2  bclaim/3  (the host verb — ring-rotated, no group/size)
               ├─► R3  batch concurrency  (gactive += K, the glimit headroom clamp — inside @gbclaim)
               ├─► R4  fairness  (ring-rotated → the interleaving witness)
               └─► R5  dynamic rate  (the shipped weight/4 / limit/4, ridden unchanged)
                     └─► R6  conformance scenarios  (3 grouped_batch_*; re-pin 67 → 70)
                           └─► R7  byte-freeze grep (= 0)
                                 └─► R8  the gate ladder + the ≥100 loop
```

---

## 4 · Agent stories (Directive + Acceptance gate — the contracts the Operator/Apollo accept at the boundary)

### AS-1 — `@gbclaim`, the affinity multi-pop (R1)

**Directive.** Added a NEW inline `Script.new(:gbclaim, …)` in `lanes.ex` beside `@gwclaim`. The `@gwclaim` body
(`lanes.ex:87-129`) re-used with the ONE delta: **the `gweight` read is DROPPED** — K = `min(depth, glimit headroom)`
(no `size`, no weight; the lane's full serviceable depth). The script does the `LMOVE` ring step (FORK 5.3-C RULED
ring-rotated); one `redis.call('TIME')` read for the whole turn; the per-member `ZPOPMIN`/`HINCRBY attempts`/`HSET
state active`/`ZADD active` loop on the shared deadline; `gactive += K` via `HINCRBY ARGV[1]..'gactive' g k`; the
`@gwclaim` re-ring guard (`lanes.ex:194-198`). The braced `KEYS[1]=ring`/`KEYS[2]=active` pin the `{q}` slot; the
lane/`gactive`/`glimit` derive from the declared queue base `ARGV[1]`. Returns the nested `{id, payload, attempts,
group}` array.

- **Precondition.** A queue with a fair-lanes ring; the branded group ids; FORK 5.3-A RULED additive.
- **Postcondition.** Up to K members from ONE rotated lane served, leased on one `TIME` deadline, `gactive += K`.
- **Invariant.** K never exceeds the `glimit` headroom; every member from the one served group; one shared lease.
- **Acceptance gate.** The affinity + ceiling `:valkey` scenarios green; `grep redis.call` on every OTHER `@g*` /
  `@bclaim` = 0 (the new `@gbclaim` is the only added script body).

### AS-2 — `bclaim/3`, the host verb (R2)

**Directive.** Added `Lanes.bclaim/3` `(conn, queue, lease_ms)` mirroring `wclaim/3` (`lanes.ex:281-294`): honors
`EchoMQ.Jobs.paused?/2` FIRST (`:empty` on a paused queue, lanes untouched); `keys = [ring, active]`, `argv =
[queue_key(queue, ""), lease_ms]` (the `@gbclaim` declared roots); maps `{:ok, []}` → `:empty` and `{:ok, served}` →
`{:ok, Enum.map(served, &List.to_tuple/1)}`. FORK 5.3-C RULED ring-rotated → no `group`/`size` argument (the rotation
picks the lane).

- **Precondition.** `@gbclaim` registered; `lease_ms > 0` (guard clause).
- **Postcondition.** `{:ok, [{id, payload, attempts, group}, …]}` on a hit | `:empty` on empty-ring/paused/no-headroom.
- **Invariant.** A paused queue answers `:empty` host-side FIRST (the `claim/3`/`wclaim/3` precedent).
- **Acceptance gate.** The affinity scenario claims a batch and asserts the 4-tuple shape + the homogeneous-group
  property; a paused-queue claim returns `:empty` with the lane untouched.

### AS-3 — the conformance scenarios + the count re-pin (R6, R7)

**Directive.** Registered the three scenarios in `scenarios/0` (a `name: "contract"` entry each) + a `defp
apply_scenario(:name, conn, q)` clause each: (a) `grouped_batch_affinity` (`conformance.ex:2367`) — flood two branded
lanes, claim a grouped batch, assert every member's row `group` equals the served group + one shared `TIME` lease (the
`batch_claim` shared-lease check); (b) `grouped_batch_ceiling` (`conformance.ex:2435`) — `glimit` g = 3, flood 8 deep,
claim a grouped batch, assert exactly 3 served + `gactive` g = 3 + a second claim `:empty` until a `complete/5` frees
headroom; (c) `grouped_batch_fairness` (`conformance.ex:2486`) — the bounded-early-window interleaving witness (the
`starvation_drill` shape, `conformance.ex:1992-2073` — a `MapSet` of served groups over a bounded window + every light
lane present + the terminal drain). Kept the prior 67 byte-unchanged; re-pinned 67 → 70 in BOTH pinning tests (the
`{:ok, 70}` assertion + the `@run_order` list + the count prose).

- **Precondition.** The prior 67 scenarios green and byte-unchanged.
- **Postcondition.** `Conformance.run/2` → `{:ok, 70}`; both pinning tests pass.
- **Invariant.** The prior scenarios are byte-identical (git-verified); each new probe is registered in the same
  change; the fairness scenario's interleaving witness is the load-bearing assertion (NOT a terminal drain alone).
- **Acceptance gate.** `git diff` on `conformance.ex` shows only additions to `scenarios/0` + new `apply_scenario`
  clauses; `Conformance.run/2` prints 70 lines; the fairness scenario goes RED under a FIFO/serve-heavy-first
  mutation (the no-op-defeater).

### AS-4 — the gate ladder + the ≥100 loop (R8)

**Directive.** Run the per-app gate ladder INSIDE `echo/apps/echo_mq`: re-probe `asdf current` from the app dir;
`valkey-cli -p 6390 ping` → PONG; `TMPDIR=/tmp mix compile --warnings-as-errors`; `TMPDIR=/tmp mix test --include
valkey`; `EchoMQ.Conformance.run/2` → `{:ok, 70}`; the **≥100 determinism loop** (`for i in $(seq 1 100); do
TMPDIR=/tmp mix test --include valkey || break; done`, the loop owning the machine — the same-ms branded-`JOB` mint
hazard); the byte-freeze grep (= 0). Report honest-row (Valkey 6390).

- **Precondition.** AS-1..AS-3 complete.
- **Postcondition.** Every gate green; the ≥100 loop green end to end.
- **Invariant.** The diff stays inside `echo/apps/echo_mq` (+ no `echo_wire` edit); `mix.lock` excluded unless a real
  dep moved (none expected).
- **Acceptance gate.** The full ladder green; the loop 100/0; the byte-freeze grep 0.

---

## 5 · The short prompt (no decision the spec has not fixed)

The grouped (affinity-respecting) batch claim inside `echo/apps/echo_mq`, additive over the proven `@gwclaim` weighted
multi-pop. ONE inline `@gbclaim` (the `@gwclaim` body with the `gweight` read DROPPED — **K = `min(depth, glimit
headroom)`**, no `size`; the group-selection RULED ring-rotated, FORK 5.3-C) + the `bclaim/3` host verb (`conn, queue,
lease_ms` — no `group`/`size`). Reuse `gactive` for batch concurrency (a batch counts its served members; the `glimit`
headroom clamp guarantees no batch passes the ceiling). Register `grouped_batch_affinity` + `grouped_batch_ceiling` +
`grouped_batch_fairness` additively (the prior 67 byte-unchanged → 70; the fairness scenario carries emq.4.4-L1 — a
bounded-early-window interleaving witness, NOT a terminal drain). Every shipped `@g*`/`@bclaim` byte-frozen (`grep
redis.call` = 0). One `TIME` read, one batch lease. No new key, no wire change (`@wire_version` stays `echomq:2.4.2`),
no `echo_wire` edit, no `apps/echomq` touch; `mix.exs` label `2.5.1`. Gate per-app on Valkey 6390 + the ≥100
determinism loop. The body [`emq.5.3.md`](emq.5.3.md) is authoritative.

Family: [`../emq.5.md`](../emq.5.md) · Body: [`emq.5.3.md`](emq.5.3.md) · Stories: [`emq.5.3.stories.md`](emq.5.3.stories.md)
· Runbook: [`emq.5.3.prompt.md`](emq.5.3.prompt.md) · Program law: `.claude/skills/echo-mq-program.md` · Design:
[`../../../../emq.design.md`](../../../../emq.design.md) §6.2 · The sibling precedent + emq.4.4-L1:
[`../../emq.4/emq.4.rungs/emq.4.4.md`](../../emq.4/emq.4.rungs/emq.4.4.md)
