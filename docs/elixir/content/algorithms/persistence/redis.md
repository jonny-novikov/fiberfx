# F4.08.3 — Redis keys (dive)

- Route (served): `/elixir/algorithms/persistence/redis`
- File: `elixir/algorithms/persistence/redis.html`
- Place in the chapter: Part 3 of 3 of the F4.08 persistence module, the closing dive. It follows `keys` (the stored integer) and `sql` (the time-range query) and completes F4.08: the branded id as a namespaced cache key plus an edge validator that sheds traffic that cannot exist. Its pager hands off to F4.09 — Branded CHAMP maps & GenServer.
- Accent: sage (F4 chapter accent); the dive uses sage / gold (and burgundy for shed rows) across the two edge modes.
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F4.08 · part 3 of 3`

Hero h1: Redis `keys` (the word `keys` is the italic `.ex` accent span).

Lede (verbatim): "In Redis the id is a string key, namespaced with a colon: `user:USR0NbWMtkosp8`. The namespace keeps key spaces apart and makes a scan or an eviction policy easy to scope. The same self-validating id pays off harder here than anywhere: a cache exists to absorb load, so the cheapest win is to reject the load that should never reach it. A malformed or impossible id is a `404` at the edge — no `GET`, no fallback query."

Kicker (verbatim): "A burst of eight requests, some real and some the kind a scanner sends. Compare an edge that validates first with one that forwards everything. Select a mode."

## Sections

- `#shed` "Validate, then reach the cache" (teaching) — the same eight requests, two edges; with validation only well-formed, plausibly-timed `USR` ids become a cache lookup; without it every request becomes a `GET` and the impossible ones miss and fall through to the database. Carries the interactive edge-mode figure and a take.
- `#advanced` "Advanced: the keyspace and the honest limit" — the key is the branded id under a type namespace (`user:…`, `session:SES…`), so one instance holds several record kinds without collision and a colon prefix scopes a `SCAN` or per-type eviction; the validating plug runs before the Redix call; the honest limit is that validation proves well-formed-and-plausibly-timed, not existence — a correctly-shaped but never-issued id still costs one lookup and a miss falls through to one query. Carries a `with`-pipeline controller code block and a bridge.

Running example: eight incoming requests (three real `USR` ids, five the shape a scanner sends) routed through Redis with and without edge validation.

Real Elixir code shown (`#advanced`, verbatim):
```
# validate at the edge; only then touch Redis, only then the DB
def profile(conn, %{"id" => id}) do
  with {:ok, _snow} <- Portal.Id.validate(id, :USR),         # no I/O
       {:ok, json} <- Redix.command(["GET", "user:" <> id]) do
    json(conn, json)                                          # cache hit
  else
    {:error, _} -> send_resp(conn, 404, "")              # malformed id: shed
    {:ok, nil}    -> load_from_db_and_cache(conn, id)        # well-formed miss
  end
end
```

## The interactives

### `#shed` figure — "Edge mode · select one"
- `<figure class="fig">` labelled by `#reTitle` ("Edge mode · select one").
- Control group `#reSel` (`.solid-select`, role group "Edge mode"), buttons:
  - `data-k="validate"` `data-c="sage"` (active) — "validate at edge"
  - `data-k="passthrough"` `data-c="gold"` — "forward everything"
- SVG element ids: rows group `#reRows` (eight rows built once, each `#reBox<i>` + `#reTag<i>`), summary `#reSummary`. Below: code `#reCode`, readout `#reOut`, edge role `#reRole`, load-on-store `#reResult`.
- Pure function `validate(pathId, expectedNs)` — same validator as the hub: length === 14, payload base62, `snow > MAX64`, namespace match, future-timestamp check (`> Date.now() + 60000`); returns `{ok, snow}` or `{ok:false, why}` with `why` in `{length, base62, range, type, future}`. Constants `B62`, `EPOCH_MS = 1704067200000`, `MAX64 = 18446744073709551615n`.
- Request burst (`REQ`, eight ids): `USR0NbWMtkosp8`, `USR0NbLeJJpTmr`, `USR0NXh7MFjxT6` (three valid), then `TSK0KHTOWnGLuC`, `USR0NbWM`, `USRzzzzzzzzzzz`, `USR0NbWM*kosp8`, `usr0NbWMtkosp8` (five shed). `nValid = 3`, `nShed = 5`.
- Per-row tag strings VERBATIM: validate mode — valid "→ cache GET", invalid "404 · <reason> (no I/O)"; passthrough mode — valid "→ cache hit", invalid "→ cache miss → DB query". `WHY` reason map: `length → "malformed length"`, `base62 → "not base62"`, `range → "out of range"`, `type → "wrong type"`, `future → "future"`.
- Summary `#reSummary` VERBATIM: validate "3 of 8 reach the cache · 5 shed at the edge (0 I/O)"; passthrough "8 cache lookups · 5 DB queries for ids that cannot exist".
- `#reRole`: "validates before the cache" / "forwards everything". `#reResult`: "3 cache lookups" (validate) / "8 lookups + 5 DB reads" (passthrough).
- Readout `#reOut` VERBATIM:
  - validate: "With validation, **3 of 8** requests reach Redis; the other **5** are answered `404` for the cost of a decode. The cache and the database see none of the scanner traffic."
  - passthrough: "Forwarding everything, all **8** become a cache `GET`; the **5** that cannot exist miss and fall through to a database query. The store pays for traffic an edge check would have shed."
- Static SVG default: `#reSummary` ships with "3 of 8 reach the cache · 5 shed at the edge (0 I/O)" matching the `validate` case picked on load; the eight rows are built and tagged by JS (the static markup ships an empty `#reRows`, so without JS the rows are unfilled — figure degrades to the summary strip and prose). No figure animation beyond the shared reveal-on-scroll.
- Take (verbatim): "A cache absorbs load best when it never sees the load it should not. Validating the id at the edge turns a scanner's flood into constant-time 404s and leaves the cache for requests that could be real."

### Footer build-stamp
- `.stamp#stamp` decodes `#stampId` = `TSK0NcaQNZJakK` via `decodeBranded` (ns + `snow >> 22n` timestamp, `(snow >> 12n) & 0x3FFn` node, `snow & 0xFFFn` seq). Static fallback `#st-ts` reads `2026-06-01 10:04:21 UTC`; click/Enter/Space toggles the panel.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://redis.io/docs/latest/develop/use/keyspace/` — "Redis — Keys & key space — namespaced string keys and key conventions."
- `https://hexdocs.pm/redix/Redix.html` — "Redix — the Elixir Redis client used at the edge."
- `https://owasp.org/www-project-top-ten/2017/A5_2017-Broken_Access_Control` — "OWASP — Broken Access Control (IDOR) — the enumeration class this shedding narrows."

Related in this course:
- `/elixir/algorithms/persistence` — "F4.08 · Branded ids & persistence — the module hub and its request validator."
- `/elixir/algorithms/identifiers` — "F4.07 · Identifiers, Snowflake & branded ids — why the id is self-describing."
- `/elixir/algorithms` — "F4 · Algorithms & Data Structures"

## Wiring

- route-tag (verbatim): `/ elixir / algorithms / persistence / redis` — segments `elixir` → `/elixir`, `algorithms` → `/elixir/algorithms`, `persistence` → `/elixir/algorithms/persistence`, current `redis` in `.rcur`.
- crumbs (verbatim): `F4` (→ `/elixir/algorithms`) / `F4.08` (→ `/elixir/algorithms/persistence`) / `redis` (`.here`).
- toc-mini: `#shed` "Validate, then reach the cache"; `#advanced` "Advanced: the keyspace and the honest limit".
- pager: prev → `/elixir/algorithms/persistence/sql` "F4.08.2 · sql"; next → `/elixir/algorithms` "F4 · Algorithms & Data Structures".
- footer: column "Chapters" — `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework). Column "The course" — `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01). Foot tag: "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta — `<title>`: "Redis keys — F4.08.3 · jonnify". `<meta description>`: "In Redis the id is a namespaced string key, user:USR0NbWMtkosp8. The self-validating id pays off hardest at a cache: an edge validator rejects malformed, out-of-range, wrong-namespace, and future ids with a 404 before a GET or a database fallback, so a scanner's flood becomes constant-time rejects. The honest limit is that a well-formed but absent id still costs one lookup."

## Build instruction

To rebuild this dive, copy the `head`…`</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on the F4 sage accent — the model sibling is the companion dive `elixir/algorithms/persistence/keys.html` (same module, same `.solid-select` shell and footer stamp). Change only the `<title>`/`<meta description>`, the header `route-tag`, the crumbs, and the `<main>` body (the `#shed` edge-mode figure plus its eight-request `REQ` burst and shared `validate` function, and the `#advanced` `with`-pipeline controller block and bridge). No-invent guards: use only the real Portal surfaces as written — the branded store, the event-sourced engine behind ONE `Portal` facade, the Phoenix web app — so reference `Portal.Id.validate/2` and `Redix.command/1` exactly, and keep the key form `user:<id>`; cite the companion course for OTP internals, do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
