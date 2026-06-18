# jonnify — the workspace map

> The one-screen orientation for an agent landing in `/Users/jonny/dev/jonnify`: what lives where, what is in
> and out of search scope, and where to go for depth. It consolidates the `echo/` · `go/` · `docs/` structure
> so a fresh agent is routed in one hop instead of re-exploring. **`html/` is excluded from search** — it is
> the rendered static-course output (heavy); the source-of-record for every page is under `docs/`.

## Rationale — the 5W

- **Why.** Spec-driven development under three pillars (Transparency · Inspection · Adaptation) and five values
  (Thin but robust · Grounded · One authority · Do no harm · Judgment at the ends). Every fact has exactly one
  defining document; nothing is invented; work proceeds in thin provable increments.
- **What.** Two things, built together: (1) **`echo_mq` 3.0** — the Valkey-native bus — and the **BCS
  data-layer stack** it lives in (`echo_wire` · `echo_data` · `echo_mq` · `echo_cache`); (2) the **local agent
  operating system** in `go/` that builds it — `aaw` (task management) + `msh` (memory) MCP servers.
- **Who.** One **Operator** (`claude@jonnify.com`) who supplies intent, decomposition, and acceptance, paired
  with **Claude agents** in named AAW roles — the **Director** (orchestrates, gates, commits), **Venus**
  (architect / spec-steward), **Mars** (implementor + code-quality gate), **Apollo** (verifier / mentor), plus
  fan-out **authors** and read-only **researchers**.
- **When (current work).** Per `.msh-memory.json`: project **`echo_mq` / `emq`**, **current rung `emq.4.1`**
  (Movement II, the groups family). Movement I is **closed** (conformance **52/52**). The `go/` agent OS is in
  **active development** toward fully-fledged memory + task management.
- **Where.** The three trees below (`echo/`, `go/`, `docs/`) + the `memory/` corpus. `html/` is out of scope.

## The three trees

| Tree | What it is                                                                                                                                                                                                                                                                                                                                                       | Start here |
|---|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---|
| **`echo/`** | The **Elixir/Mix umbrella** — the BCS data plane (`echo_wire` · `echo_data` · `echo_mq` · `echo_cache`, Valkey-native on ETS + Lua) + consumers (`exchange`, `investex`, `echo_bot`, `codemojex`). Engine: Valkey 9 on `:6390`.                                                                                                                                   | [`echo/CLAUDE.md`](../echo/CLAUDE.md) (build guide) + [`echo/README.md`](../echo/README.md); specs `docs/echo_mq/` |
| **`go/`** | The **local agent OS** — `aaw` (task mgmt, MCP `:8905`), `msh` (memory, MCP `:8899`), `mcpd` (the cobra+bubbletea controller), `mcp-go` (the **Research Preview of the official MCP Go SDK**, modifiable, **not** `mark3labs/mcp-go`). `go/go.work` spans these four; standalone tools (`jonnify-cms`, `echomq-go`) build `GOWORK=off`.                          | [`go/CLAUDE.md`](../go/CLAUDE.md); framework `docs/aaw/`; specs `docs/go/` |
| **`docs/`** | The **canon** (plain-text source of truth). Key trees: `echo_mq/` (the program — design · roadmap · progress · per-rung specs), `aaw/` + `aaw/mcp/` (the framework definition + the `aaw`-server forward design), **`go/`** (the Go-server as-built reverse specs), `echo/{bcs,art,mesh,…}` (manuscripts), `elixir/`, `redis-patterns/`, `fsharp/`, `exchange/`. | this file · [`docs/aaw/aaw.framework.md`](aaw/aaw.framework.md) · [`docs/echo_mq/`](echo_mq/) |

Plus **`memory/`** — the local memory corpus (`MEMORY.md` index + per-fact notes), resolved through the
`.msh-memory.json` project anchor (which also carries the current rung). **Excluded from search: `html/`** (the
rendered static courses — heavy; edit and read the `docs/` source instead).

## The workflow

Work ships through the **Agile Agent Workflow (AAW)** — one rung at a time, as a six-stage loop:
**sharpen → build → ship → demo → review → feedback** (feedback edits the spec; the next rung starts from one
agreed truth). Each rung is carried by **four artifacts** — the roadmap, the spec (`<rung>.md`), the user
stories (`<rung>.stories.md`), and the agent brief (`<rung>.llms.md`) — and accepted only under checks that
actually run. Two formations: the **lead-team** for code (`/x-mode`, and `/echo-mq-ship <rung>` for the bus)
and the **fan-out** for content/specs. The framework is defined in
[`docs/aaw/aaw.framework.md`](aaw/aaw.framework.md); its fullest worked example is the `echo_mq` program
([`docs/echo_mq/`](echo_mq/), AAW4 — the validation run). The `aaw` MCP server (`go/aaw`) operationalizes the
loop; `msh` (`go/msh`) is its memory half.

## Navigation rules for agents

- **Elixir umbrella work** → [`echo/CLAUDE.md`](../echo/CLAUDE.md) (+ [`echo/README.md`](../echo/README.md)).
- **Go agent-OS work** → [`go/CLAUDE.md`](../go/CLAUDE.md). The repo-root `CLAUDE.md` redirects Go work here.
- **The specs are the source of truth** — `docs/echo_mq/` (the bus), `docs/go/` (the Go servers, as-built),
  `docs/aaw/` (the framework). When a guide and the specs disagree, the specs win.
- **Don't search `html/`** — it is heavy rendered output; the source is in `docs/`.
- **Local memory** lives in `memory/` (tended by the `msh` tooling); the project anchor `.msh-memory.json`
  names the current rung.
