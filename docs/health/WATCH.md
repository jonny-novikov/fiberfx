# Health course watcher — `watch_health.sh`

Monitors the Health course pages and keeps them **consistent and cross-linked** as new modules are added. Sibling of the Elixir references watcher (`docs/elixir/references/watch_refs.sh`), same daemon mechanics.

## What it does

Polls `health/` recursively for **new** module `*.html` pages (chapter hubs `index.html`, hidden dirs, and `*.part` files are ignored). On each new page:

1. **(always, safe)** records the page and logs it.
2. **(`HEALTH_AI=1` only)** spawns a **scoped headless `claude -p` agent** that, for that one page:
   - **Consistency** — ensures the standard module anatomy (topbar + breadcrumb + back-link, hero, numbered sections, takeaway, a themed **«Источники»** block, prev/next nav), matching the chapter exemplar.
   - **References** — if missing, inserts the **Chapter-5 house format** (`health/risk/bayes.html`): a boxed `.references` card with `<div class="ref-title">`, an `<ol class="ref-list">`, and Google-Scholar **«поиск источника»** links, themed to the chapter colour — citations taken from `docs/health/health-references.md`.
   - **Cross-linking** — unlocks the prev module's "next" card to point here, wires this page's "prev", makes the parent chapter-hub tile a live link, and applies the design-doc "Сквозные ссылки" cross-references (only to pages that exist).
   - **Validate** — dependency-light pre-flight (one references block, balanced `$` + no forbidden chars inside math, internal links resolve). Deeper DOM checks are available via `docs/validator/` if a suite is warranted.

The agent edits **only** the new page, its immediate prev/next neighbours, and the chapter hub.

## Why you start it (not the assistant)

Claude Code's safety classifier blocks the assistant from auto-launching an unattended process that spawns headless agents with Bash + file-edit. **Running it yourself is the authorization.** In a Claude Code session, prefix with `!`.

## Start / manage

```bash
# autonomous consistency+cross-link mode (what you authorize by running it)
HEALTH_AI=1 docs/health/watch_health.sh start

docs/health/watch_health.sh status     # running? known/processed/queued counts, AI runs/last hour
docs/health/watch_health.sh stop        # kill switch
docs/health/watch_health.sh queue       # pages deferred (throttle / sync mode)
docs/health/watch_health.sh once         # one manual scan now
tail -f docs/health/watch.log            # live activity
```

On first start the current module pages are **baselined** as known (not reprocessed); only pages added *afterward* trigger work.

## Modes & tunables (env at start)

| Var | Default | Meaning |
|---|---|---|
| `HEALTH_AI` | `0` | `1` = autonomous (spawn `claude` per new page). `0` = detect + **queue** the page (no AI). |
| `INTERVAL` | `30` | poll seconds |
| `MAX_AI_PER_HOUR` | `10` | agent-run throttle; overflow → queue |
| `AI_TIMEOUT` | `1200` | per-page agent watchdog (seconds) |

## Cost & safety

- The agent run is **scoped to one page**, granted an **ephemeral** `--allowedTools` allowlist (`Read,Edit,Write,Grep,Glob,WebSearch,WebFetch,Skill,Bash`) + `--permission-mode acceptEdits` + `--max-turns 60`. No project-settings change; **no `--dangerously-skip-permissions`**.
- **Loop-safe:** detection diffs page *presence*, so the agent's own edits (modifications) — and the neighbour/hub edits it makes — never retrigger it; chapter hubs (`index.html`), hidden dirs, and `*.part` files are excluded.
- **Concurrency:** the course is built by hand ~2 modules per session; the watcher is a safety net for the cross-linking that the manual pace easily misses (e.g. unlocking the previous module's "next" card — a real past defect). It fires on *completed* new files; the per-hour throttle caps any bulk-add burst (overflow waits in the queue).
- **Bounded cost:** all module citations are pre-curated in `health-references.md`, so the agent integrates known references (cheap) rather than researching; it spawns at most `MAX_AI_PER_HOUR` agents/hour.
- **Stop anytime:** `watch_health.sh stop`.

## Scope notes

- **Quizzes are out of scope** — the `.quiz` component is a separate, deliberate manual pass (see `health-status.md`); the watcher does not add quizzes.
- **Chapter hubs** (`index.html`) are hand-curated and never trigger the watcher; a new module's agent updates the (existing) hub tile as a side-effect.
- The watcher acts on **new** pages only. Reconciling the **existing** 32-module references retrofit to the Chapter-5 house format is a separate one-time pass (the retrofit currently uses a plain-text minimalist list; Chapter 5 uses the boxed card + Scholar links documented above).

## Persistence across reboots (optional, deliberate)

Not installed by default — this is an autonomous AI process. To survive reboots, wrap `watch_health.sh start` in a `~/Library/LaunchAgents/*.plist` and `launchctl load` it. Enable only when you want it always-on.
