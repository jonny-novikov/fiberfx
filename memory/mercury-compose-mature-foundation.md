---
name: mercury-compose-mature-foundation
description: "Mercury component imports must COMPOSE its mature owned foundation (core formatters + internal/date-time machinery + reusable composables), not port the bundle prototype's throwaway logic — and frame forks on the maturity/reuse axis"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 04aedc27-8416-46f7-9caa-737abf6c5adc
---

For Mercury component imports/translations (the mx.7 epic), **"translate the bundle prototype" means its
ANATOMY/visual/structure/a11y only** — the value/validity/arithmetic **logic must build on Mercury's mature,
robust, OWNED reusable foundation**, never a one-off port of the prototype's naive logic:

- `@mercury/core` data **formatters** (`createFormatter`/`createTimeFormatter`, in `internal/date-time/formatter.ts`).
- the `internal/date-time` **machinery** (`field/{segments,parts,helpers,time-helpers,types}` + `placeholders`/
  `utils`/`time-value`, built on `@internationalized/date`).
- the reusable **headless composables**: `shared/` (the `Without`/`WithChildren`/`WithElementRef` type kit +
  `mergeProps` + `Selected`/`Orientation`) and the hooks `use-arrow-navigation`/`use-id`.

The architect (Venus) must **reconcile a rung's scoping against this reusable surface BEFORE building**, and scope
a **curated, REUSABLE composable** (e.g. `useDateField`) surfaced via the core barrel (`D-5`: ONE curated export;
boundary imports relative not `@/`). **INV-6:** `@mercury/ui` consumes the date layer **through `@mercury/core`**,
never `import "@internationalized/date"` directly (it is not a visible dep of `@mercury/ui`). Design the composable
for **reuse across related components** (DateField + Calendar share one date composable).

**Why:** Mercury is a mature DS with a robust owned foundation; reuse + composables are its standard. Porting a
prototype's throwaway one-off logic (e.g. the bundle DateField's native `{m,d,y}`/`parseInt`/wrap) regresses to
duplicate code and drops the i18n/validity the foundation already does correctly. (mx.7.3.1: the Operator ruled the
date-lib A2 fork → **arm (a) reframed as "compose the reusable foundation,"** explicitly rejecting the
native-faithful "translate-don't-redesign" default I had recommended.)

**How to apply:** When a fork reads as "quick native port vs heavy proper build," that framing is the WRONG axis
for Mercury — **reframe on maturity/reuse** (compose the owned foundation via a reusable composable). The Operator
engages architecture/scoping forks by **giving direction in prose** (restructuring scope, setting a principle) and
**rejected AskUserQuestion twice on mx.7.3.1** when the options missed that axis — so make a fork's option set
capture the maturity/reuse axis, or surface it in prose and take direction. [[mercury-design-system]]
[[mercury-economy-calibration]]
