# EMQ.4.4 — the build sheet (the Mars brief: weighted multi-pop + the starvation drill)

> **✅ SHIPPED — Fork B ruled Arm 2 (the additive weighted multi-pop, D-1); built + Director-verified PASS.** This
> brief was authored pre-build with the two Fork-B-dependent requirements `[WITHHELD]`; it served its build purpose.
> The **body ([`emq.4.4.md`](emq.4.4.md)) is now authoritative on the as-built** — read it for the shipped surface.
> The two `[WITHHELD]` resolved as built: **R1 weight home = `emq:{q}:gweight`** (a per-queue HASH on the
> `Keyspace.queue_key/2` shape — no new key family — set by `weight/4`); **R2 mechanism = the new inline `@gwclaim`
> script** (`wclaim/3` host verb — one `LMOVE` step, K = `min(weight, depth, glimit headroom)` heads in one atomic
> turn sharing one server-clock lease, `gactive += K`, the `@gclaim:53-59` re-ring guard; `@gclaim` BYTE-FROZEN).
> Conformance 59 → 61; `@wire_version` unchanged at `echomq:2.4.2`; `mix.exs` label → 2.4.4; the determinism
> posture was the multi-seed sweep (Arm 2 mints no id and starts no process). The starvation drill shipped as a
> **bounded-early-window interleaving witness** (every light lane served inside a 9-turn / 3-ring-cycle window)
> plus the terminal drain — NOT a terminal depth-0 check alone (the body's DoD + the stories US2 carry the why).
> The Requirements / topology / agent-stories below are the build-time record; where they read forward-tense or
> say `[WITHHELD]`, the body's as-built wins.
>
> The agent brief Mars built from. It DERIVES from the body ([`emq.4.4.md`](emq.4.4.md), authoritative) and the
> acceptance ([`emq.4.4.stories.md`](emq.4.4.stories.md)). Where this brief and the body disagree, the body wins.
>
> **The Fork-B-WITHHELD discipline (as authored pre-build).** The weight REPRESENTATION and the rotation MECHANISM
> were pinned at the Fork B ruling (the Operator's call — Director routes). This brief authored every
> Fork-B-INDEPENDENT requirement FULLY and marked the two dependent ones **[WITHHELD — pinned at the Fork B
> ruling]** with both candidate shapes documented. Mars built the WITHHELD surface to the ruled arm (Arm 2).
>
> **Framing law (propagated — bind it in any sub-brief).** Third person for any agent; no gendered pronouns for
> agents; no perceptual or interior-state verbs for agents or software (components read, compute, refuse, return);
> no first-person narration.

---

## 1 · References (read first, in this order)

1. **The rung body (authoritative):** [`emq.4.4.md`](emq.4.4.md) — Goal · 5W · Scope · INV1–6 · Fork B · DoD.
2. **The acceptance:** [`emq.4.4.stories.md`](emq.4.4.stories.md) — US1 proportion · US2 the starvation drill ·
   US3 byte-freeze · US4 wire law · US5 additive-minor · US6 determinism/honest-row · US-GATE.
3. **The family contract + the carve + Fork B restated:** [`../emq.4.md`](../emq.4.md) (EMQ.4-INV1–8; Fork B
   the three arms; INV8 the no-pre-emption boundary).
4. **The as-built lane surface (the build target — re-probe at Stage-0):**
   `echo/apps/echo_mq/lib/echo_mq/lanes.ex` —
   - `@gclaim` **lanes.ex:37-61** — the shipped ring rotation the weighting deepens. The exact byte shape:
     `LMOVE KEYS[1] KEYS[1] 'LEFT' 'RIGHT'` **:38** (the rota step; `g` = the rotated lane group; `{}` if the
     ring is empty), `local lane = ARGV[1] .. 'g:' .. g .. ':pending'` **:40** (the A-1 ARGV-slot-rooted lane
     key), `ZPOPMIN lane` **:41** (the head; on empty → `LREM KEYS[1] 0 g` + `return {}`), `HINCRBY <row>
     attempts 1` **:48** (the fencing token), the **server-clock lease** `local t = redis.call('TIME'); local
     now = t[1] * 1000 + math.floor(t[2] / 1000)` **:50-51** → `ZADD KEYS[2] now + ARGV[2] id` **:52** (active,
     lease deadline), `HINCRBY ARGV[1]..'gactive' g 1` **:53** (the active counter), the `glimit` re-ring guard
     `HGET ARGV[1]..'glimit' g` **:54** + `if lim and act >= lim → LREM KEYS[1] 0 g` **:55-56** + `elseif ZCARD
     lane == 0 → LREM KEYS[1] 0 g` **:57-58**.
   - The full `@g*` family to **byte-freeze** (every one except the Fork-B target): `@genqueue` **:16**,
     `@gpause` **:63**, `@gresume` **:69**, `@glimit` **:84**, `@greassign` **:119**, `@gdrain` **:294**,
     `@greap_group` **:355** (+ `@gclaim` **:37** too iff Fork B rules additive).
   - `claim/3` **lanes.ex:171-184** — the host verb (`Connector.eval(conn, @gclaim, keys=[ring, active],
     argv=[queue_key(""), lease_ms])` → `:empty | {:ok, {id, payload, att, group}}`; honors the queue-wide
     pause first).
   - `lane_key!/2` **lanes.ex:433-439** (`defp`) — the branded gate: `if EchoData.BrandedId.valid?(group) then
     queue_key(queue, "g:" <> group <> ":pending") else raise ArgumentError`. The weight + claim boundaries
     gate through this (or its host-verb callers) before any wire.
5. **The keyspace grammar (UNEDITED — the weight rides an existing shape):** `echo/apps/echo_mq/lib/echo_mq/keyspace.ex`
   — `queue_key/2` **:13-15** builds `emq:{q}:<type>` for ANY type string (so a `gweight` per-queue HASH needs
   NO grammar edit); `job_key/2` **:17-24** gates `BrandedId.valid?/1`; `version_key/0` **:29-30** → `{emq}:version`.
6. **The weight-home precedent (`glimit`/`gactive` shapes):** `echo/apps/echo_mq/lib/echo_mq/lanes.ex` wires
   `Keyspace.queue_key(queue, "glimit")` / `("gactive")` **:150-151** (per-queue HASHes keyed by group); read in
   `@gclaim` **:53-54** via `HGET ARGV[1]..'glimit' g` / `HINCRBY ARGV[1]..'gactive' g 1`. The same shape across
   `jobs.ex` / `stalled.ex` / `admin.ex` (group-aware reads). `Metrics.lane_depths/3` + `@lane_counts`
   **metrics.ex:279-310** reads per-lane backlog (the drill reads lane depths through this or a raw `ZCARD`).
7. **The metronome (4.3 — for Fork B Arm 3 cost):** `echo/apps/echo_mq/lib/echo_mq/metronome.ex` — `EchoMQ.Metronome`,
   a supervised `spawn_link` process per queue owning the single `BLPOP emq:{q}:wake <beat>` block + an
   idle-consumer registry; **owns NO Valkey lease** (moduledoc **:17-24**); the decision is a pure
   `EchoMQ.Metronome.Core` (`dispatch/1` + `repoke?/1`, no Valkey). The consumer path is **opt-in** (emq.4.3 D-3 —
   `consumer.ex` standalone `park/1` retained byte-for-byte; codemojex unbroken).
8. **The conformance harness:** `echo/apps/echo_mq/lib/echo_mq/conformance.ex` — `scenarios/0` (the **59**-name
   set; the `rotate` scenario "two lanes claim in strict rotation — the ring is the rota" **conformance.ex:91** is
   the equal-share precedent the weighted scenario deepens) · `run/2` → `{:ok, n}`. The two pinning tests:
   `test/conformance_run_test.exs` (`{:ok, 59}` **:48**) + `test/conformance_scenarios_test.exs` (`@run_order` =
   59 names **:28-88**).
9. **The v1 capability reference (the re-aim record, READ-ONLY — the form NOT to lift):**
   [`../../../emq.commands/features/groups/changePriority-7.md`](../../../emq.commands/features/groups/changePriority-7.md)
   (RETIRED → "weighted rotation, emq.4" — the canon names THIS rung).
10. **Design + program law:** [`../../../../emq.design.md`](../../../../emq.design.md) §4 (the server-clock lease law),
    S-6 (the declared-keys A-1 law), S-1/§6 (the braced grammar), §10 seam 2 / §4 cluster 2 (the groups family
    RULED → emq.4) · the shared program law `.claude/skills/echo-mq-program.md` (the v2 laws, the gate ladder, the
    additive-minor conformance law, NO-INVENT) · the as-built map `.claude/skills/echo-mq-surface.md`.
11. **The predecessor ledgers (what 4.1/4.2/4.3 actually built — the byte-freeze + version-model precedents):**
    [`emq-4-1.progress.md`](../../../progress/emq-4-1.progress.md) (the `@greassign`/`@gdrain`
    additive-script precedent + the 52→54 re-pin),
    [`emq-4-2.progress.md`](../../../progress/emq-4-2.progress.md) (the `@greap_group`
    additive-beside-frozen-script precedent + the 54→55 re-pin + the two-planes version model),
    [`emq-4-3.progress.md`](../../../progress/emq-4-3.progress.md) (the metronome-as-system
    + D-3 opt-in consumer + D-4 two-planes version + D-5 no-conformance-for-a-non-wire-property + the FOREGROUND
    ≥100-loop pattern + the F-1/F-2 process-ordering finding family).

---

## 2 · Requirements (numbered; each → a story + an invariant)

| # | Requirement | Story | Invariant | WITHHELD? |
|---|---|---|---|---|
| **R1** | A lane carries a **weight**; the weight's home is a per-queue **g-segment HASH** (the candidate `emq:{q}:gweight`, keyed group→weight, beside `glimit`/`gactive`) — an existing key SHAPE, **no new key family**, **no §6 grammar edit**. A weight is set on a **valid branded group** (gated at `lane_key!/2` or the host verb before any wire). | US1, US4 | INV3, INV5 | **the EXACT home pinned at the Fork B ruling** (a HASH field is the candidate; Arm 1 may add a `gdeficit` sibling, Arm 3 a `gbudget` sibling) |
| **R2** | The claim rotation serves lanes **in proportion to weight** (a higher-weight lane gets proportionally more serves, **never all**); the served job's lease is computed from the **server clock** (`redis.call('TIME')`, the shipped `@gclaim` :50-51 pattern), no host timestamp crosses the lease. | US1 | INV1, INV4 | **the rotation MECHANISM pinned at the Fork B ruling** (deficit counter on the ring → `@gclaim` edit; weighted multi-pop → a new additive script; per-lane budget → couples to the metronome) |
| **R3** | The **starvation drill**: under sustained skew (one lane flooded, others trickling), **every** lane's pending depth reaches zero over the drill window — the capstone guarantee. A weight of zero is NOT a rotation outcome (it is the operator's `Lanes.pause/3`); the drill uses positive weights on every lane. | US2 | INV1, INV4, INV5 | — (the OUTCOME is fixed; the mechanism behind it is R2's) |
| **R4** | The **byte-freeze** discipline: every shipped `@g*` script emq.4.4 does not name is byte-identical to HEAD (`grep redis.call` on those scripts in the lib diff = 0). The frozen set = all EIGHT `@g*` if Fork B rules additive; the OTHER SEVEN if Fork B rules an `@gclaim` edit. The prior fair-lanes scenarios (`rotate`, `pause`, `limit`, `lane_depth`, `stalled_group`, `reassign`, `lane_drain`, `reap_group`) pass byte-unchanged. | US3 | INV2, INV6 | — |
| **R5** | The **wire law**: no new key family; the rotation rides the shipped `emq:{q}:g:<group>:pending` / `ring` keys; **no numeric per-job priority** (weight is per-lane — `grep` for a priority score / `prioritized` key / `pc` counter = empty); the §6 grammar in `keyspace.ex` is unedited; the **two-planes version** model holds (`mix.exs` version = the rung LABEL → 2.4.4, read by nobody; `@wire_version` stays `echomq:2.4.2` IF additive — an `@gclaim` edit's wire-behaviour change is a protocol minor, the `@wire_version` step ruled at the Fork B ruling). | US4 | INV3, INV6 | the `@wire_version` step is conditional on the ruled arm |
| **R6** | The **additive-minor conformance** growth: register the **weighted-proportion** + **starvation-drill** scenarios in `scenarios/0` **with their probes in the same change**; the prior **59** scenarios byte-unchanged (git-verified); re-pin **59 → N** (N = 61) in **both** pinning tests; `Conformance.run/2` prints N and returns `{:ok, N}`. | US1, US2, US5, US-GATE | INV6 | — |
| **R7** | The **proof**: the `:valkey` weighted + drill suites green per-app (TMPDIR=/tmp, --include valkey); the determinism posture honest to the ruled mechanism (≥100 FOREGROUND loop IFF a process/lease surface, else a multi-seed sweep + the statement); honest-row reporting (Valkey on 6390); **Apollo MANDATORY** iff `@gclaim` is edited (independent ladder + loop re-run + byte-frozen-script re-verify). | US6 | S-4, INV1 | the loop-vs-sweep choice is conditional on the ruled arm |

**The two WITHHELD requirements (R1 home + R2 mechanism)** are the only ones the Fork B ruling fills. Every other
requirement is build-grade now and does not move when the mechanism is pinned (US1/US2 assert the OBSERVABLE
outcome, so R3–R7 are mechanism-agnostic).

---

## 3 · Execution topology

### Runtime shape
A claim under emq.4.4 is the shipped `Lanes.claim/3` path deepened: the rotation reads each serviceable lane's
**weight** (R1) and serves lanes **in proportion** to it (R2), still leasing the served job on the server clock
(R2/INV4) and still gating each group as a branded id (R5/INV5). The weight rides a **new per-queue g-segment
HASH** beside `glimit`/`gactive` — same key shape, no new family (R1/R5/INV3). Nothing in `echo_wire` moves (the
rotation rides the shipped connector `eval`); `apps/echomq` is untouched. The **mechanism** of "in proportion"
is the [WITHHELD] Fork-B arm:
- **Arm 1 (deficit counter, DRR):** the rotation EDITS `@gclaim` — each lane carries a `gdeficit` credited per
  rotation and consumed per serve; a lane serves while it has credit, else it is skipped and re-credited next
  round. HIGH-risk (a frozen-claim-path edit) → byte-freeze the OTHER seven `@g*` + Apollo MANDATORY + the ≥100
  loop.
- **Arm 2 (weighted multi-pop):** a NEW additive script (`@gwclaim` candidate) leaving `@gclaim` byte-unchanged
  — a higher-weight lane serves K heads per rotation (K = the weight). NORMAL+ → byte-freeze ALL eight `@g*` +
  the determinism posture by the multi-seed sweep (mint-free/process-free).
- **Arm 3 (per-lane budget refreshed by the metronome):** the beat (4.3) refreshes a per-lane serve budget — but
  the reconcile finds this ENTANGLING (the shipped metronome owns no lease and decides host-side in a pure Core;
  a per-lane budget either regresses fairness to host-side or needs a new wire structure + couples two rungs +
  risks a §6 question). Re-costed in the body's Fork B and the report.

### Build-order DAG (one increment per run)
```
Stage-0  re-probe the floor (lag-1 law): @gclaim:37-61 byte-anchor, the 8-script @g* family,
         the 59 conformance count + both pins, the gweight-home shape, the metronome shape
            │
            ▼   [the Fork B ruling is in hand BEFORE this DAG starts — Operator-ruled at the pre-build gate]
   ┌────────┴────────┐
   ▼                 ▼
 R1 weight home    R4 byte-freeze posture set (which @g* are frozen — 7 or 8 — per the ruled arm)
 (gweight HASH;        │
  the ruled home)      │
   │                   │
   ▼                   │
 R2 weighted rotation ─┘   (the ruled mechanism: @gclaim edit OR a new @gwclaim — byte-freeze the rest)
   │
   ▼
 R3 the starvation drill (the :valkey skew scenario — the load-bearing no-op-defeater)
   │
   ▼
 R6 the two conformance scenarios (weighted_proportion + starvation_drill) + re-pin 59→N in both pins
   │
   ▼
 R5 wire-law sweep (no new family / no numeric priority / §6 unedited / two-planes version) — a grep battery
   │
   ▼
 R7 the proof: per-app gate ladder + the determinism posture (loop iff process/lease, else sweep) + honest-row
       + Apollo MANDATORY iff @gclaim edited
```

### EXACT files touched (the boundary — re-probe line anchors at Stage-0)
| File | Edit | What |
|---|---|---|
| `echo/apps/echo_mq/lib/echo_mq/lanes.ex` | EDIT | the weighted rotation. **If Fork B = Arm 1:** edit `@gclaim` (:37-61) + add the `gdeficit` read/credit; byte-freeze the other seven `@g*`. **If Arm 2:** ADD a new `@gwclaim` script + its host verb; `@gclaim` byte-unchanged. The `gweight` host wiring (`Keyspace.queue_key(queue, "gweight")`, the `glimit` :150-151 precedent) + a `weight/4`-style host verb to set it. |
| `echo/apps/echo_mq/lib/echo_mq/conformance.ex` | EDIT | the `weighted_proportion` + `starvation_drill` scenarios (append to `scenarios/0` after the lane scenarios) + their probes + the count re-pin in the moduledoc/run tally prose. |
| `echo/apps/echo_mq/test/<lanes_or_weighted>_test.exs` | NEW/EDIT | the `:valkey` weighted-proportion + starvation-drill proof (model on `conformance.ex`'s `rotate`/`pause` scenarios + the lane test harness — per-test unique queue, `on_exit` purge, `Snowflake.start(4)`, branded `JOB`/`PRT` ids). |
| `echo/apps/echo_mq/test/conformance_run_test.exs` | EDIT | re-pin `{:ok, 59}` → `{:ok, N}` (:48). |
| `echo/apps/echo_mq/test/conformance_scenarios_test.exs` | EDIT | append the two names to `@run_order` (:28-88) → re-pin to N. |
| `echo/apps/echo_mq/mix.exs` | EDIT | the rung LABEL `version: "2.4.3"` → `"2.4.4"` (:7; read by nobody at runtime — the two-planes model). |
| `echo/apps/echo_wire/lib/echo_mq/connector.ex` | **EDIT IFF Arm 1** | `@wire_version` step (the conditional protocol minor; UNTOUCHED if additive). |

**NOT touched:** `keyspace.ex` (no §6 grammar edit — `gweight` rides `queue_key/2`); `jobs.ex` / `stalled.ex` /
`admin.ex` (the weight is a lane-rotation concern, not a transition concern — unless the ruled arm proves a
read-site must learn the weight, which the reconcile does not foresee); `metronome.ex` / `consumer.ex` (4.3's
surface — Arm 3 would touch them, but Arm 3 is dis-recommended); `apps/echomq` (the v1 reference); `mix.lock`
(no real dep moved).

---

## 4 · Agent stories (Directive + Acceptance gate; each surface a contract)

- **AS-1 — the weight home (R1).** *Directive:* build the lane-weight store as a per-queue g-segment HASH
  (the ruled home; `emq:{q}:gweight` keyed group→weight is the candidate) + a host verb to set a weight on a
  branded-gated group. *Acceptance gate (contract):* **precondition** the group is a valid branded id (gated at
  `lane_key!/2` / the host verb — an ill-formed group raises pre-wire); **postcondition** the weight is readable
  back for that group; **invariant** no new key family (`grep` the new key against the g-segment family = a
  match; §6 grammar unedited).
- **AS-2 — the weighted rotation (R2).** *Directive:* build the rotation so serviceable lanes are served in
  proportion to weight (the ruled mechanism — `@gclaim` edit OR a new `@gwclaim`). *Acceptance gate:*
  **precondition** two branded lanes, weights 3:1, both flooded; **postcondition** over a window lane A is served
  ≈3x lane B (within a tolerance band) AND lane B is served > 0 (US1); **invariant** the served lease is
  `TIME`-derived (no host timestamp — `grep` the rotation for a host lease ts = empty), and every unedited `@g*`
  is byte-frozen (US3).
- **AS-3 — the starvation drill (R3) — the load-bearing proof.** *Directive:* build the `:valkey` drill: flood
  one lane, trickle the others, drive the rotation, assert every lane drains. *Acceptance gate:* **precondition**
  each light lane's initial depth > 0; **postcondition** every lane reaches depth 0 within the window (US2);
  **invariant** the no-op-defeater bites — a FIFO/no-fair-share rotation leaves a light lane stuck (a mutation
  that serves the heavy lane to exhaustion first → the drill catches it).
- **AS-4 — additive-minor conformance (R6).** *Directive:* register `weighted_proportion` + `starvation_drill`
  in `scenarios/0` with probes; re-pin 59→N in both pins. *Acceptance gate:* **precondition** the prior 59 names
  + contracts + verdict bodies git-verified byte-unchanged; **postcondition** `Conformance.run/2` → `{:ok, N}`
  (N=61), both pins pass; **invariant** the git-diff of `scenarios/0` shows only additions.
- **AS-5 — the wire-law + byte-freeze sweep (R4, R5).** *Directive:* run the grep battery (no new family / no
  numeric priority / §6 unedited / byte-frozen `@g*` / two-planes version). *Acceptance gate:* **postcondition**
  every grep returns its expected empty/zero; **invariant** `@wire_version` is `echomq:2.4.2` (additive) or the
  ruled step (Arm 1), `mix.exs` is the 2.4.4 label.
- **AS-6 — the proof + determinism posture (R7).** *Directive:* run the per-app gate ladder + the determinism
  posture honest to the ruled arm. *Acceptance gate:* **postcondition** compile clean, `:valkey` suites green,
  `{:ok, N}`, the loop (process/lease) OR the sweep (pure) green; **invariant** honest-row (Valkey 6390), Apollo
  MANDATORY iff `@gclaim` edited.

---

## 5 · The per-app gate ladder + the determinism posture (run before reporting)

Run from **inside** `echo/apps/echo_mq` (never umbrella-wide — the master invariant):
```bash
cd /Users/jonny/dev/jonnify/echo/apps/echo_mq
asdf current erlang                              # re-probe — expect Erlang 28.5.0.1 / Elixir 1.18.4 (echo/.tool-versions); do NOT hardcode
redis-cli -p 6390 ping                           # → PONG (the live engine is Valkey on 6390; {emq}:version reads echomq:2.4.2 == @wire_version)
TMPDIR=/tmp mix compile --warnings-as-errors     # clean-compile gate (TMPDIR=/tmp for ALL mix — the ENOSPC overlay)
TMPDIR=/tmp mix test --include valkey            # the :valkey weighted + drill suites + the conformance run
# Conformance.run/2 → {:ok, N} (N=61), additive-minor: prior 59 byte-unchanged + git-verified, both pins re-pinned
```

**The determinism posture (honest to the ruled mechanism — NOT both):**
- **IF the rotation is a process/lease surface** (Arm 1's `@gclaim` edit touches the lease/claim path on the
  fairness-critical claim; or any arm that mints an id / starts a process): the **≥100 determinism loop owns the
  proof**, run **FOREGROUND** in timeout-bounded chunks driven to an accumulated count (emq.4.3 L-2 — a
  background loop gets reaped; ~`for i in $(seq 1 N); do TMPDIR=/tmp mix test --include valkey || break; done`
  in chunks under the 600s cap). The loop must OWN the machine (no concurrent liveness server / sibling heavy I/O).
- **IF the rotation is a pure additive script** (Arm 2 — a new `@gwclaim` that mints no id and starts no process,
  only touches the server clock like the shipped `@gclaim`): a **multi-seed sweep + an explicit honest
  determinism-posture statement** is the bound (the emq.4.1/4.2 posture — running the ≥100 loop would forge load
  the rung did not introduce).

**Byte-freeze grep (R4):** `git diff HEAD -- lib/echo_mq/lanes.ex | grep 'redis.call'` over the FROZEN set = 0
(every `@g*` except the ruled target). **FROZEN-WIRE:** `echo_wire/lib` untouched unless Arm 1 steps `@wire_version`.

---

## 6 · The short comprehensive prompt (no decision left open the body has fixed — except Fork B)

> Build, inside `echo/apps/echo_mq`, weighted/deficit rotation over the fair-lanes ring + the starvation drill,
> to the ruled Fork B arm (the Operator's call — the weight representation + the rotation mechanism are pinned at
> the ruling; build the rest now). Re-probe the floor at Stage-0 (the `@gclaim` :37-61 byte-anchor, the 8-script
> `@g*` family, the 59 conformance count + both pins, the `gweight` g-segment-HASH home, the metronome shape).
> A lane carries a weight (a new per-queue g-segment HASH beside `glimit`/`gactive` — an existing SHAPE, no new
> key family, no §6 edit), set on a branded-gated group. The rotation serves serviceable lanes in proportion to
> weight (a higher-weight lane more, NEVER all). The served job's lease is the server clock (`redis.call('TIME')`,
> the `@gclaim` :50-51 pattern). Prove it with the `:valkey` weighted-proportion scenario (two lanes 3:1 → served
> ≈3:1 over a window, lane B > 0 — a POSITIVE proof) and the starvation drill (one lane flooded, others trickling
> → every lane drains — the capstone guarantee, a POSITIVE proof; the no-op-defeater is a FIFO rotation leaving a
> light lane stuck). Register both as conformance scenarios (additive minor: prior 59 byte-unchanged, re-pin 59→61
> in both pins). Byte-freeze every unedited `@g*` (`grep redis.call` = 0; the other seven if `@gclaim` is edited,
> all eight if additive). No numeric per-job priority (weight is per-lane), no new key family, the §6 grammar
> unedited, the two-planes version (`mix.exs` label → 2.4.4; `@wire_version` `echomq:2.4.2` if additive, the
> ruled step if `@gclaim` is edited). Run the per-app gate ladder (TMPDIR=/tmp, Valkey 6390, --include valkey,
> warnings-as-errors) + the determinism posture honest to the ruled arm (the ≥100 FOREGROUND loop if a
> process/lease surface, else a multi-seed sweep + the statement) + honest-row reporting. Apollo is MANDATORY iff
> `@gclaim` is edited. `echo_wire` stays untouched unless Arm 1 steps the wire constant; `apps/echomq` untouched.
> Report the gate results faithfully before going idle (an interim if the loop is mid-run — silence reads as a
> stall).
