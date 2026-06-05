# F10 · Grooming — the echo_bot backlog, refined

> The backlog-grooming view for the F10 (`echo_bot` engine + games) value ladder: the recommended build order for the
> near-term rungs (**F10.1 build-next → F10.2 → F10.3**, then the deferred F10.4–F10.10 abstracts), each rung's
> deliverables, and — the load-bearing part — the `[RECONCILE]` rationales that turn each rung from *discover* into
> *decide*. The per-rung spec triads (`f10.N.{md,stories.md,llms.md}`) are the **source of truth**; this file is the
> planning view that sequences them and surfaces the decisions each one forces. Companion to the delivery view
> [`f10.roadmap.md`](f10.roadmap.md).

## Status — where the ladder stands

**F10.1** is **BUILD-NEXT**: its triad ([`f10.1.md`](f10.1.md) / [`.stories.md`](f10.1.stories.md) /
[`.llms.md`](f10.1.llms.md)) and its Director orchestration brief [`f10.1.prompt.md`](f10.1.prompt.md) are authored and
ready to fan out the lead-team. **F10.2** and **F10.3** are **specced backlog, groomed** — full triads exist, their
`[RECONCILE]` callouts are written forward-looking against F10.1's surfaces. **F10.4–F10.10** are feature **abstracts** in
[`f10.roadmap.md`](f10.roadmap.md), sharpened into triads only once the shipped engine and the first game earn feedback.
Nothing in `apps/echo_bot/` or `apps/echo_games/` is built yet — the umbrella at `/Users/jonny/dev/jonnify/echo` carries
`echo_data`, `portal`, `portal_web` today — so every F10.2/F10.3 reconcile is a **pre-build** reconcile against the
as-built predecessor, discharged the moment that predecessor ships.

## Recommended build order

| # | Rung | Why here |
|---|---|---|
| 1 | **F10.1 · Engine skeleton** (vendored-fork wrap) | BUILD-NEXT — the only rung with everything ready (triad + ship prompt). Greenfield, no predecessor surface to re-probe; the roadmap already settled its three would-be forks (wrap-then-own, vendored path, YAML v1.0). Stands the engine up end to end with one bot, so every later rung has a real skeleton to extend. |
| 2 | **F10.2 · Multi-bot** | Depends only on F10.1's shipped skeleton — the loader, the supervisor, the platform-adapter port + vendored wrap. Adds no platform, no vendored code, no schema change; generalizes one bot to N. "Multibot" lands here, the precondition for everything later running across many bots. |
| 3 | **F10.3 · The minimal valuable game** | Heaviest near-term rung — a new app (`echo_games`), a new isolated web server, a Svelte/Vite rewrite, WebSocket live state, and the payments seam. Builds on F10.1/F10.2 for the launch; carries the one open architecture fork (the games web server). The first playable, monetizable slice. |
| — | **F10.4–F10.10** (deferred) | Abstracts in [`f10.roadmap.md`](f10.roadmap.md): the richer Telegram surface (F10.4), webhook (F10.5), owning the wrap (F10.6), adapter hardening (F10.7), the full payments flow (F10.8), the optional Portal-consumer (F10.9), robustness + notifications + the second-platform seam (F10.10). Each is sharpened into a triad only when the shipped engine and first game earn feedback. |

**Why F10.1 first.** It is greenfield — `apps/echo_bot` does not yet exist — so there is no STALE / INVENTED / MISSING
claim against as-built `echo_bot` code; the pre-build reconcile is against the **umbrella conventions** the new app must
match (the standard `mix.exs` block, `apps_path` auto-discovery, the `:one_for_one` named-supervisor pattern, the
`config/config.exs` per-app block). The roadmap closed the three questions that would otherwise be forks (the library
posture, the vendored path, the YAML v1.0 schema), so F10.1 carries **no open fork** — only roadmap-ratified additions to
pin in the brief.

**Why F10.2 before F10.3.** F10.2 is a pure generalization of F10.1 (a directory loader + a per-bot fan-out) inside one
app, with the platform-adapter port, the vendored wrap, and the YAML v1.0 schema all inherited unchanged — its only open
shape question (static fan-out vs `DynamicSupervisor`) carries a recommendation. F10.3 introduces two new apps' worth of
surface and the one architecture fork, so it lands last in the near-term arc, on a proven multi-bot engine.

---

## F10.1 · Engine skeleton (vendored-fork wrap) — BUILD NEXT

[Spec: [`f10.1.md`](f10.1.md)] · Goal: a YAML file plus a handler module is a running bot — one bot, polling, `/start` +
`/help` static text, over a vendored ex_gram copy wrapped behind the platform-adapter port, Portal untouched.

**Deliverables**

| ID | Deliverable |
|---|---|
| D1 | The new standalone umbrella app `apps/echo_bot` (`mix.exs`: app `:echo_bot`, namespace `EchoBot`, `mod: {EchoBot.Application, []}`, the standard `../../` umbrella block, deps a YAML parser + the vendored client's HTTP/JSON deps; **no** `{:portal, in_umbrella: true}`; **no** root `mix.exs` edit). |
| D2 | The **vendored ex_gram copy** under `apps/echo_bot/vendor/ex_gram/` (the minimal `getUpdates` long-poll + `sendMessage` subset + decoders + updater shape) plus its `README.md` (provenance + preserved Beer-Ware license) and `CLAUDE.md` (the owned-fork directive: modifiable directly, no upstream PR, reachable only through the adapter; the propagation clause). |
| D3 | `EchoBot.Application.start/2` — a `:one_for_one` `EchoBot.Supervisor` over the loaded single bot's updater process (plus any adapter client/registry process). `Portal.Application` / `PortalWeb.Application` not named, started, or touched. |
| D4 | The YAML **v1.0** config loader (`EchoBot.Config`): reads `version` first, validates the rest, reads **one** definition (`name`, `platform`, `token_env`, `handler`), resolves the token from the named env var at boot (never in the YAML), selects the adapter from `platform`. |
| D5 | The platform-adapter behaviour `EchoBot.Platform` (start an updater, send a reply, the command/update shape); `EchoBot.Platform.Telegram` **wraps the vendored copy** with a polling updater selectable as a **fake** updater for tests — the only module naming a vendored module. |
| D6 | The handler/router seam — a `/start` + `/help` router answering static text, a pure function of the update, naming no Portal function and no vendored module. |
| D7 | Idempotent update handling — a re-delivered `update_id` produces the same single reply and no duplicate effect (the handler is a pure function of the update). |
| D8 | The fake-updater test posture — handler tests feed a constructed `/start` / `/help` and assert the rendered reply; a loader test asserts a YAML v1.0 file yields the five-field definition with a resolved token. |
| D9 | Verification — boot under `EchoBot.Application`; the loader produces one bot; `/start`/`/help` answer via the fake updater; a re-delivered update is idempotent; killing the updater triggers a supervised restart; only the adapter names a vendored module; Portal unchanged; a live manual demo. |

**`[RECONCILE]` rationales** (why / what) — F10.1 is **greenfield**, so these are not STALE/INVENTED claims against
as-built code but the **roadmap-ratified additions** this rung introduces, pinned in the brief and marked
`[RECONCILE]`-deferred (built this rung, decided by the roadmap, not re-opened as forks):

| Callout | Rationale |
|---|---|
| **Greenfield — convention reconcile, not code reconcile** | `apps/echo_bot` does not exist, so there is no STALE / INVENTED / MISSING claim against `echo_bot` code. *Why: the rung adds a brand-new app over an unchanged umbrella* → the pre-build reconcile is against the **umbrella conventions** the new app must match (the `mix.exs` `../../` block per `apps/portal_web/mix.exs:8-12`; `apps_path: "apps"` auto-discovery per the root `mix.exs:6`, so **no root edit**; the `:one_for_one` named-supervisor pattern per `apps/portal/lib/portal/application.ex:40` and `apps/portal_web/lib/portal_web/application.ex:21`; the `config/config.exs:52` per-app block). Confirm each cite resolves; the `echo_bot` config block is umbrella-level, never `portal`/`portal_web` code. |
| **Library posture — RATIFIED (wrap-then-own)** | *Why: the roadmap decided it* → `echo_bot` carries a **vendored, owned copy** of ex_gram (not the hex dep, not a from-scratch hand-roll) and wraps it behind the port. The copy is owned source — modifiable directly, no upstream PR. Pinned, not re-opened. |
| **Vendored path — RATIFIED (`apps/echo_bot/vendor/ex_gram/`)** | *Why: the roadmap fixed the layout* → the vendored tree lives under `apps/echo_bot/vendor/ex_gram/` with its `README.md` (provenance + Beer-Ware license) and `CLAUDE.md` (ownership directive). The F10.1 triad fixes the exact subset of ex_gram modules vendored. Pinned, not re-opened. |
| **YAML v1.0 schema — RATIFIED (approved)** | *Why: the roadmap approved the five-key schema* → `version`, `name`, `platform`, `token_env`, `handler`, all required, the `version` read first. The token is referenced by env-var name and read at boot, never in the file. Pinned, not re-opened. |
| **Scope — RATIFIED (one bot, static text)** | *Why: the roadmap set the slice* → **one** bot, polling, `/start` + `/help` static text; **no** games (→ F10.3), **no** Portal touchpoint (→ F10.9, optional). The wrap boundary (engine core reaches the vendored copy only through the adapter) is established here for every later rung to inherit. |

**Open decisions for the build:** none open — the roadmap settled the three would-be forks (library posture, vendored
path, YAML v1.0). The reconcile is the convention-cite check above; Venus pins the ratified additions and refreshes
[`f10.1.llms.md`](f10.1.llms.md). The only forward work is the closing **feedback loop** (fold F10.1's as-built
`EchoBot.Config` + supervisor surface into the F10.2/F10.3 `[RECONCILE]`s).

---

## F10.2 · Multi-bot: N YAML bots under one engine

[Spec: [`f10.2.md`](f10.2.md)] · Goal: the engine runs **N** bots from a directory of YAML v1.0 files, each under its
own supervised, isolated subtree, all under one `:one_for_one` `EchoBot.Supervisor`. Adding a bot is dropping a file.

**Deliverables**

| ID | Deliverable |
|---|---|
| D1 | The **directory** config loader — `EchoBot.Config` reads **every** `*.yaml` in the configured bot-config directory and returns a **list** of per-bot definitions, each the same shape F10.1's single-file loader returns (reusing F10.1's v1.0 reader; adding only the directory walk + list result). |
| D2 | Per-file validation + **duplicate-`name` rejection** — each file validated against v1.0 independently, reported per file; two definitions sharing a `name` (the supervisor child id) are rejected. Recommend **fail-fast at boot**, reconciled to F10.1's loader error shape. |
| D3 | The per-bot supervised **fan-out** — `EchoBot.Application.start/2` starts one isolated bot subtree per definition under the existing `:one_for_one` `EchoBot.Supervisor`, each child id derived from the bot's `name`. **Recommended shape: static fan-out** (a static child list computed at `init/1`); `DynamicSupervisor` deferred to a rung adding runtime add/remove. |
| D4 | Per-bot **token + handler dispatch** — each bot resolves its own token from its own `token_env` and routes through its own `handler`; an update to bot A is handled by bot A, never crossed with bot B. |
| D5 | The **second bot** (a second YAML file + a second handler module) added to prove the drop-a-file path with no engine-code edit; both bots answer `/start`/`/help` with their own text. |
| D6 | The per-bot **supervised-start test** — N v1.0 files yield N running supervised bots, each child id derived from its `name`, each handler reachable via the fake updater. |
| D7 | The **isolation test** — killing one bot's updater restarts only that bot under `:one_for_one`; a sibling keeps answering throughout; the engine + Portal supervisors undisturbed. |
| D8 | Verification — `mix compile` clean, N bots boot; the directory loader yields one definition per file; `name`-collisions rejected; per-bot dispatch holds; dropping a file adds a bot; one bot's crash isolates; only the adapter names a vendored module; Portal unchanged; a live two-bot demo. |

**`[RECONCILE]` rationales** (why / what) — mirrored from the F10.2 triad's
`## [RECONCILE] — folded forward from F10.1 (PENDING — predecessor not yet built)`. Each row is either
**PENDING-on-F10.1** (re-probe the as-built single-bot surface the moment F10.1 lands) or **SETTLED** (fixed by the
roadmap, inherited unchanged):

| Callout | Rationale |
|---|---|
| **`EchoBot.Config` return shape — PENDING on F10.1** | *Why: F10.2 maps the loader over a directory, so it depends on the exact value F10.1's single-file loader returns (struct vs bare map, field names, the resolved-token field)* → re-probe `apps/echo_bot/lib/echo_bot/config.ex` when F10.1 ships; F10.2's directory loader returns a **list of the same per-bot value**, one per file, matched field-for-field. Define **no new per-bot field** here. |
| **`EchoBot.Application` child-build path — PENDING on F10.1** | *Why: F10.1 starts one bot's updater under `EchoBot.Supervisor`; F10.2 generalizes to a fan-out over N definitions, so the exact single-bot child spec is the unit F10.2 repeats* → re-read `apps/echo_bot/lib/echo_bot/application.ex` and the per-bot child spec when F10.1 ships; reuse it, do not redesign the per-bot process shape. |
| **Engine supervisor strategy + name — SETTLED by the roadmap** | *Why: the roadmap fixes `:one_for_one` and F10.1 names the supervisor `EchoBot.Supervisor`* → F10.2 keeps both; the only open shape question is **static fan-out vs `DynamicSupervisor`** under that strategy (resolved in D3 with a recommendation). **No fork on strategy or name.** |
| **Per-bot child identity (child id) — SETTLED by the roadmap** | *Why: the roadmap fixes the YAML `name` as the supervisor child id + log identifier* → F10.2 derives each child id from `name`, so two same-`name` definitions collide deliberately and the loader rejects the duplicate (D2). **No new identity scheme invented.** |
| **Platform-adapter port + vendored wrap — SETTLED, inherited unchanged** | *Why: the behaviour, the Telegram adapter, and the vendored copy are F10.1 deliverables and the roadmap states the wrap is the long-lived boundary* → F10.2 adds **no** adapter, **no** vendored code, **no** platform; N bots run through the same port and wrap, the boundary preserved as an F10.2 invariant. |
| **YAML v1.0 schema — SETTLED (approved), unchanged** | *Why: the five-key v1.0 schema is approved and read per-file by F10.1* → F10.2 reads the **same** schema, once per file; it bumps **no** version and adds **no** key. The directory-of-files generalization is a loader change, not a schema change. |

**Open decisions for the build:** (1) the **static-fan-out vs `DynamicSupervisor`** shape (recommended: static fan-out;
`DynamicSupervisor` deferred to the rung that adds runtime bot management) — the Operator confirms; (2) the **failure
posture for one bad file among good ones** (recommended: fail-fast at boot), reconciled to F10.1's as-built loader error
convention. Both PENDING rows above are pre-build re-probes the Director discharges the moment F10.1 lands.

---

## F10.3 · The minimal valuable game — `echo_games` + Svelte/Vite + WebSocket + the payments seam

[Spec: [`f10.3.md`](f10.3.md)] · Goal: the first playable, monetizable slice — a bot launches "Эмоджи: Найди пару", a
Svelte 5/Vite frontend renders state pushed over a WebSocket from a server-authoritative `echo_games`, the score
computed on the BEAM, the payments seam opened. **The heaviest near-term rung.**

**Deliverables**

| ID | Deliverable |
|---|---|
| D1 | The new standalone umbrella app `apps/echo_games` (`mix.exs`: app `:echo_games`, namespace `EchoGames`, `mod: {EchoGames.Application, []}`, the standard `../../` block; deps `bandit`/`plug`/`websock`/`websock_adapter`/`jason`, **all already in `mix.lock`**; **no** `{:portal, in_umbrella: true}` / `{:portal_web, in_umbrella: true}`; **no** root `mix.exs` edit). |
| D2 | The **server-authoritative** game model + scoring (`EchoGames.Game`, pure) — the deck builder, flip/match resolution, and the exact scoring ported from `html/game.html` (`BASE_PER_PAIR = 100`, `COMBO_STEP = 25`, `WRONG_PENALTY = 10`, `TIME_BONUS = 5`/s, the three levels `4×3 / 4×4 / 6×4` with their star thresholds and the level-3 12 s reshuffle). A pure function of state + intent (clock-in is boundary-supplied). |
| D3 | The **per-session game server** (`EchoGames.Session`, a `GenServer` per session under a `DynamicSupervisor`) — holds the authoritative state, applies a tap through `EchoGames.Game`, advances levels, runs timers, produces the push state; a session crash isolates. |
| D4 | The **WebSocket protocol** (JSON) — the client sends a card-tap / new-game intent; the server pushes the authoritative state (visible deck, HUD, timer, level/game result). Server-authoritative: the client computes no score, only renders + taps. |
| D5 | The **new isolated games web server** (recommended **option B**) — an `EchoGames.Web.Router` (`Plug.Router`) on a **Bandit** listener on its **own** port (not `:4000`), serving the Vite bundle over an explicit `Plug.Static` mount (verified by a **PROBE** — a `curl` → `200`, not a config-read — the F6.5.5 prefix-strip guard), the WebSocket upgrade, the game-launch landing, and the reserved payment-webhook route. Not `PortalWeb.Endpoint`. |
| D6 | The **Svelte 5 (Runes) + Vite** frontend rewrite of `html/game.html` — a static bundle under `apps/echo_games/priv/static/`; the visual design + Russian copy preserved, the logic moved server-side (renders pushed state, sends taps, computes no score). The Vite build is a build-time Node toolchain outside the BEAM. |
| D7 | The **bot game-launch + payments seam** — a bot gains a command (specced `/play`, re-grounded against F10.2) sending a Telegram **Game** whose URL the games server serves; the games server carries a **reserved** payment-webhook route returning a not-implemented marker. The server-authoritative score (D2/D3/D4) is the paid-game precondition; the full flow is deferred (→ F10.8). |
| D8 | Tests — game-logic unit tests (deck, flip/match, exact scoring + star thresholds vs the `html/game.html` constants); a WebSocket round-trip test (tap in → authoritative-state push out, server-computed); a static-bundle serve check (a `curl` PROBE, the F6.5.5 guard). No Portal contacted. |
| D9 | Verification — boot under `EchoGames.Application` on its own port; the bundle served (probed); a tap yields a server-authoritative push; scoring matches the constants; a bot launches the Game (manual demo); the reserved route returns the marker; a session crash isolates; Portal unchanged, no route/child added to `portal_web`. |

**`[RECONCILE]` rationales** (why / what) — mirrored from the F10.3 triad's
`## [RECONCILE] — forward-looking; re-grounds against F10.1/F10.2 when they ship`. PENDING rows re-ground against the
as-built predecessor (or Operator confirmation); SETTLED rows are fixed by the roadmap:

| Callout | Rationale |
|---|---|
| **Game-launch path — re-ground against F10.2's as-built multi-bot surface (PENDING — F10.2 not built)** | *Why: the launch handler routes through the F10.1 handler/router seam (`EchoBot.Bot` + a bot's handler, `EchoBot.Platform` for the reply send), whose exact signature/arity is an F10.1/F10.2 deliverable not yet built* → when F10.2 ships, re-ground the launch handler against the as-built `EchoBot.Bot` command-routing surface and the `EchoBot.Platform` reply call; until then it is specced as **a new `/play` command sending a Telegram Game**, the integration point pinned but not arity-fixed. The launch belongs to `echo_bot`; `echo_games` only serves + owns the score — the two apps stay **decoupled** (no compile-time dependency). |
| **Games web server — option B confirmed before the triad fixes it (PENDING — Operator confirmation)** | *Why: the roadmap records the games server as **the one open architecture fork** — recommended **B** (a minimal `Plug.Router` on Bandit + `WebSock`/`WebSockAdapter`, own port + supervisor, isolated from `portal_web`) — the Operator confirms before the triad fixes it* → this triad is authored on **B**; if the Operator picks **A** (raw hand-wired Bandit/Plug router) or **C** (a second Phoenix app), D3/D5 and the topology re-derive. (`portal_web` is never a candidate — extending it breaches the no-touch boundary.) |
| **`echo_games` one app vs. an `echo_games_web` split — Operator to confirm at the sharpen (PENDING)** | *Why: the backend + the games web server can live in one app or split into `echo_games` (logic) + `echo_games_web` (the listener), mirroring `portal`/`portal_web`; the roadmap recommends **one app holding both**, splitting only if the web surface grows* → this triad is authored on the **single-app** shape; if the Operator prefers the split, the touched-files list re-partitions across two apps with no change to the game logic or the protocol. |
| **Payments seam opened; full flow deferred — SETTLED by the roadmap (F10.8)** | *Why: F10.3 opens the seam — a server-authoritative score + a **reserved** payment-webhook route — and does not build invoices, the pre-checkout/`successful_payment` updates, or validation; the roadmap places the full flow at F10.8* → **settled, not open**; the reserved route returns a not-implemented marker, exercised only as "the route exists and is isolated", never as a payment. |
| **Portal no-touch — SETTLED by the roadmap (master boundary)** | *Why: neither `echo_games` nor the games web server depends on, modifies, or supervises `portal`/`portal_web`; the games server is a **new** listener, never a `portal_web` route or child (the roadmap's master boundary)* → **settled, not open**; carried as F10.3-INV1 / INV2. |
| **The as-built umbrella deps are already in the lock — SETTLED (verified)** | *Why: `bandit 1.11.1`, `plug 1.19.2`, `websock 0.5.3`, `websock_adapter 0.5.9`, `jason 1.4.5` are already in `mix.lock`* → the games server needs **no new BEAM HTTP/WebSocket dependency**; only the Vite/Svelte **build-time** Node toolchain (outside the BEAM) and the YAML/Telegram deps `echo_bot` already carries are new. Carried as F10.3-INV7. |

**The games web-server fork (the rung's single open architecture decision).** The roadmap's decision matrix weighs three
isolated candidates against six criteria (`portal_web` is **not** a candidate — extending it breaches the no-touch
boundary):

| Option | Shape | Verdict |
|---|---|---|
| **A** | Raw Bandit + WebSock/WebSockAdapter + Plug, hand-wired router | Same stack as B but a hand-rolled router rather than declared routes. |
| **B** | New minimal **`Plug.Router` on Bandit** + WebSock/WebSockAdapter, own port + supervisor | **Recommended** — WebSocket on deps already in the lock, the Vite bundle over an explicit `Plug.Static` mount, direct control of the HTTP surface for the Game-launch URL + the future payment webhook, smallest footprint in the framework-free engine ethos, fully isolated from `portal_web`. |
| **C** | New **Phoenix app** (Channels) | Rejected — duplicates the framework `portal_web` already owns, the heaviest footprint, and two Phoenix apps invite the config/coupling overlap the no-touch boundary exists to prevent. |

**Recommendation: B.** B is preferred over A for the ergonomics of declared routes at no real footprint cost. **This is
an architecture fork — recorded with a recommendation; the Operator confirms it before the F10.3 triad is fixed.** If the
Operator picks A or C, D3/D5 and the topology re-derive.

**Open decisions for the build:** (1) the **games web-server fork** (recommended B) — the Operator confirms; (2) the
**one-app vs `echo_games_web` split** (recommended one app) — the Operator confirms at the sharpen; (3) the **game-launch
path** re-grounded against the as-built `EchoBot.Bot` / `EchoBot.Platform` surface the moment F10.2 ships.

---

## How to use this file

- **Source of truth is the per-rung spec triad**, not this view. When a rung is groomed into the build, its
  `f10.N.{md,stories.md,llms.md}` is updated; this file tracks the *plan + sequencing*, and the `[RECONCILE]` rationales
  are **mirrored from the spec bodies** (re-sync this file if a rung's callout changes).
- Each rung's **open decisions** (the surfaces to ratify, the architecture forks to confirm, the predecessor surfaces to
  re-probe) are the Director's **pre-build agenda** — settle them in Venus's reconcile before Mars builds (the lag-1
  discipline). For F10.2/F10.3 every PENDING callout is a pre-build re-probe against the as-built predecessor, discharged
  the moment that predecessor ships.
- The **games web-server fork** (F10.3, recommended B) and the **`echo_games` app shape** (F10.3, recommended one app)
  are Operator calls recorded with recommendations, not Director decisions — confirmed before the F10.3 triad is fixed.

---

Index: roadmap [`f10.roadmap.md`](f10.roadmap.md) · rung triads [`f10.1.md`](f10.1.md) · [`f10.2.md`](f10.2.md) ·
[`f10.3.md`](f10.3.md) · ship prompt [`f10.1.prompt.md`](f10.1.prompt.md). Approach:
[`../specs.approach.md`](../specs.approach.md).

> Part of the jonnify toolkit. Bots are declared in YAML v1.0 (`version`, `name`, `platform`, `token_env`, `handler`);
> the token is referenced by env-var name and read at boot, never written in the file.
