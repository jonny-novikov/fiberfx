# A2.01.2 · Who benefits

- **Route:** `/course/agile-agent-workflow/decomposition/value/who-benefits`
- **File:** `html/agile-agent-workflow/decomposition/value/who-benefits.html`
- **Model copied from:** `html/agile-agent-workflow/why/two-layers/spec.html`
- **Accent:** gold
- **Position:** A2.01 · Value, not tasks · dive 2

## Lead

Every slice names a role and the value to that role. If you cannot name who is better off, you
have a chore, not a story. And once value is named, it — not effort — is what orders the backlog:
the most valuable buildable slice goes first.

## Definition

- **role** — the someone a slice serves. On the Portal: a learner; later, an author or an admin.
  A slice with no role is a chore.
- **value to that role** — what the role can do after the slice that it could not before. Naming
  it is the difference between "wire the enrolment form" (chore) and "a learner enrols in a course"
  (story).
- **ordering by value** — the backlog is ordered by value delivered, subject to dependency, not by
  how much work a slice is. Cheap-but-pointless never beats valuable-and-buildable.

Effort still matters — it bounds whether a slice fits one rung — but it is not the *ordering* key.
Value is, with dependency as the only constraint on the order.

## Worked Portal example

The Portal's four learner stories each name the role and its value:

```
A learner browses the catalogue of courses.
A learner enrols in a course from the catalogue.
A learner opens a lesson in an enrolled course.
A learner tracks progress through a course.
```

Each is "role + value." Ordered by value-under-dependency, browse comes first (nothing depends on,
high value: without it nothing else is reachable), then enrol, then open, then track. A chore like
"add the courses table" names no role, so it cannot be placed by value at all — it is placed by
the story it serves.

## Hero interactive — name the role, or it is a chore

**Inspect each Portal item for a named role.** Fixed dataset of items, each tagged with a role or
`none`. Buttons select an item; the readout reports the role and the value, or flags the missing
role. Pure: `inspect(item)` → `{role, value, isStory:boolean}`. Sample readout: "A learner enrols
in a course. Role: learner. Value: the course is now in their enrolments. Names a role and a value
→ a story." For a chore: "Add the courses table. Role: none. Value to a role: none observable →
a chore, placed by the story it serves, not on its own."

## Content interactive — order the backlog by value, not effort

**Re-rank four stories by value or by effort and read the resulting order.** Fixed dataset: each
story has a value rank and an effort rank (and a dependency). A two-state toggle (`by value` /
`by effort`) sorts and renders the order; the readout names the top slice and whether the order
respects dependency. Pure: `order(stories, key)` → `[…ranked]`; `firstBuildable(ordered)` →
story. Sample readout (by value): "Ordered by value: browse → enrol → open → track. Top slice:
browse the catalogue — highest value and depends on nothing, so it is built first." (by effort):
"Ordered by effort, the cheapest slice leads — but it may deliver little and may depend on work
not yet done. Value, under dependency, is the ordering key." This teaches a *different* move from
the hero: the hero validates a single slice; this one orders the set.

## Bridge (principle → Portal practice)

Principle: a slice without a named beneficiary is a chore; value to a role, not effort, orders the
backlog. → Portal: "a learner enrols in a course" leads on value; "add the courses table" carries
no role and is sequenced by the story it serves, never ranked against it.

## Recap

A story names a role and the value to that role; a slice that names neither is a chore. With value
named, the backlog orders by value under dependency — the most valuable buildable slice first —
and effort only bounds the size of a rung.

## References — Sources (real, vetted)

- User Stories Applied → mountaingoatsoftware.com — the "as a <role>, I want … so that …" value form.
- INVEST in Good Stories → xp123.com — Valuable: a story must be valuable to a user or customer.
- Extreme Programming Explained → oreilly.com — the customer orders the backlog by business value.

Related: A2.01 hub; A2.01.1 outcome-not-chore; A2.01.3 vertical-slice; A1.04.2 spec layer; A2 landing;
`/elixir/course`.

## Pager

- prev = A2.01.1 `/course/agile-agent-workflow/decomposition/value/outcome-not-chore`
- next = A2.01.3 `/course/agile-agent-workflow/decomposition/value/vertical-slice`
