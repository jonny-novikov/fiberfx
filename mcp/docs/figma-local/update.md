# figma-local — update (the development loop)

> How to change or add to the surface safely, on a **frozen, hand-deployed, no-CI** wire. Install:
> [setup.md](setup.md). Ship what you build: [deploy.md](deploy.md). The contract you build *to*:
> [`docs/figma-local/`](../../../docs/figma-local/) (`figl.design.md` ADRs + `figl.roadmap.md` rungs).

## The mental model: source vs artifact, Mac vs Windows

| File | Role | Lives | Edited by |
|---|---|---|---|
| `figma-plugin/code.ts` | **The plugin source of truth** — the action `switch` + every handler. | repo | you |
| `figma-plugin/code.js` | The **compiled artifact Figma runs** (manifest `main`). `tsc` builds it from `code.ts`. | repo | **never by hand** — regenerate |
| `mcp.js` | The Mac-side MCP server — tool registrations + the bridge client + disk egress. | repo | you |
| `figure.js` | Pure Mac-side transforms (the figl.6 FigureBundle projection). No figma, no I/O. | repo | you |
| `figure.test.mjs` | The projection's regression test (`node figure.test.mjs`). | repo | you |
| `bridge-server.js` | The relay. **Rarely** touched — keep it a pure relay (no action switch). | repo | rarely |

Two split lines drive everything below:

- **Source vs artifact:** you edit `code.ts`; the deploy machine runs `code.js`. They must agree.
- **Mac vs Windows:** `mcp.js`/`figure.js` run on the Mac; `code.js`/the bridge run on Windows. A
  change to each has a different deploy shape ([deploy.md](deploy.md)).

## ⚠ The drift hazard (load-bearing)

`code.js` is generated, but it is **committed**, so it *can* be hand-edited and silently diverge from
`code.ts`. If it does, the next `pnpm build-plugin` **reverts the hand-edit** — the deployed behavior
vanishes with no error.

This bit once already: scale/Retina support was hand-edited into `code.js` while `code.ts` stayed at
1×. figl.6 / Phase 0 closed that specific instance by porting scale into `code.ts`; the **rule
stands**:

> **Port any `code.js` change back into `code.ts` before anyone rebuilds.** Check they agree:
> `grep -n exportAsync figma-plugin/code.*` (the two must match).

> **Note — `code.js` is tracked despite `.gitignore`.** `figma-mcp/.gitignore` lists
> `figma-plugin/*.js`, yet `code.js` is tracked (added before the rule). So it ships in commits *and*
> is rebuilt on the deploy box. Treat `code.ts` as canonical; if you'd rather `code.js` were a pure
> build artifact, that's an Operator call (`git rm --cached figma-plugin/code.js`) — don't flip it silently.

## Adding or changing a tool — the 3-site registration

A plugin action lives in **three places that must move together** (a comment in `code.ts` says so):

1. **`code.ts`** — a `case` in the action `switch` + its handler, **and** the action name in
   `BACKED_ACTIONS` (the plugin's self-reported capability list, sent on connect).
2. **`mcp.js`** — the action name in `ADVERTISED_ACTIONS` **and** a `server.registerTool(name, {…Zod…}, handler)`.
3. **rebuild** — `pnpm build-plugin` so `code.js` carries the new handler.

The **capability handshake** reconciles (1) vs (2): the plugin sends `backed-actions` → `bridge`
caches it → `/health` returns `backedActions` → `check-bridge-status` asserts `ADVERTISED ⊆ backed`.
A mismatch is a **WARN, never a hard fail**. Until the Windows human reloads, a newly-added action is
**"Unknown action"** on the live plugin even though `mcp.js` already advertises it — that's expected,
and the handshake names it.

**Worked example — `export-figure` (figl.6):**

- `code.ts`: `case 'export-figure'` → `async function exportFigure(...)`; `'export-figure'` added to `BACKED_ACTIONS`.
- `mcp.js`: `'export-figure'` added to `ADVERTISED_ACTIONS`; a `registerTool("export-figure", {Zod}, handler)`.
- the handler calls `buildFigureBundle` from `figure.js` and writes assets to disk.

Template to copy: `get-batch-nodes` / `resolve-variables` (the figl.3 / figl.5 additions).

## The plugin / `figure.js` split (the no-CI strategy)

The plugin **cannot run on the Mac** and **cannot be unit-tested** before the Windows deploy. So keep
its new code minimal and *figma-only*, and push every pure-data transform to the Mac:

- **In `code.ts` (untestable here):** only what needs the figma.* API — node reads
  (`serializeNodeDetailed`), token resolution (`resolveForConsumer`), asset export (`exportAsync`).
  Return **raw** payloads.
- **In `figure.js` (Mac-testable):** every pure transform — RGBA→hex, fills→`background`,
  auto-layout→flex, box-shadow, token-name→`--css-var`, humanized naming, the disk-egress *plan*.

This way the only thing riding on the un-testable deploy is the thin figma gather; the bundle's
shaping is proven on the Mac by `figure.test.mjs` *before* the plugin is reloaded.

## The Mac-side gate (run before every hand-off)

Everything the Mac *can* verify with no Figma:

```bash
cd /Users/jonny/dev/jonnify/mcp/figma-mcp

# 1. plugin type-checks against the real typings (NO-INVENT)
TMPDIR=/tmp npx tsc -p figma-plugin/tsconfig.json --noEmit       # → clean (exit 0)

# 2. build code.js from code.ts (closes drift; this is what Windows will run)
pnpm build-plugin
grep -n exportAsync figma-plugin/code.*                          # code.ts and code.js must agree

# 3. the Mac modules parse + the projection test passes
node --check mcp.js && node --check figure.js
node figure.test.mjs                                             # → N checks passed

# 4. the handshake sets line up (advertised ⊆ backed)
#    compare ADVERTISED_ACTIONS (mcp.js) ⊆ BACKED_ACTIONS (code.js)
```

What this **cannot** prove: the live figma.* behavior (the actual node walk, export, token
resolution against a real screen). That validates only on the Windows deploy — call it out in the
hand-off. → [deploy.md](deploy.md).

## NO-INVENT

The surface is frozen onto a box with no test harness, so every new tool is a multi-year liability.
Before using any `figma.*` call, verify it against `@figma/plugin-typings` at a cited line — e.g.

```bash
TYP=$(find node_modules -name plugin-api.d.ts | head -1)
grep -n 'base64Encode\|ExportSettingsSVGString' "$TYP"
```

Cite the line in a code comment and in the matching ADR. Prefer **thin-but-robust**; defer anything
speculative to a seam in `figl.roadmap.md`.

## Lockstep (the working client must never break)

A change to the **wire contract** moves three things in one window: the plugin (`code.ts`), the Mac
client (`mcp.js`), and the toolkit `node/codemoji-design/src/*.mjs` (the reference client). Deploy
them together and run the handshake immediately after — on a no-CI box, `advertised ⊆ backed` is the
regression check. Detail: [`figl.prompt.md`](../../../docs/figma-local/figl.prompt.md#lockstep-rule-the-no-ci-safeguard).

Ready to ship → [deploy.md](deploy.md).
