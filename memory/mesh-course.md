---
name: mesh-course
description: "The /mesh \"EchoMesh, In Depth\" course — mesh-* toolkit (agent/skill/command) + .htabs hover-tab component + M0–M8 built (37 pages A+, COMPLETE); senior successor to /art's EchoMesh chapters"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7b361dbb-8878-4b94-9753-702a821b1f1c
---

**EchoMesh, In Depth** = the `/mesh` course (folder-routed via `serveDirTree`), the **senior successor to /art's EchoMesh
chapters (A8–A9)**. Teaches the **CAP theorem as a menu, not a wall**: EchoMesh **SEGMENTS** the consistency/availability
trade across a Branded Component System stack on the BEAM (matching+ledger consistency-first; market-data+retention
availability-first; a staleness budget the dial), then makes infrastructure transparent (FLAME, Fly Machines, placeless
placement). **EchoMesh is PROPOSED** — its pieces real and shipped, their composition into the mesh the proposed design;
forward-status discipline + a visible "Proposed · not shipped" note.

**Toolkit SHIPPED 2026-06-15** (cloned from the [[art-course]] pattern, retargeted): skill
`.claude/skills/mesh-course-writer/` (SKILL.md + references/course-map.md), agent `.claude/agents/mesh-expert.md`,
command `.claude/commands/mesh-write.md`. Stamp namespace **MSH**. Gate `--routes-from /mesh=html/mesh
--chapter-alias m0=overview,m1=impossible,m2=best-effort-availability,m3=best-effort-consistency,m4=trading,m5=segmenting,m6=stack,m7=transparent,m8=future --require-refs`.

**Identity = the /bcs contract-sheet BASIS** (warm paper #f6f3ec, mono-forward, `.sech` numbered sections, frozen
evidence) carried into its OWN **violet-led CAP-duality surface** (user-approved palette): `--m-mesh` #7b3aa0 (house
lead, EchoMesh violet) / `--m-cons` #2a5b8f (consistency-first, blue) / `--m-avail` #1f7a5e (availability-first, green) /
`--m-edge` #b3631c (staleness/edge, amber). **The CAP trade is made VISIBLE (blue↔green) on every page.** Devices:
`.caprule` (CAP-spectrum rule), the **`.htabs` hover-to-switch tab component** (THE signature primitive — the user's key
ask: hover/focus switches, click pins, restores on mouseleave, **degrades to all-panels-visible without JS**; the /bcs
id-anatomy hover generalized), the "Proposed · not shipped" note. NEVER dark-editorial; NEVER the /bcs `--b-*` tokens
verbatim.

**Built 2026-06-15 (e2e test — 9 pages A+, all live 200):** landing `html/mesh/index.html` (the design **exemplar**,
orchestrator-authored) + **M0 overview** `/mesh/overview` (+3 dives `the-impossible`/`the-menu`/`the-mesh`) + **M1 ·
Doing the Impossible** `/mesh/impossible` (+3 dives `safety-and-liveness`/`the-proof`/`the-menu-not-the-wall`). The
**partition/recovery EMULATORS** (the user's ask) live on M1 (write→partition→read→forced-choice), M0.1 (register
emulator), M1.2 (5-step proof-walk), M1.3 (detect→partition-mode→recover). **Wired:** `main.go` (`meshDir` + `MESH_DIR`
+ 2 `app.Get`), Makefile (`MESH_DIR`), Dockerfile (`COPY html/mesh/`).

**Routing** (the TOC tally treats landing + M0 as SEPARATE pages): landing `/mesh` (`mesh.landing.md`), M0 overview
`/mesh/overview` (`mesh.0.md`), M1–M8 `/mesh/<slug>` (`mesh.[N].md`); dives under `<chapter>/<dive>`. Manuscript
`docs/echo/mesh/mesh.{landing,0..8,N.D}.md` — **all M0–M8 authored**. Grounding = CAP literature (Gilbert & Lynch
2002/2012, FLP 1985, Brewer 2012, PACELC) + the real stack (BEAM, EchoCache, EchoMQ, Tigris, Ecto.Multi, FLAME, Fly
Machines). md-first route-mirrors at `docs/echo/mesh/markdown/<route>.md`.

**Gotchas:** the **`mesh-expert` agent now dispatches** — all 12 M2–M4 pages were authored by it this session, no
`general-purpose` fallback. Keep briefs **self-contained** anyway (load the skill + copy a built MESH page) so a
fallback still works. **Emulator magnitudes must be qualitative (high/low/bounded) or carry a cited source — NO
invented %/SLA/latency labels** (caught + fixed on the M4 staleness dial: bar labels `85%`/`20%` → `high`/`low`, the
[RECONCILE]-style figure-provenance check the cms gates can't see). **Chapter dives cross-link in a cycle** (dive1→2,
2→3, 3→2), so a dive's `links` gate only greens once ALL THREE of its chapter's dives exist — fan out the dives, hold
the dangling sibling links, then run an authoritative **trio-gate** per chapter. The manuscript `mesh*.md` (incl.
`mesh.toc.md` bodies) is the **Author's, read-only**; the orchestrator syncs only the TOC **status legend**. Separate
from the [[mesh-live-svelte-specs]]/mercury work and the `anthropic-skills:mesh-writer` MANUSCRIPT skill (that authors
the .md; mesh-course-writer authors the HTML).

**M2–M4 built 2026-06-15** (12 pages, all A+ + live 200): landings `best-effort-availability` / `best-effort-consistency`
/ `trading` + their dives (consistency-first/single-writer/the-ledger · availability-first/market-data/streams-and-edge ·
continuous-consistency/staleness-budget/neither-on-purpose). Manifests relinked (course landing + 3 chapter landings,
cards + footers soon→read), TOC + course-map synced. Pager convention: a **chapter landing pages back to `/mesh`** (not
the prior chapter); dives 1&2 prev→chapter, dive3 prev→dive2 + next→back-to-chapter (a per-chapter loop, no cross-chapter
pager).

**M5–M7 built 2026-06-15** (12 pages, all A+ + live 200): landings `segmenting`/`stack`/`transparent` + their dives
(dominant-strategy/five-dimensions/branded-seam · beam/cache-bus-streams/tigris-postgres ·
same-code/ephemeral-machines/placement). Built via mesh-expert fan-out in 6 waves (landings first w/ `soon` dive cards,
then dives ≤2-concurrent holding dangling sibling pager-next links, then per-chapter trio-gate). Manifests relinked:
course-landing M5/M6/M7 cards+footer soon→read; each chapter landing's 3 dive cards soon→read + pager-next span→live
anchor + footer cross-links. TOC + course-map synced (M0/M1 headers also corrected ◐→✓ built — they were served but
mislabelled).

**M8 built 2026-06-15 — COURSE COMPLETE** (4 pages, all A+ + live 200): landing `/mesh/future` (orchestrator-authored,
carrying the **journey** signature interactive — `/redis-patterns → /echomq → /bcs → /art → /mesh`, each step adds
capability without a new external dependency, the user's "keeping it all together" thread) + dives
`whole-picture`/`real-and-proposed`/`meet-echomesh` via mesh-expert fan-out (2 then 1, trio-gate). The user granted
latitude ("your proposals can be reveals"), so the chapter REVEALS the transparent architecture as **3 pillars**: the
BEAM single-writer ledger read as **Martin Fowler's LMAX** (cite martinfowler.com/articles/lmax.html), **self-healing**
supervision + journal replay, and the storage tier **Valkey + Postgres + a SQLite WAL journal → Tigris recovery** (cite
sqlite.org/wal.html). Discipline held: pieces REAL, composition PROPOSED — the LMAX-reading and SQLite→Tigris path are
drawn on the real/proposed line in M8.2; qualitative magnitudes only (no fabricated LMAX throughput). 37 pages total;
course-landing + chapter-landing manifests relinked, TOC + course-map synced.

**Gotcha — the `no-future` cms gate collides with the M8 slug `future`.** It does a blunt
`strings.Contains(doc, "/future")` (guard against linking the Russian `/future` course), so EVERY `/mesh/future` link
tripped it — blocking the whole M8 chapter AND the relink of every mesh page to M8. Fixed in
`apps/jonnify-cms/internal/apollo/apollo.go` (`gateNoFuture` strips `/mesh/future` before scanning, so the bare
`/future` course is still caught) + spec `05-build-validate.md §6.3`; the apollo unit test stays green; **rebuild cms
after editing**. See [[user-commits-elixir-batches]].
