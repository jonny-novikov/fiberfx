# BCS course map — chapters, routes, status, and the resume point

The B0–B8 ladder of the "Branded Component System" course (served at `/bcs`), kept in sync with
`docs/echo/bcs/bcs.toc.md` (the authoritative TOC — where this file and the TOC disagree, the TOC wins).

## The chapter table

| Chapter | Route | Theme (manuscript Part) | Modules | Triad | Status |
|---|---|---|---|---|---|
| **B0** Orientation | `/bcs` | the law, the id anatomy, the evidence ethic, the map | the landing | `specs/bcs.0.{md,specs.md,llms.md}` | **✓ built** (the design exemplar) |
| **B1** Ideas Behind | `/bcs/ideas` | Part I — the conceptual floor | B1.1–B1.6 (slugs + 20 dives fixed in the ladder) | `specs/bcs.1.{md,specs.md,llms.md}` ✓ | **✓ built** (27 pages — landing + 6 hubs + 20 dives) |
| **B2** The Elixir BCS Core | `/bcs/elixir-core` | Part II — the reference implementation | B2.1–B2.6 | `specs/bcs.2.{md,specs.md,llms.md}` ✓ | ◐ in progress (landing + B2.1–B2.5 built — 21 pages; B2.6 `boundary-acceleration` waits for `bcs2.6.md`) |
| **B3** The Bus | `/bcs/bus` | Part III — EchoMQ, Valkey-native | B3.1–B3.7 (3.7 = Appendix A, the connector; Appendix B = living status, D-B3.2) | `specs/bcs.3.{md,specs.md,llms.md}` ✓ | ◐ in progress (landing + **B3.1–B3.3** built — 13 pages; B3.4–B3.7 manuscript-ready, 16 pages remain) |
| **B4** EchoCache | `/bcs/cache` | Part IV | B4.1–B4.5 (4.5 manuscript-pending, D-B4.2) | `specs/bcs.4.{md,specs.md,llms.md}` ✓ | ◐ in progress (landing + **B4.1–B4.4** built — 17 pages; B4.5 `cache-referee` manuscript-BLOCKED — no `bcs4.5.md`) |
| **B5** Go | `/bcs/go` | Part V | B5.1–B5.2 | — | ○ manuscript pending |
| **B6** Node 22+ | `/bcs/node` | Part VI | B6.1–B6.3 | — | ○ manuscript pending |
| **B7** Production on Fly | `/bcs/fly` | Part VII | B7.1–B7.4 | — | ○ manuscript pending |
| **B8** The Trading System | `/bcs/trading` | Part VIII (capstone) | B8.1 `engine` · B8.2 `log-and-ledger` · B8.3 `strategies` · B8.4 `scale-out` | `specs/bcs.8.specs.md` ✓ | ◐ in progress (landing + **B8.1–B8.2** built — 9 pages; two-layer grounding — the substrate AS-BUILT + hardened (`echo/apps/echo_cache` · `echo/apps/echo_mq` · `docs/echo_mq/emq.roadmap.md`), only the `Exchange.*` consumer PROPOSED; no platform figure invented) |

Module numbers map one-to-one to manuscript chapters: `B[N].[M]` teaches `docs/echo/bcs/content/bcs<N>.<M>.md`
(B1.6 teaches the appendix `bcs1.a1.md`; B3.7 teaches `bcsA.md`).

## The identity (fixed by the exemplar)

- Exemplar page: `html/bcs/index.html` — the contract-sheet system. Copy its head/header/footer/scripts; change
  only `<title>`/`<meta>`, the route-tag, and `<main>`.
- Tokens: `--b-paper/--b-card/--b-ink/--b-dim/--b-line` + segment hues `--b-ns/--b-ts/--b-node/--b-seq`;
  transcripts on `--b-term-bg`. System font stacks only (`--mono` mono-forward, `--sans` body). Nothing fetched.
- Stamp namespace: **`BCS`** (`apps/jonnify-cms/bin/cms stamp mint --ns BCS`). Exemplar stamp: `BCS0NtBpC9oGGW`.
- MUST NOT: dark-editorial navy/cream/gold, Cormorant Garamond / PT Serif / Manrope, `.chap`/`.mods`/`.mod`.

## The resume point

**B1 · Ideas Behind is COMPLETE** — all 27 pages live under `/bcs/ideas` (landing + 6 module hubs + 20 dives),
each STATUS: PASS; the course landing's B1 card + footer are relinked, the chapter landing's six module cards
are live, and `bcs.toc.md` marks B1 `✓ built`. The B1.1–B1.6 batch was built in waves of ≤2 (B1.1+B1.2 →
B1.3+B1.4 → B1.5+B1.6), the chapter-landing module-card flips deferred to the batch's last act per D-B1.4.

**B2 · The Elixir BCS Core is built to its manuscript edge** — the chapter landing plus all five
manuscript-ready modules are live (21 pages, each STATUS: PASS): B2.1 `otp-application`, B2.2 `property-stores`,
B2.3 `champ` (the-forest-and-the-placement-law · sharing-at-the-honest-metric · the-crossover), B2.4
`archetypes` (archetypes-are-data · one-definition-a-thousand-instruments · the-guards-and-the-lanes), and B2.5
`relations` (the-edge-is-the-relation · the-supersession-performed · traversal-and-coherence). The chapter
landing's five module cards are live links, cross-sibling links are restored, and `bcs.toc.md` marks
B2.1–B2.5 `✓ built` with their dive lists. **B2.6 `boundary-acceleration` waits for its manuscript chapter
(`bcs2.6.md`)** — its rung (`bcs_rung_2_6_check.out`, `PASS 5/5`) is on file, its prose is not, so its card
stays a non-anchor `soon` (living-status voice); B2 closes when the Operator writes the chapter.

**The B3 + B4 triads are AUTHORED (2026-06-12)** — `specs/bcs.3.{md,specs.md,llms.md}` (seven modules over the
now FULLY written Part III — `bcs3.md` + `bcs3.1`–`bcs3.6` + `bcsA.md`; the dive partitions slice the chapters'
own gates F/J/L/G/B/C; D-B3.2 keeps Appendix B living-status — `bcsB.specs.md` + two rungs committed, prose
unwritten; D-B3.3 makes the rival's asymmetry line travel with any B3.6 figure) and
`specs/bcs.4.{md,specs.md,llms.md}` (five modules over Part IV, written through `bcs4.4.md` — the book shipped
FOUR chapters where the old TOC predicted two, plus a planned fifth; D-B4.2 keeps B4.5 `cache-referee`
manuscript-pending — no comparative figure exists, none may appear; D-B4.5 priced pairs travel together). The
verified grounding banks in each `*.llms.md` quote all ten rung records verbatim.

**B3 · The Bus is in progress (2026-06-13)** — the chapter landing `/bcs/bus` plus **B3.1
`fence-and-keyspace`** (the-key-grammar · the-fence-live · the-co-location-law, rung `PASS 5/5` F1–F5), **B3.2
`jobs-are-entities`** (the-job-row · enqueue-one-script · the-orders-dividend, rung `PASS 5/5` J1–J5), and
**B3.3 `state-machine`** (claim-the-token-mint · the-fencing-token · the-morgue-and-the-reaper, rung `PASS 6/6`
L1–L6) are built — 13 pages, each STATUS: PASS, 13↔13 md bijection. The course landing's B3 card reads
"3 / 7 modules"; the chapter landing's three module cards are live; cross-sibling links (B3.1↔B3.2↔B3.3) are
restored; `bcs.toc.md` marks B3.1–B3.3 `✓ built`. The grounding bijection lives in
`docs/echo/bcs/bcs.content-map.md` (course page ↔ manuscript chapter/rung ↔ numbered bibliography entry per
`content/bcs.references.md`) — extend it per wave.

**B4 · EchoCache is in progress (2026-06-13)** — the chapter landing `/bcs/cache` and **B4.1–B4.4** (cache-aside
· coherence-by-mint-time · single-writer-ring · the-lane-that-remembers; rungs `PASS 6/6` E/F/G/H) are built —
17 pages, each STATUS: PASS, 17↔17 md bijection. Built in two waves of 2 (B4.1+B4.2 → B4.3+B4.4); the three
priced pairs travel together (D-B4.5); no comparison-set figure invented (D-B4.2); Litestream "named, not built".
Course landing reads "4 / 5 modules"; chapter-landing cards + B3 Up-next teaser flipped; cross-links restored;
`bcs.toc.md` marks B4.1–B4.4 `✓ built`; `bcs.content-map.md` carries the B4 table.

**B4.5 `cache-referee` is BLOCKED, not buildable** — `bcs4.5.md` is unwritten (re-checked 2026-06-13). It is the
referee/benchmark chapter (Nebulex · Cachex · Valkey-tracking measured); its substance is comparative figures
that do not exist, and its dive partition is "fixed when the chapter ships." Authoring it would mean fabricating
benchmark numbers — the course's cardinal violation (D-B4.2). It correctly stays a `planned` card. **Build it
only after the Operator writes `bcs4.5.md` + commits its rung.**

**B8 · The Trading System is in progress (2026-06-13) — the capstone.** The B8 ladder is designed into
`specs/bcs.8.specs.md` (four modules: `engine` · `log-and-ledger` · `strategies` · `scale-out`), and the chapter
landing `/bcs/trading` + **B8.1 `engine`** + **B8.2 `log-and-ledger`** are built — 9 pages, each STATUS: PASS,
9↔9 md bijection. **The B8 grounding discipline (BCS.8-INV1/INV2 — RECALIBRATED by the Operator):** TWO LAYERS,
sharply scoped. The **substrate is AS-BUILT SOURCE, shipped + actively hardened** — `EchoCache.*`
(`echo/apps/echo_cache/lib/echo_cache/`: ring·table·journal·coherence·shadow·litestream), the EchoMQ bus
(`echo/apps/echo_mq/`), the canon — carrying committed records (quoted verbatim, source-labelled) AND a live
rung-gated hardening program (`docs/echo_mq/emq.roadmap.md`, which names the trading platform "the program's
named consumer"). Taught present-tense with the umbrella source paths + the real module surface (e.g. the Ring's
`publish/2`/`occupancy/1`/`stats/1` + its moduledoc, quoted verbatim). **Only the trading consumer** —
`Exchange.*` / `Trading.Ledger`, no source yet — **is PROPOSED**, living-status voice, **no platform figure
invented**. Do NOT blur: the Ring/bus/cache/journal EXIST and are MEASURED; only the trading ENGINE's match
numbers are future.

**Next BUILDABLE gaps (two open fronts):** continue the capstone → `/bcs-write trading strategies scale-out`
(B8.3+B8.4 = 8 pages — B8.3 grounds in `trading.strategies.md` + the as-built lanes/Tables/claims, B8.4 in
placement/claims + the hash audit + Appendix G/H; same two-layer rule, only `Exchange.*` PROPOSED); OR the B3
remainder → `/bcs-write bus fair-lanes bus-meets-stores` (B3.4–B3.7 = 16 pages). Do NOT build B2.6 (until
`bcs2.6.md`), B4.5 (until `bcs4.5.md`), or B5–B7 (Parts pending) ahead of the book.
