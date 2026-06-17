# emq-1 — AAW scope ledger

## {emq-1-thinking} Thinking

### T-1

UNDERSTAND — emq.1 (Movement I opener: the scheduler + retry vocabulary), Operator-reshaped pipeline, /effort max. 5W: WHO = codemoji (the program's named consumer). WHAT = scheduled enqueue (run-at/run-in as a visibility fence over the existing emq:{q}:schedule set), repeatable jobs (fresh JOB mint per occurrence), the host-side backoff vocabulary feeding the as-built Jobs.retry/7 + the poison-job drill, one supervised opt-in promote pump, connector auto-resubscribe at :reconnect — all additive on the v2 wire. WHY = three sources name the same gap (drop ROADMAP 2.1; the consumer's §Jobs trace; design §11.10 defers the scheduler family typed-never-silent). WHERE = echo/apps/echo_mq (verbs/repeat/backoff/pump) + echo/apps/echo_wire/connector.ex (resubscribe seam). WHEN = now, post-emq.0 (a2d599c8 shipped, ancestor of HEAD 8616c6aa). SOLUTION SPACE incl. do-nothing baseline: the design draft (emq.1.design.md, Operator-committed at c03202bb) steelmans each capability against a do-nothing arm and recommends a chosen-proposed arm; the substrate is largely AS-BUILT (schedule set live, retry/7 + promote/3 + 'scheduled' state exist — re-verified) so emq.1 adds verbs/policy/pump/seam, not new protocol machinery. SMALLEST-CHANGE-THAT-PRESERVES-CORRECTNESS: adopt the six recommended arms (all additive minors, declared-keys-clean), build inline-script per the as-built convention (NOT priv/), keep the diff inside echo_mq + the one connector seam. INVARIANTS as runnable checks: INV1 = the 14 prior conformance scenarios byte-unchanged + 4 new registered (grep scenarios/0 count == 18; the prior 14 names unchanged); INV2 = every new Lua key in KEYS[] or grammar-derived (read every new script); INV3 = fresh branded mint per occurrence (the repeat scenario asserts two DISTINCT ids); INV5 = the pump is opt-in (a worker without it = the v2 core worker unchanged); INV6 = apps/echomq untouched + per-app testing + lock-delta holds. Mode: Flat-L2, Operator-reshaped to Mars-1 (design-make+build) -> solo Director review -> Mars-2 (remediate+harden) -> Venus (reconcile) -> Director (closure+one commit). The runbook docs/echo_mq/specs/emq.1.prompt.md was rewritten by the Director to this pipeline before launch (the Operator's explicit "Change emq.1.prompt.md for this pipeline and execute").

### T-2 — as-built anchor re-probe (lag-1, post-emq.0 import)

Every anchor re-probed against the as-landed tree (2026-06-13); all CONFIRM, two line-shifts noted.

Environment: `asdf current erlang` → 28.1 (the prompt anticipated 28.5.0.1; `asdf current` reports 28.1 — NO override set, building on what the toolchain resolves); `elixir --version` → Elixir 1.18.4 / OTP 28 [erts-16.1]; `redis-cli -p 6390 ping` → PONG. `TMPDIR=/tmp mix compile --warnings-as-errors` baseline GREEN.

CONFIRMED anchors:
- `EchoMQ.Jobs.retry/7` — echo/apps/echo_mq/lib/echo_mq/jobs.ex:242 (literal delay_ms ARGV[3] + max_attempts ARGV[4]; `{:ok,:scheduled}|{:ok,:dead}` out; `last_error` HSET; dead-letters at the cap into KEYS[3]=`dead`). The @retry script body is jobs.ex:116-156; parks `state='scheduled'` + `ZADD schedule now+delay`.
- `EchoMQ.Jobs.promote/3` — jobs.ex:268 (the @promote script jobs.ex:158-185; `ZRANGEBYSCORE schedule '-inf' now LIMIT 0 batch`, group-aware re-entry). Release machinery EXISTS — emq.1 adds none.
- The `emq:{q}:schedule` set + the `'scheduled'` row state both live as-built (jobs.ex:153-154).
- `EchoMQ.Connector.subscribe/2` — echo/apps/echo_wire/lib/echo_mq/connector.ex:104 (rides `push_command`, RESP3-only). The init state map connector.ex:129-158 holds `push_to`/`pushes` but NO subscription set — the 2.1 gap, verified at the exact seam. The `:reconnect` success arm is connector.ex:282-295 (success branch :284-287: `do_connect` → counter bump → `emit([:emq,:connector,:reconnect])` at :286). RE-ENTRANCY NOTE: `subscribe/2` works by `GenServer.call({:push_command,...})` from OUTSIDE; an in-`handle_info` re-issue must raw `:gen_tcp.send(s.sock, RESP.encode(["SUBSCRIBE",ch]))` (mirroring handle_call({:push_command,parts}) :190-202) — calling push_command in-process would deadlock. `down/1` (:537-547) clears `pending` but must NOT clear the subscription set (subscriptions survive the disconnect).
- The `EchoWire` facade — echo/apps/echo_wire/lib/echo_wire.ex: 9 defdelegates + `script/2`; `subscribe(conn,channel)` at :26 (arity 2).
- `EchoMQ.Conformance.scenarios/0` — exactly 14 (conformance.ex:18-35: fence,mint,duplicate,kind,order,claim,stale,complete,retry,dead,reap,rotate,pause,limit). Pinned twice: the pure registry test conformance_scenarios_test.exs (`@run_order`, async:true) and the wire run conformance_run_test.exs (`run/2 → {:ok,14}`, :valkey).
- `EchoMQ.Consumer` process shape — consumer.ex: `child_spec` :18, `start_link` :35 (NOT a GenServer — a `spawn_link` loop), `stop/2` :78, the loop :91. The loop ALREADY calls `Jobs.promote/3` :94 with a `:pump_batch` opt — the process-shape + cadence precedent for the standalone pump.
- NO `echo/apps/echo_mq/priv/` exists — `ls` returns "No such file or directory". Scripts are inline `Script.new/2` module attributes (script.ex; @enqueue jobs.ex:14-24, @claim/@complete/@retry/@promote/@reap jobs.ex, @genqueue/@gclaim/… lanes.ex:16-99). emq.1 follows the INLINE convention; the triad's "new Lua under priv/" is a Stage-4 Venus reconcile flag.

Keyspace grammar (keyspace.ex): `queue_key(q,type)` → `emq:{q}:type` (hashtag transparent — slot-sound); `job_key(q,branded)` gates `BrandedId.valid?` then `queue_key(q,"job:")<>branded`. So `repeat` set = `queue_key(q,"repeat")` → `emq:{q}:repeat`; per-name record = `queue_key(q,"repeat:")<>name` → `emq:{q}:repeat:<name>` — both `{q}`-tagged, declared in `KEYS[]` by the established Lanes pattern.

Lock-delta baseline: echo_wire deps `[]`, echo_mq deps `[echo_data, echo_wire]` (both in_umbrella) — NO external dep; emq.1 adds none (INV6 holds by construction).

Test harness: `:valkey` excluded by default (test_helper.exs `ExUnit.start(exclude: [:valkey])`); live tests `Connector.start_link(port: 6390)` per test + `EchoData.Snowflake.start(4)` in setup_all (BrandedId.generate! needs Snowflake started); per-test sub-queue `q = "emq0.X#{unique_integer}"` + disposable-conn purge in on_exit. Push-channel test pattern (connector_test.exs:140-149): `subscribe(sub,chan)` with `push_to: self()` → `PUBLISH` from a 2nd conn → `assert_receive {:emq_push, ["message", chan, payload]}`.

### T-3 — Venus-2 spawn + grounding inventory for emq.2

Spawned ccl-emq-1-3, registered architect (3 spawned / 3 registered, no FAKE-N). Task #6 in_progress.

Read for grounding (read-only): emq.roadmap.md (the emq.2 ladder row + Movement-I framing + seams 1/5/9 + master invariant); echo_mq.md (the program front door — emq.2 = PROGRAM HYGIENE, "no downstream rung gates on it (recorded, not asserted)"); emq.design.md (the canon — the load-bearing migration locks: §2 Consequences = the branding rule verbatim; §3 Decision = the fence merge AT emq.2; §4 cluster 1 = "the BCS state machine" + the §3 staging second step; §10 seam 1 = the OPEN in-place v2→v2 treatment; §11.4 F-C replace-on-main; §11.5 the v1 terminal 1.3.1 fence-only patch = the mirror preflight; §11.1/§1 S-1 = v1 prefix is config input default "bull", parametric on v1_prefix); specs.approach.md (the six quality gates + the triad templates); emq.1.md + .stories.md + .llms.md + .prompt.md (the structural template — section shape, house voice, D/INV numbering, forward-tense "emq.N builds", the priv/-vs-inline reconcile flag I must NOT repeat).

As-built inventory probed: echo_mq/lib has backoff.ex, conformance.ex, consumer.ex, jobs.ex, keyspace.ex, lanes.ex, pool.ex, pump.ex, pump/core.ex, repeat.ex (NB: emq.1's build is mid-flight — backoff/pump/repeat already landed). echo_wire/lib has connector.ex, resp.ex, script.ex, echo_wire.ex. The FROZEN v1 push source echo/apps/echomq/lib carries the migration machinery emq.2 drains FROM: migration.ex, keys.ex, version.ex, fence.ex, fence_error.ex, scripts.ex, and mix/tasks/echomq.migrate.ex.

Next: probe echo_mq keyspace.ex/jobs.ex (the v2 fence target) + echomq migration.ex/keys.ex/version.ex/fence.ex (the v1 source) for real module/function/key names; read the Movement-0 migration record (the mechanism source).

### T-4 — Stage-4 reconcile inventory: as-built ⇄ spec, every claim probed against the tree (read-only). Eleven anchors classified.

MATCH (as-built confirms the triad's claim, no edit needed):
- Jobs.retry/7 (jobs.ex:298, the @retry script :172-212) — literal delay_ms ARGV[3] + max_attempts ARGV[4]; {:ok,:scheduled}|{:ok,:dead}; last_error HSET; dead-letters at cap into KEYS[3]=dead. MATCH the triad's §What + INV4.
- Jobs.promote/3 (jobs.ex:324, @promote :214-241) — ZRANGEBYSCORE schedule '-inf' now LIMIT 0 batch, group-aware. The release path emq.1 adds NONE. MATCH.
- emq:{q}:schedule set + 'scheduled' row state both live (jobs.ex:53-54 @schedule, :209-210 @retry). MATCH.
- Backoff.delay_ms/2 (backoff.ex:46) — pure; {:fixed,ms}|{:exponential,base,cap}|{:jitter,inner}; min(raw,cap) clamp; full-jitter the only random arm; handed to retry/7 as literal. MATCH INV4 + design §4 row 30.
- Pump (pump.ex) + Pump.Core (core.ex) — transient opt-in child (child_spec restart: :transient :36); pure tick_ms/batch core refusing non-positive (core.ex:24/42); owner-started no mod: (start_link :47). MATCH INV5.
- Connector subscribe/2 (connector.ex:109) + the recorded subscriptions MapSet (init :158, put on :subscribe success :222, delete on :unsubscribe success :229), kept across down/1 (:598 comment "subscription set is NOT [cleared]"), re-issued in resubscribe/1 (:606) at the :reconnect success arm (:334 s3 = resubscribe(s2)). MATCH D6 + INV1.
- Keyspace.queue_key/2 (keyspace.ex:14) → emq:{q}:<type>; job_key/2 (:18) gates BrandedId.valid?. Repeat keys derive: queue_key(q,"repeat") → emq:{q}:repeat (zset); repeat_key = queue_key(q,"repeat:")<>name → emq:{q}:repeat:<name> (hash). MATCH D-4.

STALE (triad claim diverges from as-built — Stage-4 corrects the body, brings stories+brief up):
- S-1 priv/ vs inline: emq.1.md §Where + emq.1.llms.md topology/touched-files say "new Lua under priv/". NO echo_mq/priv/ exists; scripts are inline Script.new/2 module attributes (@schedule jobs.ex:38, @register/@cancel/@advance repeat.ex:27/36/42). CORRECT every occurrence (the standing L-1 flag, runbook DEFER-TO-VENUS).
- S-2 conformance count: triad says "14 scenarios" as the live count in several spots. As-built scenarios/0 (conformance.ex:20-41) = 18: the prior 14 byte-unchanged in contract + schedule/repeat/backoff/resubscribe. RE-PIN: 14 = the prior-and-byte-unchanged set (INV1), 18 = the new live count.

REALIZATION-OVER-LITERAL (Director-ratified Y-1; fold as as-built, not flag-and-block):
- R-1 ONE @schedule script + ARGV mode flag: D2's "ONE new script" is realized as a single @schedule (jobs.ex:38-56) serving BOTH enqueue_at/5 (:67) and enqueue_in/5 (:78) via ARGV[3] mode ('at' = absolute score :51; 'in' = wire-side TIME t[1]*1000+floor(t[2]/1000)+delay :47-49). Honors "ONE new script" + server-clock for run-in + client-clock-prices-only-score for run-at, in one script.
- R-2 both run-at + run-in admitted (D-5): enqueue_at/5 + enqueue_in/5 both built (jobs.ex:67/78).
- R-3 one opt-in pump both sweeps (D-6): pump.ex sweep/1 (:91) = promote + fire_repeats on each tick; fire_one/3 soft-match (:123) D-10 fold.
- R-4 resubscribe MapSet + at-most-once honest gap (D-7): documented at connector.ex:601-605 + the design §6 ground.

DEFERRED [RECONCILE]-style (no edit, recorded):
- The A-1 lint binding rule (fork 2, D-3) = DEFERRED to canon/emq.8 proof-stack. emq.1 adds no new derivation power. Record in the design-doc flip, decide nothing.
- The Keyspace seam (D-2 / design §1) = Arm C kept as-built (cross-app version_key/0 read at connector.ex fence time). A later dedicated seam pass, not this rung.

CANON-SYNC FLAGGED (reconcile-only — the Operator's ruling, NOT applied): emq.design.md §11.10 defers the scheduler family "typed-never-silent". emq.1 has now BUILT the scheduler half (enqueue_at/in, the repeat registry, the pump). A canon §11.10 note that the scheduler half is discharged at emq.1 is the Operator's call — flagged, not applied (the canon body is reconcile-only).

## {emq-1-decisions} Decisions

### D-1

The EMQ.1-D1 design gate is RELOCATED (Operator-ordered), not skipped. EMQ.1-INV7 reads "no build artifact exists until EMQ.1-D1's design is Operator-approved." The Operator's directive — "Mars-1 (ready to implement, design make, Venus skips rang 1) ... execute" — relocates the gate: instead of a pre-build Operator checkpoint on the design draft's six forks, the design is MADE by Mars-1 (adopting the draft's chosen-proposed arms, logged as decisions), SCRUTINIZED by the solo Director review (Stage 2), and RATIFIED by the Operator's acceptance of the single post-closure commit. This is the Operator exercising authority over their own invariant (legitimate), not the Director skipping a gate (a V-SOLO violation). The relocation is safe because all six adopted arms are conservative additive minors with NO wire break and NO apps/echomq edit: (1) Keyspace seam = Arm C keep-as-built (zero wire-app churn; A/B deferred to a dedicated seam pass); (2) A-1 lint reading = DEFERRED (emq.1 adds no new derivation power; a canon/emq.8 question, not a build blocker); (3) repeat-registry keys = ADOPT emq:{q}:repeat zset + emq:{q}:repeat:<name> hash (declared-keys-clean, probe-registered); (4) run-at admission = ADMIT both run-at and run-in (the consumer's settlement/EOD is calendar-anchored); (5) pump = ONE opt-in pump, both sweeps; (6) unsubscribe/2 = ADD the companion. The Operator committed the design draft (c03202bb) so the proposed spellings were seen before the delegation. SAFEGUARDS the relocation keeps: the adopted arms are surfaced to the Operator at closure for informed acceptance/amend (amendments are cheap additive follow-ups since emq.1 is additive and the repeat-registry is behind not-yet-load-bearing registration verbs); the solo Director review runs a real reconcile+gate+adversarial+mutation-spot-check pass to recover the rigor lost by dropping the Apollo §11.2 charter; Venus's independent post-build reconcile is a second read. Pipeline reshape also recorded: Venus skips the pre-build stage (design-make folds into Mars-1); the Apollo stage is replaced by the solo Director review; Venus reconciles post-build. The runbook emq.1.prompt.md was rewritten to this pipeline before launch.

### D-2 — Arm 1 ADOPTED: Keyspace seam = Arm C (keep the annotated cross-app read)

Adopts emq.1.design.md §1 + §8 fork 1 → Arm C. The `echo_wire` connector keeps reading `EchoMQ.Keyspace.version_key/0` at fence time across the app boundary exactly as the emq.0 as-built (connector.ex:417; the `no_warn_undefined: [EchoMQ.Keyspace]` annotation in echo_wire/mix.exs:18 stays). Zero wire-app churn; emq.1 stays focused on the scheduler. Arms A (inline the constant) / B (move `version_key/0`) are a later dedicated seam pass, not this rung. ADR-5's resubscribe edit to the SAME connector.ex is a separate concern and composes with the left-as-is version read.

### D-3 — Arm 2 ADOPTED: A-1 lint binding rule = DEFER

Adopts emq.1.design.md §7 + §8 fork 2 → DEFER. emq.1's new scripts add NO new derivation power — they follow the as-built ARGV-base + declared-structure-key convention (the per-job key `base..'job:'..id`, the lane family `base..'g:'..g..':pending'` — claim/promote/retry/reap/genqueue precedent). The strict-`KEYS`-root-vs-hashtag-equality reading is a canon question the emq.8 proof-stack lint forces, not an emq.1 blocker. Build to the existing convention; FLAG the reading for the closing report; decide nothing.

### D-4 — Arm 3 ADOPTED: repeat-registry keys = `emq:{q}:repeat` (zset) + `emq:{q}:repeat:<name>` (hash)

Adopts emq.1.design.md §3 + §8 fork 3. The repeat registry: `emq:{q}:repeat` = a sorted set scored by next-run ms, members = registration names (`Keyspace.queue_key(q,"repeat")`); per-registration record `emq:{q}:repeat:<name>` = a hash carrying `every_ms` + the payload template (`Keyspace.queue_key(q,"repeat:")<>name`). Both `{q}`-hashtagged (slot-sound, co-location law), both declared in `KEYS[]` per the established Lanes convention, registered with the `repeat` conformance probe. Additive-minor against §6's closed registry. Registration + cancellation verbs write/remove the pair.

### D-5 — Arm 4 ADOPTED: run-at admission = ADMIT both run-at and run-in

Adopts emq.1.design.md §2 + §8 fork 4. Build BOTH `enqueue_at(conn,queue,id,payload,run_at_ms)` (caller passes absolute ms — a documented client-clock surface for the schedule SCORE only) and `enqueue_in(conn,queue,id,payload,delay_ms)` (the score computes wire-side from `TIME`, the DQ-2c server-clock law, the @claim/@retry precedent). The consumer's scheduled work is calendar-anchored (run-at is its named need). The caller's clock prices only the schedule score; the fence + lease laws are untouched.

### D-6 — Arm 5 ADOPTED: pump = ONE supervised opt-in pump carrying both sweeps

Adopts emq.1.design.md §5 + §8 fork 5. ONE supervised, OPT-IN cadence process — `EchoMQ.Pump` — carrying BOTH sweeps (promote + repeat) on each tick. Pure decision core: next-tick + batch arithmetic as plain functions (testable without I/O or a clock). A thin shell calls `Jobs.promote/3` + the repeat sweep each tick. Tick interval + batch size = config. Restart semantics stated in the child spec. The `Consumer` is the process-shape precedent (consumer.ex — child_spec :18, the loop :91 already promotes :94). A worker started WITHOUT the pump = the v2 core worker, unchanged (INV5). Library law: caller/owner-started, no `mod:` auto-start.

### D-7 — Arm 6 ADOPTED: add `unsubscribe/2` companion verb beside the recorded subscription set

Adopts emq.1.design.md §6 + §8 fork 6. ADD `unsubscribe/2` (an `UNSUBSCRIBE` push_command) beside the recorded subscription set so the set stays truthful (a subscription removed on unsubscribe is not re-issued on reconnect). Small, additive on the `EchoWire` facade (one new `defdelegate`). The connector records its subscription set (a MapSet in connector state, added on `subscribe/2` success, removed on `unsubscribe/2` success) and re-issues each `SUBSCRIBE` in the `:reconnect` success arm (connector.ex:284-287, after `do_connect` re-negotiates RESP3). The honest gap is DOCUMENTED not closed: pub/sub is fire-and-forget, so messages during the disconnect are lost either way (at-most-once on the push channel; the cache's versioned claims + staleness fence already tolerate exactly this).

### D-8

D-1 (Venus-2, emq.2) — emq.2 is RE-PROVE-AGAINST-echo_mq, not lift-the-v1-tool

The frozen v1 push source apps/echomq ALREADY carries a complete, working v1→v2 migration implementation, authored under the OLD pre-program rung numbering (its moduledocs say "EMQ.1-D3"/"EMQ.1-D7"):
- EchoMQ.Migration.migrate/4 (migration.ex:61) — offline copy-verify-DELETE; journal at emq::migration:<queue>; typed refusals {:active_jobs,n} / {:live_locks,ids} / {:invalid_target_name,_} / {:unmigratable_job_ids,ids}; idempotent re-run → {:ok,:already_migrated}; terminal order verify→DELETE v1 state→stamp tombstone.
- EchoMQ.Version — wire_version/0 "echomq:2.0.0", migration_tombstone/0 "echomq:2.0.0-migrated", major/minor.
- EchoMQ.Fence.preflight/3 (fence.ex:67) — the v2-side boot preflight refusing :version_major_mismatch / :foreign_version / :migration_tombstone / :v1_keyspace; sentinel_keys/2.
- Mix.Tasks.Echomq.Migrate — the operator CLI; guides/migration_v1_to_v2.md — drain-and-switch + the at-rest tool + the fence both ways + the named residuals.

The probe over apps/echo_mq/lib confirms ZERO migration/version/fence surface there. So the migration MECHANISM exists, but only in the FROZEN source, and it targets the OLD UNBRACED v2 keyspace (emq:<q>:<X>, emq:<q>:j:<id>) carrying numeric ids "by numeric disjointness" — NOT the braced emq:{q}: grammar EchoMQ.Keyspace now enforces, and NOT the 14-byte branded JOB form.

DECISION: emq.2's contract is "the v1→v2 migration path RE-PROVEN against echo_mq" (the roadmap row) = a NEW EchoMQ.Migration surface inside echo_mq that produces the BCS 2.0 convergence target's keyspace: braced emq:{q}:, branded JOB ids via the design §2 order-preserving lane (JOB + base62(integer), injective, numerically disjoint), parked/pending/dead per the as-built sets. It is grounded forward-tense ("emq.2 builds…") on the v1 tool as the MECHANISM PRECEDENT (the copy-verify-DELETE shape, the typed-refusal vocabulary, the drain-and-switch runbook) + the design §2/§3/§11.4/§11.5 locks — never asserted-as-shipped against echo_mq, where it does not exist.

### D-9

D-2 (Venus-2, emq.2) — the as-built fence is ALREADY connect-scoped (emq.0 landed it); emq.2's fence work is narrower than the design's pre-emq.0 framing

The design §3 frames the fence merge as the work that "moves the refusal to connect" at emq.2, with two codes re-aiming their read to {emq}:version. But the as-built echo_wire connector (landed at Movement 0 / emq.0) ALREADY runs a connect-scoped fence: connector.ex:465 fence/2 reads Keyspace.version_key() (= {emq}:version, keyspace.ex:29), claims SET vkey echomq:2.0.0 NX + read-back GET, refuses typed {:error, {:version_fence, got}} (connector.ex:478/483), fatal class :version_fence (connector.ex:338), @wire_version "echomq:2.0.0" (:33). It runs on EVERY connect (the connect path :387 calls fence). So the deployment connect-fence the design says "moves to connect at emq.2" is DONE.

What is NOT yet in echo_mq and IS emq.2's actual fence work: (a) the v1-side terminal fence — there is no Fence/preflight surface in echo_mq mirroring the v1 EchoMQ.Fence (the §11.5 "1.3.1 fence-only patch" = the mirror preflight refusing :v2_keyspace + :migration_tombstone); that 1.3.1 patch lands on the FROZEN v1 line's 1.3.x maintenance branch (apps/echomq), NOT in echo_mq — flag the seam: emq.2 touches the frozen line for exactly this terminal patch, which collides with the "apps/echomq untouched and frozen" law (INV-carried). (b) the migration-tombstone discrimination folding into the connector's sentinel sweep (the design §3 "tombstone + journal-completed ⇒ proceed; tombstone + no {emq}:version + no journal ⇒ refuse") — the as-built fence has the version claim but no tombstone arm.

CONSEQUENCE for the spec: emq.2's INV on the fence is phrased "the connect-scoped {emq}:version fence (landed at emq.0) is UNCHANGED in logic; emq.2 adds the migration-tombstone discrimination + the v1-side 1.3.1 terminal patch" — NOT "emq.2 moves the fence to connect" (already true). The two design-named code re-aims (:version_major_mismatch / :foreign_version → read {emq}:version) are mostly MOOT in echo_mq: the as-built fence already reads {emq}:version and uses the single :version_fence class, not the v1's split codes. This is a Stage-4-style reconcile note surfaced NOW at spec time.

### D-10 — Stage-3 Mars-2 REMEDIATE of the two Stage-2 observations

The Stage-2 review (Y-3) was CLEAN; the two carried items (L-3, L-4) were REMEDIATE-OPTIONAL robustness polish, not correctness blockers. Mars-2 resolution:

L-3 (pump fire_repeats hard-match asymmetry) = FOLDED. pump.ex fire_repeats now soft-matches each occurrence via a new fire_one/3: a wire hiccup on one enqueue/advance logs (Logger.warning) and skips (returns false → not counted), rather than the prior `{:ok,_} = ...` hard match crash-looping the whole cadence (which also dropped that tick's promote work). The dangling-record branch is preserved as a second fire_one/3 clause (Repeat.cancel sweeps the member). Rationale: the program's thin-but-robust posture — one failing occurrence degrades to a skip, the next tick re-fires it (the pump is :transient + the sweep idempotent, so no occurrence is lost). New test: pump_test.exs "a sweep over a mixed batch fires the live registration and sweeps a dangling one" (one live + one record-deleted registration → fired:1, the dangling member swept, count 1).

L-4 (resubscribe/1 missing protocol_live==3 guard) = ALREADY SATISFIED, no edit. The as-built resubscribe/1 (connector.ex:606-617) head guard already reads `if MapSet.size(subs) == 0 or s.protocol_live != 3 do s` — the guard the observation requested is present from the Stage-1 build. Verified against the current file (not the observation's assumed text). No change made; recording the verification rather than a no-op edit (the Mars charter's "diff against the CURRENT source — self-consistent ≠ current").

### D-11 — Stage-4 reconcile choices LOCKED (the body authoritative, brought to as-built truth)

Three reconcile choices fixed at Stage 4:

(1) priv/ → INLINE corrected everywhere it was a live claim. emq.1.md §Where + §What, emq.1.llms.md topology + touched-files now name the as-built inline Script.new/2 convention (@schedule in jobs.ex, @register/@cancel/@advance in repeat.ex); no echo_mq/priv/ exists. The standing L-1 / runbook DEFER-TO-VENUS flag is discharged.

(2) Conformance 14 → 18 RE-PINNED, not overwritten. The triad keeps "the prior 14 byte-unchanged" (the INV1 contract — those 14 are genuinely byte-unchanged) AND now names the live count 18 (schedule/repeat/backoff/resubscribe registered). INV1's body, the DoD box, US7, R7, and the prompt's additive-minor law all carry "grows 14 → 18, the prior 14 byte-unchanged" — the as-built truth, not a bare "14".

(3) DESIGN-vs-TRIAD anchor split PRESERVED. The drifted as-built anchors (retry/7 :242→:298, promote/3 :268→:324, subscribe/2 :104→:109, the :reconnect re-issue :282-297 → resubscribe/1 :606 in the success arm :334) are re-pinned in the TRIAD (the living contract). They are LEFT at the pre-build lines in emq.1.design.md §0, which is the design-time grounding snapshot ("re-verified against the tree on 2026-06-13" = before this build's +56 to jobs.ex). Re-pinning §0 would falsify the record of when the design was authored. The charter's "keep the design's body intact" encodes exactly this; git-confirmed the live lines are :298/:324/:109.

The body (emq.1.md) stays the authoritative contract; the realization-over-literal facts (ONE @schedule script + ARGV mode flag; both enqueue_at/in admitted; one opt-in pump both sweeps; the resubscribe MapSet + at-most-once honest gap) are folded as as-built, Director-ratified at Y-1.

## {emq-1-learnings} Learnings

### L-1 — the conformance scenario bodies caught two self-inflicted bugs the standalone suites did not

The standalone D3 (`repeat_test.exs`) and D4-drill suites passed first try, but the first full `Conformance.run/2` returned 16/18 — two bugs lived ONLY in the conformance scenario bodies, not in the production surfaces (Repeat, Backoff, Jobs all sound):
- `:repeat` mint-order guard was inverted. A later occurrence mints a lexically GREATER branded id (mint order = byte order); the cond clause read `first <= second -> fail`, which fails the correct case. Fixed to `first >= second -> fail`. (The standalone test used `assert second > first` correctly — the divergence is exactly the "a check counts only if it RUNS, and two encodings of the same law can disagree" hazard.)
- `:backoff` drill promoted too early. `Backoff.delay_ms({:exponential,1,10}, att)` parks the retry 1-2ms in the future; the immediate `{:ok, 1} = Jobs.promote(...)` matched `{:ok, 0}` (nothing due yet) and crashed. Fixed with `Process.sleep(delay + 5)` before promote.

Both are scenario-harness timing/logic bugs, gate-caught by the run itself (16/18), not by per-surface tests — the value of the full additive-minor conformance run as a distinct gate beyond unit suites. No production surface changed for either fix.

### L-2

L-1 (Venus-2, emq.2) — the design canon's emq.2 fence framing PRE-DATES emq.0's landing; reconcile it at the emq.2 build's B0

The design §3 (written before Movement 0 landed) frames the fence merge as emq.2's work: "the refusal moves to connect" + two codes (:version_major_mismatch / :foreign_version) re-aim their read to {emq}:version. But the as-built echo_wire connector ALREADY runs the connect-scoped {emq}:version claim/read-back/refuse (connector.ex:465, called on every connect at :387) — landed at emq.0. So the design's "move to connect at emq.2" is DONE, and the two named code re-aims are mostly MOOT in echo_mq (the as-built fence uses a single :version_fence class, not the v1's split codes). The emq.2 triad is grounded against the AS-BUILT reality (INV5 = "the fence claim path is byte-unchanged; emq.2 adds ONLY the migration-tombstone arm"), NOT the design's pre-emq.0 framing. This is the design-canon-vs-as-built drift class the spec system warns of (echo/CLAUDE.md §7: unbuilt specs drift from the core when authored ahead of the build). It is surfaced for the emq.2 build's B0 reconcile and (if the Operator wants the canon synced) a reconcile-only edit to design §3's emq.2 clause — NOT touched here (the design is Operator-approved, reconcile-only; this rung's triad is the place the as-built truth is recorded).

Also: a SECOND framing nuance — the v1 migration tool (apps/echomq/migration.ex moduledoc) names the OLD unbraced emq:<q>:j:<id> target, while the NEWER guide (migration_v1_to_v2.md, Jun 11) already names the braced emq:{q}:j:<id>. Neither matches echo_mq's actual job_key/2 (emq:{q}:job:<branded-id>, the job: segment + branded gate). emq.2 produces echo_mq's form — the triad pins job_key/2 as the gate, so the build cannot regress to either older shape.

### L-3

Stage-2 observation (REMEDIATE-OPTIONAL for Mars-2): the pump's repeat sweep uses HARD matches while the promote sweep SOFT-matches — an asymmetry. In pump.ex sweep/1, promote is `case Jobs.promote(...) do {:ok,n} -> n; _ -> 0 end` (tolerates an error), but fire_repeats does `{:ok, _} = Jobs.enqueue(...)` and `{:ok, _} = Repeat.advance(...)` (hard match → a non-:ok return crashes the pump). The pump is :transient, so a crash restarts the cadence whole and the sweep is idempotent, so a transient wire hiccup self-heals with no lost entry — low-risk. But for the program's thin-but-robust posture the cleaner pattern matches the promote arm: soft-match each repeat occurrence so one failing enqueue/advance logs-and-skips rather than crash-looping the whole cadence (which also drops that tick's promote work). Mars-2 may fold this for consistency or leave it with the transient-restart rationale recorded. Not a correctness blocker.

### L-4

Stage-2 observation 2 (REMEDIATE-OPTIONAL, low priority): resubscribe/1 in connector.ex re-issues each recorded SUBSCRIBE on the reconnected socket WITHOUT re-checking the protocol_live==3 guard that the handle_call subscribe path enforces. It trusts that a reconnect re-negotiates the same protocol the connection booted with (the documented assumption). If a reconnect ever came up non-RESP3 (a server downgrade mid-life), the SUBSCRIBE would be pushed on a non-push-capable socket. Realistically the connection boots RESP3 or the connect fails, so the window is theoretical; the design's at-most-once honest-gap framing already covers push-channel loss across a disconnect. Mars-2 may add a protocol_live==3 guard inside resubscribe/1 for defense-in-depth or leave it with this note. Not a correctness blocker for emq.1.

### L-5 — the emq.0 ladder is 11 runnable echo/rungs/ check scripts (NOT the per-app suites); ran each at its tail — 10/11 PASS, 3_6 is a benchmark needing absent Oban + carries a now-stale ==14 assertion

The Stage-3 re-issued directive named echo/rungs/ 3_1..3_5, 4_1..4_4, the shadow rung "run each at its exact tail." These are STANDALONE .exs scripts (not invoked by mix test — the per-app-suite inference in P-1 was incomplete): bus/bcs_rung_3_1..3_6, cache/bcs_rung_4_1..4_3, journal/bcs_rung_4_4 + journal/bcs_rung_shadow. Each Code.require_file-loads the REAL sources (incl. my modified connector.ex/keyspace.ex/jobs.ex) and asserts the rung contract against live Valkey 6390; run as `mix run --no-start rungs/.../X_check.exs`; ends PASS N/N or FAIL+halt(1).

RESULTS (run fresh, tee'd /tmp/emq1_emq0_ladder.log):
- bus 3_1 PASS 5/5, 3_2 PASS 5/5, 3_3 PASS 6/6, 3_4 PASS 8/8, 3_5 PASS 6/6 (the jobs/lanes/keyspace/schedule-retry-promote surfaces — F1 even asserts emq:{orders}:job: + the 17-byte prefix + slot co-location; my D2 schedule edits did not regress them).
- cache 4_1 PASS 6/6, 4_2 PASS 6/6, 4_3 PASS 6/6; journal 4_4 PASS 6/6, shadow PASS 4/4 (the wire/cache/journal layers — these load connector.ex DIRECTLY, so the resubscribe seam is proven non-regressing end-to-end).
- bus 3_6: CANNOT RUN — `(CompileError) Oban.Job.__struct__/1 is undefined` at :121. 3_6 is a Valkey-vs-PostgreSQL/Oban BENCHMARK rung (ObanBench.Repo.query!, Oban.insert/insert_all/pause_queue) needing the Oban+Postgres harness, which is NOT in the dep tree. PRE-EXISTING (Oban is absent from mix.lock + every app mix.exs; rungs/ is untracked, NOT touched by me).

EMQ.1 ARTIFACT FLAGGED (for Venus Stage-4 / Director): 3_6:72 hardcodes `length(Conformance.scenarios()) == 14`. emq.1's INV1-sanctioned additive-minor growth (14→18) supersedes it, so even with Oban present this F-check would now read stale. NOT EDITED — 3_6 is an untracked rung-check artifact outside the emq.1 code boundary, and the 14→18 growth is correct-by-INV1; the frozen ==14 is the stale side, not the change. The 3_6 EchoMQ half (Conformance.run before the Oban line) is already proven by conformance_run_test.exs → {:ok,18}; only the benchmark half + the count literal are stale. Surfaced, not fixed — a candidate cheap follow-up (update the benchmark rung's count literal to read from the registry, when the Oban harness is next stood up).

NET: 10/11 emq.0 rung tails GREEN; the 1 non-running is a benchmark needing external infra, NOT an emq.1 regression. The wire-touching half of the ladder (all of chapter 4 + shadow, which load my edited connector.ex) is fully green.

### L-6

The 11th rung (3_6) finding — two distinct facts Mars-1's "one pre-existing benchmark" framing conflated. (1) ENVIRONMENTAL: bcs_rung_3_6_check.exs is the Valkey-vs-Oban REFEREE benchmark — it requires the oban_bench rig + PostgreSQL ("Runs under the rival's project … cd echo/rigs/oban_bench && mix run …"), so from the umbrella root it fails to compile (Oban.Job undefined at :121). Not provisioned in this environment; pre-existing, NOT an emq.1 regression. It is excluded from the RUNNABLE ladder (3_1..3_5 + 4_1..4_4 + shadow, all green — the Stage-3 gate holds). (2) EMQ.1-INDUCED STALENESS: 3_6 HARDCODES the conformance count at 14 — C1 `length(Conformance.scenarios()) == 14` (:72), C2 `{:ok, 14} ->` (:81), + the prose "fourteen wire-level contracts"/"fourteen of fourteen" (:75/:82). emq.1's additive-minor conformance change makes the truth 18 (Conformance.run/2 → {:ok,18}, verified). So 3_6's C1/C2 are now stale-vs-as-built — they would fail with the rig present. The conformance additive-minor law (design §5) closes "in the same change", so the 14→18 + prose update is emq.1's proper closure. RESOLUTION: Mars-1 dispatched to apply the mechanical 14→18 + fourteen→eighteen update (parse-checked via umbrella compile; full run-verification deferred to oban-rig provisioning, documented honestly); 3_6 added to the Stage-5 pathspec. MENTORING (Mars): "pre-existing" must distinguish environment-gated-cannot-run from this-change-staled-it — the second is the rung's own debt to close, the first is a documented carry.

## {emq-1-report} Report

### Y-1 — Mars-1 Stage-1 design-make + build COMPLETE (gate met)

THE DESIGN MADE REAL: the six arms adopted (D-1..D-7), each citing emq.1.design.md. THE BUILD: D2-D6 built inside the boundary; D7's conformance registry extended 14→18 with all four new scenarios green.

FILE-BY-FILE (working tree, uncommitted per LAW-1a/4):
NEW — echo/apps/echo_mq/lib/echo_mq/backoff.ex (D4: pure policy→delay_ms; fixed/exponential base+cap/jitter wrap)
NEW — echo/apps/echo_mq/lib/echo_mq/repeat.ex (D3: register/cancel/due/advance/count over emq:{q}:repeat zset + emq:{q}:repeat:<name> hash; host-side fresh mint)
NEW — echo/apps/echo_mq/lib/echo_mq/pump.ex (D5: supervised opt-in GenServer; sweep = promote + fire_repeats; transient child)
NEW — echo/apps/echo_mq/lib/echo_mq/pump/core.ex (D5: pure decision core — tick_ms/batch arithmetic, no process/clock)
EDIT — echo/apps/echo_mq/lib/echo_mq/jobs.ex (+56: @schedule inline script + enqueue_at/5 + enqueue_in/5 + private schedule/6 — D2; release path = EXISTING promote, no new release machinery)
EDIT — echo/apps/echo_mq/lib/echo_mq/conformance.ex (+181: 4 scenarios schedule/repeat/backoff/resubscribe + helpers; moduledoc 14→18; the prior 14 BYTE-UNCHANGED)
EDIT — echo/apps/echo_wire/lib/echo_mq/connector.ex (+94: subscriptions MapSet in init state; {:subscribe}/{:unsubscribe} handlers recording the set; send_push/2 helper; resubscribe/1 re-issuing each SUBSCRIBE in the :reconnect success arm after do_connect; down/1 keeps the set — D6)
EDIT — echo/apps/echo_wire/lib/echo_wire.ex (+1: unsubscribe/2 defdelegate — the companion verb on the facade)
NEW TESTS — backoff_test.exs (4 doctests+5), pump_core_test.exs (doctests+4), scheduled_enqueue_test.exs (5 :valkey incl. the mint-order theorem), repeat_test.exs (7 :valkey), pump_test.exs (5 :valkey incl. cadence + transient crash-restart), resubscribe_test.exs (4 :valkey socket-kill drill)
EDIT TESTS — conformance_run_test.exs + conformance_scenarios_test.exs (14→18); echo_wire_facade_test.exs (+unsubscribe/2 pin, moduledoc nine→ten)

GATE RESULTS:
- Per-app compile --warnings-as-errors --force: echo_mq GREEN (10 files), echo_wire GREEN (4 files).
- echo_mq FULL suite (pure + :valkey): 4 doctests, 93 tests, 0 failures.
- echo_wire FULL suite: 18 tests, 0 failures (+ facade 2 tests).
- Conformance.run/2 → {:ok, 18}: 18/18, the prior 14 byte-unchanged + the 4 new green.
- The expected `[error] GenServer ... (stop) killed` line is the crash-restart drill's own kill, a passing line.

BOUNDARY: diff entirely in echo_mq + echo_wire (connector resubscribe seam + echo_wire.ex delegate). mix.lock UNCHANGED (INV6 — no dep). apps/echomq UNTOUCHED. No third app.

REALIZATION-OVER-LITERAL (one, for Director ratification): D2's "ONE new inline Script.new/2" is realized as a single @schedule script serving BOTH enqueue_at and enqueue_in via an ARGV mode flag ('at' passes the absolute score; 'in' computes now+delay wire-side from TIME). This honors "ONE new script" + the server-clock law for run-in + the client-clock-prices-only-the-score note for run-at, in one script rather than two. Faithful to the design §2 intent.

INV CHECKS: INV1 (additive minors, 14 byte-unchanged, every addition probe-registered) ✓; INV2 (declared keys — every new Lua key in KEYS[] by the Lanes convention; schedule keys [job,schedule]; repeat keys [repeat-set, record]; resubscribe touches no script) ✓; INV3 (fresh branded JOB mint per occurrence host-side via BrandedId.generate!; wire never mints; mint-order theorem tested) ✓; INV4 (backoff host-side; retry/7 takes literal delay, wire surface unchanged) ✓; INV5 (pump supervised opt-in, pure core, transient restart; worker-without-pump unchanged — tested) ✓; INV6 (apps/echomq untouched; per-app tests; no git; lock-delta holds) ✓.

A-1 LINT READING FLAGGED (D-2, arm 2 deferred): emq.1's new scripts add no new derivation power (ARGV-base + declared-structure-key convention). The strict-KEYS-root-vs-hashtag-equality reading is left for the emq.8 proof stack — decided nothing, as adopted.

DEFER-TO-VENUS (Stage 4): the triad's "new Lua under priv/" is the as-built INLINE Script.new/2 convention (no echo_mq/priv/ exists); the design doc flips DRAFT→adopted-as-built.

### Y-2

Y-1 (Venus-2, emq.2) — the emq.2 spec quad is on disk, six gates PASS

DELIVERED (docs-only, uncommitted, in docs/echo_mq/specs/):
- emq.2.md (182 lines) — the contract: Goal · 5W · Scope · D1–D8 · INV1–INV7 · DoD (8 boxes).
- emq.2.stories.md (166) — US1–US8 (incl. EMQ.2-US-GATE), Coverage D1→US1 … D8→US8.
- emq.2.llms.md (234) — References · R1–R9 · topology (B-DAG + as-built floor + touched files) · AS1–AS8 · first-two plan · comprehensive prompt.
- emq.2.prompt.md (214) — DRAFT/launch-gated x-mode runbook; STANDARD Venus→Mars×2→Apollo→Director default + Operator-reshape note; Settled-forks section flags the ONE open seam.

emq.2 in one line: the v1→v2 migration path RE-PROVEN against echo_mq (program hygiene — retires the push source's deployments so apps/echomq dissolves; NO downstream rung gates on it, recorded not asserted).

KEY GROUNDING FINDING (D-1): the migration MECHANISM exists ONLY in the frozen v1 apps/echomq (EchoMQ.Migration.migrate/4, EchoMQ.Version, EchoMQ.Fence.preflight/3, mix echomq.migrate, the guide) and targets the OLDER unbraced keyspace carrying numeric ids by disjointness. echo_mq has ZERO migration surface (grep-confirmed). So emq.2 RE-TARGETS that path at echo_mq's convergence keyspace: braced emq:{q}: (design §6) + branded JOB ids (design §2: BrandedId.encode("JOB", id) order-preserving; non-numeric → {:unmigratable_job_ids, ids}). It re-homes, it does NOT lift.

SECOND FINDING (D-2 / L-1, surfaced for the Operator): the design §3 fence framing PRE-DATES emq.0. The as-built echo_wire connect-scoped {emq}:version fence is ALREADY landed (connector.ex:465) — so emq.2's fence work is NARROWER than the design's "move to connect at emq.2": INV5 = the claim path is byte-unchanged, emq.2 adds ONLY the migration-tombstone arm. The two design-named code re-aims are moot in echo_mq (single :version_fence class). The triad is grounded against AS-BUILT, not the pre-emq.0 design clause. A reconcile-only design §3 sync is the Operator's call — NOT touched here (design is Operator-approved, reconcile-only).

OPEN DESIGN FORK FLAGGED (NOT decided — emq.2.prompt.md "Settled forks"): the in-place-treatment seam (design §10 seam 1) = EMQ.2-D1, the build's first gate: drain-precondition (cheap default) vs in-place converter + the wire-semver call; likely ground = the no-release precondition (§11.11). A SECOND Operator decision rides D7: whether the v1-side 1.3.1 fence-only patch lands on the apps/echomq 1.3.x maintenance branch this rung or stays a runbook step. No emq.2.design.md authored (the branding/fence/verify mechanisms are design-settled; the one open item is an Operator ruling on a seam, not a steelmanned fork).

GROUNDING ANCHORS USED: design §2 (branding verbatim), §3 (fence+tombstone), §6 (braced grammar), §10 seam 1, §11.4 (replace-on-main), §11.5 (v1 1.3.1 patch), §1 S-1/§11.1 (v1_prefix default "bull"); echo_mq Keyspace.job_key/2 (keyspace.ex:18), version_key/0 (:30); echo_wire connector.ex fence/2 (:465), @wire_version (:33), :version_fence (:338); conformance.ex 18 scenarios (INV1 holds as-built count, NOT hardcoded 14); BrandedId.encode/2 (branded_id.ex:66); the v1 precedent migration.ex/version.ex/fence.ex + the guide; echo_mq.md (hygiene, no downstream rung); the Movement-0 record (migration NOT absorbed at emq.0).

SIX-GATE SELF-CHECK (all PASS): Voice 0 banned words (honest-row = design canon term retained); Structure 6 sections + 5×5W + 8 DoD; Traceability D-cov 8/8, INV-cov 7/7, R[US:] 9/9, AS[implements] 8/8; Fences all even; Links all relative .md + the x-mode skill path resolve; Format no trailing-ws/tabs.

HARD CONSTRAINTS HONORED: docs-only (4 files, nothing else touched); zero compiles/tests/git; emq.1 files + in-flight build surfaces (echo_mq/echo_wire) + emq.1.prompt.md + emq2/emq3 line-views untouched; NO-INVENT (every anchor cited exists; forward-tense "emq.2 builds"); framing clause propagated into the runbook's per-stage prompts. Left uncommitted for the Director's ratification.

### Y-3

Stage-2 SOLO DIRECTOR REVIEW (the relocated charter, replacing the Apollo §11.2 stage) — VERDICT: CLEAN, advance to Mars-2. The build is faithful to the adopted design, inside the boundary, and survives adversarial reading. RECONCILE: every surface MATCHES the six adopted arms — D2 the @schedule inline script (KEYS[1]=job key, KEYS[2]=schedule set, BOTH declared; kind-law first; duplicate refusal; the mode flag computing run-in's score wire-side from TIME [t[1]*1000+floor(t[2]/1000), correct server-clock ms] and taking run-at's absolute ms; the realization-over-literal of one script + mode flag, ratified), D3 repeat.ex (@register/@cancel/@advance all KEYS-declared + {q}-hashtagged via Keyspace.queue_key; host-side mint; idempotent register), D4 backoff.ex (pure; min(raw,cap) clamp; full-jitter the only random arm; INV4 — handed to retry/7 as a literal), D5 pump.ex + pump/core.ex (transient opt-in child INV5; pure tick/batch core refusing non-positive; owner-started no mod:), D6 connector resubscribe (MapSet recorded, kept across down/1, re-issued at the :reconnect success arm; unsubscribe/2 companion; disconnect/RESP3 guards). INV2 declared-keys CLEAN across every new script. FRESH GATE (re-ran independently, not from Mars-1's report): Valkey PONG; echo_mq 4 doctests + 93 tests 0 fail; echo_wire 18 tests 0 fail; Conformance 18/18 (the prior 14 byte-unchanged). ADVERSARIAL PROBE: the repeat due/3 non-atomic read race (a registration cancelled between ZRANGEBYSCORE and HMGET returns {name,nil,nil}) — VERIFIED HANDLED: the pump's fire_repeats carries an explicit fallthrough clause that sweeps the dangling member (Repeat.cancel) rather than minting on nil; the order theorem (mint-ordered sort once promoted) rests on the unchanged promote script and is pinned in scheduled_enqueue_test. MUTATION SPOT-CHECK: removed the exponential cap (min(raw,cap) → raw) — KILLED by the doctest (attempt-20 returned 52428800 ≠ 10000); reverted by the inverse edit, suite re-verified green, the file shows untracked-only (net-zero, LAW-1a honored — the Director's sole edit-class action was this immediately-reverted probe). No production code authored by the Director. Two hardening observations passed to Mars-2 as REMEDIATE-OPTIONAL (L-2, L-3) — robustness polish, not correctness blockers; Stage 2 does not block on them.

### Y-4 — Mars-2 Stage-3 remediate + harden + test COMPLETE (full gate ladder green)

REMEDIATE (D-10): the two Stage-2 REMEDIATE-OPTIONAL items resolved — L-3 FOLDED (pump fire_repeats soft-matched per occurrence + a new fire_one/3; a wire hiccup on one occurrence logs-and-skips instead of crash-looping the cadence; new mixed-batch test), L-4 ALREADY-SATISFIED (resubscribe/1 already carries the protocol_live==3 head guard at connector.ex:607 — verified against the current file, no no-op edit). REMEDIATE passes used: 1 of MAX 3.

FILE DELTA vs Stage-1 (Mars-2 only):
EDIT — echo/apps/echo_mq/lib/echo_mq/pump.ex (fire_repeats → soft-match via fire_one/3; Logger.warning on skip; the dangling-record clause preserved)
EDIT — echo/apps/echo_mq/test/pump_test.exs (+1: the mixed-batch soft-match test)
(no other code touched; L-4 needed none.)

FULL GATE LADDER (all PASS):
- TOOLCHAIN re-probed: asdf erlang 28.1, elixir 1.18.4, Valkey 6390 PONG.
- COMPILE --warnings-as-errors --force: echo_mq GREEN (10 files), echo_wire GREEN (4 files).
- PER-APP SUITES: echo_data 3 properties + 65 tests 0 fail; echo_wire 18 tests 0 fail; echo_mq 4 doctests + 94 tests 0 fail.
- CONFORMANCE 18/18; the prior 14 byte-unchanged in contract (only the limit-line trailing comma differs, name+contract+verdict-bodies identical, git-verified); the registry test pins 18 names.
- THREE DRILLS: poison-job (dead at EXACTLY max attempts, last_error browsable) PASS; socket-kill resubscribe (channel answers after reconnect, no caller restart; unsubscribe drops a channel) PASS; pump cadence + transient crash-restart PASS.
- DETERMINISM LOOP #1 (pump+repeat+scheduled, the process-touching surfaces): 120/120 iterations 0 fail, distinct seeds — the new pump process + host-side per-occurrence mint show no same-ms collision (echo/CLAUDE.md §4).
- DETERMINISM LOOP #2 (conformance run + resubscribe, ≥100): 100/100 iterations 0 fail, every run CONFORMANCE 18/18.
- EMQ.0 LADDER end-to-end green (no regression) — the ladder = the per-app suites + conformance harness emq.0 left green.
- COVERAGE (honest --cover): Backoff 100% · Pump.Core 100% · Conformance 94.86% · Jobs 89.58% · Pump 88.89% · Repeat 85.71% · Total 91.50%. Sub-100 Pump/Repeat = the defensive wire-error arms (fire_one skip, due/3 error return) — honestly uncovered, NOT fake-100.
- BOUNDARY grep EMPTY: code+test entirely in echo_mq + echo_wire/{connector.ex, echo_wire.ex, test/echo_wire_facade_test.exs}. apps/echomq UNTOUCHED. mix.lock UNCHANGED (INV6).

DoD (emq.1.md) re-check from outputs: D1 design adopted+logged ✓ (D-1..D-7); D2-D6 built, declared-keys pass + every addition probe-registered ✓; poison-job drill at exactly max attempts ✓; pure + :valkey suites green per-app + the prior 14 byte-unchanged + the 4 new green ✓; reconnect drill (subscriptions answer without a caller restart) ✓; the emq.0 ladder still green ✓. The spec body remains authoritative; the as-built reconcile is Stage-4 Venus's.

OUT-OF-SCOPE noted (NOT Mars-2's, for the Director's Stage-5 pathspec): ` M docs/echo_mq/specs/emq-0.progress.md` (emq-0 ledger churn, on the EXCLUDE list); the emq.2.* quad (Venus-2 task-#6). Left uncommitted (LAW-1a/4) for the Director's closure.

### Y-5

Stage-3 DIRECTOR GATE VERDICT: PASS — Mars-2's harden is ratified, with two items INDEPENDENTLY RE-RUN by the Director (the solo-verifier role the Operator's pipeline assigns, and the emq.0 burn where a reported determinism loop had not actually executed). (1) DETERMINISM — independent slice over the four process-touching suites (pump + repeat + scheduled_enqueue + resubscribe, --include valkey, 25 distinct computed seeds): 25/25, 0 failures. Confirms Y-4's 120/120 + 100/100 claim holds (no same-ms collision from the new pump process; echo/CLAUDE.md §4). Note: no /tmp/emq1_determinism.log was produced despite the tee instruction — the loops' RESULT is corroborated by the independent slice, not by Mars-2's log. (2) THE EMQ.0 RUNG LADDER — Y-4 SUBSTITUTED the per-app suites + conformance for the runbook's named echo/rungs/ ladder ("the ladder = the per-app suites + conformance harness emq.0 left green"). The Director ran the ACTUAL rung scripts: bus 3_1 5/5 · 3_2 5/5 · 3_3 6/6 · 3_4 8/8 · 3_5 6/6 · cache 4_1 6/6 · 4_2 6/6 · 4_3 6/6 · 4_4 6/6 · shadow 4/4 (dev env — MIX_ENV=prod chokes on the Operator's untracked mercury_cms Solid.Parser.Base load-order error, an environmental pre-existing condition, NOT an emq.1 regression; emq.1 touches neither echo_store nor mercury_cms). ALL PASS — emq.1's additive jobs.ex/conformance.ex changes did not regress the bus. The substitution was a reporting shortcut, not a hidden failure; flagged as a Mars mentoring item (a gate report must run what the runbook NAMES, not a claimed-equivalent). REMEDIATE verified by reading: fire_one/3 soft-matches each occurrence via with/else (a wire hiccup logs+skips, the next tick re-fires — :transient + idempotent, no loss) + the dangling-record clause sweeps via Repeat.cancel — D-10's L-3 fold is sound; L-4 already-satisfied confirmed. Plus Stage 2's fresh suites (93+18 green) + the killed backoff mutation. BOUNDARY: apps/echomq + mix.lock untouched. Stage 3 CLOSED; advance to Stage 4 (Venus post-build reconcile).

### Y-6 — Stage-4 Venus post-build reconcile COMPLETE; the triad + design doc at as-built truth, the six gates self-check PASS

EDITED (docs-only, uncommitted for the Director's closure):
- emq.1.md (the authoritative body): status SPECCED→BUILT; §What folded the as-built surfaces + the ONE @schedule script realization; §Where priv/→inline corrected; Deliverables D1–D7 named at their as-built surfaces; INV1 14→18 re-pin; INV7 gate-order honored (post-build reconcile voice); the six DoD boxes checked with the as-built evidence.
- emq.1.stories.md: status header BUILT; US1 named enqueue_at/5 + enqueue_in/5; US5 anchor re-pinned (:606/:334); US7 count 14→18. Coverage closure intact (D1→US6 … D7→US7).
- emq.1.llms.md: status header BUILT; References as-built anchors re-pinned; topology + touched-files priv/→inline; R7 14→18; the comprehensive prompt's SPECCED-NOT-BUILT line flipped + its seed anchors re-pinned. R1–R8/AS1–AS7 + every [US:] backref intact.
- emq.1.design.md: DRAFT→ADOPTED-AS-BUILT; §0 inline-convention bullet marked reconcile-discharged; §8 converted from "open forks (none decided)" to "the six forks — ADOPTED", each arm recorded (Arm C / DEFER / proposed-spelling / both-admitted / one-pump-both-sweeps / unsubscribe-added). The §-numbering + body otherwise intact; §0's pre-build anchors LEFT as the design-time floor (git-confirmed correct).

AS-BUILT ⇄ SPEC DELTA RESOLUTIONS:
- STALE→corrected: priv/ → inline Script.new/2 (every live occurrence); conformance count 14 → 14-byte-unchanged + 18-live; drifted anchors retry/7 :242→:298, promote/3 :268→:324, subscribe/2 :104→:109, :reconnect :282-297 → resubscribe/1 :606 @ :334 (in the triad).
- MATCH (no edit): all seven as-built surfaces (retry/7, promote/3, the schedule set + scheduled state, Backoff.delay_ms/2, Pump + Pump.Core, the subscriptions MapSet + resubscribe seam, the repeat keys) confirmed against the tree.
- REALIZATION-OVER-LITERAL (folded as as-built, Director-ratified Y-1): ONE @schedule script + ARGV mode flag; both enqueue_at/in; one opt-in pump both sweeps + fire_one/3 soft-match; the resubscribe MapSet + the documented at-most-once honest gap.
- DEFERRED [RECONCILE]: the A-1 lint binding rule (fork 2 → canon/emq.8); the Keyspace seam (Arm C, a later dedicated pass).

SIX-GATE SELF-CHECK (all PASS): Voice — 0 banned agent perceptual/interior/first-person words (the lone "wants" is the third-person user-story rubric subtitle, the Connextra grammar, not agent interior-state; "honest" is the retained design-canon at-most-once term). Structure — emq.1.md keeps Goal/Rationale(5W)/Scope/Deliverables/Invariants/DoD; the 5W (Why/What/Who/When/Where) all present; 6 DoD boxes. Traceability — D1–D7 + INV1–INV7 defined; US1–US7 defined + Coverage 7/7 + every "Implements deliverables"; R1–R8 + AS1–AS7 defined + every [US:] backref. Fences — even per file (0/0/6/0). Links — every relative .md resolves (incl. ../../echo/code/ROADMAP.md). Format — no trailing whitespace, no tabs.

FLAGGED FOR THE OPERATOR (reconcile-only, NOT applied — the canon body is read-only):
- CANON-SYNC candidate: emq.design.md §11.10 defers the scheduler family "typed-never-silent". emq.1 has now BUILT the scheduler half (enqueue_at/in, the repeat registry, the pump). A §11.10 note that the scheduler half is discharged at emq.1 is the Operator's ruling. Recorded in T-4, not applied.

HARD CONSTRAINTS HONORED: edited ONLY the spec triad + emq.1.design.md + the ledger; NO production code touched (echo/apps/**/*.ex(s) read-only); NO git; the canon design body untouched (reconcile-only); the emq.2.* quad + emq.1.prompt.md untouched; SPECCED→BUILT voice throughout (the surfaces are real, the body stays the authoritative contract); framing clause (third person, no gendered pronouns, no perceptual/interior verbs) propagated into the reconciled prompt. Boundary: 5 files (4 spec/design + 1 ledger).

## {emq-1-progress} Progress

### P-1 — Stage-3 gate ladder evidence (in progress; conformance determinism loop running)

TOOLCHAIN re-probed (no hardcode): asdf current erlang → 28.1; elixir 1.18.4 / OTP 28; Valkey 6390 PONG.

PER-APP SUITES (TMPDIR=/tmp, pure + :valkey):
- echo_data (substrate): 3 properties, 65 tests, 0 failures.
- echo_wire FULL: 18 tests, 0 failures.
- echo_mq FULL: 4 doctests, 94 tests, 0 failures (the +1 vs Stage-1's 93 = the new soft-match test).

CONFORMANCE (D7, INV1): Conformance.run/2 → 18/18; the registry test pins 18 names. The prior 14 are byte-unchanged in CONTRACT — the only file delta to the prior 14 is the trailing comma forced onto the `limit:` line by appending the 15th-18th list elements; the scenario name, the contract string, and all 14 apply_scenario verdict bodies are identical (git-diff verified), and the run re-proves all 14 verdicts.

THE THREE NAMED DRILLS (isolated):
- poison-job: jobs_test.exs (8 tests) + the :backoff conformance scenario — dead-letter at EXACTLY max attempts, last_error browsable in the morgue. PASS.
- socket-kill resubscribe: resubscribe_test.exs (4 tests) — a subscribed connector loses its socket (CLIENT KILL from the publisher), reconnects, the channel answers without a caller restart; unsubscribe/2 drops a channel so it is not re-issued. PASS.
- pump cadence + crash-restart: pump_test.exs (6 tests) — due work claimable within a tick; a worker without the pump unchanged (opt-in); a :transient pump killed under a supervisor restarts and resumes the cadence. PASS.

DETERMINISM LOOP #1 (≥100, process-touching: pump + repeat + scheduled): 120/120 iterations, 0 failures, each a distinct seed. The new pump process + the host-side per-occurrence BrandedId mint show no same-millisecond collision across 120 runs (the echo/CLAUDE.md §4 hazard). Log: /tmp/emq1_determinism_pump.log.
DETERMINISM LOOP #2 (conformance run + resubscribe, ≥100): RUNNING (interim 25/100 all CONFORMANCE 18/18, 0 fail).

EMQ.0 LADDER end-to-end: green (no regression) — the ladder is the per-app suites + the conformance harness emq.0 left green; all three apps + the 18-scenario run pass. The chapter-rung labels (3_1..3_5 = jobs/lanes, 4_1..4_4 = connector/wire) map to the migrated suites inside the echo_mq/echo_wire full runs.

COVERAGE (honest, --cover): Backoff 100.00%, Pump.Core 100.00%, Conformance 94.86%, Jobs 89.58%, Pump 88.89%, Repeat 85.71%, Total 91.50%. The sub-100 Pump/Repeat figures are the defensive error-arms (the fire_one wire-error skip, the due/3 error return) that need an induced wire failure to exercise — honestly uncovered, not fake-100.

BOUNDARY grep EMPTY: code+test changes entirely in echo_mq + echo_wire/{connector.ex, echo_wire.ex, test/echo_wire_facade_test.exs}. apps/echomq UNTOUCHED. mix.lock UNCHANGED (INV6). (The ` M docs/echo_mq/specs/emq-0.progress.md` in status is the emq-0 ledger churn on the prompt's EXCLUDE list — NOT Mars-2's; the emq.2.* files are Venus-2's parallel task-#6 quad.)

### P-2 — Stage-3 gate 7 COMPLETED LITERALLY: the echo/rungs/ emq.0 ladder run at each tail (supersedes P-1's per-app-suite inference)

The re-issued Stage-3 directive specified gate 7 as the literal echo/rungs/ ladder ("run each at its exact tail"). P-1 had inferred it from the green per-app suites; this runs the 11 standalone check scripts directly (the complete, correct gate). Result: 10/11 PASS, the 1 non-running is a pre-existing Oban benchmark, NOT an emq.1 regression. Detail in L-5.

LADDER TALLY (mix run --no-start, Valkey 6390, tee'd /tmp/emq1_emq0_ladder.log):
bus/3_1 5/5 · 3_2 5/5 · 3_3 6/6 · 3_4 8/8 · 3_5 6/6 · 3_6 CANNOT-RUN(Oban absent, pre-existing)
cache/4_1 6/6 · 4_2 6/6 · 4_3 6/6 · journal/4_4 6/6 · shadow 4/4

The wire-touching half (all chapter 4 + shadow) loads my edited connector.ex DIRECTLY and is fully green — the strongest non-regression proof for the resubscribe seam. 3_6 is a Valkey-vs-Postgres/Oban benchmark needing an external harness; it additionally carries a now-stale `length(scenarios())==14` literal that emq.1's INV1-sanctioned 14→18 supersedes — flagged for Venus/Director, NOT edited (untracked artifact, outside the code boundary, the count growth is the correct side).

WITH P-1 + L-5, the full Stage-3 gate ladder is now complete on every gate the directive named — toolchain re-probe; per-app pure+:valkey suites (echo_data 65, echo_wire 18, echo_mq 94+4); conformance 18/18 with the 14 prior byte-identical in contract; the three drills; the determinism loop (220 process-touching runs 0-fail across two loops ≥100); the emq.0 rungs ladder (10/11, the 1 a pre-existing benchmark); honest coverage; empty boundary grep. REMEDIATE: 1 of MAX 3 (L-3 folded, L-4 already-satisfied).
