# cm.4 — The auth floor: verified Telegram `initData` → a shared `SES`-in-Valkey session

> The rung body — **authoritative**. The `.stories.md` (acceptance) and `.llms.md` (the agent brief) derive
> from this file; when a derived artifact disagrees, this body wins. The **relational** half (the
> `players.tg_user_id` column, the partial unique index, `Wallet.resolve_by_tg/2`, the second migration, the
> reinit) is owned by **Venus-Postgres** — see [`cm.4.postgres.design.md`](./cm.4.postgres.design.md); it
> **stands unchanged** and this body references it at the contract level (the handshake calls
> `Codemojex.resolve_player_by_tg/2`).
>
> **The design-ahead is CLOSED. The forks are RULED (D-2, the cm-4 ledger), not surfaced.** This triad is the
> ruled floor, build-grade, for Mars. The auth model is the **shared `SES`-in-Valkey** session (the
> auth-flow KB: [`../kb/auth-flow/auth.synthesis.md`](../kb/auth-flow/auth.synthesis.md) §2/§5). The
> superseded per-request-`initData` model (this file's v1) is gone.
>
> Framing law (propagates to every prompt derived from this body): third person for any agent reference; no
> first-person-agent narration; no perceptual / interior-state verbs (sees / notices / feels).

## 1. The rung in one paragraph

Close the one named pre-launch gap. The web surface trusts a client-supplied player id:
`CodemojexWeb.GameController.require_player/1` (`game_controller.ex:77`) reads `params["player"]` verbatim
across five player-acting endpoints (join · guess · history · buy_keys · convert), and
`CodemojexWeb.UserSocket.connect/3` (`user_socket.ex:7`) accepts any connection (`{:ok, socket}`, `id/1 → nil`).
cm.4 replaces that trust point with a **shared session**. A dedicated handshake — `POST /api/auth/:platform` —
**verifies** Telegram WebApp `initData` (the pure `Codemojex.InitData` HMAC verifier), **resolves** the verified
Telegram user to a `PLR` (`Codemojex.resolve_player_by_tg/2`, Venus-Postgres), **mints a `SES`-branded session
in Valkey** (an `EchoStore.Table` entity, kind `"SES"`, a JSON value carrying `{plr, platform}`), and returns
the `SES` id as the bearer. Every later request and the socket present `Bearer <SES>`; the `:auth` plug
resolves the `SES` from the shared store and assigns `conn.assigns.player`. The session is **shared** — a
forward Go lightweight edge reads the same JSON row from the same Valkey with a stock client (G6). After cm.4
no player-acting endpoint or socket trusts a caller-supplied identity, and `POST /api/players` is **retired**
(G3 — minting now requires a verified handshake). The smallest change that makes the invalid state — acting as
another player — **unrepresentable**.

## 2. The ruling (D-2 — carried, not re-litigated)

The Operator ruled the four open forks (D-2 in the cm-4 ledger, over the converged `SES` model; the auth-flow
synthesis §3):

| # | Decision | What it means for the build |
|---|---|---|
| **Coherence** | **`:tracking`** (RESP3 `CLIENT TRACKING`) | `:cm_sessions` registers `coherence: :tracking`. Valkey itself pushes invalidation on any write/`DEL` to `ecc:{sessions}:` — a revoked `SES` is evicted from every BEAM tracking-client's L1 **immediately** (no app publish, not writer-dependent). This is the **first mutable** `EchoStore.Table` (the two existing caches are `:none` **only** because GAM/EMS are immutable-for-life; `:none` here would be a security defect — a revoked `SES` surviving in L1 keeps authenticating). |
| **TTL** | **sliding** (re-`put` on use) | A request that resolves a live `SES` re-`put`s it, re-stamping the version + the `PX` TTL (the redis-patterns sliding-session pattern) — an active player never re-handshakes mid-play. |
| **Durability** | **ephemeral** (Valkey-TTL) + **re-handshake on loss** | The `SES` lives in Valkey L2 + the EchoStore L1; on loss (a Valkey restart / TTL expiry) the client silently re-handshakes. **Graft-durability of a session is deferred** to the forward Venus-Persistence design-ahead (D-3) — **NOT a cm.4 artifact**, it does not block this floor. |
| **Dev/test** | **F2** — a `test/support` `SES`-minting helper, **NO prod bypass** | The shared store warrants the higher bar: a leaked bypass minting `SES`s into shared Valkey would fool **every** service. No `trust_supplied_player` flag; the suite mints a real `SES` via a test helper, and the real verify path is exercised by a fixture-signed `initData`. |

## 3. Ground truth (re-probed on disk — cite methods, not lines)

| Surface | As-built (verdict) | cm.4 |
|---|---|---|
| The gap | `GameController.require_player/1` returns `params["player"]` verbatim; 5 actions gate on it (MATCH) | replace with `conn.assigns.player` |
| Open actions | `health` · `rooms` · `game` · `leaderboard` trust no caller id (MATCH) | unchanged — stay on `:api` only |
| Router | one `:api` pipeline; `POST /api/players` mints a free player (MATCH) | add the handshake route + an `:auth` pipeline; **retire `POST /api/players`** (G3) |
| Socket | `UserSocket.connect/3 → {:ok, socket}`; `id/1 → nil`; `RoomChannel` read-only (MATCH) | authenticate `connect/3` by the `SES` connect-param; non-nil `id/1` |
| Token | resolved by `Codemojex.Bot.token/0` (`bot.ex:39`) — app-env key first, else `echo_bot` YAML; nil-safe (MATCH — **not** a `telegram.ex` literal, **not** a `Codemojex.Telegram` module) | the HMAC key source at the handshake; **fail-closed if nil** |
| Verifier | none exists (MATCH) | a new pure `Codemojex.InitData` |
| Session store | `EchoStore.Table` (L1 ETS / L2 Valkey); `put/3` mints version + writes both layers under the declared TTL (`table.ex:90`), `put/4` caller version (`table.ex:97`), `fetch/3 → {:ok, value, source}` ∣ `{:error, :kind}` ∣ `{:error, :no_such_cache}` (`table.ex:63`), `invalidate/3` = `DEL` L2 + `:ets.delete` (`table.ex:174`); `coherence: :tracking` is a real registration value, RESP3 `CLIENT TRACKING` armed at start + re-armed on reconnect (`table.ex:204,255-266`); the kind gate refuses a wrong-namespace id with zero keys (MATCH) | a NEW `:cm_sessions` table, kind `"SES"`, `:tracking`, a JSON loader |
| Existing caches | `Codemojex.Tables` declares `:cm_games`/`:cm_emojisets`, both `coherence: :none` because immutable-for-life; loaders frame with `:erlang.term_to_binary` (MATCH) | register `:cm_sessions` BESIDE them — `:tracking`, a **JSON** loader (NOT `term_to_binary` — a Go edge must read it) |
| Schema | `Codemojex.Schemas.Player` has `tg_chat_id`, no `tg_user_id` (MATCH) | + `tg_user_id` (Venus-Postgres) |
| Facade | `Codemojex` at `game.ex:183`; `create_player/2 → Wallet.create/2` (MATCH — **not** `lib/codemojex.ex`) | + `resolve_player_by_tg/2` (Venus-Postgres) |
| Brand `SES` | namespaces taken: CMD/EMS/GAM/GES/JOB/NOT/PLR/ROM/TXN; **`SES` is free**; `generate!/1` accepts any valid 3-letter ns (MATCH) | mint the session as `EchoData.BrandedId.generate!("SES")` |
| JSON | `:jason` (`{:jason, "~> 1.4"}`) is **declared in codemojex's own `mix.exs` deps/0** (`mix.exs:58`) — compile-visible, NOT transitive-via-phoenix (MATCH) | the SES value codec; **zero new dep** |
| Tests | 8 `Codemojex.Story` suites, all `@moduletag :valkey`, **41 scenarios = 41/0**; drive the facade, not the web layer (MATCH) | the cutover leaves them green; **add** `test/codemojex_web/auth_test.exs` |
| Config | dev DB `codemojex_dev`; test DB `codemojex_test#{MIX_TEST_PARTITION}` (partitioned); `runtime.exs` `:prod` touches only Repo + Endpoint (MATCH) | **no** `echo/config` change this rung — F2 needs no flag (the helper lives in `test/support`) |
| Connector | `Codemojex.Bus` (`store.ex:108`) = `EchoWire.start_link(port: 6390, protocol: 3)`; `Codemojex.Wire` (`wire.ex`); `valkey_port` (`application.ex:21`) | the `:cm_sessions` table rides a `:6390` connector (the `Codemojex.Tables` shape) |

**`Codemojex.Telegram` is a config-key namespace, not a module.** The token source is `Codemojex.Bot.token/0`.

## 4. The verifier — `Codemojex.InitData` (PURE, relocated to the handshake)

A new pure module `lib/codemojex/init_data.ex`. No HTTP, no `Repo`, no session store — a function over a string
and a token, testable with a test-signed fixture. It is the v1 verifier **relocated** from per-request to the
single handshake call.

```
@spec verify(init_data :: binary(), token :: binary() | nil, opts :: keyword()) ::
        {:ok, %{tg_user_id: integer(), user: map(), auth_date: integer(), raw: %{binary() => binary()}}}
        | {:error, reason}
# reason :: :missing | :malformed | :no_token | :bad_hash | :stale
```

The algorithm — **pinned against the live Telegram WebApp docs**
([core.telegram.org/bots/webapps](https://core.telegram.org/bots/webapps)), not memory (the v1 L-2 pins, carried):

1. **Parse** the raw `initData` (a URL-encoded query string) into a map of `key → URL-decoded value`
   (`URI.decode_query/1`). Absent/blank → `{:error, :missing}`. A token of `nil` → `{:error, :no_token}`
   (**fail-closed**: with no bot token configured the handshake rejects rather than authenticating).
2. **Data-check-string** — take every parsed field **EXCEPT `hash` and `signature`** (**FOOTGUN, pinned**: the
   live docs exclude **both**; `signature` is the newer Ed25519 third-party field, and a present `signature`
   left in the string corrupts the check), sort the remaining keys alphabetically, join as `key=value` with
   `\n`.
3. **Secret** — `secret_key = :crypto.mac(:hmac, :sha256, "WebAppData", token)`. **FOOTGUN, pinned**: the
   WebApp derivation (key `"WebAppData"`, msg = token) **differs** from the older Login-Widget form
   (`SHA256(token)`). Use the WebApp form.
4. **Compare** — `expected = Base.encode16(:crypto.mac(:hmac, :sha256, secret_key, data_check_string), case: :lower)`.
   Valid **iff** `:crypto.hash_equals(expected, hash)` (constant-time, OTP-native). Mismatch → `{:error, :bad_hash}`.
   **Never** `==` on the hash — a non-constant-time compare is a timing oracle (the acceptance mutation flips this).
5. **Freshness** — `auth_date` is Unix **seconds**. With `opts[:max_age_seconds]` (a generous default, e.g.
   `86_400`), reject when `now - auth_date > max_age` → `{:error, :stale}`. `opts[:now]` (Unix seconds) injects
   the clock so the fixture is deterministic; `:infinity` disables the window.
6. **Extract** — decode `user` (JSON, via `Jason`) to a map, lift `tg_user_id = user["id"]` (an integer),
   return `{:ok, %{tg_user_id:, user:, auth_date:, raw:}}`. A missing/non-integer `user.id` → `{:error, :malformed}`.

**Determinism** — `verify/3` is a pure function of (`init_data`, `token`, `opts`); the freshness clock is
`opts[:now]`. The HMAC + the compare are pure OTP (`:crypto`).

## 5. The session — `:cm_sessions`, an `EchoStore.Table` entity (kind `"SES"`)

### 5a. The table registration (in `Codemojex.Tables`)

Register a THIRD `EchoStore.Table` child beside `:cm_games`/`:cm_emojisets`, the FIRST **mutable** one:

```
Supervisor.child_spec(
  {EchoStore.Table,
   name: :cm_sessions,
   kind: "SES",
   loader: &load_session/1,      # see 5c — a CLEAN MISS for a SES (no relational system of record)
   coherence: :tracking,         # D-2 — RESP3 CLIENT TRACKING; a DEL/revoke evicts every L1 immediately
   ttl_ms: <sessions_ttl>,       # the SES lifetime (sliding); Operator-tunable, a generous default
   max_size: <cap>,
   connector: [port: 6390, protocol: 3]},
  id: :cm_sessions_table
)
```

- `:tracking` is the ruled coherence mode (D-2) and a **real** registration value (`table.ex:204,255-266`). It
  makes revocation a **security** property: a `DEL` on `ecc:{sessions}:<SES>` is pushed by Valkey to every
  tracking client, evicting the row from each BEAM holder's L1 so the next `fetch` is a clean miss → 401.
- `ttl_ms` is the SES lifetime. A **sliding** TTL (D-2): a resolve that finds a live SES re-`put`s it (5b),
  re-stamping the version + the `PX` deadline.
- The connector mirrors `Codemojex.Tables` (`port: 6390, protocol: 3`).

### 5b. The SES surface (mint / resolve / slide / revoke) — a new `Codemojex.Session` module (`lib/codemojex/session.ex`)

```
# MINT (handshake only — the SOLE writer): mint a SES id, encode {plr, platform, ...} as JSON, put it.
@spec mint(plr :: binary(), platform :: binary(), attrs :: map()) :: {:ok, ses :: binary()}
def mint(plr, platform, attrs \\ %{}) do
  ses  = EchoData.BrandedId.generate!("SES")
  json = Jason.encode!(Map.merge(%{"plr" => plr, "platform" => platform, "iat" => unix_now()}, attrs))
  :ok  = put_session(ses, json)               # EchoStore.Table.put(:cm_sessions, ses, json) — put/3 mints the version
  {:ok, ses}
end

# RESOLVE + SLIDE: fetch the SES; on a hit decode the JSON, re-put (the sliding-TTL move), return the claims.
@spec resolve(ses :: binary()) :: {:ok, %{plr: binary(), platform: binary()}} | {:error, :unknown}
def resolve(ses) do
  case EchoStore.Table.fetch(:cm_sessions, ses) do
    {:ok, json, _source} ->
      claims = Jason.decode!(json)
      _ = put_session(ses, json)              # slide: re-put re-stamps version + TTL (D-2)
      {:ok, %{plr: claims["plr"], platform: claims["platform"]}}
    _ ->                                       # {:error, :kind} | {:error, :no_such_cache} | a miss/expired
      {:error, :unknown}
  end
end

# REVOKE: drop the SES from both layers; :tracking pushes the invalidation to every L1 (D-2).
@spec revoke(ses :: binary()) :: :ok
def revoke(ses), do: EchoStore.Table.invalidate(:cm_sessions, ses)
```

- The **value is JSON** (`Jason`, declared `mix.exs:58`) — the cross-language contract. `EchoStore.Table.put`
  frames it as `SET ecc:{sessions}:<SES> (version<>json) PX ttl_ms` (`table.ex:290`); a forward Go edge reads
  the row, **strips the leading 14-byte version** (`table.ex:429`), then `json.Unmarshal`s. **Never**
  `:erlang.term_to_binary` (a Go edge cannot decode it).
- `mint/3` is called **only** at the handshake (the single-writer model). `resolve/1` is the per-request read
  + the sliding re-`put`. `revoke/1` is the logout/ban.
- The value carries `{plr, platform}` (FB B3) — the cross-edge SES contract is platform-stable; the `PLR` is
  the durable identity (in Postgres), the `SES` references it.

### 5c. The loader

A `SES` has **no relational system of record** — it lives only in Valkey (ephemeral, D-2). The `EchoStore.Table`
loader (`fetch!`-required) must therefore answer a **clean miss** for any id not in L1/L2:

```
defp load_session(<<_::binary-14>> = _ses), do: {:error, :not_found}
```

So a `fetch/3` for an unknown/expired/revoked `SES` returns a miss (L1 empty → L2 empty → loader `:not_found`),
which `resolve/1` maps to `{:error, :unknown}` → the plug 401s. (Contrast the games loader, which falls through
to Postgres; a session has no such floor.)

## 6. The handshake — `POST /api/auth/:platform` (the SOLE `SES` mint)

A new `CodemojexWeb.AuthController.handshake/2` (`lib/codemojex_web/controllers/auth_controller.ex`) + the
route. It is G1's ordering as a route (issue here, verify everywhere else) and the **single writer** the
read-only-edge model depends on (synthesis §2):

```
def handshake(conn, %{"platform" => platform} = params) do
  init_data = params["initData"] || header(conn, "x-telegram-init-data")
  with {:ok, %{tg_user_id: uid} = claims} <- Codemojex.InitData.verify(init_data, Codemojex.Bot.token(), max_age_seconds: <cfg>),
       {:ok, plr} <- Codemojex.resolve_player_by_tg(uid, name: claims.user["first_name"]),
       {:ok, ses} <- Codemojex.Session.mint(plr, platform, %{"tg_user_id" => uid}) do
    json(conn, %{session: ses, player: plr})
  else
    # Render 401 INLINE — every verify/resolve/mint failure is unauthenticated. (D-5: the
    # handshake does NOT route through the FallbackController; see the note below.)
    {:error, _reason} -> conn |> put_status(:unauthorized) |> json(%{error: :unauthenticated})
  end
end
```

> **As-built (D-5) — the handshake renders 401 INLINE, NOT via the `FallbackController`.** The
> `FallbackController.render_error/1` maps only `:no_player → 401`; every `InitData`/resolve reason
> (`:no_token` · `:bad_hash` · `:stale` · `:missing` · `:malformed`) and `:unknown` falls to its
> `render_error(other) → {:bad_request, …}` default — a **400**, which would mis-signal a verify failure and
> breach A1/A4. So `AuthController` owns its own 401 rendering in the `with`'s `else`; the `FallbackController`
> stays owned by the *game* actions (whose `:error` reasons it maps correctly). A `nil` token →
> `{:error, :no_token}` → this inline 401 (fail-closed).

- `platform` is the `:platform` path segment (FB B3's adapter selector — `"telegram"` today; a second platform
  is a new adapter, the SES shape unchanged).
- The token is `Codemojex.Bot.token/0`; a `nil` token → `InitData.verify` returns `{:error, :no_token}` →
  401 (**fail-closed**).
- `resolve_player_by_tg/2` is Venus-Postgres's resolve-or-create (Pattern A) — idempotent, one `PLR` per TG
  user under concurrency.
- `Session.mint/3` is the **only** `SES` write in the system.

## 7. The cutover map (method level — every trust point → its replacement)

### 7a. Router — `lib/codemojex_web/router.ex`

```
pipeline :auth do
  plug CodemojexWeb.Auth
end

scope "/api", CodemojexWeb do
  pipe_through :api
  post "/auth/:platform", AuthController, :handshake   # NEW — the SOLE SES mint (open: it issues the bearer)
  # ... health/rooms/game/leaderboard stay on :api (open) ...
end

scope "/api", CodemojexWeb do
  pipe_through [:api, :auth]
  post "/rooms/:id/join", GameController, :join
  post "/games/:id/guess", GameController, :guess
  get  "/games/:id/history", GameController, :history
  post "/keys/buy", GameController, :buy_keys
  post "/keys/convert", GameController, :convert
end
```

| Route | Pipeline after cm.4 |
|---|---|
| `POST /api/auth/:platform` (`:handshake`) | `:api` only — open (it *issues* the bearer; verify here is `initData`, not a `SES`) |
| join / guess / history / buy_keys / convert | `:api, :auth` |
| `POST /api/players` (`:create_player`) | **DELETED** — route + action removed (G3) |
| health · rooms · game · leaderboard | `:api` (unchanged) |

### 7b. The plug — `CodemojexWeb.Auth` (new `lib/codemojex_web/auth.ex`)

A `Plug` (`init/1` + `call/2`):

1. Read the bearer — `Authorization: Bearer <SES>` (FE). (No dev/test bypass — F2.)
2. **Resolve** — `Codemojex.Session.resolve(ses)`; on `{:ok, %{plr: plr}}` → `assign(conn, :player, plr)`
   (the resolve also slides the TTL, 5b).
3. **Reject** — a missing/malformed bearer, or `{:error, :unknown}` (unknown / expired / revoked SES) →
   `conn |> put_status(401) |> json(%{error: :unauthenticated}) |> halt()`. A revoked SES is `:unknown` on the
   next request because `:tracking` evicted it from L1 and the `DEL` cleared L2 (D-2).

The plug assigns `conn.assigns.player` — the **only** identity an action reads.

### 7c. The controller — `lib/codemojex_web/controllers/game_controller.ex`

The five actions read `conn.assigns.player`; **delete** `require_player/1`; **delete** `create_player/2` (G3).

```
def join(conn, %{"id" => room}) do
  with {:ok, game} <- Codemojex.join_room(room, conn.assigns.player) do
    json(conn, %{game: game, view: Codemojex.game_view(game)})
  end
end
```

Apply the same shape to `guess`, `history`, `buy_keys`, `convert`. `health`/`rooms`/`game`/`leaderboard` are
untouched.

### 7d. The socket — `lib/codemojex_web/channels/user_socket.ex`

```
def connect(params, socket, _connect_info) do
  case Codemojex.Session.resolve(params["session"] || params["token"]) do
    {:ok, %{plr: plr}} -> {:ok, assign(socket, :player, plr)}
    {:error, _}        -> :error
  end
end

def id(%{assigns: %{player: plr}}), do: "player_socket:" <> plr
def id(_socket), do: nil
```

The `SES` is the socket connect-param (FE — a body field, not a query string, to keep it out of proxy logs). A
bad/missing/revoked SES → `:error` (the connection is refused). `id/1` is non-nil for an authenticated socket.
`RoomChannel` is unchanged (read-only).

## 8. Dev/test posture (F2 — D-2)

**No prod bypass, no config flag.** A `test/support` helper mints a real `SES` so the suite + a ConnTest get a
bearer without a live Telegram, and a fixture-signed `initData` exercises the real handshake verify path:

```
# test/support/codemojex/auth_helper.ex (or test/support/...)
def put_session_for(plr, platform \\ "telegram") do
  {:ok, ses} = Codemojex.Session.mint(plr, platform, %{})   # a REAL SES in the test Valkey
  ses
end

def sign_init_data(fields, token) do
  # build the data-check-string (exclude hash+signature), HMAC-SHA256("WebAppData", token), append &hash=...
  # → a valid initData string the handshake accepts; tamper one field for the reject test.
end
```

- The token is `nil` in test (the codemojex app-env key is unset; `Codemojex.Bot.token/0` falls to the echo_bot
  YAML, not a deterministic signer) — so the fixture **sets a known token** via
  `Application.put_env(:codemojex, Codemojex.Telegram, token: "<test-token>")` (restored `on_exit`), signs with
  it, and asserts accept; a tampered field asserts 401. (The v1 L-1.3 finding, carried.)
- **F2 rationale (D-2):** a shared store warrants the higher bar — a leaked `trust_supplied_player` bypass
  minting `SES`s into shared Valkey would fool every service. The helper is `test/support` only; it cannot ship.

## 9. Acceptance (the runnable gate — every invariant a check; a no-op must not satisfy its letter)

Run from `echo/apps/codemojex`, `TMPDIR=/tmp`, Valkey on `6390` + Postgres up.

| # | Invariant | The check (positive proof) |
|---|---|---|
| A1 | A forged / missing / expired / **revoked** `SES` → **401** on every player-acting endpoint **and** the socket connect | `auth_test.exs`: for each of the 5 routes, a request with no `Authorization` → 401; a garbage bearer → 401; a `SES` after `revoke/1` → 401; a socket `connect/3` with each → `:error`. A present precondition runs it (a real request per route). |
| A2 | A valid handshake → a `SES` minted + the **correct `PLR`** resolved; resolve-or-create **idempotent** + the **concurrency race** | a fixture-signed `initData` → `POST /api/auth/telegram` returns `{session, player}`; presenting that `SES` runs an action as that `PLR`; two handshakes for the same TG user → the **same** `PLR` (one `players` row); the concurrent first-touch (Venus-Postgres §2.4) → one row. |
| A3 | **THE REVOCATION INVARIANT** (the load-bearing one — the first mutable EchoStore table) | mint a `SES`, prove an action authenticates with it; `Codemojex.Session.revoke(ses)`; the **next** request with that `SES` → **401** — because `:tracking` evicted it from L1 and the `DEL` cleared L2 (D-2). The test proves a revoked `SES` stops authenticating **immediately** (no stale window) — or, if a residual window is unavoidable in the harness, the staleness bound is **named in the spec** and asserted ≤ one tick. |
| A4 | The verifier is **pure + fixture-tested** (accept + tamper-reject); the compare is **constant-time** | `InitData` unit tests: a fixture signed with a known test token → `{:ok, %{tg_user_id: N}}`; flip one field → `{:error, :bad_hash}`; a present `signature` field is excluded (accept still holds); a `nil` token → `{:error, :no_token}`. **Mutation:** flipping `:crypto.hash_equals` to a truthy constant MUST make A4 fail (the net-zero spot-check). |
| A5 | `POST /api/players` is **gone** (G3) | a request to `POST /api/players` → **404** (the route is removed); a grep shows no `create_player` action. The free-player mint is impossible without a verified handshake. |
| A6 | F2 — the dev/test helper mints a real `SES`, **no prod bypass** | the helper lives in `test/support`; a grep shows **no** `trust_supplied_player` (or any auth-skip) in `lib/`. |
| A7 | The 8 story suites stay **byte-unchanged** + green | `git diff --stat test/stories/` empty; `mix test --include valkey` → the **41 story scenarios** green (41/0) **plus** the new auth suite (**29 tests**) = **70 tests / 0 failures** (the measured as-built total — 41 story + 29 auth; re-pinned in the Director Y-10 verify and Apollo's T-16). |
| A8 | The migration **up/down** + fresh-schema reinit clean | Venus-Postgres: `MIX_ENV=test mix ecto.migrate` then `ecto.rollback` (the `tg_user_id` column + the partial unique index), `mix ecto.drop/create/migrate` clean (partitioned DB). |
| A9 | The **≥100 determinism loop** (the handshake mints BOTH a `PLR` and a `SES` → the same-ms branded-id mint hazard) | `for i in $(seq 1 150); do TMPDIR=/tmp mix test --include valkey || break; done` green throughout. |
| A10 | The **privacy line** holds | the game `secret` never crosses the wire (the existing privacy stories stay green; the auth cutover does not touch the views). |

Gate ladder (per-app, from the app dir): re-probe `asdf current` / `.tool-versions` (Elixir 1.18.4 / OTP
28.x) · `valkey-cli -p 6390 ping` → `PONG` · Postgres up · `TMPDIR=/tmp mix compile --warnings-as-errors` ·
`TMPDIR=/tmp mix test --include valkey` · the migration up/down + reinit · the ≥100 loop.

## 10. Boundary

`echo/apps/codemojex/**` only:
`lib/codemojex/init_data.ex` (new) · `lib/codemojex/session.ex` (new) · `lib/codemojex/tables.ex` (the
`:cm_sessions` child) · `lib/codemojex_web/auth.ex` (new) ·
`lib/codemojex_web/controllers/auth_controller.ex` (new) · `lib/codemojex_web/router.ex` ·
`lib/codemojex_web/controllers/game_controller.ex` · `lib/codemojex_web/channels/user_socket.ex` ·
`lib/codemojex/game.ex` (the `resolve_player_by_tg/2` facade — Venus-Postgres) · `lib/codemojex/wallet.ex`
(`resolve_by_tg/2` — Venus-Postgres) · `lib/codemojex/schemas/player.ex` (`+ tg_user_id` — Venus-Postgres) ·
`priv/repo/migrations/<new>` (Venus-Postgres) · `test/support/<auth helper>` (new) ·
`test/codemojex_web/auth_test.exs` (new) · `docs/codemojex/specs/cm.4.*`.

**No `echo/config` change** (F2 needs no flag). **Out of bounds:** every sibling umbrella app (echo_mq /
echo_store / echo_data / echo_wire / echo_bot — codemojex consumes their surface, never edits it); `echo/mix.lock`
(no new dependency — `:crypto` is OTP, `:jason` is already declared); the `infra/codemojex-bitmapist/` Go edge
(a forward-vision consumer, not in this floor); a frozen ledger's history.

## 11. Phasing — what this floor ships vs the forward rungs

**The cm.4 FLOOR (this triad):** the `Codemojex.InitData` verifier + the handshake (`POST /api/auth/:platform`)
minting the `SES`-in-Valkey (JSON) + the `:cm_sessions` `EchoStore.Table` (`:tracking`, sliding TTL, ephemeral)
+ the `SES`-resolve plug over the 5 routes + the socket `SES`-verify + the `require_player → conn.assigns.player`
cutover + **retire `POST /api/players`** + the F2 dev/test helper + `invalidate`/`DEL` revocation + `auth_date`
freshness + Venus-Postgres's PLR migration.

**FORWARD rungs (shaped, NOT the floor — the floor forecloses nothing; all read the same documented `SES`
shape):** the documented **Go-edge read contract** (strip 14 bytes → `json.Unmarshal`, read-only, Valkey-ACL
`GET`-only); **bitmapist** marking (the Go marker on `:6400`, by the durable `PLR`, off the auth hot path);
**LiveView** auth (the same `fetch(:cm_sessions, …)` surface); **`SES` Graft-durability** (the forward
Venus-Persistence design-ahead, D-3).

## 12. Build brief

See [`cm.4.llms.md`](./cm.4.llms.md) — the compressed agent brief: the references, the numbered requirements
(each traced to a story + an invariant), the execution topology + the file-by-file build order (smallest-change
first), the agent stories (Directive + Acceptance gate), the cite-map (every public call → its real module),
and the gate ladder. The acceptance face is [`cm.4.stories.md`](./cm.4.stories.md).
