# figma-local — enhancement design (`figl`)

> The design doc for enhancing the **figma-local MCP server** so an agent can extract a
> Codemoji game-design screen efficiently and faithfully. It owns one thing — the **surfaced
> forks and the ADRs ruled from them** — and links the rest. Companion: the rung ladder and
> the open seams live in [figl.roadmap.md](figl.roadmap.md); the human-facing overview is
> [figma-local.md](figma-local.md). Method of record: [aaw.architect-approach.md](../aaw/aaw.architect-approach.md)
> (arms argued in four parts → the Operator rules → the chosen arm flows into the build).
>
> **Status:** design ruled (2026-06-25). Two architects (Venus-A capability lens, Venus-B
> steward lens) argued the six forks; the Operator ruled the four genuine divergences. The
> enhancements deploy on the **Windows Figma machine** (Operator-owned, no CI) — this repo is
> the Mac side. No rung is built yet; every `figl.N` below is forward-tense.

## 1. The program in one paragraph

figma-local lets an agent on this Mac read a **live Figma desktop session** running on a
Windows machine, with no Figma API key. A real extraction of the `CODEMOJIES` game screen
(`94:2974`) — run end-to-end through the toolkit at `node/codemoji-design/` — surfaced six
concrete frictions, recorded as `gaps[]` in
`node/codemoji-design/figma/codemojies/manifest.json`. This design turns those lived gaps into
a small, ruled set of MCP enhancements: fix the two true defects first (an image-egress shape
that would blow an agent's context, and two advertised-but-dead tools), then add the few
plugin-side capabilities the Mac client provably cannot supply on its own. The governing
constraint is that the public tool surface is **frozen onto a hand-deployed box with no test
harness**, so every new tool is priced as a multi-year liability, not a feature.

## 2. The architecture (as-built — verified on disk)

Three components, two machines. The agent and this repo live on the Mac; Figma and the plugin
live on Windows; the bridge is the relay that joins them.

| Component | Runs on | Role (verified) | Frozen names |
|---|---|---|---|
| `mcp.js` | Mac (this repo) | stdio MCP server; each plugin-backed tool forwards as HTTP `POST /request {action,params}` to `BRIDGE_URL` (`mcp.js:5`). Post-`figl.1` … `figl.5`, registers **11** tools: the **8** plugin-backed (`get-current-page` · `get-selection` · `get-all-pages` · `find-nodes` · `get-node-properties(nodeId?, depth?, maxNodes?)` · `export-node` · `get-batch-nodes` · `resolve-variables`) plus the **3** Mac-side (`get-figma-document` over the cached `/document` · `check-bridge-status` over `/health` with the advertised-vs-backed handshake · `cleanup-renders` over the bounded `RENDER_ROOT`). `version: "2.0.0"` is a bare label. | the 11 tool ids |
| `bridge-server.js` | Windows (`192.168.3.120`) | HTTP `:3001` (`/health`, `/document`, `POST /request`) + WebSocket `:3000`; pure relay request→plugin→response; ~30s timeout (`bridge-server.js:148`); single connection; **no auth**, CORS `*` (`:63`). | `/request`, `/health` |
| `figma-plugin/` | inside Figma (Windows) | `code.ts` action switch backs **8** actions (`get-current-page`, `get-selection`, `get-all-pages`, `find-nodes`, `get-node-properties(nodeId?, depth?, maxNodes?)`, `export-node`, `get-batch-nodes`, `resolve-variables`); all else falls to `default → "Unknown action"`. `BACKED_ACTIONS` is reported on `ws-connected` (ADR-5). `serializeNodeDetailed` carries cornerRadius (+ per-corner, `figma.mixed`-guarded), auto-layout (only when `layoutMode !== 'NONE'`), and `absoluteBoundingBox` (ADR-3); `serializeSubtree` walks it recursively when `depth` is given, capped by `maxNodes` (default 500) — depth-absent is byte-identical to the pre-figl.4 shape (ADR-2). `resolveVariables` walks node-level boundVariables AND per-paint bindings on fills/strokes/effects/layoutGrids, returning resolved value + type per binding via `Variable.resolveForConsumer` (ADR-4). Every node lookup is async (`figma.getNodeByIdAsync`) — defensive against any future `documentAccess: dynamic-page` adoption (ADR-8). `ui.html` holds the WebSocket (the plugin can only dial *out*). | the 8 actions |

**The boundary.** A rung touches at most the three figma-mcp files plus the Mac-side toolkit
that consumes them (`node/codemoji-design/src/*.mjs`). The bridge stays a **pure relay** — no
arm that turns it into a file server or a stateful store survives (see ADR-1, ADR-7).

**Two cross-cutting findings** (both architects verified independently; both load-bearing):

1. **No `documentAccess` key.** The plugin `manifest.json` declares `"api": "1.0.0"` and omits
   `"documentAccess": "dynamic-page"`, so it runs in **legacy mode**. The deprecated *sync*
   `figma.getNodeById` (`code.ts:124,132`) therefore **works today** — it only throws under
   dynamic-page (`plugin-api.d.ts:423`). The async swap is *latent hardening*, not a live bug
   (ADR-8).
2. **No auth on the bridge.** Nothing in `bridge-server.js` checks a token; any host on the LAN
   can drive the Figma session via `POST /request`, and the plugin manifest sets
   `networkAccess.allowedDomains: ["*"]`. This is a standing accepted risk, not a transport
   fork (ADR-7); it is the reason the bridge-file-write arm (B2) is vetoed.

## 3. The lived extraction (the grounding)

The `CODEMOJIES` run is the evidence every fork is argued from — **not** a hypothetical.
`manifest.json`: 77 nodes, 14 figures, 15 renders, 0 image assets. The six gaps:

| gap | what bit (lived) | the fork |
|---|---|---|
| **egress** | `export-node` returns `{data: Array.from(bytes)}` (`code.ts:141`) — a decimal int-array, ~4–6× the raw bytes; a screen PNG ≈ ~1M tokens if it reached an agent. The toolkit dodges it by decoding to disk (`extract.mjs:97`). | 2 / B1 |
| **tree** | `boundedWalk` makes ~1 `get-node-properties` call per node — 77 nodes ≈ 76 calls (`extract.mjs:60-82`). Bridge-direct, so no *agent-context* cost, but N round-trips. | 3 / C2 |
| **props** | `serializeNodeDetailed` (`code.ts:163-192`) omits cornerRadius, auto-layout (padding/itemSpacing/layoutMode/layoutSizing), `absoluteBoundingBox`, per-run typography. The spec note tells the reader to "read them from the reference PNG" (`spec.md:7`). | 1 / A2 |
| **tokens** | 14 fills carry raw `VariableID:…` aliases printed `UNRESOLVED` (`sortout.mjs:71`); the baked hex is not the token binding. | 4 / D1 |
| **instances** | ~150 repeated emoji tiles, no component identity; the toolkit dedups by cap+sample (`extract.mjs:73-75`). | 4 (deferred, S-2) |
| **dead-tools** | `get-batch-nodes` / `export-batch-nodes` are advertised in `mcp.js:170-202` but throw `"Unknown action"` in the plugin. | 1 / stabilize |

## 4. The surfaced forks (staged, not averaged)

Each fork's arms are argued in full in the two architect positions (transcript of record). Below
is the Director's faithful staging: the arms, both lenses' rankings, and the ruling. The losing
arms keep their `CHOSEN-AGAINST` case in §5.

### Fork 1 — node-property payload + the dead batch tools
- **A1** broad serializer enrichment + implement both dead handlers · **A2** targeted
  enrichment (only the named gaps) + `get-batch-nodes` only · **A3** no serializer change, just
  drop the dead registrations.
- Venus-A: **A2 ≫ A1 > A3**. Venus-B: **drop-the-lie first, then A2**. Both rejected A1 — the
  serializer is *shared by `get-selection`* (`code.ts:98,128`), so broad enrichment bloats the
  selection payload, and `figma.mixed` is a non-serializable `unique symbol` (`:909`) that
  `JSON.stringify` silently mangles on a box with no CI.
- **Convergent → ruled A2**, with the dead-tool removal split out as its own zero-deploy floor
  (Operator ruling, §5 ADR-6).

### Fork 2 — image egress
- **B1** plugin `base64Encode` → Mac decodes/writes → returns `{path,w,h,byteLen}` · **B2**
  bridge writes the file on Windows, returns a path/URL · **B3** status-quo int-array.
- Both ranked **B1** first. Both **veto B2**: it makes the no-auth bridge an arbitrary-file
  writer and lands the artifact on the machine the agent is *not* on. B3 is a footgun for any
  agent not using the toolkit's disk dodge.
- **Convergent → ruled B1** (§5 ADR-1).

### Fork 3 — subtree fetch
- **C1** new `get-node-tree` over `exportAsync({format:'JSON_REST_V1'})` · **C2** a `depth`
  param on the existing `get-node-properties` · **C3** status-quo 1-call-per-node.
- Both ranked **C2** first — even the capability lens, because C1's `JSON_REST_V1` returns a
  *different shape* than every other tool, buying drift-resistance at the price of a **second
  node schema** to learn and freeze. C2 is "one shape, deeper."
- **Convergent → ruled C2** (§5 ADR-2).

### Fork 4 — semantic resolution
- **D1** `resolve-variables` (via `Variable.resolveForConsumer`) **+** `get-component-instances`
  (via `getMainComponentAsync` + overrides + dedup) · **D2** leave raw aliases + repeated tiles;
  resolve/dedup Mac-side.
- Both agree **`resolve-variables` is *forced*** — the only gap with no client-side path: the
  typings state `valuesByMode` "will not resolve any aliases" (`plugin-api.d.ts:11441`); only
  `resolveForConsumer(consumer: SceneNode)` (`:11432`) resolves, and it needs a node context that
  exists only inside the plugin. **Divergence on instances:** Venus-A bundles the tool; Venus-B
  splits it off (the toolkit already dedups; component *identity* was not needed in the run).
- **Operator ruled: `resolve-variables` only**; instances stay client-side, the tool deferred to
  a seam (§5 ADR-4, S-2).

### Fork 5 — selection anchoring + the wire/version fence
- **E1** explicit nodeId, selection a discovery helper, version a loose label · **E2** selection
  default when nodeId omitted **+** a strict capability handshake so `mcp.js` advertises only
  what the deployed plugin backs (advertised == live), surfaced via `check-bridge-status`.
- Both want **E2** — the dead tools are the empirical proof that hand-sync fails silently.
  **Divergence on timing:** Venus-B ships the handshake *early* (the "immune system" guarding
  every later rung); Venus-A ships it *last* (the one standing new protocol, once the surface is
  final).
- **Operator ruled: early** — the handshake ships with the egress rung (§5 ADR-5).

### Fork 6 — transport topology (record-only)
- **F-keep** the 3-hop bridge (already ruled) · **F-direct** collapse the bridge.
- Both keep the bridge: every gap is payload/semantics, not transport, and a Figma plugin
  cannot host a server, so "direct" only relocates the relay into `mcp.js`. The no-auth posture
  is a cross-cutting Steward note, not a topology decision.
- **Convergent → ruled F-keep**; no-auth accepted as a standing risk (§5 ADR-7, S-1).

## 5. The ADRs (ruled)

Each ADR records the ruling (`RULED`) and the best case for the path not taken
(`CHOSEN-AGAINST`), so the decision stays inspectable a year on.

### ADR-1 — image egress is base64 + a Mac-side write
**RULED (B1).** `export-node` returns `{path, w, h, byteLen}`. The plugin encodes export bytes
with `figma.base64Encode` (`plugin-api.d.ts:1886`); `mcp.js` base64-decodes, writes to a bounded
Mac path, and returns metadata only — no bytes in the tool result. The toolkit's existing
decode-to-disk (`extract.mjs:97`) is updated in **lockstep** so the working client never breaks
on the un-tested box.
**CHOSEN-AGAINST:** B2 (bridge writes on Windows) gives the smallest wire but makes the no-auth
relay a file writer and lands the file on the wrong machine; B3 (int-array) is a context-blowing
footgun for any non-toolkit caller. New invariant: `mcp.js` gains a *bounded* filesystem write
(temp dir + cleanup) — specify the write root or it ages into orphaned files.

**Cleanup addendum (Operator 2026-06-26, ruled with figl.2).** Cleanup is an **explicit MCP
tool**, not an implicit background sweep — no surprise deletions, no daemon state, the agent
decides when to run it. The `cleanup-renders` tool takes `keepLast` (int — keep the N most
recent) and/or `keepSince` (`"1h"` / `"30m"` / `"24h"` / `"7d"` / bare ms — keep files newer
than the cutoff); a file is **kept if it satisfies either rule** (so the two parameters are
additive guards, never restrictive). `dryRun: true` lists what would be deleted without
acting. At least one of `keepLast` / `keepSince` is required (the empty call would mean
"delete everything," which is too dangerous to be implicit). The render root is
`FIGMA_MCP_RENDER_ROOT` or `os.tmpdir()/figma-mcp-renders`. **CHOSEN-AGAINST:** a background
TTL sweep (would delete a render the agent was about to re-use) and trusting OS temp cleanup
(unreliable across macOS/Linux/Docker, and the long-running MCP process keeps the dir alive).

### ADR-2 — subtree fetch is a `depth` param on the existing tool
**RULED (C2).** `get-node-properties` gains an optional `depth` (absent ≡ today's single-node
behavior, exactly). The plugin recurses the *same* `serializeNodeDetailed` over children to that
depth, bounded by a `maxNodes` cap so a deep page cannot exceed the 30s bridge timeout
(`bridge-server.js:148`). One node shape, deeper.
**CHOSEN-AGAINST:** C1 (`get-node-tree` over `JSON_REST_V1`, `plugin-api.d.ts:5017`) is Figma's
native recursive serializer and drift-resistant, but it returns the REST shape — a *second* node
schema the surface must keep coherent forever. The one-schema simplicity outweighs native
drift-resistance; if exact REST fidelity is later required, `get-node-tree` is added then,
having cost nothing now (S-2-adjacent).

### ADR-3 — node-property enrichment is targeted, not broad
**RULED (A2).** `serializeNodeDetailed` gains exactly the fields the run could not work around:
`cornerRadius` (+ per-corner) behind a `figma.mixed` guard; the four auto-layout fields
(`layoutMode`, padding, `itemSpacing`, `layoutSizing*`) **emitted only when
`layoutMode !== 'NONE'`**; `absoluteBoundingBox` (`plugin-api.d.ts:6976`).
**CHOSEN-AGAINST:** A1 (broad, + `getStyledTextSegments`) over-freezes a no-CI surface and — because the serializer is shared by `get-selection` — bloats the selection payload too.
`getStyledTextSegments` (`:9809`) is deferred to a seam (S-4); a missing field is an additive
minor next rung, not a wire break.

### ADR-4 — token resolution is a plugin-only `resolve-variables`; instances stay client-side
**RULED (D1, tokens half only).** A new `resolve-variables` tool resolves a node's bound
variables via `Variable.resolveForConsumer` (`plugin-api.d.ts:11432`), returning the resolved
value + type per bound field. This is the one capability the Mac client *physically cannot*
supply (`valuesByMode` "will not resolve any aliases", `:11441`).
**Operator ruling (Fork 4):** `get-component-instances` is **not** shipped — the toolkit already
dedups ~150 tiles by cap+sample (`extract.mjs:73-75`) and the run never needed component
*identity*. **CHOSEN-AGAINST:** bundling instances would freeze a tool to re-solve a
client-solved problem; deferred to S-2 (add only if a consumer needs identity, e.g. mapping one
Figma component → one React component + N prop-sets for the codemoji-app build).

### ADR-5 — an advertised==live capability handshake, shipped early
**RULED (E2, early).** The plugin reports its backed-action list (it already knows it — the
`code.ts:20-41` switch); `/health` returns it; `mcp.js` asserts its advertised set ⊆ the backed
set and **flags** (never bricks) a mismatch, surfaced via `check-bridge-status`. Selection-default
(nodeId omitted ⇒ `figma.currentPage.selection`) rides along as ergonomic sugar; explicit
nodeId stays the addressing model.
**Operator ruling (Fork 5):** ships in the **egress rung**, not last — so every later capability
lands deploy-checked on the no-CI box. **CHOSEN-AGAINST:** E1 (loose version label) preserves the
exact condition that produced the dead tools; late delivery (Venus-A) leaves the early rungs
unguarded on the box where code and deploy drift independently. The handshake must degrade to a
warning, not a hard fail, or it could brick the Mac server against an older deployed plugin.

### ADR-6 — the dead tools are dropped Mac-side first
**RULED (Operator, Fork 1 floor).** `figl.1` deletes the two dead registrations in
`mcp.js:170-202` — a Mac-side, version-controlled change with **zero Windows deploy** —
restoring advertised==live immediately and proving the loop before the hand-deployed box is
touched. `get-batch-nodes` is re-implemented in the enrichment rung (`figl.3`);
`export-batch-nodes` stays dropped (superseded by file-based egress, ADR-1).
**CHOSEN-AGAINST:** implementing `get-batch-nodes` in the first rung (the wire half already
exists) would ship the batch read sooner but forces a Windows deploy on rung one.

### ADR-7 — keep the bridge; no-auth is an accepted standing risk
**RULED (F-keep + Operator, Fork 6).** The 3-hop topology stands; the bridge remains a pure
relay. The no-auth exposure is accepted as a standing risk and recorded as a seam (S-1) with a
near-zero-cost mitigation on file (a shared-secret header checked at `bridge-server.js`). The
**B2** bridge-file-write arm is **hard-vetoed** while no-auth stands.
**CHOSEN-AGAINST:** adding auth now is deferred (orthogonal to the extraction bottleneck);
F-direct rewrites a shipped, ruled topology for zero fidelity gain.

### ADR-8 — the async `getNodeByIdAsync` swap is latent hardening, sequenced defensively
**RULED.** Because the plugin runs in legacy mode (no `documentAccess` key), the sync
`getNodeById` works today; the swap to `getNodeByIdAsync` (`plugin-api.d.ts:421`) is *latent*
hardening, not a live bug. It is folded into the `resolve-variables` rung (`figl.5`) as a
defensive companion, ahead of any future dynamic-page adoption (which would make the sync form
throw, `:423`).
**CHOSEN-AGAINST:** a dedicated async-only rung (Venus-A's `figl.2`) is correct but spends a
deploy on a change with no user-visible effect; folding it into `figl.5` pays the deploy once.

## 5b. The export + embed extension — ADRs (`figl.6`–`figl.8` · 2026-06-27)

The 2026-06-27 Operator ask — high-fidelity + React-suitable export, then a context-embeddable
payload "for efficient LLMs token usage" — extends the program past extraction. The export-direction
fork (a structured **Bundle IR** vs. ready-to-render **Codegen**) was argued in full via the
two-architect method in
[export.design.md](../codemojex-tma/kb/figma-livesync/export.design.md) and **ruled Bundle (staged)**.
These four ADRs record that ruling and the three additive decisions the new rungs turn on; the rungs
are in [figl.roadmap.md](figl.roadmap.md).

### ADR-9 — export is a structured FigureBundle IR; codegen deferred
**RULED (Bundle, staged — Operator 2026-06-27).** `export-figure` returns a thin **FigureBundle**:
resolved geometry + CSS-style props + text runs + token *references* (`{token, value}`) + asset *refs*
— a data contract a renderer or agent turns into React. Token-by-reference is *why* Bundle won: the
plugin emits the variable *name* and the consumer's `@theme` map decides the class; codegen would have
to guess it.
**CHOSEN-AGAINST:** Codegen (emit `.tsx` directly) is closest to drop-in but freezes a styling-target
guess (inline / CSS-module / Tailwind) onto a no-CI plugin surface and carries a codegen-maintenance
liability. Deferred behind a **named seam** — a Mac-side `export-react` scaffold reads the FigureBundle
and emits `.tsx`, additive on top, no rework — revisited when a second consumer proves the Tailwind
target stable. Full case: export.design.md.

### ADR-10 — figure assets are humanized, stable, and by-reference (SVG to disk, not inline)
**RULED-pending (recommend).** Both vectors and rasters write to a **stable, humanized** path
(`<ASSET_ROOT>/<screen-slug>/<layer-slug>[-<shortId>].<ext>`); the bundle carries lightweight metadata
only (`{id, node, name, type, w, h, scale, byteLen, path}`). This extends ADR-1 (bytes never in the
result) with the two properties reuse needs: **stable** names (not the timestamped ephemeral render
filename, `mcp.js:99` — a path you can re-reference) and **humanized** names (the Figma layer slug, not
`94_2974`). A separate `assets/` subdir keeps reusable assets — `cleanup-renders` already lists only
top-level files (`mcp.js:305`), so the subdir is unswept for free.
**CHOSEN-AGAINST:** inline SVG in the bundle (attractive for tiny icons, but bloats the result the
*context* pays for and is not independently reusable — counter to "save locally for future use"); the
timestamped `RENDER_ROOT` name (cleanup-friendly but not a stable reference). The `svg:'inline'`
toggle preserves the inline option for the small-icon case.

### ADR-11 — the screen registry is Mac-side and read-only (no Figma mutation)
**RULED-pending (recommend).** Naming overrides live in a Mac-side `screens.json`
(`{type, name, figure, slug, updatedAt}`), assigned via `name-screen` (selection-default) and read via
`list-screens`. Naming **never mutates the Figma document** — it maps a human name onto a node id on
the Mac. This keeps the whole program read-only against the live design and needs **no new plugin
*write* capability** (the highest-liability class on a no-CI box).
**CHOSEN-AGAINST:** writing the name back into the Figma layer (a plugin mutation — deferred to S-7,
gated behind the no-auth seam S-1); Figma `clientStorage` (couples the registry to one machine's plugin
state and is not version-controllable). The selection-driven batch is a **mode** of the existing
`get-selection` + `export-figure`, not a new tool — holding tool-count liability flat.

### ADR-12 — `llms.txt` is an index plus an embedded payload; bytes by-reference
**RULED-pending (recommend).** `export-llms` emits the llmstxt.org-format **`llms.txt`** index *and* a
**payload** (`llms-full.txt`) that inlines the compact structural skeleton + the token table + the
asset manifest (paths only). The split mirrors the convention's `llms.txt` / `llms-full.txt` pair: the
index for cheap discovery, the payload for one-read context embedding. Heavy bytes stay by-reference
(ADR-1 carried forward) — the payload is the *map*, the humanized assets are the *territory*.
**CHOSEN-AGAINST:** index-only (forces an agent to chase N links before it can reason — defeats
"efficient context embedding"); a payload that inlines bytes (re-introduces the ~1M-token egress ADR-1
exists to prevent). Embed depth is a knob (S-8); default skeleton + tokens + manifest.

## 6. References

- The method: [aaw.architect-approach.md](../aaw/aaw.architect-approach.md) (four-part arms, the
  multi-architect debate, surfaced-fork → "Seams & open decisions").
- The rung ladder + the open seams: [figl.roadmap.md](figl.roadmap.md).
- The overview + the as-built tool surface: [figma-local.md](figma-local.md).
- The lived extraction + the working reference implementation of the proposed tools:
  `node/codemoji-design/` (`figma/codemojies/manifest.json`, `src/{extract,bridge,sortout}.mjs`).
- The as-built MCP: `mcp/figma-mcp/{mcp.js,bridge-server.js,figma-plugin/code.ts}`.
- API surfaces verified in `@figma/plugin-typings@1.130.0` (`plugin-api.d.ts`) at the lines cited
  inline.
