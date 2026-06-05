# F6.08.1 — Sessions & authentication (dive)

- **Route (served):** `/elixir/phoenix/deployment/auth`
- **File:** `elixir/phoenix/deployment/auth.html`
- **Place in the chapter:** the first of the three F6.08 dives (part 1 of 3). It teaches generated authentication — `mix phx.gen.auth`, the signed-cookie session, the `fetch_current_user` plug, and `on_mount` for LiveView — before `releases` packages the app and `deploy` ships it. Belongs to the M3 "ship to users" arc.
- **Accent:** chapter accent blue (`--blue`); the `.ex` h1 span renders in `--elixir-bright` lilac; the `.dive-tag` shell is lilac per the shared design system.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.08 · part 1 of 3`.

Hero `h1` (verbatim): `Sessions & authentication` (the `.ex` accent span wraps `authentication`).

Hero lede (`.lede`, verbatim): "Authentication in Phoenix is not a framework you bolt on — it is mostly code you generate and then own. `mix phx.gen.auth Accounts User users` writes an **Accounts context** (exactly the F6.04 shape), a `User` schema with a hashed-password field, a token schema, the registration and login LiveViews and controllers, and the session plumbing — then you read it, run its migration, and adjust it like any other code. Three pieces carry the weight. The **session** is a signed cookie: on login the app verifies the password with bcrypt and stores a *token* in the cookie, not the password and not the user struct. A **plug**, `fetch_current_user`, runs in the browser pipeline on every request, reads that token, and puts `current_user` into `conn.assigns` so controllers and templates can see it. And because a LiveView holds a long-lived socket rather than a request, it enforces auth with **`on_mount`** — a hook that runs before the socket connects and can halt and redirect. Password hashing, CSRF, and token expiry come built in; what you decide is which routes require a user."

Kicker (`.kicker`, verbatim): "Four parts: the three moving pieces, the login flow end to end, protecting routes in the router, and enforcing auth in a LiveView with `on_mount`."

## Sections

Four teaching sections in order:

1. **`#what` — Session, plug, on_mount** — the three moving pieces, with the interactive `#auSel` selector.
2. **`#flow` — The login flow** — login once (submit → verify with bcrypt → token in cookie) plus every later request (cookie → `fetch_current_user` plug → `conn.assigns.current_user`), with the `#auFlowTitle` flow diagram.
3. **`#router` — Protecting routes** — `fetch_current_user` in the `:browser` pipeline, `require_authenticated_user` for protected scopes; a `pre.code` Elixir block.
4. **`#live` — Enforcing it in LiveView** — `on_mount` under a `live_session`; a `pre.code` Elixir block, a `.bridge` (requests → sockets), and the `.note` forward to `releases`.

**Running example:** the Portal's `PortalWeb` web app — `mix phx.gen.auth Accounts User users`, the `:browser` pipeline, a `:require_authenticated_user` plug, `PortalWeb.UserAuth.on_mount/4`, and the protected `CatalogLive`.

**Real Elixir shown (`pre.code`, verbatim tokens):**
- Router (`#router`): `pipeline :browser do … plug :fetch_session; plug :fetch_current_user end`, then `scope "/", PortalWeb do pipe_through [:browser, :require_authenticated_user]; live "/catalog", CatalogLive end`.
- LiveView (`#live`): `live_session :authenticated, on_mount: [{PortalWeb.UserAuth, :ensure_authenticated}] do live "/catalog", CatalogLive end`, and `def on_mount(:ensure_authenticated, _params, session, socket)` calling `mount_current_user(socket, session)`, returning `{:cont, socket}` or `{:halt, redirect(socket, to: ~p"/users/log_in")}`.

## The interactives

### Section figure — "Authentication · select one" (`#auTitle`)

- **Figure:** `<figure class="fig" aria-labelledby="auTitle">` in `#what`; `.solid-select#auSel` (role group "Auth piece").
- **Control buttons (data-k / label):** `session` ("the session", starts `active`) · `plug` ("a plug") · `onmount` ("on_mount"). Buttons carry no `data-c`.
- **SVG rect ids:** `#auRow_session`, `#auRow_plug`, `#auRow_onmount`.
- **Readouts:** `#auOut` (`.geo-readout`, `aria-live`), plus `#auRole` (default "the session") and `#auResult` (default "a signed cookie with a token").
- **Pure function:** `pick(k)` — over `ORDER = ['session','plug','onmount']` toggles each button's `active`/`aria-pressed` by `data-k === k`, sets each `#auRow_*` rect on/off, writes `PARTS[k].name` into `#auRole`, `PARTS[k].is` into `#auResult`, and `'<b>'+name+'</b> — '+is+'. '+desc` into `#auOut`. Initial call `pick('session')`.
- **`PARTS` readout dataset (`name` / `is` / `desc`, verbatim):**
  - session: name "the session", is "a signed cookie with a token", desc "On login the app verifies the password with bcrypt and stores a token in a signed cookie — not the password, not the user struct. The token can be invalidated server-side."
  - plug: name "a plug", is "loads current_user into assigns", desc "fetch_current_user runs in the :browser pipeline on every request, reads the token from the cookie, and puts current_user into conn.assigns so controllers and templates can see it."
  - onmount: name "on_mount", is "enforces auth in a LiveView", desc "A LiveView holds a socket, not a request, so it enforces auth with on_mount — a hook that loads the user from the session and returns {:cont, socket} or {:halt, redirect(...)} before connecting."

### Section figure — "log in → token in cookie → plug loads the user" (`#auFlowTitle`)

A static (no-control) two-column flow in `#flow`: `<figure class="fig" aria-labelledby="auFlowTitle">` showing LOGIN (once) — "submit email + password" → "Accounts: verify password (bcrypt)" → "put token in the session cookie" — and EVERY LATER REQUEST — "request carries the cookie" → "plug: fetch_current_user" → "conn.assigns.current_user is set", joined with the note "the token, written once, identifies the user on every request that follows". No buttons; informational only.

### Degrade behaviour

The `#auSel` figure ships its controls, SVG, and the default `#auOut`/`#auRole`/`#auResult` values in static markup; JS only enhances (`pick('session')` re-applies the default). The flow figure is fully static. Animations respect `prefers-reduced-motion: reduce`; no browser storage. There is no References block on this dive (the module References live on the hub).

### Footer build-stamp decoder (`#stamp`)

- **Stamp id (`#stampId`):** `TSK0NdZT1FE77I`; the static `#st-ts` reads "2026-06-02 00:18:34 UTC".
- **Pure functions:** `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` — `ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`, `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`, epoch `EPOCH_MS = 1704067200000`, formatting into `#st-ns`/`#st-snow`/`#st-node`/`#st-seq`/`#st-ts`; toggle on click / Enter / Space. Decoding `TSK0NdZT1FE77I` yields the `2026-06-02 00:18:34 UTC` timestamp shown.

## References

This dive carries no `#refs` section. The F6.08 module References (Sources + "Related in this course") live on the hub at `/elixir/phoenix/deployment`. Note rather than fabricate: there is no per-dive References block here.

## Wiring

- **route-tag:** `<span class="rsep">/</span>elixir / phoenix / deployment / <span class="rcur">auth</span>` — segmented, `elixir`/`phoenix`/`deployment` linked, `auth` the current span; matches `/elixir/phoenix/deployment/auth`.
- **crumbs:** `F6` → `/elixir/phoenix` · sep `/` · `F6.08` → `/elixir/phoenix/deployment` · sep `/` · here `auth` (no link).
- **toc-mini:** `#what` ("Session, plug, on_mount") · `#flow` ("The login flow") · `#router` ("Protecting routes") · `#live` ("Enforcing it in LiveView").
- **pager:** prev → `/elixir/phoenix/deployment` ("← F6.08 · overview"); next → `/elixir/phoenix/deployment/releases` ("Next · releases & config →").
- **footer (`foot-nav`, 3-column):** identical to the hub — brand `.foot-logo` → `/elixir` with the "Functional Programming in Elixir…" `.foot-tag`; Chapters column `/elixir/algebra`…`/elixir/phoenix` (F1–F6); The course column `/elixir`, `/elixir/course`, `/elixir/algebra/functions` ("Start · F1.01").
- **Page meta:** `<title>` "Sessions & authentication — F6.08.1 · jonnify"; `<meta description>` "mix phx.gen.auth generates an Accounts context, a User schema, and the session plumbing. The session is a signed cookie carrying a token; a plug loads the current user into conn.assigns, and a LiveView enforces auth with on_mount before the socket connects — authentication is just another context plus standard plugs."

## Build instruction

To rebuild this dive, copy the `<head>`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and both trailing `<script>` blocks verbatim from a recent built F6 (blue-accent) dive sibling; change only `<title>`/`<meta>`, the segmented `.route-tag` (`auth` current), and the `<main>` body (hero, the four `#what`/`#flow`/`#router`/`#live` sections, the two figures, the two `pre.code` blocks, the `.bridge`, and the pager). No-invent guards: use only the real Portal surfaces as written — `mix phx.gen.auth`, the generated `Accounts` context, the `:browser` / `:require_authenticated_user` pipelines, `fetch_current_user`, `PortalWeb.UserAuth.on_mount/4`, `~p"/users/log_in"`, `CatalogLive`; the web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set, and never names `Portal.Engine`, a repo, or `GenServer.call`. Cite the companion course for OTP internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of "just"/"simply"/"obviously". Model sibling to copy from: `elixir/phoenix/deployment/releases.html` (the next dive in this module).
