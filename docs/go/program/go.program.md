# go — the program operating manual

> How a **Go-server rung** ships: the gate ladder, the boundary, the reverse-mode discipline, and the
> live-server caution. This is the **operating contract** shared by both sub-programs (`msh` · `aaw`) — the
> mechanics-of-build live in [`go/CLAUDE.md`](../../../go/CLAUDE.md); this file is *how we ship against them*.
> The reference exemplar is [`docs/echo_mq/program/emq.program.md`](../../echo_mq/program/emq.program.md).

## The gate ladder (per module, hermetic)

Run from inside the module's own directory (`go/aaw`, `go/msh`, or `go/mcpd`):

```bash
GOWORK=off go build ./...     # the clean-build gate
GOWORK=off go vet ./...       # the static-analysis gate
GOWORK=off go test ./...      # the suite (selftest for aaw; the per-rule corpus for msh)
gofmt -l .                    # must print nothing
```

`GOWORK=off` matches exactly what `mcpd` and CI build — each server compiles **hermetically** from its own
`go.mod`, reproducible and independent of `go/go.work`. The workspace exists for interactive dev only (an edit
to `mcp-go` flows into `aaw` + `msh` without re-vendor); it is **never** the gate.

## The boundary

- A rung edits **one server** (`go/aaw` **or** `go/msh`) + at most the shared SDK **`go/mcp-go`** (which is
  free to modify, Operator decision D-5). A controller change is a separate `mcpd` rung.
- **Don't restart the live servers casually.** `mcpd` builds to a temp path and atomically hot-swaps on success
  — a failed build never takes down a running server. The Operator adopts a fresh build with `make mcp`; an
  agent leaves the live `:8905`/`:8899` servers running.
- Touching a tool surface or restarting a server needs an `/mcp` reconnect to be seen by the client.

## The reverse-mode discipline

These are **production servers being documented**, so the **code is canonical** for surface facts and the spec
is derived from it and reconciled to it each rung ([`aaw.reverse.md`](../../aaw/aaw.reverse.md)). **NO-INVENT:**
every cited surface — a tool name, a function, a file, a version — is verified at its `file:line` before it is
written; forward-tense is used **only** for genuinely unbuilt surface. A divergence between the spec and the
code is recorded as a delta and surfaced to the Operator, never silently synced.

## Design forks

Where a rung opens a genuine design choice that belongs to the Operator (a contract, a dependency, a routing
question), the architect surfaces it in **four-part arms** — Rationale · 5W (Why·What·Who·When·Where) ·
Steelman · Steward — and recommends without deciding
([`aaw.architect-approach.md`](../../aaw/aaw.architect-approach.md)). A fork is a deliberate instrument; a rung
whose approach is settled goes straight to the work.

## The artifacts (one authority)

Per server: `*.design.md` · `*.roadmap.md` · `*.progress.md` · `*.features.md` · `*.testing.md` ·
`*.references.md`, plus the `specs/` rung ladder (triads deferred). For **`aaw`**, the **forward v2** design and
the `mcp1–8` triads live at [`docs/aaw/mcp/`](../../aaw/mcp/) and are **linked, never duplicated** — that tree
stays the forward authority; `docs/go/aaw/` is the as-built reconcile.

## Map

[`go/CLAUDE.md`](../../../go/CLAUDE.md) · the framework [`docs/aaw/`](../../aaw/) · the role calibrations
[`go.venus.md`](go.venus.md) · [`go.mars.md`](go.mars.md) · [`go.apollo.md`](go.apollo.md) · the exemplar
[`docs/echo_mq/program/`](../../echo_mq/program/).
