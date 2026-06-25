# cm.4 — Verified Telegram `initData` (the auth floor) · the rung runbook

> The `<rung>.prompt.md` for `/codemojex-ship cm.4` — the Director's bootstrap runbook. The triad
> (`cm.4.{md,stories.md,llms.md}`) does not exist yet; **Venus authors it in Stage 1** from this runbook.
> Mode **Flat-L2**, formation **L2 Squad** (HIGH-risk). The canon is
> [`../codemojex.design.md`](../codemojex.design.md) (§"The web surface" names this exact gap) +
> [`../codemojex.roadmap.md`](../codemojex.roadmap.md) (the feature catalog, "Identity and access"). The
> program is [`../program/codemojex.program.md`](../program/codemojex.program.md).

## The rung in one paragraph

Close the **one named pre-launch gap**: the surface trusts a client-supplied player id —
`CodemojexWeb.GameController.require_player/1` (`game_controller.ex:77`) reads `params["player"]` verbatim
(5 player-acting endpoints: join · guess · history · buy_keys · convert), and `UserSocket.connect/3`
accepts any connection (`{:ok, socket}`, `id → nil`). Replace that trust point with **verified Telegram
`initData`**: a pure verifier (HMAC-SHA-256 over the data-check-string, the WebApp secret derived from the
existing `Codemojex.Telegram` `:token` — **zero new secret, zero new dep**, `:crypto` is OTP) that
authenticates each request, **resolves the verified Telegram user to a `PLR`** (resolve-or-create on a new
`players.tg_user_id` unique index), and assigns it — so no player-acting endpoint or socket trusts a
caller-supplied identity. **Per-request verification** (the `initData` *is* the bearer credential); the
short-lived `SES` session token is an OPTIMIZATION **deferred** to a later rung. The smallest change that
makes the invalid state — acting as another player — **unrepresentable**.

## Mode & formation

**Flat-L2 · L2 Squad.** HIGH-risk (auth/security + a schema delta + a wire-adjacent cutover of every
authenticated endpoint). **Apollo MANDATORY.** **Data-model rung → Venus ∥ Venus-Postgres** (the
`tg_user_id` column/index/migration + the resolve-or-create transactional path, with its uniqueness race).
The Director rules the forks via `AskUserQuestion`; the verify deepens (the migration up/down, the ≥100
mint loop, the mutation battery on the verifier).

## Boundary

`echo/apps/codemojex/**` ONLY:
- `lib/codemojex_web/router.ex` (an `:auth` pipeline) · `controllers/game_controller.ex` (the
  `require_player` cutover) · `channels/user_socket.ex` (`connect/3` auth) ·
- a NEW verifier (`lib/codemojex/init_data.ex` — pure — and/or a `CodemojexWeb.Auth` plug) ·
- `lib/codemojex/schemas/player.ex` (`+ tg_user_id`) · `lib/codemojex/store.ex` + the facade
  `lib/codemojex.ex` (resolve-or-create) · `priv/repo/migrations/<new>` ·
- `test/<new auth test>` · the rung's `docs/codemojex/specs/cm.4.*`.

Plus **read** the umbrella `echo/config/{dev,test,runtime}.exs` and add **one** dev/test-posture config line
(surface it; the rung does not own the umbrella config broadly — split it to its own scoped commit if the
Operator prefers). **Out of bounds:** every sibling umbrella app; `mix.lock` (no new dep).

## Ground truth (re-probed on disk — do not re-derive)

- **The gap:** `game_controller.ex:77` `defp require_player(%{"player" => p}) when is_binary(p) and p != "", do: p` — trusts the param; 5 endpoints route through it. `create_player` mints a new player from a name. `user_socket.ex` `connect/3 → {:ok, socket}` (no auth), `id/1 → nil`. `room_channel.ex` is **read-only** (its only client→server msg, `refresh`, takes no player).
- **The secret:** `config :codemojex, Codemojex.Telegram, token: ...` (resolved at `telegram.ex` / `bot.ex:40`) — **REUSE** as the `initData` HMAC key. No new secret/dep.
- **The schema:** `players` has `tg_chat_id` (a *chat* id, for notifications) but **NO `tg_user_id`**; `initData` identifies a *user* → add `tg_user_id` (bigint, **UNIQUE**) + resolve-or-create. `wallet.ex:27` mints the `PLR` + sets `tg_chat_id` on create.
- **The tests:** the 8 story suites drive the **facade** (`Codemojex.create_player/join_room/submit`), NOT the web layer — so the `require_player` cutover leaves them **41/0 green**. **No web/controller test exists** → the rung ADDS one.
- **Config:** `echo/config/{dev,test}.exs` (DB `codemojex_dev`/`codemojex_test`); the **test env contacts no Telegram** (the fake updater never uses the token) → the rung needs a dev/test posture to verify without a real signature.

## Settled (do not re-litigate)

- Verify per the **Telegram WebApp** spec: build the `data_check_string` (every `initData` field except
  `hash`, sorted by key, joined `key=value` with `\n`); the WebApp secret = `HMAC-SHA256(key="WebAppData",
  msg=bot_token)`; valid iff `lower_hex(HMAC-SHA256(key=secret, msg=data_check_string)) == hash`.
  **Constant-time compare.** **FOOTGUN:** the WebApp derivation differs from the Login-Widget one
  (`SHA256(bot_token)`) — ground the exact key/msg order against the **current Telegram WebApp docs**, not memory.
- The verifier is a **PURE** function (no HTTP) — testable with a **test-signed fixture** (sign with a test
  token → assert accept; tamper one field → assert reject).
- Resolve-or-create the `PLR` by the verified Telegram user id, **idempotently** (one `PLR` per TG user;
  concurrent first-touch → one row, enforced by the unique index).
- **Per-request verification** — no `SES` session token this rung.
- The existing 8 story suites stay **byte-unchanged** + green.

## Forks to frame (Venus → the Director's `AskUserQuestion`)

- **F1 — Session.** Per-request `initData` verify *(REC — the tight floor)* vs mint+carry a short-lived
  signed `SES` token now. If per-request, `SES` defers to a later rung.
- **F2 — Binding.** `players.tg_user_id` (bigint, **UNIQUE**) + resolve-or-create *(REC — the only grounded
  path)* — confirm the column nullability/backfill, the unique index, and the resolve-or-create contract.
- **F3 — `create_player` endpoint.** Retire (resolve-or-create replaces it) vs keep behind the dev/test
  posture / admin-only *(REC — keep behind the dev/test flag; prod creates via resolve-or-create)*.
- **F4 — Socket.** Authenticate `connect/3` now *(REC — verify `initData` from the connect params → assign
  the player + `id/1`)* vs defer (the channel is read-only today).
- **F5 — Dev/test posture.** A config flag (e.g. `config :codemojex, CodemojexWeb, trust_supplied_player:
  true` in dev/test, absent/false in prod) so the story/dev surface + local `curl` work without a real
  signature, AND a test-signed `initData` fixture for the real verify path *(REC — both)*.
- **F6 — Freshness.** A configurable `auth_date` max-age (reject stale `initData`) *(REC — include, generous
  default)* vs omit.

## Per-stage prompts

- **Stage 1 — Venus ∥ Venus-Postgres** (identical locked-constraints brief, disjoint files, no sibling
  reads until both land):
  - *Venus* (token/wire/code + the build brief): author `cm.4.{md,stories.md,llms.md}`; the verifier
    surface + the `:auth` pipeline/plug, the `require_player → conn.assigns.player` cutover map (`file:line`),
    the socket `connect/3` auth, the dev/test posture, the acceptance (forged/missing/expired → 401; valid →
    the right `PLR`; the pure-verifier fixture). Frame F1/F3/F4/F5/F6.
  - *Venus-Postgres* (relational): the `players.tg_user_id` column + the **UNIQUE** index, the
    resolve-or-create transactional path (`Store` + the facade), the migration (add column + index), the
    reinit posture. Frame F2.
- **Stage 2 — Mars-1:** build to the brief inside the boundary — the pure verifier + the plug/pipeline + the
  resolve-or-create + the `require_player` cutover + the socket auth + the dev/test flag + the migration +
  the auth test; `compile --warnings-as-errors`; run the gate.
- **Stage 3 — Director verify:** an independent gate re-run (compile + `mix test --include valkey` on Valkey
  6390 + Postgres + the migration up/down + the ≥100 mint loop) + an adversarial probe (a forged hash · a
  replayed/stale `initData` · a field-injection · a `tg_user_id` collision) + a **net-zero mutation
  spot-check** on the verifier (flip the HMAC compare → a test MUST catch it; revert by inverse Edit).
- **Stage 4 — Mars-2:** remediate + harden — constant-time hash compare; the freshness window; the
  resolve-or-create race; the dev/test flag **safe-by-default in prod**.
- **Stage ◇ — Apollo (MANDATORY, HIGH-risk):** the §11.2 charter — the prompted-checks table (the HMAC
  verify · the 401 rejections · the resolve idempotency · the no-trust-supplied-in-prod default · the socket
  auth · the freshness) each `file:line` PASS/FAIL; ≥1 un-prompted finding; ≥1 attack-that-held (a forged
  `initData` rejected); a mutation kill-rate on the verifier (flip the compare · drop the freshness ·
  accept-on-empty-hash — each caught). Resolve every ambiguity via `AskUserQuestion`. **BUILD-GRADE /
  BLOCKED.**
- **Stage 5 — Director ship:** one LAW-4 pathspec commit + the Stage-6 fold (flip `cm.4` SHIPPED in the
  roadmap/progress, renumber the `cm.4+` band; surface the next frontier — the `SES` session optimization,
  then `RMP`/`BNK`).

## Acceptance (the gate)

- `compile --warnings-as-errors` clean; `mix test --include valkey` green — the 8 stories **byte-unchanged**
  at 41/0 + the **new auth suite** — on Valkey 6390 + Postgres, `TMPDIR=/tmp`.
- The migration **up/down** (`tg_user_id` add + UNIQUE index) + the fresh-schema reinit clean.
- The **≥100 determinism loop** (the resolve-or-create mints a `PLR` → the same-ms mint hazard).
- A forged/missing/expired `initData` → **401** on every player-acting endpoint + the socket `connect`; a
  valid `initData` → the **correct `PLR`**; the resolve-or-create is **idempotent** (same TG user → one `PLR`).
- The verifier is **pure + fixture-tested** (accept + tamper-reject); the HMAC compare is **constant-time**.
- In **prod** config the trust-supplied bypass is **OFF by default** (a test asserts the prod default
  rejects a supplied id).
- `mix codemojex.stories` regenerated if a story was added.

## Commit pathspec

`echo/apps/codemojex/**` + `docs/codemojex/specs/cm.4.*` + the `cm.4` status flip in
`docs/codemojex/codemojex.{roadmap,progress}.md` + the one `echo/config` dev/test-posture line (surface it;
split to its own scoped commit if the Operator prefers). **NEVER `git add -A`; pathspec only**; re-verify
`git diff --cached --name-only` is purely the rung before the commit.
