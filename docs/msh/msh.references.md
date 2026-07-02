# msh — the references (read before expanding the canon)

> The grounding set for any agent expanding [msh.design.md](./msh.design.md) or
> [msh.roadmap.md](./msh.roadmap.md). NO-INVENT: a surface not verifiable in one of these sources is either
> forward-tense (and marked so) or does not belong in the canon.

## The genesis record (this program's own ground)

- [kb/genesis/genesis.grounding.md](./kb/genesis/genesis.grounding.md) — the locked constraints + ground
  truth the program was founded on (file:line census of the as-built seams).
- [kb/genesis/msh.design.A-steward-lens.md](./kb/genesis/msh.design.A-steward-lens.md) ·
  [kb/genesis/msh.design.B-steelman-lens.md](./kb/genesis/msh.design.B-steelman-lens.md) — the lens pair;
  the losing arms keep their steelman here.
- [kb/genesis/msh.synthesis.md](./kb/genesis/msh.synthesis.md) — the fork ledger + the D-5..D-12 rulings.
- [specs/progress/msh-genesis.progress.md](./specs/progress/msh-genesis.progress.md) — the run ledger
  (T/D/L/Z channels; the decisions channel is the ruling authority).

## The as-built baseline (frozen; cite, never expand)

- [docs/go/msh/msh.design.md](../go/msh/msh.design.md) + [msh.roadmap.md](../go/msh/msh.roadmap.md) — the
  reverse-mode record of the shipped Phase-1 toolchain (`msh.0–msh.6`; it lags the code: 7-tools claim,
  the §8 frontmatter fork since implemented).
- Code seams: `go/msh/memory/command/corpus.go` (ingestion), `go/msh/cmd/main.go` (registration),
  `go/msh/memory/command/root.go` + `go/msh/memory/internal/config/config.go` (resolution + the marker
  wart), `go/msh/memory/internal/config/defaults.go` (the dormant Hugot/Similarity seam).
- The live anchor: `.msh-memory.json` at the repo root (schema v1.1 lands at msh2.1).
- The Go workspace law: `go/CLAUDE.md` (GOWORK=off, mcpd hot-swap, never kill a live server).

## The method (the aaw framework)

- [aaw.architect-approach](../aaw/aaw.architect-approach.md) — four-part arms, the multi-architect debate,
  the contract-set instrument (the msh2.5 pack schema follows it).
- [aaw.specs-approach](../aaw/aaw.specs-approach.md) — the rung triad contract `./specs/README.md` adopts.
- [aaw.rules](../aaw/aaw.rules.md) — the voice, the fences, the Decisions law the canon obeys.

## The consumers (what the engine serves)

- The memory corpus: `memory/` (69 notes; MEMORY.md the hand-curated index; schema v2 at msh2.2).
- The docs program trees: `docs/<prog>/` (the normalized pattern msh2.6 lints and msh2.7 ingests;
  `docs/msh/` is the first exemplar).
- The session transcripts: `~/.claude/projects/<slug>/*.jsonl` (via `history_search`; pointers per D-11).
- The aaw run artifacts: `<scope>.progress.md` + `<scope>.registry.json` beside each program's specs
  (machine artifacts of ship runs — never a content index; the name `*.registry.json` is reserved to them).
