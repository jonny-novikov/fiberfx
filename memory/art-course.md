---
name: art-course
description: "The /art \"The Art of BCS\" course — infra reframed to CAP-restructured TOC (A9=EchoMesh in Depth); A0+A1 built (8 pages, A+); senior continuation of /bcs"
project: echo
metadata: 
  node_type: memory
  type: project
  originSessionId: ebec5470-df3f-443c-b8b7-37d8e445e9df
---

**The Art of BCS** = the senior continuation of `/bcs`, served at `/art` (folder-routed via `serveDirTree`). The
architect's case for owning the runtime: the BEAM subsumes the constellation (coordinator/log-broker/message-broker/
orchestrator), the brand carries state across boundaries, built part-by-part to **EchoMesh** (a FORWARD CONCEPT — no
code yet; taught in proposed/living-status voice).

**Built this session (the meta-task):**
- Infrastructure trio (cloned from the [[bcs-course]] pattern, retargeted): skill `.claude/skills/art-course-writer/`
  (SKILL.md + references/course-map.md), agent `.claude/agents/art-expert.md` (the `-expert` family naming, NOT
  "art-course-writer" for the agent), command `.claude/commands/art-write.md`.
- Landing `html/art/index.html` — STATUS: PASS A+ on all ten jonnify-cms gates. Route-mirror md
  `docs/echo/art/markdown/index.md`.
- Wired: `main.go` (artDir var + ART_DIR env + 2 app.Get + log line, mirrors the /fsharp precedent), `Dockerfile`
  (COPY html/art/), `Makefile` (ART_DIR var + start/run + help echo). Build verified `GOWORK=off go build`; server
  serves /art→200, /art/bad→404, traversal→404, /bcs unaffected.

**Identity = the architect's-blueprint adaptation of the BCS contract-sheet** (NOT dark-editorial, NOT the warm
oxide-red `--b-*` cloned verbatim): cool blueprint paper `--a-paper`, house lead `--a-arc` (architect indigo),
`--a-avail` (green), `--a-mesh` (EchoMesh violet), `--a-edge` (amber). Devices: `.ninerule` (vs BCS `.idrule`), the
**borrowed-availability calculator** (`a^N` ceiling, the signature interactive) + the **constellation-subsumed**
lookup, rich `.door` course-to-course blocks. Stamp namespace `ART` (`cms stamp mint --ns ART`).

**Grounding rule (the new-vs-BCS bit):** figures are DERIVED arithmetic (the `a^N` ceiling) + cited primary sources
(AWS SLA 99.99%/99.5%, Armstrong thesis AXD301 nine-nines *with caveat*, Kafka KRaft, Kubernetes, FLAME), never
fabricated. Gotcha caught this session: seven nines = ~3 **s**/year (1e-7×525600), NOT 3 min (that's five nines).

**Structure:** two levels — chapter `A[N]` landing (`art[N].md`) + **three dives** (`art[N][D].md`); A0 is the course
root, its dives are leaf files. Chapters A0–A10, slugs thesis/no-coordinator/no-log-broker/no-message-broker/
no-orchestrator/hot-path/durable-edge/echomesh/**echomesh-depth**/whole-picture. **2026-06-15 restructure: A9 was
"Observability" → now A9 · EchoMesh in Depth (CAP/PACELC; the 2nd half of the A8→A9 heart pair; the lone 2-dive
chapter → 32 dives total).** New "source author's materials" `art.cap.md` (CAP/PACELC theory) + `art.references.md`
(25 distributed-systems papers: Gilbert-Lynch CAP, FLP, Paxos, Yu-Vahdat) ground A8/A9. Gate
`--chapter-alias …,a8=echomesh,a9=echomesh-depth,a10=whole-picture` (NOT a9=observability).

**A0+A1 SHIPPED 2026-06-15** (8 pages A+, all live 200): A0 landing + dives `/art/credo`·`/art/runtime`·`/art/map`; A1
landing `/art/thesis` + `the-constellation`·`the-primitives`·`identity-across-boundaries`. **Fan-out pattern that
worked:** orchestrator authors the chapter landings (shared manifest surfaces); fan out `art-expert` per dive in
**waves of 2 in REVERSE-chain order** so each dive's `prev` resolves at its own gate time (forward `next` = a `soon`
span the orchestrator flips to a link in the relink pass — the `links` gate validates anchors against files on disk via
`SectionRoutes`). **svg gate is MANDATORY** — every page needs an inline `<svg role=img aria-label>` (make ≥1 of the
≥2 interactives an SVG). **A9-reconcile:** `art03.md` (the Map manuscript) still said "A9 Observability" — authored to
the TOC's "EchoMesh in Depth" instead (TOC wins for structure; the read-only manuscript lags). **A2–A9 chapter landings SHIPPED 2026-06-15** (7 of 8, A+, all live 200: no-coordinator/no-log-broker/
no-message-broker/no-orchestrator/hot-path/echomesh/echomesh-depth) — chapter landings fanned out one `art-expert` each
(distinct files = no parallel-write conflict, so fan-out is safe despite the command's "orchestrator authors landings"
default) in waves of 2; **hub pager** (prev→/art, next→first-dive-`soon`) needs ZERO chain finalize; A8+A9 forward-voice
with a "Proposed · not shipped" banner; A9 = exactly 2 dive cards. **A7 BLOCKED — `art7.md` is ABSENT** (the TOC is ahead
of the book; do NOT author A7 until `art7.md` lands). **Resume = the dives under A2–A6/A8/A9** (need `art2X`–`art8X.md`;
only A9's `art91`/`art92.md` exist) + the A7 + A10 landings once their manuscripts land. **Operator authors the
manuscript out-of-band** (`art.cap.md` appeared then vanished mid-run); never edit `docs/echo/art/art*.md` UNLESS the
user explicitly grants it (they did once, to reconcile `art03.md`'s stale "A9 Observability" → "EchoMesh in Depth"),
only `art.toc.md` + `markdown/`. The `art-expert` agent **`description:` frontmatter edit is blocked by the auto-mode
self-modification classifier UNTIL the user explicitly authorizes it** (body edits always pass; with a grant the
frontmatter edit goes through). See [[user-commits-elixir-batches]].
