# emq-e101-reconcile — AAW scope ledger

## {emq-e101-reconcile-learnings} Learnings

### L-1 — E1 grounding drift: echo/apps/echomq has been CONVERTED to v2; the frozen v1 line no longer exists on disk

The brief's premise — "E1 grounds in echo/apps/echomq (the FROZEN v1 line, @version 1.3.0); the v1 surfaces (EchoMQ.Keys with the `bull` default, emq:{queue}: keyspace, bullmq:5.65.1) are CORRECT — keep them" — is STALE against the actual repo.

VERIFIED ground truth (read echo/apps/echomq/lib/echomq/{keys,job,scripts,lock_manager}.ex):
- There is only ONE echomq: echo/apps/echomq. The memory-noted repo-root apps/echomq does NOT exist.
- mix.exs still says @version "1.3.0", but commits e689c0cc "emq prefix" / d2d8266a "[emq.1] specs + implementation" / d2252a32 "[echomq] VIOLATIONS: VALKEY IS THE BACKEND" converted the code to the v2 keyspace.
- keys.ex moduledoc line 2: "The EchoMQ 2.0 keyspace — the unbraced emq:<q>: grammar". So echomq IS v2 now.

What VERIFIES (fn/arities cited by the pages — all REAL, keep): EchoMQ.Keys.{wait,active,paused,delayed,prioritized,completed,failed,marker,waiting_children,stalled,limiter,meta,events,pc}/1, all_queue_keys/1, base/1; job/2, lock/2, logs/2, dependencies/2, processed/2; EchoMQ.Job.from_redis/4 (+ atm/ats/stc/rjk/deid/defa real); EchoMQ.Scripts.{move_to_active/4, move_to_finished/7, execute_raw/4, execute_transaction/2, extend_lock/5, extend_locks/5}; EchoMQ.LockManager (default lock_duration 30_000). move_to_active assembles 11 keys (the "-11" count is accurate).

What is WRONG against the source (string OUTPUTS, not fn names): pages show emq:{queue}:wait / emq:{queue}:{jobId} / emq:{queue}:{jobId}:lock with BRACES — real code emits emq:<queue>:wait (no braces) and the job key is emq:<queue>:j:<jobId> (a j: namespace). Pages claim EchoMQ.Keys.new("emails") => %{prefix:"bull",...} and "default prefix bull" — real new/2 REJECTS :prefix and returns %{name:...}; bull survives only in the v1->v2 migration fence (:v1_prefix). Pages claim meta version reads bullmq:5.65.1 — real version is echomq:2.0.0 (version.ex/fence.ex); bullmq:5.65.1 lives only in queue.ex as lineage. Example file queue-level-keys.ex cites EchoMQ.Keys.id(ctx) — there is NO id/1 (retired). moveToActive-11 is the v1 BullMQ-wire filename; v2 dispatches :move_to_active via a manifest.

DECISION (this run): the 4 scoped changes (BCS xref, Valkey source + BullMQ gloss reframe, end-user voice, stale paths) are surgical and done. The keyspace-format/bull/version drift is a PRE-EXISTING as-built-moved problem, OUT of the 4 scoped changes, and fixing it across 4 pages + SVGs + JS datasets + example files would be a HEAVY reconcile that the brief forbids ("LIGHT", "preserve every interactive/SVG", "do not rewrite prose wholesale"). All cited fn/arities verify real (the brief's explicit grounding-verification scope is fn/arity), so NO invented surface is left. Flag the keyspace drift to the operator for a scope decision.

## {emq-e101-reconcile-decisions} Decisions

### D-1 — Ship the 4 scoped LIGHT-reconcile changes; flag (not fix) the keyspace-format grounding drift

Applied to all 4 pages (hub + 3 dives) + their md mirrors: (1) BCS cross-reference added to Related — /bcs on every page, plus /bcs/bus on the two keyspace pages (queue-level, job-level); (2) Valkey source added (valkey.io/docs/) + every BullMQ Sources gloss reframed to "the wire protocol the v1 line implements (frozen at 1.3.0); EchoMQ 2.0 forks from it"; (3) end-user voice verified — no rung markers / "drafted" / "rung ships" / first-person / perceptual-verbs-on-tools present; (4) no docs/echomq stale paths (none existed). References kept as a two-column .refs grid (2 h3 columns, ≥3 http Sources each). No pre.code block touched → no example re-extraction. Route-tag/crumbs/pager/footer/stamp/interactives/SVGs untouched (diff = 14 ins / 5 del, References-only).

All 4 gate A+ STATUS: PASS (10/10 gates). All cited EchoMQ.* fn/arities verified real against echo/apps/echomq. No v2 surface (echo_mq/EchoWire/EchoCache/EchoMQ.Keyspace…) introduced.

NOT fixed (flagged in L-1, out of the 4 scoped changes + forbidden by "LIGHT / preserve interactives / no wholesale rewrite"): the keyspace-format drift — pages show emq:{queue}: braces + bull default + bullmq:5.65.1 + EchoMQ.Keys.id/1, but echo/apps/echomq is now v2 (emq:<q>:j:<jobId>, bull retired, echomq:2.0.0, no id/1). Operator decision needed: re-ground E1 to v2-as-built, or restore a genuinely-frozen v1 snapshot.
