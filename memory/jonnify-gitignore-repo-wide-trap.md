---
name: jonnify-gitignore-repo-wide-trap
description: jonnify root .gitignore has a bare `.gitignore` rule (line ~180) that ignores EVERY per-app/nested .gitignore repo-wide — add ignores to the ROOT registry, not a per-app file
metadata:
  node_type: memory
  type: project
  originSessionId: 466fdd7e-18b5-4685-aa04-c820181e763a
---

The jonnify repo-root `.gitignore` contains a **bare `.gitignore` line** (~line 180, after
`.svelte-kit/`). Because it is unanchored, it ignores **every `.gitignore` file repo-wide** — any
new per-app or nested `.gitignore` you create is silently ignored: it works LOCALLY (git honors
untracked ignore files) but never commits, so CI / fresh clones don't get it. The root `.gitignore`
stays tracked only because it predates the rule (gitignore never untracks an already-tracked file).

**How to apply:** add new ignore rules to the **root `.gitignore`** (the single tracked ignore
registry — it already carries app-specific paths like `node/codemoji-design/figma/`, `apps/dashboard/build/`,
the investex cert negation). Do NOT create a per-app `.gitignore` (e.g. `echo/apps/<app>/.gitignore`)
expecting it to ship — it won't. The root file's own Elixir/Phoenix comment *advises* per-app
`.gitignore` for `priv/static` etc., but that advice is unfollowable given the bare rule. Verify any
new ignore with `git check-ignore -v <path>`. If a per-app `.gitignore` is genuinely required, it
needs `git add -f` (against the grain — prefer root).

**Why it matters:** caught 2026-06-28 fixing the codemojex board edge build — tried to add a per-app
`.gitignore` for the edge-delivered `priv/static/board/` artifact, it didn't show as untracked,
`git check-ignore -v` pointed at root `.gitignore:180`. Moved the rule to root (commit `e0fd3305`).
Related: [[codemojex-livereact-render]] · [[env-secret-inspection-safety]].
