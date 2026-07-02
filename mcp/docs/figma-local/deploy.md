# figma-local — deploy (the runbook)

> Ship a built change to the live surface. Build it first: [update.md](update.md). The rung-by-rung
> build scope (figl.1–6) is [`figl.prompt.md`](../../../docs/figma-local/figl.prompt.md) — this page
> is the **general** deploy procedure for *any* change.

## Why deploy is two-part

The surface spans two machines, and the artifact (`code.js`) runs on a *different* machine than the
repo. So a change can need an action on **either or both**:

| You changed | Deploy shape | Locus |
|---|---|---|
| `figma-plugin/code.ts` | `pnpm build-plugin` → **reload the plugin in Figma** | Windows + a human in Figma |
| `bridge-server.js` | **restart the bridge** (`pnpm bridge`) + reload the plugin so it reconnects | Windows |
| `mcp.js` / `figure.js` | **sync to the Mac + reconnect the MCP** (`/mcp`) | Mac |
| `figma-plugin/manifest.json` | re-import the plugin (Plugins → Development → Import from manifest) | Windows + Figma |

> **Reverting source is not enough.** The deployed artifact is `code.js`. To change *or roll back* a
> plugin behavior you must **rebuild and reload** — editing `code.ts` alone does nothing live.

**What no agent can do:** the Figma reload is a manual click (Plugins → Development → re-run); the Mac
cannot rebuild or reload the plugin. Plan the hand-off accordingly.

## Step-by-step

Locus tags: `[WIN]` Windows checkout · `[FIGMA]` a human in Figma Desktop · `[MAC]` this repo.

### If `code.ts` changed (the common case)

1. `[WIN]` Pull the change into the Windows checkout (`C:\dev\jonnify\mcp\figma-mcp` — confirm the
   path with the Operator).
2. `[WIN]` `pnpm build-plugin` — regenerates `code.js` from `code.ts`.
3. `[FIGMA]` **Plugins → Development → Figma MCP Bridge** (re-run) → loads the new `code.js`; confirm
   the UI says **"Connected to bridge"**.
4. `[MAC]` If `mcp.js`/`figure.js` also changed, sync them and **reconnect** the MCP (`/mcp` in Claude
   Code, or `claude mcp remove/add`).
5. Verify — see [§Verify](#verify-the-handshake--smoke-test).

### If only `mcp.js` / `figure.js` changed (Mac-only — no Windows touch)

1. `[MAC]` The files are in-repo; just **reconnect** the MCP (`/mcp`). New tools/params load on reconnect.
2. Verify.

### If `bridge-server.js` changed

1. `[WIN]` Restart the bridge: stop the `pnpm bridge` process, start it again.
2. `[FIGMA]` The plugin auto-reconnects within ~3 s; confirm "Connected to bridge".
3. Verify (especially anything reading `/health`).

## Verify (the handshake + smoke-test)

There is **no CI** on the deploy box, so verification is manual and the handshake is the regression test.

1. **Reachability** — `[MAC]` or `[WIN]`:
   ```bash
   curl http://192.168.1.120:3001/health
   # {"status":"ok","connected":true,"hasDocument":true,"backedActions":[ … ]}
   ```
2. **Handshake** — from a Claude session: `check-bridge-status` →
   `handshake.status:"ok"` and your new action present in `backedActions`. `warn` ⇒ the plugin wasn't
   reloaded (advertised but not backed); `unknown` ⇒ no plugin connected.
3. **Smoke-test the change** against the live `CODEMOJIES` screen (`94:2974`). For `export-figure`:
   select the frame → `export-figure` (no args = selection) → expect a thin FigureBundle with token
   refs + humanized `.svg`/`.png` under `<FIGMA_MCP_ASSET_ROOT>/<screen-slug>/`, and **no bytes** in
   the result.
4. **Regression** — confirm a prior tool still works (e.g. `export-node 94:2974` returns a `{path,…}`).

## Rollback

Each change is one change-set. To roll back a **plugin** change:

1. `[WIN]` Revert the change-set in the Windows checkout.
2. `[WIN]` `pnpm build-plugin` (rebuild the *old* `code.js`).
3. `[FIGMA]` Reload the plugin (and `[WIN]` restart the bridge if `/health` changed).
4. `[MAC]` Revert + reconnect if `mcp.js`/`figure.js` were part of it.

Because the plugin is the deployed artifact, **reverting source without a rebuild + reload leaves the
old behavior live.**

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| New tool returns **"Unknown action"** | Plugin not reloaded — `mcp.js` advertises it, the live `code.js` doesn't back it | `[WIN]` `pnpm build-plugin` → `[FIGMA]` reload; `check-bridge-status` should flip it backed |
| `check-bridge-status` → `handshake:"warn"` | Same as above (advertised ⊄ backed) | Reload the plugin; re-run the handshake |
| `check-bridge-status` → `connected:false` | Plugin not running in Figma | `[FIGMA]` Plugins → Development → Figma MCP Bridge |
| Any tool call fails outright | Bridge process down | `[WIN]` restart `pnpm bridge`; `curl …/health` from the PC |
| `curl` from the Mac times out | Firewall rule missing / Mac off-subnet | Check the TCP 3001 rule; `ipconfig getifaddr en0` ([setup.md](setup.md#5-open-the-firewall-for-the-mac-one-time)) |
| Tool calls **hang ~30 s then error** | Request reached the plugin but it never replied (handler threw silently / heavy walk) | Check the plugin handler; the bridge caps at 30 s (`bridge-server.js:153`) — bound walks with `depth`/`maxNodes` |
| A deployed change **reverted** after a rebuild | A `code.js` hand-edit not ported to `code.ts` | Port it into `code.ts`, rebuild (the drift hazard — [update.md](update.md#-the-drift-hazard-load-bearing)) |
| Mid-build `ENOSPC` / spurious I/O on `mix`-adjacent runs | tmp overlay | prefix `TMPDIR=/tmp` (Mac-side builds) |

Deeper Mac/firewall/security troubleshooting: [`MAC-CLIENT.md`](../../figma-mcp/docs/MAC-CLIENT.md#troubleshooting).

## Done criteria

The change is deployed when: `check-bridge-status` reports `advertised ⊆ backed` with the new action
listed, the smoke-test passes against `94:2974`, and a prior tool still works. Record the outcome —
on a no-CI box the deploy report *is* the test record.
