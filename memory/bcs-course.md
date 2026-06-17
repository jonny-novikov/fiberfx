---
name: bcs-course
description: "The /bcs \"Branded Component System\" course — spec system at docs/echo/bcs/, OWN contract-sheet identity (not dark-editorial), BCS stamp namespace, full-links-PASS rule; B0+B1+B2 BUILT; B3 (landing+B3.1–B3.3, 13pp), B4 (landing+B4.1–B4.4, 17pp; B4.5 BLOCKED), B8 (landing+B8.1, 5pp — CAPSTONE grounded in docs/exchange/ DESIGN corpus (renamed from docs/trading 2026-06-13; trd.1.1 Gateway now REAL code — see [[exchange-platform]]), PROPOSED, two-layer grounding BCS.8-INV2) all IN PROGRESS; content-map=bcs.content-map.md; resume = /bcs-write trading log-and-ledger strategies OR bus fair-lanes"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1e2f4407-c4aa-48da-8fb7-4e280e7d318f
---

The **/bcs course** (built 2026-06-11) teaches the BCS **manuscript** at `docs/echo/bcs/content/` (the
Author/Operator's book: Parts I–VIII, decisions D-1…D-10 in `content/bcs.progress.md`, frozen rung transcripts in
`content/echo_data/`). Course chapters **B0–B8 mirror manuscript Parts 1:1**; module `B[N].[M]` teaches
`content/bcs<N>.<M>.md`. Chapter slugs: ideas · elixir-core · bus · cache · go · node · fly · trading.

**Spec system at `docs/echo/bcs/`** (mirrors redis-patterns): `bcs.md` (contract) + `bcs.roadmap.md` (grounding
map + seams ledger) + `bcs.toc.md` (course TOC — NOT `content/bcs.toc.md`, that is the manuscript's reading
order, never edit it or the ledger, D-7). Chapter triads use the **D-4 naming**: `specs/bcs.N.{md,specs.md,llms.md}`
— `.specs.md` with stories folded in, NOT `.stories.md`. `bcs.0.*` = the shipped B0 exemplar triad.

**Three deliberate inversions vs the sibling courses:**
1. **Own visual identity** — the "contract-sheet" system (light paper `--b-paper/--b-card/--b-ink`, segment hues
   `--b-ns` red/`--b-ts` blue/`--b-node` green/`--b-seq` violet, system font stacks, ZERO external requests,
   `figure.frozen` transcript blocks, 3/11 `.idrule`). MUST-NOT: dark-editorial navy/cream/gold,
   Cormorant/PT Serif/Manrope, `.chap`/`.mods`/`.mod`. Exemplar to copy = `html/bcs/index.html`.
2. **Stamps in its own namespace**: `cms stamp mint --ns BCS` (D-8 applied to the course; landing = `BCS0NtBpC9oGGW`).
3. **Full links PASS, no fail-by-design manifests** — unbuilt chapters are NON-ANCHOR `soon` cards; every page
   holds STATUS: PASS on all ten gates.

**Grounding law:** every figure VERBATIM from a committed output under `content/` (verified: `hash32(...)=234878118`,
`MAX_PAYLOAD "AzL8n0Y58m7"`, connector `PASS 8/8` w/ `29456`/`454483`/`161192` ops/s vs Valkey 8.1.8, rung 1.1
`PASS 6/6`); living-status voice ("the manuscript plans…") for Parts IV–VIII + chapters 3.4–3.6.

**Shipped:** landing A+ ten/ten (`--require-refs` + 4 mounts: /bcs /echomq /redis-patterns /elixir, aliases
`b1=ideas,…,b8=trading`); route wired (main.go bcsDir/BCS_DIR + 2 app.Get, Makefile BCS_DIR in start+run,
Dockerfile COPY); md mirror at `docs/echo/bcs/markdown/index.md`. Deferred by sibling precedent: llms.txt,
root-hub card, sitemap folderRouted.

**Infra:** `.claude/agents/bcs-expert.md` (not spawnable until session reload — fall back general-purpose),
`.claude/skills/bcs-course-writer/` (+ references/course-map.md = resume point), `.claude/commands/bcs-write.md`.

**B1 BUILT COMPLETE** (2026-06-11): all **27 pages** live under `/bcs/ideas` (1 chapter landing + 6 module hubs +
20 dives), every page A+ STATUS: PASS, 27↔27 md bijection. 6 modules: system-substrate · identity-contract ·
id-system · ecs-to-bcs · time-inside-the-name · branding-beats-its-own-integer (appendix=B1.6, D-B1.2); 20 dives
fixed (D-B1.1). Verified grounding bank in `bcs.1.llms.md`. Built in waves of ≤2 (B1.1+B1.2 → B1.3+B1.4 →
B1.5+B1.6) per `/bcs-write`; **the chapter-landing module-card flips + the course-landing B1 card/footer relink
were ALL deferred to the batch's last act (D-B1.4)** — at wave-3 close I flipped all 6 module cards + the pager
on `html/bcs/ideas/index.html` AND the B1 card + footer column on `html/bcs/index.html`, re-gated both PASS,
synced bcs.toc.md (B1 `✓ built`) + the skill's course-map.md resume point. Concurrent siblings deferred
cross-links but neither named the other in prose → nothing to restore. bcs-expert subagent type RESOLVED (no
general-purpose fallback needed this session).

**Tree gotcha (2026-06-11):** the echomq COURSE-level docs are GONE from docs/echomq root (echomq.md/.toc/.roadmap
+ e0–e8 triads removed w/ "remove legacy echomq course" 750bda97; specs/course/ exists but EMPTY) — served
html/echomq still live; remaining spec authority = docs/echomq/specs/emq/emq.md. BCS docs repointed there.
[[echomq-course-spec]] memory is stale on those paths.

**Portal wiring (2026-06-11, now historical — the portal app has since moved out of this repo to its own repository; the in-repo serving path is the Go static route above at `html/bcs/`):** /bcs was portal-served (F6.5.5 parity port): `page_html/bcs.html.heex` + extracted
`bcs-index.css`/`.js` in priv/static/assets (digest re-run), `PageController.bcs` layout:false, router
`get "/bcs"`. Two port-only deltas vs html/bcs/index.html: HEEx brace hazard `emq:{q}:` → `&#123;q&#125;` entities,
+ the shared `<.auth_control>` pill with a CHROME BRIDGE at the end of bcs-index.css (re-expresses
--gold-bright/--gold/--line as --b-ts/--b-line so the dark-token pill renders in the contract-sheet identity).
No deep_link_base remap needed — every internal link on the landing is itself portal-served. BCS is the FIFTH
course card on BOTH course indexes (html/courses.html + portal home.html.heex, kept in parity: 5-count copy,
BCS filter chip, accent #7ab0d8 drafting-blue-bright).

**B2 IN PROGRESS** (2026-06-12): triad `specs/bcs.2.{md,specs.md,llms.md}` senior-authored from Part II manuscript
(modeled on bcs.1.*); chapter landing `/bcs/elixir-core` + **B2.1 `otp-application`** (the-export-list ·
existence-and-the-kill · the-blast-radius, grounds rung 2.1 `PASS 5/5` R1–R5 + bcs.ex gate/2 + supervisor.ex +
Go supervise loop) + **B2.2 `property-stores`** (the-only-key · chronology-without-a-column · the-review-performed,
grounds rung 2.2 `PASS 5/5` P1–P5 + property_store.ex window/3) — **9 pages all A+ STATUS: PASS**, 9↔9 md bijection.
Ladder fixed in bcs.2.specs.md (D-B2.1 dives slice each chapter's gates): B2.3 `champ` · B2.4 `archetypes` ·
B2.5 `relations` · B2.6 `boundary-acceleration` (**B2.6 manuscript-PENDING — bcs2.6.md absent though rung 2.6
`PASS 5/5` is on file; course teaches PROSE chapters not bare rungs → stays planned, living-status**, D-B2.2).
Relinked course landing (B2 card→link "2/6 modules building" + footer) + chapter landing (B2.1/B2.2 cards→built,
pager next), synced bcs.toc.md + course-map.md. **Crash-recovery used:** the B2.1 author agent died on API-Overload
AFTER writing all 4 md before any HTML → md-first checkpoint paid off, a FRESH rebuild agent built HTML from the
surviving md (verified figure-faithful first). bcs-expert type RESOLVED again.

**B2.3–B2.5 BUILT** (2026-06-12, /bcs-write batch): **B2.3 `champ`** (the-forest-and-the-placement-law ·
sharing-at-the-honest-metric · the-crossover, rung 2.3 `PASS 7/7` H1–H7, keeps the in-record `[debug] ChampServer`
line — "the record keeps the drop's voice") + **B2.4 `archetypes`** (archetypes-are-data ·
one-definition-a-thousand-instruments · the-guards-and-the-lanes, rung 2.4 `PASS 5/5` A1–A5, ARC ns) + **B2.5
`relations`** (the-edge-is-the-relation · the-supersession-performed · traversal-and-coherence, rung 2.5
`PASS 5/5` E1–E5, edge_store.ex, Codd 1970) — 12 pages all A+ PASS, **B2 now 21↔21 md bijection**. Waves: 2.3+2.4
concurrent, 2.5 lone-background. Orchestrator verify: tag-stripped `figure.frozen` diff vs `.out` = 0 mismatches
across all 12; number sweep's only suspects = dive-numbering (healthy). Agents self-caught defects: title drift
to TOC truth (B2.4 agent), a derived "49 holders" near-invention removed (B2.5 agent). Restore pass converted 8
deferred `<strong>` sibling mentions → live links (NOTE: md mirrors keep **bold** for in-prose refs — the B2.2
precedent — only Related: lines get the routes added). Chapter landing 3 cards flipped; course landing needed NO
change (B2 card already live). The user's "modules 2-6 = 16 pages" arg reconciled down to 12 (B2.1/B2.2 existed;
B2.6 spec-blocked) — AskUserQuestion confirmed.

**bcs.3 + bcs.4 TRIADS AUTHORED** (2026-06-12, senior-solo per the B2-triad precedent): the manuscript edge had
MOVED past memory — Part III now FULLY written (bcs3.md + 3.1–3.6 + bcsA; rungs 5/5·5/5·6/6·8/8·6/6·6/6 +
connector 8/8 + CONFORMANCE 14/14) and Part IV written through 4.4 (bcs4.md + 4.1–4.4, each rung PASS 6/6 with
derive lines IN the record; the book shipped FOUR chapters where the course TOC predicted two, plus a planned
4.5) — always recount content/ before trusting the TOC/memory edge. Triads: B3 = 7 modules
(fence-and-keyspace · jobs-are-entities · state-machine · fair-lanes · bus-meets-stores · conformance ·
the-connector=bcsA), B4 = B4.1–4.4 buildable (cache-aside · coherence-by-mint-time · single-writer-ring ·
the-lane-that-remembers) + B4.5 cache-referee manuscript-pending. New chapter decisions: D-B3.2 Appendix B
living-status (bcsB.specs.md + 2 connector rungs committed, prose unwritten → NOT a module); D-B3.3 the rival's
asymmetry line travels with any B3.6 figure; D-B4.2 NO comparative cache figure exists until bcs4.5.md; D-B4.3
derive lines are part of the evidence; D-B4.5 priced pairs travel together (762ns↔31µs, 72µs↔148µs,
148µs↔524µs). Self-check: 91 transcript-shaped lines + 52 distinctive fragments in the triads verified verbatim
against the 10 .out records, 0 mismatches. Views synced: bcs.toc.md (B3/B4 sections rewritten w/ slugs+dives,
tally 34→37 modules), bcs.roadmap.md (glance rows B0–B4 statuses + grounding map B3/B4 + triad list),
course-map.md resume.

**B3 IN PROGRESS** (2026-06-12, /bcs-write bus batch): chapter **landing `/bcs/bus`** (orchestrator-authored from
the bcs3.md preface — seven-module arc interactive + the six laws of the part + the 7-record evidence block) +
**B3.1 `fence-and-keyspace`** (hub + the-key-grammar [F1+F2] · the-fence-live [F3+F4] · the-co-location-law [F5],
grounds rung 3.1 `PASS 5/5`, keyspace.ex grammar quoted whole + Go JobKey + bcsA cross-refs 8507/version_fence)
— **5 pages all A+ STATUS: PASS**, 5↔5 md bijection. bcs-expert subagent type RESOLVED (no fallback). Landing
authored FIRST (orchestrator-only) so the B3.1 hub pager prev=/bcs/bus resolved at the agent's gate; landing's
own B3.1 card + pager-next stayed non-anchor until B3.1 landed, then flipped (full-links-PASS at every state).
Orchestrator verify: 24 transcript-shaped lines vs bcs_rung_3_1_check.out = 0 mismatches; 8507/version_fence/
slot 105/8.1.8 all trace to bcsA.md; 4 stamps decode-verified + distinct + dd-parity. Relinked course landing
(B3 card→link "1 / 7 modules building" + footer) + chapter landing (B3.1 card→built, pager-next→link), synced
bcs.toc.md (B3 ◐, B3.1 ✓ built) + course-map.md. NOTE: operator touched html/bcs/index.html out-of-band
mid-batch (linter/commit) — my B3 relink survived; re-verify the tree after external edits.

**B3.2 + B3.3 BUILT** (2026-06-13, one wave of 2 concurrent bcs-expert agents): **B3.2 `jobs-are-entities`**
(hub + the-job-row [boot+J1] · enqueue-one-script [J2+J3, the ten-line Lua whole + EMQKIND match] ·
the-orders-dividend [J4+J5, 301 pending / ORD0Nt6z93U3dY], rung 3.2 `PASS 5/5`) + **B3.3 `state-machine`**
(hub + claim-the-token-mint [L1+L2, claim Lua whole] · the-fencing-token [L3+L4, token 99 EMQSTALE / two lives
one counter] · the-morgue-and-the-reaper [L5+L6, 40 ms reap], rung 3.3 `PASS 6/6`) — **8 pages all STATUS:
PASS**, B3 now 13↔13 md bijection. **Session-limit recovery:** both agents hit the session limit during their
FINAL report — but all 8 HTML + 8 md were already on disk and fully gate-clean; orchestrator verified instead of
respawning (gate 8/8 PASS, 56 frozen transcript lines vs the two .out = 0 mismatches, 8 distinct stamps
decode+dd-parity, audits all empty). Restored 8 deferred cross-links (B3.2↔B3.3 + B3.1's the-key-grammar →B3.2);
B3.4/B3.5 mentions stay `<strong>` (unbuilt). Flipped both chapter-landing cards, course landing "3 / 7
modules", synced toc/course-map. NEW: `docs/echo/bcs/bcs.content-map.md` = the course-page↔manuscript↔rung↔
bibliography bijection (per-wave prerequisite; bibliography = `content/bcs.references.md`, the CLOSED citation
set — B3.2 #25/#26, B3.3 #27/#15/#28); extend it per wave.

**B4 IN PROGRESS** (2026-06-13, `/bcs-write cache`): chapter **landing `/bcs/cache`** (orchestrator-authored from
the bcs4.md preface — five-chapter arc interactive + the six laws of the part + the four `PASS 6/6` rung
evidence block) + **B4.1–B4.4** built in two waves of 2 (B4.1+B4.2 → B4.3+B4.4): **B4.1 `cache-aside`**
(declared-not-discovered · one-fill-per-herd · the-jittered-clock, rung 4.1 E1–E6) · **B4.2
`coherence-by-mint-time`** (the-twenty-nine-bytes · the-broadcast-lane · the-job-lane, rung 4.2 F1–F6) · **B4.3
`single-writer-ring`** (two-sequences-one-table · occupancy-and-the-bound · the-storm-drill, rung 4.3 G1–G6) ·
**B4.4 `the-lane-that-remembers`** (two-memories-one-file · the-bus-dies-the-lane-replays · coverage-and-the-
price, rung 4.4 H1–H6) — **17 pages all STATUS: PASS**, 17↔17 md bijection. Orchestrator verify: 4 rung records
diff-verified verbatim (incl. header + derive lines, D-B4.3) = 0 mismatches; the three **priced pairs travel
together** (D-B4.5: 762 ns↔31 µs · 72 µs↔148 µs · 148 µs↔524 µs — confirmed co-present per page); NO comparison-
set number invented (D-B4.2); Litestream "named, not built"; 16 distinct stamps dd-verified. Restored 10
deferred cross-links (B4.1↔B4.2↔B4.3↔B4.4); B4.5 + B3.4(park-don't-poll) stay `<strong>` (unbuilt). Relinked
chapter landing (4 cards→built, pager-next), course landing (B4 card→"4 / 5 modules building" + footer), AND the
B3 landing's Up-next B4 teaser. Synced bcs.toc.md (B4 ◐, B4.1–B4.4 ✓ built), bcs.content-map.md (B4 table +
ref families 16/38/39/40/41/42/4/43/44/45/46/47/48), course-map. bcs-expert type RESOLVED. **Session-limit recovery
recurred** (B3.2/B3.3 wave) but did not this batch.

**B4.5 `cache-referee` is BLOCKED — manuscript-pending (D-B4.2).** `bcs4.5.md` + `bcs_rung_4_5_check.*` are
ABSENT (re-checked 2026-06-13). It is a REFEREE/BENCHMARK chapter — its whole substance is comparative
measurements (Nebulex · Cachex · Valkey server-assisted tracking: hit-path latency, herd drill, coherence-lag).
There are ZERO committed figures and the dive partition is "fixed when the chapter ships." Authoring it =
inventing structure + fabricating benchmark numbers = the course's cardinal violation. It correctly stays a
`planned` card (no hub, no route; `/bcs/cache/cache-referee` 404s by design). **Do NOT author B4.5 until the
operator writes `bcs4.5.md` + commits its rung** — then ground from it (the manuscript fixes the 3 dives) and
build for real.

**B8 IN PROGRESS — the capstone, grounded in a DESIGN CORPUS not a manuscript** (2026-06-13, `/bcs-write`
pivot): there is NO `bcs8*.md` manuscript and NO old triad; instead the Operator authored the **trading suite
design** under `docs/exchange/` (5 files: trading.md front-door · trading.specs.md · trading.roadmap.md (8 rungs
TRD.1–8, milestones A/B/C) · trading.patterns.md (the Decider + the Disruptor argued deep) · trading.strategies.md
(7 strategy patterns)), **status PROPOSED**. I designed the **4-module B8 ladder** from it (REPLACING the old TOC
placeholder names) + authored `specs/bcs.8.specs.md` (spec of record): **B8.1 `engine`** (the-disruptor-seat ·
the-decider · price-time-by-mint-order) · **B8.2 `log-and-ledger`** · **B8.3 `strategies`** · **B8.4 `scale-out`**.
Built so far: the chapter **landing `/bcs/trading`** + **B8.1** (hub + 3 dives) = **5 pages all A+ PASS**, 5↔5 md
bijection. bcs-expert RESOLVED.

**THE B8 GROUNDING DISCIPLINE (novel — BCS.8-INV1/INV2, RECALIBRATED 2026-06-13 by the Operator):** TWO LAYERS,
sharply scoped. (1) **The SUBSTRATE is AS-BUILT SOURCE, shipped + actively hardened — NOT proposed.** Real Elixir
in the live umbrella: `EchoCache.{Ring,Table,Journal,Coherence,Shadow,Litestream}` at
`echo/apps/echo_cache/lib/echo_cache/` (Ring surface: `publish/2`→`:ok`/`:dropped` counted, `occupancy/1`,
`stats/1`, two-atomics, ETS slots — quote the source + moduledoc), the EchoMQ bus
`echo/apps/echo_mq/lib/echo_mq/` (jobs/lanes/consumer/conformance/...), `EchoWire`, `EchoData`. Committed records
(bcs3.4 8/8, bcs4.1–4.4 6/6, bcsG/bcsH, hash audit 4/4) quoted VERBATIM + a LIVE rung-gated hardening program
`docs/echo_mq/emq.roadmap.md` (3 movements; emq.0 shipped, emq.1 ratified) that NAMES the trading platform "the
program's named consumer standing on this tree." Taught PRESENT-TENSE with umbrella source paths. (2) **ONLY the
TRADING CONSUMER is PROPOSED:** `Exchange.{Gateway,Book,OrderBook,Decider,Projection,Placement}` + `Trading.Ledger`
— **no source exists** (confirmed) — living-status/design voice, **NO platform match/throughput/fill/posting
number invented**. The ONLY numbers: as-built-committed (labelled) OR attributed external (LMAX 6M/s, Fowler).
**Do NOT blur:** the Ring/bus/cache/journal EXIST + are MEASURED; it's the trading ENGINE's match numbers that
don't exist yet. ("PROPOSED" qualifies Exchange.*/Trading.*, never the substrate.)

**B8.1 + B8.2 BUILT** (9 pages total inc. landing, all A+ PASS, 9↔9 md bijection): **B8.1 `engine`**
(the-disruptor-seat · the-decider · price-time-by-mint-order — as-built Ring, ring.ex moduledoc quoted verbatim,
B4.3 figures) ADVANCED 2026-06-13 (over-hedges fixed, frozen-drop paths → live umbrella, hardening pledge added,
stamps unchanged) + **B8.2 `log-and-ledger`** (the-journal-and-the-shadow · replay-equals-live ·
the-double-entry-ledger — as-built Journal/Shadow/Litestream from echo/apps/echo_cache + B4.4 record, priced pair
524µs↔148µs; PROPOSED Trading.Ledger Postgres double-entry + Exchange.Projection). Verified: 0 transcript
mismatches, 0 invented platform numbers (derive-band 200µs–2ms etc. all in frozen blocks), moduledoc whitespace-
normalized verbatim vs ring.ex, 8 distinct stamps, scripts clean. Relinked course landing (B8 "2 / 4 modules") +
chapter landing (B8.1+B8.2 cards). TOC + content-map (bcs.content-map.md B8 table) + spec (bcs.8.specs.md
grounding discipline) all carry the sharpened two-layer rule.

**B4.5 stays SOON/planned** (Operator chose hold) — benchmark chapter, manuscript-BLOCKED (no bcs4.5.md).

**Resume options:** continue B8 → `/bcs-write trading strategies scale-out` (B8.3+B8.4 = 8 pages — B8.3 grounds in
trading.strategies.md + lanes/Tables/claims as-built, B8.4 in placement/claims + hash audit + Appendix G/H; same
two-layer rule); OR the still-open B3 gap → `/bcs-write bus fair-lanes bus-meets-stores` (B3.4–B3.7 = 16 pages).
Do NOT build B2.6 (until bcs2.6.md), B4.5 (until bcs4.5.md), or B5–B7 ahead of the book.
Related: [[redis-patterns-course]], [[user-commits-elixir-batches]].

## Archived index line (2026-06-12, index compaction)

/bcs course over the BCS manuscript: docs/echo/bcs spec system (D-4 triads), OWN contract-sheet identity + BCS stamp ns + full-links-PASS; B0+B1 (27pp)+B2 (21pp) BUILT; B3 IN PROGRESS (landing + B3.1 fence-and-keyspace, 5pp A+); bcs.3+bcs.4 triads authored; resume = /bcs-write bus jobs-are-entities (B3.2→B3.7, 24pp) then cache (17pp)
