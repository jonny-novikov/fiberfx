---
name: aaw-scope-hygiene
description: "How to remove stale teams/scopes from aaw's .aaw/scopes.json — there is NO delete tool; the sanctioned path is an out-of-band file edit (read-through index), stale = the scope's own ledger file is gone"
project: aaw
metadata: 
  node_type: memory
  type: project
  originSessionId: bcd9b57a-f3d4-44ec-bde7-93fbc0a81666
---

**Removing stale teams from the aaw MCP server = edit `<workspace>/.aaw/scopes.json` directly.** The aaw server (`go/aaw`, :8905) exposes **no delete/prune/archive tool or CLI subcommand** — the CLI is only `serve`|`selftest`, and the MCP surface only *creates* (`aaw_init`/`aaw_spawn`/`agent_register`). Removal is by design an out-of-band file edit: the store is a **read-through projection** of `scopes.json` (`GetScope`/`ScopeNames`/`probe` re-read per call — store.go:218 *"a row deleted out of band stays deleted"*), and `writeIndex` is documented to **never clobber an out-of-band edit to another row** (store.go:131-133, holds `s.mu`, re-reads in the same critical section). So a live edit is honored instantly with **no server restart** — verify with `probe` (re-enumerates) + `aaw_status <removed>` (→ `NOT_INITIALIZED`).

**The real "stale" signal = the scope's own ledger file `<ledger_dir>/<scope>.progress.md` is missing** (a dangling registry pointer — its deliverable dir was reorganized/removed). The server's built-in `Archived` flag (TTL: `created_at + ttl_days` lapsed, store.go:558) is **display-only, unenforced, and near-useless** — `ttl_days:0` means "no hint" (returns false), so most scopes never flag. The `ARCHIVED` gate code (gates.go:32) is reserved for a future mcp7 rung with no emitter yet.

**Safety recipe (done 2026-06-30, 88→40 scopes):** (1) `.aaw/scopes.json` is **gitignored** (`.gitignore` `.aaw/*`) → edits are NOT version-controlled → **back up first** (any scope is also re-addable via idempotent `aaw_init`, losing only original `created_at`). (2) Classify by `os.path.isfile(<ledger_dir>/<scope>.progress.md)` + test scopes (operator `selftest` or `/tmp`,`/var/folders` ledger_dir). (3) Write filtered map **atomically** (temp + `os.replace`) to mirror the server's `writeFileAtomic` and avoid a torn read; Go marshals with **sorted keys + 2-space indent**. Removed 48 dangling/test rows (echo_mq specs-reorg ledgers, dropped `mx-6`, retired `docs/portal`/`docs/exchange`/`live_svelte`, the 2 test scopes); kept 40 with live ledgers.

Related: [[aaw-mcp-server-v2]] [[aaw-mcp-server-ladder]] [[mcpd-controller]].
