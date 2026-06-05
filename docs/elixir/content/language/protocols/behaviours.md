# F3.06.3 — Behaviours & callbacks (dive)

- Route (served): `/elixir/language/protocols/behaviours`
- File: `elixir/language/protocols/behaviours.html`
- Place in the chapter: the third and last of the F3.06 dives, part 3 of 3. It is the compile-time counterpart to the protocol pages — a behaviour is a contract on a module (`@callback` / `@behaviour` / `@impl`), the basis OTP is built on. It follows F3.06.2 (`defimpl`) and closes the module, pointing forward to F3.07 (Processes & the actor model).
- Accent: `elixir` (purple).
- Status: built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow: `F3.06 · part 3 of 3`

H1: Behaviours & callbacks

Hero lede (verbatim):

> A behaviour is the other half of polymorphism. Where a protocol dispatches on a value's type at runtime, a behaviour is a contract on a **module**: `@callback` declares the functions a module must provide, `@behaviour` opts a module in, and the compiler checks that every callback is implemented.

Kicker (verbatim):

> The portal sends notifications through interchangeable modules — email, SMS, push. A `Portal.Notifier` behaviour names what each must implement. Choose a module and see whether it satisfies the contract.

## Sections

1. **A contract the compiler checks** (`#contract`) — teaching section. The behaviour declares two callbacks, `deliver/2` and `valid_target?/1`; a module that adopts it must define both. Carries the interactive figure and the takeaway (enforced at compile time, on the module — the mirror image of a protocol).
2. **Declaring callbacks** (`#declare`) — `@callback` gives each required function a typed signature; an implementing module adds `@behaviour` and marks each definition `@impl true`. Carries the real Elixir code block, a `bridge` (two kinds of polymorphism → in Elixir: OTP's `GenServer` and `Supervisor` are behaviours), and a forward `note` to F3.07.

Running example: the `Portal.Notifier` behaviour with callbacks `deliver/2` and `valid_target?/1`, adopted by `EmailNotifier`, `SmsNotifier`, and an incomplete `PushNotifier`.

Real Elixir code shown (the `#declare` block, verbatim):

```elixir
defmodule Portal.Notifier do
  @callback deliver(target :: String.t(), message :: String.t()) :: {:ok, term} | {:error, term}
  @callback valid_target?(target :: String.t()) :: boolean
end

defmodule EmailNotifier do
  @behaviour Portal.Notifier
  @impl true
  def deliver(to, msg), do: {:ok, "email to #{to}"}
  @impl true
  def valid_target?(to), do: String.contains?(to, "@")
end
```

## The interactives

Figure — `<figure class="fig">` with title "The implementing module · select one" (`id="bhTitle"`). Control group `id="bhSel"`, role group, label "Implementing module", buttons:
- `data-k="email"`, `data-c="elixir"`, label "EmailNotifier" (default active)
- `data-k="sms"`, `data-c="blue"`, label "SmsNotifier"
- `data-k="incomplete"`, `data-c="sage"`, label "PushNotifier"

SVG element ids: `bhBox`, `bhBoxT` (the module + `@behaviour Portal.Notifier`); the two required-callback rows `bhR0`/`bhR1` with status labels `bhS0`/`bhS1`; the compiler result line `bhResT`. Code block `id="bhCode"`; readout `id="bhOut"`. The pure function `pick(k)` reads a `CASES` table; each case sets the module box, the per-callback status (implemented/missing), the compiler status line, the code, and the `bhOut` prose. Readout strings (verbatim):
- `email` → status line `all callbacks implemented`, rows both `implemented`, out: `EmailNotifier adopts <code class="inl">@behaviour Portal.Notifier</code> and defines both callbacks, each marked <code class="inl">@impl true</code>. The contract is satisfied and the module compiles clean.`
- `sms` → status line `all callbacks implemented`, rows both `implemented`, out: `SmsNotifier satisfies the same contract with its own bodies. A behaviour fixes the function set every module must provide, not how each one behaves.`
- `incomplete` → status line `missing valid_target?/1 — compile warning`, rows `implemented` / `missing` (red), out: `PushNotifier defines <code class="inl">deliver/2</code> but omits <code class="inl">valid_target?/1</code>. The compiler warns that a required callback is missing &mdash; a contract checked at build time, not at the call.`

Degrade behaviour: the figure ships a static default in the markup (the `email` case — `EmailNotifier · @behaviour Portal.Notifier`, both `deliver/2` and `valid_target?/1` marked "implemented", result `all callbacks implemented`), visible without JS. Reveal-on-scroll is JS-gated and gated by `prefers-reduced-motion: reduce`; the `.arc-flow` animation runs only under `prefers-reduced-motion: no-preference`.

Footer build-stamp: `id="stampId"` carries `TSK0NbPCzRrgYq`; the in-markup decoded `timestamp` is `2026-05-31 16:59:48 UTC`. The decoder splits namespace `TSK` and base62-decodes the rest to a Snowflake against `EPOCH_MS = 1704067200000`.

## References (#refs, verbatim)

Intro line: "Primary sources for this lesson, and where it connects in the course."

Sources:
- `https://hexdocs.pm/elixir/typespecs.html` — Typespecs and behaviours — Elixir documentation — contracts via behaviours.
- `https://hexdocs.pm/elixir/protocols.html` — Protocols — Elixir documentation — polymorphism by data type.
- `https://hexdocs.pm/elixir/Protocol.html` — `Protocol` — Elixir documentation — defining and consolidating protocols.

Related in this course:
- `/elixir/language/protocols` — F3.06 · Protocols & behaviours
- `/elixir/language/protocols/define` — Defining a protocol
- `/elixir/language/protocols/defimpl` — Implementing with defimpl

## Wiring

- route-tag: `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/language">language</a><span class="rsep">/</span><a href="/elixir/language/protocols">protocols</a><span class="rsep">/</span><span class="rcur">behaviours</span>`
- crumbs: `F3` (→ `/elixir/language`) `/` `F3.06` (→ `/elixir/language/protocols`) `/` `behaviours` (here)
- toc-mini: `#contract` "A contract the compiler checks"; `#declare` "Declaring callbacks"
- pager: prev → `/elixir/language/protocols/defimpl` "F3.06.2 · defimpl"; next → `/elixir/language` "Back to F3 · The Elixir Language"
- footer: column "Chapters" → `/elixir/algebra` (F1 · Algebra), `/elixir/functional` (F2 · Functional Programming), `/elixir/language` (F3 · The Elixir Language), `/elixir/algorithms` (F4 · Algorithms & Data Structures), `/elixir/pragmatic` (F5 · Pragmatic Programming), `/elixir/phoenix` (F6 · Phoenix Framework); column "The course" → `/elixir` (Course home), `/elixir/course` (Contents & history), `/elixir/algebra/functions` (Start · F1.01); brand tagline "Functional Programming in Elixir — functional thinking taught twice: first as mathematics, then as idiomatic Elixir."
- Page meta: `<title>Behaviours &amp; callbacks — F3.06.3 · jonnify</title>`; `<meta name="description" content="@callback declares a typed contract on a module; @behaviour and @impl true fulfil it and let the compiler flag a missing callback — the compile-time counterpart to a protocol, and the basis for OTP behaviours.">`

## Build instruction

To (re)build this page, copy the `<head>…</style>`, the `<header class="site">`, the `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent BUILT sibling on this `elixir` (purple) chapter accent — the model sibling is `elixir/language/protocols/defimpl.html` (the adjacent F3.06.2 dive), which carries the identical dive anatomy: hero `crumbs` + `eyebrow` "part N of 3" + upright `lede` + `toc-mini`, a teaching `#…` section with a `solid-select` `.fig` whose SVG holds stacked status rows + a result line, a `pre.code` block, a `bridge`, the forward `note`, References, pager, and the branded stamp. Change only `<title>`/`<meta>`, the `route-tag`, and the `<main>` body. No-invent guards: use only the real Portal surfaces as written — the branded store and the event-sourced engine behind ONE `Portal` facade, and the Phoenix web app; the only behaviour surface this dive names is `Portal.Notifier` with callbacks `deliver/2` and `valid_target?/1`, fulfilled by `EmailNotifier`/`SmsNotifier`/`PushNotifier`. Cite the companion `/elixir/phoenix` chapter and `/elixir/language/otp` for OTP behaviours (`GenServer`, `Supervisor`); do not re-teach them here. Voice rules: no first person, no exclamation marks, no emoji, and none of just/simply/obviously.
