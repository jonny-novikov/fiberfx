# Agile Agent Workflow · operator guide

> The Operator's guide to **writing and managing** the Agile Agent Workflow course — the spec-driven build process,
> end to end. The course is its own exemplar: it is built with the same Author/Operator loop and the same
> roadmap → stories → brief → build → gate chain it teaches. This file is the runbook for the human at the wheel:
> how to plan a chapter, write its stories and brief, dispatch the Author agents, supervise and accept their work,
> keep the four living views honest, and commit. The craft of a single page lives in the `agile-course-writer` skill
> and `docs/agile-agent-workflow/CLAUDE.md`; the *what ships and why* lives in [`aaw.roadmap.md`](aaw.roadmap.md).

## The two roles

- **Operator (you, the human).** Own intent, decomposition, and acceptance. Choose the next chapter/module from the
  roadmap, write its user stories and agent brief, dispatch the Author, review the result, and accept only at
  `STATUS: PASS`. You never hand-write a page; you specify it and judge it.
- **Author (the `agile-expert` Claude agent).** Owns implementation. Turns a module's spec + stories into the built
  pages (a hub + its dives), copies the design system, grounds every example on the real Portal, and self-checks the
  gates. Never decides the goal; never runs git.

> Acceptance is the Operator's job and the hard part. A page that passes the ten gates is **necessary, not
> sufficient** — the gates cannot see content fidelity, an invented Portal API, a duplicate `id`, a broken inline
> script, or the *intended* (vs merely resolving) crumb. Read those by hand.

## The spec chain (write these before any page)

The course is built spec-first. For a chapter `A<N>`:

1. **The roadmap** — [`aaw.roadmap.md`](aaw.roadmap.md), the single course roadmap. Keep its chapter row + milestone +
   status current; it is the plan.
2. **The user stories** — `a<N>.stories.md`: what the learner, the developer, and the Claude Author can each do after
   the chapter/module/dive, as Connextra stories with Given/When/Then and acceptance criteria. This is the *definition
   of done* in human terms.
3. **The agent brief** — `a<N>.llms.md`: the machine-readable brief an Author reads to build a module — routes,
   structure, conventions, the gate command, the cross-link palette, the no-invent guards, the model pages.

Only once the stories and brief exist do you dispatch the Author. Feedback edits the spec (stories/brief/roadmap),
never the built page directly.

## Running a build batch (the loop)

The `/agile-write <chapter> <module> …` command runs this; do it by hand when you need to:

1. **Ground & de-risk.** Build `apps/jonnify-cms/bin/cms`; confirm the server (`:8765`) and the model pages exist;
   read the chapter's stories + brief.
2. **Fan out.** Spawn one `agile-expert` Author per module, in parallel, each given its slice of the brief + stories,
   the model page, the locked cross-links/pager, and the no-git constraint. A chapter's landing must exist first (if
   not, author the landing as the keystone before fanning out its modules).
3. **Adversarially verify** (never trust "all PASS"). Re-gate every page; then check the gate-invisible failure modes:
   `grep` for invented Portal APIs (`Portal\.` not `Portal.ID`, allowing the real F6 surfaces from `docs/elixir/specs/`),
   a **duplicate-`id` scan**, `node --check` on every inline script, clamp spacing, the segmented route-tag, real
   Sources `href="http`, and crumbs/pager that point at the *intended* parent. Crawl: new routes 200, unbuilt siblings
   404. Fix any defect deterministically (do-no-harm), then re-gate.
4. **Relink the landing** (Operator-only). Turn each newly-built module's card `<div class="mod">` → `<a class="mod"
   href="…">`, flip its pill `soon → built`. Re-gate the landing.
5. **Sync the four living views.** The served pages, `agile-agent-workflow.toc.md`, `course-map.md`, and `llms.md` must
   agree — chapter/module status, route links, the dive list, the resume point. View-sync is an **Operator-only step
   after the fan-out** — never delegated into parallel agents (concurrent edits to one file race and clobber).
6. **Commit the batch** (Operator-only). One coherent commit per batch: the new pages + their md sources + the relinked
   landing + the synced views, together, so the views never diverge in history.

## Managing the course

- **The backlog is the roadmap.** The next work is always the roadmap's near-term path. Update the roadmap's status as
  modules land.
- **Numbering.** Chapter `A<N>` → module `A<N>.<MM>` (two-digit) → subpage `A<N>.<MM>.<S>`. A chapter landing may carry
  orientation dives (a recap/overview) as flat leaves; teaching modules nest under the chapter dir.
- **Status discipline (no redundant prose).** Don't write "all built"/"complete" in nav prose — the cards' pills show
  status. Describe structure and the arc.
- **The agents.** New `.claude/agents/*.md` defs are not spawnable until a session reload — try `agile-expert` first,
  fall back to `general-purpose` with a self-contained brief only on a real "agent type not found" error.

## Known hazards (read before a big batch)

- **Concurrent commits during a fan-out** can merge-corrupt an Author's file — duplicating a block (a redeclared `var`,
  a duplicate `id`, an unbalanced container). The cms gates do not parse JS or check duplicate ids, so a corrupt page
  can still "pass" once. **Always run `node --check` + a duplicate-`id` scan + a conflict-marker grep** on the served
  pages after a batch, and resolve any `<<<<<<<`/duplicate-block to the correct version.
- **Clamp spacing is gate-invisible.** `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` must keep the spaces; unspaced is invalid
  CSS dropped to a UA default. `cms check --fix` repairs it.
- **The `links` gate proves resolvability, not intent.** A crumb to `/why` vs `/what` passes either way — read it.
- **Real Sources.** The `refs` gate only checks the block is present; every Sources `<li>` must be a real, vetted
  external link from the registry on the course home — never fabricated.

---

> Part of the jonnify toolkit. The Operator plans and accepts; the Author builds; the gates and the Operator decide
> done. The course is managed the way it is taught.
