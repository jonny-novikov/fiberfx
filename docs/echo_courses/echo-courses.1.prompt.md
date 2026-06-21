---
title: "ec.1 — ship prompt (the x-mode runbook)"
id: echo-courses-1-prompt
rung: ec.1
mode: "right-sized Director-solo ship of a pre-built rung"
risk: NORMAL
vehicle: "generic x-mode (.claude/commands/x.md) — NOT /echo-mq-ship"
---

# ec.1 — ship prompt { id="echo-courses-1-prompt" }

## The rung in one paragraph

`ec.1` is the **Echo v5 server scaffold** for `echo-courses` (`go/echo-courses/`): the module +
`replace github.com/labstack/echo/v5 => ../echo`, `echo.New`, `middleware.Recover()` +
`middleware.RequestLogger()`, `GET /healthz`, static serving under `/static`, `echo.StartConfig` graceful
shutdown driven by `signal.NotifyContext`, and the `cmd/`·`internal/`·`web/`·`content/` layout. It was **built
and verified green this session** (gate + running-binary smoke). This run does not re-build it — it **ships** it:
an independent re-verification on the current tree, then the LAW-4 pathspec commits.

## Vehicle & mode

- **Vehicle: generic x-mode** (`.claude/commands/x.md` + the x-mode skill). NOT `/echo-mq-ship` — that pre-loads
  the Valkey / conformance / branded-id context, none of which applies to a Go web app. Gates are the
  `go/CLAUDE.md` ones.
- **Mode: right-sized Director-solo ship of a pre-built rung.** The build is done and green (a right-sized
  bootstrap), so there is no fresh Flat-L2 build; the live work is the Director's independent verify + the commits.
- **Risk: NORMAL.** Greenfield scaffold, no auth / data / irreversible-migration surface → **no Apollo**. (The
  high-risk rung is `ec.6`, the live-domain Fly cutover.)

## Settled forks — confirm before the commit (Director × Operator)

1. **The vendored framework ships with the rung.** `echo-courses` compiles only through `replace => ../echo`,
   so the repo cannot build it unless `go/echo` (the Echo **v5.2.0** snapshot — 146 files, MIT) is in version
   control too. **Decision:** commit `go/echo` as its own "vendor Echo v5.2.0" commit (recommended — it is
   already placed in-repo and MIT-licensed), OR convert it to a git submodule / vendored tree first (defers the
   ship). Until ruled, the `echo-courses` commit has a dangling local dependency.
2. **Module org** `github.com/fiberfx/echo-courses` (matches `mcp-go` / `echomq-go`). Flipping to
   `jonny-novikov` (matches `jonnify-cms`) is a one-line `go.mod` + import path change across 3 `.go` files —
   decide **before** the commit; a post-commit rename is churn.
3. **Scope = `ec.1` only.** `ec.2`–`ec.6` are separate rungs (the next is `ec.2`, templating + base layout).

## Stage 0 — bootstrap (Director)

Read this prompt + [`echo-courses.1.md`](echo-courses.1.md) + [`echo-courses.roadmap.md`](echo-courses.roadmap.md).
Declare the mode in plain text. Confirm the triad is build-grade (Venus reconciled it this session) and that the
forks above are ruled with the Operator (`AskUserQuestion` if any is open — fork 1 especially).

## Stage 1 — Venus (architect): DONE this session

The `ec.1` spec is authored and **backward-reconciled to as-built** (status `Built`, the "As built" section, the
v5 API corrections: no `e.Shutdown`, the `Renderer` signature, `RequestLogger`). No action unless Stage 3 finds a
spec↔as-built drift.

## Stage 2 — Mars (build): DONE this session

The scaffold is built green: `go.mod`/`go.sum` (`replace => ../echo`), `cmd/server/{main,main_test}.go`,
`internal/handler/{health,health_test}.go`, `internal/catalog/doc.go`, `web/static/version.txt`, the layout
dirs, `Makefile`, `README.md`. No fresh build.

## Stage 3 — Director solo review (the live verification)

Independently, on the current tree — **do not trust this session's report; re-run it**:

```bash
cd /Users/jonny/dev/jonnify/go/echo-courses
GOWORK=off go mod tidy && GOWORK=off go build ./... && GOWORK=off go vet ./... \
  && GOWORK=off go test ./... && gofmt -l .          # all clean; gofmt prints nothing
# running-binary smoke
GOWORK=off go build -o bin/server ./cmd/server
ADDR=:18099 ./bin/server &  SRV=$!
curl -s --retry 40 --retry-connrefused -o /dev/null -w '%{http_code}\n' http://127.0.0.1:18099/healthz  # 200
curl -s -w '\n%{http_code}\n' http://127.0.0.1:18099/static/version.txt                                  # 200
kill -TERM $SRV; wait $SRV; echo "exit=$?"   # exit=0 (graceful, not 143)
```

- **Boundary grep:** the only changes are under `go/echo-courses/`, `go/echo/` (vendored), `docs/echo_courses/`.
  No `echo_mq` / `echo/` (Elixir umbrella) / other-app bleed. Review `git status --short`.
- **Spec fidelity:** `ec.1.md`'s "As built" cites methods that exist in the tree.

Record findings; expect none (Mars-2 collapses). If any, do a focused fix and re-gate.

## Stage 5 — Director ship (LAW-4, pathspec only)

Preconditions: gate green; `.git/rebase-merge` / `rebase-apply` checked; `git diff --cached --name-only` reviewed
(the Operator pre-stages out-of-band — **never `git add -A`, never a bare `git commit`**). Split the entangled
tree into scoped commits, each re-verifying its `--cached` set is purely its concern:

1. `git commit -F <msg> -- go/echo`          → `[echo-courses] vendor Echo v5.2.0 (github.com/labstack/echo/v5)`   *(only if fork 1 = commit)*
2. `git commit -F <msg> -- go/echo-courses`  → `[echo-courses] ec.1 — Echo v5 server scaffold`
3. `git commit -F <msg> -- docs/echo_courses` → `[echo-courses] specs + ec.1 reconcile to as-built`

Do not push unless asked.

## Acceptance — done = all true

- `ec.1`'s five acceptance criteria green: compiles, `/healthz` 200, static serving, `SIGTERM` drain (exit 0), layout present.
- Gate clean (`GOWORK=off` build/vet/test + gofmt-empty) + smoke.
- Boundary clean; commits scoped per concern; nothing foreign in any `--cached`.

## Launch

Hand this file to the x-mode run as the `<rung>.prompt.md` (`/x-mode docs/echo_courses/echo-courses.1.prompt.md`).
