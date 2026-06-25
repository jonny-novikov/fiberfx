# figma-local — roadmap (`figl`)

> The single rung ladder for the figma-local enhancement, plus the open seams the Operator
> deferred. The design and the ADRs are in [figl.design.md](figl.design.md); the overview is
> [figma-local.md](figma-local.md). Every rung is **forward-tense** — none is built. The ladder
> is the two architects' ladders (Venus-A: 7 rungs; Venus-B: 5) collapsed by the four Operator
> rulings of 2026-06-25.
>
> **Deploy law.** The Mac side is this repo. The plugin + bridge are **hand-deployed on the
> Windows Figma machine with no CI** — so each rung names its deploy property, and any rung that
> changes a wire contract updates the Mac toolkit (`node/codemoji-design/src/*.mjs`) in
> **lockstep** so the working client never breaks on the un-tested box.

## Master invariants (hold on every rung)

- **The bridge stays a pure relay** — no rung makes it stateful or a file server (ADR-1, ADR-7).
- **Advertised == live** — `mcp.js` advertises only actions the deployed plugin backs; from
  `figl.2` this is *checked*, not hoped (ADR-5).
- **`figma.mixed` is guarded** — any property that can return the `unique symbol`
  (`plugin-api.d.ts:909`) is guarded before serialization; an unguarded read mangles the whole
  payload to `{}` (ADR-3).
- **Writes are bounded** — the Mac-side file write (`figl.2`) targets a specified root with
  cleanup; no orphaned files.
- **The handshake flags, never bricks** — a version/capability mismatch degrades to a warning on
  `check-bridge-status`, never a hard failure against an older deployed plugin (ADR-5).

## The ladder

### `figl.1` — Stabilize advertised==live (Mac-only, **no deploy**)
- **Do:** delete the dead `get-batch-nodes` / `export-batch-nodes` registrations
  (`mcp.js:170-202`). Restores advertised==live instantly (ADR-6).
- **Deploy:** none — this repo only. Proves the loop before the Windows box is touched.
- **Verify:** reconnect the MCP; the two tools no longer appear; the remaining 8 still respond;
  `check-bridge-status` unchanged.
- **Risk:** lowest in the program (a deletion on a version-controlled file).

### `figl.2` — Egress + the capability handshake (**first Windows deploy**)
- **Do (egress, B1 / ADR-1):** `code.ts` `exportNode` returns `figma.base64Encode(bytes)`
  (`plugin-api.d.ts:1886`) instead of `Array.from(bytes)` (`code.ts:141`); `mcp.js` base64-decodes,
  writes to a bounded Mac path, returns `{path, w, h, byteLen}`. Update `extract.mjs:97`
  (`Buffer.from(res.data)` → read base64 / consume `{path}`) in **lockstep**.
- **Do (handshake, E2 / ADR-5):** the plugin reports its backed-action list; `/health`
  (`bridge-server.js:76`) returns it; `mcp.js` asserts advertised ⊆ backed and flags a mismatch
  via `check-bridge-status`. Selection-default (nodeId omitted ⇒ current selection) rides along.
- **Deploy:** Windows (plugin + bridge `/health`). The egress is the worst live defect; the
  handshake is the guard every later rung relies on — they ship together so the box is never
  left advertising-unchecked.
- **Verify:** `export-node 94:2974` returns a path + dims, writes a non-empty PNG, returns no
  bytes; `check-bridge-status` lists backed actions and shows advertised ⊆ backed; the toolkit's
  `extract` still renders end-to-end against the new contract.

### `figl.3` — Targeted payload enrichment + re-implement `get-batch-nodes` (Windows deploy)
- **Do (A2 / ADR-3):** `serializeNodeDetailed` gains `cornerRadius` (+ per-corner, `figma.mixed`
  guarded), the four auto-layout fields **emitted only when `layoutMode !== 'NONE'`**, and
  `absoluteBoundingBox` (`plugin-api.d.ts:6976`). Implement the `get-batch-nodes` plugin handler
  (loop `getNodeByIdAsync` → `serializeNodeDetailed`); its `mcp.js` wrapper already exists.
- **Deploy:** Windows (plugin).
- **Verify:** a frame returns `cornerRadius`/padding where present and *omits* auto-layout on a
  `layoutMode: 'NONE'` node (so `get-selection` is not bloated); `get-batch-nodes` returns N
  enriched nodes in one call; the handshake now lists `get-batch-nodes` as backed.

### `figl.4` — One-call bounded subtree (C2 / ADR-2) (Windows deploy)
- **Do:** `get-node-properties` gains an optional `depth` (absent ≡ today's single node, exactly)
  + a `maxNodes` cap; the plugin recurses the *same* `serializeNodeDetailed` over children.
- **Deploy:** Windows (plugin).
- **Verify:** `depth` absent returns the unchanged single-node shape; `depth: 2` returns a
  bounded tree in one call; `maxNodes` truncates rather than exceeding the 30s bridge timeout
  (`bridge-server.js:148`); the toolkit's `boundedWalk` can collapse to one call.

### `figl.5` — `resolve-variables` (forced) + async hardening (D1 tokens / ADR-4, ADR-8) (Windows deploy)
- **Do (resolve-variables):** a new tool resolving a node's bound variables via
  `Variable.resolveForConsumer` (`plugin-api.d.ts:11432`), returning resolved value + type per
  bound field. The one capability the Mac client cannot supply.
- **Do (async hardening):** swap sync `figma.getNodeById` (`code.ts:124,132`) → `getNodeByIdAsync`
  (`plugin-api.d.ts:421`) — behavior-preserving under legacy mode, defensive ahead of any
  dynamic-page adoption.
- **Deploy:** Windows (plugin).
- **Verify:** a bound `VariableID` resolves to a concrete value + `resolvedType`; the 14
  `CODEMOJIES` aliases (`tokens.md`) resolve to real bindings; the async swap preserves every
  existing read.

## Seams & open decisions (deferred — surfaced, not resolved)

| id | seam | disposition |
|---|---|---|
| **S-1** | **No-auth bridge.** Any LAN host can drive Figma via `POST /request` (`bridge-server.js`, no token; CORS `*`). | **Accepted standing risk** (Operator, 2026-06-25). Mitigation on file: a one-line shared-secret header checked at `bridge-server.js`, sent by `mcp.js`. **B2 (bridge file-write) is hard-vetoed** while no-auth stands. Revisit if LAN exposure changes. |
| **S-2** | **`get-component-instances`.** Component identity (main component + overrides) for the ~150 repeated tiles, via `getMainComponentAsync` (`:10788`). | **Deferred** (Operator, 2026-06-25). The toolkit already dedups client-side (`extract.mjs:73-75`). Add only when a consumer needs identity — e.g. mapping one Figma component → one React component + N prop-sets for the codemoji-app build. Sibling: a `get-node-tree`/`JSON_REST_V1` tool (C1) if exact REST fidelity is later required. |
| **S-3** | **dynamic-page / `documentAccess`.** The plugin runs legacy mode; no key set. | **Not adopted.** Required only if instances (`getMainComponentAsync`) land. The `figl.5` async swap (ADR-8) prepares the read path so adoption would not break it. |
| **S-4** | **`getStyledTextSegments`.** Per-run typography for mixed text (`:9809`). | **Deferred** from A2 (ADR-3). Add when a TEXT consumer needs per-run styling beyond the current `fontSize`/`fontName`. |
| **S-5** | **Export scale/format options.** `ExportSettings { constraint: { type: 'SCALE'|'WIDTH'|'HEIGHT', value } }` (`:4881`). | **Deferred.** Ship B1's `{path,...}` at default 1× first; add a `scale`/`format` param when a second extraction needs a non-1× render. |
| **S-6** | **Transport F-direct.** Collapse the 3-hop bridge. | **Deferred.** No lived fact reopens the prior F-keep ruling; a plugin cannot host a server, so "direct" only relocates the relay. |

## Decisions ledger (`RULED`)

| D-n | decision | ruling | record |
|---|---|---|---|
| D-1 | image egress | base64 + Mac-side write (B1) | convergent — ADR-1 |
| D-2 | subtree fetch | `depth` param on existing tool (C2) | convergent — ADR-2 |
| D-3 | node enrichment | targeted (A2), auto-layout gated on `layoutMode` | convergent — ADR-3 |
| D-4 | token resolution | `resolve-variables` only; instances client-side | Operator 2026-06-25 — ADR-4, S-2 |
| D-5 | handshake timing | early, with the egress rung | Operator 2026-06-25 — ADR-5 |
| D-6 | dead-tools floor | drop Mac-side first; `get-batch-nodes` re-added `figl.3` | Operator 2026-06-25 — ADR-6 |
| D-7 | transport / auth | keep bridge; no-auth accepted; B2 vetoed | Operator 2026-06-25 — ADR-7, S-1 |
| D-8 | async reads | `getNodeByIdAsync`, folded into `figl.5` | convergent — ADR-8 |

## Verification posture (no CI on the deploy box)

There is no test harness on the Windows machine, so verification is **manual and per-rung**,
run from the Mac after each hand-deploy: reconnect the MCP, call `check-bridge-status` (from
`figl.2` it asserts advertised ⊆ backed), then exercise the rung's new surface against the live
`CODEMOJIES` screen and confirm the toolkit's `extract` still completes end-to-end. The handshake
(`figl.2`) is the closest this topology gets to a regression test: it is the standing check that
a future plugin/`mcp.js` drift can never again advertise a phantom tool. The enhance-and-deploy
runbook for the Windows box — per-rung edits, build/deploy primitives, and the verify steps — is
[figl.prompt.md](figl.prompt.md).

## References

- Design + ADRs: [figl.design.md](figl.design.md) · Overview: [figma-local.md](figma-local.md).
- Method: [aaw.architect-approach.md](../aaw/aaw.architect-approach.md) (surfaced-fork →
  "Seams & open decisions" → `RULED` ledger).
- Working reference implementation + the lived gaps: `node/codemoji-design/`.
- As-built MCP: `mcp/figma-mcp/`.
