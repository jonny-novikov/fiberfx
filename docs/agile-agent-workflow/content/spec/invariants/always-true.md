# A4.5.3 · Always true — dive

- **Route:** `/course/agile-agent-workflow/spec/invariants/always-true`
- **File:** `html/agile-agent-workflow/spec/invariants/always-true.html`
- **Accent:** elixir-purple · **Stamp:** `TSK0Ng9hnHJgW0`
- **Model:** lesson ← `why/two-layers/spec.html`

> **Ground-truth note (refinement pass).** The prose mention of the F6.1 rung is carried as a clickable `.specref`
> chip (label "F6.1 · Bootstrap the Phoenix Portal", id `sr-portal-f61`): a frame, a one-sentence tooltip, and a
> link to the spec-ladder viewer at `/course/agile-agent-workflow/spec/specimens` (bare-route href +
> `data-sr-hash="f6-1"`; JS appends `#f6-1` on click). The `f6.1.md` / `f6.1.stories.md` filenames inside the
> worked-example `pre.code` block stay as code labels (not prose citations). `%Portal.Error{}` and the closed
> error set are real allowed surfaces and stay.

## Lead

An invariant says "always". A check says "for this case". The gap between them is the point of this dive: no
finite set of passing checks proves an invariant holds for every value, because there is always a next value the
checks did not name. An invariant must be stated as a universal rule and exercised against a stream of values,
not asserted from one green scenario.

## Precise definition

- **"For all"** — an invariant is universally quantified. It claims a property of every value the increment can
  take, including values no test has tried.
- **A finite check set samples it** — each Given/When/Then is one point. Passing checks raise confidence; they do
  not close the universal claim.
- This is why a spec names invariants separately: an invariant is the rule held against *every* value as the
  increment runs, while a check is one named example of it holding.

## Worked Portal example

- The master invariant — "the web layer calls only the `Portal` facade" — holds for every request the Portal ever
  serves, including users that do not exist yet.
- The check "an unknown user id renders the empty state (a `200`)" (F6.1-US5) tests one value. The facade is total
  at the F6.1 rung — carried in the prose as the "F6.1 · Bootstrap the Phoenix Portal" spec-ladder chip — so the
  empty state holds; but that one passing check is a sample of the universal rule, not a proof of it for all ids.
- "The error set is closed" holds for every error value: a `code` one of
  `:already_enrolled | :course_not_found | :lesson_locked | :invalid_progress`, extended only by an explicit
  no-catch-all mapping. A new error kind without that mapping would break the invariant, whatever the scenario.

`pre.code`: a `.md` fragment — the Invariants line and a one-line Coverage-style note showing the check sampling
it. No Elixir source.

## Hero interactive — hold the rule over a value stream

- **Move:** step a fixed stream of request values; the master invariant holds for every value as the stream
  advances; the readout reports "invariant: holds for all N · check: holds for 1".
- **Control ids:** `atStep` (a `.fold-ctrl` range over the value stream, value id `atStepVal`).
- **Dataset:** a fixed stream of request values (a known user, an unknown user, no enrollments, a second unknown
  user, …).
- **Pure:** `holdsForAll(n)` → boolean (the master invariant holds for the first n values); `checkAt(n)` → which
  one value the single check covers; `readoutFor(n)` → the readout string.
- **Sample readout:** `Invariant: holds for all 4 values stepped — the web layer called only the facade for every one. Check: holds for 1 — the unknown-id scenario it names. The invariant is the universal rule; the check is one sample of it.`

## Main interactive — a check set never closes "for all"

- **Move (different):** add passing checks one at a time; the readout shows the covered-scenario count rise while
  the invariant's universal claim stays unproven by them — there is always a next value.
- **Control ids:** `atChecks` (`.fold-ctrl` range, value id `atChecksVal`).
- **Pure:** `coveredBy(n)` → count of scenarios checked; `closesForAll(n)` → false (a finite set never closes the
  universal); `readoutFor(n)` → the readout.
- **Sample readout:** `3 checks pass — 3 scenarios covered. The master invariant still is not proven for all values: a finite check set samples the rule, it does not close it. The next request is a value no check named.`

## Bridge

- principle: an invariant is a universal claim; a finite set of passing checks samples it but never closes it.
- Portal: the master invariant holds for every request; F6.1-US5's "unknown id → 200" check tests one value — it
  exercises the rule, it does not prove it for all ids.

## References

- Sources: Continuous Delivery, Specification by Example, Gherkin reference.
- Related: hub `/course/agile-agent-workflow/spec/invariants`,
  `/course/agile-agent-workflow/spec/invariants/the-master-invariant`, `/course/agile-agent-workflow/why/correct`,
  `/elixir/phoenix`.

## Pager

- prev = `/course/agile-agent-workflow/spec/invariants/the-master-invariant`
- next = `/course/agile-agent-workflow/spec/invariants` (back to hub)
