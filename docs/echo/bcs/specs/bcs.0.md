# BCS.0 · Orientation — the landing, and the door into the course

> The first rung of the BCS course: the `/bcs` landing built as the course's **design exemplar** (the new visual
> identity is defined here and copied everywhere after), and the route wired into the jonnify Fiber server —
> built, started, verified. Spec of record: [`bcs.0.specs.md`](bcs.0.specs.md) · agent guide:
> [`bcs.0.llms.md`](bcs.0.llms.md).

## Why

The course exists as specs ([`../bcs.md`](../bcs.md), [`../bcs.toc.md`](../bcs.toc.md),
[`../bcs.roadmap.md`](../bcs.roadmap.md)) but not as a single served page. Until `/bcs` resolves, there is no
door: nothing to link from the sibling courses, no design system for chapter authoring to copy, and no proof the
wiring pattern holds for a tenth folder-routed section. B0 ships the smallest faithful slice — one page, one
route — and, because the course renders in its own visual identity, that one page carries the largest design
decision the course makes. The exemplar must exist before any fan-out, for the same reason the manuscript built
`bcs1.1` first: the smallest faithful form settles the conventions everything later copies.

## What

Two deliverable surfaces and their proof:

1. **The landing** — `html/bcs/index.html`, the B0 orientation page: the law in three clauses (a triptych), the
   14-byte id dissected (the anchor motif, as an interactive SVG), the frozen-evidence ethic (figures quoted
   verbatim in transcript-styled blocks), the B1–B8 chapter map (unbuilt chapters as non-anchor `soon` cards),
   doors to `/echomq` and `/redis-patterns`, a two-column References block, and the canonical chrome — clickable
   route-tag, 3-column footer, a **`BCS…`** build stamp with its decoder. Authored md-first
   (`../markdown/index.md`).
2. **The wiring** — the `/bcs` + `/bcs/*` routes in `main.go` via the shared `serveDirTree` (env-overridable
   `BCS_DIR`, default `/app/html/bcs`), the `Makefile` dev env, and the `Dockerfile` `COPY` — the identical
   five-line pattern every folder-routed course uses, minus the deferred seams recorded in the
   [roadmap](../bcs.roadmap.md).

Proof is mechanical: the ten jonnify-cms gates at STATUS: PASS (with `--require-refs`), a clean root build, and a
live crawl on the local server.

## Who

- **The reader** arriving from a sibling course or a direct link: orientation in one page — what the law is, what
  the id is, what evidence backs the series, where the course goes next.
- **The Operator** reviewing the rung: the design identity decision made concrete and reversible (one page, no
  shared-asset changes).
- **The authoring agents** that build B1–B8 later: the landing is the page they copy their design system from;
  [`bcs.0.llms.md`](bcs.0.llms.md) is their brief.

## When

After the course docs (this rung's triad is authored against them) and before any chapter triad or chapter page.
B1 authoring is blocked on this rung: without the exemplar there is no design system to copy.

## Where

- `html/bcs/index.html` + `docs/echo/bcs/markdown/index.md` — the page and its md mirror.
- `main.go` · `Makefile` · `Dockerfile` — the wiring (the exact touchpoints are in
  [`bcs.0.specs.md`](bcs.0.specs.md)).
- Grounding read from [`../content/`](../content/bcs.toc.md): the preface, `bcs1.md`, the contract, the connector
  appendix — per the [roadmap grounding map](../bcs.roadmap.md).

## How

Senior-authored, not fanned out: the orchestrator writes the md mirror, designs and writes the landing, wires the
server, and runs the verification sequence end to end (build → gates → start → crawl). The design follows the
brief in [`bcs.0.specs.md`](bcs.0.specs.md); the gate matrix there is the mechanical contract. No git commands;
the Operator commits out-of-band.

## Decisions

- **D-B0.1 — The course stamps in its own namespace.** Build stamps are `BCS…` ids
  (`cms stamp mint --ns BCS`), not `TSK…` — the D-8 rule applied to the course itself. The decoder panel renders
  the same fields (namespace, snowflake, node, seq, timestamp).
- **D-B0.2 — Full links PASS.** Unbuilt chapters are non-anchor `soon` cards. The sibling courses' route-manifest
  homes fail the `links` gate by design; B0 inverts that, so every gate is green from the first page.
- **D-B0.3 — No external requests.** The landing is one self-contained file: inline CSS and JS, **system font
  stacks** (monospace-forward), no CDN fonts, no KaTeX, no third-party assets. The identity differentiates from
  dark-editorial partly by this: nothing is fetched.
- **D-B0.4 — Deferred seams.** `html/llms.txt`, the root-hub card, and the `cmd/sitemap` `folderRouted` slice are
  not touched (the sibling-course precedent, recorded in the [roadmap](../bcs.roadmap.md)).

## Boundaries

This rung builds one page and one route. It does not author any chapter page, does not edit the manuscript or its
ledger (D-7), does not touch shared assets or other courses' files, and does not deploy (the Dockerfile line
ships on the next manual `fly deploy`).

## Companion files

[`bcs.0.specs.md`](bcs.0.specs.md) (the spec of record) · [`bcs.0.llms.md`](bcs.0.llms.md) (the agent guide) ·
the course docs ([`../bcs.md`](../bcs.md) · [`../bcs.toc.md`](../bcs.toc.md) ·
[`../bcs.roadmap.md`](../bcs.roadmap.md)) · the manuscript front matter
([`../content/bcs.preface.md`](../content/bcs.preface.md) · [`../content/bcs1.md`](../content/bcs1.md) ·
[`../content/contract.md`](../content/contract.md)).

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Manuscript: ../content/bcs.toc.md
