# codemojex-e2e

Playwright end-to-end **stories** for the codemojex three-tier render —
Tier 1 static welcome → Tier 2 LiveView lobby → Tier 3 LiveReact game shell —
driven against a running dev server through the **real Telegram-initData auth
handshake** (no dev bypass).

## The `/lobby` "redirect" is the auth gate, not a bug

`CodemojexWeb.LobbyLive.mount/3` redirects to `/` whenever
`Codemojex.Session.resolve(session["ses"])` fails. A plain browser carries no
Telegram `initData`, so `CodemojexWeb.MiniAppAuth` never mints a `SES`, and the
lobby bounces to the welcome. This is the cm.4 auth floor working as designed.

To render the lobby you need a real session. These tests obtain one the sanctioned
way: they **forge a valid `initData`**, HMAC-signed with the bot token
(`lib/initData.ts`, mirroring `Codemojex.InitData.verify/3`), set it as the
`tg_init` cookie the welcome forwards, and let `MiniAppAuth` mint the `SES`.

- **Story 2** documents the redirect gate (unauthenticated `/lobby` → `/`).
- **Story 3** is the proof the lobby renders **with** a valid session.

## Run

```bash
cd node/codemojex-e2e
npm install
npm run install:browsers          # one-time: chromium
npm test                          # runs the stories
npm run report                    # open the HTML report (screenshots + traces)
```

The dev server must be reachable at `http://127.0.0.1:4000`. The config's
`webServer` block boots it (sourcing `echo/.env`, since `mix` does not) with
`reuseExistingServer: true`, so an already-running server is reused.

The bot token is read from the process env, else parsed from
`/Users/jonny/dev/jonnify/echo/.env` (override with `CODEMOJEX_ENV_FILE`).
Override the target with `CODEMOJEX_BASE_URL`.

## What's in the report

`screenshot: "on"`, `trace: "on"`, `video: "on"` attach to every test, plus each
story saves a full-page screenshot via `lib/shoot.ts` (attached + written to
`screenshots/`). Story 5 runs the `@axe-core/playwright` accessibility plugin and
attaches the violations JSON.

## Layout

```
playwright.config.ts   baseURL + report/trace/screenshot/webServer config
lib/env.ts             resolve CODEMOJI_BOT_TOKEN (env or echo/.env)
lib/initData.ts        forge + sign Telegram initData; the tg_init cookie helper
lib/shoot.ts           full-page screenshot + report attachment
tests/lobby.spec.ts    the five stories (welcome, gate, lobby, game shell, a11y)
```
