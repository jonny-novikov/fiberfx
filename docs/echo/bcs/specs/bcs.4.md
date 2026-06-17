# BCS.4 · EchoCache — the near-cache the comparison set does not ship, taught

> The B4 chapter of the BCS course (`/bcs/cache`), teaching manuscript Part IV — branded keys, local speed,
> bus-driven coherence: declared L1 tables, one fill per herd, coherence by mint time, the single-writer ring,
> and the lane that remembers. One chapter landing, four buildable module hubs (B4.1–B4.4) plus B4.5
> manuscript-pending, dives fixed per module in the ladder. Spec of record: [`bcs.4.specs.md`](bcs.4.specs.md)
> · agent guide: [`bcs.4.llms.md`](bcs.4.llms.md).

## Why

B2 gave the names a home, B3 put them in motion; B4 makes reading them cheap without making them wrong. Part IV
is the manuscript's near-cache — and its one structural claim against the named comparison set (Valkey's
server-assisted tracking, Nebulex's near-cache topology, Cachex) is that their coherence is *deletion* while
EchoCache's coherence message carries a *version that is a branded identity*, so newer-wins is a comparison of
two names: the identity theorem cashed a third time. The Part is **written through chapter 4.4**
(`content/bcs4.md` preface + `bcs4.1.md`–`bcs4.4.md`), with four frozen rung records
(`bcs_rung_4_1`…`4_4_check.out`, each `PASS 6/6`); **chapter 4.5 (The Cache Referee) is a manuscript TOC entry
only** — `bcs4.5.md` is not written, so B4.5 stays `planned` in the living-status voice (the D-B2.2 rule).

The manuscript planned this Part as two chapters when the course TOC was first sketched; the book shipped four
(plus the planned fifth). The course ladder follows the book: B4.1–B4.4 buildable now, B4.5 when its prose
ships.

## What

The chapter, and its buildable slice:

1. **The chapter landing** — `/bcs/cache` (`html/bcs/cache/index.html`): Part IV's teaching arc — the six laws
   of the part (declared not discovered · one fill per herd · coherence is a message about a name · two lanes
   named per surface · the single writer applies the stream · recovery is replay beside the bus, never WAL
   inside it) over five module cards (B4.5 non-anchor `planned`), an "Up next" grid. Orchestrator-only.
2. **B4.1 · Cache-Aside at ETS Speed** — hub `cache-aside/` + three dives. Teaches `content/bcs4.1.md`
   (`PASS 6/6`, E1–E6): the declared directory, three sources of one answer, single-flight fills, the 762 ns
   hit, the jittered clock, the bound that degrades to pass-through.
3. **B4.2 · Coherence by Mint Time** — hub `coherence-by-mint-time/` + three dives. Teaches `content/bcs4.2.md`
   (`PASS 6/6`, F1–F6): the twenty-nine-byte message, newer-wins with teeth, the broadcast lane at 72 µs, the
   loss gated, the job lane surviving a crash, the 2.1× price of the guarantee.
4. **B4.3 · The Single Writer and the Ring** — hub `single-writer-ring/` + three dives. Teaches
   `content/bcs4.3.md` (`PASS 6/6`, G1–G6): two atomic sequences over preallocated ETS slots, order through
   batches, occupancy as the gauge, drop as a counted refusal, the storm with the owner decoupled, convergence
   as a comparison. LMAX and the Disruptor read as prior art.
5. **B4.4 · The Lane That Remembers** — hub `the-lane-that-remembers/` + three dives. Teaches
   `content/bcs4.4.md` (`PASS 6/6`, H1–H6): the per-group SQLite journal, two memories in one file, the crash
   seams closed, the bus dying and the lane replaying, coverage as compaction, the 3.5× price of memory.
6. **B4.5 · The Cache Referee** — *manuscript pending* (`bcs4.5.md` unwritten; the TOC plans Nebulex, Cachex,
   and Valkey's tracking measured where they run). A non-anchor `planned` card; living-status voice.

Proof is mechanical: every page at STATUS: PASS across the ten gates, every figure traced to its committed
source, the md mirror authored first.

## Who

- **The reader** — who has B2's stores and B3's bus and now needs the read path: what a declared cache is, how
  one fill survives a herd, why a version is a name, when to pay for the job lane, what the ring buys under a
  storm, and what a journal beside the bus remembers.
- **The Operator** — reviews each batch against the frozen records, including the rungs' own `derive` lines
  (Part IV's records interleave derivations with measurements — the referee habit is in the evidence itself).
- **The authoring agents** — one `bcs-expert` per module, briefed from [`bcs.4.llms.md`](bcs.4.llms.md).

## When

After B3 (or its first batches — B4 pages cite B3 concepts through built routes where they exist and named
`<strong>` text where they do not). Within the chapter: the landing first (orchestrator-only), then waves of ≤2
(suggested: B4.1+B4.2 → B4.3+B4.4), deferred cross-links restored per wave, the course-landing relink last.

## Where

- Pages: `html/bcs/cache/` (landing + four module dirs, three dives each; the `cache-referee` dir follows when
  `bcs4.5.md` ships); md mirrors: `docs/echo/bcs/markdown/cache/**`.
- Grounding (read-only): `content/bcs4.md`, `bcs4.1.md`–`bcs4.4.md`, with the rung records under
  `content/echo_data/runtimes/elixir/` (`bcs_rung_4_1`…`4_4_check.out`).
- Relink targets (orchestrator-only): `html/bcs/index.html`, `html/bcs/cache/index.html`,
  `docs/echo/bcs/bcs.toc.md`.

## How

Orchestrated by `/bcs-write cache …`: landing from this triad (bootstrapped from the built B2/B3 chapter
landing), one `bcs-expert` per module with the [`bcs.4.llms.md`](bcs.4.llms.md) brief, adversarial verification,
manifest relink, TOC sync. No git anywhere; the Operator commits out-of-band.

## Decisions

- **D-B4.1 — The dive partition slices the chapter's own gates.** B4.1's E1–E6, B4.2's F1–F6, B4.3's G1–G6,
  B4.4's H1–H6 — recorded in the ladder; agents do not redesign them. (The D-B2.1/D-B3.1 discipline.)
- **D-B4.2 — B4.5 waits for its manuscript chapter.** The referee chapter's comparison set (Nebulex, Cachex,
  Valkey tracking) is *named* by the Part preface and may be referenced as the preface frames it — coherence as
  deletion, no version, no order — but **no comparative figure exists until `bcs4.5.md` ships**, so no page
  invents one. B4.5 stays `planned`, living-status voice. (The D-B2.2 rule, third application.)
- **D-B4.3 — The derive lines are part of the evidence.** Part IV's rung records interleave `derive` lines with
  measurements; pages quoting a measured figure may (and on `figure.frozen` blocks should) carry its derive
  line, because the prediction-before-measurement discipline is part of what the chapter teaches.
- **D-B4.4 — References extend the vetted registry with Part IV's own citations.** The Erlang/OTP `ets` and
  `atomics` docs, the Valkey SET/EXPIRE/Pub-Sub/client-side-caching pages, Go `x/sync` singleflight, Lamport
  1978, Fowler's LMAX article and the LMAX Disruptor technical paper, Richardson's transactional-outbox pattern
  page, the SQLite WAL documentation, and the Litestream how-it-works page. Nothing outside the union of this
  list and the B0–B3 registry.
- **D-B4.5 — The price rows travel in pairs.** The chapter's economics are honest because each price is quoted
  beside its alternative (762 ns vs 31 µs; 72 µs vs 148 µs; 148 µs vs 524 µs). A page quoting one side of a
  priced pair quotes the other — the cache course's version of the asymmetry rule (D-B3.3).

## Boundaries

This chapter builds Part IV's written pages only. B4.5 is not authored ahead of the book. The bus gains no
persistence here (D-2 stands; the journal is *beside* the bus); Streams stay on the EMQ 3.0 horizon (D-3);
Litestream is named as the off-box layer and deliberately not implemented — pages teach that boundary as the
manuscript states it. Protocol depth doors to `/echomq`; caching substrate patterns to `/redis-patterns` (R1);
the umbrella to `/elixir`.

## Companion files

[`bcs.4.specs.md`](bcs.4.specs.md) (the spec of record) · [`bcs.4.llms.md`](bcs.4.llms.md) (the agent guide) ·
the course docs ([`../bcs.md`](../bcs.md) · [`../bcs.toc.md`](../bcs.toc.md) ·
[`../bcs.roadmap.md`](../bcs.roadmap.md)) · the B2/B3 triads · the manuscript (`../content/bcs4.md`,
`bcs4.1.md`–`bcs4.4.md`) and the committed evidence under `../content/echo_data/runtimes/elixir/`.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Manuscript: ../content/bcs.toc.md
