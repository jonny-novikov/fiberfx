---
name: jonnify-gitignore-repo-wide-trap
description: jonnify root .gitignore has BARE unanchored rules — `.gitignore` (~line 180) AND `bin/` (line 56) — each ignoring that name repo-wide; nested files of those names work locally but never commit. Verify w/ git check-ignore; fix via a ROOT negation
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

**The trap is a CLASS, not one line.** The root `.gitignore` carries multiple **bare, unanchored**
rules that each ignore that *name* everywhere: `.gitignore` (~line 180) AND **`bin/` (line 56)**. Any
nested dir/file matching such a name is silently ignored. Signature: "I added a file and it never shows
as untracked" → run `git check-ignore -v <path>` before assuming it'll commit.

**Why it matters:** (1) 2026-06-28, the codemojex board edge build — a per-app `.gitignore` for
`priv/static/board/` didn't show untracked; `git check-ignore -v` → root `.gitignore:180`; moved the rule
to root (`e0fd3305`). (2) 2026-07-01, the codemojex **frontend-delivery** build — the game's
`mercury/codemojex/apps/game/bin/{edge-deploy.sh, phoenix-modules-build.sh}` (the build + deliver scripts)
are ignored by the bare `bin/:56`, so they can't commit; the fix is a root **negation**
(`!mercury/codemojex/apps/game/bin/`) — a *source* `bin/` must be un-ignored explicitly.
Related: [[codemojex-livereact-render]] · [[env-secret-inspection-safety]].
