# ec-5 — AAW scope ledger

## {ec-5-thinking} Thinking

### T-1 — UNDERSTAND/EXPAND: ec.5 polish the live echo-courses site.

5W: WHO platform/reader+crawler-facing · WHAT externalize the layout's inline design-system CSS + the two inline interactive scripts to web/static (fingerprinted, byte-equivalent look) + per-page title/description/Open Graph/canonical + GET /sitemap.xml + GET /robots.txt; redeploy · WHEN after ec.4 (live), before ec.6 cutover · WHERE go/echo-courses (boundary), go/echo read-only · WHY SEO + caching parity without downtime · HOW lift inline assets to fingerprinted static, meta from catalog data, sitemap from catalog.

Mode: Flat-L2, right-sized Director + ONE mars (NORMAL, M; same shape as ec.2-4). No Apollo.

Grounded facts (NO-INVENT):
- Published master html/index.html carries ZERO OG/canonical/favicon/JSON-LD — only <title> + <meta description>. So OG+canonical are ADDITIVE polish; the only strict-parity duty is the index <meta description> staying byte-identical to published (already verbatim layout.html:8).
- Detail pages are landings (ec.4 D-3) — no per-course interactive widgets to wire. AC2 "interactive assets" resolves to the EXISTING two inline scripts (index filter pages/index.html:22; reveal-on-scroll layout.html:146) externalized. No new widgets invented.
- Load-bearing invariant: byte-equivalence. The two <style> blocks (layout.html:13-111, 112-135) are verbatim from published markup; externalized CSS bytes must equal the former inline bytes. ec.5 signature test.
- Static today served from DISK via e.Static("/static", staticDir) (main.go:100); templates+content are embedded. Asymmetry resolved by the fork ruling below.

Fork ruled up front (AskUserQuestion, Operator): asset-serving/fingerprint seam → ARM A1 embed + content-hash route. //go:embed templates static; boot sha256 → /static/app.<hash8>.{css,js} served from embedded bytes, Cache-Control public,max-age=31536000,immutable; hashed URLs injected into layout; <script defer> for JS. Hermetic, true fingerprint.

Smallest change preserving correctness: move bytes (no rewrite), add an asset-fingerprint layer + a meta block + two tiny handlers; keep routes/catalog/render contracts intact. Verify via LOCAL DEV SERVER (no Docker); fly deploy is the Operator's (standing ruling, ec.4 D-4).

### T-2 — ec.5 reconcile: the as-built ground truth

Read the as-built tree + the published master before authoring. Findings, each PROBE-grounded (not config-read):
- ASSET ASYMMETRY (confirmed): web/embed.go:16 embeds ONLY `templates` (`//go:embed templates`); main.go:100 serves static from DISK (`e.Static("/static", staticDir)`, staticDir=`web/static`). web/static today holds ONLY `version.txt` (66 bytes), no css/js. D-1 closes this: add `static` to the embed + serve content-hashed routes from embedded bytes.
- BYTE-EQUIVALENCE BOUNDARY (the signature invariant): layout.html carries TWO `<style>` blocks — the design-system root (lines 13-111) + the courses-page chrome (lines 112-135). The published master html/index.html ALSO carries exactly two `<style>` blocks (lines 12 + 111). ec.5 externalizes the concatenation of the two block bodies (sans `<style>` wrappers) to app.<hash>.css; the served bytes must equal the former inline bytes.
- THE TWO INLINE SCRIPTS (AC2 resolution): reveal-on-scroll in layout.html:146-149; the track-filter in pages/index.html:22-34. These are the ONLY interactive assets — detail pages are landings (ec.4 D-3), zero per-course widgets. ec.5 externalizes THESE two, invents no widget.
- PUBLISHED-MASTER META PARITY (NO-INVENT, pinned): html/index.html `<head>` = `<title>Courses · jonnify</title>` + ONE `<meta name=description>` + font preconnects/stylesheet. Zero og:, zero rel=canonical (the lone `canonical` grep hit is body text at line 192), zero favicon, zero JSON-LD. So OG+canonical are ADDITIVE polish; the only strict-parity duty is the index `<meta description>` byte-identical to published — already verbatim at layout.html:8 (diff-clean vs html/index.html:7).
- BUILD CONTEXT: module github.com/fiberfx/echo-courses, go 1.25.0, replace echo/v5 => ../echo; Makefile has build/run/test/vet/fmt/tidy/gate/clean. GOWORK=off, not a go.work member.

### T-3 — Mars build plan (ec.5, NORMAL)

As-built read complete. Topology confirmed against the runbook:
- layout.html: two <style> blocks at lines 13-111 (design-system :root + chrome) and 112-135 (courses-page chrome); reveal-on-scroll <script> at 146-149; verbatim <meta description> at line 8 == html/index.html:7 (byte-identical, verified).
- pages/index.html: filter <script> at 22-34.
- pages/course.html: {{.Eyebrow}}/{{.Title}}/{{.Body}} landing.
- web/embed.go: //go:embed templates ONLY (must extend to "templates static").
- main.go: e.Static("/static", staticDir) disk-served (line 100); envOr helper (118-123); newEcho(staticDir, cat).
- render.go: New(fsys) parses each page set WITHOUT .Funcs() — so Option B (FuncMap) would force a render-layer change (funcs must register pre-parse). Option A (Head struct in view-models) touches only handler + templates.
- HEAD layout.html is UNEDITED (git diff empty) → the byte-equivalence baseline is HEAD as-is.

Existing tests that ec.5 must touch:
- courses_test.go TestIndex_ChipsAndCards (108-117) asserts the filter <script> rides INLINE on /courses — the script moves to app.js, so this must flip: inline fragments ABSENT on /courses, PRESENT on /static/app.<hash>.js.
- main_test.go TestNewEcho_StaticServing (48-69) writes probe.txt to a temp STATIC_DIR, expects /static/probe.txt 200 → disk e.Static must be PRESERVED (version.txt + fonts case).

Build order (topology): (1) externalize app.css (concat of the two <style> bodies, sans wrappers) + app.js (reveal then filter, sans wrappers); (2) embed static + content-hash routes + sitemap/robots + CANONICAL_BASE; (3) wire the head (Head struct, D-5 Option A-hybrid). Then the gate + byte-equivalence proof + curl battery.

### T-4 — Build complete + full gate green (ec.5, NORMAL).

Built the three moves in topology order, boundary = go/echo-courses ONLY (go/echo untouched, no second module):
1. web/static/app.css (NEW) = concat of the two HEAD layout.html <style> bodies, sed-sliced from git show HEAD (byte-equivalent by construction). web/static/app.js (NEW) = reveal body + filter body, same method. NO new widget.
2. web/embed.go: //go:embed templates -> templates static. internal/asset/asset.go (NEW): Load(web.FS) sha256-8 fingerprints each → /static/app.<hash>.{css,js}, Register wires exact GET routes serving embedded bytes with immutable Cache-Control + exact Content-Type; boot fail-fast on missing asset. internal/handler/seo.go (NEW): Sitemap (well-formed urlset over CANONICAL_BASE + /courses + each Course.Path) + Robots (allow-all + Sitemap:). main.go: read CANONICAL_BASE via envOr (default https://jonnify.fly.dev), thread through run/newEcho, register asset + sitemap/robots, keep disk e.Static for version.txt.
3. render.Head struct (NEW, beside Card). NewCourses(cat, cssURL, jsURL, canBase) populates Head per page via h.head(...); indexData/detailData embed Head. layout.html: deleted both <style> blocks + the reveal <script>, injected the head meta (description/canonical/og×5/twitter) + the CSS <link> + the deferred <script>. index.html: deleted the inline filter <script>. course.html UNCHANGED (head flows through layout — L-3).

GATE (GOWORK=off, go/echo-courses, local dev server, no Docker, no fly deploy):
- make gate: OK (tidy+build+vet+test; gofmt -l . empty).
- SIGNATURE byte-equivalence: CSS diff EMPTY, JS diff EMPTY (vs git show HEAD inline bodies) — re-run after edits, still empty.
- Tests added: internal/asset (URL shape, hashed-route 200+CT+immutable+wrong-hash-404, served-bytes-verbatim, hash==sha256-prefix); internal/handler/seo_test (sitemap well-formed+6 urls, robots valid, index head published-description-byte-identical+og+canonical+no-og:image, detail head Summary+article+canonical from base); render_test TestLayoutChrome flipped to assert externalized links + inline source GONE; courses_test filter-script assertion flipped (inline absent, deferred app.js linked).
- Local dev server battery: 7 published paths 200; /courses/:slug render-identical; hashed CSS/JS 200 + text/css|text/javascript; charset=utf-8 + Cache-Control public,max-age=31536000,immutable; wrong hash 404; version.txt 200 (disk e.Static coexists — L-4); sitemap 200 application/xml 6 absolute URLs; robots 200 valid; index head + /elixir head correct; CANONICAL_BASE=https://example.test flip → canonical/og:url/sitemap/robots ALL flipped (D-2 consumed); zero residual <style>/IntersectionObserver/inline-filter on / and /bcs; exactly 1 <script defer src>; published <meta description> byte-identical to html/index.html:7; SIGTERM exit 0.
- NET-ZERO (HEAD binary in throwaway worktree vs ec.5 binary): full / diff = ONLY the head meta/CSS-link delta + the inline-scripts→deferred-script delta; the <body> content sections (topbar/hero/cards/chips/footer) produce ZERO diff lines (byte-identical).
- Markup (AC6): tidy zero STRUCTURAL errors on / and /bcs (the <section>/<svg> "not recognized" notes are HTML4-validator-vs-HTML5 false positives — html/index.html master shows the same 6); xmllint sitemap WELL-FORMED; all 7 internal links 200 incl brand href="/".
- Determinism posture: NOT the ≥100 id-mint/process/lease class (stateless web rung). 20/20 consecutive full runs PASS; go test -shuffle=on green (no order-dependence); content-hash stable across two independent boots.
Dockerfile/fly.toml inspection-only: binary self-contains assets; /healthz check; kill_timeout=15 > 10s graceful. Dockerfile:41 COPY web/static now non-load-bearing for serving (keeps version.txt for disk path) — noted, not Docker-built.

## {ec-5-decisions} Decisions

### D-1 — Asset-serving / fingerprint seam = ARM A1 (embed + content-hash route). Ruled by the Operator via AskUserQuestion, up front (per the ec.3 "surface one fork up front" calibration).

Contract Mars builds to:
- web/embed.go: //go:embed templates static (add static to the embed set; the binary becomes self-contained for CSS/JS).
- At boot, compute sha256 over each asset's bytes; take an 8-hex-char prefix; serve at /static/app.<hash8>.css and /static/app.<hash8>.js FROM the embedded bytes with header Cache-Control: public, max-age=31536000, immutable (+ the correct Content-Type).
- Inject the two hashed URLs into every rendered page (via the render layer's data or a FuncMap), so layout.html links them in <head> (CSS) and before </body> (<script defer>).
- The URL changes iff the bytes change → never-stale + safe immutable caching.

Rejected: A2 disk e.Static + ?v=hash (path-keyed caches can serve stale; immutable unsafe); A3 build-time hashed filename (adds a build step + a generated artifact; hash unknown until build).

Implementation caveat for Mars to resolve against REAL Echo v5 (NO-INVENT): the explicit fingerprint routes coexist with e.Static("/static",…) on the same /static prefix — verify Echo v5's router does not conflict/panic; if it does, serve the embedded fingerprinted assets under the same prefix via explicit GET routes and keep e.Static only for any other files, OR drop e.Static for app.* entirely. Decide by the running binary, not by assumption.

### D-2 — Canonical / OG absolute base URL = an env var (CANONICAL_BASE) defaulting to https://jonnify.fly.dev. Rationale: canonical + og:url need an absolute origin; the published site is jonnify.fly.dev (the host ec.6 cuts over). Configurable so the Fly app/Operator can override per environment; default keeps dev + prod correct with zero config. Director ruling (non-architecture minor; not an AskUserQuestion-class Arm).

### D-3 — og:image OMITTED for ec.5. Rationale: the published master carries ZERO Open Graph/image; no brand-cover raster asset exists in-repo; an SVG og:image is poorly supported by social scrapers. Ship og:title/og:type/og:url/og:description/og:site_name + canonical + twitter:card=summary (text-only summary card is valid without an image). A real PNG/JPG og:image is a future additive once a cover is produced — shipping a broken/unsupported image reference now would be worse than none. Director ruling (non-architecture minor). The index <meta description> stays byte-identical to the published master (strict-parity duty); detail descriptions = Course.Summary.

### D-4 — Runbook bakes D-1/D-2/D-3 as SETTLED, not open

echo-courses.5.prompt.md states the three Director-ruled forks as locked contracts Mars builds TO (not questions to reopen):
- D-1 asset-serving = Arm A1 embed + content-hash route: `//go:embed templates static`; boot-time sha256 → `/static/app.<hash8>.css` + `/static/app.<hash8>.js` served from embedded bytes with `Cache-Control: public, max-age=31536000, immutable`; hashed URLs injected into the layout (`<link>` in head, `<script defer>` before `</body>`).
- D-2 canonical/OG base = env `CANONICAL_BASE`, default `https://jonnify.fly.dev`.
- D-3 og:image OMITTED (published master has zero OG; no cover asset; SVG OG poorly supported). Ship og:title/type/url/description/site_name + canonical + twitter:card=summary. Index `<meta description>` stays BYTE-IDENTICAL to published; detail descriptions = Course.Summary.
The Stage-2 build directive enumerates these as fixed; reopening any is out of scope for this rung.

### D-5 — Per-page meta + asset-URL injection mechanism = Mars's call (two named options, spec fixes the CONTRACT not the form)

The spec/runbook fixes WHAT each page's head must render (the contract: hashed-asset link/script tags + per-page title/description/og/canonical) and leaves the Go SHAPE to Mars, noting both viable options:
- Option A — a shared Head struct threaded into every page's view-model (indexData/detailData gain an embedded Head{AssetCSS, AssetJS, Title, Description, OGTitle, OGURL, CanonicalURL, …}), populated by the handler; layout.html reads `.Head.*`. Pro: explicit, testable, no template-funcs; Con: every view-model embeds Head.
- Option B — a template FuncMap (`assetURL "app.css"`, `canonical .Path`, `ogTitle .`) registered on the render set, reading boot-computed hashes + a CANONICAL_BASE the renderer closes over; layout.html calls the funcs. Pro: handlers stay lean; Con: funcs carry hidden state.
Either satisfies the ACs. The byte-equivalence test, the URL-parity battery, and the head-inspection checks are shape-agnostic. Mars picks one and states it; the Director accepts at the contract boundary.

### D-6 — per-page-meta + asset-URL injection = Option A (Head struct), hybrid form. RESOLVED (Mars's call per runbook D-5).

Rationale: render.go's New(fsys) parses each page set via template.New(name).ParseFS(...) with NO .Funcs() registered. html/template requires funcs to be registered BEFORE parse, so Option B (a FuncMap closing over the boot hashes) would force a render-layer change to thread funcs into every ParseFS call — a wider blast radius than the contract needs. Option A keeps render.go PRISTINE.
Form: a render.Head struct (exported, beside render.Card) carrying both the global asset URLs (CSSHref, JSHref — the boot-computed /static/app.<hash>.{css,js}) AND the per-page meta (Title, Description, CanonicalURL, OGType). It is embedded in indexData/detailData; the handlers (which hold an *Assets value built once at boot + CANONICAL_BASE) populate it per request. This is the runbook's sanctioned hybrid: "A FuncMap suits the global asset hashes; per-page meta needs page data — a hybrid is fine" — here unified into ONE Head struct the handlers fill, so there is a single injection mechanism, no FuncMap, no render.go edit. layout.html reads .Head.* in <head> and before </body>.

### D-7 — Stage-4 (Mars-2 remediate+harden) COLLAPSED. Rationale: the Director's Stage-3 independent verify found zero blocking findings (gate green, byte-equivalence proven, parity + asset immutable-cache + SEO + CANONICAL_BASE-consumed + mutation-teeth all pass). The lone observation (L-5, HEAD→405 on asset routes) is non-blocking with no production impact. Per the cost-discipline calibration (right-size formation; rigor is constant, ceremony scales), a clean verified-green rung ships without spawning a build agent for a cosmetic one-liner. Proceed to Stage-5 ship.



## {ec-5-alternatives} Alternatives

### V-1 — Asset-serving arms (Director/Operator ruled A1; recorded for the audit trail)

The D-1 fork weighed three arms for closing the embed/disk asymmetry + cache-busting:
- A1 (RULED): embed `static` + a content-hash route `/static/app.<hash8>.css|js` from embedded bytes, immutable Cache-Control, hashed URL injected. Pro: single-binary deploy (no static files on disk — symmetric with templates already embedded ec.2), correct cache invalidation by construction (a byte change → a new hash → a new URL), no build-step asset pipeline. This is the published-parity caching behavior the rung exists for.
- A2 (against): keep `e.Static` from disk + a `?v=<hash>` query string. Con: leaves the disk dependency the single-binary deploy is meant to remove; query-string busting is weaker (some CDNs ignore the query) and asymmetric with the embedded templates.
- A3 (against): a full asset pipeline (esbuild/minify). Con: over-scoped for an M polish rung; the CSS/JS are already hand-authored verbatim-from-published — minifying would BREAK the byte-equivalence invariant that is the rung's signature. Explicitly out.
A1 wins on single-binary symmetry + correct invalidation + preserving byte-equivalence.

## {ec-5-learnings} Learnings

### L-1 — "interactive assets" (AC2) is a landing-rung trap; resolve it to the as-built scripts, not invented widgets

The spec's AC2 ("a course page with interactive elements … its interactive assets load and the interactions run") reads, at face value, like per-course interactive widgets. But ec.4 D-3 made every detail page a LANDING (Course.Body + header) with zero per-course interactivity. The only interactive assets in the whole site are the TWO inline scripts: the index track-filter (pages/index.html:22-34) and the global reveal-on-scroll (layout.html:146-149). ec.5 EXTERNALIZES those two into app.<hash>.js; it does NOT author new widgets (that would be invented scope, violating NO-INVENT + the §9 non-goal "no client-side framework rewrites"). Reconciled AC2 in echo-courses.5.md with a [RECONCILE] note. Same class as the F6.6 mechanism-word lesson: a spec phrase must be reconciled to the as-built primitive, or it mis-directs the build toward inventing surface.

### L-2 — Generate the externalized assets FROM the HEAD bytes, never by hand.

app.css/app.js were produced by slicing the exact byte ranges out of `git show HEAD:...` (sed -n '14,110p;113,134p' for the two CSS bodies; '147,148p' + index '23,33p' for the two scripts), so the signature byte-equivalence diff is EMPTY by construction, not by careful retyping. This is the mars.md "a verbatim port diffs against the CURRENT source" lesson applied at authoring time: the source of the bytes IS the diff baseline, so there is no reflow/stray-byte hazard. The two diffs (CSS, JS) were re-run after every template edit and stayed empty.

### L-3 — D-5 Option A (Head struct) routes ALL head meta through layout.html, so course.html needed NO edit (runbook item 7 collapses).

The head meta (title via the existing {{block "title"}}, description/canonical/og/twitter via .Head.*) renders ONCE in layout.html reading .Head.*. Because indexData and detailData both embed render.Head and the handlers populate it, pages/course.html required no per-page meta block — the realization of runbook item 7's intent without touching that template. Net: layout.html + index.html are the only template edits; course.html is byte-unchanged. This is why Option A beats Option B here — a single injection point in the layout, render.New stays FuncMap-free (no render.go signature change).

### L-4 — Echo v5 radix router: a concrete static route and a wildcard on the same prefix COEXIST (no panic), concrete wins by priority.

The runbook's open caveat ("verify the explicit /static/app.<hash>.* routes coexist with e.Static('/static',…)") resolved BY THE RUNNING BINARY: e.Static registers GET /static/* (echo.go:596 pathPrefix+"*"); the explicit GET /static/app.<hash>.{css,js} are fully-static paths. Live proof on :18755 — the hashed CSS/JS served 200 from embedded bytes WHILE /static/version.txt still served 200 from disk AND a wrong hash /static/app.00000000.css fell through to 404. So the content-hash routes and the disk e.Static fallback compose cleanly; no e.Static removal needed (version.txt keeps serving). Decided by test, not assumption.

### L-5 — Non-blocking observation: the content-hash asset routes (asset.Register → e.GET) answer GET only; a HEAD to /static/app.<hash>.css returns 405, whereas the disk e.Static handler answers HEAD. No production impact (browsers/CDNs GET assets; immutable assets never revalidate; Fly health is on /healthz GET), so NOT a blocker for ec.5. If a future rung wants HEAD parity for static assets, register e.HEAD alongside e.GET in asset.Register (a one-liner) — documented here so it is not lost. Also: a measurement-method trap — curl -I (HEAD) made a correct immutable Cache-Control read as absent; verify headers with curl -D - on a GET for GET-only routes.



## {ec-5-report} Report

### Y-1 — Stage-1 complete: ec.5 runbook authored + spec reconciled (BUILD-GRADE)

DELIVERABLES:
1. AUTHORED docs/echo_courses/echo-courses.5.prompt.md — the ship runbook, mirroring echo-courses.4.prompt.md: rung-in-one-paragraph; Mode (Flat-L2, Director + ONE mars, NORMAL, no Apollo); D-1/D-2/D-3 stated as SETTLED contracts (verbatim, not questions); the 8-file build topology; per-stage prompts (Stage-2 Mars build, Stage-3 Director verify, Stage-4 Mars-2 harden, Stage-5 Director ship + Stage-6 fold); the gate (the SIGNATURE byte-equivalence proof via git-show-extract-concat-diff + the local-dev-server URL-parity/asset-route/sitemap/robots/head-inspection battery + the CANONICAL_BASE-consumed check + link + markup); acceptance (ACs 1-6 + roadmap §8 gates); verification = LOCAL DEV SERVER (fly deploy = Operator, ec.4 D-4 standing); the scoped commit pathspec.
2. RECONCILED docs/echo_courses/echo-courses.5.md — 6 [RECONCILE] markers: AC1 (byte-equivalence = signature invariant + the proof), AC2 (interactive assets = the TWO existing inline scripts externalized, no new widgets — landings per ec.4 D-3), AC3 (OG/canonical additive; index description byte-identical to published; og:image omitted D-3; canonical from CANONICAL_BASE D-2), the two scope asset bullets (embed + content-hash D-1), the §ec5-spec mechanism + blockquote + §ec5-risks (signature invariant + content-hash invalidation + the dead-env-key check), and the blockquote (dropped "fonts" — as-built loads fonts from the Google CFD CDN, not web/static).

VERDICT: BUILD-GRADE. Every spec claim is MATCH-against-as-built or an explicit [RECONCILE]-marked correction; zero STALE/INVENTED/MISSING left. Grounding probes all PROBE-not-config: embed.go:16 (templates-only embed), main.go:100 (disk e.Static), layout.html:8 (meta-description verbatim vs html/index.html:7), layout.html:13-135 (two <style> blocks), layout.html:146-149 + pages/index.html:22-34 (the two scripts), html/index.html (zero og/canonical/favicon/json-ld — the lone canonical hit is body text line 192).

LEDGER: D-4 (runbook bakes D-1/2/3 settled), D-5 (per-page-meta mechanism = Mars's call, Option A Head-struct / Option B FuncMap), V-1 (asset-serving arms — A1 ruled), L-1 (AC2-is-the-two-scripts trap), T-2 (the as-built reconcile). msh link-lint over docs/echo_courses = no findings.

NO FORK for the Operator — all forks were pre-ruled (D-1/2/3); the one open implementation choice (D-5) is a build-shape detail, not an architecture fork, correctly left to Mars.

Everything left in the working tree for the Director to ratify. No git, no code touched.

### Y-2 — ec.5 BUILD-GRADE (Mars Stage-2). Full gate green; ready for Director verify.

The polish is built additively over the live ec.4 site, boundary go/echo-courses only. All six ACs satisfied: AC1 design system externalized + byte-equivalent (signature diff EMPTY); AC2 interactivity externalized to app.js (the two existing scripts, no new widget); AC3 per-page head (title/description/og×5/canonical/twitter; index description byte-identical to published; detail = Summary; no og:image per D-3); AC4 /sitemap.xml (6 absolute URLs) + /robots.txt valid; AC5 binary serves the complete styled site (every published path 200) — local-dev-server equivalent, fly deploy is the Operator's; AC6 zero structural markup errors. D-5 = Option A (Head struct), unifying the head in layout.html (render.go untouched, FuncMap-free; course.html needs no edit). D-1/D-2/D-3 built to as contracts. 13 files (9 modified + 4 new), all in go/echo-courses; go/echo untouched; no spec edit; no commit (Director's at Stage-5). Net-zero proven against a HEAD-binary diff: only the head/asset wiring changed, the body sections are byte-identical. Determinism: 20/20 + shuffle + cross-boot hash stability (stateless rung, not the ≥100 class). Three learnings folded (L-2 generate-from-HEAD-bytes, L-3 Option-A-collapses-course.html, L-4 radix-router-coexistence). Open for Stage-3 independent verify.

### Y-3 — Director Stage-3 independent verify: BUILD-GRADE, zero blocking findings.

Re-ran on the LOCAL DEV SERVER (no Docker; fly deploy is the Operator's, ec.4 D-4):
- GATE (GOWORK=off, from go/echo-courses): go build ✓ · go vet ✓ · go test -count=1 (uncached) all PASS · gofmt -l empty ✓.
- BOUNDARY: only go/echo-courses + docs/echo_courses touched; the other untracked trees (elixir/, go/echomq-go/, go/jonnify-cms/, go/valkey-go/) are pre-existing Operator out-of-band (present in the opening snapshot), untouched by ec.5.
- SIGNATURE PROOF (byte-equivalence, independent re-extract from HEAD via awk between the <style>/<script> markers, diffed): CSS app.css == the two HEAD <style> bodies (119 lines) ✓; JS app.js == HEAD reveal + filter scripts (13 lines) ✓. The look cannot have drifted.
- URL PARITY: /courses · / · /elixir · /redis-patterns · /echomq · /course/agile-agent-workflow · /bcs · /courses/elixir all 200; /courses/nope 404 ✓ (ec.4 not regressed).
- ASSET ROUTES (D-1): GET /static/app.<hash>.css|js → 200, exact Content-Type (text/css|text/javascript; charset=utf-8), Cache-Control: public, max-age=31536000, immutable (verified on GET with curl -D -; the earlier empty was a HEAD-probe artifact — Echo GET-routes 405 on HEAD); wrong hash → 404 ✓.
- SEO: /sitemap.xml → 200 application/xml, lists /courses + all 5 published paths absolute under CANONICAL_BASE ✓; /robots.txt → 200, allow-all + Sitemap: line ✓.
- HEAD: index <meta description> BYTE-IDENTICAL to html/index.html:7 (diff empty) ✓; canonical/og:title/type/url/description/site_name + twitter:card=summary present, no og:image (D-3) ✓; /elixir description = Course.Summary, og:type=article, canonical=/elixir ✓; residual inline <style>/IntersectionObserver/filter in rendered / = 0 ✓.
- D-2 CONSUMED: CANONICAL_BASE=https://example.test flip moved canonical + og:url + sitemap loc to example.test ✓ (not a dead key).
- GRACEFUL: SIGTERM → exit 0 ✓.
- MUTATION (net-zero, LAW-1a): dropped the /courses sitemap loc → TestSitemap failed (missing url + count 5≠6); reverted; post-revert green. Tests have teeth; Director authored no production code.

Verdict: ship. Stage-4 (Mars-2 harden) COLLAPSES — zero blocking findings.

## {ec-5-complete} Complete

### Z-1 — ec.5 SHIPPED (polish the live echo-courses site). Flat-L2, right-sized: Director + Venus + Mars; Stage-4 collapsed (D-7, zero blocking findings). Verified on the LOCAL DEV SERVER; fly deploy is the Operator's (ec.4 D-4 standing).

Delivered: the design-system CSS + the two interactive scripts externalized to embedded, content-hash-served web/static/app.<hash>.{css,js} (Cache-Control immutable; byte-equivalent to the former inline blocks — signature proof empty, CSS 119 / JS 13 lines); per-page SEO title/description + Open Graph (no og:image, D-3) + canonical from CANONICAL_BASE (D-2, verified consumed); GET /sitemap.xml + /robots.txt. The site stayed complete + live (all published paths 200).

Decisions: D-1 (Arm A1 embed+content-hash, Operator-ruled) · D-2 (CANONICAL_BASE) · D-3 (og:image omitted) · D-4 (runbook bakes settled) · D-5/D-6 (injection = Option A Head struct) · D-7 (Stage-4 collapse). Report: Y-3 (Director verify BUILD-GRADE). Learnings: L-1..L-5 (incl. L-5 the non-blocking HEAD→405 observation).

Commit: two scoped LAW-4 pathspec commits — go/echo-courses (the build) + docs/echo_courses (spec→Built + roadmap status + ledger). go/echo already tracked → no vendor commit. Operator landed echo-courses.5.prompt.md out-of-band (ecd355a0). Next: ec.6 the production cutover (HIGH; Apollo-mandatory).
