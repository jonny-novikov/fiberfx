# References watcher — `watch_refs.sh`

Monitors the Elixir course pages and keeps references current as new pages are added.

## What it does

Polls `elixir/` recursively for **new** `*.html` pages. On each new page:

1. **(always, safe)** regenerates `docs/elixir/kb/elixir-references.md` and re-mirrors the offline copies (`fetch_refs.py`).
2. **(REFS_AI=1 only)** spawns a **scoped `claude -p` agent** that, for that page's module, deep-researches references if the module has none yet, then inserts a gated **References** block into the page — validated with `cms check` (must end A+).

## Why you start it (not the assistant)

Claude Code's safety classifier blocks the assistant from auto-launching an unattended process that spawns headless agents with Bash + file-edit. **Running it yourself is the authorization.** In a Claude Code session you can prefix with `!`.

## Start / manage

```bash
# autonomous deep-research mode (what you authorized)
REFS_AI=1 docs/elixir/references/watch_refs.sh start

docs/elixir/references/watch_refs.sh status     # running? counts, AI runs/last hour
docs/elixir/references/watch_refs.sh stop        # kill switch
docs/elixir/references/watch_refs.sh queue       # pages deferred (throttle / sync mode)
tail -f docs/elixir/references/watch.log         # live activity
```

On first start the current **41 pages are baselined** as known (not reprocessed); only pages added *afterward* trigger work.

## Modes & tunables (env at start)

| Var | Default | Meaning |
|---|---|---|
| `REFS_AI` | `0` | `1` = autonomous (spawn `claude` per new page). `0` = sync bibliography+mirror and **queue** the page (no AI). |
| `INTERVAL` | `20` | poll seconds |
| `MAX_AI_PER_HOUR` | `12` | agent-run throttle; overflow → queue |
| `AI_TIMEOUT` | `1200` | per-page agent watchdog (seconds) |

## Cost & safety

- The agent run is **scoped to one page**, granted an **ephemeral** `--allowedTools` allowlist (`Read,Edit,Write,Grep,Glob,WebSearch,WebFetch,Skill,Bash`) + `--permission-mode acceptEdits` + `--max-turns 60`. No project-settings change; **no `--dangerously-skip-permissions`**.
- **Loop-safe:** detection diffs page *presence*, so the agent's own edits (modifications) never retrigger it; `references/`, `drafts/`, and `.part` files are excluded.
- **Bounded cost:** references are pre-curated and verified for all 56 modules, so the deep-research path fires mainly for genuinely *new topics*; known modules are a cheap sync + integrate. The per-hour throttle caps a bulk-add burst (overflow waits in the queue).
- **Stop anytime:** `watch_refs.sh stop`.

## Persistence across reboots (optional, deliberate)

Not installed by default — this is an autonomous AI process. To survive reboots, wrap `watch_refs.sh start` in a `~/Library/LaunchAgents/*.plist` and `launchctl load` it. Enable only when you want it always-on.
