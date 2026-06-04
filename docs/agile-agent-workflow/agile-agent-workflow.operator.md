# The Operator's runbook — authoring the Agile Agent Workflow course

This is the **human Operator's** guide to running the course's authoring pipeline. It mirrors the course's own
thesis: the **Operator** (you) supplies judgement, decomposition, and acceptance; the **Author** (a Claude
`agile-expert` agent) supplies fast, well-specified implementation. So this file is the human counterpart to
[`CLAUDE.md`](./CLAUDE.md) — that one briefs the Author, this one briefs you.

> One-line model: **you decide *what* and *whether*; the agents produce *how*; the gates and your review decide
> *done*.** You never hand-write a page; you decompose the chapter, dispatch the agents, and accept the result.

---

## 1. What you own vs. what the agents own

| The Operator (you) | The Author (the `agile-expert` agents) |
|---|---|
| Decide the next batch (which chapter, which modules, which dives) | Author each module: hub + ≥3 dive subpages + md sources |
| Run `/agile-write …` (or fan out by hand) | Copy the design system, write content, build the interactives |
| Review and accept the output (the real work — §4) | Self-gate to `STATUS: PASS` and return a data summary |
| Commit the batch (§5) | **Never** run git; never touch the chapter landing |
| Keep the four living views honest (§3 of CLAUDE.md) | Stay inside their own module dir |

The agents are good but not infallible — they have invented a Portal API and drifted on gate-invisible details
before. **Acceptance is yours.** A page that passes the ten gates is *necessary*, not *sufficient* (see §4).

---

## 2. The toolchain

| Piece | Path | What it is |
|---|---|---|
| The command | `.claude/commands/agile-write.md` → `/agile-write` | Fans out the agents + does the orchestrator-only steps |
| The agent | `.claude/agents/agile-expert.md` | The Author — a thin def that loads the skill |
| The skill | `.claude/skills/agile-course-writer/SKILL.md` | The craft: the ten gates, voice, the interactive contract, anatomy |
| The author guide | `docs/agile-agent-workflow/CLAUDE.md` | What a Claude author must hold (the four views, the gate, the registry) |
| The validator | `apps/jonnify-cms/bin/cms` | The ten gates; the source of truth for routes + passing |
| The local server | `make watch` (port **8765**) | Serves `html/agile-agent-workflow/` live; restarts only on `.go` changes |

`GOWORK=off` is mandatory for any `go` command in this workspace (the `Makefile` exports it for you).

---

## 3. Driving a batch with `/agile-write`

```
/agile-write <chapter-slug> <module-slug>[:dive1,dive2,dive3] [<module-slug>[:dives] …]
```

- **Token 1** = the **chapter** dir slug (`decomposition`, `roadmap`, …) or an `A<N>` number. Its landing must
  already exist — you author its *modules*, not the chapter.
- **Tokens 2…N** = one **module** each. `acceptance` lets the agent design ≥3 dives from the TOC abstract;
  `acceptance:given-when-then,scenarios,executable-spec` pins the dive slugs.

**Examples**

```
# Author the four remaining A2 modules, agents design the dives:
/agile-write decomposition acceptance splitting value-ladder workshop

# Author one module with explicit dive slugs:
/agile-write decomposition acceptance:given-when-then,scenario-tables,executable-spec

# Start a fresh chapter's first modules (its landing must already be built):
/agile-write roadmap agile-distilled xp-small-batches roadmap-anatomy
```

**What the command does, end to end** (you watch; it runs):

1. **Grounds** the batch from `course-map.md` + the TOC + the chapter landing (numbers, titles, abstracts, build order).
2. **De-risks** shared deps once (builds `cms`, checks the server, checks the model pages) so parallel agents don't race.
3. **Locks cross-links** to the model pager convention, then **fans out one agent per module in parallel**.
4. **Adversarially verifies** — re-gates every page itself, greps for invented Portal APIs, checks clamp/route-tag/Sources, crawls routes (200 / unbuilt 404).
5. **Relinks** the chapter landing cards (`div → a`, `soon → built`).
6. **Syncs** the four living views and **reports** — without committing.

Scale to taste: one module token for a single module, or the whole remaining chapter in one line. Each agent runs
~15 minutes; they run concurrently, so a four-module batch is roughly one agent's wall-clock.

---

## 4. Reviewing and accepting (the Operator's real job)

The command's own Step 3 re-gates and crawls, so trust the **gate tally** and **route crawl** it reports. Your
acceptance is about the things a gate cannot judge:

- **Is the content right?** Read one hub and one dive. Does the teaching match the TOC abstract? Is the Portal
  example faithful (the canonical ladder: browse → enrol → open a lesson → track progress)? No invented Portal API
  beyond `Portal.ID` — the report should say the invented-API grep is empty.
- **Do the interactives teach, and are they truthful?** Open the new routes on `http://localhost:8765/…` and click
  through. The readout must reflect a real computation, and the page must still show controls + SVG with JS off.
- **Is the navigation correct, not just resolvable?** The `links` gate proves a link *resolves*, never that it is
  the *intended* one. Confirm crumbs/pager point where they should, and that the relinked landing cards read
  `built`.
- **Voice.** Skim for first person, exclamation marks, or hype words — the gate catches the word list, not tone.

If something is off, say so in plain language ("the `splitting` hero interactive doesn't recompute"); the orchestrator
fixes it deterministically and re-gates. You do not edit pages yourself.

---

## 5. Committing — the batch discipline

**Nothing in this pipeline commits.** The agents are forbidden from running git; the orchestrator leaves everything
in the working tree. You commit the batch out-of-band, once you have accepted it:

```bash
git add html/agile-agent-workflow/<chapter> docs/agile-agent-workflow
git commit -m "feat(agile): <chapter> A<N>.<MM>–A<N>.<MM> — <modules>"
```

A batch is a coherent unit: the new module dirs, their md sources under `docs/.../content/`, the relinked chapter
landing, and the three synced doc views (TOC, `course-map.md`, `llms.md`). Commit them together so the four views
never diverge in history. The tree is expected to go clean between sessions — do not assume work stays staged.

---

## 6. Choosing the next batch

The **resume point lives at the bottom of `.claude/skills/agile-course-writer/references/course-map.md`** — it names
the next gap. As of this writing:

- **A2.04** "Acceptance criteria with Given/When/Then" — the next Part II module (the `invest` module's `story-smells`
  already foreshadows it).
- **A1.05** "Correct by definition" (`/why/correct`) — the lone gap inside chapter A1.

Decompose before you dispatch: skim the TOC (`agile-agent-workflow.toc.md`) section for the chapter, decide the
module slugs and (optionally) the dive arc, then run `/agile-write`. The dependency order in the TOC is the build
order — author the rungs a reader climbs first.

---

## 7. Known gotchas

- **New command / agent not spawnable this session.** `.claude/agents/*.md` and `.claude/commands/*.md` are loaded
  at **session start**. If `/agile-write` doesn't autocomplete or `agile-expert` errors "agent type not found",
  restart the session. The command already falls back to `general-purpose` (with the full self-contained brief) so a
  batch still runs correctly mid-session.
- **The zsh gate trap.** Running the validator by hand, force word-splitting in zsh: `cms check ${=FLAGS} <page>`.
  Unquoted `$FLAGS` does **not** split in zsh (it does in bash), which silently makes every check look failed.
- **Clamp spacing is invisible to the gates.** `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` must keep the spaces around
  `+`/`-`; the unspaced form is invalid CSS dropped to a UA default. `cms check --fix` repairs it.
- **Server staleness.** Content is served live from disk, so a new page is visible on save — but `make watch` only
  restarts on `.go` changes. If a route 404s unexpectedly, confirm the file path matches the route exactly.

---

## 8. Doing it by hand (if the command is unavailable)

The command is just the documented procedure. To run a batch manually: read [`CLAUDE.md`](./CLAUDE.md) §"How a
batch is run", build `cms`, then for each module spawn one agent with `subagent_type: "agile-expert"` (or
`general-purpose` as fallback) given its route, abstract, dive slugs, the model pages, locked pager links, the gate
command, and the no-git constraint. Then relink the landing, re-gate, sync the four views, and commit. The command
exists so you never have to remember all of that — but the steps are the same.

---

> Part of the jonnify toolkit. The roadmap plans; the spec defines and proves; the Author builds; the gates and the
> Operator accept.
