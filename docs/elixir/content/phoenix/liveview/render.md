# F6.06.3 — render & diffs (dive)

- Route (served): `/elixir/phoenix/liveview/render`
- File: `elixir/phoenix/liveview/render.html`
- Place in the chapter: the third and last of the F6.06 (LiveView) deep dives. It closes the lifecycle loop opened by `mount` and `events`: how `render/1` projects assigns into HEEx, how change tracking on the static/dynamic split produces a minimal diff, and how streams keep large collections out of socket memory. It is the final piece of the "make it live" arc; the next module is F6.07 (PubSub).
- Accent: blue (F6 · Phoenix; `<h1 .ex>` word "diffs" in `--elixir-bright`).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F6.06 · part 3 of 3`

`<h1>` (verbatim): render & `diffs` (the word "diffs" is the `.ex` accent span).

Hero lede (`.lede`, verbatim):

> A LiveView re-renders on every change, yet stays cheap, because a HEEx template is split in two: fixed **static** markup and interpolated **dynamic** holes. Only the dynamic values that actually changed travel the socket — the diff is the minimal delta of the rendered state since the last render.

Kicker (`.kicker`, verbatim):

> First the split that makes change tracking possible, then a worked diff computed for real, then `render/1` in Elixir with its diffs annotated, and finally streams — for collections too large to keep in socket assigns.

## Sections

Teaching sections in order:

1. `#split` — "The static / dynamic split". Prose + a `.deflist` defining `static`, `dynamic`, `change tracking`, and `diff`.
2. `#diff` — "A diff, computed". Carries the page's interactive figure.
3. `#code` — "render/1 in Elixir". A `pre.code` of `render(assigns)` returning HEEx, with the two holes annotated.
4. `#streams` — "Streams for big lists". A `pre.code` showing `stream/3` and `stream_insert/3`, plus a `.bridge` (F5 OTP → a diff).
5. `#recap` — "What this lands". A `<ul>` recap and the closing `.note` completing F6.06.

Running example: a catalog view with two holes — `{@count}` at position `0` and `{course.title}` at position `1` — used to compute which holes re-send.

Real Elixir code shown:
- `render/1` block — `def render(assigns) do ~H""" <h1>Courses ({@count})</h1> <%!-- hole [0] --%> <ul> <li :for={course <- @courses}>{course.title}</li> <%!-- hole [1] --%> </ul> """ end`; closing comments `# an event re-runs render/1; the diff is the changed holes only:`, `# @count 41 -> 42, @courses same # => %{"0" => "42"}`, `# @courses gains a row, @count same # => %{"1" => [...]} (shell never re-sent)`.
- Streams block — `def mount(_params, _session, socket) do {:ok, stream(socket, :courses, Portal.list_courses())} end`; `def handle_event("add", %{"course" => params}, socket)` with `{:ok, course} = Portal.create_course(params)` and `{:noreply, stream_insert(socket, :courses, course)} # one row, not the whole list`; the template `<ul id="courses" phx-update="stream"> <li :for={{dom_id, course} <- @streams.courses} id={dom_id}>{course.title}</li> </ul>`.

## The interactives

### Figure — "The diff over the socket · choose what changed" (`#dfSel` + `#dfOut`)

- `<figure class="fig" aria-labelledby="dfTitle">`; `<h4 id="dfTitle">` text "The diff over the socket · choose what changed".
- Control group `.solid-select#dfSel` (role="group"), four buttons, each `data-c="sage"`: `count` (label "@count ticks", starts `active`), `courses` (label "@courses changes"), `both` (label "both change"), `none` (label "nothing changes").
- SVG element ids: static shell `#dfShell`; hole-0 box `#dfBox0` with value `#df0val` and tag `#df0tag`; hole-1 box `#dfBox1` with value `#df1val` and tag `#df1tag`; payload `#dfPayload`; note `#dfNote`. Below the SVG: a live `pre.code#dfCode`, the readout `.geo-readout#dfOut`, and a holes-re-sent count `#dfCount` (default `1 of 2`).
- Pure functions: `searchCourses`-style helpers `payloadMap(c)` builds the `%{...}` diff string from which holes changed; `render(k)` toggles the active button, recolors both hole boxes/tags (sage when re-sent, blue/dim when unchanged), writes `#dfPayload`/`#dfNote`/`#dfCount`, rebuilds `#dfCode`, and writes `#dfOut`; `esc(s)` HTML-escapes. Hole data: `H0 = {old:'41', neu:'42', label:'{@count}', short:'"42"'}`, `H1 = {old:'list', neu:'list + 1 row', label:'{course.title} list', short:'[...]'}`. Wired on each button's `click`; initial call `render('count')`.
- `CASES` data (`h0` / `h1` / `title`, verbatim titles):
  - count: h0 true, h1 false — title "@count 41 -> 42, @courses unchanged".
  - courses: h0 false, h1 true — title "@courses gains a row, @count unchanged".
  - both: h0 true, h1 true — title "@count ticks and @courses gains a row".
  - none: h0 false, h1 false — title "an event fires but no assign changed".
- Readout / note strings (verbatim): `#dfNote` when something changed "only changed holes are sent; the shell and unchanged holes are skipped", when nothing changed "no hole changed; the diff is empty and nothing is sent". `#dfCode` empty-case suffix "# empty: socket stays silent". Static `#dfPayload` default `%{"0" => "42"}`; static `#dfCode` default comments `# @count 41 -> 42, @courses unchanged` / `# diff over the socket:` / `%{"0" => "42"}`.
- Degrade: the correct static state (case `count`, 1 of 2 holes re-sent) is in the markup; `render('count')` on load only confirms it. No browser storage; `prefers-reduced-motion` respected globally.

### Footer build-stamp decoder (`#stamp`)

- Stamp id `TSK0NdUKuboO3c` (in `#stampId`); panel `#st-ts` hard-codes "2026-06-01 23:06:46 UTC".
- Decoded: `ns=TSK`, `snowflake=319975090986942464`, `node=0`, `seq=0`, timestamp `2026-06-01 23:06:46 UTC` (epoch `EPOCH_MS = 1704067200000`).
- Functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`). Toggle on click / Enter / Space sets `.open` and `aria-expanded`.

## References (#refs, verbatim)

Intro line: "How render, change tracking, and streams are specified."

Sources
- `https://hexdocs.pm/phoenix_live_view/assigns-eex.html` — Phoenix LiveView — Assigns & change tracking — the static / dynamic split and how diffs are computed.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#sigil_H/2` — Phoenix.Component — `~H` — the HEEx sigil that `render/1` returns.
- `https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#stream/4` — Phoenix.LiveView — `stream/3` — collections held in the DOM, not in assigns.

Related in this course
- `/elixir/phoenix/liveview/mount` — F6.06.1 · mount & assigns
- `/elixir/phoenix/liveview/events` — F6.06.2 · handle_event & state
- `/elixir/phoenix/heex` — F6.05 · Templates, components & HEEx — the template this renders.
- `/elixir/phoenix/liveview` — F6.06 · Phoenix LiveView fundamentals
- `/elixir/phoenix` — F6 · Phoenix Framework

## Wiring

- route-tag (verbatim, segmented): `/` `elixir` `/` `phoenix` `/` `liveview` `/` `render` (the `render` segment is the current `.rcur`; `elixir`, `phoenix`, `liveview` are links).
- crumbs (verbatim): `F6` → `/elixir/phoenix` · sep `/` · `F6.06` → `/elixir/phoenix/liveview` · sep `/` · here `render` (no link).
- toc-mini: `#split` ("The static / dynamic split") · `#diff` ("A diff, computed") · `#code` ("render/1 in Elixir") · `#streams` ("Streams for big lists") · `#recap` ("What this lands").
- pager: prev → `/elixir/phoenix/liveview/events` ("← F6.06.2 · handle_event & state"); next → `/elixir/phoenix` ("F6 · Phoenix Framework →").
- footer (`.foot-nav`, three columns):
  - brand: `.foot-logo` → `/elixir`; `.foot-tag` "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
  - Chapters: `/elixir/algebra`, `/elixir/functional`, `/elixir/language`, `/elixir/algorithms`, `/elixir/pragmatic`, `/elixir/phoenix` (F1–F6, same labels as the hub).
  - The course: `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01).
- Page meta: `<title>` "render & diffs — F6.06.3 · jonnify"; `<meta description>` "render/1 returns HEEx from the assigns, and LiveView tracks which assigns changed to send only those values over the socket. A HEEx template compiles into static segments and dynamic holes, so the diff is the minimal delta of the rendered state since the last render; streams keep large, append-only collections out of socket memory."

## Build instruction

To rebuild this page, copy the `<head>`…`</style>`, `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT F6 (blue-accent) dive, then change only the `<title>`/`<meta description>`, the segmented `.route-tag`, and the `<main>` body. The model sibling is `/elixir/phoenix/liveview/events` (`elixir/phoenix/liveview/events.html`) — the same lesson-hero `.lede`/`.kicker`, the same blue accent, the same `.solid-select`/`.geo-readout`/`pre.code` shells, and the same deeper-standard section anatomy (note this dive's interactive uses `data-c="sage"` on its `#dfSel` buttons, so keep the `.solid-select button.active[data-c="sage"]` rule). No-invent guards: use only the real Portal surfaces as written — `Portal.list_courses/0`, `Portal.create_course/1`, the `~H` sigil, `render/1`, `stream/3`/`stream_insert/3`, `phx-update="stream"`, `@streams`, and the static/dynamic change-tracking model — over the branded store / one-facade / event-sourced engine; the diff payloads `%{"0" => "42"}` / `%{"1" => [...]}` are illustrative of the closed render contract, not new API. Cite the F5 companion for OTP "minimal delta on every change" internals rather than re-teaching them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
