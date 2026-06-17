# BCS.4 · spec of record

> The authoritative spec for the B4 chapter (**EchoCache — the near-cache**, `/bcs/cache`): deliverables,
> invariants, the module ladder with the fixed dive partition, the acceptance stories folded in, and the
> Definition of Done. **B4.1–B4.4 are manuscript-ready** (Part IV written through chapter 4.4); **B4.5 waits
> for `bcs4.5.md`** (D-B4.2). Chapter doc: [`bcs.4.md`](bcs.4.md) · agent guide (with the verified grounding
> bank): [`bcs.4.llms.md`](bcs.4.llms.md).

## Deliverables

- **BCS.4-D1 — The chapter landing.** `html/bcs/cache/index.html` (+ md mirror `../markdown/cache/index.md`):
  Part IV's teaching arc (the six laws of the part → the modules) over five module cards (B4.5 non-anchor
  `planned`; unbuilt modules non-anchor `soon`), an "Up next" grid, ≥1 interactive, References, pager (prev
  `/bcs/bus`, next the first built hub), full chrome. Orchestrator-only; bootstraps from the built B2/B3
  chapter landing. [US: BCS.4-US1]
- **BCS.4-D2 — Four module hubs.** One per buildable ladder row, each: the module's framing from its manuscript
  chapter, its three dive cards, ≥1 interactive, a frozen-transcript evidence block (the rung record),
  References, pager. [US: BCS.4-US1]
- **BCS.4-D3 — Twelve dives.** Three per module per the ladder's dive column, each a full lesson: ≥2
  interactives, verbatim evidence, References, the hub → dive1 → dive2 → dive3 → hub pager chain.
  [US: BCS.4-US1]
- **BCS.4-D4 — The relink + sync + verification.** The course landing's B4 card flips live with the first green
  batch (footer too), the chapter landing's cards flip per batch, `bcs.toc.md` tracks built modules, the batch
  passes the verification sequence in [`bcs.4.llms.md`](bcs.4.llms.md). [US: BCS.4-US2]

## The module ladder (the fixed dive partition — D-B4.1)

| Module | Slug · route under `/bcs/cache/` | Manuscript | What it adds | Dives | Status |
|---|---|---|---|---|---|
| **B4.1** | `cache-aside` | `bcs4.1.md` | the declared L1 over L2 Valkey; the `PASS 6/6` rung (E1–E6) | `declared-not-discovered` (E1 the monitored directory — "two caches enumerable with their full declarations", the wrong-kind refusal at the door; E2 three sources of one answer — L1, L2 with `PTTL 300 ms of 300`, the loader once) · `one-fill-per-herd` (E3 the herd drill — "200 concurrent cold readers, loader runs 1, coalesced waiters 199"; singleflight as the named prior art; E4 the speed — `1311621 hit reads per second (762 ns each)` vs `31 us per L2 GET`, "40 times cheaper") · `the-jittered-clock` (E5 jitter — "400 rows filled in 24 ms expire 138 ms apart at jitter 0.2", the zero-jitter control, the sweeper's `swept 400, table size 0`; E6 the bound — "size capped at 100 of 100, 101 fills served their callers and skipped the insert") | ✓ buildable |
| **B4.2** | `coherence-by-mint-time` | `bcs4.2.md` | the versioned invalidation; the `PASS 6/6` rung (F1–F6) | `the-twenty-nine-bytes` (F1 the vocabulary — channel, queue, "a twenty-nine-byte payload of two names, parse refusing garbage", the typed `:requires_resp3`; F2 newer-wins with teeth — the late stale invalidation bounced off both layers, "idempotence is a comparison, not a log"; Lamport's total order carried in the name) · `the-broadcast-lane` (F3 — `median push latency 72 us over 100 messages`, the cross-node round trip; the substrate's at-most-once contract taken whole; F4 the loss gated — the job-lane table "still serves px=100.00 -- bounded staleness until its own lane delivers") · `the-job-lane` (F5 the crash choreography — "the first consumer died holding the job, the reaper returned it, the healer applied it … at-least-once delivery, exactly-once effect"; F6 the price — "broadcast median 72 us fire-and-forget, job lane median 148 us at-least-once -- the guarantee costs 2.1 times the latency") | ✓ buildable |
| **B4.3** | `single-writer-ring` | `bcs4.3.md` | coherence application on a bounded ring; the `PASS 6/6` rung (G1–G6) | `two-sequences-one-table` (G1 the surface + the truthful declaration; G2 order through batches — "1000 items crossed the ring in publish order exactly … through 2 batches (largest 801) on 1 wakes"; the atomics ordering sentence; the Disruptor correspondence) · `occupancy-and-the-bound` (G3 the gauge — "mid-storm the gauge read 600 of 4096 and drained to exactly 0", `1005116 items per second`; G4 full as a counted refusal — "64 accepted, 136 refused with :dropped and counted -- never blocked, never overwritten") · `the-storm-drill` (G5 — "500 invalidations crossed the wire and the ring in 25 ms with nothing dropped … a fill fired mid-storm completed in 0 ms"; G6 convergence — "exactly on 100 applied and 400 stale -- arrival order changed nothing") | ✓ buildable |
| **B4.4** | `the-lane-that-remembers` | `bcs4.4.md` | the per-group SQLite journal; the `PASS 6/6` rung (H1–H6) | `two-memories-one-file` (H1 — one journal file per group named by its branded id, "intents (the outbox) and applied (the lane's last word per name)"; H2 both crash seams closed — Richardson's outbox with the bus's own dedup; "once coverage is total, replay is exactly %{replayed: 0, deduplicated: 0}") · `the-bus-dies-the-lane-replays` (H3 the memory across a full restart — `:remembered_stale` without touching the cache; H4 the loss drill — "exactly 30 uncovered intents re-enqueued in seq order", the applied memory closing at 50 of 50) · `coverage-and-the-price` (H5 compaction — "the outbox empties, the memory does not"; H6 the price — `143 us per record-and-mark pair`, the remembered lane's `524 us` vs the bare lane's 148, "3.5 times the latency buys an outbox, a last word per name, and a replay that survives the bus"; the prepared-statements fix the gate forced) | ✓ buildable |
| **B4.5** | `cache-referee` | *manuscript pending* | Nebulex, Cachex, and Valkey's server-assisted tracking measured where they run — the TOC plans hit-path latency, the herd drill, and coherence-lag distributions | *fixed when `bcs4.5.md` ships* | ○ manuscript pending (D-B4.2) |

Pager chain: chapter landing pager prev `/bcs/bus` · next the first built hub; hub prev = chapter landing, next
= own first dive; dives chain hub → dive1 → dive2 → dive3 → back to the hub.

## Invariants

- **BCS.4-INV1 (figures verbatim)** — every number, id, gate line, derive line, and transcript line quoted
  exactly as the grounding bank in [`bcs.4.llms.md`](bcs.4.llms.md) records it; each module's rung record quoted
  character for character in a source-labelled `figure.frozen` block on its hub. Re-derive nothing, invent
  nothing.
- **BCS.4-INV2 (full links PASS at every state)** — unbuilt routes never anchored; B4.5 stays a non-anchor
  `planned` card; concurrent-wave siblings defer cross-links.
- **BCS.4-INV3 (identity)** — the contract-sheet system copied from a built BCS page; no dark-editorial token.
- **BCS.4-INV4 (chrome + stamps)** — segmented clickable route-tag, canonical 3-column footer, a fresh `BCS…`
  stamp per page, decode-verified, static timestamp dd updated.
- **BCS.4-INV5 (md-first)** — `docs/echo/bcs/markdown/cache/<route>.md` for every page, authored before its
  HTML.
- **BCS.4-INV6 (living status + boundaries)** — nothing under `content/` edited; B4.5, Litestream's
  implementation, EMQ 3.0 Streams, and Parts V–VIII in living-status voice; no comparative referee figure
  invented (D-B4.2); doors per D-B4.5's pairing rule and the chapter doc.
- **BCS.4-INV7 (priced pairs)** — a page quoting one side of a priced pair quotes the other (D-B4.5).

## Acceptance stories (folded)

- **BCS.4-US1 — The reader.** As a reader who has B2's stores and B3's bus, I want Part IV's near-cache taught
  as a chapter, with the manuscript's own rung evidence on every page, so that declared caches, single-flight
  fills, mint-time coherence, the ring, and the journal are learnable without opening the repository.
  - Given a batch ships, when I open `/bcs/cache`, then its modules are live cards and their dives resolve, and
    every figure matches the committed outputs character for character.
  - Given JavaScript is disabled, when I open any B4 page, then every section is readable and the interactives
    degrade to static diagrams.
  - Encodes BCS.4-INV1, BCS.4-INV3. Priority: must · Size: 5 · Implements: BCS.4-D1, BCS.4-D2, BCS.4-D3.
- **BCS.4-US2 — The Operator.** As the Operator, I want every batch gated and the views synced.
  - Given any page in a batch, when the gate command runs, then STATUS: PASS on all ten gates.
  - Given a batch completes, when I open `/bcs`, then the B4 card state is truthful and `bcs.toc.md` matches the
    tree; B4.5 reads `planned`.
  - Encodes BCS.4-INV2, BCS.4-INV4, BCS.4-INV5. Priority: must · Size: 3 · Implements: BCS.4-D4.
- **BCS.4-US3 — The authoring agent.** As a module agent, I want a brief that names my manuscript chapter, my
  dives, my verified figures, my sources, and my pager.
  - Given [`bcs.4.llms.md`](bcs.4.llms.md), when I author my module, then every fact I cite appears in the bank
    or the named manuscript file, and my pages touch only my module's routes.
  - Encodes BCS.4-INV1, BCS.4-INV6, BCS.4-INV7. Priority: must · Size: 2 · Implements: BCS.4-D2, BCS.4-D3.

Coverage: D1→US1 · D2→US1,US3 · D3→US1,US3 · D4→US2.

## Definition of Done (the buildable chapter)

- [ ] 17 md mirrors under `docs/echo/bcs/markdown/cache/` (landing + 4 hubs + 12 dives), each authored before
  its HTML.
- [ ] 17 pages under `html/bcs/cache/`, each STATUS: PASS via the exact command in
  [`bcs.4.llms.md`](bcs.4.llms.md).
- [ ] Figure-provenance audit: every number re-found in its committed source — the four rung records quoted
  verbatim, derive lines intact where carried.
- [ ] Identity audit: `grep -rn 'Cormorant\|Manrope\|PT Serif' html/bcs/cache/` empty; no `.chap`/`.mods`/`.mod`.
- [ ] 17 fresh `BCS…` stamps, each decode-verified.
- [ ] Course landing relinked (B4 card + footer) and chapter landing relinked per batch, re-gated PASS;
  `bcs.toc.md` synced; B4.5 reads `planned` everywhere.
- [ ] Live crawl: every new route 200 on `:8765`; `/bcs` still 200.
- [ ] No manuscript file, ledger, shared asset, or sibling-course file touched. No git commands run.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.4.md
