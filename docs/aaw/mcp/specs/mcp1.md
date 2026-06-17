# MCP1 · the single-writer store discipline

> The correctness foundation of the aaw MCP server v2: make every file the server owns a single-writer,
> atomic, files-are-truth store — closing the unlocked-registry race, the length-based CCL mint, the
> torn-write window, and the read-once index — over the live PoC's surface, adding no new tool.

## Goal

The smallest shippable increment over the live PoC (`apps/aaw`, `2.0.0-min`) that makes the server's data
plane correct under concurrency and crash: all of a scope's writes serialize through one per-scope writer;
every whole-file write is atomic (temp + fsync + rename); CCL-ids mint from a persisted counter and survive
re-spawn; the workspace index is read-through so an out-of-band edit is never resurrected; and a second
server process on the same workspace refuses to boot. The 17-tool surface is unchanged — this rung ships
robustness, not new capability, and every later rung depends on it.

## Rationale (5W)

- **Why**   — the PoC carries the exact defect classes the server exists to prevent: two concurrent
  `aaw_spawn` calls race an unlocked registry read-modify-write and can lose a row or mint a duplicate
  CCL-id; in-place `os.WriteFile` can truncate the audit trail on a crash; the index is read once at boot
  and written back whole, so an out-of-band row deletion is resurrected. A process that records process
  must first be correct about its own records.
- **What**  — one per-scope serialization domain over the scope's three files; a persisted `next_ccl`
  mint with identity continuity on re-spawn; an atomic write discipline; a pure read-through workspace
  index (the L-2 fix); and a boot-time flock single-instance guard.
- **Who**   — the Director (whose gate reads must reflect the true registry), every peer (whose spawn must
  not be lost under the parallel-ceremony formation), the Operator (who edits `.aaw/scopes.json` by hand),
  and the maintainer who needs a refactor pinned by a running check.
- **When**  — the first rung of the build ladder; depends only on the live PoC and the vendored SDK
  (`apps/mcp-go`); MCP2 and every later rung depend on it. No `apps/mcp-go` change.
- **Where** — `apps/aaw/internal/store/**` (index, registry, ledger IO, the per-scope lock) and the
  `aaw_spawn`/`agent_register` sites in `apps/aaw/cmd/aaw/main.go`, plus tests. The tool surface and the
  ledger grammar are untouched; the diff stays inside the store package and its two call sites.

## Scope

- **In**  — the per-scope writer lock broadened to cover ledger + registry + messages writes; the
  persisted `next_ccl` counter and the re-spawn-keeps-CCL-id rule; temp+fsync+rename for index, registry,
  and ledger, with `O_APPEND` single-line writes for `messages.jsonl` and `.claude/audit.log`; the
  read-through index (no resident map; read-merge-write under the store lock); the flock guard on
  `.aaw/aaw.lock` with the holder id in `probe`; and the conformance tier-1 plus the exemplar-ledger
  parse-compat golden that pin these.
- **Out** — the `actor` attribution parameter, `agent_heartbeat`, the three-source liveness fusion, the
  `aaw_status` gate console, and the advisory FAKE-N / V-SOLO signal emission (all MCP2); the `channel_*`
  family and `tool_x_resonance` (the Q-3-ship rung); the closed error-code vocabulary and the EBNF ledger
  grammar formalization (their own rung); configuration, custom ports, and the wire-contract check (the
  config/ports/wire rung); the transport-mode decision (the transport rung). Each is deferred to the named
  rung.

## Deliverables

- **MCP1-D1** — one **per-scope serialization domain**: a mutex per scope name guarding every write to the
  scope's ledger, registry, and messages files, broadening the PoC's ledger-only lock
  (`internal/store/ledger.go:41-46`) to cover the unlocked registry read-modify-write
  (`internal/store/store.go:182-204`, called from `cmd/aaw/main.go:155-184`). The store-level lock guards
  only the index; no lock nests except store→scope.
- **MCP1-D2** — a persisted monotonic **`next_ccl`** counter in the registry; `aaw_spawn` mints
  `ccl-<scope>-<n>` from it, never from `len(r.Agents)+1` (`cmd/aaw/main.go:173`); a re-spawn of an
  existing name keeps its CCL-id and refreshes `spawned_at` (the resume-identity-continuity pattern).
- **MCP1-D3** — an **atomic write discipline**: every whole-file write (index, registry, ledger) goes to
  `<file>.tmp`, fsync, rename over the original; the two line-logs (`messages.jsonl`, `.claude/audit.log`)
  use `O_APPEND` single-line writes — replacing the PoC's in-place `os.WriteFile`
  (`store.go:97,203`, `ledger.go:171`).
- **MCP1-D4** — a **pure read-through index**: the resident scope map is removed; every scope lookup reads
  `.aaw/scopes.json` under the store lock; every mutation re-reads, applies the single-row change, and
  renames into place — so an out-of-band edit (including a row deletion) is honored on the next call and
  never resurrected (the L-2 fix), replacing read-once-at-boot + full-map write-back (`store.go:70-98`).
- **MCP1-D5** — a boot-time **flock single-instance guard** on `<workspace>/.aaw/aaw.lock`, held for the
  process lifetime, with the holder's instance id and pid written into the lock file and surfaced by
  `probe`; a second server process on the same workspace refuses to boot (`INSTANCE_LOCKED`), making the
  in-process per-scope lock sufficient for all file mutations.

## Invariants

- **MCP1-INV1** — **single writer per scope.** Any number of concurrent tool calls across any number of
  scopes serialize per scope; within one scope, ledger numbering stays gap-free and no registry row is
  lost — two concurrent `aaw_spawn` calls never lose a row and never mint a duplicate CCL-id.
- **MCP1-INV2** — **atomic or absent.** Every whole-file write is observed by any reader as either the
  complete prior file or the complete new file; a crash mid-write truncates neither the ledger, the
  registry, nor the index — at most the in-flight entry is lost, never the file.
- **MCP1-INV3** — **the index is files-truth.** An out-of-band edit to `.aaw/scopes.json`, including a row
  deletion, takes effect on the next tool call and is never resurrected by server memory; a deleted row
  stays deleted.
- **MCP1-INV4** — **one instance per workspace.** A second server process bound to the same workspace
  refuses to boot while the flock is held, so the in-process per-scope lock is the only serialization any
  file mutation needs.
- **MCP1-INV5** — **CCL identity is stable.** A CCL-id minted for a name in a scope is never re-minted or
  collided; a re-spawn of that name returns the same id, so an identity resumed across stages keeps one
  CCL-id.

## Definition of Done

- [ ] the per-scope mutex covers ledger + registry + messages; registry IO is no longer an unlocked
      read-modify-write; the CCL mint reads `next_ccl`, not `len(r.Agents)+1`; the store lock guards the
      index alone (MCP1-D1, MCP1-D2).
- [ ] every whole-file write is temp + fsync + rename; the two line-logs are `O_APPEND` (MCP1-D3).
- [ ] the index is read-through with no resident map; an out-of-band delete stays deleted (MCP1-D4).
- [ ] boot acquires the flock; a second instance on the same workspace refuses with `INSTANCE_LOCKED`;
      `probe` reports the holder (MCP1-D5).
- [ ] MCP1-INV1–INV5 are pinned by running tests: a concurrency property for INV1 (N parallel spawns, no
      lost row, no duplicate CCL); a crash/atomicity test for INV2; an out-of-band-edit golden for INV3; a
      two-process flock test for INV4; a resume-keeps-CCL test for INV5.
- [ ] the parse-compat golden over the hand-written exemplar ledgers
      (`docs/echomq/specs/emq/design/emq-design.progress.md`, `docs/aaw/mcp/aaw.mcp.progress.md`) continues
      numbering correctly — the early gate.
- [ ] the tool surface is unchanged (17 v1 tools); `aaw selftest` is green; the live scopes (`emq-design`,
      `aaw-mcp`) still parse and append — demoable.

Stories: ./mcp1.stories.md · Agent brief: ./mcp1.llms.md · Index: ./mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
