# F3.06.2 — Implementing for a struct (dive)

- Route (served): `/elixir/language/protocols/defimpl`
- File: `elixir/language/protocols/defimpl.html`
- Place in the chapter: the second of the three F3.06 dives, part 2 of 3. It is the "how" page — `defimpl Protocol, for: Struct` writes the per-type bodies that a call resolves to, forming a dispatch table that grows by addition. It follows F3.06.1 (`define`) and precedes F3.06.3 (`behaviours`).
- Accent: `elixir` (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.06 · part 2 of 3`

H1: Implementing for a struct

Hero lede (verbatim):

> `defimpl Protocol, for: Struct` gives the bodies a call resolves to. Each type has its own block, and together they form a dispatch table the runtime indexes by the value's type. The protocol stays a list of signatures; the implementations carry the work.

Kicker (verbatim):

> The portal implements `Portal.Summary` for three entities — `User`, `Session`, and `Lesson`. One call, three bodies. Choose a value and watch the matching implementation run and return its own summary.

## Sections

1. **The dispatch table** (`#table`) — teaching section. Three `defimpl` blocks register three implementations under one protocol; a call carries the value to the matching block, runs that body, and returns its result. Carries the interactive figure and the takeaway (adding a fourth entity means a fourth `defimpl`).
2. **Writing the implementations** (`#write`) — inside a block the struct name is short (`for: User`); each `summarize/1` pattern-matches the fields it needs and returns a string. Carries the real Elixir code block, a `bridge` (the idea → in Elixir: open for extension, closed for modification), and a forward `note` to `behaviours`.

Running example: the `Portal.Summary` protocol implemented for `User`, `Session`, and `Lesson`.

Real Elixir code shown (the `#write` block, verbatim):

```elixir
defimpl Portal.Summary, for: User do
  def summarize(%User{email: e, role: r}), do: "#{e} · #{r}"
end

defimpl Portal.Summary, for: Session do
  def summarize(%Session{id: id}), do: "session #{id} · active"
end

defimpl Portal.Summary, for: Lesson do
  def summarize(%Lesson{id: id, minutes: m}), do: "lesson #{id} · #{m} min"
end
```

## The interactives

Figure — `<figure class="fig">` with title "The incoming value · select one" (`id="diTitle"`). Control group `id="diSel"`, role group, label "Incoming value", buttons:
- `data-k="user"`, `data-c="elixir"`, label "%User{}" (default active)
- `data-k="session"`, `data-c="blue"`, label "%Session{}"
- `data-k="lesson"`, `data-c="sage"`, label "%Lesson{}"

SVG element ids: `diIn`, `diInT` (incoming value); the three dispatch rows `diR0`/`diR1`/`diR2` with markers `diM0`/`diM1`/`diM2` (the "runs" badge); the result line `diResT`. Code block `id="diCode"`; readout `id="diOut"`. The pure function `pick(k)` reads a `CASES` table; each case carries a `match` index (0/1/2) that lights the matching row's stroke and "runs" marker and sets the result string, code, and `diOut` prose. Readout strings (verbatim):
- `user` (match 0) → result `"ada@portal.dev · student"`, out: `The value is a <code class="inl">User</code>, so the <code class="inl">for: User</code> block runs and returns the email and role.` (input `%User{email: "ada@portal.dev", role: :student}`)
- `session` (match 1) → result `"session SES0NbAb29FnXc · active"`, out: `A <code class="inl">Session</code> resolves to the <code class="inl">for: Session</code> block &mdash; the same protocol, a body that reads the session id.` (input `%Session{id: "SES0NbAb29FnXc", active: true}`)
- `lesson` (match 2) → result `"lesson LSN0NbAb2Lk9GS · 12 min"`, out: `A <code class="inl">Lesson</code> runs the <code class="inl">for: Lesson</code> block, which reads its id and minutes. A new type would add a fourth block beside these.` (input `%Lesson{id: "LSN0NbAb2Lk9GS", minutes: 12}`)

Degrade behaviour: the figure ships a static default in the markup (the `user` case — `%User{email: "ada@portal.dev", role: :student}`, the `for: User` row marked "runs" at full opacity, result `"ada@portal.dev · student"`), visible without JS. Reveal-on-scroll is JS-gated and gated by `prefers-reduced-motion: reduce`; the `.arc-flow` animation runs only under `prefers-reduced-motion: no-preference`.

Footer build-stamp: `id="stampId"` carries `TSK0NbPCz2Jmr2`; the in-markup decoded `timestamp` is `2026-05-31 16:59:48 UTC`. The decoder splits namespace `TSK` and base62-decodes the rest to a Snowflake against `EPOCH_MS = 1704067200000`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/protocols.html` — Protocols — Elixir documentation — polymorphism by data type.
- `https://hexdocs.pm/elixir/Protocol.html` — `Protocol` — Elixir documentation — defining and consolidating protocols.
- `https://hexdocs.pm/elixir/typespecs.html` — Typespecs and behaviours — Elixir documentation — contracts via behaviours.

Related in this course:
- `/elixir/language/protocols` — F3.06 · Protocols & behaviours
- `/elixir/language/protocols/define` — Defining a protocol
- `/elixir/language/protocols/behaviours` — Behaviours & callbacks

## Wiring

- route-tag: `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><a href="/elixir/language/protocols">protocols</a><span class="rsep">/</span><span class="rcur">defimpl</span>`
- crumbs: `F3` (→ `/elixir/language`) `/` `F3.06` (→ `/elixir/language/protocols`) `/` `defimpl` (here)
- toc-mini: `#table` "The dispatch table"; `#write` "Writing the implementations"
- pager: prev → `/elixir/language/protocols/define` "F3.06.1 · define"; next → `/elixir/language/protocols/behaviours` "Next · behaviours"
- footer: column "Chapters" → `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework); column "The course" → `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01); brand tagline "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>Implementing for a struct — F3.06.2 · jonnify</title>`; `<meta name="description" content="defimpl Protocol, for: Struct gives the per-type bodies a call resolves to; three implementations form a dispatch table that grows by addition — open for extension, closed for modification.">`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on this `elixir` (purple) chapter accent — the model sibling is `elixir/language/protocols/behaviours.html` (the adjacent F3.06.3 dive), which carries the identical dive anatomy: hero `crumbs` + `eyebrow` "part N of 3" + upright `lede` + `toc-mini`, a teaching `#…` section with a `solid-select` `.fig` whose SVG holds stacked dispatch rows + a result line, a `pre.code` block, a `bridge`, the forward `note`, References, pager, and the branded stamp. Change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store and branded ids (`SES0NbAb29FnXc`, `LSN0NbAb2Lk9GS`), the event-sourced engine behind ONE `Portal` facade, and the Phoenix web app; the only protocol surface this dive names is `Portal.Summary` with `summarize/1` implemented `for:` `User`, `Session`, and `Lesson`. Cite the companion `/elixir/phoenix` chapter for any web/OTP internals; do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
