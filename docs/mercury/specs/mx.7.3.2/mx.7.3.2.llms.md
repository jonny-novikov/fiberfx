# mx.7.3.2 — build context (sub-batch 2: Calendar)

Working notes for [`mx.7.3.2.md`](./mx.7.3.2.md). Root = `mercury/`. The body is authoritative. **NO-INVENT.**
**Edit ONLY** `packages/mercury-ui/src/components/inputs/Calendar/` + `src/index.ts` (+1) +
`src/styles/additions.css` + `docs/mercury/specs/mx.7.3.2/` — **and**, only if A2 arm (a), a curated additive
export in `packages/mercury-core/src/`. The bundle `packages/mercury-ds/` is **read-only**.

## Read first (inherited)

The sub-epic [`../mx.7.3/mx.7.3.md`](../mx.7.3/mx.7.3.md) + the mx.7 epic [`../mx.7/mx.7.md`](../mx.7/mx.7.md)
§4/§5 + the batch-1 grounding [`../mx.7.3.1/mx.7.3.1.md`](../mx.7.3.1/mx.7.3.1.md) §A·A2 (the date-lib arms +
the grounded "no ready hook" finding — reused here) + [`../mx.7.1/mx.7.1.llms.md`](../mx.7.1/mx.7.1.llms.md) (the
translation recipe).

## ⚠ Rule §A·A2 (the date-lib for Calendar) before building

Ruled per machine; same grounded arms as mx.7.3.1 — (a) curated `@mercury/core` calendar hook (heaviest;
i18n-correct; reuse the mx.7.3.1 layer if arm (a) was ruled there) · (b) ui takes `@internationalized/date`
directly (violates INV-6) · (c) native `Date`, translate the prototype faithfully (lightest; epic-consistent).
**INV-6: `@mercury/ui` must NOT `import "@internationalized/date"` directly.**

## References (read in order)

1. [`mx.7.3.2.md`](./mx.7.3.2.md) — the body (§3 surface + §4 translation notes + §A·A2).
2. The bundle prototype: `packages/mercury-ds/project/components/inputs/Calendar/Calendar.tsx` (month grid; native
   `Date`; prev/next paging; `accent`) + its `.prompt.md` (prop-list seed only — strip framing).
3. The live `Icon`: `packages/mercury-ui/src/components/foundations/Icon/Icon.tsx` — the `ICONS` record +
   `IconName` (use a **real glyph** for the nav chevrons — confirm `chevron-left`/`chevron-right` exist; the
   bundle's `chev` is not a live name). Cross-link target `inputs/DateField/` (mx.7.3.1) + `overlay`/`Popover`
   (mx.7.4, forward-tense in the contract).
4. The core date layer (A2 arm (a)): `packages/mercury-core/src/internal/date-time/` (machinery on
   `@internationalized/date`; **no ready hook** — arm (a) builds one; reuse the mx.7.3.1 hook/layer if it exists).
5. Styles: `packages/mercury-ui/src/styles/additions.css` (the `.mx-calendar` rules + the
   `.mx-calendar--accent-<id>` ramps — reuse the mx.7.1 ramp set), `tokens.css` (surface/border/`--fg-*`,
   the radius scale).
6. The contract format: [`../../contracts.md`](../../contracts.md).

## Ground facts (re-probe before trusting)

- **Stack** as mx.7.3.1 (React 19, TS ^5.6 `verbatimModuleSyntax`/`strict`/`noUncheckedIndexedAccess`). Guard
  React-19 nullable `useRef().current`.
- **`@mercury/ui`'s only dep is `@mercury/core`** — INV-6 (no direct `@internationalized/date`).
- **No ready calendar hook in core** — arm (a) builds one (reuse the mx.7.3.1 date layer if arm (a) was ruled).
- **Bundle glyph names ≠ live Icon set** (mx.7.2 L5) — remap the nav chevron to a real `IconName`; a typed `name`
  makes `sb:typecheck` the backstop.
- **`accent` is class-driven** (`.mx-calendar--accent-<id>`) — never `mercAccent`, never forwarded as a raw color.
- **`sb:typecheck` is the authoritative story NO-INVENT gate** (library `tsc` excludes `**/*.stories.tsx`).

## The file tree

```
packages/mercury-ui/src/components/inputs/Calendar/{Calendar.tsx,index.ts,Calendar.prompt.md,Calendar.stories.tsx}
packages/mercury-ui/src/index.ts                 # +1: export * from "./components/inputs/Calendar"
packages/mercury-ui/src/styles/additions.css     # + .mx-calendar + .mx-calendar--accent-<id> rules
# ONLY if A2 arm (a): a curated packages/mercury-core/src/ export (reuse the mx.7.3.1 hook if present)
```

## The gate (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck && pnpm --filter "./packages/*" build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build
pnpm sb:typecheck && pnpm sb:build
# barrel additive: +1 (Calendar + CalendarProps), 0 removed/renamed
NEW=packages/mercury-ui/src/components/inputs/Calendar
grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" $NEW
grep -rnE "#[0-9a-fA-F]{3,8}\b" $NEW packages/mercury-ui/src/styles/additions.css
grep -rn  "mercAccent\|_lib/accent" $NEW
grep -rn  "@internationalized/date" packages/mercury-ui/src
grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/" $NEW
```

## Gotchas

- **Rule A2 first**; reuse the mx.7.3.1 date layer if arm (a) was ruled there (don't build a second hook).
- **Real glyph for the nav chevron** — verify the live `IconName`; never invent `chev`.
- **Dynamic non-color inline allowed** (grid template); never a raw hex.
- **Commit hygiene:** bundle OUT of the pathspec; `mercury/…` pathspec only; never `git add -A`; never `pnpm -r`.
- **Framing:** no gendered pronouns / perceptual verbs / first-person in the contract.

## Lessons carried from mx.7.3.1

The Director fills this at release from mx.7.3.1's as-built — expected: the ruled A2 arm + (if arm (a)) the core
date hook to reuse, the date-state-machine controlled/uncontrolled pattern, and which token/font lines mx.7.1/7.2
already added (reuse, don't re-add).

## When this batch ships

aaw scope slug `mx-7-3-2` (dashed). REAL aaw Trio (`aaw_init` + registered `venus`/`mars`); Apollo recommended
for the grid machine.
