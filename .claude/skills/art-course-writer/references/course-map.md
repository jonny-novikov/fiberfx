# The Art of BCS course map — chapters, routes, status, and the resume point

The A0–A10 ladder of *The Art of BCS* (served at `/art`), kept in sync with
[`docs/echo/art/art.toc.md`](../../../../docs/echo/art/art.toc.md) (the authoritative TOC — where this file and the
TOC disagree, the TOC wins). The course is the **senior continuation of `/bcs`**: eleven chapters mapping the
manuscript's Prelude, Preface, and ten Parts. Each chapter is a **landing + three dives** (two file levels; **A9 ·
EchoMesh in Depth is the lone two-dive chapter**) — eleven landings and thirty-two dives at completion.

## The chapter table

| Chapter | Route | Theme (manuscript Part) | Dives | Status |
|---|---|---|---|---|
| **A0** Orientation | `/art` | the credo, the runtime, the map | `credo` · `runtime` · `map` | **◐ building this batch** — landing served (the **design exemplar**); 3 dives authored from `art01.md`–`art03.md` |
| **A1** The Thesis | `/art/thesis` | Part I — the runtime is the platform | `the-constellation` · `the-primitives` · `identity-across-boundaries` | **◐ building this batch** — manuscript authored in full (`art1.md` + `art11.md`–`art13.md`); landing + 3 dives authored |
| **A2** No Coordinator | `/art/no-coordinator` | Part II — ZooKeeper subsumed | `coordinator-role` · `coordination-in-the-runtime` · `exchange-no-coordinator` | ○ manuscript pending |
| **A3** No Log Broker | `/art/no-log-broker` | Part III — Kafka subsumed | `log-broker-role` · `the-three-shapes` · `exchange-log` (+ `the-named-exit`) | ○ manuscript pending |
| **A4** No Message Broker | `/art/no-message-broker` | Part IV — ActiveMQ/Artemis subsumed | `broker-role` · `lanes-as-the-broker` · `coherence-not-a-broker` (+ `artemis-on-its-merits`) | ○ manuscript pending |
| **A5** No Orchestrator | `/art/no-orchestrator` | Part V — Kubernetes subsumed | `orchestrator-role` · `runtime-and-fly` · `flame` (+ `go-workers-ephemeral`) | ○ manuscript pending |
| **A6** The Hot Path | `/art/hot-path` | Part VI — LMAX on the BEAM | `the-disruptor-seat` · `latency-by-construction` · `matching-core` (+ `strategies`) | ○ planned (**exemplar-backed** — `exchange.patterns.md` + shipped `Exchange.*` rungs `trd.1.1`, `trd.2.1`) |
| **A7** Durable & Regulated Edge | `/art/durable-edge` | Part VII — the line drawn | `journal-and-shadow` · `regulated-ledger` · `the-line` | ○ manuscript pending |
| **A8** Introducing EchoMesh | `/art/echomesh` | Part VIII — **introduces the heart** | `what-echomesh-is` · `topology-and-locality` · `mesh-edges-owned-engine` | ○ planned (**PROPOSED concept** — forward-looking voice; venue/Go tier preserved as first edge nodes `trd.9`, `trd.9.1`) |
| **A9** EchoMesh in Depth | `/art/echomesh-depth` | Part IX — **CAP/PACELC depth** (2nd half of the heart) | `pacelc-design` · `under-the-hood` (**2 dives**) | ○ planned (**PROPOSED** — landing + both dives authored w/ interactive emulators; grounded in `art.cap.md` + `art.references.md`) |
| **A10** The Whole Picture | `/art/whole-picture` | Part X — and the bridge | `the-deployment` · `constellation-absent` · `candid-ledger` | ○ manuscript pending |

A chapter maps one-to-one to a manuscript chapter: `A[N]` teaches `docs/echo/art/art<N>.md`; its dive `A[N].[D]`
teaches `art<N><D>.md`. A0 is the course landing itself; A0's three dives (`credo`/`runtime`/`map`) are leaf files at
the course root (`/art/<slug>` → `<slug>.html`, teaching `art01.md`/`art02.md`/`art03.md`). A1–A10's dives sit under
the chapter dir.

## The identity (fixed by the exemplar)

- Exemplar page: `html/art/index.html` — the **architect's-blueprint** adaptation of the contract-sheet system. Copy
  its head/header/footer/scripts; change only `<title>`/`<meta>`, the route-tag, and `<main>`.
- Tokens: `--a-paper` (cool blueprint paper) `/--a-card/--a-ink/--a-dim/--a-line` + themed hues `--a-arc` (architect
  indigo, the house lead) `/--a-avail` (availability green) `/--a-mesh` (EchoMesh violet) `/--a-edge` (edge amber);
  evidence on `--a-term-bg`. System font stacks only (`--mono` mono-forward, `--sans` body). Nothing fetched.
- Devices: the **nines-rule** (`.ninerule`), the borrowed-availability **calculator** figure, the constellation-
  subsumed lookup, `.sech` numbered section headers, `figure.frozen` evidence blocks, the rich `.door` course-to-
  course reference blocks.
- Stamp namespace: **`ART`** (`apps/jonnify-cms/bin/cms stamp mint --ns ART`). Exemplar stamp minted per build.
- MUST NOT: dark-editorial navy/cream/gold, Cormorant Garamond / PT Serif / Manrope, `.chap`/`.mods`/`.mod`; and MUST
  NOT clone the `/bcs` warm `--b-*` oxide-red tokens verbatim.

## The resume point

**A0 · Orientation and A1 · The Thesis are built this batch.** The A0 landing (`html/art/index.html`) remains the
course's **design exemplar** — the thesis, the **borrowed-availability calculator** (the `a^N` ceiling made live), the
**constellation-subsumed** lookup, the A0–A10 chapter map ending at EchoMesh, the rich doors, References, STATUS: PASS.
Built on top of it this batch: A0's three dives (`credo`/`runtime`/`map`, served at `/art/<slug>`, teaching
`art01.md`–`art03.md`) and the **A1 chapter** (landing `/art/thesis` + the three dives
`the-constellation`/`the-primitives`/`identity-across-boundaries`, teaching `art1.md` + `art11.md`–`art13.md`). The
first built dive becomes the **dive exemplar** later dives copy. Every figure verbatim from the manuscript chapter or
its cited source (AWS SLA, Armstrong's thesis & history, the BEAM Book, Programming Erlang, the Twitter Snowflake
announcement, Kafka KRaft, Kubernetes); EchoMesh named as a forward concept.

**Next buildable:** the **A2–A9 chapter landings** — their landing manuscripts (`art2.md`–`art9.md`) are authored, so
each landing ships with its dives as `soon` cards. The **heart pair** is furthest along: **A8 · Introducing EchoMesh**
(`/art/echomesh`) and **A9 · EchoMesh in Depth** (`/art/echomesh-depth`) have landings rendered under
`docs/echo/art/html/`, and A9's two dives (`art91.md` PACELC + `art92.md` under-the-hood) are authored with interactive
emulators — author both chapters in **forward-looking voice**, grounded in `art.cap.md` + `art.references.md`. **A6 ·
The Hot Path** is exemplar-backed (`exchange.patterns.md` + shipped `Exchange.*` rungs `trd.1.1`, `trd.2.1`).

**Do NOT author ahead of the manuscript.** The dive articles under **A2–A8** are manuscript-pending (no
`art2X`–`art8X.md` yet) — build those chapters' landings only, dives `soon`. **A10 · The Whole Picture** is
manuscript-pending (landing too). **EchoMesh (A8 + A9) is a PROPOSED concept** — its pieces (the venue edge, the Go
tier) are real and shipped, their composition into the mesh is the proposed design; never assert a shipped mesh figure.
