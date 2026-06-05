# F3.06.1 — Defining a protocol (dive)

- Route (served): `/elixir/language/protocols/define`
- File: `elixir/language/protocols/define.html`
- Place in the chapter: the first of the three F3.06 dives, part 1 of 3. It is the "what & how it resolves" page — `defprotocol` declares the contract, and a call dispatches by the value's type. It precedes F3.06.2 (`defimpl`, the per-type bodies) and F3.06.3 (`behaviours`, the compile-time counterpart).
- Accent: `elixir` (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.06 · part 1 of 3`

H1: Defining a protocol

Hero lede (verbatim):

> `defprotocol` declares a set of function signatures without bodies — the contract. When one is called, Elixir reads the argument's type and dispatches to the implementation registered for that type. If none exists, the call raises `Protocol.UndefinedError`.

Kicker (verbatim):

> The portal declares `Portal.Summary` with one function, `summarize/1`. Calling it on a value is a lookup by type. Send different values through and watch which implementation the call resolves to.

## Sections

1. **A call resolves by type** (`#resolve`) — teaching section. The same call, `Portal.Summary.summarize(value)`, lands in a different module for each type; the portal has implementations for `User` and `Session`, but not for a bare integer. Carries the interactive figure and the takeaway.
2. **Declaring the contract** (`#declare`) — the declaration lists signatures only; bodies live in the implementations. Carries the real Elixir code block, a `bridge` (F3.05.3 matching on the tag → F3 protocol dispatch), and a forward `note` to `defimpl`.

Running example: the `Portal.Summary` protocol with `summarize/1`, dispatched over `Portal.Accounts.User`, `Portal.Auth.Session`, and a bare integer.

Real Elixir code shown (the `#declare` block, verbatim):

```elixir
defprotocol Portal.Summary do
  @doc "A short one-line summary of any portal entity."
  def summarize(value)
end

# a call is a lookup by the value's type
Portal.Summary.summarize(%User{email: "ada@portal.dev", role: :student})
# => dispatches to the User implementation

Portal.Summary.summarize(42)
# ** (Protocol.UndefinedError) protocol Portal.Summary not implemented for 42
```

## The interactives

Figure — `<figure class="fig">` with title "The incoming value · select one" (`id="dpTitle"`). Control group `id="dpSel"`, role group, label "Incoming value", buttons:
- `data-k="user"`, `data-c="elixir"`, label "%User{}" (default active)
- `data-k="session"`, `data-c="blue"`, label "%Session{}"
- `data-k="int"`, `data-c="sage"`, label "42"

SVG element ids: `dpIn`, `dpInT` (incoming value), `dpTag` (type read by the protocol), `dpImpl`, `dpImplT` (`summarize/1` resolves to). Code block `id="dpCode"`; readout `id="dpOut"`. The pure function `pick(k)` reads a `CASES` table and rewrites the incoming-value box, the read type, the resolved implementation (or error), the code, and the `dpOut` prose. Readout strings (verbatim):
- `user` → tag `Portal.Accounts.User`, impl `Portal.Summary.Portal.Accounts.User`, out: `The value type is <code class="inl">Portal.Accounts.User</code>, so the call resolves to that type implementation and runs its body.` (code resolves `=> "ada@portal.dev · student"`)
- `session` → tag `Portal.Auth.Session`, impl `Portal.Summary.Portal.Auth.Session`, out: `A <code class="inl">%Session{}</code> resolves to the Session implementation &mdash; a different module, the same protocol and the same call.` (code resolves `=> "session SES0NbAb29FnXc · active"`)
- `int` → tag `Integer`, impl `** (Protocol.UndefinedError) not implemented for Integer`, out: `No implementation exists for an integer, so the call raises <code class="inl">Protocol.UndefinedError</code>. A protocol reaches only the types it has implementations for.`

Degrade behaviour: the figure ships a static default in the markup (the `user` case — `%Portal.Accounts.User{email: "ada@portal.dev"}` resolving to `Portal.Summary.Portal.Accounts.User`), visible without JS. Reveal-on-scroll is JS-gated and gated by `prefers-reduced-motion: reduce`; the `.arc-flow` animation runs only under `prefers-reduced-motion: no-preference`.

Footer build-stamp: `id="stampId"` carries `TSK0NbPCyd3UHI`; the in-markup decoded `timestamp` is `2026-05-31 16:59:48 UTC`. The decoder splits namespace `TSK` and base62-decodes the rest to a Snowflake against `EPOCH_MS = 1704067200000`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/protocols.html` — Protocols — Elixir documentation — polymorphism by data type.
- `https://hexdocs.pm/elixir/Protocol.html` — `Protocol` — Elixir documentation — defining and consolidating protocols.
- `https://hexdocs.pm/elixir/typespecs.html` — Typespecs and behaviours — Elixir documentation — contracts via behaviours.

Related in this course:
- `/elixir/language/protocols` — F3.06 · Protocols & behaviours
- `/elixir/language/protocols/defimpl` — Implementing for a struct
- `/elixir/language/protocols/behaviours` — Behaviours & callbacks

## Wiring

- route-tag: `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><a href="/elixir/language/protocols">protocols</a><span class="rsep">/</span><span class="rcur">define</span>`
- crumbs: `F3` (→ `/elixir/language`) `/` `F3.06` (→ `/elixir/language/protocols`) `/` `define` (here)
- toc-mini: `#resolve` "A call resolves by type"; `#declare` "Declaring the contract"
- pager: prev → `/elixir/language/protocols` "F3.06 · protocols"; next → `/elixir/language/protocols/defimpl` "Next · defimpl"
- footer: column "Chapters" → `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework); column "The course" → `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01); brand tagline "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>Defining a protocol — F3.06.1 · jonnify</title>`; `<meta name="description" content="defprotocol declares a contract of function signatures; a call resolves to the implementation registered for the value's type, dispatching by tag, or raises Protocol.UndefinedError when no implementation exists.">`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on this `elixir` (purple) chapter accent — the model sibling is `elixir/language/protocols/defimpl.html` (the adjacent F3.06.2 dive), which carries the identical dive anatomy: hero `crumbs` + `eyebrow` "part N of 3" + upright `lede` + `toc-mini`, one teaching section with a `solid-select` `.fig`, a `pre.code` block, a `bridge`, the forward `note`, References, pager, and the branded stamp. Change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store and branded ids (`SES0NbAb29FnXc`, `LSN…`), the event-sourced engine behind ONE `Portal` facade, and the Phoenix web app; the only protocol surface this dive names is `Portal.Summary` with `summarize/1`, dispatched over `Portal.Accounts.User` and `Portal.Auth.Session`. Cite the companion `/elixir/phoenix` chapter for any web/OTP internals; do not re-teach them. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
