---
name: msh-mcp-server
description: "apps/msh = the self-contained 'msh' Go module: CLI (memory/mint) + MCP server serving mcp__msh__{memory_audit,memory_stale,memory_graph,memory_scan,memory_project,mint} over streamable-HTTP :8899 (registered in .mcp.json); .msh-memory.json is the project anchor (root + project context, auto-resolved)"
metadata: 
  node_type: memory
  type: project
  originSessionId: fa6ff6a4-f406-4f8c-84ca-2aa04a482b6a
---

`apps/msh` (module `github.com/jonny-novikov/msh`, single entry point `apps/msh/cmd/main.go`) is the **"msh" toolchain + MCP server**. As of the 2026-06-16 restructure it is **one self-contained Go module** — the former top-level `msh-memory/` module was folded INTO it and deleted; there is no external `fiberfx/msh-memory` dep, no `go.work` entry for it, no replace. Layout:

- `cmd/` — `main.go` (the wiring), `mint.go`, tests. Package `main`.
- `brandedid/` — the **brd14 codec + minter** (`github.com/jonny-novikov/msh/brandedid`).
- `memory/command/` — the memory toolchain (`…/memory/command`), `memory/internal/*`, `memory/testdata/`.

**Subcommands** (cobra):
- `msh memory scan|graph|stale|audit|project|version` — the folded memory toolchain, mounted via `command.New("memory",…)`. `msh memory scan` is a working **one-liner** (auto-root, default format `pretty`). `msh memory project` prints the active program context from `.msh-memory.json`.
- `msh mcp serve|start|stop|restart [--port 8899] [--root P] [--stdio]` — serve is foreground (graceful SIGINT/SIGTERM); start detaches via `Setsid` + a **pidfile/log at `os.TempDir()` = `$TMPDIR` `/var/folders/...` on macOS, NOT `/tmp`** (probe the printed path); stop/restart use pidfile + signal-0 liveness.
- `msh mint [--ns USR | positional NS] [-f text|json|ndjson|csv|yaml] [-n COUNT] [--node N]` — mints branded snowflake ids. **Flag is `--ns` (GNU/pflag); the stub's `-ns` is doc shorthand**; NS also accepted positionally (`msh mint USR`).

**brd14 / mint contract.** A branded id = 3-letter uppercase namespace + 11 base62 over a `ts(41)<<22 | node(10)<<12 | seq(12)` snowflake, **epoch 2024-01-01Z (1704067200000)**, alphabet `0-9A-Za-z`. The codec is **vendored verbatim** from the canonical `dev/echo_data/runtimes/go/brandedid` (== `docs/echo/code/src/go/brandedid`) — whose own doc says "the contract travels as test vectors, not as a shared object"; `brandedid_test.go` re-asserts the vector `Encode("USR",274557032793636864)=="USR0KHTOWnGLuC"` + `Hash32`. The **minter** ports `EchoData.Snowflake` (echo/apps/echo_data/lib/echo_data/snowflake.ex): one atomic cell CAS-advancing `max(now, last+1)` → strictly monotonic even within a ms / across a backward clock step; default node = FNV(hostname) mod 1024.

**MCP** uses the official `modelcontextprotocol/go-sdk`, vendored at `apps/mcp-go` (module `github.com/fiberfx/mcp-go/v2`, replaced to `../mcp-go`). `mcp.AddTool[In,Out]` derives the schema from a `json:`/`jsonschema:`-tagged struct; `NewStreamableHTTPHandler` → plain `http.Handler`. Tools registered in `registerMemoryTools` + `registerMintTool`, surfaced as **`mcp__msh__{memory_audit,memory_stale,memory_graph,memory_scan,memory_project,mint}`** (the `msh` prefix is the `.mcp.json` server key, which holds `"msh":{"type":"streamable-http","url":"http://localhost:8899/"}`). A bare `GET /` returns HTTP 400 (wants an initialize POST) — a *healthy* liveness signal. **Adding/removing a tool, or starting the server after session start, requires the client to `/mcp` reconnect (or restart) before the tools appear** — a streamable-http server is connected-to at session start, not retro-injected.

**`.msh-memory.json` = the project anchor** (NOT the markdown corpus; it points AT it). Schema: `{"root":"…", "project":{"name","code","roadmap","state":{"status","current_rung"}}}` — e.g. `echo_mq`/`emq`/`emq.roadmap.md`/`in_progress`@`emq.4.1`. It is parsed by `command.LoadMemoryConfig(startDir)` (JSON walk-up; relative `root` resolved against the file's dir) and surfaced via `command.ProjectInfo` → `msh memory project` + `mcp__msh__memory_project` (orients an agent to the active program). Distinct from `internal/config` (the YAML stale-rule config: `msh.memory.yaml`/`.msh-memory.yaml`).

**Memory-root resolution is unified** in `command.ResolveRoot` (used by BOTH the CLI and the MCP server — the old duplicate JSON reader in main.go is gone): explicit `--root` > nearest `.msh-memory.json` `root` (walk-up) > `MEMORY.md` marker. So `msh memory <cmd>` and `msh mcp serve` both auto-resolve with no `--root`; explicit still wins, so the `--root`-passing tests are unaffected.

**Gotchas.** Build per-module with **`GOWORK=off`** (repo convention). `go build ./...` from `apps/msh` collides ("build output 'cmd' already exists") — use `go build -o <bin> ./cmd`. `go.work` (root) still has **pre-existing broken members** (`apps/gateway`, `atlas`, `db`, `flyer`, `imgkit`, `pgroll`, `tbls` — missing go.mod) that warn-not-block in workspace mode; `apps/msh` is a member, `apps/mcp-go` deliberately is NOT (would pull its example deps).

Verification: full `apps/msh` suite green under `github.com/jonny-novikov/msh/...`; `cmd/mcp_test.go` drives the tools over a real `httptest` streamable-HTTP roundtrip (incl. minting a `SES` id) against `memory/testdata/memory`; `command/project_test.go` covers the JSON walk-up + render. **Scanner gotcha:** the frontmatter parser reads a TOP-LEVEL `type:`, but the memory notes nest it as `metadata.type` → every note shows `TYPE=unknown` in `scan`/`graph` and the type/orphan stale rules don't classify them (open follow-up: teach the parser to read `metadata.type`). Related Go-Cobra toolchain: [[jonnify-cms-toolchain]].
