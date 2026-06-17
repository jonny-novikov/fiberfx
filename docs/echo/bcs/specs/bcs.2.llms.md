# BCS.2 · agent guide

> How to build the B2 batch (`/bcs/elixir-core`): requirements, do-NOTs, the **verified grounding bank** (the
> senior read every figure below directly in the manuscript chapters and the committed rung records — cite from
> here and the named sources; re-derive nothing, invent nothing), per-module briefs, and the verification
> commands. This rung builds **B2.1** and **B2.2**; B2.3–B2.6 carry pointers, deepened when their rungs run.
> Spec of record: [`bcs.2.specs.md`](bcs.2.specs.md) · chapter doc: [`bcs.2.md`](bcs.2.md).

## References

- The triad: [`bcs.2.md`](bcs.2.md) · [`bcs.2.specs.md`](bcs.2.specs.md) (the module ladder + invariants + DoD).
- The course docs: [`../bcs.md`](../bcs.md) (contract; the identity MUST-NOT list) ·
  [`../bcs.toc.md`](../bcs.toc.md) · [`../bcs.roadmap.md`](../bcs.roadmap.md) (grounding map).
- The design exemplars: a built B1 chapter landing (`html/bcs/ideas/index.html`), a built B1 hub
  (`html/bcs/ideas/system-substrate/index.html`), a built B1 dive
  (`html/bcs/ideas/system-substrate/the-six-gates.html`); the B0 exemplar `html/bcs/index.html` is the
  bootstrap. Copy head/header/footer/scripts from a built BCS page of the same surface — never another course.
- The manuscript chapters (each module's content spine, read-only):
  `../content/bcs2.md` (the Part preface — the chapter landing's spine) · `../content/bcs2.1.md` ·
  `bcs2.2.md` · `bcs2.3.md` · `bcs2.4.md` · `bcs2.5.md`; the committed evidence under
  `../content/echo_data/runtimes/elixir/` (the rung records + the code drops).

## Requirements

- **BCS.2-R1** — md mirror first (`docs/echo/bcs/markdown/elixir-core/<route>.md`), then the HTML, per page.
  [US: BCS.2-US1]
- **BCS.2-R2** — build each page to the ladder in [`bcs.2.specs.md`](bcs.2.specs.md); dives are fixed (D-B2.1),
  not redesigned. [US: BCS.2-US3]
- **BCS.2-R3** — every figure from the bank below or re-verified in the named `content/` file before use; the
  rung records quoted verbatim in source-labelled `figure.frozen` blocks. [US: BCS.2-US1]
- **BCS.2-R4** — a fresh `BCS…` stamp per page: `apps/jonnify-cms/bin/cms stamp mint --ns BCS` →
  `stamp decode <id>` → update the panel's static timestamp dd. [US: BCS.2-US2]
- **BCS.2-R5** — gate every page with the command below; ship only at STATUS: PASS. [US: BCS.2-US2]

## Do NOT

- Do not copy dark-editorial tokens, fonts, or card classes; copy only built BCS pages (bootstrap: the B0
  exemplar).
- Do not anchor unbuilt routes; defer cross-links to the concurrent sibling module (the orchestrator restores
  them post-build); B2.3–B2.6 and B3–B8 are named in `<strong>`, not linked.
- Do not edit `../content/**`, the course landing, the chapter landing (orchestrator-only), or the TOC.
- Do not fetch anything external; no storage APIs; honour `prefers-reduced-motion`.
- Do not write a figure absent from the bank and the sources; do not assert B2.6 or manuscript Parts III–VIII
  as written ("the manuscript plans…").
- Do not run git. Mind the gate traps: the words `just`/`simply`/`obviously` in visible prose; the literal
  substring `/future` anywhere in the file; a perceptual verb on a tool (a store/gate/supervisor does not
  "see"/"want"/"know"/"decide").

## Per-module briefs + the verified grounding bank

Pager law (both modules): hub prev = `/bcs/elixir-core`, next = own first dive; dives chain hub → dive1 →
dive2 → dive3 → back to the hub. Crumbs mirror the route. `Related` links: the chapter landing, the sibling
module **within this batch only after the orchestrator's restore pass**, and the doors (`/echomq`,
`/redis-patterns`, `/elixir`) where the content meets them.

### B2.1 `otp-application` — teaches `../content/bcs2.1.md`

Dives: `the-export-list` · `existence-and-the-kill` · `the-blast-radius`.

Verified figures (source: `bcs2.1.md`, quoting `bcs_rung_2_1_check.out`):

- The transcript, verbatim (quote in this exact order — it is how the record prints):
  ```
  boot: two stores under one_for_one; native codec self-check passed at each init
  R1 surface ok -- exports: six domain functions plus OTP callbacks, nothing else -- no table, no pid, no internals
  R2 existence ok -- existence restored, data not: fresh table after kill -- durability is a different chapter's job
  R4 radius ok -- sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash
  R3 checkpoint ok -- recovered through the boundary, not the heap: re-put from a read-back row
  R5 gate ok -- prt_store refuses an ORD name with {:error, :namespace} -- admitted kinds are per-boundary
  PASS 5/5
  ```
- **R1 — the boundary is the export list.** The store module's actual surface is `start_link/1`, `put/3`,
  `get/2`, `page_desc/2`, `record_entity/2`, `placement/1`, plus the behaviour's own OTP callbacks — "six domain
  functions plus OTP callbacks, nothing else." What a system never exports is the load-bearing half: the table
  (`protection: :private`), any pid, any internal record shape.
- **R5 — the boundary declares its kinds.** `prt_store` offered an `ORD` name is refused `{:error, :namespace}`
  — admitted namespaces are a per-boundary property, checked at every ingress (clause three from Chapter 1.2).
- **R2 — existence is the supervisor's; data is not.** Killing the portfolio store: the supervisor restores the
  process, the pre-kill row is gone — "existence restored, data not: fresh table after kill." The BEAM guards
  data, not existence; a private ETS table dies with its owner [2], by design.
- **R3 — checkpoints are rows.** A row read back through the API, lost in the crash, recovered the only
  legitimate way — "recovered through the boundary, not the heap: re-put from a read-back row." Process state is
  working memory; anything load-bearing in it is a checkpoint not yet written.
- **R4 — restart strategy is a blast-radius statement.** Crashing the portfolio store while the order store
  holds a row: "sibling untouched (one_for_one): ord_store pid stable, row intact through prt_store's crash."
  Under `one_for_one`, "only that child process is affected" [1]; children start left to right and stop in
  reverse [1], so the supervisor's child list is documentation the runtime enforces.
- The boot line carries clause three applied to startup: "native codec self-check passed at each init" — a
  store refuses to exist before the canon proves itself.
- The supervisor is `EchoData.Bcs.Supervisor`, `one_for_one` over named stores. The proper `Application`
  callback module arrives with the umbrella adoption rung (named in prose, not built here).
- **The Go counterpart (quote verbatim from `bcs2.1.md`'s How):**
  ```go
  func supervise(ctx context.Context, run func(context.Context) error) {
      backoff := 100 * time.Millisecond
      for ctx.Err() == nil {
          if err := runRecovering(ctx, run); err != nil {
              time.Sleep(backoff) // existence restored next loop;
              backoff = min(backoff*2, 2*time.Second)
              continue // data was the goroutine's locals: gone, by design
          }
          return
      }
  }
  ```
  One loop per system is the `one_for_one` analog; a shared loop over several owners is `one_for_all`.
- Decisions (from the chapter): data dies with the owner, by design · checkpoints are rows · `one_for_one` is
  the default, wider is a written claim · the export list is the boundary contract (adding an export is an
  architecture change with R1 as its gate).
- Files: `content/echo_data/runtimes/elixir/lib/echo_data/bcs/property_store.ex`, `bcs/supervisor.ex`,
  `bcs.ex`; `bcs_rung_2_1_check.exs` + `.out`; and `bcs_rung_1_1_check.out` (the skeleton's six gates,
  re-running green under the grown surface).

Sources (refs block): Erlang/OTP `supervisor` docs `https://www.erlang.org/doc/apps/stdlib/supervisor.html`
(restart strategies; `one_for_one` blast radius; start order / reverse shutdown) · Erlang/OTP `ets` docs
`https://www.erlang.org/doc/apps/stdlib/ets.html` (table protection levels; lifetime bound to the owning
process). Door: the umbrella + Portal engine where `echo_data` lives → `/elixir`.

### B2.2 `property-stores` — teaches `../content/bcs2.2.md`

Dives: `the-only-key` · `chronology-without-a-column` · `the-review-performed`.

Verified figures (source: `bcs2.2.md`, quoting `bcs_rung_2_2_check.out`; the store at `property_store.ex`):

- The transcript, verbatim:
  ```
  boot: three system tables under one tree -- AST instruments, PRT balances, ORD orders
  P1 shape ok -- instrument and balance rows live behind their own boundaries; values are private representations
  P2 key ok -- the branded form is the only key: the same snowflake's decimal rendering refused as :invalid
  P3 order ok -- newest five by byte order equal the last five minted: no timestamp column consulted
  P4 window ok -- window [tA,tB) by synthetic cursors returned 100 of 100 expected, ascending by key
  P5 review ok -- surface grew by exactly one export: window/3 -- the review Chapter 2.1's decision required, performed
  PASS 5/5
  ```
- **P1 — the database shape.** Three stores under one tree — `AST` instruments, `PRT` balances, `ORD` orders —
  domain rows behind their own boundaries; "values are private representations." (The balance value carries a
  positions map for now — interim by declaration, superseded by Chapter 2.5.)
- **P2 — the branded form is the only key.** The instrument's own snowflake rendered as the 19-digit decimal is
  "refused as `:invalid`" on read and write. The key law is now enforced from all three sides the series has
  measured: the store charges more for the decimal (Chapter 1.3), every compiled runtime renders it slower
  (Appendix 1.1), and the boundary refuses it outright (here).
- **P3 — chronology without a column.** Three hundred `ORD` mints across real wall time; the newest five by byte
  order equal the last five minted — "no timestamp column consulted." `page_desc/2` walks the table tail; the
  order theorem is a read path.
- **P4 — the window, landed in-process.** Two wall-clock instants captured mid-mint, two synthetic cursors built
  by the `min_for` arithmetic of Chapter 1.5, and `window/3` answering "returned 100 of 100 expected, ascending
  by key" — the mints in `[lo, hi)`, half-open. The bounds are branded ids, gated like any ingress; the
  ascending order is the `ordered_set`'s term order [1], not a sort call.
  - **The implementation (quote verbatim from `bcs2.2.md`'s How — it is the real `property_store.ex`):**
    ```elixir
    spec = [{{:"$1", :_}, [{:>=, :"$1", {:const, lo}}, {:<, :"$1", {:const, hi}}], [:"$1"]}]
    {:reply, {:ok, :ets.select(s.table, spec)}, s}
    ```
    Both bounds pass through `Bcs.gate/2` first; term order over binaries is byte order [1].
  - **The Go counterpart (verbatim):**
    ```go
    lo := brandedid.MustEncode("ORD", minFor(t0))
    hi := brandedid.MustEncode("ORD", minFor(t1))
    i := sort.SearchStrings(keys, lo)
    j := sort.SearchStrings(keys, hi)
    window := append([]string(nil), keys[i:j]...) // [lo, hi), ascending
    ```
- **P5 — the review, performed.** "surface grew by exactly one export: window/3" — Chapter 2.1's decision (adding
  an export is an architecture review with R1 as its gate) exercised for the first time. The previous chapter's
  committed record stays exactly as it was: evidence outputs are frozen snapshots of their day; scripts evolve
  with the surface, committed records do not — the 2.1 record is now the pre-amendment surface evidence.
- The three desk reads: `get/2` when the name is known, `page_desc/2` when the question is *latest*, `window/3`
  when the question is *between*. The window contract: `window(store, lo, hi)` is `[lo, hi)`, ascending, bounds
  gated against the store's namespace.
- Decisions: one export per review, with the gate as the instrument · evidence outputs are frozen · the interim
  representation is declared (the balance's positions map, superseded by 2.5) · window bounds are ingress.
- Files: `content/echo_data/runtimes/elixir/lib/echo_data/bcs/property_store.ex` (grown by `window/3`);
  `bcs_rung_2_2_check.exs` + `.out`; the frozen `bcs_rung_2_1_check.out` as the pre-amendment evidence.

Sources: Erlang/OTP `ets` docs `https://www.erlang.org/doc/apps/stdlib/ets.html` (`ordered_set` term-order
traversal; `select/2` and match specifications; protection levels). Door: the storage economics under the
keyspace → `/redis-patterns`; the Portal engine where `echo_data` lives → `/elixir`.

### B2.3–B2.6 — pointers (deepened when their rungs run)

These rows are specced in the ladder; their full grounding banks are authored when the modules are built.

- **B2.3 `champ` — `../content/bcs2.3.md`**, quoting `bcs_rung_2_3_check.out` (`PASS 7/7`, H1–H7) and the drop
  `champ/{branded_champ,champ_node,champ_server}.ex`. Headline figures (verbatim): `v1 holds 1000, v2 holds
  1001`; `v2 costs 122 words beside v1 (one path copy) against 6688 standalone -- 98% of v2 is shared with v1`;
  `namespace_size AST=500 ORD=500`; `by-snowflake 1858 ns/op vs string-id 2344 ns/op`; `champ 41 ms vs ets 7
  ms`; `champ 799 ns vs ets 315 ns`; `one ets copy-out in 2540 us`; `10000 server calls 28 ms vs
  snapshot-once-then-pure 8 ms (copy cost included)`; `compute_hash_int -> BrandedId.hash32`. Source: Steindorfer
  & Vinju, OOPSLA 2015 `https://dl.acm.org/doi/10.1145/2814270.2814312`. Door: `/redis-patterns`.
- **B2.4 `archetypes` — `../content/bcs2.4.md`**, quoting `bcs_rung_2_4_check.out` (`PASS 5/5`, A1–A5) and
  `bcs/archetypes.ex`. Headline figures: `tick 0.25 from the instrument, settlement :daily_mark from the
  archetype, margin true from the base`; `multiplier 100 at next read`; `an instrument row is 18 words, its
  composed view 14`; `{:error, :cycle}`, `{:error, :depth}`; `store-lane 5442 ns/op vs snapshot-lane 1048
  ns/op`, `a bare row get is 2653 ns/op`; the `ARC` namespace registration. Sources: West 2007
  `https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/` · Gamma interview
  `https://www.artima.com/articles/design-principles-from-design-patterns`.
- **B2.5 `relations` — `../content/bcs2.5.md`**, quoting `bcs_rung_2_5_check.out` (`PASS 5/5`, E1–E5) and
  `bcs/edge_store.ex`. Headline figures: `the holds relation is its own system -- PRT subjects, AST objects,
  indexes private`; `link, unlink, props, from, to, degree -- and its indexes are nobody's business`; both ends
  gated `{:error, :namespace}`; `positions struck out of the balance row and copied down as edges -- the 2.2
  label is paid`; `forward 200 ascending with a 10-edge page head; reverse finds all 50 holders, ascending`;
  `degree 199; the reverse index no longer lists the subject`. Source: Codd 1970
  `https://dl.acm.org/doi/10.1145/362384.362685`.
- **B2.6 `boundary-acceleration` — manuscript pending.** The rung `bcs_rung_2_6_check.out` (`PASS 5/5`, B1–B5) is
  on file — `every ingress gated: 5 sites in the property store, 9 in the edge store`; `a passing gate 149
  ns/op; a wrong-kind refusal 154 ns/op`; `hash32 pure 133 vs native 82 ns/op`; `8 readers on the granted table
  2507051 ops/s; 8 readers through the owner 606978 ops/s`; `Part II closes green: five rung records on file --
  5/5, 5/5, 7/7, 5/5, 5/5` — but the prose chapter (`bcs2.6.md`) is not written, so the module stays `planned`
  and takes the living-status voice.

## Agent stories

- **BCS.2-AS1 [implements BCS.2-US3]** — Per module: author the md mirrors (hub + dives), then the pages,
  copying the design from the named model. Acceptance gate: every figure on the pages appears in this bank or
  the named manuscript file, character for character; the rung record is quoted verbatim in a `figure.frozen`
  block.
- **BCS.2-AS2 [implements BCS.2-US1]** — Interactives per surface: hub ≥1, dive ≥2, pure functions over the
  module's own fixed dataset (the transcript gates, the export list, the window bounds, the `page_desc` tail),
  live readout, static degrade.
- **BCS.2-AS3 [implements BCS.2-US2]** — Gate, then self-audit: figure provenance, identity leak, clamp
  spacing, route-tag form, stamp decode, md mirror present.

## Build order

1. Orchestrator: chapter landing (`/bcs/elixir-core`) from this triad — gate it.
2. Wave 1 (2 agents): B2.1 (`otp-application`) + B2.2 (`property-stores`). (Defer the cross-sibling link;
   restore after the wave lands.)
3. Orchestrator: restore deferred links → relink the chapter landing (B2.1/B2.2 cards) and the course landing
   (B2 card + footer) → sync [`../bcs.toc.md`](../bcs.toc.md) → final verification.

## The verification sequence

```bash
# Gate (per page; all ten must PASS)
FLAGS="--routes-from /bcs=html/bcs --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /elixir=elixir --chapter-alias b1=ideas,b2=elixir-core,b3=bus,b4=cache,b5=go,b6=node,b7=fly,b8=trading --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} html/bcs/elixir-core/<path>.html

# Stamp (per page)
apps/jonnify-cms/bin/cms stamp mint --ns BCS && apps/jonnify-cms/bin/cms stamp decode <id>

# Batch audits (all must return nothing)
grep -rn '/future' html/bcs/elixir-core/
grep -rnEi '\b(revolutionary|blazing|magical|simply|just|obviously|effortless)\b' html/bcs/elixir-core/
grep -rn 'localStorage\|sessionStorage\|Cormorant\|Manrope\|PT Serif' html/bcs/elixir-core/
grep -rnE 'clamp\([^)]*[0-9](\+|-)[0-9]' html/bcs/elixir-core/
grep -rnE '\b(store|gate|supervisor|system|boundary|bus|id) (sees?|wants?|knows?|decides?)\b' html/bcs/elixir-core/

# Live crawl (server on :8765; 000 = server down, not route missing)
curl -s -o /dev/null -w '%{http_code}\n' localhost:8765/bcs/elixir-core
```

## Comprehensive prompt

Build your assigned B2 module of the BCS course. Read [`bcs.2.specs.md`](bcs.2.specs.md) (your module's row in
the ladder is your structure — do not redesign it), your manuscript chapter under `../content/`, and your
module's section of this guide (your verified figures and sources). Author the md mirrors first
(`docs/echo/bcs/markdown/elixir-core/<route>.md`), then the pages, copying the contract-sheet design from the
named built BCS page — never another course. Quote every figure verbatim from the bank; render the rung record
in a source-labelled `figure.frozen` block; mint and decode-verify a fresh `BCS…` stamp per page; keep every
internal link resolving (defer the sibling-module link per your brief). Gate each page with the command above;
ship only at STATUS: PASS. Touch only your module's routes. Never run git.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.2.md · Spec: ./bcs.2.specs.md
