# Codemojex · Developing & Testing the Render Stack in the Browser

How to boot the [render stack](render-stack.md) locally, why a plain browser hitting `/lobby` bounces
to the welcome, and how to drive the authenticated lobby/game — and screenshot it — with the
Playwright e2e harness, **without a Telegram client and without a dev auth bypass**.

> **TL;DR.** `mix` does **not** load `.env`, so source it first:
> ```
> cd echo/apps/codemojex && set -a && source ../../.env && set +a && TMPDIR=/tmp MIX_ENV=dev mix phx.server
> ```
> Open **http://localhost:4000** (use `localhost`, not `127.0.0.1` — origin checks). A plain browser at
> `/lobby` redirects to `/` because there is no Telegram session — that is the auth gate, not a bug. To
> see the authenticated lobby/game, run the e2e harness in
> [`node/codemojex-e2e/`](../../../node/codemojex-e2e) (`npm test` / `npm run test:headed`), which forges
> a real signed session.

---

## 1. Prerequisites

| Need | Why | Check |
|---|---|---|
| **Valkey** on `:6390` | the EchoMQ bus + competitive state | `valkey-cli -p 6390 ping` → `PONG` |
| **Postgres** `codemojex_dev` | the Repo (crucial data) | `cd echo/apps/codemojex && TMPDIR=/tmp MIX_ENV=dev mix ecto.create && mix ecto.migrate` |
| **Node 22 + npm** | building the committed `app.js` (one-time) | `node --version` |
| committed **`priv/static/assets/app.js`** | the LiveView client (no JS build step in prod) | `ls echo/apps/codemojex/priv/static/assets/app.js` |
| **`TMPDIR=/tmp`** for every `mix` | the harness tmp overlay can hit ENOSPC | — |

## 2. Booting the dev server

**`mix` has no built-in dotenv** — nothing in the umbrella loads `echo/.env`. If you run
`mix phx.server` directly, none of `.env`'s vars (`CODEMOJI_BOT_TOKEN`, `DATABASE_*`, AWS/Tigris) are in
the environment. Source it into the shell first:

```bash
cd echo/apps/codemojex
set -a && source ../../.env && set +a          # export every var from echo/.env (it is gitignored)
TMPDIR=/tmp MIX_ENV=dev mix phx.server
```

A clean boot logs `Running CodemojexWeb.Endpoint with Bandit … at 127.0.0.1:4000`. Then:

```
curl -s  localhost:4000/api/health   # 200  (JSON API)
curl -sI localhost:4000/             # 200  (legacy PageController landing)
curl -sI localhost:4000/lobby        # 302 → /   (auth gate; see §4)
```

> In dev, the Repo uses the local `codemojex_dev` from `dev.exs` — `DATABASE_URL` in `.env` is only read
> in `:prod` (`runtime.exs`), so sourcing it is harmless here.

## 3. Building the front-end assets

The JS is built in the **mercury** workspace (the echo image has no JS build step). Two builds; only
the first is needed for local dev:

```bash
cd mercury/codemojex/apps/game
pnpm phoenix:build     # typecheck + build phoenix* + the boot → priv/static/assets/{phoenix.js, phoenix_live_view.js, app.js}  (COMMIT these)
# pnpm build           # → priv/static/game/game-<hash>.js  (the EDGE game; deferred — see hot-swap)
```

The image has no JS build step, so `app.js` is **committed**. The game bundle is **edge-delivered** and
not built/committed here — in dev it is simply absent, so `/game/:gam` renders the shell with no React
UI (`data-bundle` empty). See [livereact-hot-swap.md](livereact-hot-swap.md).

## 4. The auth gate — why `/lobby` redirects

`LobbyLive.mount` (and `GameLive.mount`) redirect whenever `Codemojex.Session.resolve(session["ses"])`
fails. A plain browser carries no Telegram `initData`, so `MiniAppAuth` mints no `SES`, so there is no
session — and the LiveView bounces (`/lobby` → `/`, `/game/:gam` → `/lobby`). **This is the cm.4 auth
floor working as designed; there is no dev bypass.**

To get a session you need a valid `initData`. Three ways:

1. **Inside Telegram** — the real `@codemoji_bot` Mini App: the welcome forwards a real `initData`.
2. **The e2e harness** (§6) — forges a real HMAC-signed `initData` and drives the handshake. Use
   `npm run test:headed` to *watch* the authenticated lobby/game in a browser.
3. **A forged dev cookie in your own browser** — sign an `initData` with the bot token (the harness's
   `lib/initData.ts` is the reference) and set it as the `tg_init` cookie, then load `/lobby`.

## 5. Two dev gotchas you will hit

### 5.1 `check_origin` — use `localhost`, not `127.0.0.1`

The endpoint `url` host is `localhost`. WebSocket origin checks (unlike plain HTTP) enforce it, so a
page served from `127.0.0.1` gets its `/live` socket **rejected** — the page renders but is **dead**
(no `enter_room`, no live updates), with `Could not check origin … Origin: http://127.0.0.1:4000` in the
log. `dev.exs` sets `check_origin: false` so either host works locally (prod keeps its `runtime.exs`
allowlist). Still, prefer **http://localhost:4000**.

### 5.2 The bot token in dev (outbound only)

`Codemojex.Bot.token/0` reads `config :codemojex, Codemojex.Telegram, token:` first. That wiring was
`:prod`-only, so `runtime.exs` now also arms it from `CODEMOJI_BOT_TOKEN` in `:dev` — **outbound sends
only**. *Inbound* polling stays off in dev: prod owns `@codemoji_bot`'s webhook and a dev `getUpdates`
poller would conflict with it; wire a separate dev bot token if you need dev inbound. The
`ECHO_BOT_HELLO_TOKEN` warning on boot is a *different*, benign demo bot.

## 6. The e2e harness — [`node/codemojex-e2e/`](../../../node/codemojex-e2e)

A self-contained Playwright project that drives the **real** auth path and screenshots each tier into
the HTML report. It is standalone (the `codemoji-*` pnpm-workspace glob does not capture `codemojex-e2e`).

```bash
cd node/codemojex-e2e
npm install
npm run install:browsers      # one-time: chromium
npm test                      # run the stories  (dev server must be reachable)
npm run report                # open the HTML report (screenshots + traces + video)
npm run test:headed           # watch the authenticated flow live in a browser
```

### 6.1 How it authenticates (no bypass)

[`lib/initData.ts`](../../../node/codemojex-e2e/lib/initData.ts) forges a **valid** Telegram WebApp
`initData`, signed exactly as the server verifies it (`Codemojex.InitData.verify/3`):

```
secret_key       = HMAC_SHA256(key: "WebAppData", msg: bot_token)
hash             = HMAC_SHA256(key: secret_key, msg: data_check_string)   # lower-hex
data_check_string = every field EXCEPT hash & signature, sorted by key, "\n"-joined
```

That `initData` is set as the `tg_init` cookie the welcome forwards, so `MiniAppAuth` runs the genuine
handshake and mints a real `SES`. The bot token is read from the process env, else parsed from
`echo/.env` (override with `CODEMOJEX_ENV_FILE`).

### 6.2 The stories

| Story | Proves |
|---|---|
| Tier 1 — welcome shell | `/welcome/index.html` renders the play link |
| Tier 2 — auth gate | unauthenticated `/lobby` redirects to `/` |
| **Tier 2 — authenticated lobby** | `/lobby` renders the rooms **with a real session** |
| Tier 3 — game shell | enter room → `/game/:gam`, `#game-root` + `GameIsland` + server props |
| a11y (axe plugin) | no critical accessibility violations on the lobby |

Each story attaches a full-page screenshot (`lib/shoot.ts`) plus trace + video to the report
(`screenshot/trace/video: "on"`). The config's `webServer` block can boot the dev server itself
(sourcing `echo/.env`) with `reuseExistingServer: true`, so an already-running `:4000` is reused.

### 6.3 Layout

```
playwright.config.ts   baseURL + report/trace/screenshot + webServer (reuse) config
lib/env.ts             resolve CODEMOJI_BOT_TOKEN (env or echo/.env)
lib/initData.ts        forge + sign Telegram initData; the tg_init cookie helper
lib/shoot.ts           full-page screenshot + report attachment
tests/lobby.spec.ts    the five stories
```

Artifacts (`playwright-report/`, `test-results/`, `screenshots/`, `node_modules/`) are git-ignored via
the **root** `.gitignore` (the repo ignores nested `.gitignore` files by convention).

## 7. The Elixir gate (compile + tests)

From the app dir, with `TMPDIR=/tmp`:

```bash
cd echo/apps/codemojex
valkey-cli -p 6390 ping                          # PONG
TMPDIR=/tmp mix compile --warnings-as-errors     # clean
TMPDIR=/tmp mix test --include valkey            # full suite (100/0); the auth/privacy/story specs
```

The auth suite (401 battery, revocation, socket connect) and the privacy stories pin the invariants the
render stack must not break: bearer-only identity on the API, the SES session on the browser path, and
no secret over the wire.

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `/lobby` → `/` in a browser | no Telegram session (auth gate) | use the e2e harness / a forged `tg_init` cookie / open inside Telegram |
| `/game/:gam` shows an empty game | game bundle is edge-delivered, not deployed | expected in dev; deploy the game (hot-swap §6) or set `GAME_ASSET_URL` |
| page renders but nothing is interactive | `/live` socket rejected by `check_origin` | use `http://localhost:4000`; `dev.exs` already sets `check_origin: false` |
| bot sends drop with `:no_token` | `.env` not sourced / token not wired | `set -a && source ../../.env && set +a` before `mix phx.server` |
| `ECHO_BOT_HELLO_TOKEN` warning on boot | the separate echo_bot **demo** bot | benign — ignore (not `@codemoji_bot`) |
| `mix compile` raises on `use Phoenix.HTML` | phoenix_html 4.x removed it | already fixed in `codemojex_web.ex`; don't reintroduce `use Phoenix.HTML` |
| `npm install` fails on `@mrdotb/live-react` | wrong npm coordinates (phantom dep) | already removed; the hex `live_react` provides the Elixir side |

## 9. Map

[render-stack.md](render-stack.md) · [livereact-hot-swap.md](livereact-hot-swap.md) ·
[rendering.md](rendering.md) · harness: [`node/codemojex-e2e/`](../../../node/codemojex-e2e) ·
inbound bot: [webhook-vs-polling.md](webhook-vs-polling.md).
