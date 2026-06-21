---
title: "ec.3 — course catalog & content model (ship prompt / x-mode runbook)"
id: echo-courses-3-prompt
rung: ec.3
mode: "Flat-L2, right-sized (Director + one mars builder)"
risk: NORMAL
vehicle: "generic x-mode (.claude/commands/x.md) — NOT /echo-mq-ship"
---

# ec.3 — ship prompt { id="echo-courses-3-prompt" }

## The rung in one paragraph

ec.3 defines the `Course` model + a **file-backed loader** that reads `content/<slug>.html` (a YAML front-matter
block + an HTML body), seeded with the **five published courses in published order**, and builds an ordered
catalog + a facet index for the filter counts. Everything downstream reads the catalog, not hand-written markup.
No routes/rendering yet (ec.4). The loader is **fail-fast** (missing field / duplicate slug / unreadable → boot
aborts with a named error).

## Vehicle & mode
generic x-mode; right-sized: Director authored this runbook + verifies + ships; **one `mars`** builds. NORMAL → no
Apollo, no Mars-2 (fold remediation into the verify).

## Settled forks (RULED — do not reopen)
- **Content storage = HTML body + YAML front-matter** (Operator ruled this run; roadmap §7 decision 3). Each
  course is one `content/<slug>.html`: a `---`-fenced YAML front-matter block + a raw-HTML body. Front-matter
  parses via **`gopkg.in/yaml.v3`** (already in `go.sum` via echo — **zero new external deps**; add it to
  `require`). The body becomes `template.HTML`. **No Markdown engine** (goldmark was chosen against — the real
  bodies are HTML, and it is the only would-be new dependency).

## The Course model + loader (the build)

```go
// internal/catalog
type Course struct {
    Slug    string        // from the filename (content/<slug>.html)
    Order   int           // front-matter; sort key for published order
    Title   string        // front-matter
    Tracks  []string      // front-matter (the eyebrow labels, e.g. ["Elixir","BEAM"])
    Facet   string        // front-matter (the filter facet: Elixir|Redis|EchoMQ|Agents|BCS)
    Summary string        // front-matter
    Path    string        // front-matter (the published URL)
    Accent  template.CSS  // front-matter (the --accent value, e.g. var(--gold-bright) or #e0564e)
    Icon    template.HTML // front-matter (the card svg, verbatim from html/index.html)
    Body    template.HTML // the HTML after the front-matter block
}
// Load(fsys fs.FS) (*Catalog, error): read *.html, split front-matter (--- … ---) + body,
//   yaml.v3 unmarshal the metadata, body -> template.HTML, sort by Order, build:
//     - Courses []Course (ordered)
//     - Facets: ordered [{Label, Key, Count}] for All + each facet (Key = strings.ToLower(Facet))
//   FAIL-FAST: a missing required field, a duplicate slug, an unreadable/!front-matter file -> named error.
```

The catalog is loaded at boot from an **embedded** `content/` tree (`//go:embed`, mirroring ec.2's `web` embed —
add `content` to an embed FS; a `content` package or extend `web`). Decide the cleanest embed home; keep it
`GOWORK=off`-buildable.

## The seed — the five published courses (extract VERBATIM from `html/index.html`, NO-INVENT)

Write `content/<slug>.html` for each. The **summary** text and the **icon `<svg>`** must be copied **verbatim**
from the matching `.series-card` in `html/index.html` (do not paraphrase a summary or redraw an icon). The
metadata:

| order | slug | title | tracks | facet | path | accent |
|--|--|--|--|--|--|--|
| 1 | `elixir` | Functional Programming | [Elixir, BEAM] | Elixir | `/elixir` | `var(--gold-bright)` |
| 2 | `redis-patterns` | Redis Patterns Applied | [Redis, EchoMQ] | Redis | `/redis-patterns` | `#e0564e` |
| 3 | `echomq` | EchoMQ in Depth | [EchoMQ, protocol] | EchoMQ | `/echomq` | `#6fdccf` |
| 4 | `agile-agent-workflow` | Agile Agent Workflow | [Claude Agents, Portal] | Agents | `/course/agile-agent-workflow` | `#cdb8f0` |
| 5 | `bcs` | Branded Component System | [Identity, five runtimes] | BCS | `/bcs` | `#7ab0d8` |

**Body (ec.3):** a **minimal** HTML intro per course — a heading + the summary as a paragraph (a migrated
starter, NOT new authored course content; the roadmap non-goal forbids authoring content). ec.4 decides how the
detail page renders the body. This is enough to satisfy AC5 (body → `template.HTML` available to a template).

The facet counts derive from `Facet`: **All 5 · Elixir 1 · Agents 1 · Redis 1 · EchoMQ 1 · BCS 1**.

## Deliverables (inside `go/echo-courses` ONLY)
- `internal/catalog/catalog.go` — the `Course` + `Catalog` types + `Load(fsys) (*Catalog, error)` (replaces the
  ec.1 `doc.go` placeholder); fail-fast; the facet index.
- the embedded `content/` tree + `content/<slug>.html` ×5 (front-matter + verbatim summary/icon + minimal body).
- `go.mod` — add `require gopkg.in/yaml.v3 v3.0.1` (already in `go.sum`).
- wire the catalog load into boot (`newEcho`/`run`) so a bad catalog **fails fast** at startup (do NOT render it
  yet — ec.4 adds routes; ec.3 just proves the load + fail-fast). Keep `/`, `/healthz`, `/static`, graceful
  unchanged.
- `internal/catalog/catalog_test.go` — AC1 (5 courses, published order, exact titles/tracks/paths), AC2 (missing
  field → named error), AC3 (duplicate slug → error), AC4 (facet counts All 5 / Elixir 1 / Agents 1 / Redis 1 /
  EchoMQ 1 / BCS 1), AC5 (a body → non-empty `template.HTML`). Use a `fstest.MapFS` for the failure cases.

## Gate (run before reporting; `GOWORK=off`, from `go/echo-courses`)
`make gate` (`go mod tidy && go build ./... && go vet ./... && go test ./... && gofmt -l .` empty), then the
running-binary smoke: `GET /` 200 (the ec.2 placeholder still renders), `/healthz` 200, `/static/version.txt`
200, `SIGTERM` → exit 0. (The catalog isn't routed yet; ec.4 wires it — but a malformed seed must abort boot.)

## Acceptance (ec.3.md) — done = all true
1. Seeded `content/` → exactly five courses in published order, exact titles/tracks/paths.
2. A course file missing a required front-matter field → startup aborts with a named error.
3. Two files with the same slug → a duplicate-slug error.
4. The facet counts are All 5 / Elixir 1 / Agents 1 / Redis 1 / EchoMQ 1 / BCS 1.
5. A course body in the source format → its rendered HTML is available to the detail template.

## Commit (LAW-4, scoped, Director-only, on the Operator's go)
Index-empty precheck; pathspec only; never `git add -A`.
- `git add go/echo-courses && git commit -F <msg> -- go/echo-courses` → `[echo-courses] ec.3 — course catalog & content model`
- `git add docs/echo_courses && git commit -F <msg> -- docs/echo_courses` → `[echo-courses] ec.3 specs + reconcile + ec-3 ledger`

**Stage-6 fold:** flip ec.3's status in `echo-courses.roadmap.md`; backward-reconcile `echo-courses.3.md` (status →
Built, an "As built" section, the HTML+front-matter ruling); write `ec-3.progress.md`. Surface ec.4 (routes + URL
parity — NORMAL+, the parity battery begins).
