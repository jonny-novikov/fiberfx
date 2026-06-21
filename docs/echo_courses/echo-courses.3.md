---
title: "ec.3 — Course catalog & content model"
id: echo-courses-3-catalog
rung: ec.3
size: M
risk: NORMAL
status: Draft
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
| **Where** | `internal/catalog` (model + loader), `content/<slug>.md` (front-matter + body). |
| **Why** | One declarative source for the five courses; adding a course is adding a file. |
| **How** | Parse front-matter into `Course`, render the body to HTML, build the catalog at boot, fail fast on malformed/duplicate entries. |

## Scope { id="ec3-scope" }

### In scope

- A `Course` model: `Slug`, `Title`, `Tracks []string`, `Summary`, `Path` (published URL), and a body source.
- `content/<slug>.md` per course with a front-matter block (`title`, `tracks`, `summary`, `path`) and a body.
- A loader that reads `content/`, parses front-matter, renders the body to HTML, returns an ordered catalog, and a track index (facet → courses).
- Seed data for the five published courses (table below), in published order.

### Out of scope

- Routes and rendering the index/detail (ec.4); assets/SEO (ec.5).
- Authoring new course bodies (deep bodies may start as an HTML partial per course; see roadmap decision 3).

## Specification { id="ec3-spec" }

`internal/catalog` parses each `content/<slug>` file's front-matter into a `Course`, renders the body (Markdown → HTML, or a per-course HTML partial for deep/interactive bodies), and assembles an ordered slice plus a `map[track][]Course` for the filter. Loading happens once at boot; a missing required field, a duplicate slug, or an unreadable file aborts startup. The seed set, in published order:

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
- **Risk — track-label mapping:** the published facets ("Agents", "BCS") are display labels; map them explicitly from track tags so the counts match (criterion 4).
- **Risk — deep bodies:** Markdown may not capture interactive course bodies; allow an HTML-partial body per course and templatize progressively.
