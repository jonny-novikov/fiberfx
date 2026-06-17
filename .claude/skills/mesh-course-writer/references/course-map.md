# EchoMesh, In Depth course map — chapters, routes, status, and the resume point

The map of *EchoMesh, In Depth* (served at `/mesh`), kept in sync with
[`docs/echo/mesh/mesh.toc.md`](../../../../docs/echo/mesh/mesh.toc.md) (the authoritative TOC — where this file and the
TOC disagree, the TOC wins). The course is the **senior successor to the EchoMesh chapters (A8–A9) of `/art`**: a
landing, the M0 overview, and chapters M1–M8 mapping the CAP literature and the EchoMesh stack. Each chapter is a
**landing + three dives** (two file levels), beside the course landing.

## The chapter table

| Page | Route | Theme | Dives | Status |
|---|---|---|---|---|
| **Landing** | `/mesh` | CAP is a menu; segment the trade | — (the front page) | **✓ built** — `html/mesh/index.html`, the **design exemplar** (the `.htabs` component + the CAP-spectrum signature) |
| **M0** Overview | `/mesh/overview` | CAP as safety vs liveness; the menu | `the-impossible` · `the-menu` · `the-mesh` | ✓ built (landing + 3 dives, served) |
| **M1** Doing the Impossible | `/mesh/impossible` | the proof, the menu not the wall | `safety-and-liveness` · `the-proof` · `the-menu-not-the-wall` | ✓ built (landing + 3 dives, served) |
| **M2** Best Effort Availability | `/mesh/best-effort-availability` | consistency-first | `consistency-first` · `single-writer` · `the-ledger` | ✓ built (landing + 3 dives, served) |
| **M3** Best Effort Consistency | `/mesh/best-effort-consistency` | availability-first | `availability-first` · `market-data` · `streams-and-edge` | ✓ built (landing + 3 dives, served) |
| **M4** Trading | `/mesh/trading` | the staleness dial | `continuous-consistency` · `staleness-budget` · `neither-on-purpose` | ✓ built (landing + 3 dives, served) |
| **M5** Segmenting — the heart | `/mesh/segmenting` | the dominant strategy | `dominant-strategy` · `five-dimensions` · `branded-seam` | ✓ built (landing + 3 dives, served) — **the heart** |
| **M6** The Stack | `/mesh/stack` | surfaces on the trade | `beam` · `cache-bus-streams` · `tigris-postgres` | ✓ built (landing + 3 dives, served) |
| **M7** Transparent Infrastructure | `/mesh/transparent` | same code everywhere | `same-code` · `ephemeral-machines` · `placement` | ✓ built (landing + 3 dives, served) |
| **M8** The Future Is Now | `/mesh/future` | the synthesis + the bridge | `whole-picture` · `real-and-proposed` · `meet-echomesh` | ✓ built (landing + 3 dives, served) — **the synthesis** |

The landing teaches `mesh.landing.md`; M0 teaches `mesh.0.md` (dives `mesh.0.[1-3].md`); `M[N]` teaches
`mesh.[N].md` (dives `mesh.[N].[D].md`). M0's three dives sit under `/mesh/overview/<dive>`; M1–M8's under
`/mesh/<chapter>/<dive>`. **M5 · Segmenting is the heart; M8 · The Future Is Now is the synthesis and the bridge.**

## The identity (fixed by the exemplar)

- Exemplar page: `html/mesh/index.html` — the **CAP contract-sheet** identity: the /bcs contract-sheet BASIS (warm
  paper, mono-forward, numbered sections, frozen evidence) carried into a violet-led, CAP-duality surface. Copy its
  head/header/footer/scripts (incl. the `.htabs` component JS); change only `<title>`/`<meta>`, the route-tag, `<main>`.
- Tokens: `--m-paper`/`--m-card`/`--m-ink`/`--m-dim`/`--m-line` (the /bcs basis) + accents `--m-mesh` (EchoMesh violet,
  house lead) / `--m-cons` (consistency-first blue) / `--m-avail` (availability-first green) / `--m-edge` (staleness/
  edge amber). System font stacks only. Nothing fetched.
- Devices: the **CAP-spectrum rule** (`.caprule`), the **`.htabs` hover-to-switch tab component** (the signature
  primitive — concept schemas, the stack surfaces, health/recovery/partition emulators), `.sech` headers,
  `figure.frozen` evidence, the rich `.door` blocks, the **"Proposed · not shipped"** note.
- Stamp namespace: **`MSH`** (`apps/jonnify-cms/bin/cms stamp mint --ns MSH`). Exemplar stamp minted per build.
- MUST NOT: dark-editorial navy/cream/gold, Cormorant Garamond / PT Serif / Manrope, `.chap`/`.mods`/`.mod`; and MUST
  NOT clone the `/bcs` `--b-*` tokens verbatim.

## The resume point

**The landing is the course's design exemplar.** `/mesh` (`html/mesh/index.html`) is the first MESH page and the
bootstrap every later surface copies. It carries the thesis, the **four-strategies-on-the-CAP-spectrum** signature
(`.htabs` + an SVG spectrum), the **stack `.htabs`**, the chapter map M0–M8, the rich doors, and References — STATUS:
PASS on all ten gates. Its grounding is `mesh.landing.md` / `mesh.0.md` and the cited CAP literature + stack sources;
EchoMesh named as a forward concept ("Proposed · not shipped").

**Built and served so far:** the landing, **M0 · Overview**, and chapters **M1–M8** — each a landing and its three
dives — thirty-seven pages, A+ on all ten gates, in the violet-led CAP contract-sheet identity with the `.htabs`
component and partition/recovery emulators. **The course is complete: every chapter M0–M8 is built and served.**

**Next buildable:** none — the course is fully built. M8 · The Future Is Now (`/mesh/future` + the three dives
`whole-picture`/`real-and-proposed`/`meet-echomesh`) shipped as the synthesis: a journey signature interactive
(`/redis-patterns → /echomq → /bcs → /art → /mesh`, each step adding capability without a new external dependency) and
the transparent architecture revealed as three pillars — the BEAM single-writer runtime read in the LMAX sense,
self-healing supervision with journal replay, and the Valkey / Postgres / SQLite-journal-to-Tigris storage tier. Any
further work is extension (e.g. tidying the M2–M4 chapter-landing pagers/footers), not a missing chapter.

**Forward status:** EchoMesh is a PROPOSED concept — its pieces (the BEAM, EchoCache, the EchoMQ bus and streams,
Tigris, Postgres/`Ecto.Multi`, FLAME, Fly Machines) are real and shipped; their composition into the mesh is the
proposed design. Every page carries a "Proposed · not shipped" note where it leans on the mesh, and never asserts a
shipped mesh figure.
