# mx.7.1 — build context (batch 1: foundational primitives)

Working notes for [`mx.7.1.md`](./mx.7.1.md). Root = `mercury/`. The body is authoritative; this derives from
it. **NO-INVENT:** every bundle prop cited is verified in the bundle `.tsx`; every live target + token is real.
**Edit ONLY** `packages/mercury-ui/src/` (the 5 component folders + `src/index.ts` + `src/styles/additions.css`;
+ a font line if needed) + `docs/mercury/specs/mx.7.1/`. The bundle `packages/mercury-ds/` is **read-only**.

## Inherited from the epic (read first)

[`../mx.7/mx.7.md`](../mx.7/mx.7.md) §4 (the four cross-batch forks) + §5 (what every batch inherits). Do not
re-decide them here. In one line: translate to `.mx-*` + tokens; additive-only tokens/fonts; never rename an
existing export; design flows DOWN (no `/design-sync`); the 4-file home + the additive barrel + the gate.

## References (read in order)

1. [`mx.7.1.md`](./mx.7.1.md) — the body (§6 translation map is the build target).
2. The bundle prototypes (the prop-surface seed — translate, don't drop in):
   `mercury-ds/project/components/{foundations/Heading,foundations/Text,inputs/Label,actions/IconButton,layout/Separator}/<Name>.tsx`
   (+ each `<Name>.prompt.md` as the prop-list seed only).
3. The live idiom exemplars (imitate the shape): `packages/mercury-ui/src/components/foundations/Divider/Divider.tsx`
   (the `.mx-*` + `cx` rule; `Separator`'s sibling) and `actions/Button/Button.tsx` (`forwardRef`, `cx("mx-btn",
   \`mx-btn--${variant}\`, …)`, the variant/size unions `IconButton` shares).
4. The styles: `packages/mercury-ui/src/styles/additions.css` (add the `.mx-*` rules here), `tokens.css` (the
   token families + the `@font-face` block; the font candidate DM Sans 600), `src/styles/fonts/` (the self-hosted
   woff2 — DM Sans 400/500/700, DM Mono 300/400/500, DM Serif Display 400).
5. The contract format: [`../../contracts.md`](../../contracts.md) + any mx.2 `<Name>.prompt.md` as a shape exemplar.

## Ground facts (re-probe before trusting)

- **Stack:** Vite ^6, React 19, Node 22, pnpm 10.17, TypeScript ^5.6; `tsconfig.base.json` `verbatimModuleSyntax`
  (use `import type` for types), `strict` + `noUncheckedIndexedAccess`, `jsx: react-jsx`.
- **Tokens already cover the bundle** (Cross-fork II): `--iris-9`/`--bg-brand`/`--bg-active-subtle`/the radius scale
  + all three DM `@font-face` are present at identical values. Add only DM Sans 600 if a component needs weight 600.
- **The `accent` prop**: the bundle's `Heading`/`Text`/`Label` import `mercAccent` from `_lib/accent.ts`. **Do NOT
  import it into `@mercury/ui`** — realize `accent?: "iris"|"indigo"|"green"|"orange"|"plum"|"red"` as
  `.mx-<name>--accent-<id>` classes reading the `--<ramp>-11`/`--<ramp>-9` token families (all real ramps in
  `tokens.css`). One rule per ramp.
- **IconButton ≠ a second Button**: reuse the button tokens; `IconButton`'s `variant`/`size` unions are byte-equal
  to `ButtonProps`'. `shape="circle"` → `--radius-full`; `label` → `aria-label`.
- **`sb:typecheck` is the authoritative story NO-INVENT gate** (the library `tsc` excludes `**/*.stories.tsx`,
  D-9). A wrong prop/symbol fails there, not in `pnpm --filter @mercury/ui typecheck`.

## The file tree (create exactly these; nothing else)

```
packages/mercury-ui/src/components/foundations/Heading/{Heading.tsx, index.ts, Heading.prompt.md, Heading.stories.tsx}
packages/mercury-ui/src/components/foundations/Text/{Text.tsx, index.ts, Text.prompt.md, Text.stories.tsx}
packages/mercury-ui/src/components/foundations/Separator/{Separator.tsx, index.ts, Separator.prompt.md, Separator.stories.tsx}
packages/mercury-ui/src/components/inputs/Label/{Label.tsx, index.ts, Label.prompt.md, Label.stories.tsx}
packages/mercury-ui/src/components/actions/IconButton/{IconButton.tsx, index.ts, IconButton.prompt.md, IconButton.stories.tsx}
packages/mercury-ui/src/index.ts                 # +5 barrel lines (additive)
packages/mercury-ui/src/styles/additions.css     # +5 .mx-* rule blocks (+ accent ramps)
packages/mercury-ui/src/styles/tokens.css        # ONLY if DM Sans 600 needed (additive @font-face)
```

(`Separator` group = `foundations` per the body's group note; if the Operator prefers `layout`, move that folder.)

## The translation recipe (every component)

1. Read the bundle `.tsx` → extract the prop surface + anatomy (ignore the inline `style={{}}` values).
2. Write `<Name>.tsx`: `import type { … } from "react"`, `import { cx } from "@mercury/core"`, a
   `forwardRef`/function component extending the HTML attrs, `className={cx("mx-<name>", …modifiers, className)}`.
3. Add the `.mx-<name>` rules to `src/styles/additions.css` — `rgb(var(--token))` only, no raw hex; the accent
   ramps as `.mx-<name>--accent-<id>`.
4. `index.ts` = `export * from "./<Name>";`. Add the line to `src/index.ts` (additive).
5. `<Name>.prompt.md` — hand-author (mx.2 format): role · `## Props` (from the translated `.tsx`) · `## The enum
   language` (variants → token families) · `## Composition` (cross-links) · `## Examples` · `## Notes`. Strip all
   bundle framing.
6. `<Name>.stories.tsx` — CSF3 (`Meta`/`StoryObj`), `title: "<Group>/<Name>"`, a Playground + a variants/states
   grid; controls from the contract. (mx.8 enriches later — keep it the basic mx.4 shape now.)

## The gate (run from `mercury/`)

```bash
pnpm --filter "./packages/*" typecheck
pnpm --filter "./packages/*" build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build   # echomq + mobile
pnpm sb:typecheck                                                # authoritative story NO-INVENT gate
pnpm sb:build                                                    # prior homes + 5

# barrel additive (resolve the full set, not a text-diff):
#   0 removed/renamed, +5 names (+ Props)
# idiom + hygiene greps — expect EMPTY:
grep -rnE "style=\{\{[^}]*(rgb|#[0-9a-fA-F]{3})" packages/mercury-ui/src/components/{foundations/Heading,foundations/Text,foundations/Separator,inputs/Label,actions/IconButton}
grep -rnE "#[0-9a-fA-F]{3,8}\b" packages/mercury-ui/src/components/{foundations/Heading,foundations/Text,foundations/Separator,inputs/Label,actions/IconButton} packages/mercury-ui/src/styles/additions.css
grep -rn  "mercAccent\|_lib/accent" packages/mercury-ui/src/components
grep -rniE "check_design_system|pixel-perfect|/design-sync|showcase/" packages/mercury-ui/src/components/{foundations/Heading,foundations/Text,foundations/Separator,inputs/Label,actions/IconButton}
```

## Gotchas

- **Never rename `Divider`** (Separator collision — master invariant). Add `Separator`; leave `Divider` untouched.
- **No `mercAccent` in the library** — `accent` is class-driven.
- **Heading uses DM Mono (`--font-secondary`) at the display sizes** — that is the canon, not a bug.
- **`Textarea`/`TextArea` is NOT in this batch** (it is the mx.7.3 fold) — do not add a `TextArea` here.
- **Commit hygiene:** the bundle `packages/mercury-ds/` stays OUT of the commit; `mercury/…` pathspec only; never
  `git add -A`; never `pnpm -r` (use `--filter`). The Director commits; agents run no git.
- **Framing (propagate into every contract):** no gendered pronouns for agents; no perceptual/interior-state
  verbs; no first-person narration; state each surface as a contract.

## Lessons carried from the prior batch

None — batch 1. The Director fills this slot for mx.7.2 from mx.7.1's as-built (esp. the `accent`-class pattern,
the DM-Mono heading mapping, and any token line added).

## When this batch later ships

Its aaw scope slug is the **dashed** form `mx-7-1` (never `mx.7.1` — a dot split-brains the aaw registry). No team
is created at authoring time.
