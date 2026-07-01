# Codemoji Dev Toolkit — Tauri v2 shell over a Phoenix-served React app

A native developer toolkit that wraps your existing Phoenix-served React SPA in a
Tauri v2 window and overlays a **Channel event panel**. The panel taps every
Phoenix Channel frame by wrapping `window.WebSocket` through a Tauri
initialization script, so it works against the app Phoenix already serves — no
change to your React build.

## What changed from the Ultralight build

Tauri renders in the **system webview** (WKWebView, WebView2, WebKitGTK). Two
consequences, both in your favour:

1. **WebSocket works natively.** `phoenix.js` connects to your Channels with the
   ordinary browser transport. There is no native socket bridge, no marshalling
   thread, no `__bridge_recv`. The dev panel taps by wrapping `window.WebSocket`.
2. **The app can stay remote.** The window points at the Phoenix URL; Phoenix
   serves the React app exactly as it does in a browser. The toolkit is a wrapper,
   not a fork of your front-end.

## Three ways to run it

- **A — Wrap the remote app (this scaffold).** The window loads the Phoenix URL
  via `WebviewUrl::External`, and the dev panel is injected with
  `initialization_script`. Nothing about your React build changes. Best when the
  toolkit should mirror the live app.
- **B — Bundle the React build.** Set `build.frontendDist` to your built assets
  and drop the panel in as a React component; the app talks to Phoenix over
  Channels/HTTP. Best for an offline-capable, signed, distributable tool with full
  Tauri IPC.
- **C — Hybrid (multiwebview).** Bundle a thin toolkit chrome (menus, panel, Rust
  taps) and load the Phoenix app in an inner webview or a second window. Tauri v2
  supports multiple webviews per window. Best when you want native toolkit chrome
  around an app you do not want to modify.

This scaffold implements **A**. Notes below cover switching to B/C.

## Layout

```
codemoji-devtools/
  src-tauri/
    tauri.conf.json          v2 config: no auto window, DeveloperTool bundle, CSP
    capabilities/default.json core IPC + websocket plugin + remote Phoenix allowlist
    Cargo.toml
    build.rs
    src/
      main.rs
      lib.rs                 creates the window at PHX_APP_URL, injects the panel
  dev-panel/
    inject.js                WebSocket tap + event panel (injected at document-start)
```

## Run

```bash
# 1) start Phoenix separately (it serves the welcome + lobby + the injected game)
#    e.g. from echo/apps/codemojex:  mix phx.server   -> http://localhost:4000

# 2) launch the toolkit shell — wraps http://localhost:4000 by default.
#    No Tauri CLI needed: `cargo run` opens the window directly (the window points at
#    an EXTERNAL url, so there is no local dev server to wait on).
bin/run.sh
#    …or without the helper:
PHX_APP_URL=http://localhost:4000 cargo run --manifest-path src-tauri/Cargo.toml

# point at another instance:
PHX_APP_URL=https://codemojex.fly.dev bin/run.sh

# optional — HMR + Rust hot-reload + devtools (needs `cargo install tauri-cli`):
cargo tauri dev        # waits for build.devUrl (localhost:4000); start Phoenix first

# build installers (needs the CLI):
cargo tauri build
```

Toggle the panel with **Ctrl + `** or the `events` button. Rows show time,
direction (↑ out / ↓ in), topic, event, and ref; click to expand the decoded
payload. Heartbeats are dimmed, `phx_reply` is green, `phx_error`/`phx_close` red.
`export` writes the captured log to a file via the `export_events` command (or a
Blob download if IPC is unavailable).

## Gotchas that will bite otherwise

- **CSP `connect-src`.** In **bundled** mode Tauri injects the CSP from
  `tauri.conf.json`, and the socket is blocked unless every Phoenix origin plus
  `ws://`/`wss://` is in `connect-src` (already listed in the config). In **remote**
  mode the page is served by Phoenix, so **Phoenix's** CSP governs the socket — set
  it there, not here.
- **Remote IPC allowlist.** A remotely-served page reaches Tauri commands only if
  its origin is in a capability's `remote.urls` (done in `capabilities/default.json`)
  and `withGlobalTauri` is on. Without it, `export` silently falls back to a download.
- **Initialization script timing.** `initialization_script` runs at document-start,
  before page scripts, which is why the `WebSocket` wrap is in place before
  `phoenix.js` connects. The panel DOM is built on `DOMContentLoaded`.
- **Switching to bundled (B).** Remove the `WebviewUrl::External` window in `lib.rs`,
  set `build.frontendDist`, let the default window load the bundle, and either keep
  the injected panel or import a React component version.

## Making it a real toolkit, not just a viewer

A Channels tap sees channel traffic only. To reach the runtime — processes, ETS,
telemetry, message-queue depth — add one of these to the Rust side, which the
webview cannot do on its own:

- **Rust WebSocket** (`tauri-plugin-websocket`, already wired) for a privileged or
  second connection the page must not hold — e.g. an admin socket.
- **A privileged admin endpoint** on Phoenix that the Rust core calls, exposing
  EchoMQ telemetry (queue depth, in-flight, consumer lag) the player-facing
  channels never carry.
- **A distribution-connected node.** For deep diagnostics, have the Rust core (or a
  sidecar) attach to the BEAM over Erlang distribution / an RPC endpoint. As covered
  earlier, a connected node beats a Channels client for a developer tool because it
  sees the whole runtime; surface that data through a Tauri command into the panel.
- **Native menu + multiwindow** for a second webview showing a custom LiveDashboard
  page alongside the wrapped app.
