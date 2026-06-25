# cm.4 — Agent brief (`.llms.md`)

> The compressed brief Mars builds from. Derived from [`cm.4.md`](./cm.4.md) (authoritative) +
> [`cm.4.stories.md`](./cm.4.stories.md) (acceptance). The model is the **ruled** shared-`SES`-in-Valkey floor
> (D-2). The **relational** half (the `tg_user_id` column, the partial unique index, `Wallet.resolve_by_tg/2`,
> the migration, the reinit) is specified by **Venus-Postgres** in
> [`cm.4.postgres.design.md`](./cm.4.postgres.design.md) — it **stands unchanged**; build that side to *its*
> contract, not by guessing here.
>
> Framing law (binds every prompt derived from this brief): third person for any agent reference; no
> first-person-agent narration; no perceptual / interior-state verbs.

## References (read first, in order)

1. [`cm.4.md`](./cm.4.md) — the rung body (the ruling §2, the verifier §4, the `SES` surface §5, the handshake
   §6, the cutover §7, the dev/test posture §8, the acceptance §9).
2. [`cm.4.postgres.design.md`](./cm.4.postgres.design.md) — the relational contract (Venus-Postgres, **stands**):
   `players.tg_user_id` (nullable `bigint`) + the partial unique index `players_tg_user_id_index`
   (`WHERE tg_user_id IS NOT NULL`), `Wallet.resolve_by_tg/2` + facade `Codemojex.resolve_player_by_tg/2`
   (Pattern A: `on_conflict: :nothing` + re-fetch), the second migration, the partitioned-test-DB reinit.
3. [`../kb/auth-flow/auth.synthesis.md`](../kb/auth-flow/auth.synthesis.md) §2/§5 — the build-ready `SES` model
   the floor builds (the why; the body §2 is the what).
4. The as-built surface (probe, do not assume):
   - `lib/codemojex_web/controllers/game_controller.ex` — `require_player/1` + the 5 actions + `create_player/2`
     (to delete).
   - `lib/codemojex_web/router.ex` — the `:api` pipeline + the routes + `POST /api/players` (to remove).
   - `lib/codemojex_web/channels/user_socket.ex` — `connect/3` + `id/1`.
   - `lib/codemojex/bot.ex` — `Codemojex.Bot.token/0` (the HMAC key source; nil-safe → fail-closed).
   - `lib/codemojex/tables.ex` — the two `:none` `EchoStore.Table` children (the registration shape to mirror;
     `:cm_sessions` is the **third**, the first **mutable**).
   - `lib/codemojex/game.ex` (line 183, `Codemojex`) + `lib/codemojex/wallet.ex` (`create/2`) — where
     resolve-or-create attaches (Venus-Postgres).
   - `echo/apps/echo_store/lib/echo_store/table.ex` — `put/3` (mints version + writes both under the TTL,
     `:90`), `put/4` (`:97`), `fetch/3 → {:ok, value, source} | {:error, :kind} | {:error, :no_such_cache}`
     (`:63`), `invalidate/3` (`:174`), `coherence: :tracking` (`:204,255-266`), the framed-String + 14-byte
     version split (`:290,429`), the registration opts (`:name`/`:kind`/`:loader` required, `:ttl_ms`,
     `:coherence`, `:max_size`, `:connector`).
   - `mix.exs` — `{:jason, "~> 1.4"}` is **declared** (`:58`), `{:phoenix, "~> 1.7"}` (`:55`).
5. The Telegram WebApp validation spec — [core.telegram.org/bots/webapps](https://core.telegram.org/bots/webapps)
   (the algorithm is pinned in cm.4.md §4; build to the body).

## Requirements (numbered; each → a story → an invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R1 | `Codemojex.InitData.verify/3` — pure; WebApp HMAC; excludes `hash` **and** `signature`; `:crypto.hash_equals` compare; freshness via `opts[:max_age_seconds]` + `opts[:now]`; **fail-closed** on a nil token; closed error set `:missing\|:malformed\|:no_token\|:bad_hash\|:stale` | S5 | A4 |
| R2 | `:cm_sessions` `EchoStore.Table` child in `Codemojex.Tables` — kind `"SES"`, `coherence: :tracking`, sliding `ttl_ms`, a **JSON** loader (clean miss; NOT `term_to_binary`), a `:6390` connector | S1, S3 | A1, A3 |
| R3 | `Codemojex.Session.{mint/3, resolve/1, revoke/1}` (`lib/codemojex/session.ex`) — `mint` = `generate!("SES")` + `Jason.encode!({plr, platform, …})` + `put`; `resolve` = `fetch` → decode → **re-`put` (slide)** → claims; `revoke` = `invalidate` | S1, S3 | A1, A3 |
| R4 | `CodemojexWeb.AuthController.handshake/2` + `POST /api/auth/:platform` — verify `initData` → `resolve_player_by_tg` → `Session.mint` → return `{session, player}`; the **sole** `SES` mint | S1 | A1, A2 |
| R5 | `CodemojexWeb.Auth` plug — read `Bearer <SES>` → `Session.resolve` → `assign(conn, :player, plr)`; 401 + `halt` on miss/unknown/revoked; **no** dev/test bypass | S1, S2 | A1 |
| R6 | Router `:auth` pipeline; the 5 player-acting routes through `:api`+`:auth`; the handshake on `:api`; **delete `POST /api/players`** | S1, S6 | A1, A5 |
| R7 | `game_controller.ex` — the 5 actions read `conn.assigns.player`; **delete** `require_player/1`; **delete** `create_player/2` | S1, S6 | A1, A5 |
| R8 | `user_socket.ex` — `connect/3` resolves the `SES` connect-param → assign player; `id/1` non-nil; reject on miss | S1, S2 | A1 |
| R9 | `Codemojex.resolve_player_by_tg/2` (facade) → `Wallet.resolve_by_tg/2` (Venus-Postgres body) | S4 | A2, A9 |
| R10 | A `test/support` SES-minting helper + a fixture `initData` signer (set a known token via `Application.put_env`, restore `on_exit`); **no** prod bypass | S5, S7 | A4, A6 |
| R11 | `test/codemojex_web/auth_test.exs` (plain ExUnit / Phoenix.ConnTest) — the 401 battery + the handshake-happy-path + **the revocation invariant** + the `POST /api/players` 404 + the F2 no-bypass grep; the 8 story suites untouched | S1–S8 | A1–A10 |

## Execution topology

Runtime shape — a single handshake (`POST /api/auth/:platform`) is the **sole `SES` writer**: it verifies
`initData` (the pure `Codemojex.InitData`), resolves the `PLR` (Venus-Postgres), and mints a `SES`-branded
session in Valkey (an `EchoStore.Table` entity, kind `"SES"`, a JSON value carrying `{plr, platform}`). Two
read ingresses — the HTTP `:auth` plug and the socket `connect/3` — present `Bearer <SES>`, resolve it from the
shared store (an L1 ETS hit → L2 → a clean-miss loader), assign `conn.assigns.player`, and slide the TTL. The
only identity an action reads is the assigned `:player`; a caller-supplied id is never trusted. Revocation is a
`DEL` (`invalidate/3`) whose RESP3 `CLIENT TRACKING` push (`coherence: :tracking`) evicts every BEAM holder's
L1 immediately.

**Build-order DAG (smallest-change-first; each step compiles `--warnings-as-errors` before the next):**

1. **`Codemojex.InitData`** (new `lib/codemojex/init_data.ex`) — the pure verifier. No deps on the rest; build
   + unit-test first (S5 closes here, fully offline).
2. **`:cm_sessions` registration** — the third `EchoStore.Table` child in `Codemojex.Tables` (`:tracking`, a
   JSON `load_session/1` clean-miss loader). Compile-visible before the Session module uses it.
3. **`Codemojex.Session`** (new `lib/codemojex/session.ex`) — `mint/3`/`resolve/1`/`revoke/1` over
   `EchoStore.Table.{put,fetch,invalidate}` + `Jason` + `generate!("SES")`.
4. **Resolve-or-create** — `Wallet.resolve_by_tg/2` (Venus-Postgres body) + `Codemojex.resolve_player_by_tg/2`
   (facade `game.ex`). Needs the `tg_user_id` column (Venus-Postgres migration) compiled in.
5. **`CodemojexWeb.AuthController`** (new) + the handshake — verify → resolve → mint (depends on 1+3+4).
6. **`CodemojexWeb.Auth`** plug (new) — read `Bearer` → `Session.resolve` → assign / 401 (depends on 3).
7. **`router.ex`** — the handshake route + the `:auth` pipeline + **delete `POST /api/players`** (depends on 5+6).
8. **`game_controller.ex`** — the 5 actions → `conn.assigns.player`; delete `require_player/1` + `create_player/2`.
9. **`user_socket.ex`** — `connect/3` resolves the `SES` connect-param; `id/1` non-nil (depends on 3).
10. **`test/support` helper** + **`test/codemojex_web/auth_test.exs`** (depends on all above).

**Files touched** (the whole set; nothing else):
`lib/codemojex/init_data.ex` (new) · `lib/codemojex/session.ex` (new) · `lib/codemojex/tables.ex` ·
`lib/codemojex_web/auth.ex` (new) · `lib/codemojex_web/controllers/auth_controller.ex` (new) ·
`lib/codemojex_web/router.ex` · `lib/codemojex_web/controllers/game_controller.ex` ·
`lib/codemojex_web/channels/user_socket.ex` · `lib/codemojex/game.ex` · `lib/codemojex/wallet.ex` ·
`lib/codemojex/schemas/player.ex` · `priv/repo/migrations/<new>` · `test/support/<auth helper>` ·
`test/codemojex_web/auth_test.exs` · `docs/codemojex/specs/cm.4.*`. **No `echo/config` change.**

## Agent stories (Directive + Acceptance gate — each surface a contract)

- **AS1 — the pure verifier.** *Directive:* build `Codemojex.InitData.verify/3` per cm.4.md §4. *Contract:*
  **pre** a raw `initData` + a token; **post** `{:ok, %{tg_user_id, …}}` for a valid+fresh signature, else
  `{:error, reason}` in the closed set; **invariant** no HTTP, no `Repo`, no session store; constant-time
  compare; fail-closed on a nil token. *Gate:* the fixture accepts; a tampered field → `:bad_hash`; a stale
  `auth_date` → `:stale`; a present `signature` still accepts; a nil token → `:no_token` (A4).
- **AS2 — the SES table + surface.** *Directive:* register `:cm_sessions` (`:tracking`, JSON loader) in
  `Codemojex.Tables`; build `Codemojex.Session.{mint,resolve,revoke}`. *Contract:* **pre** a `SES` id; **post**
  `mint` writes a JSON row + returns the `SES`; `resolve` returns `{plr, platform}` + slides the TTL, else
  `{:error, :unknown}`; `revoke` drops both layers; **invariant** the value is JSON (a Go edge reads it after a
  14-byte strip), never `term_to_binary`; `mint` is called only by the handshake (single writer). *Gate:* a
  minted SES resolves to its `{plr}`; after `revoke`, the next `resolve` is `{:error, :unknown}` (A3).
- **AS3 — the handshake.** *Directive:* `AuthController.handshake/2` + `POST /api/auth/:platform`: verify →
  `resolve_player_by_tg` → `Session.mint` → `{session, player}`. *Contract:* **pre** `initData` + a `:platform`;
  **post** `{session, player}` for valid+fresh, else 401; **invariant** the only `SES` write in the system;
  fail-closed on a nil token. *Gate:* a fixture-signed `initData` → a SES + the right PLR; idempotent for the
  same TG user (A2).
- **AS4 — the plug + pipeline + cutover.** *Directive:* `CodemojexWeb.Auth` (read `Bearer` → resolve → assign ∥
  401+halt); the `:auth` pipeline; the 5 routes re-piped; the handshake route added; **`POST /api/players`
  deleted**; the 5 actions read `conn.assigns.player`; `require_player/1` + `create_player/2` deleted. *Contract:*
  **pre** a request to a player-acting route; **post** the action runs only with an assigned verified `:player`,
  else 401; `POST /api/players` → 404; **invariant** no action body is reachable without a prior assign; no
  auth-skip surface in `lib/`. *Gate:* the 401 battery on all 5 routes; a valid SES → the right PLR; `POST
  /api/players` → 404 (A1, A5).
- **AS5 — the socket.** *Directive:* `connect/3` resolves the `SES` connect-param → assign player; `id/1`
  non-nil. *Contract:* **pre** connect params; **post** `{:ok, socket}` with `:player` for a valid SES, else
  `:error`; **invariant** a refused connect carries no player. *Gate:* a valid SES connects; a forged/missing/
  revoked one → `:error` (A1).
- **AS6 — the F2 posture + the suite.** *Directive:* a `test/support` SES-minting helper + the fixture signer;
  `auth_test.exs` with the 401 battery + the handshake happy path + **the revocation invariant** + the
  `POST /api/players` 404 + the no-bypass grep. *Contract:* **pre** the test env; **post** the helper mints a
  real SES, `lib/` has no bypass; **invariant** the bypass cannot ship. *Gate:* A6 + the 8 suites byte-unchanged
  + 41/0 + the new suite green (A7).

## Cite-map (every public call → its real surface)

| Call in the brief | Real surface |
|---|---|
| `Codemojex.Bot.token/0` | `lib/codemojex/bot.ex:39` (app-env then echo_bot YAML; nil-safe → fail-closed) |
| `EchoData.BrandedId.generate!("SES")` / `("PLR")` | `echo_data` `lib/echo_data/branded_id.ex:93` (`SES` free, T-6; `PLR` minted in `wallet.ex:20`) |
| `EchoStore.Table.put/3` · `fetch/3` · `invalidate/3` | `echo/apps/echo_store/lib/echo_store/table.ex:90 / :63 / :174` (`put/3` mints version + writes both under the TTL; `fetch → {:ok,value,source}\|{:error,:kind}\|{:error,:no_such_cache}`; `invalidate` = `DEL` L2 + `:ets.delete`) |
| `coherence: :tracking` (the registration) | `echo/apps/echo_store/lib/echo_store/table.ex:204,255-266` (RESP3 `CLIENT TRACKING` armed at start, re-armed on reconnect) |
| the framed-String + 14-byte version split | `table.ex:290` (`SET … (version<>value) PX`) + `table.ex:429` (`<<version::binary-14, value::binary>>`) |
| `Codemojex.Tables` registration shape | `lib/codemojex/tables.ex` (the two `:none` children — `:cm_sessions` is the third, `:tracking`) |
| `Codemojex.resolve_player_by_tg/2` / `Wallet.resolve_by_tg/2` | `cm.4.postgres.design.md` §2 (Venus-Postgres; facade `game.ex`, body `wallet.ex`) |
| `Codemojex` facade / `Wallet.create/2` | `lib/codemojex/game.ex:183` / `lib/codemojex/wallet.ex:20` — **not** `lib/codemojex.ex` |
| `Jason.encode!/1` · `decode!/1` | `mix.exs:58` (`{:jason, "~> 1.4"}` — DECLARED, the cross-language SES codec; zero new dep) |
| `:crypto.mac/4` · `:crypto.hash_equals/2` | OTP `crypto` — confirmed OTP 28 (pure OTP, no dep) |
| `URI.decode_query/1` · `Base.encode16/2` | stdlib |
| `Plug` / `put_status` / `json` / `halt` | `use CodemojexWeb, :controller` + `Phoenix.Controller` / `Plug.Conn` (Phoenix `~> 1.7`, `mix.exs:55`) |
| `Phoenix.ConnTest` (the auth suite driver) | Phoenix test support (in-process dispatch; `server: false` is fine) |

## Gate ladder (run from `echo/apps/codemojex`, `TMPDIR=/tmp`)

1. re-probe `asdf current` / `.tool-versions` (Elixir 1.18.4 / Erlang 28.x — do not hardcode).
2. `valkey-cli -p 6390 ping` → `PONG`; Postgres up.
3. `TMPDIR=/tmp mix compile --warnings-as-errors`.
4. `TMPDIR=/tmp mix test --include valkey` — the 41 scenarios (41/0) **byte-unchanged** + the new auth suite
   (incl. **the revocation invariant** — A3).
5. the migration up/down + `MIX_ENV=test mix ecto.drop/create/migrate` clean (partitioned DB; Venus-Postgres).
6. the ≥100 determinism loop: `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done`
   (the handshake mints a `PLR` **and** a `SES` — the same-ms hazard).
7. `git diff --stat test/stories/` empty; a grep shows no `trust_supplied_player`/auth-skip in `lib/`, and
   `POST /api/players` removed.

## Notes for Mars (footguns, grounded)

- **`:cm_sessions` is the FIRST mutable `EchoStore.Table`.** The two existing caches are `:none` only because
  GAM/EMS are immutable-for-life; a session is mutable + revocable, so `:none` would be a security defect.
  Register `coherence: :tracking` (D-2) — it is a real, as-built value (`table.ex:255-266`).
- **The SES value MUST be JSON**, never `:erlang.term_to_binary` (the existing loaders use it — do NOT copy
  that for sessions; a Go edge must read the value). `Jason` is declared (`mix.exs:58`) — no `mix.lock` move.
- **The sliding TTL is a re-`put` on resolve** — `put/3` re-stamps the version + the `PX` TTL (`table.ex:90`).
  Do not add a separate `EXPIRE` call; the re-`put` is the slide.
- **The loader is a clean miss** — a `SES` has no relational system of record (ephemeral, D-2). `load_session/1`
  returns `{:error, :not_found}` so an unknown/expired/revoked SES is a miss → the plug 401s.
- **The token is nil in test** — the fixture signer MUST set a known token via `Application.put_env(:codemojex,
  Codemojex.Telegram, token: …)` (restore `on_exit`); `Codemojex.Telegram` is a config-key namespace, NOT a
  module (do not `alias`/`import` it).
- **The partial-index `conflict_target` fragment** (Venus-Postgres Pattern A) must stay byte-matched to the
  migration `where:` (`cm.4.postgres.design.md` §2.3) — a mismatch raises at runtime.
- **No `echo/config` change** — F2 needs no flag; the helper is `test/support` only.
