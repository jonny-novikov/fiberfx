# B1.4 · The Handle at Its Best — two clauses, discovered

> Route: `/bcs/ideas/ecs-to-bcs/the-handle-at-its-best` (dive 1 of 3, module B1.4). The route-mirror
> source-of-record. Teaches the What of `content/bcs1.4.md`; every quotation verbatim from that chapter's
> record of West 2007 and Weissflog 2018. Build stamp: `BCS0NtOW9jbeSG`.

## Hero

Kicker: `B1.4 · DIVE — THE HANDLE AT ITS BEST`. Title: **The handle, at its best.** Lede — before the chapter
buries the index-handle, it states the modern discipline at full strength: centralized systems own their
allocations, only index-handles cross to the outside world, and spare bits carry a generation counter. Read
with Part I's eyes, that is two of the law's three clauses discovered independently, inside one process.
Heronote — source `content/bcs1.4.md` · What, quoting West 2007 and Weissflog 2018. The argument is
sympathetic by design.

### Interactive 1 — the 2018 discipline (hero)

Weissflog's three rules drawn as an SVG: a system box owning private arrays, with only a handle crossing the
boundary. Select a rule to read its exact statement and the clause it discovered:

- **The sole owner** — move memory management into centralized systems, *"the systems being the sole owner of
  their memory allocations"*. Clause one, discovered: systems own their state.
- **Private arrays** — same-typed items grouped into arrays whose base pointers are system-private. The layout
  is nobody's business outside the system.
- **Handles cross** — only index-handles cross to the outside world, the handle's spare bits carrying a
  generation pattern — a per-slot counter after the November 2018 update — so a stale handle is *usually*
  caught when the slot is reused. Clause two, discovered: only identities cross.

Degrades to this static list.

## §1 · The discipline (#discipline)

Source: `content/bcs1.4.md` · What. The two admissions, quoted by the chapter:

```text
Weissflog 2018   "the systems being the sole owner of their memory allocations"
                 the generation check "isn't waterproof" -- detection, not prevention
West 2007        at five percent CPU cost, "we allowed the components to store
                 pointers to one another" -- the traveling pointer, under frame-rate duress
```

Read with Part I's eyes, the discipline is clause one (systems own their state) and clause two (only
identities cross) discovered independently, enforced by convention inside a single address space.

## §2 · The 2007 confession (#confession)

Even the pattern's founding document records the pressure on clause two: West's 2007 component article reports
that when manager-mediated access cost five percent of CPU, *"we allowed the components to store pointers to
one another"* — the traveling pointer, admitted under frame-rate duress, inside the very article that taught
the industry components. Convention holds until the frame budget objects; nothing in the address space refuses
the crossing.

## §3 · Interactive 2 — the generation counter, exercised (#exercise)

A model of the per-slot generation counter, stepped over a fixed event sequence on one slot. The model gives
the slot two generation bits, so its counter wraps after four values — real engines carry more bits, and the
same wrap. Steps:

1. allocate → handle `h1 = {idx 7, gen 1}`; slot 7 holds gen 1, live.
2. free slot 7 → the slot is reusable; `h1` still circulates.
3. reallocate → handle `h2 = {idx 7, gen 2}`; slot 7 holds gen 2.
4. present `h1` → gen 1 ≠ 2 → stale handle caught. Detection works.
5. reuse the slot until its counter wraps back to gen 1, then present `h1` → gen 1 = 1 → the stale handle is
   admitted. The check *"isn't waterproof"* — collision detection over a reused slot, probabilistic by
   construction.

The readout shows the slot state and the verdict at each step. Degrades to this static list. The chapter's
diagnosis follows in the next dive: detection of reuse is the wrong ambition once the minting law makes reuse
unrepresentable.

## References (#refs)

Sources: Weissflog — Handles are the better pointers
(`https://floooh.github.io/2018/06/17/handles-vs-pointers.html`) · West — Evolve Your Hierarchy
(`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/`).
Related: `/bcs/ideas/ecs-to-bcs` (the B1.4 hub) · `/bcs/ideas` (B1 · Ideas Behind) · `/bcs` (course home).

## Pager

Previous: `/bcs/ideas/ecs-to-bcs` — B1.4 · the hub. Next: `/bcs/ideas/ecs-to-bcs/the-three-deaths` — The Three
Deaths.
