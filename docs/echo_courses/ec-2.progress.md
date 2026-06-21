# ec-2 — ship ledger { #ec-2 }

Rung **ec.2 — templating engine & base layout** · program echo-courses (`go/echo-courses`) ·
vehicle `/echo-courses-ship ec.2` (x-mode, Flat-L2 right-sized: Director + one `mars`) · shipped 2026-06-21.

## {ec-2-ship}

**T-1 — UNDERSTAND.** ec.2 registers Echo's `Renderer` with `html/template` and lifts the published courses shell
(`html/index.html`) into a base layout + card/filter partials, served from an embedded template tree, proven by a
placeholder page. Stands on the ec.1 scaffold; no real data (ec.3) or routes (ec.4) yet.

**D-1 — engine = `html/template`** (roadmap §7 decision 1; standard-library, Renderer-native).

**D-2 — structure = `embed.FS` + `internal/render` + per-page `{{block "content"}}` composition** (Operator ruled
this run). A custom `internal/render.Renderer` over `//go:embed templates`; not the bundled `echo.TemplateRenderer`.

**D-3 — `render.Card.Accent` is `template.CSS`, not `string`** (build realization). `html/template` rewrites a
plain-string `var(--token)` custom-property value to `ZgotmplZ` (a silent accent-drop); `template.CSS` (trusted,
in-repo) emits it verbatim. Verified absent in the render.

**L-1 — spec correction (inline styles).** ec.2.md said "design-system **stylesheet link**"; the published shell
carries the CSS as inline `<style>`. Carried inline (verbatim); ec.5 externalizes to `web/static`. ec.2.md
backward-reconciled (Specification, AC3, the resolved-risk bullet, the As-built section).

**V — verify (independent Director pass).** Gate green (`GOWORK=off` build/vet/test + gofmt). Smoke `GET /` → 200,
14234 bytes; body has `jonnify · courses` + `(с) jonnify` + `Open →` + 6 `filter-btn` + `var(--gold-bright)`,
`ZgotmplZ` absent; `/healthz` 200, `/static` 200, `SIGTERM` → exit 0. Verbatim chrome (design tokens, header,
the Cyrillic `с` byte) confirmed. Boundary clean (the `mars` touched only `go/echo-courses`). Mutation spot-check:
corrupt template → FAIL (real-tree fail-fast + wiring), drop the filter → FAIL (AC5), both reverted net-zero — the
tests have teeth. Mars-2 collapsed (zero findings).

**Y — report.** ec.2 ships green. Acceptance 5/5: fail-fast (AC1) · placeholder via `c.Render` 200 + chrome
(AC2/AC3) · card partial (AC4) · filter 6-facet (AC5). Built by one `mars`; Director-verified independently.

**Z — complete.** ec.2 shipped 2026-06-21. Next: **ec.3** — course catalog + content model (the `Course` model +
a file-backed loader seeded with the five published courses, in published order).
