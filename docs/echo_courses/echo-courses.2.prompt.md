---
title: "ec.2 — templating engine & base layout (ship prompt / x-mode runbook)"
id: echo-courses-2-prompt
rung: ec.2
mode: "Flat-L2, right-sized (Director + one mars builder)"
risk: NORMAL
vehicle: "generic x-mode (.claude/commands/x.md) — NOT /echo-mq-ship"
---

# ec.2 — ship prompt { id="echo-courses-2-prompt" }

## The rung in one paragraph

ec.2 registers Echo's `Renderer` with **`html/template`** and lifts the published courses shell into a **base
layout + partials**, served from an **embedded** template tree. Build: `web/embed.go` (`//go:embed templates`),
`web/templates/{layout.html, partials/{card,filter}.html, pages/placeholder.html}`, an `internal/render`
`echo.Renderer` that parses one template set per page at boot (**fail-fast**) and composes via `{{block
"content" .}}`, then wire `e.Renderer` in `newEcho` + a placeholder route proving `c.Render`. The chrome is
copied **verbatim** from `html/index.html`. No real course data yet (ec.3) and no index/detail routes (ec.4).

## Vehicle & mode

- **Vehicle: generic x-mode.** go/ work; the `go/CLAUDE.md` gate ladder, not mix/Valkey.
- **Mode: Flat-L2, right-sized** — the Director authored this runbook + verifies + ships; **one `mars`** does the
  build. NORMAL risk → **no Apollo**, no Mars-2 (fold any remediation into the Director's verify loop).

## Settled forks (RULED this run — do not reopen)

1. **Engine = `html/template`** (roadmap §7 decision 1) — standard-library, Renderer-native.
2. **Structure = `embed.FS` + `internal/render` + per-page `{{block "content"}}` composition** (Operator ruled).
   Templates are `//go:embed`-ed (single binary for ec.6); a **custom** `internal/render.Renderer` parses one
   `*template.Template` per page (layout + partials + that page) and executes `"layout.html"`. **Not** the
   bundled `echo.TemplateRenderer` (its flat `ExecuteTemplate` can't do the block override cleanly).

## The grounding — `html/index.html` (the published /courses index; extract VERBATIM, NO-INVENT)

This file IS the published shell. Copy its chrome exactly into `layout.html`; turn its repeated shapes into
partials. Do not restyle, rename a class, or invent markup.

- **Head:** `<meta charset>`, viewport, `<title>Courses · jonnify</title>` (make the title a `{{block "title"}}Courses · jonnify{{end}}`
  so pages can override), the `<meta name="description">`, the Google-Fonts `preconnect` + the font `<link>`, and
  the **two inline `<style>` blocks** (the `:root` design-system tokens + the courses-page chrome). Copy the
  styles inline, verbatim. **NOTE (spec correction):** ec.2.md says "design-system stylesheet **link**"; the real
  page has the CSS **inline** — carry it inline now; ec.5 externalizes it to `web/static`. (The Director will
  backward-reconcile ec.2.md after the build.)
- **Header (`.topbar`):** `<a href="/" class="brand"><span class="brand-mark"></span><span>jonnify · courses</span></a>`
  then `<span class="route-tag">/courses</span>`. The literal `jonnify · courses` must appear.
- **Footer (`<footer>`):** the `.foot-mark` svg + the two `<p>` — the second is `(с) jonnify` (note: the `с` is
  Cyrillic, as published — copy the bytes, do not "fix" it).
- **Reveal script:** the trailing `<script>` IntersectionObserver block — carry it in the layout.
- **Card (`.series-card`):** `<a class="series-card" data-tags="…" href="…" style="--accent:…">` → `.s-icon`
  (svg) → `.s-eyebrow` (tag line) → `<h3>` (title) → `<p>` (summary) → `.s-go` (`Open →`). Turn into
  `partials/card.html` as `{{define "card"}}` over a card struct: `Accent, Tags, Href, Icon (template.HTML),
  Eyebrow, Title, Summary`.
- **Filter (`.filter-bar`):** the 6 `.filter-btn` (All 5 / Elixir 1 / Agents 1 / Redis 1 / EchoMQ 1 / BCS 1) +
  the trailing filter `<script>`. Turn the bar into `partials/filter.html` as `{{define "filter"}}`. For ec.2 the
  facet labels may be static markup; the data-driven counts + the JS wiring land in **ec.4** (note it, don't
  build it).

## Deliverables (the `mars` build — inside `go/echo-courses`, NO third module)

1. **`web/embed.go`** — `package web` + `//go:embed templates` + `var FS embed.FS`. (Static stays filesystem
   from ec.1; only templates embed now.)
2. **`web/templates/layout.html`** — the base shell: `<!doctype html>` → head (block "title", meta, fonts, the
   two inline `<style>`s) → body with the `.topbar` header, `{{block "content" .}}{{end}}`, the `<footer>`, the
   reveal `<script>`. Verbatim chrome.
3. **`web/templates/partials/card.html`** — `{{define "card"}}` the `.series-card` shape over the card struct.
4. **`web/templates/partials/filter.html`** — `{{define "filter"}}` the `.filter-bar`.
5. **`web/templates/pages/placeholder.html`** — `{{define "content"}}` a minimal page that proves the render:
   a heading + one `{{template "card" …}}` (sample data) + `{{template "filter" …}}`.
6. **`internal/render/render.go`** — the `echo.Renderer`. Contract (idiomatic; adjust as needed but keep
   fail-fast + the per-page set):
   ```go
   func New(fsys fs.FS) (*Renderer, error) // parse one set per templates/pages/*.html
       // each set = ParseFS(fsys, "templates/layout.html","templates/partials/*.html", <page>)
       // a parse error -> a NAMED error (render: parse <page>: …); main aborts boot
   func (r *Renderer) Render(c *echo.Context, w io.Writer, name string, data any) error
       // r.pages[name].ExecuteTemplate(w, "layout.html", data); unknown name -> error
   ```
   The v5 `Renderer` signature is `Render(c *echo.Context, w io.Writer, name string, data any) error` (c FIRST).
7. **`cmd/server/main.go`** — in `newEcho`: `r, err := render.New(web.FS)`; on error abort (return/exit with the
   named error); `e.Renderer = r`. Add a placeholder route `GET /` → `c.Render(200, "placeholder.html", data)`
   (ec.4 replaces `/` with the real index). Keep `/healthz`, `/static`, and the graceful shutdown unchanged.
8. **Tests** — `internal/render/render_test.go`: `New` over a `fstest.MapFS` with a **malformed** template returns
   a named error (fail-fast, AC1); `New(web.FS)` succeeds and knows `"placeholder.html"`. A render test
   (`cmd/server` or `internal/render`): `GET /` (or `Render` directly) → output contains `jonnify · courses`
   (header) **and** `(с) jonnify` (footer) (AC2/AC3); the card partial with sample data yields tag line/title/
   summary/`Open →` (AC4); the filter partial yields the 6 facet controls (AC5).

## Gate (run before reporting; `GOWORK=off`, from `go/echo-courses`)

```bash
cd go/echo-courses
GOWORK=off go mod tidy && GOWORK=off go build ./... && GOWORK=off go vet ./... \
  && GOWORK=off go test ./... && gofmt -l .            # gofmt prints nothing
GOWORK=off go build -o bin/server ./cmd/server
ADDR=:<port> ./bin/server &
#   GET /            -> 200, body has "jonnify · courses" AND "(с) jonnify"
#   GET /healthz     -> 200   ·   GET /static/version.txt -> 200
#   kill -TERM       -> exit 0 (graceful)
```

## Acceptance (ec.2.md) — done = all true

1. All templates parse at boot; a deliberately malformed template **aborts startup with a named error**.
2. A placeholder page via `c.Render` returns 200 with the base layout's header + footer present.
3. The rendered shell shows `jonnify · courses` (header) + `(с) jonnify` (footer); the design-system styles are in
   the head.
4. The card partial with sample data → tag line, title, summary, `Open →`.
5. The filter partial → the facet controls (labels wired to data in ec.4).

## Commit (LAW-4, scoped, Director-only, on the Operator's go)

Index-empty precheck; pathspec only; never `git add -A`; the tree is entangled with the Operator's parallel work.

- `git add go/echo-courses && git commit -F <msg> -- go/echo-courses` → `[echo-courses] ec.2 — templating engine & base layout`
- `git add docs/echo_courses && git commit -F <msg> -- docs/echo_courses` → `[echo-courses] ec.2 specs + reconcile (status Built, As-built, inline-styles correction) + ec-2 ledger`

**Stage-6 fold:** flip ec.2's status in `echo-courses.roadmap.md`; backward-reconcile `echo-courses.2.md` to as-built
(status → Built, an "As built" section, the inline-styles correction); write `ec-2.progress.md`. Surface ec.3.
