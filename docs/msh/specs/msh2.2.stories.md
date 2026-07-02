# msh2.2 — acceptance stories

> Given/when/then over the rung's public surface (CLI + MCP + the corpus contract). Derives from
> [msh2.2.md](./msh2.2.md); the body wins on any disagreement. Every story runs against fixture
> directories — never the live corpus — except S-12/S-13, which record the real backfill under the S-4
> fence.

## S-1 · A declared `project:` scopes the scan (contract: §3.1 placement, §3.3 filter)

As an agent recalling one program's notes, running a scoped scan, so that only that program's rows load.
- **Given** a fixture corpus where note A declares top-level `project: mercury` and note B declares
  `project: msh`, **when** `msh memory scan --project mercury` runs, **then** exactly A's row is emitted.
- **Given** a note carrying `project:` only nested under `metadata:`, **when** the scoped scan runs,
  **then** that note does NOT match the declared value (top-level only; the degrade order governs it).

## S-2 · The MCP `project` param returns the same rows (invariant: one implementation)

As an MCP client, passing `project` to `memory_scan`, so that the tool and the CLI agree.
- **Given** the S-1 fixture served over MCP, **when** `memory_scan {project: "mercury"}` is called,
  **then** the returned rows equal the CLI's `--project mercury` output.

## S-3 · A scoped stale run invents nothing (contract: §3.3 post-filter)

As an operator auditing one project, filtering stale findings, so that the filter is a view, never a
different corpus.
- **Given** a fixture where a project-P note is linked ONLY from a project-Q note, **when**
  `msh memory stale --project P` runs, **then** no `ORPHAN` (or any) finding appears that is absent from
  the unfiltered run, **and** every emitted finding's `file` has effective project P.

## S-4 · The degrade order covers keyless notes (Seam S-2b)

As a project owner with organic subdirectories, so that keyless notes still scope sensibly.
- **Given** a keyless note at `<root>/echo_mq/note.md`, **when** the corpus loads, **then** its effective
  project is `echo_mq` and `--project echo_mq` includes it.
- **Given** a keyless flat note at `<root>/note.md`, **when** any `--project P` filter runs, **then** the
  note is excluded; **and when** the unfiltered scan runs, **then** it appears with no project value.

## S-5 · A declared `status:` wins over the sniff (contract: §3.4)

As a note author declaring supersession, so that status is stated, not guessed.
- **Given** a note with `status: superseded` and a body with no supersession marker, **when** the corpus
  loads, **then** the node's status is `superseded`.
- **Given** a note with `status: active` whose body's first 1KB contains `(superseded`, **when** the
  corpus loads, **then** the node's status is `active` (the declaration pins it).

## S-6 · The sniff still classifies a keyless note (regression: the fallback)

As an operator with legacy notes, so that supersession detection never regresses.
- **Given** a note with NO `status:` key whose body's first 1KB contains `> superseded`, **when** the
  corpus loads, **then** the node's status is `superseded` — byte-identical behavior to HEAD.

## S-7 · An invalid `status:` degrades loudly (contract: §3.4)

As a maintainer who typos a value, so that the mistake is visible, never silently guessed.
- **Given** a note with `status: retired`, **when** the corpus loads, **then** the node records a
  `frontmatter_error` naming the invalid value, **and** its status is what the sniff fallback yields.

## S-8 · A due `review_after` produces a warn finding (contract: §3.5)

As the corpus steward, running stale/audit, so that notes past their review date surface by default.
- **Given** a note with `review_after: 2026-06-01` and an injected reference date 2026-07-02, **when**
  the `REVIEW-DUE` rule runs, **then** one warn finding names the note, the date, and the ref.
- **Given** `review_after: 2026-08-01` at the same ref, **then** no finding; **given**
  `review_after: 2026-07-02` (ref == date), **then** the finding fires (due ON the named day).
- **Given** a superseded note with a past `review_after`, **then** no finding (dead notes carry no
  review obligation).

## S-9 · An invalid `review_after` fails the audit (contract: §3.5 + D6)

As the corpus steward, so that a malformed date is a gate failure, not a silent skip.
- **Given** a note with `review_after: soon`, **when** `msh memory audit` runs, **then** an
  error-severity `REVIEW-DUE` finding is reported and the exit code is non-zero (the audit exit now
  honors ANY error-severity finding, per its own contract line).

## S-10 · The rule is deterministic under an injected date (invariant: design §4.3)

As the program's maintainer, pinning golden fixtures, so that review-due output never drifts with the
wall clock.
- **Given** the G-6 fixture corpus and a fixed injected reference date, **when** the rule runs twice (or
  in CI a year later), **then** the findings are byte-identical; **and** no code path in the rule reads
  the system clock.

## S-11 · The tool surface only grows descriptions (invariant: additive-minor)

As the program's maintainer, so that the MCP surface stays pinned while params are added.
- **Given** the built server, **when** the pin test lists tools, **then** the count is exactly 8 and the
  set is unchanged; **and** the `memory_scan`/`memory_stale` schemas each carry the new optional
  `project` param; **and** their descriptions name the new metadata / the `REVIEW-DUE` rule.

## S-12 · The backfill keys the corpus honestly (§5, under the S-4 fence)

As the Operator, reviewing the one fenced `memory/` mass edit, so that every note is scoped and nothing
else changed.
- **Given** the dry-run mapping table (script-emitted, Director-reviewed) and a tree backup, **when** the
  staged script applies, **then** every note under `memory/` except `MEMORY.md` carries a top-level
  `project:`; the byte-diff shows ONLY frontmatter line insertions; zero `status:` and zero
  `review_after:` keys are written (the §2 census: sniff = 0, the one tombstone ruled active).
- **Given** the pre-backfill scan output, **when** the post-backfill scan runs, **then** every node's
  STATUS value is byte-identical, **and** `msh memory audit` reports 0 errors with counts unchanged from
  the recorded before-leg (71 files, error=0 warn=0 info=1).

## S-13 · The dirty files stay out of the rung's commit (§5 carve-out)

As the Operator with in-flight `[memory]` edits, so that the rung's commit stays pure.
- **Given** the six Operator-touched memory files (as-shipped: `MEMORY.md`, `codemojex-program.md`,
  `mercury-design-system.md`, `mercury-dual-vitest-jestdom-trap.md` as tracked edits +
  `codemojex-write-suite.md`, `mercury-visual-regression-harness.md` untracked), **when** the rung's LAW-4
  backfill commit is staged as the git-computed pure-insertion set, **then** `git diff --cached --name-only`
  contains none of the six; the four dirty notes' new `project:` lines ride the Operator's own batch;
  `MEMORY.md` shows no diff at all.

## Coverage

| Deliverable (spec §4/§5) | Stories |
|---|---|
| D1 parser v2 (top-level) | S-1, S-7 |
| D2 node surface + effective project | S-4, S-5 |
| D3 scoped scan (CLI + MCP + render) | S-1, S-2 |
| D4 scoped stale (post-filter) | S-3 |
| D5 REVIEW-DUE + injected ref | S-8, S-10 |
| D6 audit exit honesty | S-9 |
| D7 docstring sync | S-11 |
| D8 pin stays 8 | S-11 |
| §5 backfill R-1..R-4 | S-12 |
| §5 dirty-tree carve-out | S-13 |
| sniff-fallback regression | S-6 |
