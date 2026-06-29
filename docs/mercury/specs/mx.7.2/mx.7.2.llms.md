# mx.7.2 — build context (batch 2: simple feedback / display + layout)

Working notes for [`mx.7.2.md`](./mx.7.2.md). Root = `mercury/`. The body is authoritative. **NO-INVENT** /
**edit ONLY** `packages/mercury-ui/src/` (the 10 folders + barrel + `additions.css`) + `docs/mercury/specs/mx.7.2/`.
The bundle `packages/mercury-ds/` is **read-only**.

## Inherited from the epic + mx.7.1 (read first)

[`../mx.7/mx.7.md`](../mx.7/mx.7.md) §4/§5 (cross-batch forks + shared contract) and
[`../mx.7.1/mx.7.1.llms.md`](../mx.7.1/mx.7.1.llms.md) (the translation recipe + the `accent`-class pattern,
established and re-used here). Do not re-decide the cross-batch forks.

## References (read in order)

1. [`mx.7.2.md`](./mx.7.2.md) — the body (§3 surfaces + §4 translation notes are the build target).
2. The bundle prototypes (prop-surface seed):
   `mercury-ds/project/components/{feedback/Callout,feedback/Spinner,feedback/Skeleton,data-display/Blockquote,
   data-display/DataList,data-display/Code,data-display/Kbd,layout/AspectRatio,layout/Collapsible,layout/ScrollArea}/`.
3. Live idiom exemplars: `Divider.tsx` (rule), `Alert.tsx` (the tone families `Callout` mirrors — `feedback/Alert`),
   `Accordion.tsx` (`navigation/Accordion` — the disclosure `Collapsible` is distinct from), and the live `Icon`
   (`foundations/Icon` — the glyph set `Collapsible` composes; **use a real glyph name**).
4. Styles: `src/styles/additions.css` (+ the new `.mx-*` rules + accent ramps), `tokens.css` (the `--bg-info`/
   `--bg-caution`/… semantic families `Callout` maps to; the radius scale; the DM Mono `--font-secondary`).

## Ground facts (re-probe)

- **The `accent`-class pattern (from mx.7.1):** `Callout`/`Spinner`/`Blockquote`/`Code`/`Collapsible` realize
  `accent` via `.mx-<name>--accent-<id>` classes reading the `--<ramp>-9/11` families — **never import
  `mercAccent`**.
- **`Callout` tone map:** `info→--bg-info`, `brand→--bg-brand-subtle`, `positive→--bg-positive`,
  `caution→--bg-caution`, `negative→--bg-negative`, `discovery→--bg-discovery` (+ matching `--fg-*`/`--border-*`);
  `variant` soft/surface/outline = fill/border treatment. All families verified in `tokens.css`.
- **`Collapsible` composes the live `Icon`** — `import { Icon } from "../../foundations/Icon"` (relative);
  the chevron glyph must be a **real** name in the live Icon set (verify; do not invent). Controlled
  (`open`/`onOpenChange`) + uncontrolled (`defaultOpen`); guard React-19 nullable `useRef().current`.
- **`ScrollArea`** already uses a className in the bundle (`merc-sa`) — translate to `.mx-scrollarea` + a webkit
  scrollbar rule reading tokens. `AspectRatio`/`Skeleton`/`ScrollArea` use **dynamic non-color** inline styles
  (`aspect-ratio`, `maxHeight`, computed sizes) — allowed; the INV-2 grep flags color literals only.
- **`sb:typecheck`** is the authoritative story NO-INVENT gate (library `tsc` excludes stories, D-9).

## The file tree (create exactly these)

```
packages/mercury-ui/src/components/feedback/Callout/{Callout.tsx,index.ts,Callout.prompt.md,Callout.stories.tsx}
packages/mercury-ui/src/components/feedback/Spinner/{…}
packages/mercury-ui/src/components/feedback/Skeleton/{…}
packages/mercury-ui/src/components/data-display/Blockquote/{…}
packages/mercury-ui/src/components/data-display/DataList/{…}
packages/mercury-ui/src/components/data-display/Code/{…}
packages/mercury-ui/src/components/data-display/Kbd/{…}
packages/mercury-ui/src/components/layout/AspectRatio/{…}
packages/mercury-ui/src/components/layout/Collapsible/{…}
packages/mercury-ui/src/components/layout/ScrollArea/{…}
packages/mercury-ui/src/index.ts                 # +10 barrel lines (additive)
packages/mercury-ui/src/styles/additions.css     # +10 .mx-* rule blocks
```

## The translation recipe + the gate

Same recipe + gate as [`../mx.7.1/mx.7.1.llms.md`](../mx.7.1/mx.7.1.llms.md) (read it), with the dir list above and
the `sb:build` home delta **+10**. The greps target the 10 new dirs.

## Gotchas

- **`Callout` is NOT `Alert`; `Collapsible` is NOT `Accordion`** — add net-new, cross-link, leave the existing
  exports untouched (master invariant).
- **No `mercAccent` in the library**; **real Icon glyph** in `Collapsible`; **no color literal** in inline styles
  (dynamic ratio/size inline is fine).
- **Commit hygiene:** bundle out of the commit; `mercury/…` pathspec; no `git add -A`; no `pnpm -r`. Director commits.
- **Framing (propagate into contracts):** no gendered pronouns / perceptual verbs / first-person; contracts state
  pre/post conditions.

## Lessons carried from mx.7.1

The Director fills this at release — expected: the `.mx-*--accent-<id>` ramp pattern (re-used by 5 of these 10),
the DM-Mono mapping (`Code` reuses `--font-secondary`), and whether the DM Sans 600 line was added in mx.7.1
(reuse it; do not re-add).

## When this batch later ships

aaw scope slug = dashed `mx-7-2` (never `mx.7.2`). No team at authoring time.
