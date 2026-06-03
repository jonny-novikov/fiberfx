# agile-watcher — keep `html/agile-agent-workflow/` conformant

A two-tier reconciliation loop for the **Agile Agent Workflow** course
(`html/agile-agent-workflow/`, served at **`/course/agile-agent-workflow`**),
modelled on the elixir references watcher (`docs/elixir/references/`):

1. **`watch.sh` — the detector (cheap, always-on, READ-ONLY).** Polls the
   section tree and emits one verdict line per new/changed page. It never edits,
   so it cannot race a concurrent IDE edit, and because a conformed page is A+
   (no drift) it never re-signals its own fix.
2. **`reconcile.sh` — the actuator (on-signal).** Applies the deterministic,
   route-verified repairs and re-grades. Run by the on-signal conformance Agent,
   or by hand.

## Canonical scheme

- URL mount: **`/course/agile-agent-workflow`** (re-mounted in `main.go`; the bare
  `/agile-agent-workflow` no longer resolves).
- Chapter segment = the **on-disk directory name** (semantic, e.g. `why`), so the
  URL tree below the mount mirrors the filesystem. Author positional slugs
  (`a0`, `a1`) are swapped to the dir name only when that yields a real route.

## The tools

The repairs live in the `jonnify-cms` validator (built binary
`apps/jonnify-cms/bin/cms`), so they are tested Go, not shell heuristics:

- **`cms check --routes-from <mount>=<dir> FILE…`** — run the nine Apollo gates
  with the section's filesystem routes (derived at `mount`) added to the
  resolvable set, so a folder-routed course can reach a true A+.
- **`cms check --fix …`** — first apply the deterministic, **route-verified**
  repairs (clamp spacing + relink), writing the file, then check. A rewrite is
  applied only when its target is a real route — never invented.

Canonical command (what `reconcile.sh` runs):

```
cms check --fix --routes-from /course/agile-agent-workflow=html/agile-agent-workflow <files>
```

## Output contract (`watch.sh`)

```
BASELINE <n> pages armed                    once, at startup (also lists pre-existing DRIFT)
DRIFT    <relpath> status=<S> clamps=<n> svg=<n>   actionable — spawn the conformance Agent
CLEAN    <relpath> status=PASS clamps=0 svg=<n>    informational — a changed page is now A+
```

`status` is the route-aware `cms check` verdict (authoritative for links);
`clamps` counts spaceless-calc bugs; `svg=0` flags a missing hero figure.
Silence means no new or changed files.

## Run

```
bash docs/agile-agent-workflow/watch.sh        # detector (foreground; Ctrl-C to stop)
bash docs/agile-agent-workflow/reconcile.sh     # fix + grade every page
bash docs/agile-agent-workflow/reconcile.sh html/agile-agent-workflow/why/four-artifacts.html  # one page
```

In a Claude session the detector is armed as a persistent **Monitor** named
`agile-watcher`; each `DRIFT` line is the signal to spawn the conformance Agent
(relink + clamp-fix + verify, following the exemplar
`html/agile-agent-workflow/why/four-artifacts.html`). The watcher itself never
edits — all editing is done by the spawned Agent.

## Env overrides

`REPO`, `SECTION`, `MOUNT`, `CMS`, `INTERVAL` (poll seconds, default 5),
`STATE` (snapshot file, default `/tmp/agile-watch.state`).
