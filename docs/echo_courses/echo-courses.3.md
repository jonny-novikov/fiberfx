---
title: "ec.3 — Course catalog & content model"
id: echo-courses-3-catalog
rung: ec.3
size: M
risk: NORMAL
status: Built
stands-on: "ec.2"
---

# ec.3 — Course catalog & content model { id="echo-courses-3-catalog" }

> _Define the `Course` model and a file-backed catalog loaded from `content/`, seeded with the five published courses so the index and routes derive from one declarative source._

## Summary

A `Course` record and a loader that reads `content/<slug>` files with a front-matter block into an in-memory catalog. Seed it with the five courses exactly as published, so everything downstream reads from the catalog rather than hard-coded markup.

## Rationale

The published index repeats per-course facts — title, track tags, summary, the "Open →" target — in hand-written HTML. Modeling a course once and loading the set from files makes the index and the filter counts derive from data, makes adding a course a one-file change, and gives the parity tests a single thing to assert against.

## 5W + H { id="ec3-5wh" }

| | |
|---|---|
| **Who** | Platform; the catalog feeds the index, filter, and routes. |
| **What** | A `Course` model, a `content/` layout with front-matter, and a loader producing an ordered catalog. |
| **When** | After ec.2; precedes routes. |
| **Where** | `internal/catalog` (model + loader), `content/<slug>.html` (YAML front-matter + an HTML body), `content/embed.go` (the embedded corpus). |
| **Why** | One declarative source for the five courses; adding a course is adding a file. |
| **How** | Parse the YAML front-matter into `Course`, carry the HTML body as `template.HTML`, build the catalog at boot, fail fast on malformed/duplicate entries. |

## Scope { id="ec3-scope" }

### In scope

- A `Course` model: `Slug`, `Order`, `Title`, `Tracks []string`, `Facet`, `Summary`, `Path` (published URL), `Accent` (`template.CSS`), `Icon` (`template.HTML`), and `Body` (`template.HTML`).
- `content/<slug>.html` per course with a YAML front-matter block (`order`, `title`, `tracks`, `facet`, `summary`, `path`, `accent`, `icon`) and an HTML body.
- A loader that walks `content/`, parses the front-matter (`gopkg.in/yaml.v3`), carries the body as `template.HTML`, returns an ordered catalog (by `Order`) and a facet index (facet → count).
- Seed data for the five published courses (table below), in published order.

### Out of scope

- Routes and rendering the index/detail (ec.4); assets/SEO (ec.5).
- Authoring new course bodies (the seed bodies are minimal HTML intros; the detail-page content is ec.4's concern). The content storage is **HTML body + front-matter** (roadmap decision 3, ruled).

## Specification { id="ec3-spec" }

`internal/catalog` walks the embedded `content/` tree, splits each `content/<slug>.html`'s `---`-fenced **YAML front-matter** from its **HTML body** (`gopkg.in/yaml.v3`; the body becomes `template.HTML` — no Markdown engine), and assembles an ordered slice (by `Order`) plus a facet index for the filter counts. Loading happens once at boot; a missing required field, a duplicate slug (the walk makes a same-slug collision across subdirs detectable), or an unreadable/front-matter-less file aborts startup with a named `catalog: …` error. The seed set, in published order:

| Slug | Title | Tracks | Path |
|------|-------|--------|------|
| `elixir` | Functional Programming | Elixir, BEAM | `/elixir` |
| `redis-patterns` | Redis Patterns Applied | Redis, EchoMQ | `/redis-patterns` |
| `echomq` | EchoMQ in Depth | EchoMQ, protocol | `/echomq` |
| `agile-agent-workflow` | Agile Agent Workflow | Claude Agents, Portal | `/course/agile-agent-workflow` |
| `bcs` | Branded Component System | Identity, five runtimes | `/bcs` |

The filter facets derive from the track index: All (5), Elixir (1), Agents (1), Redis (1), EchoMQ (1), BCS (1).

## Acceptance criteria { id="ec3-acceptance" }

1. **Given** the seeded `content/`, **when** the catalog loads, **then** it yields exactly five courses in published order with the exact titles, tracks, and paths above.
2. **Given** a course file missing a required front-matter field, **when** the server boots, **then** startup aborts with a named error.
3. **Given** two files with the same slug, **when** loading, **then** it aborts with a duplicate-slug error.
4. **Given** the loaded catalog, **when** the track index is built, **then** the facet counts are All 5 / Elixir 1 / Agents 1 / Redis 1 / EchoMQ 1 / BCS 1.
5. **Given** a course body in the source format, **when** loaded, **then** its rendered HTML is available to the detail template.

## Dependencies & risks { id="ec3-risks" }

- **Depends on:** ec.2.
- **Facet mapping (resolved):** each course carries an explicit `facet` field (Elixir | Redis | EchoMQ | Agents | BCS), distinct from its `tracks` eyebrow labels, so the counts match exactly (criterion 4); the filter key is `strings.ToLower(facet)`.
- **Deep bodies (resolved):** the content storage is HTML body + front-matter (no Markdown engine), so interactive/HTML bodies are carried verbatim as `template.HTML`. The seed bodies are minimal intros; ec.4 decides detail-page rendering.

## As built { id="ec3-as-built" }

Shipped to ec.3 acceptance (5/5); gate green; the catalog loads from the embedded corpus, fail-fast.

- **Model + loader.** `internal/catalog/catalog.go`: `Course{Slug, Order, Title, Tracks, Facet, Summary, Path, Accent template.CSS, Icon template.HTML, Body template.HTML}`; `Load(fsys fs.FS) (*Catalog, error)` walks the tree (`fs.WalkDir`), splits front-matter/body, `yaml.v3`-unmarshals, sorts by `Order`, builds the facet index; named `catalog: …` errors on a missing field / duplicate slug / no front-matter.
- **Corpus.** `content/embed.go` (`//go:embed *.html`) + `content/{elixir,redis-patterns,echomq,agile-agent-workflow,bcs}.html` — front-matter + the **summary + icon copied verbatim** from `html/index.html` + a minimal HTML body.
- **Wiring.** `cmd/server/main.go` loads the catalog at boot (fail-fast) and discards it (`_`) — ec.4 routes it. `/`, `/healthz`, `/static`, graceful unchanged. `go.mod` adds `gopkg.in/yaml.v3` (already in `go.sum` — no new external fetch).
- **Verified.** Independent gate green; catalog tests (AC1 seeded/order, AC2 missing-field ×7 named errors, AC3 duplicate slug, AC4 facet counts, AC5 body→HTML); a mutation spot-check (remove a title → fail-fast FAIL; flip a facet → AC4 FAIL, reverted net-zero) confirmed teeth on the real embed; the verbatim summaries/icons re-checked against `html/index.html`.
