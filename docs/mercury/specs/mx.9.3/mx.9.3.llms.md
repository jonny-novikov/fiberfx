# MX.9.3 · build context (the agent brief)

Build context for [`mx.9.3.md`](./mx.9.3.md) (authoritative body) + [`mx.9.3.stories.md`](./mx.9.3.stories.md).
The body wins on any disagreement. **SOLID-FORWARD** — this brief is re-sharpened at the rung's own ship:
the CSF field inventory and the bundle-pattern read below are SHIP-TIME grounding, deliberately not
performed at authoring (2026-07-02).

> **Framing (propagate — do not drop):** no gendered pronouns for agents; no perceptual or interior-state
> verbs; no first-person narration. State each surface as a contract.

## References — read at THIS rung's ship (the re-sharpen list)

1. **This brief + the body** — the contracts and the gate.
2. **The pattern source** — `mercury/packages/mercury-ds/project/showcase/library.jsx`, the `StoryBlock`
   component only (read-only untracked seed; reimplement typed, port nothing verbatim — it is
   JSX-on-`window` for the rejected in-browser loader).
3. **2–3 real as-built story files** — one plain (e.g. `.../actions/Button/Button.stories.tsx`), one
   `storybook/test`-importing (one of the 11), one `render()`-using — to fix the EXACT CSF field set the
   interpreter must read (`component` · `parameters.summary` · per-story `render`/`args` · the ignored
   `play`). The mx.9.2 registry surface (`ShowcaseEntry.loadStories`) is the input type.
4. **The shim contract** — [`../mx.9.1/mx.9.1.md`](../mx.9.1/mx.9.1.md) INV-4 (the six exports; the
   designed loud-failure mode on a 7th name).

**Precondition:** mx.9.2 SHIPPED. **Inherited rulings:** B · C · D · E (epic §7). **Formation: Trio +
deepened verify (ELEVATED)** — the Director's verify includes the liveness sweep and both adversarial
probes, independently re-run.

## Requirements (each traced: story ⇠ requirement ⇢ invariant)

| # | Requirement | Story | Invariant |
|---|---|---|---|
| R-1 | The interpreter parses the CSF module and mounts each story (render-as-component else createElement(component, args)), error-boundaried, name-titled | S-1 | INV-1, INV-3, INV-4 |
| R-2 | The Stories stub is replaced by the wired panel (await loader → loading state → story cards) | S-1 | INV-2, INV-5 |
| R-3 | `play` is never invoked; play-only shim stubs never fire; a stub throw ESCALATES | S-2 | INV-3, INV-2 |
| R-4 | The liveness sweep: all 65 loaders awaited + mounted; the 11 shim importers named in evidence | S-2 | INV-2 |
| R-5 | The two adversarial probes run and revert (7th-name → loud vite failure; throwing render → contained card) | S-3 | INV-2, INV-4 |
| R-6 | Lazy per selection; scope `apps/showcase/src/**`; barrel byte-identical; greps empty | S-4 | INV-5, INV-6 |

## Execution topology (shape, not bytes — re-sharpened at ship)

- **NEW** `src/lib/storyRender.tsx` — `parseCsfModule(mod): { meta, stories: Array<{ name, render?, args? }> }`
  + `<StoryCard>` (error boundary + title + mount) + `<StoriesPanel entry={...}>` (await → map). The
  non-story export filter (e.g. a re-exported helper) is fixed at ship against the real files.
- **EDIT** `src/shell/ComponentPage.tsx` — the Stories stub → `<StoriesPanel>`; the Docs stub stays
  (mx.9.4's).
- **The sweep** — a verify-stage mechanism iterating `REGISTRY` and awaiting every `loadStories()` with
  mount; its FORM (a dev-only route, a temporary harness, or a scripted browser pass) is the implementor's
  call at ship — the CONTRACT is: all 65 pass, the 11 named, evidence recorded in the rung report, and no
  sweep artifact ships in the committed app (a dev-only guard or full removal before gate).
- **The probes** — throwaway files under `packages/mercury-ui/src/components/<group>/__Probe*__/`,
  created → observed → DELETED (transient; the Director re-verifies `packages/**` clean).

## The gate ladder (run from `mercury/` — NEVER `pnpm -r`)

```bash
pnpm --filter "./packages/*" typecheck && pnpm --filter "./packages/*" build   # unchanged
pnpm --filter @mercury/showcase typecheck && pnpm --filter @mercury/showcase build
pnpm --filter "./apps/*" --filter "!@mercury/storybook" build                  # 3 product apps
grep -rnE "from \"@storybook/" apps/showcase/src                               # → empty
grep -rnE "design-sync|DesignSync|@babel/standalone|window\.MercuryUI|_ds_bundle" apps/showcase  # → empty
grep -n "\.play" apps/showcase/src -r                                          # → no call site
# Deepened verify (Director, independent): the 65-module liveness sweep (11 shim files named) ·
# probe (a) 7th-name loud failure · probe (b) contained render throw · lazy two-component navigation ·
# barrel-diff byte-identical.
```

## The prompt (the decisions this spec fixes; the ship re-sharpens the rest)

Replace the mx.9.2 Stories stub with a live panel: a typed reimplementation of the bundle `StoryBlock`
pattern that awaits the registry's `loadStories()`, parses the CSF module (`mod.default` meta; named
exports = stories), mounts `render()` as its own component else `createElement(meta.component,
story.args)`, titles each card by export name, wraps each in an error boundary, and **never touches
`play`**. Prove the mx.9.1 shim LIVE: sweep all 65 modules (the 11 `storybook/test` value-importers named
in the evidence), verify `fn()` handlers no-op silently, and treat any play-only stub throw as an
escalation, never a patch. Run both adversarial probes and revert them. Touch only `apps/showcase/src/**`;
no new dependency; no git; the ladder + deepened verify green before reporting. Re-sharpen this brief at
ship against the real story files + the bundle seed before writing code.
