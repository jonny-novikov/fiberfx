# BCS.0 · spec of record

> The authoritative spec for the B0 rung: deliverables, invariants, the gate matrix the landing must satisfy
> mechanically, the design brief, the acceptance stories folded in, and the Definition of Done. Chapter doc:
> [`bcs.0.md`](bcs.0.md) · agent guide: [`bcs.0.llms.md`](bcs.0.llms.md).

## Deliverables

- **BCS.0-D1 — The visual identity.** The course's design system, defined on the landing per the design brief
  below: monospace-forward typography on system font stacks, the 3/11 segmentation rhythm, the triptych grammar,
  transcript-styled evidence blocks, a palette of its own. The MUST-NOT list in [`../bcs.md`](../bcs.md) is
  binding. [US: BCS.0-US1, BCS.0-US3]
- **BCS.0-D2 — The landing.** `html/bcs/index.html`, authored md-first (`../markdown/index.md`): hero with the id
  anatomy (interactive SVG), the law triptych, the evidence ethic with verbatim figures, the B1–B8 map (non-anchor
  `soon` cards), doors to the sibling courses, two-column References, full chrome (route-tag · 3-column footer ·
  `BCS…` stamp + decoder), `class="pager"` forward link. [US: BCS.0-US1]
- **BCS.0-D3 — The wiring.** `/bcs` + `/bcs/*` served by `serveDirTree` from `BCS_DIR` (default `/app/html/bcs`):
  `main.go` (package var · env override · two `app.Get` registrations · the section-list comment · the startup
  log), `Makefile` (`BCS_DIR ?=` var · the `start` and `run` env blocks · the help line), `Dockerfile`
  (`COPY html/bcs/ /app/html/bcs/`). [US: BCS.0-US2]
- **BCS.0-D4 — The verification.** The gate run at STATUS: PASS, the root build clean, the live crawl green, the
  regression checks green — the exact sequence in [`bcs.0.llms.md`](bcs.0.llms.md). [US: BCS.0-US2]

## Invariants

- **BCS.0-INV1 (self-contained)** — the landing makes zero external requests: inline CSS/JS, system font stacks,
  no CDN, no images fetched. Disabling JavaScript leaves every section readable.
- **BCS.0-INV2 (full links PASS)** — every internal href resolves against the gate's allowed set; unbuilt
  chapters are non-anchor cards; the site root `/` is never linked.
- **BCS.0-INV3 (frozen evidence)** — every figure on the page exists verbatim in a committed output under
  `../content/` (the contract, the vectors, the transcripts, the bench record). A number not present there does
  not appear.
- **BCS.0-INV4 (chrome)** — the clickable segmented route-tag and the canonical 3-column footer + bottom bar with
  a valid `BCS…` stamp and working decoder are present and restyled into the identity, structure intact.
- **BCS.0-INV5 (no regression)** — every previously served route (incl. `/healthz`, `/echomq`,
  `/redis-patterns`, `/elixir`) serves unchanged; the wiring adds, never edits, existing registrations.
- **BCS.0-INV6 (identity boundary)** — none of the dark-editorial MUST-NOT tokens appear: no
  `--ink`/cream/gold palette values, no Cormorant Garamond / PT Serif / Manrope stacks, no `.chap`/`.mods`/`.mod`
  card classes.

## The gate matrix (mechanical — verified in `apps/jonnify-cms/internal/apollo/apollo.go`)

| Gate | What the landing must contain |
|---|---|
| `containers` | balanced div/section/main/header/footer/nav/article/figure/aside outside svg/script/style |
| `svg` | ≥1 inline `<svg>`, balanced — the id-anatomy / chapter-map graphic |
| `no-future` | zero occurrences of the literal substring `/future` anywhere in the file, comments and JS included |
| `voice` | visible prose free of: revolutionary, blazing, magical, simply, just, obviously, effortless |
| `storage` | no `localStorage` / `sessionStorage` tokens anywhere, scripts included |
| `motion` | the literal string `prefers-reduced-motion` present (a reduce media query) |
| `degrade` | no `.reveal` class, or JS-gated via `html.js .reveal`; page readable without JS |
| `links` | every internal href resolves (mounts: `/bcs`, `/echomq`, `/redis-patterns`, `/elixir`); never `/` |
| `pager` | a literal `class="pager"` block with a resolving internal href |
| `refs` | a literal `class="refs"` References section (run with `--require-refs`) |

Two gate-invisible checks, by reading: **clamp spacing** (spaces around `+`/`-` inside `clamp()`), and
**route-tag intent** (the current segment is `rcur`, no anchor at root depth).

## The design brief (BCS.0-D1, expanded)

- **Anchor motif — the id anatomy.** `USR0KHTOWnGLuC` (the chapter-1 example) and the page's own stamp dissected:
  a 3-character namespace segment + an 11-character Base62 payload carrying `ts(41) | node(10) | seq(12)`. The
  hero renders the dissection; the 3/11 split recurs as a layout rhythm (rules, column ratios, spacing).
- **The triptych grammar.** The law's three clauses as a three-panel composition; three-part section headers.
- **Transcript evidence blocks.** Measured figures (the canonical vector `234878118`, `MAX_PAYLOAD
  "AzL8n0Y58m7"`, the connector's 454,483 pipelined ops/s vs 29,456 sequential, `PASS 6/6`) render as committed
  terminal output: bordered, source-labelled, quoted verbatim.
- **Typography.** Monospace-forward on system stacks (`ui-monospace`/`SFMono-Regular`/`Menlo`… for the id, the
  evidence, and the headers' technical register; a system sans for body prose). No external fonts.
- **Palette.** The course's own — chosen at build time, distinct from the dark-editorial navy/cream/gold. The
  identity is fixed by the shipped exemplar, then recorded in the authoring skill.
- **Interactivity.** ≥1 interactive (the id-anatomy SVG: hover/focus a segment, read its field), pure functions,
  degrades to a static diagram, honors `prefers-reduced-motion`, stores nothing.

## The wiring touchpoints (BCS.0-D3, exact)

| File | Change |
|---|---|
| `main.go` | `bcsDir = "/app/html/bcs"` in the package var block (after `echomqDir`); `BCS_DIR` override beside the other section overrides; `app.Get("/bcs", …)` + `app.Get("/bcs/*", …)` → `serveDirTree(c, bcsDir, …, "bcs")` after the `/echomq` pair; add `bcs` to the folder-routed comment and the startup log |
| `Makefile` | `BCS_DIR ?= $(REPO_DIR)/html/bcs` after `ECHOMQ_DIR`; `BCS_DIR=$(BCS_DIR) \` in **both** the `start` and `run` env blocks; a `/bcs` help line |
| `Dockerfile` | `# Copy the Branded Component System course …` + `COPY html/bcs/ /app/html/bcs/` after the echomq COPY |

Deferred (recorded in the [roadmap](../bcs.roadmap.md) seams ledger): `cmd/sitemap` `folderRouted`,
`html/llms.txt`, the root-hub card.

## Acceptance stories (folded)

- **BCS.0-US1 — The reader.** As a reader landing on `/bcs`, I want one page that states the law, dissects the
  id, shows the evidence ethic, and maps the chapters, so that I know what the course is and where it goes.
  - Given the server runs, when I open `/bcs`, then the landing renders with the law triptych, the id-anatomy
    SVG, at least one verbatim transcript figure, and the B1–B8 map with `soon` markers.
  - Given JavaScript is disabled, when I open `/bcs`, then every section is readable and the SVG renders
    statically.
  - Encodes BCS.0-INV1, BCS.0-INV3. Priority: must · Size: 3 · Implements: BCS.0-D1, BCS.0-D2.
- **BCS.0-US2 — The Operator.** As the Operator, I want the route wired the way every folder-routed course is
  wired and a mechanical verification trail, so that the rung is reviewable and reversible.
  - Given the wiring, when the root binary builds and starts, then `curl /bcs` returns 200, `/bcs/nope` returns
    404, and every pre-existing route still serves.
  - Given the gate command in [`bcs.0.llms.md`](bcs.0.llms.md), when it runs on the landing, then it reports
    STATUS: PASS across all ten gates.
  - Encodes BCS.0-INV2, BCS.0-INV4, BCS.0-INV5. Priority: must · Size: 2 · Implements: BCS.0-D3, BCS.0-D4.
- **BCS.0-US3 — The authoring agent.** As a chapter-authoring agent, I want a shipped design exemplar and a
  recorded identity boundary, so that B1–B8 pages copy a real page instead of re-deriving a design.
  - Given the landing ships, when an agent reads it with [`bcs.0.llms.md`](bcs.0.llms.md), then the tokens,
    chrome, and evidence styling are copyable verbatim and the MUST-NOT boundary is explicit.
  - Encodes BCS.0-INV6. Priority: must · Size: 1 · Implements: BCS.0-D1.

Coverage: D1→US1,US3 · D2→US1 · D3→US2 · D4→US2.

## Definition of Done

- [ ] `../markdown/index.md` authored first; `html/bcs/index.html` mirrors it.
- [ ] All ten gates PASS via the exact command in [`bcs.0.llms.md`](bcs.0.llms.md).
- [ ] `GOWORK=off go build` clean at the root; `go vet` clean; `gofmt` applied.
- [ ] Server starts; `/bcs` 200; `/bcs/nope` 404; `/healthz`, `/echomq`, `/redis-patterns`, `/elixir` 200.
- [ ] Adversarial greps clean: `/future`, voice words, storage tokens, clamp spacing, `href="/"`.
- [ ] Stamp round-trips: `cms stamp decode` on the page's `BCS…` id.
- [ ] No manuscript file, ledger, shared asset, or sibling-course file touched. No git commands run.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.0.md
