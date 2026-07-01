# aaw.specs-approach.md — the spec-triad authoring contract

> Part of the **AAW framework** canon. The contract every spec **rung** is authored to and gated against, across
> every AAW program (the echo_mq bus, the bot, graft, the courses, Mercury). It defines the **artifact set**, the
> **exact template** for each artifact, the **six quality gates**, and the **completion rule**. It is the
> *how-to-write-a-spec* sibling of the workflow definition [`aaw.framework.md`](aaw.framework.md) (the theory:
> roles, rungs, the four artifacts) and the architect's method [`aaw.architect-approach.md`](aaw.architect-approach.md)
> (forks + the contract set). The framework says *what* the artifacts are; this says *exactly how each is shaped
> and proven*. Authored second, from the practice that shipped first.

## What a spec chapter is made of (the artifact set)

A **chapter** is a ladder of rungs under `docs/<program>/specs/`. It carries (AAW's four artifacts +
[`aaw.framework.md`](aaw.framework.md) §"the four artifacts"):

| Artifact | File | Answers | Commitment it carries |
|---|---|---|---|
| **Index** | `<chapter>.md` | the map of the ladder | the **value ladder** (a row per rung), the **master invariant**, the **closed error set**, the architecture decision every rung inherits |
| **Roadmap** | `<chapter>.roadmap.md` | what ships, and in what order | the milestone arc + per-iteration rows (**Ships · Demo · Harness · Feedback**); defines no behaviour, re-planned freely |
| **Spec** | `<rung>.md` | what we build & how we know it is right — **authoritative** | the **invariants** and the **Definition of Done** (completion is a closure over traced, executed checks) |
| **Stories** | `<rung>.stories.md` | what the user gets | the **acceptance** (Given/When/Then) + the **Coverage** line — every deliverable realized by a story a person signs |
| **Brief** | `<rung>.llms.md` | how the agent builds it | **traced requirements** + a prompt that ends in its own verification gates |

The **spec · stories · brief move together as the triad** — stories and brief DERIVE from the spec body, so they
cannot silently disagree with it (when a derived artifact disagrees, **the body wins**). The **roadmap sits
outside** the triad and decides which rung it is for. An optional **prompt runbook** (`<rung>.prompt.md`) is the
Director's orchestration brief — the persistent design pack that fixes a rung's design durably; when it exists,
the `.llms.md` comprehensive prompt **points to it, never duplicates it**.

## The templates

### `<chapter>.md` — the index
The chapter's value ladder: one row per rung (`<rung>` · Ships · the deliverable arc), the **master invariant**
(the one property every rung holds), the **closed error set** (the fixed vocabulary of failure reasons — a rung
adds no new reason), and the architecture decision the rungs inherit.

### `<chapter>.roadmap.md` — the roadmap
The milestone arc and the per-iteration rows. Each iteration row names the rung's **Ships / Demo / Harness /
Feedback**. The roadmap is re-planned freely and defines no behaviour.

### `<rung>.md` — the spec body (authoritative)
**Exactly six `##` sections, in order:**

1. **Goal** — one paragraph: the increment, in value terms.
2. **Rationale (5W)** — **exactly five bold bullets**: **Why** · **What** · **Who** · **When** · **Where**.
3. **Scope** — **In** / **Out** (what this rung does and explicitly does not).
4. **Deliverables** — `<rung>-D#`, each a provable unit.
5. **Invariants** — `<rung>-INV#`, each a **runnable check**, not prose (a property a gate exercises).
6. **Definition of Done** — `- [ ]` checkboxes, each closing over a story or an invariant.

Footer line: `Stories: <rung>.stories.md  ·  Agent brief: <rung>.llms.md  ·  Index: <chapter>.md  ·  Approach:
<relative path to this file>`.

### `<rung>.stories.md` — acceptance (Specification by Example)
Connextra stories, one per deliverable: `## <rung>-US#` → *As a `<role>`, I want `<capability>`, so that
`<benefit>`* (value, not a task; a concrete role). Each story carries:

- **Acceptance criteria** — concrete **Given / When / Then** (name the observable, never "works correctly").
- an **INVEST** line ending `encodes <rung>-INV#.` (the invariant(s) the story exercises).
- a `Priority: … · Size: … · Implements deliverables: <rung>-D#.` line.

Close with the **Coverage line**: `Coverage: D1→US# · D2→US# · …  Spec: <rung>.md · Agent brief: <rung>.llms.md.`
— so completion is provable from the text alone. **A gate must specify its own liveness** — a no-op must not
satisfy its letter (a present precondition runs it with a positive proof; an absent one under an opt-in is a
LOUD failure, never a silent skip-or-pass).

### `<rung>.llms.md` — the agent brief
The section order:

- `## References` — the exact upstream the builder reads first (links/paths first); cap the required reading.
- `## Requirements` — `<rung>-R#`, each ending `[US: <rung>-US#]` (traced back to a story).
- `## Execution topology` — a **runtime** fenced block + a **tasks** (build-order DAG) fenced block + a
  `Touched files:` line (the exact files, so the builder assembles a system, not a pile of snippets).
- `## Agent stories` — `<rung>-AS#` `[implements <rung>-US#]`, each a **Directive** (what to build) + an
  **Acceptance gate** (the check that closes it), stated as precondition / postcondition / invariant.
- `## Execution plan — first two stories` — the write-ready opening so the builder's first actions are writes.
- `## Comprehensive implementation prompt` — a fenced block leaving no decision the spec has not fixed (or a
  pointer to the `<rung>.prompt.md` pack).

### `<rung>.prompt.md` — the runbook (optional)
The Director's orchestration brief: the stages, the formation, the gate. When present it is the source of truth
for the rung's Deliverables, and the triad points to it rather than restating it.

## The six quality gates

A triad ships only when all six are green. Each is a **deterministic** check (a Python sweep is cleanest — it
counts fences and resolves links without shell-quoting hazards):

1. **Voice** — no `\b(just|simply|obviously|effortless|magical|revolutionary|blazing[ -]?fast)\b`; first person
   only in the stories' Connextra "I want"; **no perceptual or interior-state verb on a software component** (a
   lock / worker / token does not "see" / "want" / "know" / "decide", pronoun subjects `it`/`they` included).
   **Strip the story-id tokens first** (`[US:…]`, `<rung>-US#`, `-US#`) — `\bus\b` collides with the `US` id
   prefix and false-positives the first-person check.
2. **Structure** — `<rung>.md` has **exactly 6 `## ` sections** and **exactly 5** `^- \*\*(Why|What|Who|When|Where)\*\*`
   bullets; the DoD is `- [ ]` checkboxes; Scope has In / Out.
3. **Traceability** — the Coverage line is present; every `INV#` is `encodes`-named by ≥1 story; every `R#`
   carries `[US:]`; every `AS#` carries `[implements]`. **Flatten whitespace before EVERY trace check**
   (`re.sub(r'\s+',' ',text)`) — the wrap gotcha hits `encodes <rung>-INV#`, `[US: …]`, and `[implements …]`,
   which routinely wrap to a bullet's last line, so a single-line regex false-negatives all three.
4. **Fences** — the triple-backtick code-fence markers balance to an **even count** per file; never nested at
   the same backtick length.
5. **Links** — every relative `](…)` resolves on disk. Link only the rung's own `<rung>.*` siblings,
   `<chapter>.md`, this approach doc, and real external URLs; **do NOT link a concurrent-wave sibling rung**
   (reference it by id — the orchestrator links it after the fan-out).
6. **Format** — the footer line matches the exemplar's; the id schemes hold (`<rung>-D#` / `-INV#` / `-US#` /
   `-R#` / `-AS#`); a new triad copies the **exemplar's section order, footer, and id scheme EXACTLY**, changing
   only the rung id and the content.

## The completion rule

**Done is a closure over checks, not a feeling.** A rung is complete iff every Deliverable is named in the
Coverage line, every Requirement carries `[US:]`, every Agent story carries `[implements]`, every Invariant is
encoded by a story, and the DoD checkboxes each close over a story or an invariant whose gate **actually runs**.
There is no behaviour in the rung not pinned by a story's acceptance or an invariant. **Ground in REAL
artifacts** — cite a real file / module / function (verified to exist); a rung's own future modules are written
**forward-looking** (`<rung> builds <Module>`), never asserted present.

## Course-chapter mode (when the rung is a course chapter, not a code rung)

The same three files and the same six-section / five-bullet structure apply, but three sections bind to **pages**:
**Deliverables = pages** (the chapter landing, each module hub, each dive, the home/TOC relink); **Invariants =
properties of the pages** (the master invariant holds in the PROSE; no-invention with verified citations; the
page anatomy + the program's cms gates pass); **Execution topology = the page-authoring DAG** (landing → hubs →
dives → relink/TOC-sync) with a `Touched files:` line spanning the built pages and the route-mirror sources. The
footer gains a **Roadmap** segment, since the grounding contract lives in the roadmap.

## Map

- The workflow definition (roles · rungs · the four artifacts · the loop): [`aaw.framework.md`](aaw.framework.md).
- The architect's two instruments (forks + the contract set): [`aaw.architect-approach.md`](aaw.architect-approach.md).
- The normative rules: [`aaw.rules.md`](aaw.rules.md).
- The consumers of this contract: the `/spec-write` orchestrator + the `spec-author` fan-out agent (apply these
  templates); `venus` / `venus-mercury` / `echo-mq-architect` (author + reconcile triads to these gates).
