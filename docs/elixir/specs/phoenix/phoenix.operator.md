# F6 · Operator's guide — supervising Claude's Agile Portal development

> A field manual for the **Human L0 Operator**: the person in the conversation who owns intent and priorities,
> reviews each spec and each shipped increment, and gives the go/no-go. Claude runs the rest — Author, Director, and
> the specialized lead-team — turning each rung into specs, building it, verifying it, and shipping it over the
> unchanged `Portal` facade. The workload is one pipeline, **roadmap → specs → user-stories → llms → teams → agents →
> ship**, and it holds two standing promises every rung: the [master invariant](phoenix.md) (the web calls only the
> facade) and the [liveness criterion](phoenix.md) (every rung leaves the Portal **live and hot in dev**).

This guide is the *process* view. The *what-to-build* lives in the spec triads (`f6.N.{md,stories.md,llms.md}`); the
*delivery plan* lives in [`phoenix.roadmap.md`](phoenix.roadmap.md); the *map* lives in [`phoenix.md`](phoenix.md);
the *build conventions and footguns* live in [`echo/CLAUDE.md`](../../../../echo/CLAUDE.md). When this guide and a spec
disagree about what to build, the spec wins.

---

## 1. Two roles, and what each decides

The loop has exactly two parties, mirroring the F5 roadmap's Author/Operator pattern.

- **L0 — the Operator (the human).** Owns the *why* and the *what-next*: priorities, milestone order, the acceptance
  of a shipped rung, and every architecture / API-contract / new-dependency decision. Reviews the spec **body** (it is
  authoritative) and the shipped increment, then returns feedback. Feedback edits the spec, because the spec is the
  single source of truth and the build follows it.
- **L1+L2 — Claude (the Author + Director + lead-team).** Turns a rung into a spec triad at the F5 quality bar, then
  runs the build as a Director coordinating three specialized peers (Venus, Mars, Apollo). Claude decides
  implementation details with one obvious answer and proceeds; Claude **stops and asks** the Operator on anything that
  changes a contract.

The decision split is the load-bearing rule:

| Decision | Owner | Mechanism |
| --- | --- | --- |
| Architecture change · API contract · new dependency | **Operator** | Claude STOPs and ASKs before proceeding |
| Priorities, milestone order, "ship or iterate" | **Operator** | review + feedback at the rung's close |
| Which of two reasonable implementations | Claude (Director/Mars) | logged as a decision, surfaced for veto |
| An implementation detail with one answer | Claude (Mars) | proceeds; cited to the spec line |

The per-rung loop the Operator drives is **sharpen → build → ship → demo → review → feedback → adapt**.

---

## 2. The workload, end to end

Seven artifacts, each feeding the next. The Operator reads the left two columns; Claude owns the authoring; the right
column is what the Operator reviews at that stage.

| # | Stage | Artifact & home | Authored by | What the Operator reviews |
| --- | --- | --- | --- | --- |
| 1 | **Roadmap** | [`phoenix.roadmap.md`](phoenix.roadmap.md) — milestones, build order, the per-rung iteration table, the status board | Author | priorities and milestone order; is the next rung the right next slice? |
| 2 | **Spec body** | `f6.N.md` — Goal · Rationale (5W) · Scope · Deliverables · Invariants · Definition of Done · the `[RECONCILE]` callout | Author (Venus refreshes) | the body is authoritative — read it first; is the goal and scope right? |
| 3 | **User stories** | `f6.N.stories.md` — Connextra (`As a … I want … so that …`) + **Given/When/Then** acceptance + INVEST/coverage traceability | Author (Venus) | the acceptance criteria — is "done" defined the way the role needs it? |
| 4 | **Agent brief (llms)** | `f6.N.llms.md` — references · requirements · execution topology (a task DAG) · the paste-ready prompt Mars builds from | Author (Venus) | usually skim-only; it lags the body by ≤1 rung and is reconciled before build |
| 5 | **Teams** | `TeamCreate` + the flat lead-team (Director + Venus/Mars/Apollo), **real** `Agent` spawns (LAW-1), coordinated by `SendMessage` | Director | nothing to review — this is mechanism; visible in the conversation as spawns |
| 6 | **Agents** | the specialized roles in `.claude/agents/{venus,mars,apollo}.md` — the discipline lives *in the definitions*, so spawn prompts carry only the rung delta | Director | nothing to review per rung; the agent defs are the durable process asset |
| 7 | **Ship** | the gate (compile `--warnings-as-errors` + tests + the determinism loop) + the **liveness check** + one LAW-4 Director commit | Director ratifies | the demo + Apollo's verdict; accept, or return feedback that edits the spec |

The compounding idea: **author the cheap artifacts (stories, brief) before the expensive one (code), and let the
stories be the acceptance.** A rung is done when every story's Given/When/Then is a passing test and the gate is green
across the determinism loop — nothing softer.

---

## 3. The per-rung pipeline — the six stages the Director runs

Each rung gets a Director brief, `f6.N.prompt.md`, that names the stages and carries only what is *new about this
rung* (the discipline is in the agent definitions). [`f6.6.prompt.md`](f6.6.prompt.md) is the worked template. The
stages, and the Operator's touch-point at each:

1. **Venus · reconcile + brief.** Runs `/reconcile f6.N` *pre-build* (the lag-1 reconcile: does the spec's claimed
   surface exist in the code it depends on?), corrects any drift in the body, pins the one or two contracts the rung
   adds, and refreshes the brief. Reports a delta table + a BUILD-GRADE/BLOCKED verdict. *Operator: ratifies any new
   public contract Venus pins (surfaced for veto).*
2. **Mars-1 · build.** Builds the increment to the brief, citing the spec line for every public call, inventing
   nothing, keeping the diff inside the facade. Compiles clean. *Operator: none.*
3. **Mars-2 · harden.** Adds the `LiveViewTest` / `ConnTest` coverage for every Given/When/Then, audits idiom, runs
   the determinism loop. *Operator: none.*
4. **Apollo · verify.** Runs `/reconcile f6.N post` (does the as-built code satisfy the spec's promises?), re-runs the
   gate independently, adversarially greps the master invariant, rules on any open realization, syncs the spec body to
   what shipped, and renders **BUILD-GRADE** or **BLOCKED (n deltas)**. *Operator: reads the verdict.*
5. **Director · ratify + commit (LAW-4).** On BUILD-GRADE, one scoped commit (explicit pathspec, never `git add -A`,
   excluding the operator's out-of-band work). *Operator: the demo + the accept/iterate call.*
6. **Director · feedback loop.** Folds the rung's findings forward into the downstream specs as `[RECONCILE]` markers —
   making knowns explicit so the next rung reconciles against truth, not drift. *Operator: none; visible in the
   downstream spec diffs.*

If Apollo returns **BLOCKED**, the needed code change routes back through the Director to a fresh Mars spawn — Apollo
never edits production code, never commits. That separation is what keeps the verifier adversarial.

---

## 4. The standing gates — what "shipped" means

Two invariants hold at *every* rung, plus the build gate and the acceptance rule:

- **Master invariant.** The web layer calls only the `Portal` facade and renders only the closed `%Portal.Error{}`
  set — no controller, LiveView, plug, or template names `Portal.Engine`, a repo, or `GenServer.call`. Apollo proves
  it by grep on the new web module; a boundary leak is a defect even when every test is green.
- **Liveness criterion.** Every rung leaves the Portal **running and serving** in dev: the umbrella boots clean, the
  endpoint binds `:4000`, `GET /health` answers `200`, and the rung's own route renders. The runbook is §5.
- **The build gate** (Mars runs it; Apollo reproduces it; the Operator can too):
  `TMPDIR=/tmp mix compile --warnings-as-errors` clean → `TMPDIR=/tmp mix test` green → for any id- or
  process-touching rung, the **≥100-iteration determinism loop** (a single green run is not proof — the
  same-millisecond branded-id collision flakes only across runs; see [`echo/CLAUDE.md`](../../../../echo/CLAUDE.md) §4).
- **The visual-proxy gate** (for a styling / presentation rung — F6.5.5 was the first). When acceptance is
  *visual* (the page renders in the design system), the proof is TEXT PROXIES + a computed-style parity gate,
  never screenshots: a **clamp-spacing parse** over every touched CSS file (an unspaced `[+-]` inside `clamp()`
  is invalid CSS that silently drops to the UA default — the highest-leverage check, gate-invisible to `mix
  test`); a **token-fidelity diff** (the design `:root` byte-for-byte against its master); and a **two-origin
  Playwright parity gate** (`apps/e2e`, computed style + geometry — NOT pixels — against the static baseline).
  Such a rung **drops the ≥100 determinism loop** when it touches no id-mint or process state (F6.5.5-INV8) —
  the liveness criterion is the styled-envelope curls + the parity gate, not a repeated-suite loop.
- **The config-injection probe** (when a rung makes a value CONFIGURABLE — F6.5.5's polish made the deep-link
  base so). "Configurable" is proven by an actual SWAP, never by inspecting the default alone: boot the node a
  second time with the override env set (`DEEP_LINK_BASE_URL=https://example.test mix phx.server`) and assert
  the **rendered output** carries the override — on EVERY surface the value reaches (here both the
  server-rendered HEEx markup AND the static JS's injected `<meta>`/`window` value), AND that the OLD default
  literal no longer survives in the rendered page (proving the host comes from config, not a baked literal).
  Pair it with the **invariant the configurability must NOT break**: F6.5.5's base touches CATEGORY-4 nav
  links ONLY — never the Portal's own `~p"/assets/…"` static assets (a page pulling its CSS/JS from the base
  visually matches yet is a hollow shell + a liveness regression), so the asset-locality probe (`curl
  :4000/assets/<f>` → 200 local, no redirect; zero `<base>/assets` in the rendered page) runs under the swap too.
- **Acceptance.** A rung is done iff every story's Given/When/Then is a passing test and the gate is green across the
  loop — and the `/reconcile` gate is build-grade (every spec claim is `MATCH` or an explicit `[RECONCILE]`-DEFERRED).

The `[RECONCILE]` discipline is how a spec written *rungs ahead of its build* stays honest: each downstream body opens
with a callout making its known-deferred dependencies explicit, with a `*(Why: …)*` clause. The reconcile gate
*allows* a `[RECONCILE]`-marked claim while *blocking* an unmarked stale or invented one.

---

## 5. The runbook — keep the Portal live & hot, and check after each rung

All commands run from the umbrella root `/Users/jonny/dev/jonnify/echo`.

**"Hot" here is BEAM hot-code-load, not Phoenix live-reload.** This umbrella is hand-built without `mix phx.gen.*`, so
it carries no `phoenix_live_reload` dependency and no `CodeReloader`/`LiveReloader` plug. The dev loop that keeps the
Portal hot is a long-lived `iex -S mix`: after each edit, `recompile()` in that same shell loads the changed modules
into the running node — the warm node keeps its bound `:4000` socket and its in-memory engine/event-store state across
rungs, so a catalog built up interactively survives the next rung's code change.

```bash
# ── Preconditions (once per machine) ─────────────────────────────────────
cd /Users/jonny/dev/jonnify/echo
mix deps.get
mix ecto.create        # creates `portal_dev` — Portal.Repo (F6.3) is a supervision child,
                       # so the DB MUST exist or the node will not boot (config/dev.exs:
                       # localhost:5432, user `jonny`, no password)

# ── Boot live, kept hot (the session you leave running) ──────────────────
iex -S mix             # binds http://localhost:4000 — server: true in runtime.exs (every env but :test)
# …after editing code for the next rung, in the SAME iex shell:
#   iex> recompile()   # BEAM hot-code-load: new modules into the warm node; :4000 + state survive

# Foreground alternative without the shell (no recompile() hot loop — restart to pick up edits):
mix phx.server

# ── The per-rung liveness check (run AFTER the gate is green) ─────────────
curl -fsS localhost:4000/health        # operator probe → 200 (no session or CSRF)
curl -fsS localhost:4000/courses | head  # the rung's own route renders (F6.6: the live catalog)
#   `curl -fsS` exits non-zero on any non-2xx, so its exit code IS the gate — wire it into a script if you like:
#   curl -fsS localhost:4000/health >/dev/null && echo "PORTAL LIVE" || echo "PORTAL DOWN"

# ── The build gate (reproduce what Mars/Apollo run) ──────────────────────
TMPDIR=/tmp mix compile --warnings-as-errors
TMPDIR=/tmp mix test
for i in $(seq 1 100); do TMPDIR=/tmp mix test || break; done   # determinism loop (id/process-touching rungs)
```

The minimal "is the Portal still live?" check after any rung is two lines: boot (or `recompile()` the warm node), then
`curl -fsS localhost:4000/health` → `200`. If that fails, the rung is not shippable, regardless of a green suite.

---

## 5.1 Workload — add a static parity page through Phoenix (the Nth parity page)

A recurring **workload**, not a chapter rung: take a static golden-master page the Fiber server already serves under
`html/<section>/index.html`, and make Phoenix serve a byte-faithful, design-system-identical copy at the same clean URL —
flipping the home card from a production REMAP to a LOCAL route as a strangler-fig step. Three pages have run this spine
(`/` ↔ `html/courses.html`, `/elixir` ↔ `elixir/index.html`, `/course/agile-agent-workflow` ↔
`html/agile-agent-workflow/index.html`); the steps are route-agnostic, so this is the repeatable L0 runbook. It runs the
same Venus→Mars→Apollo loop (§3); the contract is a concise parity brief (the worked example is
[`aaw-parity.md`](aaw-parity.md), §11 spine).

**The L0 split — what the human decides vs what each agent does:**

| Stage | Owner | What happens |
| --- | --- | --- |
| 0 · pick the page | **Operator** | Name the golden master (`html/<section>/index.html`, Operator out-of-band) + its `:8765/<route>` Fiber baseline. The new public route is an **Operator ratification** (a new HTTP surface — §1's decision split). |
| 1 · reconcile (PROBE, not config-read) | Venus | Confirm the as-built pattern (the thin action, the public `scope "/"`, `deep_link_base/0`, `Plug.Static at:"/"`). **Probe `:4000`** for the route's current `404` and the asset's absence — a serving fact is a `curl`, never a re-read of `endpoint.ex` (the F6.5.5 `at:"/assets"` mount read-as-correct yet 404'd; the cure was a curl). READ the master's `<head>`/`<style>`/`<script>`/internal hrefs. Read **both** `<script>` blocks to decide whether a `<meta name="deep-link-base">` injection is needed: add it ONLY if the page's JS builds deep links (elixir does; agile does NOT). |
| 2 · parity contract | Venus | Pin: the route+action (the ratification), the full-document template, the **verbatim** asset relocation (exact master line ranges), the keep-vs-remap taxonomy for **every** internal href, the home-card flip, the two-sided INV9, the e2e extension. |
| 3 · build | Mars | action + route → assets (verbatim, clamp-clean) → full-document template (inline `<style>`/`<script>` → `~p"/assets/…"`; deep links remapped inline; `<meta>` ONLY if step 1 said so) → home-card flip (`deep_link_base() <> …` → relative) → e2e (a third `describe` + the navigation test). |
| 4 · gate | Apollo | **clamp-spacing** (`grep -nE 'clamp\([^)]*[+-][^ 0-9.]' <asset>.css` → 0, siblings byte-unchanged; computed `<h1>` > 70px) · **asset-locality, two-sided** (`curl :4000/assets/<f>.css` → 200 local, no redirect; rendered refs `~p"/assets/…"`, zero carrying the base) · **two-origin parity** (computed style + geometry, the `apps/e2e` suite on the default AND override base) · **standing-liveness** (below) · **config-swap** (the override re-renders category-4 only). Re-run the master line-range `diff` to prove the relocation is byte-identical. |
| 5 · ratify + commit | **Operator** + Director | The Operator accepts the demo; the Director makes one scoped commit (explicit pathspec, **excluding** the Operator out-of-band parity source `html/<section>/*`). |

**Standing-liveness for a parity page — the load-bearing nuance (G3).** The proof the route serves is a probe of the
**already-running, durable `:4000`** the Director holds in the main session — `curl -fsS :4000/health` → 200 AND `curl
-fsS :4000/<route>` → 200, the node still answering afterward. An **agent CANNOT leave a node durably running**: a node
an agent boots (for a config-swap check, say) is reaped at that agent's turn-end, so it is never a standing artifact.
The agent's reliable path is therefore the **handoff** — hand the Director the boot/`recompile()` command and probe the
Director's `:4000`; the "leave a node running" branch belongs to the Director's session or the deploy, not the agent.
Run any ephemeral-node check (the config-swap) WITHIN the turn so the check RAN, then tear that node down — never
present it as live to the Operator. (The Nth parity page confirmed this in the field: an agent reported its own
`:4010`/`:4011` "left up," and both were dead to the next probe.)

**The parity-specific gate vocabulary** (beyond §4's standing gates): the master line-range **byte-diff** (the relocation
is verbatim or it is not), the **href taxonomy counts** (exact in both template source and rendered DOM), and the
**`<meta>`-injection decision** (a per-page READ of the JS, not a cargo-cult of the prior page's `<meta>` tag).

---

## 6. How to read a verdict

What the Operator sees at a rung's close, and what each part means:

- **Apollo's BUILD-GRADE / BLOCKED verdict + delta table** — each spec promise mapped to an as-built `file:line` and a
  verdict (`MATCH` / `STALE` / `INVENTED` / `MISSING` / `DEFERRED`). BUILD-GRADE iff all are `MATCH` or
  `[RECONCILE]`-DEFERRED. A BLOCKED verdict names the blocking deltas; the Director routes the fix to Mars and
  re-verifies — it does not ship.
- **The gate result Apollo reproduced** — compile clean, the test pass-count, and the determinism-loop result
  (e.g. `100/100`). Apollo re-runs the gate; the build's own report is evidence, not proof.
- **The `[RECONCILE]` markers planted forward** — the findings this rung folds into the downstream specs, each with a
  why. These are the Operator's preview of what the next rungs must reconcile.
- **When the Operator is asked** — Claude STOPs and ASKs only for an architecture / API-contract / new-dependency
  decision. A pinned read-only contract that the reconcile already ratified in principle is surfaced for veto, not
  asked as a blocking fork.

---

## 7. The LAWS, for the Operator

Five rules govern how Claude runs the rung; they explain behaviours the Operator will observe:

- **LAW-1 — real multi-agent spawns.** Each named peer (Venus/Mars/Apollo) is a *real* spawned subagent with its own
  context, not role-play. The Operator sees genuine `Agent` spawns and `SendMessage` reports.
- **LAW-1a — the Director does not edit code.** Once the team is spawned, the Director coordinates and ratifies but
  must not `Edit`/`Write` implementation files — peers write the code. This is why the Director reads and reviews by
  eye but hands every code change to Mars.
- **LAW-2 — Opus.** All peers run on Opus.
- **LAW-3 — framing.** Emitted prose (prompts, comments, specs) carries no gendered pronouns for agents, no
  perceptual or interior-state verbs, no first-person narration — and propagates that rule downstream.
- **LAW-4 — one scoped commit at the rung's close.** Exactly one Director commit per rung, with a contextualized
  message, using an **explicit pathspec** — never `git add -A`. The commit **excludes the Operator's out-of-band
  work**: `.claude/skills/agile-course-writer/*`, `html/agile-agent-workflow/*`, `html/logic/*`,
  `docs/agile-agent-workflow/*`, `*.zip`. The Operator commits course/operator work separately; the rung commit
  fences it off.

---

## 8. Map

- Chapter index & the two standing invariants: [`phoenix.md`](phoenix.md)
- Delivery plan, milestones, status board: [`phoenix.roadmap.md`](phoenix.roadmap.md)
- A worked Director brief (the six-stage template): [`f6.6.prompt.md`](f6.6.prompt.md)
- The rung triads: `f6.N.md` (body) · `f6.N.stories.md` (stories) · `f6.N.llms.md` (brief)
- The specs approach & completion rule: [`../specs.approach.md`](../specs.approach.md)
- Build conventions, the master invariant in code, the determinism footgun: [`echo/CLAUDE.md`](../../../../echo/CLAUDE.md)
- The specialized agent definitions: `.claude/agents/{venus,mars,apollo}.md`

---

> Part of the jonnify toolkit. The Portal is served live in dev on `:4000`; every rung leaves it that way.
