# cm.4 — Stories (the acceptance face)

> The Operator's verifiable acceptance for cm.4, derived from [`cm.4.md`](./cm.4.md) (the body wins on any
> disagreement). The model is the **ruled** shared-`SES`-in-Valkey floor (D-2). Each story is Connextra +
> Given/When/Then; each names the invariant(s) it exercises and the check that closes it. A gate must exercise
> its outcome — a no-op must not satisfy a story's letter.
>
> Framing: third person; no first-person-agent narration; no perceptual / interior-state verbs.

## Roles

- **A Mini-App player** — a Telegram user opening the Codemoji Mini App; the WebApp hands the surface a signed
  `initData` once, at the first screens.
- **An attacker** — anyone issuing requests directly to `/api/*` or the socket without a valid `SES`.
- **The Operator** — accepts the rung; signs off the revocation invariant, the retired endpoint, and the
  byte-unchanged suite.
- **A Go lightweight edge** — a forward-vision consumer that reads the shared `SES` from Valkey (named here so
  the floor's `SES` shape is sufficient; the edge is NOT built this rung).

---

## S1 — A verified player acts as themselves, via a shared session

*As a Mini-App player, I want one handshake to exchange my Telegram `initData` for a session that authenticates
every later request and the socket, so that no caller can act under my `PLR`.*

**Exercises:** A1 (401 on every gated ingress), A2 (valid handshake → the right `PLR`). **Surface:** the
handshake `POST /api/auth/:platform` + the `:auth` plug over join/guess/history/buy_keys/convert + the socket.

- **Given** a player whose Telegram WebApp produced a valid, fresh `initData` for tg user `N`
- **When** that `initData` is presented to `POST /api/auth/telegram`
- **Then** the response carries a `SES` id and the resolved `PLR` (one `players` row for `N`),
- **And** presenting `Authorization: Bearer <SES>` to `POST /api/games/:id/guess` runs the guess as that `PLR`,
- **And** the same holds for `join` · `history` · `buy_keys` · `convert`,
- **And** a socket `connect/3` carrying that `SES` as the connect-param succeeds with the player assigned and
  `id/1` non-nil.

## S2 — A forged, missing, or stale credential is refused at the door

*As an attacker, when I present no session, a forged session, or a stale `initData`, I want the request
rejected before any action runs, so that the trusted-player gap is closed.*

**Exercises:** A1 (401), A4 (constant-time reject + the freshness window). **Surface:** `CodemojexWeb.Auth` +
`Codemojex.Session.resolve/1` + `Codemojex.InitData.verify/3`.

- **Given** the five player-acting endpoints behind the `:auth` pipeline
- **When** a request presents no `Authorization` header → **401**,
- **And** a request presents a garbage / non-`SES` bearer → **401**,
- **And** a handshake presents `initData` whose `auth_date` is older than the configured max-age → **401**
  (`:stale`, no `SES` minted),
- **And** a handshake presents `initData` with a tampered `hash` → **401** (`:bad_hash`),
- **And** a socket `connect/3` with any of these → `:error`,
- **And** the `initData` hash comparison is constant-time (`:crypto.hash_equals/2`).

## S3 — A revoked session stops authenticating immediately (THE load-bearing invariant)

*As the Operator, I want revoking a session to take effect on the very next request, so that a banned or
compromised player cannot keep acting — the property that makes the first mutable EchoStore table safe.*

**Exercises:** A3 (the revocation invariant — `:tracking` evicts every L1; `DEL` clears L2). **Surface:**
`Codemojex.Session.revoke/1` → `EchoStore.Table.invalidate/3` over a `coherence: :tracking` table.

- **Given** a live `SES` that authenticates an action (proven first)
- **When** `Codemojex.Session.revoke(ses)` runs (a `DEL` on `ecc:{sessions}:<SES>`)
- **Then** the next request presenting that `SES` → **401** — the `:tracking` push evicted it from every BEAM
  holder's L1 and the `DEL` cleared L2, so `resolve/1` is a clean miss,
- **And** the eviction is immediate (no stale window) — **or** the spec names a bounded staleness window and
  the test asserts the bypass closes within it (≤ one tick).

## S4 — Resolve-or-create binds one `PLR` per Telegram user, idempotently

*As a Mini-App player returning across sessions, I want my verified Telegram id to map to exactly one `PLR`, so
that my balances and history persist and a concurrent first touch never forks me into two players.*

**Exercises:** A2 (idempotent resolve), A9 (the same-ms mint hazard). **Surface:** the handshake calls
`Codemojex.resolve_player_by_tg/2 → Wallet.resolve_by_tg/2` (Venus-Postgres, Pattern A; the `tg_user_id`
partial unique index).

- **Given** no `players` row yet exists for tg user `N`
- **When** a first handshake for `N` arrives
- **Then** exactly one `PLR` is minted (`EchoData.BrandedId.generate!("PLR")`) with `tg_user_id = N`,
- **And** a second handshake for `N` resolves to the **same** `PLR` (no second row),
- **And** N concurrent first-touch handshakes for `N` → all the same `PLR`, exactly one row (the partial unique
  index is the backstop; Venus-Postgres §2.4),
- **And** under the ≥100 determinism loop the handshake (minting both a `PLR` and a `SES`) never forks a row.

## S5 — The verifier is a pure, fixture-tested function

*As Mars + Apollo, I want the `initData` check to be a pure function provable by a signed fixture, so that the
HMAC path is exercised offline with no live Telegram.*

**Exercises:** A4 (pure + accept + tamper-reject + the `signature`-exclusion + fail-closed). **Surface:**
`Codemojex.InitData` unit tests.

- **Given** a known test bot token (set via `Application.put_env(:codemojex, Codemojex.Telegram, token: …)`,
  restored on exit) and an `initData` signed with it per the WebApp scheme
- **When** `Codemojex.InitData.verify(init_data, token, now: <fixed>)` is called
- **Then** it returns `{:ok, %{tg_user_id: N, …}}`,
- **And** flipping any one signed field → `{:error, :bad_hash}`,
- **And** an `initData` that additionally carries a `signature` field still verifies (the data-check-string
  excludes both `hash` **and** `signature`),
- **And** a `nil` token → `{:error, :no_token}` (fail-closed),
- **And** the function performs no HTTP and reads no `Repo` and no session store.

## S6 — The free-player endpoint is gone

*As the Operator, I want the unauthenticated create-player route removed, so that minting a player (and its
opening balance) requires a verified handshake — the free-money gap is closed.*

**Exercises:** A5 (G3 — `POST /api/players` retired). **Surface:** `router.ex` (route removed) +
`game_controller.ex` (`create_player/2` removed).

- **Given** the cm.4 router
- **When** a request hits `POST /api/players`
- **Then** the response is **404** (the route does not exist),
- **And** a grep of `game_controller.ex` shows no `create_player` action — the only path to a new `PLR` is
  resolve-or-create at the verified handshake.

## S7 — The dev/test posture mints a real session with no prod bypass

*As the Operator, I want the test convenience to mint a real session via a `test/support` helper and to carry
no production bypass, so that no auth-skip path can ship into the shared store.*

**Exercises:** A6 (F2 — D-2). **Surface:** a `test/support` SES-minting helper; no `lib/` bypass.

- **Given** the test suite needs a bearer without a live Telegram
- **When** the `test/support` helper mints a `SES` via `Codemojex.Session.mint/3` (a real row in the test Valkey)
- **Then** a ConnTest authenticates with that `SES`,
- **And** a grep of `lib/` shows **no** `trust_supplied_player` (or any auth-skip) — the prod path always
  requires a verified handshake.

## S8 — The existing acceptance suite stays byte-unchanged and green

*As the Operator, I want the 8 game story suites unchanged and passing after the auth cutover, so that the floor
adds security without disturbing proven game behaviour.*

**Exercises:** A7 (byte-unchanged + green), A10 (privacy). **Surface:** the cutover reads
`conn.assigns.player`; the suites drive the **facade**, not the web layer.

- **Given** the 8 `Codemojex.Story` suites under `test/stories/` (41 scenarios, all `@moduletag :valkey`)
- **When** the auth cutover lands and `mix test --include valkey` runs (Valkey 6390 + Postgres)
- **Then** all 41 scenarios pass (**41/0**) and the new `test/codemojex_web/auth_test.exs` passes,
- **And** `git diff --stat test/stories/` is empty (no story file edited),
- **And** the game `secret` never crosses the wire (the existing privacy stories stay green).

---

## Coverage (every body Deliverable → its story → its invariant)

| Deliverable (cm.4.md) | Story | Invariant(s) |
|---|---|---|
| `Codemojex.InitData.verify/3` (pure verifier) | S5 | A4 |
| The handshake `POST /api/auth/:platform` (the sole `SES` mint) | S1 | A1, A2 |
| `Codemojex.Session.{mint,resolve,revoke}` + the `:cm_sessions` `:tracking` table | S1, S3 | A1, A3 |
| The `:auth` pipeline + `CodemojexWeb.Auth` plug | S1, S2 | A1 |
| `require_player → conn.assigns.player` cutover (5 actions) | S1, S2 | A1 |
| Socket `connect/3` auth + non-nil `id/1` | S1, S2 | A1 |
| `Codemojex.resolve_player_by_tg/2` (resolve-or-create — Venus-Postgres) | S4 | A2, A9 |
| `players.tg_user_id` + the partial unique index + migration (Venus-Postgres) | S4 | A2, A8, A9 |
| **The revocation invariant** (`:tracking` + `invalidate`/`DEL`) | S3 | A3 |
| Retire `POST /api/players` (G3) | S6 | A5 |
| The F2 dev/test helper (no prod bypass) | S7 | A6 |
| The 8 story suites byte-unchanged + privacy | S8 | A7, A10 |
