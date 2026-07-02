---
description: >-
  echo-courses-ship — ship ONE spec-driven rung of the echo-courses program (the Echo v5 courses server at
  go/echo-courses that rebuilds jonnify.fly.dev/courses) end to end through the x-mode lead-team,
  Director-supervised, to scoped LAW-4 commits. It is /x-mode with the echo-courses context pre-loaded: it adds
  nothing to the laws — it binds them to go/ work (the generic venus/mars charters, no echo_mq-* skills), the go/
  gate ladder (GOWORK=off build/vet/test + gofmt + a running-binary smoke, NOT Valkey/conformance/mix), the
  vendored-Echo-v5.2.0 law (replace => ../echo), and the URL/visual parity gates. The INPUT is the rung's
  docs/echo_courses/echo-courses.<N>.prompt.md runbook + its spec; the canon is the single
  docs/echo_courses/echo-courses.roadmap.md. Triggers: "ship ec.1", "echo-courses-ship ec.4", "run/launch the
  ec.2 pipeline". Do NOT use /echo-mq-ship (that pre-loads the Valkey/conformance/branded-id context), the
  *-course-writer skills, or generic documents.
argument-hint: <rung> (ec.1 … ec.6)  ·  empty (the next unshipped rung per the roadmap)
model: fable
---

# /echo-courses-ship — ship an echo-courses rung via the supervised lead-team

Ship ONE spec-driven rung of the **echo-courses program** — the Echo v5 server at `go/echo-courses/` that
rebuilds the published `jonnify.fly.dev/courses` site from a catalog + content (rungs `ec.1`–`ec.6`) — end to
end through the x-mode lead-team, Director-supervised, to one-or-more **scoped LAW-4 commits**. It is **`/x-mode`
with the echo-courses context pre-loaded**: it adds nothing to the laws — it binds them to `go/` work so the run
does not re-derive them.

**It is a binding layer, not a re-implementation.** Defer to the sources of truth:

1. **`.claude/commands/x.md` + the `/x-mode` skill** — the LAWS (CLAUDE_LAWS 1/1a/2/3/4), the pipeline (Venus
   strawman/reconcile + Arms → Director rules the Arms via `AskUserQuestion` → Mars build + self-verify →
   Director verify → Mars-2 harden → Director ship; Apollo mentors after a high-risk ship, out of band), the §5
   spawn protocol, the §6 audit tools, the §10 commit rules. **Read the `/x-mode` skill first** — everything in
   it applies; the deltas below are the echo-courses binding.
2. **`go/CLAUDE.md`** — the `go/` workspace build guide: the gate commands, the **`GOWORK=off` rule**, the
   standalone-tool convention. echo-courses is a **standalone tool** (not a `go.work` member), like `jonnify-cms`.
3. **the rung's spec** — `docs/echo_courses/echo-courses.<N>.md` (authoritative) + its `.prompt.md` (the
   authoritative scope for the run) + the single roadmap `docs/echo_courses/echo-courses.roadmap.md`.

## Arguments & scope

```
$ARGUMENTS
```

- **A RUNG** — `ec.1` … `ec.6` → ship that rung (the default). Internally the aaw `scope` is the **dashed**
  slug `ec-1` … `ec-6` (NO dots — `tool_x_*` / `TeamCreate` require `^[a-z0-9][a-z0-9-]*$`).
- **Empty** → read the roadmap §5 status line and ship the next **unshipped** rung in program order; if that is
  ambiguous, ask in plain text (do not guess a large scope).

## What is different from a generic /x-mode run (the echo-courses binding)

- **The team is GENERIC, not project-specialized.** There are no `echo-courses-*` skills. Spawn each peer
  `subagent_type: "general-purpose"` and adopt its `.claude/agents/<role>.md` charter (`venus` =
  reconcile/author the triad; `mars` = build to the brief, edits code+tests not the spec). The peers self-register
  via `mcp__aaw__agent_register` from their own context (LAW-1; no narrated spawns). This command's "## The
  echo-courses facts" block below is the pre-loaded context they would otherwise re-derive.
- **The boundary is `go/echo-courses`** (+ the vendored `go/echo`, which is a **read-only dependency** — vendored
  from, never edited). No third module; the Elixir umbrella `echo/`, the agent-OS modules, and the other
  standalone tools are out of bounds.
- **The gate ladder is the `go/` one (`go/CLAUDE.md` §3), NOT `mix`/Valkey/conformance.** Hold each stage
  against it, run **`GOWORK=off`** from the module dir (`make gate` is the one-shot):
  ```bash
  cd go/echo-courses
  GOWORK=off go mod tidy && GOWORK=off go build ./... && GOWORK=off go vet ./... \
    && GOWORK=off go test ./... && gofmt -l .            # gofmt prints nothing
  # running-binary smoke (every rung from ec.1):
  GOWORK=off go build -o bin/server ./cmd/server; ADDR=:<port> ./bin/server &
  #   /healthz -> 200 · a /static asset -> 200 · kill -TERM -> exit 0 (graceful, not 143)
  ```
  From **ec.4** add the **URL-parity battery** (every published path → 200 + the right course) and a **link
  check** over the rendered pages; from **ec.5** add the visual/SEO parity checks.
- **The vendored-Echo law (load-bearing).** Echo **v5** has no published release: the framework is vendored at
  `go/echo` (the **v5.2.0** snapshot, `module github.com/labstack/echo/v5`) and consumed via
  `replace github.com/labstack/echo/v5 => ../echo`. Built `GOWORK=off`; not a `go.work` member. **The repo cannot
  build echo-courses unless `go/echo` is in version control**, so the first ship that introduces the module
  commits `go/echo` as its own concern (see LAW-4 below). Treat `go/echo` as read-only.
- **The v5 API facts (NO-INVENT — do not re-derive, confirm new surface against `go/echo` source):** `Context`
  is a struct (`*echo.Context`), not an interface; graceful shutdown is
  `echo.StartConfig{Address, GracefulTimeout}.Start(ctx, e)` driven by `signal.NotifyContext` cancellation —
  there is **no `e.Shutdown`**; the request logger is `middleware.RequestLogger()`; the `Renderer` interface is
  `Render(c *echo.Context, w io.Writer, name string, data any) error` (the `*Context` is **first**; `echo.TemplateRenderer`
  already implements it over `html/template`).
- **The parity gates bind from ec.4** (roadmap §8): URL parity (every published path resolves to the right
  course), visual parity (the jonnify design system; header `jonnify · courses`, footer `(с) jonnify`), fail-fast
  (templates + content parse at boot), the **catalog is the single source**, no broken links, Echo v5 idioms.
- **The risk tier decides the verify depth + formation** (the `.prompt.md`'s declared tier): `ec.1`–`ec.5` are
  **NORMAL** → the Director's solo verify is the floor, **no Apollo** (`ec.4` is **NORMAL+** — the URL-parity
  battery is mandatory in verify). **`ec.6` (the live-domain Fly cutover) is HIGH** → Apollo is mandatory, and the
  verify deepens: the deployed app serves **every published path** before any traffic moves, and the rollback is
  proven by a single documented step.
- **Right-size the formation.** If the rung's build already exists and is green (a right-sized bootstrap — e.g.
  `ec.1` was built directly), Stages 1–2 are **already done**: the run collapses to the Director's **independent
  verify + the scoped commits**. Do not re-spawn a build team for built-and-green code (rigor is constant; only
  ceremony scales).

## The echo-courses facts (the pre-loaded context for the peers)

- **Published ground truth** (roadmap §2) — five deep-dive courses, filterable by track, on the jonnify design
  system: `/elixir` (Functional Programming), `/redis-patterns` (Redis Patterns Applied), `/echomq` (EchoMQ in
  Depth), `/course/agile-agent-workflow` (Agile Agent Workflow), `/bcs` (Branded Component System). The published
  paths are **inconsistent and load-bearing** — preserve them exactly.
- **The rungs** — `ec.1` scaffold (boot/healthz/static/graceful/layout) · `ec.2` templating + base layout (the
  `Renderer` + header/footer/card/filter partials) · `ec.3` course catalog + content model (the `Course` +
  file-backed loader, seeded with the five) · `ec.4` routes + pages with **URL parity** + the track filter ·
  `ec.5` design-system parity, assets + SEO · `ec.6` ship on Fly (Dockerfile, `fly.toml`, cutover + rollback).
- **As-built (ec.1)** — `cmd/server/main.go` (`newEcho` wiring + `run`/`StartConfig`), `internal/handler.Health`,
  `internal/catalog` (reserved), the `web/{templates,static}` + `content/` layout, `Makefile` (the `gate` target).
- Every claim grounds in a real `go/echo-courses` file, the vendored `go/echo` API, or a roadmap §; NO-INVENT,
  forward-tense ("ec.N builds …") for an unshipped surface.

## 0. Bootstrap (Director, before any spawn)

Read the rung's `echo-courses.<N>.prompt.md` (the authoritative scope) + its `.md` spec + the roadmap, **and
`go/CLAUDE.md`, and the `/x-mode` skill**. Declare the mode (**Flat-L2**, or **Director-solo** for an
already-built rung). Deep-reason the rung (the `/x-mode` §0: 5W, solution space incl. a do-nothing baseline, the
invariants as runnable gates, the smallest change that preserves correctness) → `tool_x_trace` (T-n). **Confirm
the Stage-1 gate is reachable** — the spec exists (or Venus authors it) and the `.prompt.md`'s settled forks
carry **no open Operator decision** (notably: *commit the vendored `go/echo` snapshot vs submodule*, and the
*module org* `github.com/fiberfx/echo-courses`); if a fork is open, **STOP and `AskUserQuestion`** before
spawning.

## 1. Stand up the TRUE team & run the pipeline

`scope` = the dashed rung slug (`ec-4`); `operator` = `jonny`; `workspace` = `/Users/jonny/dev/jonnify`;
`ledger_dir` = `docs/echo_courses` (the run ledger `<scope>.progress.md` lands there). Sequence per `/x-mode` §1:
`mcp__aaw__init` → `aaw_spawn`+`agent_register` the `director` → `TeamCreate(scope)` → `tool_x_trace(T-1)`. Create
one Task per stage. **zsh does not word-split unquoted vars** — iterate file lists with
`find … -print0 | while IFS= read -r -d '' f`.

Lift each stage's directive from the `.prompt.md`; wrap it in the `/x-mode` §3 per-spawn ceremony + "Read and
operate by `.claude/agents/<role>.md`."

**Venus** (reconcile the triad lag-1 against `go/echo-courses` / the vendored `go/echo`, or author it; frame seam
forks as four-part Arms — Rationale/5W/Steelman/Steward) → **Director rules the Arms** (mandatory
`AskUserQuestion`) → **Mars-1** (build to the brief inside the boundary, cite the spec for every public call, the
real v5 API only, run the go/ gate + smoke) → **Director verify** (a REAL pass: a fresh-gate reconcile + an
**independent `GOWORK=off` gate re-run** + the running-binary smoke + the parity battery (ec.4+) + a mutation
spot-check — Edit-in → test-catches → revert → `git diff --stat` clean net-zero, LAW-1a) → **Mars-2** (resume
Stage-1 Mars — one identity, two passes — remediate + harden; REMEDIATE loop MAX 3) → **Director ship** (the
scoped LAW-4 commits + the Stage-6 fold). **Apollo** spawns **only on `ec.6`** (high-risk), with the §11.2
charter, and resolves every ambiguity with the Operator via `AskUserQuestion` before the ship.

## 2. LAW-4 — the scoped commits (Director-only, per x.md §10)

At `tool_x_complete` (Z-n), exactly once: the Director's verify clean + the go/ gate green (+ on `ec.6`, Apollo
BUILD-GRADE); **≥1 `tool_x_decision` (D-n)** + the **Z-n** written this turn; `git status --short` AND
`git diff --cached --name-only` reviewed; `.git/rebase-merge`/`rebase-apply` checked. The working tree is **heavily
entangled** with the Operator's parallel work — **NEVER `git add -A`, NEVER a bare commit**; stage each concern
with an explicit pathspec and commit it with `-- <paths>`. Split into **separate scoped commits per concern**, so
each is a faithful record:

- `git add go/echo && git commit -F <msg> -- go/echo` → `[echo-courses] vendor Echo v5.2.0 (github.com/labstack/echo/v5 snapshot)` *(only the first ship that introduces the module / when `go/echo` is not yet tracked)*
- `git add go/echo-courses && git commit -F <msg> -- go/echo-courses` → `[echo-courses] <rung> — <title>` (e.g. `ec.1 — Echo v5 server scaffold`)
- `git add docs/echo_courses && git commit -F <msg> -- docs/echo_courses` → `[echo-courses] <rung> specs + reconcile to as-built`

`go/echo-courses/.gitignore` excludes `bin/` (the smoke binary never enters a commit). Each message cites the
slug, the Z-n, the D-n, and the Y-n report. **Stage-6 fold:** flip the rung's status line in
`echo-courses.roadmap.md`, backward-reconcile the rung `.md` to the GREEN as-built surface (status → Built + an
"As built" section), and surface the next rung. Do not push unless asked.

## 3. Quality gate (before Z-n, mirrors /x-mode §5)

- [ ] The `.prompt.md` + spec + roadmap + `go/CLAUDE.md` + the `/x-mode` skill read; mode declared.
- [ ] T-n derivation, D-n per locked contract, L-n per surprise written to `<scope>.progress.md`.
- [ ] Every peer is a REAL self-registered `Agent` spawn (`general-purpose` + the venus/mars charter; no FAKE-N);
      the Director called no Edit/Write on production code EXCEPT a mutation spot-check reverted net-zero (LAW-1a).
- [ ] Every design Arm was ruled via `AskUserQuestion` before the build (incl. the vendor-commit + module-org forks).
- [ ] The go/ gate is green: **`GOWORK=off`** `go build`/`vet`/`test` + `gofmt -l .` empty + the running-binary
      smoke (healthz/static 200, SIGTERM → exit 0); the parity battery on `ec.4`+; the boundary grep is empty
      (only `go/echo-courses`, `go/echo`, `docs/echo_courses` changed — no Elixir-umbrella or other-module bleed).
- [ ] LAW-4: Z-n written → one Director pathspec commit **per concern**; nothing foreign in `--cached`.
- [ ] `mcp__aaw__status(scope)` shows the registered peers.

## 4. Map

- The laws + pipeline: `.claude/commands/x.md` + the `/x-mode` skill. The charters the peers wrap:
  `.claude/agents/{venus,mars,apollo}.md`.
- The `go/` build guide (the gate ladder + GOWORK=off): `go/CLAUDE.md`.
- The canon + the single roadmap: `docs/echo_courses/echo-courses.roadmap.md`.
- The specs (source of truth): `docs/echo_courses/echo-courses.<N>.{md,prompt.md}`.
- The code (the boundary): `go/echo-courses/` (+ the vendored, read-only `go/echo/`).
- The run's audit trail: `docs/echo_courses/<scope>.progress.md` + `mcp__aaw__status`.
