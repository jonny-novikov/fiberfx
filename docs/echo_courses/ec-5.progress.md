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

## {ec-5-report} Report

### Y-1 — Stage-1 complete: ec.5 runbook authored + spec reconciled (BUILD-GRADE)

DELIVERABLES:
1. AUTHORED docs/echo_courses/echo-courses.5.prompt.md — the ship runbook, mirroring echo-courses.4.prompt.md: rung-in-one-paragraph; Mode (Flat-L2, Director + ONE mars, NORMAL, no Apollo); D-1/D-2/D-3 stated as SETTLED contracts (verbatim, not questions); the 8-file build topology; per-stage prompts (Stage-2 Mars build, Stage-3 Director verify, Stage-4 Mars-2 harden, Stage-5 Director ship + Stage-6 fold); the gate (the SIGNATURE byte-equivalence proof via git-show-extract-concat-diff + the local-dev-server URL-parity/asset-route/sitemap/robots/head-inspection battery + the CANONICAL_BASE-consumed check + link + markup); acceptance (ACs 1-6 + roadmap §8 gates); verification = LOCAL DEV SERVER (fly deploy = Operator, ec.4 D-4 standing); the scoped commit pathspec.
2. RECONCILED docs/echo_courses/echo-courses.5.md — 6 [RECONCILE] markers: AC1 (byte-equivalence = signature invariant + the proof), AC2 (interactive assets = the TWO existing inline scripts externalized, no new widgets — landings per ec.4 D-3), AC3 (OG/canonical additive; index description byte-identical to published; og:image omitted D-3; canonical from CANONICAL_BASE D-2), the two scope asset bullets (embed + content-hash D-1), the §ec5-spec mechanism + blockquote + §ec5-risks (signature invariant + content-hash invalidation + the dead-env-key check), and the blockquote (dropped "fonts" — as-built loads fonts from the Google CFD CDN, not web/static).

VERDICT: BUILD-GRADE. Every spec claim is MATCH-against-as-built or an explicit [RECONCILE]-marked correction; zero STALE/INVENTED/MISSING left. Grounding probes all PROBE-not-config: embed.go:16 (templates-only embed), main.go:100 (disk e.Static), layout.html:8 (meta-description verbatim vs html/index.html:7), layout.html:13-135 (two <style> blocks), layout.html:146-149 + pages/index.html:22-34 (the two scripts), html/index.html (zero og/canonical/favicon/json-ld — the lone canonical hit is body text line 192).

LEDGER: D-4 (runbook bakes D-1/2/3 settled), D-5 (per-page-meta mechanism = Mars's call, Option A Head-struct / Option B FuncMap), V-1 (asset-serving arms — A1 ruled), L-1 (AC2-is-the-two-scripts trap), T-2 (the as-built reconcile). msh link-lint over docs/echo_courses = no findings.

NO FORK for the Operator — all forks were pre-ruled (D-1/2/3); the one open implementation choice (D-5) is a build-shape detail, not an architecture fork, correctly left to Mars.

Everything left in the working tree for the Director to ratify. No git, no code touched.
