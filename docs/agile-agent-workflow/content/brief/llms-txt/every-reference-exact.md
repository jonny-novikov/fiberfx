# A5.1.2 — Every reference exact

- **Route:** `/course/agile-agent-workflow/brief/llms-txt/every-reference-exact`
- **File:** `html/agile-agent-workflow/brief/llms-txt/every-reference-exact.html`
- **Eyebrow:** `A5.1.2 · dive 2/3` · **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Crumbs:** jonnify (`/elixir`) / Agile Agent Workflow (`/course/agile-agent-workflow`) / A5 · The agent brief (`/course/agile-agent-workflow/brief`) / A5.1.2 · Every reference exact
- **Pager:** prev `/course/agile-agent-workflow/brief/llms-txt/links-first` · next `/course/agile-agent-workflow/brief/llms-txt/the-machine-brief`

## Lead

A5.1.1 put the links first: the agent reads the sources before any narrative. This dive sharpens the
links themselves. A reference that resolves to one reading is a contract; a reference that resolves to two
is a fork in the road the agent has to pick — and a pick is a decision the brief failed to make. The
principle: **name each source precisely enough that the agent reads the one right thing, not an
approximation.**

## The precise definition

An **exact reference** names its target to a precision that admits one reading. "The facade" names a thing
that could be any of several; "the `Portal` facade" narrows it; "`Portal.courses_of/1 :: {:ok,
[%Enrollment{}]}`" pins the function, its arity, and its return shape so there is nothing left to choose.
The same discipline applies to a contract reference: a closed error set named by its struct and its `code`
field admits no fourth variant the agent might invent.

## F6 grounding — the "Upstream contract (do not modify)" reference

From the **real** `docs/elixir/specs/phoenix/f6.1.llms.md`, the `## References` block carries one reference
that is also a constraint — quoted verbatim, do not paraphrase its arity or shape:

> **Upstream contract (do not modify).** The `Portal` facade — query `courses_of/1 :: {:ok, [%Enrollment{}]}`
> (as-built and **total / success-only**: the wrapped list, no bare-list arm, and no `{:error, %Portal.Error{}}`
> producer — an unknown or malformed user id yields `{:ok, []}`). The controller still pattern-matches the
> `{:error, %Portal.Error{} = e}` arm defensively (railway-oriented), so the `422` render path exists and is
> unit-testable; that arm is simply not produced by `courses_of/1` at F6.1. And the closed error set
> `%Portal.Error{code, message, field}` with `code` in
> `:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`.

The reference names the function (`courses_of/1`), the success shape (`{:ok, [%Enrollment{}]}`, total /
success-only), the defensive arm (`{:error, %Portal.Error{} = e}` → `422`), and the closed `code` set. The
controller `F6.1-R4` reads this and builds two arms — the success list and the `422` error render — without
inventing a third.

## Interactive 1 (hero, framing) — precision dial

- **Intent:** show that ambiguity falls to zero as the same reference is named more precisely. The hero
  *frames* the idea (one reference, three phrasings, an ambiguity score); the content interactive *proves the
  consequence* (an exact reference lets the agent build both arms without inventing).
- **Dataset (fixed):** three phrasings of one reference —
  - `the facade` — ambiguity 2 (which facade? which function? what shape?)
  - `the Portal facade` — ambiguity 1 (the right module, but which function and shape?)
  - `Portal.courses_of/1 :: {:ok, [%Enrollment{}]}` — ambiguity 0 (function, arity, return shape pinned)
- **Control:** a 3-stop range slider (`#precDial`, values 0–2) plus three buttons; a "readings" SVG bar that
  narrows as precision rises.
- **Pure function:** `ambiguityOf(phrasingIndex) -> {label, score, readings}` over the fixed dataset (score
  0–2; `readings = score + 1`).
- **Readout (`#precOut`, aria-live):** e.g. *"`Portal.courses_of/1 :: {:ok, [%Enrollment{}]}` — ambiguity 0
  of 2: the reference resolves to one reading. The agent reads the one right thing."*

## Interactive 2 (content, teaching) — which arm does the agent build

- **Intent:** prove the consequence of precision — an exactly-named contract lets the agent build every arm
  the controller needs; a loosely-named one leaves arms the agent must invent.
- **Dataset (fixed):** the two facade arms `F6.1-R4` names —
  - `success` — `{:ok, courses}` → `render(:index, courses: courses)` (the success list)
  - `error` — `{:error, %Portal.Error{} = e}` → `put_status(422) |> render(:error, error: e)` (the 422 render)
  - Each arm has `named_exactly` true under the exact spec; under the loose spec, `success` stays nameable
    (1 of 2) and `error` is not (the `%Portal.Error{}` shape and `code` set are unnamed).
- **Control:** a two-button toggle (`#armsSpec`): `named exactly` vs `named loosely`.
- **Pure function:** `armsPinned(spec) -> {built, total, names}` — counts arms the agent can build without
  inventing (2 of 2 when exact; 1 of 2 when loose).
- **Readout (`#armsOut`, aria-live):** *"Named exactly — arms the agent can build without inventing: 2 of 2
  (the success list and the 422 error render)."* / loose: *"Named loosely — arms: 1 of 2. The 422 path's
  error shape is unnamed, so the agent invents `%Portal.Error{}` or drops the arm."*

## Bridge

- **Principle (`.cell.idea`):** Name each source precisely enough that the agent reads the one right thing.
  An exact reference admits one reading; a loose one admits several, and the agent has to pick.
- **→ Portal (`.cell.elix`):** `f6.1.llms.md` pins `courses_of/1` to its exact return shape
  `{:ok, [%Enrollment{}]}` and the closed `%Portal.Error{code, message, field}` set, so the controller
  renders the success list and the `422` error, never a guessed third shape.
- **Take:** An exact reference is a contract; a loose one is an invitation to improvise.

## Cross-links

- **In-prose `/elixir`:** `/elixir/phoenix/lifecycle/controllers` — the controller that calls the exact facade.
- **Related in this course:** `/elixir/phoenix/lifecycle`; plus the module hub and the two sibling dives.

## Sources (3, vetted)

- The `llms.txt` convention — `https://llmstxt.org/`
- Anthropic — Building effective agents — `https://www.anthropic.com/engineering/building-effective-agents`
- The Pragmatic Programmer — `https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/`
