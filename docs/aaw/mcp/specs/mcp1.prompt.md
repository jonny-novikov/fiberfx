# MCP1 · build runbook (the persistent design pack)

> The orchestrator's design-lock for the MCP1 build rung, made persistent. It fixes the deliverables, the
> per-item grounding (verified `file:line`), the model to copy, the gate command, and the no-invent guard,
> so the x-mode build pipeline (Venus brief → Mars ×2 → Apollo → one LAW-4 commit) runs from a settled
> design. The `mcp1.llms.md` comprehensive-prompt section points here; this is the canonical source.

## The rung in one paragraph

Harden the live PoC's data plane (`apps/aaw`, `2.0.0-min`) into a single-writer, atomic, files-are-truth
store, over the existing 17-tool surface, adding no tool: one per-scope serialization domain across
ledger + registry + messages; a persisted `next_ccl` mint with re-spawn identity continuity; temp+fsync+
rename for every whole-file write with `O_APPEND` for the two line-logs; a pure read-through workspace
index (the L-2 fix); and a boot-time flock single-instance guard. Mode (CALIBRATED 2026-06-11 by the
Operator, mid-rung): **settled tier** — one implementor build pass carrying the full gate, the
Director's independent gate re-run, one LAW-4 pathspec commit. The original `Flat-L2 (build + harden
+ verify)` three-pass prescription was over-ceremony for a settled-design, single-package rung and
was descoped mid-run (aaw-mcp ledger D-10; the standing tier rule lives in the roadmap's "How the
roadmap runs"). Every later rung depends on this one.

## Settled forks (no open Operator decision)

- The synthesis is settled per the design corpus: base = `design/venus-1.md`; the relevant ADRs are 1
  (read-through index), 2 (flock), 3 (per-scope serialization domain), 4 (atomic writes), 22 (persisted
  `next_ccl` + identity continuity); the defect sites are re-verified in `design/apollo.evaluation.md` §8.
- This rung ships **no** transport, config, port, wire, attribution, liveness, signal, channel, resonance,
  error-vocabulary, or grammar change — all are later rungs (see `mcp1.md` Scope/Out). Do not widen.
- The artifact-shape note (re-homed 2026-06-11 under the Operator's WRITING TRIAD LAW): the rung carries
  the full specs-approach triad — `mcp1.md` (the six-section spec) + `mcp1.stories.md` (the user stories +
  Coverage line) + `mcp1.llms.md` (the agent brief) — plus this runbook, under the chapter index `mcp.md`.
  The original fused `mcp1.specs.md` form (spec + stories merged, the shape this runbook was executed
  against) is retired. The traceability closure runs `D#→US#` (Coverage line in `.stories.md`) →
  `R# [US:]` / `AS# [implements]` (`.llms.md`).

## Per-deliverable grounding (verified file:line — do not re-derive, do not invent)

| Deliverable | As-built site to change | The change |
| --- | --- | --- |
| MCP1-D1 per-scope domain | `internal/store/ledger.go:41-46` (ledger-only lock); `internal/store/store.go:182-204` + `cmd/aaw/main.go:155-184` (unlocked registry RMW) | one mutex per scope name over ledger + registry + messages; store lock for the index only |
| MCP1-D2 next_ccl mint | `cmd/aaw/main.go:173` (`len(r.Agents)+1`) | persisted `next_ccl` in the registry; re-spawn keeps the CCL-id, refreshes `spawned_at` |
| MCP1-D3 atomic writes | `store.go:97`, `store.go:203`, `ledger.go:171` (in-place `os.WriteFile`) | `writeFileAtomic` = tmp + fsync + rename; `O_APPEND` for `messages.jsonl` + `.claude/audit.log` |
| MCP1-D4 read-through index | `store.go:70-98` (read-once + full-map write-back) | drop the resident map; read-merge-write the single row under the store lock; the L-2 fix |
| MCP1-D5 flock guard | `cmd/aaw/main.go:306-347` (`runServer`) | advisory flock on `.aaw/aaw.lock`, held for life; `INSTANCE_LOCKED`; holder in `probe` |

## The model to copy

The exemplar code-rung triad is `docs/elixir/redlock/rl1.*` (a clean single-responsibility first rung).
The grounding style — one real `file:line` per surface, no invented arity — is `design/venus-1.md` §8
and `design/apollo.evaluation.md` §8. The Go idioms (table-driven + golden + a concurrency property via
parallel goroutines + `go test -race`) replace the Elixir `StreamData` idiom of the model; the discipline
is identical (every invariant pinned by a check that RUNS).

## The gate (run before reporting done)

```text
- go build ./...                                   (clean)
- go vet ./apps/aaw/...                             (clean)
- go test -race ./apps/aaw/internal/store/...       (INV1 concurrency, INV2 atomicity, INV3 out-of-band,
                                                     INV5 resume-CCL — all green)
- a two-process boot test: second instance exits non-zero with INSTANCE_LOCKED, first keeps serving (INV4)
- the parse-compat golden over docs/echomq/specs/emq/design/emq-design.progress.md and
  docs/aaw/mcp/aaw.mcp.progress.md: parse + append continues numbering, prior bytes preserved
- aaw selftest against a hermetic temp WORKSPACE: 17 tools, every refusal as before
- grep: no os.WriteFile in place for index/registry/ledger; no len(r.Agents) in the CCL mint;
  no resident scope map read path; tool count unchanged; apps/mcp-go untouched
```

## The no-invent guard

Cite a real `file:line` for every surface changed; invent no tool, parameter, field, or error code (the
closed error-code vocabulary is a LATER rung — this rung adds only `INSTANCE_LOCKED` as a boot refusal, not
a tool-result code). Keep the diff inside `apps/aaw/internal/store/**` + the two `cmd/aaw/main.go` call
sites + tests; `apps/mcp-go` is untouched this rung (its modify-freedom under D-5 is for the transport
rung, not this one). Leave all changes in the working tree for the Director's single LAW-4 commit; run no
git.

## Stage pathspec (Director, at rung-close)

`apps/aaw/internal/store/ apps/aaw/cmd/aaw/main.go docs/aaw/mcp/specs/mcp1.md
docs/aaw/mcp/specs/mcp1.stories.md docs/aaw/mcp/specs/mcp1.llms.md docs/aaw/mcp/specs/mcp1.prompt.md` —
excluding any Operator out-of-band path; never `git add -A`. (The as-run close at `7972859f` staged the
pre-law fused name `mcp1.specs.md`; the pathspec above is the post-re-home form.)

Spec: mcp1.md · Stories: mcp1.stories.md · Agent brief: mcp1.llms.md · Index: mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
