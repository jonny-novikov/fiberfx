# figma-local

> The local-Figma MCP that lets an agent read a **live Figma desktop session** — no API key —
> and the enhancement program that makes Codemoji game-design extraction efficient and faithful.
> This is the overview; the design and decisions are in [figl.design.md](figl.design.md), the
> rung ladder and open seams in [figl.roadmap.md](figl.roadmap.md).

## What it is

Three components across two machines (verified on disk; full table in
[figl.design.md](figl.design.md) §2):

```
Mac (this repo)                         Windows Figma machine (192.168.1.120)
  agent ──▶ mcp.js ──HTTP POST /request──▶ bridge-server.js ──WebSocket──▶ figma-plugin
            (stdio MCP)                     (:3001 / :3000, pure relay)      (inside Figma)
```

The agent and this repo run on the Mac; Figma, the bridge, and the plugin run on Windows. The
bridge is an **unauthenticated** LAN relay (a standing accepted risk — [figl.roadmap.md](figl.roadmap.md)
S-1). Enhancements are **hand-deployed on the Windows box (no CI)** — never on this Mac.

## The as-built tool surface (10 registered, 6 live)

From `mcp/figma-mcp/mcp.js`. Two are advertised but **dead** until `figl.1` (they throw
`"Unknown action"` in the plugin):

| group | tools |
|---|---|
| discovery | `get-figma-document` · `get-current-page` · `get-all-pages` · `get-selection` · `find-nodes` |
| detail | `get-node-properties` |
| export | `export-node` |
| health | `check-bridge-status` |
| **dead** | `get-batch-nodes` · `export-batch-nodes` *(dropped in `figl.1`; `get-batch-nodes` returns enriched in `figl.3`)* |

The current token-budget hazards (why the enhancement exists): `export-node` returns a decimal
int-array (~1M tokens for a screen); `get-node-properties` returns one level only and omits
cornerRadius / auto-layout / resolved variables; large discovery dumps should be avoided in
favor of selection-first calls. Until the rungs land, the **toolkit** below is how to extract
without paying those costs.

## The enhancement (where it is going)

A five-rung ladder, ruled 2026-06-25 by a two-architect debate (capability vs steward lenses)
per [aaw.architect-approach.md](../aaw/aaw.architect-approach.md). Headlines:

1. **`figl.1`** — drop the dead tools (Mac-only, no deploy).
2. **`figl.2`** — base64 image egress (`{path,w,h,byteLen}`, no bytes in context) + an
   advertised==live capability handshake.
3. **`figl.3`** — targeted node enrichment (cornerRadius, auto-layout, bounding box) + a real
   `get-batch-nodes`.
4. **`figl.4`** — a bounded `depth` param for one-call subtree fetch.
5. **`figl.5`** — `resolve-variables` (the one capability the Mac client cannot supply) + async
   read hardening.

Full deliverables, deploy properties, verification, and the deferred seams: [figl.roadmap.md](figl.roadmap.md).
The enhance-and-deploy runbook for the Windows box is [figl.prompt.md](figl.prompt.md) — run it
against the Windows checkout, never on this Mac.

## The toolkit (the working client + the reference implementation)

`node/codemoji-design/` (`@codemoji/design`) is the Mac-side CLI that extracts a screen today
using only the 6 live tools, routing image bytes bridge→disk so they never reach an agent's
context. It **doubles as the reference implementation** of every proposed tool — each gap it
works around is tagged with the fork that fixes it (`figma/<screen>/manifest.json → gaps`). The
`CODEMOJIES` extraction (`figma/codemojies/`) is the lived grounding for the whole design.

```
node bin/codemoji-design.mjs doctor      # probe the bridge + which actions the plugin backs
node bin/codemoji-design.mjs extract     # extract the current selection → figma/<screen>/
```

## Doc map

| file | owns |
|---|---|
| [figma-local.md](figma-local.md) | this overview — topology, the as-built surface, the doc map |
| [figl.design.md](figl.design.md) | the architecture, the six surfaced forks (staged), the ruled ADRs |
| [figl.roadmap.md](figl.roadmap.md) | the `figl.1`–`figl.5` ladder, the master invariants, the Seams & open decisions, the `RULED` ledger |
| [figl.prompt.md](figl.prompt.md) | the enhance-and-deploy runbook for the Windows machine — per-rung edits, build/deploy primitives, verify |

## Status

Design **ruled**; build **not started**. The two architect positions (Venus-A capability,
Venus-B steward) are the transcript of record behind [figl.design.md](figl.design.md) §4. The
agent-facing usage instructions (`mcp/docs/figma-local.md`) and the scoped `CLAUDE.md` pointers
are separate deliverables, scoped to work in `echo/apps/codemojex` or `node/codemoji-app` only.
