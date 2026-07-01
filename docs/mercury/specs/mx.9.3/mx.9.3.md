# MX.9.3 · The live-stories surface — the CSF interpreter + the shim liveness gate

> **Status: 📐 SOLID-FORWARD (authored 2026-07-02 in the mx.9 split; re-sharpened at its own ship).** The
> third sub-rung of the [`../mx.9/mx.9.md`](../mx.9/mx.9.md) SUB-EPIC — **hard-gates on
> [mx.9.2](../mx.9.2/mx.9.2.md)** (the registry + the Stories stub it fills). mx.9.3 lands the epic's K-3:
> a small **CSF interpreter** (the bundle `StoryBlock` pattern, reimplemented typed) rendering each
> component's live `*.stories.tsx` in the Stories panel — **and it is the rung where the mx.9.1
> `storybook/test` shim must prove its liveness**: this is the first rung that executes story modules.
> Pattern source at ship: `packages/mercury-ds/project/showcase/library.jsx` (read-only untracked seed —
> its exact read happens at THIS rung's ship, per the re-sharpen).
>
> **Risk: ELEVATED · formation Trio + deepened verify** (the shim-liveness sweep, the no-Storybook-runtime
> re-proof, and the adversarial probes below are the deepening — a story-module regression here is
> silent-at-build and loud-at-runtime, the worst kind). The Operator may override at ship. **Inherited
> rulings (2026-07-02, epic §7 — closed):** B · C · D · E.

Parent epic: [`../mx.9/mx.9.md`](../mx.9/mx.9.md) · prior rung: [`../mx.9.2/mx.9.2.md`](../mx.9.2/mx.9.2.md)
· the shim contract: [`../mx.9.1/mx.9.1.md`](../mx.9.1/mx.9.1.md) (INV-4/INV-5) · canon:
[`../../mercury.design.md`](../../mercury.design.md) · acceptance:
[`mx.9.3.stories.md`](./mx.9.3.stories.md) · build context: [`mx.9.3.llms.md`](./mx.9.3.llms.md).

## 0 · The slice

The epic's K-3 (the story renderer) realizing epic S-5. The mx.9.2 Stories stub becomes live: selecting a
component and opening its Stories tab lazy-loads that component's `*.stories.tsx` module (the registry's
`loadStories` loader — first invoked HERE) and renders its named-export stories through a small
interpreter — **no Storybook runtime**. Two loads bear the risk: (a) the **module graph** — 11 of the 65
story files VALUE-import `storybook/test`, resolved by the mx.9.1 shim; this rung's gate proves the shim
LIVE across all 65 modules, not just present; (b) the **execution discipline** — the interpreter reads
`render`/`args` only and never touches `play` (interaction tests stay the Storybook host's job).

## 1 · Goal

Every component's Stories tab renders its live stories from source: the interpreter reads the CSF module
(`mod.default` = the meta — `component`, optional `parameters.summary`; the named exports = the stories),
mounts `story.render()` as its own component where present, else
`createElement(meta.component, story.args)`, each story in its own error boundary with its export name as
the card title. All **65** story modules (the 2026-07-02 count — DERIVED) load cleanly through the shim;
`fn()`-produced `args` handlers are callable no-ops; no play-only stub ever fires during render; grep finds
no value import from `@storybook/*` anywhere in `apps/showcase/src/**`.

## 2 · Rationale (5W)

- **Why.** The Stories surface is the showcase's live half of the one-source law (epic §0): the same
  co-located `*.stories.tsx` the Storybook host renders with its runtime, rendered here by a ~100-line
  interpreter — one source, two renderers. It is also the only place the shim's design can be PROVEN: a
  gate that never executes a story module would satisfy the shim's letter while proving nothing.
- **What.** The interpreter module + the wired Stories panel + the liveness sweep + the two adversarial
  probes (the deepened verify).
- **Who.** *Built by* the implementor to [`mx.9.3.llms.md`](./mx.9.3.llms.md); *verified by* the Director
  with the deepened-verify checklist; *consumed by* every browser of the library and by mx.9.5 (the
  dual-theme acceptance renders THROUGH this surface).
- **When.** After mx.9.2 (the registry + stub). Parallel-safe with mx.9.4 (different stub, different
  loader). Before mx.9.5 (the closer re-runs this surface whole).
- **Where.** `mercury/apps/showcase/src/**` only.

## 3 · Invariants (runnable checks)

- **INV-1 · The render path is live source, no Storybook runtime** (epic INV-5 render half + K-3). The
  interpreter consumes the CSF module shape directly; the story files' `import type { Meta, StoryObj }
  from "@storybook/react-vite"` stays type-only (erased at build). Checks:
  `grep -rnE "from \"@storybook/" apps/showcase/src` → empty (no value OR type import in app code);
  `grep -rn "import type" packages/mercury-ui/src/components/**/[A-Z]*.stories.tsx | grep "@storybook"`
  confirms the type-only shape unchanged (re-proof, not assumption); the built app resolves no
  `@storybook/*` package (bundle-analysis or resolve-trace at ship).
- **INV-2 · THE SHIM LIVENESS GATE — all 65 story modules load through the mx.9.1 shim.** A present
  precondition MUST exercise its gate with a positive proof: the verify step iterates the **whole
  registry** and awaits every `loadStories()` — every one of the 65 modules (DERIVED count) resolves and
  its stories mount; the **11 `storybook/test` value-importers are the proof surface** (each must appear
  in the sweep's pass list by name). `fn()` returns land in `args` as event handlers — clicking a rendered
  story's control fires the no-op silently (no throw, no console error). **If a play-only stub
  (`expect`/`userEvent`/`fireEvent`/`waitFor`/`within`) throws during render, that IS the gate catching a
  broken assumption ("the showcase never runs play") — ESCALATE to the Director; never patch the shim or
  the interpreter to swallow it.**
- **INV-3 · `play` is never executed.** The interpreter reads `meta` + each story's `render`/`args` and
  **never invokes `story.play`**. Check: `grep -n "\.play" apps/showcase/src` → the only permitted hits
  are a comment or a deliberate exclusion line, never a call.
- **INV-4 · Per-story error boundaries.** One broken story renders an inline error card (the story name +
  the message); its siblings and the shell render on. Check: the broken-story adversarial probe (§4 K-4).
- **INV-5 · Lazy per selection.** Only the selected component's story module loads (the mx.9.2 lazy
  discipline carried forward — navigation to component A must not load component B's module). Observable:
  the dev network panel on a two-component navigation.
- **INV-6 · Scope + barrel.** The diff is `apps/showcase/src/**` only; `packages/**` untouched; the
  barrel byte-identical (Director-run diff); the consume-down greps stay empty.

## 4 · Key deliverables

| # | Deliverable | Acceptance |
|---|---|---|
| K-1 | The **interpreter** (`src/lib/storyRender.tsx` or sibling) — parse the CSF module (`mod.default` meta; named exports = stories; ignore non-story exports), mount `render()`-as-component else `createElement(meta.component, story.args)`, each in an error boundary, titled by export name | S-1; INV-1, INV-3, INV-4 |
| K-2 | The **Stories panel wired** — the mx.9.2 stub replaced: `loadStories()` awaited with a loading state, the interpreter renders the story cards | S-1; INV-2, INV-5 |
| K-3 | The **liveness sweep** — a verify-stage pass over the whole registry (all 65 loaders awaited + mounted; the 11 shim-dependent files named in the pass evidence) | S-2; INV-2 |
| K-4 | The **adversarial probes** (deepened verify): (a) a throwaway story importing a **7th** `storybook/test` name fails **LOUD at vite import-analysis** — the shim's designed failure mode (mx.9.1 shim header; the fix is one shim export, an escalation not a patch); (b) a throwaway story whose `render()` throws renders an inline error card while siblings render (revert both probes) | S-3; INV-2, INV-4 |

## 5 · The method (build order)

1. **Write the interpreter** to the K-1 contract (the exact CSF field set — `component`,
   `parameters.summary`, `render`, `args`, the `play` exclusion — re-verified at ship against 2–3 real
   as-built story files + the bundle `library.jsx` `StoryBlock`, read THEN).
2. **Wire the Stories panel** (replace the stub; loading state; story cards).
3. **Run the liveness sweep** (K-3) and record the 65-module pass with the 11 shim files named.
4. **Run the adversarial probes** (K-4), revert the throwaway files.
5. **Run the gate ladder** (brief §Gate) + the deepened-verify checklist; the Director re-runs
   independently.

## 6 · Dependencies

- **Hard-gates on:** [mx.9.2](../mx.9.2/mx.9.2.md) (the registry + the stub). The mx.9.1 shim is the
  load-bearing precondition this rung proves.
- **Unblocks:** mx.9.5 (the dual-theme acceptance renders through this surface). Independent of mx.9.4.
- **Touches:** `mercury/apps/showcase/src/**` only (probe files transiently excepted, reverted).

> **Framing (propagate):** no gendered pronouns for agents; no perceptual or interior-state verbs; no
> first-person narration. Each surface is a contract; acceptance is at the boundary.
