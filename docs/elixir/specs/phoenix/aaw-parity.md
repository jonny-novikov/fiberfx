# AAW-parity — a THIRD static parity page through Phoenix

> **Workload, not a chapter rung.** This is a concise parity contract + MarsAAW build brief,
> following the established two-parity-page pattern (`/` ↔ `html/courses.html`, `/elixir` ↔
> `elixir/index.html`). It adds a THIRD: `:4000/course/agile-agent-workflow` ↔
> `html/agile-agent-workflow/index.html`. The contract is the single source of truth; the
> stories live inline (§4 acceptance + §9 e2e), the brief is §6–§8.

**Status: BUILD-GRADE — SHIPPED + verified (ApolloAAW post-build reconcile).** The Director ratified
the new public route + action (§3); MarsAAW built the seven files; ApolloAAW reproduced the full gate
against the Director's durable `:4000`. Post-build delta: every promise (R1-R6, the §7 taxonomy, the
two-sided INV9, the five guardrails) is **MATCH** — the two relocated assets are **byte-identical** to
the master line ranges (CSS = master 12-308 + 327-338; JS = 709-733 + 737-752), the §7 href counts are
**exact** in both template source and rendered DOM (23 + 5 category-4 remaps, 1 bare index, 4 bare
`/elixir`, 0 un-remapped deep links), and the page carries **no** `<meta name="deep-link-base">` (the
agile JS builds no deep links — §1.3 confirmed). Gate reproduced: `mix compile --warnings-as-errors`
clean, `mix test` 39 tests (3 ConnTests incl. the new agile) 0 failures, the portal_web determinism
loop **100/100 GREEN**, the e2e parity suite **20/20** on BOTH the default and the `example.test`
override base. Nothing INVENTED; no boundary leak (the template names only `deep_link_base/0`).

**Framing (propagate into all build work):** no gendered pronouns for agents; no perceptual or
interior-state verbs; no first-person narration.

---

## 0. Why this rung exists (two things at once)

1. **A real strangler-fig expansion.** The home page's "agents" card today REMAPS to production:
   `home.html.heex:41` is `href={PortalWeb.deep_link_base() <> "/course/agile-agent-workflow"}`.
   Making Portal SERVE that route flips the card to LOCAL/relative — a click then navigates
   WITHIN the Portal to a styled parity page. The flip ALSO brings the home page closer to its
   own golden master: `html/courses.html:163` has the card RELATIVE (`href="/course/agile-agent-workflow"`),
   while the Portal currently renders it remapped. One edit closes both gaps.
2. **A mentoring measurement.** Same workload as the two prior parity pages, same Venus→Mars→Apollo
   loop. The FIVE guardrails (§5) are written as EXPLICIT acceptance gates ApolloAAW can score —
   if the mentoring took, each fires pre-emptively and nothing recurs.

---

## 1. Reconcile — the as-built pattern is CONFIRMED (probe + read)

All probes run against the LIVE node the Director keeps hot at `:4000` and the Fiber baseline at
`:8765`. **A serving/route surface-fact is discharged by a probe, never a config-read** (the
`endpoint.ex` moduledoc records that the F6.5.5 `at:"/assets"` mount read-as-correct yet 404'd —
the cure was a curl, not a re-read).

### 1.1 Probe results (live)

| Probe | Result | Reading |
|---|---|---|
| `curl :4000/` | `200`, 4531 B | Portal serves the courses index (`home/2`). |
| `curl :4000/elixir` | `200`, 33718 B | Portal serves the elixir index (`elixir/2`). |
| `curl :4000/course/agile-agent-workflow` | `404`, 9 B | The new route is UNSERVED pre-build (correct). |
| `curl :4000/assets/elixir-index.css` | `200`, `text/css` | `Plug.Static at:"/"` serves co-located assets (FIX A holds). |
| `curl :4000/assets/agile-index.css` | `404`, `text/html` | The new asset is ABSENT pre-build (correct). |
| `curl :8765/course/agile-agent-workflow` | `200`, 46116 B, `text/html` | The Fiber baseline serves the master — the parity origin. |

### 1.2 Pattern claims (read from code)

| Claim | Evidence | Class |
|---|---|---|
| Two thin actions, no facade call, no assigns, `layouts: []` | `page_controller.ex:19-28`; `portal_web.ex:42-43` | MATCH |
| Public scope `scope "/", PortalWeb`, `get("/",…)` + `get("/elixir",…)` | `router.ex:59-69` (lines 62-63) | MATCH |
| `deep_link_base/0` = config, default `https://jonnify.fly.dev`, CATEGORY-4-only, NOT for `~p"/assets/…"` | `portal_web.ex:16-27` | MATCH |
| The elixir template REMAPS every `/elixir/<sub>` deep link inline (`deep_link_base() <> "/elixir/…"`) and keeps bare `/elixir` relative | `elixir.html.heex:22,24,41,42,134,197-203,220,225-236` | MATCH |
| `<meta name="deep-link-base" content={PortalWeb.deep_link_base()}>` exists ONLY because `elixir-index.js` (a Plug.Static file) builds the arc "Open Fn" deep link and cannot read Elixir config | `elixir.html.heex:12-15`; `portal_web.ex:19-24` | MATCH |
| Assets are `~p"/assets/…"` (`<link>` head + `<script>` foot) | `elixir.html.heex:11,254` | MATCH |
| `Plug.Static at:"/", only: static_paths()` (FIX A) | `endpoint.ex:34-38` | MATCH |
| Home agile card remaps to production | `home.html.heex:41` | MATCH |
| Golden master courses.html has the agile card RELATIVE | `html/courses.html:163` | MATCH (the flip target) |
| `index-parity.spec.ts` = two `describe` blocks (COURSES, ELIXIR), two origins, computed-style + geometry + remap + asset-locality, `NAV_BASE`-driven | `apps/e2e/tests/index-parity.spec.ts:92-292` | MATCH |
| `phoenix.operator.md` exists; §5 is the live-Portal runbook | `phoenix.operator.md:132` | MATCH (Apollo EXTENDS, not authors from scratch) |

**No STALE / INVENTED / MISSING claims.** The one DEFERRED item is the new route+action, which
is a Director-ratified ADDITION (§3), not a drift.

### 1.3 The master — structure read (the parity source)

`html/agile-agent-workflow/index.html`, 755 lines. **OPERATOR OUT-OF-BAND — a read-only parity
source. NEVER edit or commit `html/agile-agent-workflow/*`.** It is ACTIVELY AUTHORED by the
Operator, so parity is against the CURRENT SNAPSHOT (drift caveat, §10).

| Region | Lines | Note |
|---|---|---|
| `<head>` boilerplate (charset, viewport, title, description) | 4-7 | Title: "Agile Agent Workflow in Elixir — Pragmatic Programming with Claude Agents · jonnify" |
| Google Fonts preconnect + stylesheet (CDN) | 8-10 | CATEGORY-3 external — UNTOUCHED |
| **`<style>` block #1 (head)** | **11-309** | opens `<style>` @11, content 12-308, `</style>` @309 |
| `</head>` / `<body>` | 310-311 | |
| `<header>` … `</header>` | ~315-321 | brand + nav cross-links to `/elixir`, `/elixir/course` |
| `<main id="main" class="wrap">` | 324 | |
| **`<style>` block #2 (body inline, right after `<main>`)** | **326-339** | opens `<style>` @326, content 327-338, `</style>` @339 — `.mod .dives`, `.foot-cols`, `.foot-bottom` rules |
| body content (hero, sections, footer) | 341-707 | |
| **`<script>` block #1** | **708-734** | Snowflake branded-id decoder for the build stamp — pure string math, **builds NO URLs** |
| **`<script>` block #2** | **736-753** | scroll-reveal IntersectionObserver — **builds NO URLs** |
| `</body></html>` | 754-755 | |

**Decisive finding (drives §7): neither `<script>` block builds any `/course/...` deep link.**
Block #1 decodes the build-stamp id (Base62 string math); block #2 reveals `.reveal` elements on
scroll. → **NO `<meta name="deep-link-base">` injection is needed for the agile page.** Mars MUST
NOT cargo-cult the elixir template's `<meta>` tag (that tag exists solely for `elixir-index.js`'s
arc link-builder, which the agile JS has no analogue of).

---

## 2. The deliverable surface (what Mars builds)

A single new full-document parity page + its two relocated assets + the route/action + the home-card
flip + the e2e extension. Presentation only — names no facade, engine, repo, or any module below
the boundary.

---

## 3. FORK for the Operator — the new public route + action (RATIFY before build)

A new HTTP surface is the Operator's call. Two adds, both presentation-only:

- **Action:** `PageController.agile/2` → `render(conn, :agile)` — appended to `page_controller.ex`,
  identical in form to `home/2`/`elixir/2` (no params, no facade call, no assigns).
- **Route:** `get("/course/agile-agent-workflow", PageController, :agile)` — added to the public
  `scope "/", PortalWeb` block (`router.ex:59-69`), alongside `get("/", …)` and `get("/elixir", …)`.

This names only a controller + an action (the router's discipline: no module below the boundary).
It does NOT touch the protected scope, the `:api` scope, the LiveView routes, or any pipeline.
**This is the ONE decision the contract does not make for the Director.** Everything downstream is
fixed by this contract.

---

## 4. Acceptance stories (each Deliverable → a Given/When/Then story)

> **D1 — the served parity page.**
> *As a learner on the Portal, I want the agile-agent-workflow course index to open WITHIN the
> Portal in the design system, so that the home "agents" card lands on a styled local page, not a
> jump to production.*
> - **Given** the node is live at `:4000`, **When** I `GET /course/agile-agent-workflow`, **Then**
>   I receive `200 text/html` whose `<h1>` and body reproduce the master and whose computed type
>   scale + geometry match the Fiber baseline at `:8765/course/agile-agent-workflow`.
> - Exercises: INV-PARITY, INV-CLAMP.

> **D2 — the home-card flip (closer to golden master).**
> *As the Portal home page, I want the "agents" card to link to the now-served local route, so
> that I match my golden master (`courses.html`) and keep navigation inside the Portal.*
> - **Given** the agile route is served, **When** I render `/`, **Then** the agile card's `href`
>   is relative `/course/agile-agent-workflow` (NOT `deep_link_base() <> …`), and clicking it
>   lands on the Portal agile page (`200`), never production.
> - Exercises: INV-NAV, INV-LOCALITY (the card is the page's own served route → category 1/5).

> **D3 — asset locality (two-sided).**
> *As an operator, I want the agile page's CSS/JS served from the Portal's own `priv/static`, so
> that the page is a live local asset, not a hollow shell pointing at production.*
> - **Given** the page is served, **When** I `GET /assets/agile-index.css` and `…/agile-index.js`,
>   **Then** each returns `200` with the right content-type, no redirect, and the rendered markup
>   references them as root-relative `~p"/assets/agile-index.{css,js}"` — never the deep-link base.
> - Exercises: INV-LOCALITY, INV9(b).

> **D4 — the deep-link taxonomy (configurable base, category 4 only).**
> *As a maintainer, I want every internal href classified keep-vs-remap, so that exactly the
> non-served deep links carry the configurable production base and nothing else does.*
> - **Given** the page is rendered, **When** I scan its anchors, **Then** the 23 `/course/agile-agent-workflow/<sub>`
>   deep links and the 5 `/elixir/course` cross-links carry `deep_link_base()`, the bare
>   `/course/agile-agent-workflow` + the 4 bare `/elixir` + the assets stay relative, the CDN refs
>   and `#anchors` are untouched, and ZERO un-remapped `/course/...` or `/elixir/...` deep links
>   survive.
> - Exercises: INV-NAV, INV9(a).

**Coverage:** D1 → §6-R1/R2 (route+template); D2 → §6-R5 (card flip); D3 → §6-R3 (assets) + §8;
D4 → §7 (taxonomy). Every Deliverable maps to a build requirement and an e2e check (§9).

---

## 5. The FIVE guardrails as explicit acceptance gates (ApolloAAW scores each)

Each guardrail is a CHECK with a pass/fail oracle. This is the mentoring measurement: did the prior
two parity pages' lessons fire pre-emptively here.

| # | Guardrail | The gate (oracle) | Where enforced |
|---|---|---|---|
| G1 | **clamp-spacing** | `grep -nE 'clamp\([^)]*[+-][^ 0-9.]' priv/static/assets/agile-index.css` returns ZERO (no `+`/`-` immediately followed by a non-space, non-digit — i.e. every arithmetic operator stays SPACED). The master is clean (9 `clamp()`, all spaced, e.g. `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)`); the relocation is VERBATIM, so this stays clean. e2e: agile `<h1>` computed `font-size` > 70px at both origins. | §6-R3, §9 |
| G2 | **probe-not-config-read** | The serving facts in §1.1 were obtained by `curl`, not by reading `endpoint.ex`. Apollo re-probes post-build: `curl :4000/course/agile-agent-workflow` → 200, `curl :4000/assets/agile-index.css` → 200 text/css. A config-read is NOT an acceptable proof. | §1.1, §8 |
| G3 | **standing-liveness** | The liveness check leaves `:4000` UP. NEVER boot→curl→kill. Probe the ALREADY-RUNNING node (`recompile()` in the warm iex, or a fresh `mix phx.server` left running) — `curl -fsS :4000/health` → 200 AND `curl -fsS :4000/course/agile-agent-workflow` → 200, the node still serving afterward. | §8, operator.md §5 |
| G4 | **asset-locality (two-sided)** | (a) `curl :4000/assets/agile-index.css` → 200 `text/css`, `…/agile-index.js` → 200 (`text/javascript`/`application/javascript`), no redirect; (b) the rendered page references them as `~p"/assets/…"` and ZERO `/assets/...` ref is an absolute URL / carries the deep-link base. e2e mirrors the elixir asset-locality test. | §8, §9 |
| G5 | **configurable-base** | No `jonnify.fly.dev` literal outside the config default (`portal_web.ex:27`). Boot with `DEEP_LINK_BASE_URL=https://example.test` + run e2e with `PORTAL_DEEP_LINK_BASE=https://example.test`: every category-4 deep link re-renders with the override, the assets do NOT. | §7, §9 |

---

## 6. MarsAAW brief — Requirements (numbered, each traced to a story + an invariant)

> **References (read these first, in order):**
> 1. This contract (the authority).
> 2. The as-built pattern to clone: `echo/apps/portal_web/lib/portal_web/controllers/page_html/elixir.html.heex`
>    (the full-document template + the inline `deep_link_base()` remap idiom), `page_controller.ex`
>    (the action form), `router.ex:59-69` (the public scope), `portal_web.ex:16-27` (`deep_link_base/0`).
> 3. The parity source (READ-ONLY, never edit): `html/agile-agent-workflow/index.html`.
> 4. The e2e template to extend: `apps/e2e/tests/index-parity.spec.ts`.

**R1 — the action** (→ D1, INV-PARITY). Append to
`echo/apps/portal_web/lib/portal_web/controllers/page_controller.ex`:
```
@doc "Render the static agile-agent-workflow course index at /course/agile-agent-workflow — a 200, no domain call."
def agile(conn, _params), do: render(conn, :agile)
```
Precondition: none. Postcondition: a `200` rendering `page_html/agile.html.heex`. Invariant: names
no facade/engine/repo (INV1).

**R2 — the route** (→ D1, INV-PARITY). In `echo/apps/portal_web/lib/portal_web/router.ex`, inside
the existing `scope "/", PortalWeb do … end` (lines 59-69), after `get("/elixir", …)`:
```
get("/course/agile-agent-workflow", PageController, :agile)
```
Invariant: one URL named after its resource; no overlap with `resources`/`live`.

**R3 — the template** (→ D1, INV-CLAMP, INV-LOCALITY). New file
`echo/apps/portal_web/lib/portal_web/controllers/page_html/agile.html.heex` — the FULL
`<!doctype html>…</html>` reproducing the master `html/agile-agent-workflow/index.html`, with
exactly these transforms and NOTHING else:
- The head `<style>` block (master 11-309) → REMOVED; replaced by
  `<link rel="stylesheet" href={~p"/assets/agile-index.css"}>` in the head (the elixir page's
  position, `elixir.html.heex:11`).
- The body inline `<style>` block (master 326-339) → its body is FOLDED INTO the same
  `agile-index.css` (see R4); the inline block is REMOVED from the template (no second `<style>`).
- The two `<script>` blocks (master 708-734, 736-753) → REMOVED; replaced by a single
  `<script src={~p"/assets/agile-index.js"}></script>` immediately before `</body>` (the elixir
  page's position, `elixir.html.heex:254`).
- **NO `<meta name="deep-link-base">` tag** — the agile JS builds no deep links (§1.3). Do not add it.
- Every internal href rewritten per the §7 taxonomy.
- Everything else (markup, classes, SVGs, text, the CDN font links, `#anchors`) — VERBATIM.
Postcondition: `curl :4000/course/agile-agent-workflow` → 200 text/html; computed-style + geometry
parity with the Fiber baseline.

**R4 — the assets (VERBATIM relocation)** (→ D3, G1, G4). Two new files under
`echo/apps/portal_web/priv/static/assets/`:
- **`agile-index.css`** = the two `<style>` BODIES concatenated VERBATIM, in document order:
  master lines **12-308** (head block inner) followed by master lines **327-338** (body inline
  block inner). Concatenate the inner content only (exclude the `<style>`/`</style>` tags). Do NOT
  reformat, re-indent, or re-space — every `clamp()` keeps its exact byte form (G1). The result is
  one stylesheet; the two ranges are non-contiguous in the master but adjacent in the asset.
- **`agile-index.js`** = the two `<script>` BODIES concatenated VERBATIM, in document order: master
  lines **709-733** (block #1 inner) followed by master lines **737-752** (block #2 inner). Exclude
  the `<script>`/`</script>` tags. No deep-link builder exists in either, so no `window.__deepLinkBase`
  read is added.

These filenames enter the served set automatically: `Plug.Static` serves `priv/static/assets/*`
via `static_paths()` (`endpoint.ex:34-38`; `portal_web.ex:14`) — no endpoint change needed.

**R5 — the home-card flip** (→ D2, INV-NAV, INV-LOCALITY). In
`echo/apps/portal_web/lib/portal_web/controllers/page_html/home.html.heex:41`, change the agile
card href from
`href={PortalWeb.deep_link_base() <> "/course/agile-agent-workflow"}`
to the relative
`href="/course/agile-agent-workflow"`
(now Portal-served — matches `courses.html:163`). Leave the rest of the card and `home.html.heex`
untouched. This moves one occurrence out of the deep-link-base set: `/`'s remap e2e (R6) updates
so the agile card is asserted LOCAL, not production.

**R6 — the e2e** (→ all, G1/G4/G5). Extend `apps/e2e/tests/index-parity.spec.ts` — see §9.

### Build-order task DAG

```
R1 action ─┐
R2 route  ─┼─► (route serves) ─► R3 template ─► (page renders)
R4 assets ─┘                          │
                                      ├─► R5 home-card flip (independent edit, same render path)
                                      └─► R6 e2e (asserts R1-R5)
```
R1+R2+R4 are independent and can land together; R3 depends on R4 (the `~p"/assets/agile-index.*"`
must resolve); R5 is independent; R6 closes over all.

### EXACT files MarsAAW touches (six)

| File | Change | New/Edit |
|---|---|---|
| `echo/apps/portal_web/lib/portal_web/controllers/page_controller.ex` | append `agile/2` | Edit |
| `echo/apps/portal_web/lib/portal_web/router.ex` | one `get(…)` in the public scope | Edit |
| `echo/apps/portal_web/lib/portal_web/controllers/page_html/agile.html.heex` | the full parity template | **New** |
| `echo/apps/portal_web/priv/static/assets/agile-index.css` | the 2 `<style>` bodies, verbatim | **New** |
| `echo/apps/portal_web/priv/static/assets/agile-index.js` | the 2 `<script>` bodies, verbatim | **New** |
| `echo/apps/portal_web/lib/portal_web/controllers/page_html/home.html.heex` | line 41 card → relative | Edit |
| `apps/e2e/tests/index-parity.spec.ts` | a 3rd `describe` (AGILE) + the nav test + asset-locality | Edit |

(Seven files in total; six in `portal_web`, one e2e.) **Do NOT create a `page_html/agile/`
function-component module** — the existing pages are full-document `.heex` templates rendered by
`render(conn, :agile)` against the `PageHTML` view; follow that, not generated component scaffolding.

---

## 7. The link taxonomy — a keep-vs-remap verdict for EVERY internal href

Grounded in the master scan. **The configurable base applies to CATEGORY 4 ONLY.** Counts are exact
(`grep`-verified against `html/agile-agent-workflow/index.html`).

| # | Category | Master occurrences (count) | Verdict | Rewrite |
|---|---|---|---|---|
| 1 | **Bare index** — the page itself, now Portal-served | `/course/agile-agent-workflow` @686 (×1, the footer "Course home") | **LOCAL / relative** | keep `href="/course/agile-agent-workflow"` |
| 2 | **Own assets** | the 2 `<style>`→`agile-index.css`, the 2 `<script>`→`agile-index.js` | **LOCAL** (Plug.Static) | `href={~p"/assets/agile-index.css"}`, `src={~p"/assets/agile-index.js"}` |
| 3 | **External CDN** | Google Fonts preconnect + stylesheet @8-10 (×3) | **UNTOUCHED** | verbatim |
| 4 | **Non-served deep links** — sub-pages + the elixir contents page (NOT Portal-served) | `/course/agile-agent-workflow/<sub>` (×23, distinct: `/what`×3, `/why`×3, `/decomposition`×2, `/roadmap`×2, `/spec`×2, `/brief`×2, `/reliability`×2, `/portal`×1, `/what/two-layer-model`×2, `/what/four-artifacts`×2, `/what/author-operator-loop`×2) **PLUS** `/elixir/course` @318,576,652,659,688 (×5) | **REMAP** | `href={PortalWeb.deep_link_base() <> "/course/agile-agent-workflow/<sub>"}` and `href={PortalWeb.deep_link_base() <> "/elixir/course"}` |
| 5 | **Portal-served self-routes** | bare `/elixir` @316,343,671,689 (×4, brand + crumb + footer) | **LOCAL / relative** | keep `href="/elixir"` |
| 5a | **In-page anchors** | `#main`@312, `#arc`,`#foundations`,`#modules`,`#exemplar` @359-362 (×5) | **UNTOUCHED** | verbatim |

**The split inside `/elixir*` mirrors the elixir template's own resolved fork** (`elixir.html.heex`):
bare `/elixir` is a Portal-served route → relative; `/elixir/course` is NOT served → remapped. This
is consistent precedent, NOT a new decision.

**Totals to assert (e2e):** after rewrite the rendered DOM has
- `hrefCount("/course/")` == 1 (the bare index only; the 23 sub-links now carry the base).
- `hrefCount(NAV_BASE + "/course/agile-agent-workflow/")` == 23.
- `hrefCount("/elixir/")` == 0 (all 5 `/elixir/course` now carry the base).
- `hrefCount(NAV_BASE + "/elixir/")` >= 5.
- bare `/elixir` relative count == 4; bare `/course/agile-agent-workflow` relative count == 1.

> **Note on `<meta>` injection (do NOT add it):** the elixir page injects
> `<meta name="deep-link-base">` ONLY for its static `elixir-index.js` arc link-builder. The agile
> JS (master 708-753) builds NO `/course/...` URL — both blocks were READ, confirming it. Therefore
> the agile page carries NO `<meta name="deep-link-base">` and NO `window.__deepLinkBase` read. All
> category-4 remaps are inline `deep_link_base() <> …` in the HEEx template (the server-rendered side),
> which is the ONLY boundary crossing the agile page needs.

---

## 8. The two-sided invariant (the INV9 discipline) + the standing-liveness check

**INV9 (two-sided):**
- **(a) configurable base.** No hardcoded `jonnify.fly.dev` survives outside the config default
  (`portal_web.ex:27`). Every category-4 deep link reads `deep_link_base()`. Proof: G5.
- **(b) asset locality.** The agile page's assets stay Portal-local. Proof: `curl :4000/assets/agile-index.css`
  → 200 `text/css`, `…/agile-index.js` → 200, no redirect; rendered refs are `~p"/assets/…"`; no
  `/assets/...` ref carries the base or is an absolute URL. Because the agile JS builds no deep
  links, there is NO injection point that could accidentally sweep an asset — (b) is structurally
  safe AND must still be checked.

**Standing-liveness (G3 — the load-bearing measurement):** the proof that the route serves is a
probe of the ALREADY-RUNNING `:4000` node, leaving it UP. The Director's durable boot persists; a
`recompile()` in that warm iex hot-loads the new modules. NEVER boot→curl→kill. The check:
`curl -fsS :4000/health` → 200 AND `curl -fsS :4000/course/agile-agent-workflow` → 200, with the
node still answering afterward. (operator.md §5 is the live-Portal runbook; this workload adds the
L0 sub-runbook, §11.)

---

## 9. The e2e — extend `index-parity.spec.ts` (the THIRD route + the navigation test)

Mirror the existing ELIXIR `describe` block (lines 181-292), adapted to the agile master, and ADD
the navigation test (a flip of the COURSES remap test). Concretely:

1. **Constants.** Add `const AGILE = { fiber: `${FIBER_BASE}/course/agile-agent-workflow`, portal:
   `${PORTAL_BASE}/course/agile-agent-workflow` };` alongside `COURSES`/`ELIXIR` (lines 51-58).

2. **`describe("AAW · /course/agile-agent-workflow parity — Phoenix vs Fiber")`** — two origins
   (`for (const [origin, url] of Object.entries(AGILE))`):
   - **type scale (clamp guard, G1):** the agile hero `<h1>` computed `font-size` > 70px at both
     origins (master hero `h1` clamp max is `clamp(2.7rem,1.9rem + 4.2vw,5.1rem)` ≈ 81.6px @1440; a
     dropped/unspaced clamp collapses it to ~32px). Plus a body-copy size guard analogous to
     `.prose p > 18px` against the agile page's body-text selector (READ the master to pick the
     real selector — do not invent one).
   - **geometry:** an above/below ordering of two stable landmarks (e.g. the hero section sits above
     the modules/`#modules` section; the `.mod` cards in a chapter occupy more than one distinct x —
     multi-column on desktop). Pick selectors that exist in the master.

3. **`remap (portal)` test** (D4, G5) — Portal origin ONLY (the Fiber baseline serves the
   un-remapped original):
   - `hrefCount("/course/")` == 1 (the bare index survives; all 23 sub-links carry the base).
   - `hrefCount(NAV_BASE + "/course/agile-agent-workflow/")` >= 23 (`> 0` is the load-bearing
     minimum; the exact 23 is the strong form).
   - `hrefCount("/elixir/")` == 0; `hrefCount(NAV_BASE + "/elixir/")` >= 5.
   - bare `/elixir` relative count == 4; the bare `/course/agile-agent-workflow` relative count == 1.
   - a spot-checked `.mod` deep link starts with `NAV_BASE + "/course/agile-agent-workflow/"`.
   - an in-page anchor (`a.skip` → `#main`) stays untouched.

4. **`asset-locality (portal)` test** (D3, G4) — mirror lines 273-291: the agile `<link>`/`<script>`
   are `/assets/agile-index.css` / `/assets/agile-index.js`; `hrefCount(NAV_BASE + "/assets")` == 0;
   zero absolute `/assets/...` URL.

5. **NAVIGATION test** (D2 — the new one, on the `/` page) — add to the COURSES `describe` (or its
   own): on `PORTAL_BASE + "/"`, the agile card (`.series-card[data-tags="agents"]`) has
   `href === "/course/agile-agent-workflow"` (LOCAL, NOT `NAV_BASE + …`), AND `page.goto` /
   `page.click` of it lands on `:4000/course/agile-agent-workflow` returning 200 (a real Portal page,
   not production). **Update the existing COURSES `remap (portal)` test** (lines 133-154): the agile
   card is no longer asserted as `NAV_BASE + "/course/agile-agent-workflow"` (×1) — it is now LOCAL.
   The `hrefCount("/course/")` on `/` becomes 1 (the relative agile card), and the
   `hrefCount(NAV_BASE + "/course/agile-agent-workflow")` on `/` becomes 0.

> The run recipe is unchanged from the header of `index-parity.spec.ts` (baseline against `:8765`,
> parity against `:4000`; G5 boots with `DEEP_LINK_BASE_URL` + runs with `PORTAL_DEEP_LINK_BASE`).

---

## 10. Drift caveat (the master is actively authored)

`html/agile-agent-workflow/index.html` is Operator out-of-band and actively edited. Parity is
against the CURRENT snapshot (755 lines, the line ranges in §1.3/§6). A STRUCTURAL change to the
master (new `<style>`/`<script>` blocks, new deep-link categories, a changed selector the e2e
landmarks on) requires a Portal re-sync (re-extract the assets, re-scan the taxonomy). The e2e
checks COMPUTED STYLE + GEOMETRY, not pixels/byte-content, so it TOLERATES minor content edits
(copy, a reworded card) without a re-sync — only a structural shift breaks it. If a re-sync is
needed, it is the same six-file edit (§6) re-run against the new snapshot.

---

## 11. phoenix.operator.md runbook spine (ApolloAAW extends operator.md §5 post-build)

`phoenix.operator.md` already EXISTS; §5 is the live-Portal runbook. Apollo, as docs-keeper, ADDS a
focused L0 sub-runbook **"Add a static parity page through Phoenix"** — the repeatable ordered
workflow this third page demonstrates:

1. **Identify the master + the Fiber route.** `html/<section>/index.html` (the golden master,
   Operator out-of-band) + its `:8765/<route>` baseline. Probe both serve.
2. **Reconcile (probe + read).** Confirm the as-built pattern (the two thin actions, the public
   scope, `deep_link_base/0`, `Plug.Static at:"/"`); probe `:4000` for the route's CURRENT 404 and
   the asset's absence. Read the master's `<head>`/`<style>`/`<script>`/internal hrefs. Classify
   any drift. **A serving fact = a curl, never a config-read.**
3. **Contract.** Pin the route+action (a Director ratification), the full-document template, the
   verbatim asset relocation (exact master line ranges), the keep-vs-remap taxonomy (every href),
   the home-card flip, the two-sided INV9, the e2e extension.
4. **Build (Mars).** action + route → assets (verbatim, clamp clean) → template (inline `<style>`/
   `<script>` → `~p"/assets/…"`; deep links remapped; `<meta>` injection ONLY if the JS builds deep
   links) → home-card flip → e2e.
5. **Gate (Apollo).** clamp-spacing (CSS + computed `<h1>`>70px) · asset-locality (two-sided curl +
   e2e) · parity (computed-style + geometry, two origins) · standing-liveness (probe the running
   node, leave `:4000` UP) · configurable-base (the override re-renders category 4, not assets).
6. **Ratify + commit.** The Director ratifies the new route, then commits the rung bundle (the
   `portal_web` edits + the e2e), EXCLUDING any Operator out-of-band path.

This spine generalizes the workload to "the Nth parity page" — the steps are route-agnostic.

---

## 12. Discipline (inviolable, carried into the build)

- **Edit ONLY the spec/contract.** Mars writes the `.ex`/`.heex`/asset/`.spec.ts`. Venus edits only
  this contract.
- **PROBE, don't config-read.** Every serving fact here is a curl/read (§1.1).
- **Surface forks; don't decide them.** §3 is the Operator's to ratify.
- **Operator out-of-band — NEVER edit or commit:** `html/agile-agent-workflow/*`,
  `docs/agile-agent-workflow/*`, `.claude/skills/agile-course-writer/*`,
  `.claude/commands/agile-write.md`, `docs/elixir/specs/bot/*`, `html/logic/*`, `*.zip`. (READING
  `html/agile-agent-workflow/index.html` as a parity source is allowed.)
- **Framing:** no gendered pronouns for agents; no perceptual/interior-state verbs; no first-person
  narration.
