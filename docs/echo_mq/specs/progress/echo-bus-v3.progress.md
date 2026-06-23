# echo-bus-v3 — AAW scope ledger

## {echo-bus-v3-thinking} Thinking

### T-1 — echo-bus-v3 design phase: the dual-architect consolidation before emq3.5

**Phase, not a shipping rung.** An Operator-inserted architectural rung BEFORE emq3.5 (the stream archive). Output = a design-ahead KB + a reconciliation of the published vision manuscript. No `echo/apps/echo_mq` code, no rung commit; forks SURFACED, not ruled (the Operator rules from the KB, the build follows).

**5W.** *Why* — emq3.5 is the first Stream-Tier rung that reaches OUT of echo_mq into a persistence engine, and the fold seam is named-but-UNSPECIFIED (no doc states how a trimmed slice becomes a `VolumeServer.commit/3` call, nor the merge-read). Reconcile the vision vs the specs vs the Graft as-built on paper first. *What* — the `echo-bus-v3` KB (2 vision-forward perspectives + diffs + ADR matrix + 5W/Rationale + consolidated report) + surgical edits to `docs/echo-persistence/`. *Who* — 2 vision-forward architects (Lens A bus-led, Lens B persistence-led) + Director consolidation. *When* — now, the precursor to emq3.5. *Where* — `docs/echo_mq/kb/echo-bus-v3/{README,consolidated,local-store/,engines/,platform/}` + `docs/echo-persistence/*.md`.

**Lenses (both vision-forward, multi-lens — Operator-ruled, NOT adversarial vision-vs-as-built).** Lens A bus-led ("the log reaches down to the floor", keystone emq3.5) · Lens B persistence-led ("the floor rises to carry the log", keystone the commit-log-as-outbox / ADR-A). They converge on emq3.5 — the fold is both "bus reaching down" and "floor rising up" — which lands the reframed path on emq3.5 as the keystone.

**Structure.** Folder-per-chapter (Operator-chosen): each of local-store/engines/platform = A-lens + B-lens + synthesis; top-level README + consolidated.md (cross-chapter ADR matrix anchored on the existing S-1..S-7 / §2/§3/§5/§12 / DQ-1..DQ-4, + the reframed path + the unified manuscript changeset).

**Recon (3 Explore maps) established the inputs and the inconsistency surface:** eg.6 DEFERRED not next (fly.io EchoMQ floor) · the emq3.5 fold call-site unspecified · `emq.streams.md` ladder still PROPOSED-labels shipped rungs · OpenDAL is the RUST engine's remote (native uses `EchoStore.Tigris`) · echo-persistence internal status-stamp drift (M12 calls M14 "soon").

## {echo-bus-v3-decisions} Decisions

### D-1 — the consolidation result: 6/10 CONVERGED (all of emq3.5's build surface), 4/10 DIVERGED (one meta-axis = the reframed development path)

The two vision-forward lenses (A bus-led, B persistence-led) argued the same 10 forks independently. Result:

**CONVERGED (6) — these ARE the complete emq3.5 build surface:**
- F-LS-A archive landing → a reserved high-range page index (the shipped `@obx_base` outbox pattern generalized; `plugins/graft.ex:46`), the page payload carrying the branded id; A2 Volume-per-stream a named per-stream opt-in.
- F-ENG-A which engine → the native `EchoStore.Graft` via public `commit/3` (`volume_server.ex:50`); COEXIST-canonical, in-process; Rust rejected for emq3.5.
- F-ENG-B fold-consumer placement → store-side (forced by `echo_store→echo_mq`; the native `Committer` proves the shape); both reject the injected-callback that would put the no-loss invariant inside the bus.
- F-ENG-C eg.6 → native engine alone for emq3.5; Rust a deferred evidence-gated peer.
- F-PLAT-B merge-read `W` → a scalar branded id derived from the engine's folded frontier (no drift); a bus-side key only as a derived cache / named polyglot addition. (Re-confirms streams-tier F3.5-B.)
- F-PLAT-C vocabulary → keep "Echo Bus + Echo Persistence" (shipped) distinct from "EchoMesh" (proposed).

**DIVERGED (4) — one meta-axis (keep-boundaries-finish-the-frontier vs unify-onto-the-floor-deepen-toward-ADR-A):**
- F-PLAT-A the spine: bus-led (bus spine, persistence floor; loop reframed as transport asymmetry) vs persistence-led (engine substrate, bus first client; manuscript + dep-graph + ADR-A converge). THE headline.
- F-PLAT-D sequencing: after the tier, finish toward the BCS door (bus) vs the v4 ADR-A commit-log-as-outbox line (persistence).
- F-LS-B SQLite's fate: keep as default outbox (bus) vs Graft-as-outbox subsumes it per ADR-E (persistence). Both agree SQLite stays rebuildable near-term.
- F-LS-C watermark coupling: keep the stream MINID window + CubDB GC distinct (bus) vs derive the GC boundary from MINID (persistence). Both agree fold-before-trim + pin-override carry correctness.

**Consequence:** emq3.5 is fully build-ready on the convergences; the meta-axis is the reframed-development-path ruling for the Operator and does NOT block emq3.5. Lag-1 corrections folded: `EchoMQ.StreamConsumer` is AS-BUILT (emq3.3); the outbox prior art is `plugins/graft.ex:46` (`@obx_base = :erlang.bsl(1,48)`).

### D-2 — Operator rulings on the four DIVERGED forks (EBV3-7..EBV3-10): two deferred (spine + sequencing), two ruled (durability destination + watermark)

The Operator ruled the four diverged forks via AskUserQuestion:

- **EBV3-7 / F-PLAT-A (the spine): DEFERRED** — "finish emq3.5→emq3.6 to the converged surface now; let the spine ruling set what follows" (the Director's staged recommendation). The bus-led/persistence-led *label* stays unruled. **Storage-axis annotation (Operator, verbatim intent):** "Graft = Primary Target. SQLite is a thin pluggable replacement, out of scope." So the durability *substance* is pre-committed toward the persistence-led destination even though the platform's teaching *spine* is deferred.
- **EBV3-8 / F-PLAT-D (post-tier sequencing): DEFERRED** — "tie to the spine ruling"; follows EBV3-7.
- **EBV3-9 / F-LS-B (SQLite's fate): RULED → Graft-canonical** — "EchoStore.Durability's default production is robust Graft." SQLite is demoted to a thin pluggable adapter, OUT OF SCOPE for the program (stays swappable — not hard-retired — but is neither the production default nor worked further). Resolves the long-term destination toward Path B's storage end-state, ahead of the deferred spine; softer than ADR-E's literal `exqlite` retirement (SQLite remains a pluggable adapter).
- **EBV3-10 / F-LS-C (watermark coupling): RULED → distinct for emq3.5** — the Recommended arm; lower coupling, no correctness exposure (correctness rests on fold-before-trim + the engine's pin-override). The MINID-coupled GC boundary is a later measured additive optimization, not emq3.5.

**Refinement of D-1's "four forks, one axis":** the Operator showed the axis is separable — the durability *destination* (EBV3-9: Graft-canonical) is rulable ahead of the spine *narrative* (EBV3-7) and the post-tier *sequencing* (EBV3-8). Three forks stayed coupled to the spine; the storage destination did not; the watermark ruled to the low-coupling default.

**Consequence for emq3.5:** unchanged and reinforced — the six convergences are the build surface; EBV3-10 fixes the watermark distinct; EBV3-9 confirms the fold's commit target (the native `EchoStore.Graft`, already the converged F-ENG-A) is the production-default durability. emq3.5 enters its spec-triad build green.

**Manuscript consequence:** the §6 `engines/native-elixir/the-commit-log-outbox.md` item INVERTS — Graft is the production-default durability (forward-tense where the as-built still literally defaults to SQLite — verify `durability.ex` on apply), SQLite the pluggable/out-of-scope alternative; NOT the staged "SQLite is the default, Graft is BYO." The `checkout-and-gc.md` two-watermarks framing is consistent with EBV3-10 (distinct). The spine STAGE clause (`the-door-to-bcs`) stays (EBV3-7 deferred).

## {echo-bus-v3-report} Report

### Y-1 — Director verify of the consolidation + manuscript reconciliation: PASS

Verified the echo-bus-v3 deliverable on disk after the fork rulings (D-2) + Reconciler-1's §6 application:

- **Boundary CLEAN.** `git status --short` over the scope = 10 modified pages under `docs/echo-persistence/` + the untracked KB `docs/echo_mq/kb/echo-bus-v3/` + the untracked ledger. Nothing under `echo/apps/**`, no canon spec body, no `mix.lock`, no third app.
- **Link integrity CLEAN.** `msh specs echo-persistence` (severity error) → 0 findings; `msh specs echo_mq` → only the 5 PRE-EXISTING out-of-scope errors (4× `[word](word)` in the frozen `emq-5-4.progress.md`, 1× stale link `emq3-4.progress.md:67`) — NONE in `kb/echo-bus-v3/`. The KB cross-links, the §8 ledger link, and Reconciler-1's manuscript→KB forward-links all resolve.
- **The F-LS-B inversion LANDED CORRECTLY** (`the-commit-log-outbox.md` §2). `git diff HEAD` = one surgical sentence-pair added: Graft the canonical production durability "the design commits to / where durability is headed" (forward-tense), the transactional-enqueue boundary folding onto the engine commit-log, SQLite the shipped-today pluggable adapter "out of scope, neither the production default nor carried further." NO-INVENT-verified vs `durability.ex` (SQLite still the literal default at :28; Graft the EchoMQ-4+ BYO plugin at :17) — the forward-tense framing does NOT over-claim Graft as the present default.
- **The spine STAGE clause STAGES, does not resolve** (`the-door-to-bcs/index.md` §1): both readings present (bus = co-equal commit-LSN-loop member + live frontier / engine = the floor), "does not settle which member leads," both "defensible," points to the KB. EBV3-7 (deferred) honored.
- **The F-LS-C framing is consistent with distinct-for-emq3.5** (`checkout-and-gc.md` §2): "two retention watermarks… different axes… coupled only by fold-then-trim; whether they should also share a value is an open design question" — the distinct arm, coupling left as the named future optimization.

Result: deliverable sound. emq3.5 is build-ready on the 6 convergences + the 2 storage rulings (Graft-canonical durability, distinct watermark). No commit (none asked); tree staged-ready as two scoped concerns (KB+ledger / manuscript).

## {echo-bus-v3-learnings} Learnings

### L-1 — a staged manuscript edit INVERTS at a ruling boundary; the better fix bridges; and account for every edited file in the report

Three craft findings from the reconciliation:

1. **Staged edits are not neutral edits.** The §6 changeset authored `the-commit-log-outbox.md` to STAGE the unruled F-LS-B (present SQLite-default / Graft-BYO). When the Operator ruled the opposite destination (D-2: Graft-canonical), that staged edit became actively WRONG and had to INVERT. Lesson: when a changeset spans a ruling boundary, the half written to "stage, don't resolve" encodes a default lean — flag each staged item "re-evaluate if ruled," because a ruling can FLIP it, not just confirm it. (The Director caught this mid-flight and steered the implementor before it finalized.)

2. **The better fix bridged rather than inverted.** The crude steer was "flip SQLite-default to Graft-default." The implementor saw the page teaches the engine's commit-log (replication, ADR-C), not the `Durability` adapter, and landed the ruling via the ADR-A thesis — "the transactional-enqueue boundary folding onto this one append-only log" (the two outboxes BECOME one log) — forward-tense, NO-INVENT-clean against `durability.ex`. Lesson: a ruling about subsystem A often lands best on a page about subsystem B by stating the design's intent to UNIFY them, not by transplanting A's fact onto B.

3. **Report accuracy (implementor calibration, PROPOSE-ONLY).** Reconciler-1's report listed `the-commit-log-outbox.md` as "NO EDIT" and counted "9 dirty" when the disk showed the edit applied (well) and 10 dirty. The work was correct; the self-report under-counted. Lesson: reconcile the final report against `git status`/`git diff` before sending — every dirty file accounted for, every applied edit listed. A correct edit + an inaccurate report still costs the verifier a full re-derivation. (For the Operator/Apollo to fold forward into the implementor role; not applied this phase.)

### L-2 — WITHDRAW L-1 finding #3 (the "under-report" note): a crossed report/steer race, not a Reconciler-1 error

New evidence (Reconciler-1's confirmation report) resolves the apparent report/disk discrepancy L-1 #3 flagged. True timeline:
1. Reconciler-1 report #1 listed `the-commit-log-outbox.md` as NO EDIT — ACCURATE at composition: the file was genuinely untouched then (the staged §6 brief targeted the `EchoStore.Durability` ADAPTER outbox, not this engine-`Committer` REPLICATION dive — a correct distinction Reconciler-1 drew).
2. The Director's steer (the inversion instruction) reached Reconciler-1 AFTER report #1 was composed.
3. Reconciler-1 then applied the inversion (NO-INVENT-verified vs `durability.ex`, forward-voice for the still-SQLite-defaulting code), and sent report #2 confirming the exact OLD→NEW the Director had already verified on disk.

So "9 dirty / NO EDIT" was true when report #1 was written; "10 dirty / inverted" became true after the steer. The Director's verification landed in the async window BETWEEN the two reports and mis-attributed the gap to a reporting inaccuracy. There was NO under-reporting. **L-1 finding #3 is WITHDRAWN — do not fold it into implementor calibration.** L-1 #1 (staged-edits-INVERT-at-ruling-boundaries) and #2 (bridge-don't-transplant) STAND; #2 in fact CREDITS Reconciler-1's judgment (it saw the dive-vs-adapter distinction and bridged via the ADR-A "two outboxes become one log" thesis rather than transplanting). Reconciler-1's handling — accurate-at-time report, correct response to the steer, NO-INVENT verification, clean OLD→NEW — was exemplary.

Director's own lesson (the real one): in a mid-flight team, a teammate's report and the lead's steer can CROSS. Verify against the LATEST disk state, and when a disk/report gap appears, reconcile it with the teammate (or check for a pending follow-up) BEFORE attributing it to a reporting error. A second report may be in flight.
