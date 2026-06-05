# F4.08 — Branded ids & persistence (module hub)

- Route (served): `/elixir/algorithms/persistence`
- File: `elixir/algorithms/persistence/index.html`
- Place in the chapter: Module 8 of F4 · Algorithms & Data Structures, on the persistent-map spine `F4.05 → F4.09` (HAMT → CHAMP → Snowflake/branded ids → persistence → branded-CHAMP owned by a GenServer). F4.07 built the branded id; this module stores it as a key in SQLite, PostgreSQL, and Redis, and shows it validating itself at the edge before any store is touched. The hub frames three dives — `keys`, `sql`, `redis` — and an advanced section on shedding enumeration and DDoS, then hands off to F4.09.
- Accent: sage (F4 chapter accent); the persistence module also threads blue and gold per-dive left-borders.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4 · Persistent maps · module 8`

Hero h1: Branded ids & `persistence` (the word `persistence` is the italic `.ex` accent span).

Lede (verbatim): "F4.07 built the id; this module stores it. The 64-bit Snowflake is a `bigint` primary key in SQLite and PostgreSQL and a namespaced string key in Redis — compact, sortable, and time-ordered everywhere. But the property that earns its keep arrives *before* any store is touched: a branded id **validates itself**. A request for a malformed or time-impossible id can be answered with a `404` in constant time, with zero I/O."

Kicker (verbatim): "Take a request like `GET /user/profile/USR0NbWMtkosp8`. The edge checks the id's shape and timestamp first; only a well-formed `USR` id from a plausible moment reaches the database. Select a request and watch the gate decide."

## What the page frames

The hub is not a `.mods` grid; the three dives are full-width card links inside the `#dives` section, each with a colored left-border:

- F4.08.1 — Branded ids as keys — "Store the 64-bit integer, index it, and brand it only at the edge: eight bytes that sort by time and validate themselves." — route `/elixir/algorithms/persistence/keys` — left-border sage — built.
- F4.08.2 — SQLite & PostgreSQL — "A `bigint` column and a time-range query expressed as `id BETWEEN min AND max`, no timestamp column needed." — route `/elixir/algorithms/persistence/sql` — left-border blue — built.
- F4.08.3 — Redis keys — "Namespaced string keys, and an edge validator that sheds malformed and impossible ids before they reach the cache." — route `/elixir/algorithms/persistence/redis` — left-border gold — built.

In-page teaching sections, in order: `#validate` "Validate before you query" (the four no-I/O checks: length is exactly fourteen, payload is base62, decoded integer in 64-bit range, namespace matches and timestamp not in the future); `#dives` "Three deep dives"; `#advanced` "Advanced: shedding enumeration & DDoS" (enumeration / IDOR probe vs. flooding, the honest boundary that validation proves well-formed-and-plausibly-timed not existence, plus a `Portal.Id.validate/2` Plug code block). The hero carries an interactive `%User{}` struct → row figure; `#validate` carries the request-validator figure.

## The interactives

### Hero figure — "Struct → row · the id is the key"
- `<figure class="hero-fig">` labelled by `#hpTitle` ("Struct → row · the id is the key").
- Controls (`.hp-ctrls`): button `#hpPersist` ("▸ persist"), button `#hpLoad` ("load").
- SVG element ids: `#hpArrows`, `#hpRow`, per-column value texts `.hp-v-id` / `.hp-v-name` / `.hp-v-email` / `.hp-v-role`, state strip `#hpState`, SQL line `#hpSql`; caption `#hpCap`.
- Running data (`COLS`): `id: USR0NbWMtkosp8` (gold, PK), `name: "Ada"` (sage), `email: "ada@x.io"` (sage), `role: :admin` (elixir). Stored constant `ID = 'USR0NbWMtkosp8'`.
- Behaviour: `persist` sets `written = true` and `render()` fills each `.hp-v-*` cell, lights the id cell border sage as the primary key; `load` sets `written = false` and returns to the in-memory view.
- Readout strings VERBATIM:
  - Empty `#hpState`: "row not yet written · the id will be its primary key"; empty `#hpSql`: "INSERT INTO users (id, name, email, role) VALUES (…)".
  - Written `#hpState`: "row written · id USR0NbWMtkosp8 is the primary key"; written `#hpSql`: `INSERT INTO users (id, name, email, role) VALUES (USR0NbWMtkosp8, "Ada", "ada@x.io", "admin")`.
  - Empty caption `#hpCap`: "`%User{}` in memory · the row is empty." / "persist maps each field to its column — the branded id becomes the primary key."
  - Written caption `#hpCap`: "`%User{}` persisted · each field sits in its column." / "the branded id is the row's primary key — sortable and self-validating."
- Degrade: the static SVG ships with empty `—` cells and the "row not yet written" state; the `.hp-fill` cell animation is gated `@media (prefers-reduced-motion: no-preference)` and disabled under reduce. `render()` only syncs button disabled-state at load.

### `#validate` figure — "Incoming request · select one"
- `<figure class="fig">` labelled by `#peTitle` ("Incoming request · select one").
- Control group `#peSel` (`.solid-select`, role group "Incoming request"), buttons:
  - `data-k="ok"` `data-c="sage"` (active) — "valid USR id"
  - `data-k="type"` `data-c="gold"` — "wrong type"
  - `data-k="len"` `data-c="gold"` — "malformed"
  - `data-k="range"` `data-c="gold"` — "impossible"
- SVG element ids: request text `#peReq`, output box `#peOutBox`, output text `#peOut`, caption `#peCaption`. Below the SVG: code `#peCode`, readout `#peReadout`, verdict `#peRole`, cost `#peResult`.
- Request set (`REQ`): `ok → USR0NbWMtkosp8`, `type → TSK0KHTOWnGLuC`, `len → USR0NbWM`, `range → USRzzzzzzzzzzz`.
- Pure function `validate(pathId, expectedNs)`: runs four no-I/O checks (length === 14; payload base62; `snow > MAX64` → impossible; `ns !== expectedNs` → wrong type; timestamp `> Date.now() + 60000` → future) and returns `{ok, snow, time}` or `{ok:false, why}`. Constants: `B62` alphabet, `EPOCH_MS = 1704067200000`, `MAX64 = 18446744073709551615n`.
- Readout strings VERBATIM:
  - Valid `#peOut`: "200 · forward to store"; invalid `#peOut`: "404 · rejected, no I/O".
  - Valid `#peCaption`: "a well-formed USR id is forwarded to the store"; invalid `#peCaption`: the `v.why` reason.
  - `why` reasons (verbatim): "malformed — length is not 14", "malformed — not base62", "impossible — exceeds 64-bit range", "wrong type — expected USR", "impossible — timestamp in the future".
  - `#peRole`: "valid — forward" (or the `v.why`); `#peResult`: "one decode, then a lookup" (valid) / "one decode, zero I/O" (invalid).
  - Valid `#peReadout`: "A valid `USR` id. The decode also hands back the creation time — **<time>** — with no `created_at` column and no query. One lookup now confirms the record exists."
  - Invalid `#peReadout`: "Rejected at the edge: **<why>**. The request is answered `404` in constant time, so a flood of ids like this costs the database nothing."
- Take (verbatim): "A malformed or impossible id is rejected for the price of a shift and a comparison. The store only ever sees ids that could exist — and for those, the id already says when they were made."

### Footer build-stamp
- `.stamp#stamp` decodes `#stampId` = `TSK0NcaQMWseDg`. `decodeBranded` splits ns `TSK` + base62 payload, shifts `snow >> 22n` for the timestamp, `(snow >> 12n) & 0x3FFn` for node, `snow & 0xFFFn` for seq. Static fallback `#st-ts` reads `2026-06-01 10:04:21 UTC`; click/Enter/Space toggles the decode panel.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://www.sqlite.org/datatype3.html` — "SQLite — Datatypes — storing a 64-bit id in an INTEGER column."
- `https://www.postgresql.org/docs/current/datatype-numeric.html` — "PostgreSQL — Numeric Types — the `bigint` column for a Snowflake."
- `https://redis.io/docs/latest/develop/use/keyspace/` — "Redis — Keys & key space — namespaced string keys."
- `https://owasp.org/www-project-top-ten/2017/A5_2017-Broken_Access_Control` — "OWASP — Broken Access Control (IDOR) — the enumeration risk sparse ids reduce."

Related in this course:
- `/elixir/algorithms/identifiers` — "F4.07 · Identifiers, Snowflake & branded ids — the id this module stores."
- `/elixir/algorithms/maps` — "F4.04 · Maps, sets & hashing — the registry keyed by these ids."
- `/elixir/algorithms/champ` — "F4.06 · CHAMP maps — the in-memory map F4.09 keys on them."
- `/elixir/algorithms` — "F4 · Algorithms & Data Structures"

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / persistence` — segments `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, current `persistence` in `.rcur`.
- crumbs (verbatim): `F4 · Algorithms & Data Structures` (→ `/elixir/algorithms`) / `F4.08 · persistence` (`.here`).
- toc-mini: `#validate` "Validate before you query"; `#dives` "Three deep dives"; `#advanced` "Advanced: shedding enumeration & DDoS".
- pager: prev → `/elixir/algorithms/identifiers` "F4.07 · identifiers"; next → `/elixir/algorithms/persistence/keys` "Start · branded ids as keys".
- footer: column "Chapters" — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: "Branded ids & persistence — F4.08 · jonnify". `<meta description>`: "A branded Snowflake is the key everywhere the portal stores data: a 64-bit bigint primary key in SQLite and PostgreSQL, a namespaced string key in Redis. Its decisive property arrives before any store is touched — the id validates itself, so a request for a malformed or time-impossible id (GET /user/profile/USR0NbWMtkosp8) is answered 404 in constant time with zero I/O, shedding the enumeration and flooding traffic that targets a database."

## Build instruction

To rebuild this hub, copy the `head`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the F4 sage accent — the model sibling is `elixir/algorithms/identifiers/index.html` (F4.07, the predecessor hub on the same persistent-map spine). Change only the `<title>`/`<meta description>`, the header `route-tag`, and the `<main>` body (the hero struct→row figure, the `#validate` request-validator figure, the three dive cards, and the advanced Plug block). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — so reference `Portal.Id.validate/2` and `Portal.Id.brand/2` exactly, and the bound helpers `EchoData.Snowflake.min_for_time/1` / `max_for_time/1` only as the dives do; cite the companion course for OTP internals and do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
