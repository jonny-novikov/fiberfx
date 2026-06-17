# MCP1 · agent brief (llms)

> Implementation brief for a coding agent. References, traced requirements, the execution topology, and a
> paste-ready prompt. Pairs with the spec mcp1.md, the stories mcp1.stories.md, and the runbook
> mcp1.prompt.md.

## References

- `apps/aaw/internal/store/store.go` — the store of record: `:70-98` index load/save (the L-2 site — read
  once at `Open`, full-map write-back), `:104-140` `InitScope` (`:118-120` ledger_dir-required),
  `:182-204` `LoadRegistry`/`SaveRegistry` (the unlocked read-modify-write, direct `os.WriteFile`),
  `:217-234` `Touch`/`Counts`. These are the surfaces this rung hardens.
- `apps/aaw/internal/store/ledger.go` — the ledger engine: `:41-46` the per-scope `ledgerLocks` (the lock
  this rung broadens), `:48` `entryRe`, `:68-79` whole-file `nextN`, `:96-175` `Append` (`:171` the
  in-place `WriteFile` to replace with temp+rename). The grammar itself is unchanged this rung.
- `apps/aaw/cmd/aaw/main.go` — the call sites: `:155-184` `aaw_spawn` (`:173` the `len(r.Agents)+1`
  mint to replace with `next_ccl`; `:159-172` the parent-exists gate, kept), `:187-219` `agent_register`
  (the second unlocked registry writer), `:306-347` `runServer` (`:314-340` the bind, `:343` the banner —
  the flock guard installs here), `:352-411` the selftest (`:373` the 17-tool pin).
- The design corpus (settled): `venus-1.md` — ADR-1 (read-through index), ADR-2 (flock), ADR-3
  (per-scope serialization domain), ADR-4 (atomic writes), ADR-22 (persisted `next_ccl` + identity
  continuity); `apollo.evaluation.md` — rows 1, 2, 3, 14, 19, 20 (the strongest convergences, defect
  sites re-verified in §8). The donor corpus was retired from the tree at `f44f0539`; those ids resolve
  in git history (`git show 9d145486:docs/aaw/mcp/design/<file>`), and the consolidated authority is
  [`../aaw.mcp.design.md`](../aaw.mcp.design.md).
- Upstream: the proposal `aaw.mcp.proposal.md` (R-1 files-are-truth, R-4 single-writer, R-5
  registry-is-evidence) — retired from the tree post-canon; readable via
  `git show 74d8a899:docs/aaw/mcp/aaw.mcp.proposal.md` — and
  [the specs approach](../../../elixir/specs/specs.approach.md)
  (thin-but-robust, invariants pinned by running checks).

## Requirements

- **MCP1-R1** — every write to a scope's ledger, registry, or messages file is taken under one mutex keyed
  by the scope name; the store-level lock guards `.aaw/scopes.json` alone; no lock nests except
  store→scope. [US: MCP1-US1]
- **MCP1-R2** — `aaw_spawn` mints `ccl-<scope>-<n>` from a persisted `next_ccl` counter incremented under
  the per-scope lock; a re-spawn of an existing name returns the stored CCL-id and refreshes `spawned_at`;
  no mint reads `len(r.Agents)`. [US: MCP1-US1]
- **MCP1-R3** — index, registry, and ledger writes go to `<file>.tmp`, fsync, then `os.Rename` over the
  original; `messages.jsonl` and `.claude/audit.log` use `O_APPEND` single-line writes; no whole-file
  writer calls `os.WriteFile` in place. [US: MCP1-US2]
- **MCP1-R4** — the resident scope map is removed; `GetScope` and every read re-read `.aaw/scopes.json`
  under the store lock; every mutation re-reads, applies the single-row change, and renames; a row absent
  on disk is absent to the server on the next call. [US: MCP1-US3]
- **MCP1-R5** — boot acquires an advisory flock on `<workspace>/.aaw/aaw.lock`, held for the process
  lifetime, writing the instance id + pid; a second instance on the same workspace exits non-zero with
  `INSTANCE_LOCKED`; `probe` reports the holder. [US: MCP1-US4]
- **MCP1-R6** — the ledger grammar, the 17 tool names, and their schemas are unchanged; the exemplar
  ledgers parse and continue numbering; the selftest runs against a hermetic temp workspace. [US: MCP1-US5]

## Execution topology

Runtime: one server process holds the workspace flock for its lifetime. A tool call flows handler →
`internal/store` → (the store lock for the index · a per-scope lock for ledger/registry/messages) →
temp-file + rename, and back. No resident scope cache exists; the index is re-read per call. The lock state
lives in the process; the durable state lives in files.

```text
boot ──flock(.aaw/aaw.lock)──▶ runServer ──held for lifetime──▶ probe reports holder
call ──▶ handler ──▶ store ──store-lock──▶ read-through .aaw/scopes.json (L-2 fix)
                          └──scope-lock──▶ ledger.Append / SaveRegistry(next_ccl) / messages O_APPEND
                                            each whole-file write: tmp → fsync → rename
```

Tasks (each step leaves the app compiling):

```text
1. flock guard in runServer (.aaw/aaw.lock; INSTANCE_LOCKED; holder in probe)
   ─▶ 2. atomic writeFileAtomic(tmp+fsync+rename) used by index/registry/ledger writers
   ─▶ 3. read-through index (drop the resident map; read-merge-write under the store lock)
   ─▶ 4. per-scope lock broadened to registry + messages; SaveRegistry taken under it
   ─▶ 5. persisted next_ccl mint + re-spawn-keeps-CCL-id in aaw_spawn
   ─▶ 6. tests: INV1 concurrency property, INV2 atomicity, INV3 out-of-band golden,
         INV4 two-process flock, INV5 resume-CCL; the exemplar parse-compat golden; selftest
```

Touched files: `apps/aaw/internal/store/store.go`, `apps/aaw/internal/store/ledger.go`,
`apps/aaw/cmd/aaw/main.go`, `apps/aaw/internal/store/atomic.go` (new — the atomic writer),
`apps/aaw/internal/store/store_test.go`, `apps/aaw/internal/store/ledger_test.go`,
`apps/aaw/internal/store/testdata/` (the committed exemplar-ledger goldens).

## Agent stories

- **MCP1-AS1** [implements MCP1-US2] — Directive: add `internal/store/atomic.go` with
  `writeFileAtomic(path, data)` = write `<path>.tmp`, `f.Sync()`, `os.Rename`; route the index, registry,
  and ledger writers through it; leave `messages.jsonl`/`audit.log` on `O_APPEND`. Acceptance gate: an
  atomicity test asserts a reader never observes a partial file; `go build ./...` clean.
- **MCP1-AS2** [implements MCP1-US3] — Directive: remove the resident scope map; make `GetScope` and all
  reads re-read `.aaw/scopes.json` under the store lock; make each mutation read-merge-write the single
  row, then `writeFileAtomic`. Acceptance gate: an out-of-band delete golden shows the row stays gone on
  the next call; no `saveIndexLocked` full-map write-back remains.
- **MCP1-AS3** [implements MCP1-US1] — Directive: broaden the per-scope lock to cover `SaveRegistry` and
  the messages write; move the CCL mint to a persisted `next_ccl` counter; keep an existing name's CCL-id
  on re-spawn. Acceptance gate: a concurrency property runs N parallel `aaw_spawn` and asserts N rows / N
  distinct ids (INV1, INV5); a resume test asserts a re-spawned name keeps its id.
- **MCP1-AS4** [implements MCP1-US4] — Directive: acquire an advisory flock on `.aaw/aaw.lock` at boot,
  held for the lifetime, writing instance id + pid; a held lock makes a second boot exit non-zero with
  `INSTANCE_LOCKED`; surface the holder in `probe`. Acceptance gate: a two-process test shows the second
  refuses and the first keeps serving (INV4).
- **MCP1-AS5** [implements MCP1-US5] — Directive: copy the committed exemplar ledgers into `testdata/`;
  assert parse + append continues numbering and preserves prior bytes; run the 17-tool selftest against a
  hermetic temp workspace. Acceptance gate: the golden + selftest are green; tool count is still 17.

## Execution plan — first two stories

1. **MCP1-AS1 — atomic writer.** Add `internal/store/atomic.go` (`writeFileAtomic`: `os.CreateTemp` in the
   target dir, write, `Sync`, `Close`, `os.Rename`); replace the in-place `os.WriteFile` at `store.go:97`,
   `store.go:203`, and `ledger.go:171`. Gate: `go test ./internal/store/...` atomicity case green;
   `go build ./...` clean.
2. **MCP1-AS2 — read-through index.** Drop the `Store` resident map; `GetScope` reads + parses
   `.aaw/scopes.json` under the store mutex each call; `InitScope`/archival mutations read-merge-write the
   single row through `writeFileAtomic`. Gate: an out-of-band-delete test (delete a row on disk, call a
   scope-bound tool, expect `NOT_INITIALIZED`) passes; no resident-map read path remains.

## Comprehensive implementation prompt

The single brief that builds MCP1 is the runbook [`mcp1.prompt.md`](mcp1.prompt.md) — the persistent
design pack the orchestrator locked, carrying the per-deliverable grounding (file:line), the model, the
gate command, and the no-invent guard. Run it in agent-story order (AS1→AS5), end on the verification
gates, and report the modules changed, the gate results, and confirmation that the tool surface stayed at
17 and `apps/mcp-go` was untouched. Do not run git.

Spec: mcp1.md · Stories: mcp1.stories.md · Runbook: mcp1.prompt.md · Index: mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
