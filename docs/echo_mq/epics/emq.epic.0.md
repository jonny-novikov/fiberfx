# Epic EMQ0 · EchoMQ — AAW application & corpus

> **PROPOSED** — the meta-epic that introduces the **Epics & Corpus** layer to the AAW emq program: an
> organizing altitude *above the rung*, born from a concrete failure (a cross-cutting catalogue with nowhere to
> live). EchoMQ is the proof-of-concept; what works here folds back into the AAW framework canon
> ([aaw.framework.md](../../aaw/aaw.framework.md) · [aaw.rules.md](../../aaw/aaw.rules.md)).

## Scope

`emq` only — as the proof of a new AAW concept, chosen because its sophisticated implementation and long
roadmap (Movements I–III, rungs emq.0–emq.8, the 50-command v1 parity surface) are exactly the conditions that
expose the gap a per-rung structure cannot fill. **In scope:** the `epics/` layer, the `kb/` knowledge base, and
the memory model — for the emq program. **Out of scope:** rolling these to other programs (deferred until the
pattern proves here — D0-4), and the *physical* project-wide memory move (a separate, Operator-gated execution
step — see instrument 3).

## Rationale — the trigger and the values it serves

The trigger was concrete: the v1↔v3 command matrix (then `emq.1.specs.md`, since reorganized into the
feature-sorted [`../emq.command-registry.md`](./emq.epic.1/emq.commands.registry.md)) arrived as a **1290-line file** that
*either bloats an agent's context* (it must be loaded whole) *or misses crucial entries* (no structure forces
completeness). It had nowhere to live because the AAW **two-layer model** has no concept **above the rung**: the
rung is the atomic vertical slice, the roadmap sequences rungs, and a *cross-cutting corpus* (50 analogues
spanning every rung) is neither.

The matrix violated two of the framework's own values, at the documentation layer:

- **One authority** — "every fact has exactly one defining document." A 1290-line file co-mingles 50 command
  authorities in one place: a drift surface no one keeps coherent.
- **Thin but robust** — a thin slice is the unit of work; a monolith an agent must load whole is its opposite.

**Epics restore both.** An Epic is a thin *index* (the catalogue) over per-feature slices under a grammar, so an
agent loads *one feature*, never the monolith, and each command's v3 form is defined in exactly one place. The
disease is "no above-rung corpus layer"; the matrix's bloat was only the symptom. (The matrix itself is demoted
to a **development-supporting artifact** — not the catalogue; the catalogue is the forward-only v3.x DSL of
[emq.epic.1](./emq.epic.1.md).)

## The 5W

- **Why** — give cross-cutting corpora (command catalogues, knowledge, memory) a home, so an agent loads the
  slice it needs and every fact keeps one authority; end the monolith failure mode at the doc layer.
- **What** — three corpus instruments for the emq program: (1) the **`epics/`** layer (theme + owned
  catalogue), (2) the **`kb/`** knowledge base, (3) the **memory model** (repo-controlled, Director-owned).
- **Who** — the **Director** owns and maintains the corpus as the emq program leader (organizes the epics,
  curates the kb, updates the memory); agents read and cite it; the **Operator** decides its shape (this epic).
- **When** — now, after the program reached enough depth (the flow family + the 50-command parity surface) that
  the per-rung structure visibly overflowed, and before the v3.x command rewrite (emq.epic.1) needs its
  catalogue.
- **Where** — `docs/echo_mq/epics/` (the catalogues) · `docs/echo_mq/kb/` (the guides) · the
  repo-git-controlled memory symlinked from `~/.claude/projects/.../memory/` (observability).

## The decision matrix

| # | Decision | Ruling | Rationale |
|---|---|---|---|
| **D0-1** | An Epic's place in the AAW layer model | **Theme + owned corpus** — an Epic spans many rungs (e.g. the v3.x command DSL) and owns a catalogue: `emq.epic.N.md` (the index) + `emq.epic.N/` (the slices); the roadmap still sequences the rungs beneath it. | Mirrors `specs/` (triad + decomposition dir) one altitude up — the structure the program already trusts, applied to the corpus. Gives the matrix a home AND the rungs a parent. |
| **D0-2** | The DSL catalogue form (emq.epic.1) | **Per-feature md slices** — one md per feature (`groups`, `batches`, flows, locks, metrics, …), each holding its commands as `#{command}`-anchored sections, cross-referenced by those hashes within and across features. Fields per command: feature · decision · BCS · EchoMesh · use-cases · Given/When/Then in Elixir (→ [`../stories/`](../stories/)). | Forward-only — **no v1↔v3 matrix** (the old reference is a dev-support artifact). A *feature* is the unit a reader needs; the `#{command}` hash is the near-term DSL grammar (a queryable cross-reference, not a flat scroll). |
| **D0-3** | The Claude Memory Mind Model | **Repo-git-controlled memory, Director-owned** — the canonical memory lives in the repo (versioned, reviewable, durable, shared); `~/.claude/projects/.../memory/` becomes a **symlink** into it for observability; the Director organizes and updates it as the emq program leader. | Ephemeral local memory is invisible to review and lost on a machine change. Git-controlling it puts memory under the same inspection the framework demands of every fact; the symlink keeps the standard tool path working. |
| **D0-4** | How far the AAW framework absorbs Epics | **Surgical — APPLIED 2026-06-15** — added "Epic / corpus" as a named instrument (`aaw.framework.md`) + the corpus rule (`aaw.rules.md` *The events*) + the Director's *Owns* corpus role; the program manual + calibrations moved out of `specs/` to `docs/echo_mq/program/`. The third-layer elevation stays deferred until the pattern proves across ≥2 programs. | "Practice ships first, codified second" (the framework's own discipline). One program's proof earns a named instrument, not yet a structural layer change. |

## The three corpus instruments (the proposals, reconciled)

### 1 · `docs/echo_mq/epics/` — the Epics layer  *(the structure)*

Per *User Stories Applied* best practice, an **Epic** is a large theme decomposed into stories/rungs, carrying a
catalogue. Structure (mirrors `specs/`, the [RECONCILE] of the stub's `docs/epics/` against agile practice):

- `emq.epic.N.md` — the **charter + index**: scope, the catalogue's feature table, the rungs the epic spans.
- `emq.epic.N/` — the **slices**: the per-feature DSL mds (`<feature>.md`) + the epic's spec-grade detail
  (`emq.N.specs.md` / `emq.N.stories.md`) where it carries one.
- **emq.epic.1** is the first: *EchoMQ v3.x command DSL* (D0-2) — the forward-only catalogue that supersedes the
  1290-line matrix.

### 2 · `docs/echo_mq/kb/` — the knowledge base  *(the guides)*

A developer-facing corpus of **guides and worked examples**, written in plain prose **without** the ledger's
`[T·D·L·V·Z]-N` shorthand — readable by any developer joining the program, not only by an agent fluent in the
audit channels. Distilled *from* the ledgers (`specs/progress/`) and the design canon: the ledgers stay the
audit trail, the kb is the onboarding/reference narrative. (Scaffolded: `docs/echo_mq/kb/`.)

### 3 · the Claude Memory Mind Model  *(the memory)*

The framework memory — **organized and updated by the Director** as the emq program leader — lives
**repo-git-controlled**; the Claude memory location (`~/.claude/projects/-Users-jonny-dev-jonnify/memory/`,
**today a real directory, not yet symlinked**) becomes a **symlink** to the repo folder, for observability.
Memory becomes versioned, reviewable, and shared rather than ephemeral local state.

- **Honest bound:** that memory directory is **project-wide** (it holds elixir / bcs / … memories,
  not only emq), so the physical move + symlink is a **whole-project, Operator-gated execution step** — named here
  and decided as the model, **not executed by this epic**.

## Benefits

- **No context bloat, no missed entries** — an agent loads one feature slice (or one kb guide), never a
  1290-line monolith; the per-feature structure forces completeness (a missing command is a missing section,
  visible at a glance).
- **One authority per fact** — each command's v3 form, each guide, each memory has exactly one defining file;
  duplication, the drift surface, is designed out.
- **A reviewable corpus** — git-controlled epics + kb + memory are inspectable, diff-able, and shared,
  extending the framework's transparency pillar from the code to the knowledge layer.
- **A reusable AAW pattern** — proven on emq, the Epic/corpus instrument folds back into the framework canon
  (D0-4) for every program that outgrows its per-rung structure.

---

Index: [emq.epic.1](./emq.epic.1.md) (the v3.x command DSL) · the rung layer: [`../specs/`](../specs/) · the
audit trail: [`../specs/progress/`](../specs/progress/) · the knowledge base: [`../kb/`](../kb/) · the
framework: [aaw.framework.md](../../aaw/aaw.framework.md) · [aaw.rules.md](../../aaw/aaw.rules.md).
