# echo — the BCS data-layer umbrella

One Elixir/Mix umbrella (`Echo.MixProject`, `apps_path: "apps"`). At its core is the **Branded Component
System (BCS) data plane** — `echo_wire` · `echo_data` · `echo_mq` · `echo_store`, a Valkey-native data layer
built on ETS and Lua — with consumer apps standing on it. This README is the **developer front door**; the
authoritative build guide is [`CLAUDE.md`](CLAUDE.md), and the **specs are the source of truth** in
[`../docs/echo_mq/`](../docs/echo_mq/).

## The apps

| App                                               | Role                                                                                                                                                                                                                                                  | In-umbrella deps |
|---------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---|
| `echo_wire`                                       | The **owned wire** — RESP3 framing, the single-owner socket connector, the script registry behind a version fence (`EchoMQ.Connector` / `RESP` / `Script`; `EchoWire` is the facade).                                                                 | — (base) |
| `echo_data`                                       | **Identity + structure + BCS** (pure) — the 14-byte branded-id contract (`EchoData.{BrandedId,Snowflake,Base62}`), the persistent structures, the BCS systems (`Bcs.{PropertyStore,EdgeStore,Archetypes}` + `Bcs.gate`), the optional Rust NIF codec. | — (pure) |
| `echo_mq`                                         | **The bus** — the Valkey-native job/queue/stream system keyed by branded `JOB` ids. Keyspace `emq:{q}:`, inline Lua, server-clock leases.                                                                                                             | `echo_data` · `echo_wire` |
| `echo_store`                                      | **The store** — L1 ETS over L2 Valkey (cache-aside), Graft Engine, Tigris S3 Replication. Keyspace `ecc:{table}:{id}`.                                                                                                                                | `echo_data` · `echo_mq` · `echo_wire` · `exqlite` |
| `exchange` · `investex` · `echo_bot` · `codemojex` | Consumers / standalone (trading capstone · venue gRPC client · YAML multibot engine · the demo). Out of scope for the BCS data-stack build guide.                                                                                                     | various |

The four-app **BCS data-layer stack** is the focus of development here; `CLAUDE.md` is scoped to it.

## Toolchain

**Elixir 1.18.4 · Erlang/OTP 28.5.0.1** (asdf, `.tool-versions`). **Re-probe `asdf current` / `.tool-versions`
from the app dir — never hardcode the toolchain** (it has drifted before).

## Quickstart

```bash
cd /Users/jonny/dev/jonnify/echo
mix deps.get
mix compile

# Valkey 9 on :6390 (RESP3) — the engine for any wire/bus rung (externally managed):
valkey-server --port 6390 --daemonize yes --save ''
valkey-cli -p 6390 ping          # → PONG  (always ping before trusting a green wire suite)
```

## Build & test — the per-app gate ladder

The gate ladder is **per-app, NEVER umbrella-wide** — run it from inside the app's own directory:

```bash
cd apps/<app>                                    # echo_wire | echo_data | echo_mq | echo_cache
TMPDIR=/tmp mix compile --warnings-as-errors     # the clean-compile gate
TMPDIR=/tmp mix test                             # add --include valkey for a wire/bus rung
```

- **`TMPDIR=/tmp` for ALL `mix`** — the harness tmp overlay can hit ENOSPC, surfacing as spurious mid-suite
  ExUnit I/O failures.
- The default `mix test` runs the **pure column** (`:valkey` excluded); wire/bus tests are `@moduletag :valkey`
  and need `--include valkey` + a live engine on 6390.
- **Conformance** (`echo_mq`): `EchoMQ.Conformance.run/2 → {:ok, 52}` under the additive-minor law.

For the **full gate ladder, the v2 master invariant, the determinism loop, and the boundary rules**, see
[`CLAUDE.md`](CLAUDE.md) — the authoritative per-umbrella build guide. When this README and `CLAUDE.md`
disagree, `CLAUDE.md` wins; when either disagrees with the specs (`../docs/echo_mq/`), the specs win.

## The `go/` workspace

The repo's Go workspace [`../go/`](../go/) is the **local agent operating system** that builds this umbrella:
the **`aaw`** (task-management) and **`msh`** (memory) MCP servers, the `mcpd` controller, and the `mcp-go` SDK.
To work on it, read [`../go/CLAUDE.md`](../go/CLAUDE.md). The workspace is initialized over the agent-infra
cluster:

```bash
cd ../go && go work use ./aaw ./msh ./mcpd ./mcp-go   # (go/go.work already present)
(cd aaw && go build ./...)                             # verify a module builds
```

## The workflow — spec-driven, rung by rung

This umbrella ships through the **Agile Agent Workflow (AAW)**: thin provable increments (**rungs**), each
defined by a spec, built from a brief, accepted only under checks that actually run. The framework definition
is [`../docs/aaw/aaw.framework.md`](../docs/aaw/aaw.framework.md); the **fullest worked example** is the
`echo_mq` program ([`../docs/echo_mq/`](../docs/echo_mq/) — the single rung ladder, the conformance spine, the
per-rung ledgers). Ship a rung with `/echo-mq-ship <rung>`; the `aaw` MCP tools (`mcp__aaw__*`) operationalize
the loop.

## Map

[`CLAUDE.md`](CLAUDE.md) (the build guide) · [`../docs/echo_mq/`](../docs/echo_mq/) (the specs, source of truth)
· [`../docs/aaw/`](../docs/aaw/) (the workflow) · [`../go/CLAUDE.md`](../go/CLAUDE.md) (the agent OS) ·
[`../docs/jonnify.workspace.md`](../docs/jonnify.workspace.md) (the whole-workspace map).
