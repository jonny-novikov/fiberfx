# figl — enhance & deploy prompt (run on the WINDOWS Figma machine)

> The authoritative scope for building the figma-local enhancement ladder. **Run this against the
> Windows checkout `C:\dev\jonnify\mcp\figma-mcp`** (the source of truth for the plugin + bridge) — *not on the
> Mac*; the Mac cannot rebuild or reload the Figma plugin. The design and the ruled ADRs are in
> [figl.design.md](figl.design.md); the ladder + invariants + seams in [figl.roadmap.md](figl.roadmap.md).
> Implement **to the ADRs** (they carry the exact API surfaces and line citations) — this prompt
> scopes and sequences the work and owns the **deploy + verify** procedure; it does not pre-write
> the code.
>
> **Ground rule (NO-INVENT):** every Figma API call is verified against `@figma/plugin-typings`
> at the line cited in the matching ADR before it is used. The bridge stays a **pure relay**. The
> handshake **flags, never bricks**. `figma.mixed` is guarded before any serialization.

## Who runs which step

Each step is tagged by locus. The Operator coordinates the two machines.

- `[WIN]` — an agent/Claude Code session on the Windows machine, editing `C:\dev\jonnify\mcp\figma-mcp`.
- `[FIGMA-manual]` — a human action in Figma Desktop (re-running the plugin); an agent cannot click it.
- `[MAC]` — sync + reconnect on the Mac (the live `mcp.js` is `/Users/jonny/dev/jonnify/mcp/figma-mcp/mcp.js`).

## Preconditions (verify before any rung)

1. `[WIN]` Bridge up: `pnpm bridge` running in `C:\dev\jonnify\mcp\figma-mcp`; Figma Desktop open with the
   "Figma MCP Bridge" plugin showing **Connected to bridge**.
2. `[MAC]` Reachable + connected: `curl http://192.168.3.120:3001/health` →
   `{"status":"ok","connected":true,"hasDocument":true}`.
3. `[WIN]` Toolchain: `pnpm install` done; `tsc` available (the `build-plugin` script is
   `cd figma-plugin && tsc`, output `code.js` per the plugin manifest `main`).
4. `[WIN]` Working tree clean on `C:\dev\jonnify\mcp\figma-mcp` (so each rung is one reviewable change), and a
   way to sync `mcp.js` back to the Mac (git pull / scp / shared folder — per `docs/MAC-CLIENT.md`).

## Build & deploy primitives (the only commands you need)

| action | command / step | locus |
|---|---|---|
| build the plugin | `pnpm build-plugin` (≡ `cd figma-plugin && tsc` → `code.js`) | `[WIN]` |
| reload the plugin | Figma → **Plugins → Development → Figma MCP Bridge** (re-run loads the new `code.js`); confirm "Connected to bridge" | `[FIGMA-manual]` |
| restart the bridge | stop the `pnpm bridge` process, start it again | `[WIN]` |
| health / capability check | `curl http://192.168.3.120:3001/health` | `[WIN]` or `[MAC]` |
| sync the Mac client | update `/Users/jonny/dev/jonnify/mcp/figma-mcp/mcp.js`, then reconnect the MCP in Claude | `[MAC]` |
| reconnect the MCP | `/mcp` reconnect in Claude Code (or `claude mcp remove/add` per `docs/MAC-CLIENT.md`) | `[MAC]` |

**Deploy shapes by file:** a `code.ts` change ⇒ `build-plugin` + `[FIGMA-manual]` reload. A
`bridge-server.js` change ⇒ restart the bridge (+ reload the plugin so it reconnects). An `mcp.js`
change ⇒ `[MAC]` sync + reconnect.

## The ladder

Build in order. Each rung lands as one change-set, deploys, and is verified against the live
`CODEMOJIES` screen (`94:2974`) before the next begins.

### `figl.1` — drop the dead tools (`[MAC]` only, **no Windows deploy**) · ADR-6
- **Edit:** in `mcp.js`, delete the `get-batch-nodes` and `export-batch-nodes` `registerTool`
  blocks (`mcp.js:170-202`). Mac-side runtime; also drop them in the Windows checkout so the two
  copies stay identical.
- **Deploy:** `[MAC]` reconnect the MCP. No plugin/bridge change.
- **Verify:** the two tools no longer appear; the other 8 still respond; `check-bridge-status` is
  unchanged. *This rung proves the loop with zero deploy risk.*

### `figl.2` — base64 egress + the capability handshake + cleanup tool (**first Windows deploy**) · ADR-1, ADR-5
- **Edit (egress, B1):** `code.ts` `exportNode` returns `figma.base64Encode(bytes)` (typings
  `:1886`) in place of `Array.from(bytes)` (`code.ts:141`), with `{nodeId, format, data, w, h, byteLen}`.
  `mcp.js` base64-decodes, writes to a **bounded** Mac path (`RENDER_ROOT = FIGMA_MCP_RENDER_ROOT`
  or `os.tmpdir()/figma-mcp-renders`), and returns `{path, nodeId, format, w, h, byteLen}` —
  no bytes in the tool result.
- **Edit (cleanup, ADR-1 addendum):** a new `cleanup-renders` MCP tool — explicit cleanup, no
  background sweep. Params: `keepLast` (int) and/or `keepSince` (`"1h"` / `"30m"` / `"24h"` /
  `"7d"` / bare ms); a file is kept if it satisfies either rule. `dryRun: true` previews.
  At least one rule is required (the empty call is rejected).
- **Edit (handshake, E2):** the plugin sends a `backed-actions` WS message on `ws-connected`
  (carrying the `BACKED_ACTIONS` const that mirrors the `code.ts:20-41` switch);
  `bridge-server.js` caches it and `/health` (`:76`) includes it as `backedActions`; `mcp.js`
  asserts its advertised set ⊆ the backed set and **flags** a mismatch through
  `check-bridge-status` (status `"warn"` with the missing list, never a hard fail).
  Add selection-default: `get-node-properties` / `export-node` called with no `nodeId` fall
  back to `figma.currentPage.selection` when it has **exactly one** node (multi-selection is
  an explicit error).
- **Lockstep:** update the toolkit `node/codemoji-design/src/extract.mjs:97` (it currently decodes
  the int-array via `Buffer.from(res.data)`) to consume the new base64 contract
  (`Buffer.from(res.data, 'base64')`) — ship it **with** this rung so the working client never breaks.
- **Deploy:** `[WIN]` `build-plugin`; `[FIGMA-manual]` reload; restart the bridge for the `/health`
  change; `[MAC]` sync `mcp.js` + reconnect.
- **Verify:** `export-node 94:2974` returns a path + dims + `byteLen`, writes a non-empty PNG, and
  returns **no** byte array; `check-bridge-status` lists the backed actions and shows
  `handshake.status: "ok"` with `advertised ⊆ backed`; selection-default works (no-nodeId call
  with one selection); `cleanup-renders { keepLast: 1 }` deletes all but the newest;
  `node bin/codemoji-design.mjs extract` still renders end-to-end.

### `figl.3` — targeted enrichment + real `get-batch-nodes` (Windows deploy) · ADR-3
- **Edit (enrichment, A2):** `serializeNodeDetailed` gains `cornerRadius`
  (+ `topLeftRadius` / `topRightRadius` / `bottomLeftRadius` / `bottomRightRadius`) behind a
  `figma.mixed` guard (unified value emitted only when every corner agrees; per-corner numbers
  always concrete), the four auto-layout fields (`layoutMode`, `paddingTop|Right|Bottom|Left`,
  `itemSpacing`, `layoutSizingHorizontal|Vertical`) **only when `layoutMode !== 'NONE'`**, and
  `absoluteBoundingBox` (`:6976`).
- **Edit (`get-batch-nodes` — both halves):** implement the plugin case (loop
  `getNodeByIdAsync` → `serializeNodeDetailed`; missing nodes come back as `{id, error}`
  per-id) AND re-add the `mcp.js` `registerTool` wrapper (`figl.1` dropped it Mac-side so
  `advertised==live` held while the handler was missing). Add `'get-batch-nodes'` to both
  `BACKED_ACTIONS` (plugin) and `ADVERTISED_ACTIONS` (mcp.js).
- **Deploy:** `[WIN]` `build-plugin`; `[FIGMA-manual]` reload; `[MAC]` sync `mcp.js` + reconnect
  (the mcp.js wrapper changed).
- **Verify:** a frame returns `cornerRadius`/padding where present and **omits** auto-layout on a
  `layoutMode: 'NONE'` node (so `get-selection` is not bloated); `get-batch-nodes` returns N
  enriched nodes in one call (and missing ids come back as `{id, error}` entries, not a batch
  failure); `check-bridge-status` lists `get-batch-nodes` under `backedActions` with
  `handshake.status: "ok"`.

### `figl.4` — one-call bounded subtree (Windows deploy) · ADR-2
- **Edit (plugin):** `getNodeProperties(nodeId?, depth?, maxNodes?)` — when `depth` is omitted,
  return `serializeNodeDetailed(node)` **byte-identically to pre-figl.4** (no `truncated` /
  `nodeCount` fields added). When `depth` is given, the new `serializeSubtree` walks the SAME
  `serializeNodeDetailed` recursively, replacing the lite `{id,name,type}` child stubs with
  detailed children; `maxNodes` (default `500`, sized for a CODEMOJIES-scale screen well under
  the ~30s bridge timeout) caps total serializations — when hit, the root carries
  `truncated: true` + `nodeCount`. Dispatch the new params through the `case 'get-node-properties'`.
- **Edit (mcp.js):** extend the `get-node-properties` Zod schema with
  `depth: z.number().int().nonnegative().optional()` and
  `maxNodes: z.number().int().positive().optional()`; forward both unchanged. No change to
  `ADVERTISED_ACTIONS` (same tool, additive params).
- **Lockstep:** `node/codemoji-design/src/bridge.mjs` — refresh the ACTION SURFACE doc to mention
  the new `depth?` / `maxNodes?` params on `get-node-properties`. `extract.mjs:60-82`'s
  `boundedWalk` keeps its current per-node calls — collapsing it to one depth-call is an
  *optional future optimization* the depth surface unblocks, not a `figl.4` deliverable
  (ADR-2's "absent ≡ today's shape EXACTLY" preserves the existing client).
- **Deploy:** `[WIN]` `build-plugin`; `[FIGMA-manual]` reload; `[MAC]` sync `mcp.js` + reconnect.
- **Verify:** `get-node-properties { nodeId: "94:2974" }` returns the byte-identical pre-figl.4
  shape (no `truncated` / `nodeCount`); `get-node-properties { nodeId: "94:2974", depth: 2 }`
  returns one detailed-children tree in one call; `get-node-properties { nodeId: "94:2974",
  depth: 10, maxNodes: 20 }` returns `{ truncated: true, nodeCount: 20 }` rather than blocking
  on the ~30s bridge timeout (`bridge-server.js:148`); `check-bridge-status` still reports
  `handshake.status: "ok"` (action surface unchanged).

### `figl.5` — `resolve-variables` + async hardening (Windows deploy) · ADR-4, ADR-8
- **Edit:** a new `resolve-variables` tool resolving a node's bound variables via
  `Variable.resolveForConsumer` (`:11432`), returning resolved value + type per bound field. Swap
  the sync `figma.getNodeById` (`code.ts:124,132`) → `getNodeByIdAsync` (`:421`) —
  behavior-preserving under legacy mode, defensive ahead of any dynamic-page adoption (S-3).
- **Deploy:** `[WIN]` `build-plugin`; `[FIGMA-manual]` reload; `[MAC]` sync `mcp.js` + reconnect.
- **Verify:** a bound `VariableID` resolves to a concrete value + `resolvedType`; the 14
  `CODEMOJIES` aliases (`node/codemoji-design/figma/codemojies/tokens.md`) resolve to real
  bindings; the async swap preserves every existing read.

## Lockstep rule (the no-CI safeguard)

A rung that changes a wire contract (`figl.2` especially) moves **three things together**: the
plugin (`code.ts`), the Mac client (`mcp.js`), and the toolkit (`extract.mjs`). Deploy them in one
window and run the `check-bridge-status` handshake immediately after — on a box with no test
harness, the handshake's advertised ⊆ backed assertion is the regression check.

## Rollback

Each rung is one change-set on `C:\dev\jonnify\mcp\figma-mcp`. To roll back: revert the change-set,
`build-plugin`, `[FIGMA-manual]` reload (and restart the bridge if `/health` changed), then
`[MAC]` sync + reconnect. Because the plugin is the deployed artifact, *reverting the source is not
enough* — you must rebuild and reload for the old `code.js` to take effect.

## Done criteria

All five rungs deployed and verified against `94:2974`; `check-bridge-status` reports advertised ⊆
backed with the full enhanced action set; `node bin/codemoji-design.mjs extract` produces a
manifest whose `gaps[]` for egress / tree / props / tokens are cleared (instances remains, by
design — S-2). The post-deploy verification itself is task #8 (Operator-gated).

## References

- Ruled design + ADRs: [figl.design.md](figl.design.md) · Ladder + seams: [figl.roadmap.md](figl.roadmap.md).
- Topology, firewall, security notes, the two-copy setup: `mcp/figma-mcp/docs/MAC-CLIENT.md`.
- Reference implementation of every proposed tool: `node/codemoji-design/src/*.mjs`.
