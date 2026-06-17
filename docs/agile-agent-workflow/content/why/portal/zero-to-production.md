# A1.06.2 — Zero to production

> Route: /course/agile-agent-workflow/why/portal/zero-to-production
> Eyebrow: A1.06 · dive 2 · Meet the project: Portal
> Accent word: production

## Lead

The Portal starts at zero — an empty repository plus the one given branded-id store — and ends in
production: a deployed, supervised, multi-surface platform. This dive names what "zero" is and what
"production" demands, and shows that the gap between them is crossed by thin increments, not one leap.

## The two endpoints (the precise definition)

- **Zero** is the smallest honest starting point: an empty repository and the single given component —
  the branded-id store. The store can mint and decode a typed id (`Portal.ID.generate/1`,
  `Portal.ID.decode/1`, whose result carries `.type` and `.timestamp`). Nothing is deployed, nothing is
  supervised, nothing is observed, and there is one surface — a function call in a test.
- **Production** is a deployed, supervised, multi-surface Portal: the store, an event-sourced engine
  behind one facade, a Phoenix web app, a Telegram bot, and a student dashboard — running where students
  reach it, restarted when a part fails, reachable on more than one surface, and observable so a failure
  is visible.

Production is not "the code is written." Production is the set of properties a running system must have
for students to depend on it: deployed, supervised, multi-surface, observable, reliable.

## Worked Portal example

At zero, the only thing that works is the store, exercised in a test:

    id = Portal.ID.generate(:user)        # => "USR0NbAb1xcFCy"
    decoded = Portal.ID.decode(id)
    decoded.type                          # => :user
    decoded.timestamp                     # the embedded mint time

That is the whole system at zero: one component, one surface, no deployment. Every production property is
absent. To reach production, each property is added as its own thin rung — deploy, supervise, add the web
surface, add the bot, add the dashboard, make each observable — and production is reached only when every
required rung has shipped. (The OTP supervision that makes "supervised" true is taught by the companion
/elixir course; this course cites it, it does not re-teach it.)

## Hero interactive — zero vs production

Move: a `.solid-select` toggles between "zero" and "production". The SVG and readout name what each state
has and what it lacks. Zero: has an empty repo + the branded-id store; lacks deployment, supervision,
extra surfaces, observability. Production: has all five properties — deployed, supervised, multi-surface,
observable, reliable. Pure function `endpointReadout(state)` over a fixed dataset.

## Content interactive — the gap is closed rung by rung

Move (different from the hero): a stepper/slider over N required rungs fills a "production-readiness" bar
from zero to done. The readout shows that production is reached only when **every** required rung has
shipped — the gap is crossed by thin increments, not one leap. Pure function `readinessReadout(shipped)`
returns the count, the percentage, the next rung, and whether production is reached. This ties A1.01.2
big-bang: a single leap is the failure mode; the gap is closed rung by rung.

## Bridge (principle → Portal practice)

- Principle: define the finish line as properties a running system must have, then close the distance
  with thin increments — production is reached only when every required property is present.
- Portal: zero is the empty repo + the store; production is the deployed, supervised, multi-surface,
  observable Portal — and each property is its own rung, shipped one at a time.
- Take: production is a set of properties, not a moment; the gap from zero is crossed rung by rung.

## References

Sources:
- Continuous Delivery — https://continuousdelivery.com/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/

Related in this course:
- A1.06 hub — /course/agile-agent-workflow/why/portal
- A1.01.2 big-bang-specs — /course/agile-agent-workflow/why/failure-modes/big-bang-specs
- A1.04 two-layers — /course/agile-agent-workflow/why/two-layers

## Pager

- prev → A1.06.1 · What Portal is → /course/agile-agent-workflow/why/portal/domain
- next → A1.06.3 · One rung at a time → /course/agile-agent-workflow/why/portal/one-rung
