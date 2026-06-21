# ec-4 — AAW scope ledger

## {ec-4-thinking} Thinking

### T-1 — ec.4 routes + URL parity: derivation & mode

INPUTS: echo-courses.4.md (spec, authoritative; no .prompt.md exists for ec.4 → Venus authors the brief), echo-courses.roadmap.md (§2 ground truth, §8 gates), as-built ec.1–ec.3 (catalog.go / render.go / main.go / layout+card+filter templates), golden master html/index.html.

5W: WHO course readers at published URLs. WHAT GET /courses index (hero "In-depth courses." + "5 deep dives" stat + track filter + 5 cards in published order) · 5 detail routes on published paths (/elixir, /redis-patterns, /echomq, /course/agile-agent-workflow, /bcs) · /courses/:slug internal canonical (render-identical, no redirect) · ?track= server mirror · 404 unknown slug — all catalog-driven. WHERE internal/handler (index+detail), wired in cmd/server/main.go newEcho; NEW templates pages/index.html + pages/course.html. WHEN after ec.3, gates ec.5/ec.6. WHY serve the catalog as pages without breaking a published URL.

SOLUTION SPACE: (A, chosen) thread the already-loaded *catalog.Catalog into newEcho (main.go:run currently loads-and-DISCARDS it — the designed ec.4 seam); index handler renders Courses+Facets; register the 5 published paths + /courses/:slug all to a detail handler keyed by an explicit path→course map built from catalog.Path; filter client-side JS (port from golden master) + ?track= server filter. (B, rejected) a single /:slug catch-all — published paths are multi-segment (/course/agile-agent-workflow), collide with /healthz//static//courses, and the spec mandates explicit registration "from the catalog's Path". (C, baseline) keep placeholder → fails every ec.4 acceptance.

INVARIANTS AS GATES (verify): URL parity — each published path → 200 + right course (curl battery, criterion 2). Catalog single source — routes+cards+facets all derive from catalog; no hardcoded course list survives outside content/ (grep). Fail-fast preserved (catalog+templates parse at boot — already in run()). Echo v5 idioms — handlers take *echo.Context, render via Renderer. No broken links — brand href="/" must resolve (→ the GET / question).

FORK SURFACED (real, not ceremony): F-A facet-chip ORDER. Golden master html/index.html filter = All,Elixir,Agents,Redis,EchoMQ,BCS (published). ec.3 Catalog.Facets first-seen course order = All,Elixir,Redis,EchoMQ,Agents,BCS. Tension: gate-4 (catalog is the single source) vs gate-2 (visual parity on chip order) + criterion-4's quoted order. No single catalog Order key yields both the card order and the filter order → Operator decision. Venus frames as a four-part Arm; Director rules via AskUserQuestion before the build.

MODE: Flat-L2 (multi-file: handlers+templates+routing+filter JS+parity battery; a genuine seam fork). Risk NORMAL+ → Director solo verify is the floor + MANDATORY URL-parity battery; NO Apollo (per command: ec.1–ec.5 NORMAL, no Apollo). Pipeline: Venus (reconcile triad vs ec.1–3 + golden master, author brief, frame F-A) → Director rules F-A (AskUserQuestion) → Mars-1 (build+go/ gate+smoke) → Director verify (independent GOWORK=off gate + smoke + parity battery + net-zero mutation spot-check) → Mars-2 (harden) → Director ship (scoped LAW-4 commits: go/echo-courses + docs/echo_courses; go/echo already tracked so NO vendor commit). Boundary: go/echo-courses only (go/echo read-only, already committed).

### T-2 — ec.4 reconcile delta (spec vs as-built ec.1-3 + golden master html/index.html)

VERDICT: BUILD-GRADE after surgical corrections (applied to echo-courses.4.md). All seven acceptance criteria are buildable on the as-built surface; no INVENTED public call survives.

CLAIM CLASSIFICATION (cite=real):
- MATCH: GET /courses index from Catalog.Courses/.Facets; 5 detail routes on published paths from Course.Path; /courses/:slug internal canonical (router param token ':' confirmed router.go:138); 404 via echo.NewHTTPError (httperror.go:99); handlers take *echo.Context, render via c.Render (render.go:87); newEcho seam (main.go:69 loads-and-DISCARDS the catalog — the designed ec.4 thread-in point); fail-fast already in run() (main.go:65).
- CORRECTED (was INVENTED in the brief I was handed): path-param accessor is c.Param("slug") NOT c.PathParam (context.go:283 — there is no PathParam method). NewHTTPError takes TWO args (code int, message string) NOT one (httperror.go:99). Folded both into the spec + brief as NO-INVENT pins.
- PINNED from golden master (criterion grounding): (1) card grid order == Course.Order (elixir1..bcs5) — criterion-1 "published order" CONFIRMED == Order. (2) eyebrow = strings.Join(Tracks," · ")+" · English" (golden "Elixir · BEAM · English"). (3) card data-tags = strings.ToLower(Facet) — golden cards carry data-tags="elixir" (singular facet key), NOT the multi-track list; this is the pin that makes a chip filter its card. (4) the filter <script> is verbatim in the golden master (splits data-tags on space, toggles .filter-hidden) — ec.4 ports it; ec.5 owns asset files so it rides INLINE in pages/index.html. (5) hero-sub + section "Choose a course"/"5 deep dives"/"All five are taught in English…" copy is in the golden master and DIFFERS from the ec.2 placeholder — index uses the golden copy.
- 404 NOTE: DefaultHTTPErrorHandler renders *HTTPError as JSON (echo.go:431) — criterion 6 needs status 404 only; a styled 404 page is out of scope (ec.5). Pin so Mars does not over-build.

FORK F-A (facet-chip order) REAL, surfaced to Director (AskUserQuestion): golden filter order All,Elixir,Agents,Redis,EchoMQ,BCS vs Catalog.Facets first-seen All,Elixir,Redis,EchoMQ,Agents,BCS. gate-4 (catalog single source) vs gate-2/criterion-4 (visual+quoted order). No single Order key yields BOTH card order AND this chip order.

## {ec-4-decisions} Decisions

### D-1

F-A ruling — facet-chip order: PUBLISHED order, carried in the catalog (Arm B)

DECISION: ec.4 renders the filter chips in the PUBLISHED order (All, Elixir, Agents, Redis, EchoMQ, BCS), carried in the CATALOG via a per-course front-matter `facet_order` field (Venus's Arm B).

GROUNDING (Operator directive "Re-read specs"): the spec settles the OUTCOME — acceptance criterion 4 quotes the published order verbatim, so Arm A (drive from Catalog.Facets first-seen → Elixir,Redis,EchoMQ,Agents,BCS) is OUT (it fails criterion 4). The MECHANISM is a team impl choice (x.md §4: two reasonable implementations → decide, do not escalate). B over C because roadmap §1 mandates "one place to add a course": B keeps chip order a CATALOG property in the course's own front-matter (gate-4 single-source honored; a future course self-describes its chip slot), whereas C (a published-order constant in the ec.4 handler) makes chip order a SECOND place to edit when a course is added — a §1 footgun.

CONTRACT (Mars builds to this): add `FacetOrder int` to catalog.Course + `facet_order` to courseMeta + require it in validate(); buildFacets orders the non-All facets by FacetOrder (All stays first; when a facet is shared, the first-seen course's facet_order sets it); facet_order per content file — elixir=1, agents=2, redis=3, echomq=4, bcs=5 (grid Course.Order UNCHANGED: elixir1/redis2/echomq3/agents4/bcs5); update catalog_test.go's facet-order expectation to [All,Elixir,Agents,Redis,EchoMQ,BCS]. The URL/visual parity battery asserts the rendered chip order == published.

### D-2

F-B ruling — GET / behaviour

DECISION: register `GET /` to the SAME index handler as `GET /courses` (both first-class, no redirect), so the topbar brand `href="/"` resolves (gate-5 no-broken-links) and the index is reachable at both paths. Venus's recommendation; an implementation detail with one obvious answer (x.md §4 — not an Operator escalation). No home page is invented; ec.6's Fly deployment may remap `/` at the edge if the jonnify site root needs it. The link-check (criterion 7) asserts `/` → 200.

### D-3

F-C ruling — detail-page scope: LANDING (spec-settled, ruled in-team per L-1)

DECISION: each `/elixir`-style detail page renders the catalog body as a course **landing** (the intro), NOT a re-host of the deep multi-page course. Ruled in-team — NOT escalated: the deploy-forward reconcile's roadmap §9 non-goal states "the detail pages are landings" and §7 decision 4 recommends it, so the spec fixes the OUTCOME (L-1's test) and this is read off the spec. The deep course content stays served at its existing routes; the ec.6 cutover must not shadow them.

CONTRACT: `pages/course.html` renders {layout + `Course.Body` (`template.HTML`) + the eyebrow/title/tracks header}; `Course.Body` is the minimal HTML intro from ec.3's `content/<slug>.html`. No deep-content migration.

### D-4

Deploy-executability — verify via the LOCAL DEV SERVER; deploy-ready artifacts; Operator deploys manually

DECISION (Operator directive "No Docker testing needed. Local dev server"): ec.4 is built + verified via the **local dev server** (`make run` / `go run ./cmd/server` + the curl parity battery against localhost) — **NO Docker build/run testing** (the daemon is down and the Operator ruled it out). The `Dockerfile` + `fly.toml` are authored as **deploy-ready artifacts** (the deploy-forward scope) but verified by **inspection only** (a standard multi-stage Go build referencing the binary + `web/static` + `/healthz`, adapted from the `go/` jonnify pattern), NOT Docker-tested. The actual `fly deploy` is the Operator's **manual** step (flyctl authed as jonny.novikov@gmail.com; the `go/fly.toml` convention is "operator runs fly deploy" — no CI).

GROUNDING: deploy-forward (the committed reconcile, user-ruled) puts the deploy artifacts in ec.4; the executability (can the agent deploy?) was the one genuinely-open item L-1 says to escalate — the Operator ruled it. AC8 (container serves all paths) is satisfied by the local-dev-server equivalent (the binary serves every path); AC9 (`fly deploy`) becomes the Operator's manual completion.

## {ec-4-learnings} Learnings

### L-1

Over-escalation — I asked the Operator a question the spec had settled

I surfaced F-A's ORDER to the Operator via AskUserQuestion, but acceptance criterion 4 already QUOTED the published chip order — the spec had fixed the outcome. The Operator redirected: "Re-read specs."

LESSON: before surfacing a fork to the Operator, test whether the spec already fixes the OUTCOME. If it does, the only open question is MECHANISM, which is decided in-team (tool_x_decision/alternative), never escalated. Escalate to the Operator only genuinely-open OUTCOMES (a true architecture/contract/dependency fork the spec leaves undetermined). Echoes the cost-discipline memory (rigor constant, ceremony scales down): an Operator round-trip on a spec-settled question is wasted ceremony.

CAVEAT (what still held): Venus's reconcile was NOT wasted — the golden-master grounding (card order==Order, eyebrow format, data-tags==ToLower(Facet), the verbatim filter <script>, the golden hero copy) + the NO-INVENT API corrections (c.Param not c.PathParam; NewHTTPError two-arg) were the real Stage-1 yield and are build-grade. The miscalibration was only in routing the OUTCOME up instead of reading it off criterion 4.

### L-2

Deploy-forward reframe arrived mid-run + the build landed out-of-band RED on its own gate

Two parallel-work facts shaped the ship. (1) After this run's D-1/D-2, the Operator reconciled the whole ladder to deploy-forward (ec.4 = the live site, +Fly deploy) and ruled "no Docker testing, local dev server" — folded as D-3 (landing, spec-settled) + D-4 (local-dev-server verify, deploy-ready artifacts). (2) The ec.4 production code was committed out-of-band (`6e4a1b0b`) and an independent Mars rebuild converged on it byte-for-byte — but it was **red on its own `make gate`**: a gofmt-dirty `main_test.go` + `TestIndex_ChipsAndCards` asserting the JS comment `html/template` strips from inline `<script>`. LESSON: a committed build is not a verified build — re-run the gate on what is actually on disk; the verbatim-port of inline JS loses comments (assert the surviving logic, not the comment), and "a check counts only if it RUNS green".

## {ec-4-verify} Verification

### V-1 — Director independent verify (Stage-3, on the as-committed tree + the ship delta)

GATE: `make gate` green (build/vet/test + gofmt) after the two test fixes. PARITY BATTERY (local dev server, D-4 — no Docker): `/courses` + `/` + the five published paths all 200 + right course; index 5 cards; `?track=Redis`/`REDIS` → 1 (case-insensitive); `/courses/elixir` byte-IDENTICAL to `/elixir` (D-3, no redirect); unknown slug → 404; SIGTERM → exit 0. MUTATION: break a `facet_order` → the catalog facet-order test FAILS (teeth), reverted net-zero. HEAD-RED confirmed: HEAD `courses_test.go` had 1 brittle JS-comment assertion + `main_test.go` gofmt-dirty. DEPLOY ARTIFACTS (inspection, D-4): Dockerfile context `go/` (handles `replace => ../echo`), `ADDR` is the read env (no unread-PORT no-op), `kill_timeout 15` > `gracefulTimeout 10s`. BOUNDARY: only `go/echo-courses` (the 2 test fixes + the 2 new deploy artifacts); `go/echo` untouched. Mars-2 collapsed (zero findings).

## {ec-4-report} Report

### Y-1 — ec.4 shipped

ec.4 (the live site) ships green. Acceptance 1–8 verified via the local dev server; criterion 9 (`fly deploy`) is the Operator's manual completion. The production code landed out-of-band (`6e4a1b0b`); the ship adds the deploy-ready `Dockerfile`/`fly.toml` and the two load-bearing test fixes that make the committed tree pass its own gate, plus the docs backward-reconcile.

## {ec-4-complete} Complete

### Z-1

ec.4 shipped 2026-06-21 via `/echo-courses-ship ec.4` (continuation; D-1..D-4). Next: **ec.5** — polish + redeploy (externalize the CSS to `web/static`, interactive assets, SEO/sitemap/robots; the site stays live).
