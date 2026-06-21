# ec-3 — ship ledger { #ec-3 }

Rung **ec.3 — course catalog & content model** · program echo-courses (`go/echo-courses`) ·
vehicle `/echo-courses-ship ec.3` (x-mode, Flat-L2 right-sized: Director + one `mars`) · shipped 2026-06-21.

## {ec-3-ship}

**T-1 — UNDERSTAND.** ec.3 defines the `Course` model + a file-backed loader over `content/<slug>.html`, seeded
with the five published courses in published order, building an ordered catalog + a facet index. Fail-fast at
boot. No routes (ec.4). Stands on ec.2.

**D-1 — content storage = HTML body + YAML front-matter** (Operator ruled; roadmap §7 decision 3).
`content/<slug>.html`, `yaml.v3` front-matter (already in `go.sum` — zero new external deps), body →
`template.HTML`. No Markdown engine (goldmark chosen against — the real bodies are HTML).

**D-2 — the model carries the card chrome.** `Course{Slug, Order, Title, Tracks, Facet, Summary, Path, Accent
template.CSS, Icon template.HTML, Body template.HTML}` — the complete per-course record so ec.4 maps Course→card
without re-touching `content/`.

**L-1 — WalkDir over flat glob (mars realization).** `Load` walks (`fs.WalkDir`), so a duplicate-slug collision
(AC3) is structurally exercisable (`dup.html` + `sub/dup.html` → same slug). Same contract, AC3 honestly provable.

**L-2 — spec lag (.md → .html).** ec.3.md said `content/<slug>.md` / "Markdown → HTML"; the ruling is HTML +
front-matter. ec.3.md backward-reconciled (Where, How, scope, Specification, risks, As-built).

**V — verify (independent Director pass).** Gate green (`GOWORK=off` build/vet/test + gofmt). Catalog tests:
AC1 (5, published order, exact titles/tracks/paths), AC2 (missing-field ×7 named errors), AC3 (duplicate slug),
AC4 (facet counts All 5 / Elixir 1 / Agents 1 / Redis 1 / EchoMQ 1 / BCS 1), AC5 (body → `template.HTML`). Smoke:
`GET /` 200 (ec.2 placeholder), `/healthz` 200, `/static` 200, `SIGTERM` → exit 0. NO-INVENT: the summaries +
icon svgs are byte-verbatim in `html/index.html`. Dep delta: only `yaml.v3` added (no goldmark); hermetic
`GOWORK=off` build. Boundary clean (only `go/echo-courses`). Mutation spot-check: remove a title → fail-fast FAIL;
flip a facet → AC4 FAIL; both reverted net-zero — teeth on the real embed. Mars-2 collapsed.

**Y — report.** ec.3 ships green. Acceptance 5/5. Built by one `mars`; Director-verified independently.

**Z — complete.** ec.3 shipped 2026-06-21. Next: **ec.4** — routes + pages with **URL parity** (the `/courses`
index + the five detail routes on their published paths + the track filter). NORMAL+ — the parity battery begins
(every published path → 200 + the right course; a link check over the rendered pages).
