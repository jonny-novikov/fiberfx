# Troubleshooting — the known gotchas, symptom → cause → fix

> Every entry below was hit for real on this track. When one bites, fix it the recorded way —
> do not rediscover.

## The island never boots from a fresh build (F-1, the worst one)

- **Symptom:** the game page loads, the bundle fetches, nothing mounts; `import()`-ing the
  artifact shows `mount` is `undefined`. Every source grep passes.
- **Cause:** app-mode Rollup (the game builds via `rollupOptions.input`, not `build.lib`)
  applies the facade optimization and drops the entry's named exports; production can survive on
  an older artifact while every fresh build is dead.
- **Fix:** `preserveEntrySignatures: "strict"` in `vite.config.ts` (shipped). **Gate:** the
  node-import check in [testing.md](./testing.md) — it is the only check that sees this.

## Edits don't hot-swap (no HMR, only manual reload works)

- **Symptom:** editing `src/**` does nothing until the game view is manually reloaded; no
  react-refresh in the console.
- **Cause:** the committed host boot (`echo/apps/codemojex/priv/static/assets/app.js`) predates
  the `@codemojex/liveview-boot` wiring that injects `/@vite/client` + the `/@react-refresh`
  preamble when `game_bundle` is a Vite source URL. (Verified 2026-07-02: zero occurrences in
  the committed asset — the one `grep -l vite` hit is the substring in "invite".)
- **Fix (Operator-run — it rewrites committed `echo/` assets):**
  `pnpm --filter @codemojex/game phoenix:build`, then hard-reload the shell. Until then,
  fast-reload is the loop: edit → reload the game view → fresh code.

## `VITE_GAME_SMOKE=1` "doesn't work"

- **Symptom:** the flag is exported but the game still renders (or vice versa).
- **Cause:** `import.meta.env` is baked when the Vite **server starts** — an env change on a
  running server does nothing.
- **Fix:** restart the Vite process with the flag. Verify without the window:
  `curl -s http://127.0.0.1:5173/src/index.tsx | head -1` shows the inlined `import.meta.env`
  (the key appears only in smoke mode).

## Redirected from `/lobby` back to `/`

- Not a bug: the **Telegram platform auth gate** (the browser pipeline carries the signed
  session; `/auth/:platform` is the handshake). Complete the in-app auth flow from the welcome
  page; the shell wraps the same flow the browser gets.

## Phoenix dies mid-session: `Application codemojex exited: shutdown` after BLPOP timeouts

- **Symptom:** `:4000` stops answering (curl `000`) while the `mix phx.server` process is still
  alive (a zombie VM). The log shows cascading GenServer terminations on the EchoMQ wire —
  `GenServer.call(..., {:pipeline, [["BLPOP", "emq:{cm-settle}:wake", "0.100"]]}, 2100)` /
  `emq:{cm.bot.commands}:wake` — each `** (EXIT) time out`, then
  `Application codemojex exited: shutdown`.
- **Cause:** a > 2s stall (system sleep/pause, a Valkey hiccup, heavy concurrent load on the
  shared `:6390`) blows the consumers' 2100 ms call timeout around a 100 ms BLPOP; both consumer
  loops die at once and take the supervisor past restart intensity. Observed live 2026-07-02
  02:39.
- **Fix (dev):** kill the zombie (`pgrep -fl beam.smp` → `kill <pid>`), confirm
  `valkey-cli -p 6390 ping` → `PONG`, and reboot Phoenix with the same command. **Engine note
  (out of `/cm-ship` scope):** the BLPOP callers' call-timeout margin is an `echo/`-side
  hardening candidate for a future `/codemojex-ship`/`/echo-mq-ship` rung.

## Phoenix warns `{:missing_token, "ECHO_BOT_HELLO_TOKEN"}` at boot

- Benign for the dev loop: the echo_bot **polling updater** stays off. Welcome, lobby, game, and
  the Channels all work. Set the bot's `token_env` only when the live dev bot itself is the thing
  under test.

## `mix` fails mid-suite with weird I/O errors (or ENOSPC)

- **Cause:** the harness tmp overlay.
- **Fix:** `TMPDIR=/tmp` on **every** `mix` command (`TMPDIR=/tmp mix phx.server`,
  `TMPDIR=/tmp mix test`, …). An Elixir-side rule — Node/pnpm work does not need it.

## jest-dom matchers explode: "Invalid Chai property: toBeInTheDocument" / TS2339

- **Cause:** the dual-vitest trap — a package running a different vitest **major** than the
  root-hoisted one, with jest-dom extending the wrong expect.
- **Fix (already the idiom here):** extend the package's **own** expect —
  `import "@testing-library/jest-dom/vitest"` in the test file (see `GameSmoke.test.tsx:1`) —
  plus a module-mode `src/vitest.d.ts`. Copy the existing test files; do not restructure the
  test infra.

## Hot-swap code crashes under vitest

- **Cause:** `import.meta.hot` is **truthy** under vitest but `hot.data` is `undefined` — only
  real Vite dev carries the swap bag.
- **Fix:** guard on `import.meta.hot?.data` (as `src/index.tsx` does), never on
  `import.meta.hot` alone.

## Port conflicts

- Vite runs `--strictPort` and fails fast if `:5173` is taken; Phoenix wants `:4000`. Find the
  squatter: `lsof -nP -i :4000 -i :5173`. The shell itself binds no port (it wraps the external
  Phoenix URL).

## `pnpm install` / lockfile confusion

- Run installs from `mercury/codemojex/` (or `mercury/`) — the game is a **member of the
  mercury workspace** (post cmt.3 Arm A); the lockfile is `mercury/pnpm-lock.yaml`. There is no
  nested lockfile in the game app.

## "The build wrote into `echo/` — did I break the boundary?"

- No. `vite.config.ts` deliberately targets `echo/apps/codemojex/priv/static/game/`, which is
  **gitignored** (root `.gitignore:220`). The `/cm-ship` boundary governs the **diff**; a build
  artifact in an ignored dir never enters it. An actual `echo/` **source** edit is what forks to
  `/codemojex-ship`.

## The emitted CSS contains `*,:before,:after,::backdrop` — preflight leak?

- No. That block is Tailwind v4's `@property` **fallback** (inside a `@supports` guard),
  initializing internal `--tw-*` variables only. The preflight check is the reset **signature**
  (`box-sizing:border-box`, element margins) — grep those, expect 0.
