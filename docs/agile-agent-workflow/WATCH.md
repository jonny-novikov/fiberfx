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
- The **course home page (`index.html`) is the route manifest.** Its chapter-tile
  links *define* the chapter routes — including deliberate forward-links to
  not-yet-built chapters (`/decomposition`, `/roadmap`, `/spec`, `/brief`,
  `/reliability`, `/portal`). Those **fail the `links` gate by design** until the
  chapter lands; that FAIL on the hub is expected, not actionable drift.
- A0 splits in two: **`/intro`** is the A0 Foundations landing, and **`/what`** is
  the A0.2 "What we are building" module hub holding the three foundation pages
  (`two-layer-model`, `four-artifacts`, `author-operator-loop`, + the
  `two-layer-model-roadmap-anatomy` deep-dive). Those pages migrated `intro/`→`what/`.

## The tools

The repairs live in the `jonnify-cms` validator (built binary
`apps/jonnify-cms/bin/cms`), so they are tested Go, not shell heuristics:

- **`cms check --routes-from <mount>=<dir> FILE…`** — run the nine Apollo gates
  with the section's filesystem routes (derived at `mount`) added to the
  resolvable set, so a folder-routed course can reach a true A+.
- **`cms check --fix …`** — first apply the deterministic, **route-verified**
  repairs (clamp spacing + relink), writing the file, then check. A rewrite is
  applied only when its target is a real route — never invented.
- **`--chapter-alias a0=intro,a1=why`** — during `--fix` relink, map an author's
  positional chapter slug to its semantic dir before route-verifying. (A one-time
  *namespace split* — e.g. `/a0` → `/intro` for the landing but `/a0/<module>` →
  `/what/<module>` — is beyond a single alias and is done as an explicit migration,
  not by the watcher.)
- **`--require-refs`** — also run the tenth, opt-in **refs** gate: every page must
  carry a References section (a `.refs` block). The agile course mandates one on
  every page; the gate is off by default so it never retroactively fails an elixir
  page that predates the convention.

Canonical command (what `reconcile.sh` runs):

```
cms check --fix --routes-from /course/agile-agent-workflow=html/agile-agent-workflow \
  --chapter-alias a0=intro,a1=why --require-refs <files>
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
