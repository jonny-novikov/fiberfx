---
name: redis-reframe-echomq
description: "The /redis-patterns course REFRAME: re-prefixed rungs (specs/reframe-echomq/) → BCS contract-sheet identity (redis-red), grounded in the REAL echo/apps code (echo_mq/echo_cache/echo_wire) with the EXCHANGE PLATFORM (echo/apps/exchange) the worked consumer, ZERO BullMQ, Valkey-only, no .out files. B0/R0 fully reconciled (10pp) + the 4 meta-files + the contract reground + a NEW one-shot /redis-reconcile command (B<N>→R<N>); B1/R1 caching (29pp) + B2/R2 coordination (22pp) RECONCILED (all PASS A+); B2 lesson = the v1-vs-v2 trap (echo/apps/echomq FROZEN v1 + a deleted Go port were cited as grounding — real-but-wrong, scrub LockManager|EchoMQ.Keys|Scripts|moveToActive|cluster.go to 0); resume = /redis-reconcile B3 (R3 queues)"
metadata: 
  node_type: memory
  type: project
  originSessionId: e9265937-7278-4619-b5bc-d127815c1163
---

## EVOLVED — B0 reconcile to the Exchange Platform exemplar (2026-06-13) — READ FIRST, supersedes 3 earlier points

The operator evolved the reframe into a stronger **TARGET DESIGN**:
- **Exemplar: Portal → the EXCHANGE PLATFORM.** The worked consumer is the Exchange Platform — REAL partial code at
  `echo/apps/exchange/` (`Exchange.Gateway`/`OrderBook`/`Decider`; design corpus `docs/exchange/`), renamed from the
  "trading platform" (`docs/trading/` → `docs/exchange/`). NOT Portal.
- **BullMQ → ZERO mentions** (SUPERSEDES decision #4's "one lineage note"). `emq` ships a new library with no
  compatibility layer; the v1 history is told without naming BullMQ ("EchoMQ broke from its v1 line, now frozen at
  1.3.0"). I removed BOTH the reserved-tier note AND the immutable-core note.
- **Ground in the REAL as-built code, NOT specs, NEVER `.out` files** (operator: "'out' files not included in
  course… EchoMQ is the REAL ADVANCED PATTERNS APPLIED. KEEP FOCUSED"). The spine: `echo/apps/echo_mq` (EchoMQ —
  Jobs/Lanes/Consumer/Keyspace + Lua), `echo/apps/echo_cache` (EchoCache — Ring/Table/Journal/Coherence),
  `echo/apps/echo_wire` (**EchoWire = the ONE owned Valkey client** over `EchoMQ.Connector` — `@wire_version
  "echomq:2.0.0"`, EVALSHA-first `eval/5`, `fence/2` version fence), `echo/apps/exchange` (the consumer). VERIFIED:
  both EchoCache AND EchoMQ reach Valkey through `EchoMQ.Connector` (coherence.ex/table.ex alias it) → the "one
  facade = EchoWire" framing is honest, not a contrivance.

**B0 (the whole R0 chapter, 10 HTML + 10 md + 3 llms.txt) RECONCILED — all 10 STATUS: PASS, scrubs 0.**
- R0.2 RETITLED **"Valkey under the Exchange Platform"** (slug `redis-under-portal` KEPT — no URL/link breakage).
  facade-seam reground: the `Portal` facade / `%Portal.Error{}` → the echo data layer / EchoWire + the connector's
  real typed returns (`:disconnected`/`:overloaded`/`{:version_fence,_}`); the `Portal.enroll` code → real
  `Exchange.Gateway.parse_place/1` with its six closed errors (`:unknown_instrument|:bad_direction|:bad_order_type|
  :nonpositive_quantity|:bad_price|:malformed`). reserved-tier: "trading platform (docs/trading/)" → "Exchange
  Platform (docs/exchange/)".
- **8.1.8 → 9.1.0 everywhere:** `8.1.8` was a BUG (never in any committed source); `bcsA.md:9` = the live engine
  is **Valkey 9.1.0** on `:6390`; the targeted GA release is `8.1.0`.
- Home evidence block regrounded to the connector code; the gate-dump "PASS 8/8" line dropped from the home (the
  WOVEN "L3 connector gated PASS 8/8" figures in R0.3 STAY — they teach the layer model, not a .out dump).

**Meta-files reground to the target design (Effort 2):** the contract `reframe-echomq.md` (D-RE-3 → zero BullMQ;
NEW **D-RE-5** = Exchange exemplar + ground-in-code-not-.out; the no-BullMQ law → UNCONDITIONAL; figure inventory
+= an as-built-code row + the 8.1.8→9.1.0 fix), `redis-course-writer` SKILL.md + course-map.md, `redis-expert.md`
(the load-bearing whitelist line `Portal.ID`/`%Portal.Error{}` → ground in echo/apps + Exchange; the no-invent
scrub `Portal\.` → `(Exchange|EchoMQ|EchoCache|EchoWire)\.`), `redis-write.md`. All: Portal→Exchange, BullMQ→zero,
+docs/exchange, Valkey-only, no-.out, cross-course gate mounts KEPT.

**NEW `/redis-reconcile` command (Effort 3) — REWRITTEN** from the single-mode structural-refit into the **one-shot
chapter reconcile-to-TARGET-DESIGN** engine (modelled on echomq-reconcile's shape; single comprehensive mode:
identity re-skin if dark-editorial + Portal→Exchange + BullMQ→zero + ground-in-real-code + the 3 binding craft
rules + the gate-invisible conventions; fan-out redis-expert per module → adversarial gate **WITH cross-course
mounts** (the old file was MISSING them) → orchestrator relink → sync views). Args map **B<N>→R<N>**;
`/redis-reconcile B1` = reconcile R1 caching. This is the engine for re2–re5.

**emq.md PATH FIXED:** `docs/echomq/specs/emq/emq.md` (NEVER EXISTED) → **`docs/echo_mq/emq.design.md`** (the real
canon; also `docs/echo_mq/emq.roadmap.md`) across ALL redis files (R0.3 pages+md, the 4 meta-files, the contract,
re0 triad). **11 OTHER-COURSE files still carry the stale path** (echomq-course-writer ×2, echomq-expert.md,
docs/echo/bcs ×3, docs/aaw ×3, docs/echomq/specs/core ×2) — repo-wide pre-existing, OUT of redis scope, FLAGGED.

**re2 = `/redis-reconcile B1` (R1 `caching`) SHIPPED** — 29pp (landing + 7 modules × hub+3 dives), all STATUS: PASS,
full dark→light re-skin + Portal→EchoCache re-ground (grounded in the REAL `echo/apps/echo_cache` Table/Journal/
Coherence/Keyspace + `EchoMQ.Script` + `Exchange.Gateway`, bcs4.1/4.2 figures verbatim). Fan-out = 7 redis-expert
agents (fell back to general-purpose for most — the brief is self-contained; brief written to /tmp once, each agent
told its section). Orchestrator did the landing + spec/TOC/roadmap/llms.txt sync. **Adversarial verify caught what
the agents' "all PASS" missed:** 2 `PASS 6/6` gate-dump lines (removed — bcs figure but the no-.out discipline bans
foregrounding a gate tally), 1 stray dark hex, 10 `course:42` old keys (→ `instruments:AAPL`), 6 module llms.txt +
client-side's fabricated "EchoMQ ScriptLoader" + session's "Portal.Auth.sign_in" (all orchestrator-synced). The
agents self-caught a fabricated Go `loader.go` and a voice slip.

**re3 = `/redis-reconcile B2` (R2 `coordination`) SHIPPED** — 22pp (landing + 5 modules × hub+3 dives + workshop hub),
all STATUS: PASS A+. Full dark→light re-skin + a DEEPER re-ground than B1. **THE B2 LESSON — the v1-vs-v2 trap:** two
`EchoMQ.*` trees exist on disk — `echo/apps/echomq` (NO underscore) = the FROZEN v1 line @1.3.0 (`EchoMQ.Keys`
unbraced `emq:orders:*`, `EchoMQ.LockManager`, `EchoMQ.Scripts`, `EchoMQ.Worker`) and `echo/apps/echo_mq` (WITH
underscore) = the v2 break the course teaches (`EchoMQ.Jobs`/`Keyspace`/`Script`/`Connector`, braced `emq:{q}:`,
inline `Script.new/2`). The old R2 pages cited the v1 tree + a DELETED Go port (`apps/echomq-go`, `cluster.go`,
`CalculateCRC16`, `moveToActive-11`) — all real-but-WRONG, so the no-invent gate alone can't catch them. The verify
MUST grep `LockManager|EchoMQ\.Keys\b|EchoMQ\.Scripts|moveToActive|cluster\.go|echomq-go` → 0. Real v2 grounding (all
verbatim on disk): atomic-updates = inline `@enqueue`/`@claim` via `Script.new/2`, EVALSHA-first `Connector.eval/5`;
distributed-locking = the claim LEASE (`@claim` `ZADD active now+lease_ms`) + `attempts` (HINCRBY) the fence +
`EMQSTALE` + `Consumer`/`Jobs.reap` recovery (NOT LockManager/ExtendLock); redlock = contrast (single-Valkey lease);
cross-shard = multi-key Lua needs one slot + `attempts` the version token; hash-tag = `Keyspace.queue_key`→`emq:{q}:*`,
`slot/1` CRC16 % 16384 client-side (vector `12739`); workshop = `Exchange.Gateway.parse_place/1` → atomic `@enqueue`.
Fan-out = 6 redis-expert (ALL resolved, no fallback this time). **Verify-catches the agents' "all PASS" hid:** the
home-map workshop card still read "Make ENROLLMENT atomic" (Portal-domain residue the `portal` grep misses — it says
"enrollment" not "Portal"); content-map R2 rows + 4 module llms.txt + the chapter spec/TOC/roadmap all still carried
v1 ghosts (orchestrator-synced). False positives correctly KEPT: `redis-under-portal` (the frozen R0.2 slug) ×2 in
the landing Related links; `dmEls.out` (a JS var, not a `.out` citation). Agents self-caught perceptual-verb voice
slips + a malformed span. **Resume = re4 = `/redis-reconcile B3`** (R3 `queues`, still dark-editorial; grounds in
EchoMQ wait/active/`RPOPLPUSH`-equivalent — the v2 `claim`/`complete`/`reap` state machine, `echo/apps/echo_mq`).
The R5–R8 TOC/roadmap grounding cells + the content-map header (line 13) + R3/R6 content-map rows (still Portal/Go-
port/v1) retarget as each chapter reconciles.

---

The **/redis-patterns reframe** (2026-06-12) rebrands the built course (111 pages, R0–R4) from its
**dark-editorial** identity (which is *literally the BCS MUST-NOT list* — dark `--ink:#0a0e1a`, Google-fetched
Cormorant/PT Serif/Manrope/JetBrains) to the **BCS contract-sheet** light-paper identity **with redis-red
`#d6584f` as the signature accent** (a recognizable /bcs sibling, not a clone), re-grounds it to **Valkey +
EchoMQ + EchoCache**, drops all BullMQ framing, and retargets the **"Applied"** in the title to *applied to the
BCS architecture* (EchoMQ backed by Valkey, Valkey under the hood, EchoCache in front).

**Spec system: `docs/redis-patterns/specs/reframe-echomq/`** (a NEW `re`-prefix sub-system beside the chapter
specs — a rung crosses a chapter's PAGES but leaves its module ladder intact). 6 files: `reframe-echomq.md`
(the CONTRACT/rulebook — theme token-swap + dark→light class map, the 3 devices, the figure inventory, the
no-BullMQ+naming law, the gate command), `reframe-echomq.roadmap.md` (the rung sequence + value ladder),
`re0.{md,stories.md,llms.md,prompt.md}` (the exemplar triad+prompt, mirroring the overview/ quad form).

**The 4 locked operator decisions:** (1) theme = contract-sheet + redis-red accent (copy `html/bcs/index.html`
verbatim, `--r-red` takes every B0 `--b-ns` *accent* slot; the 4 segment hues stay for figure semantics; NOTHING
fetched). (2) re0 set = 6 pages: home + overview landing + the **R0.3 `patterns-become-protocol`** module (hub +
3 dives the-four-layers/the-immutable-core/the-door-to-echomq — chosen: heaviest BullMQ debt). (3) devices = a
NEW `.door` (contract-sheet, `--r-red` rail, a source-labelled `figure.frozen` where a committed figure exists) +
keep the existing `.bridge` + a lightweight `.vnote` ("notes on Valkey"). (4) BullMQ = drop all framing, keep **ONE**
neutral lineage note ("forked from the BullMQ v1 line, now frozen at 1.3.0") on `the-immutable-core` only. **[SUPERSEDED 2026-06-13 → ZERO BullMQ mentions; see EVOLVED at top.]**

**Naming law (operator):** always **"EchoMQ"** (never "EchoMQ 2.0" as a label — 2.0 is the implicit default;
`echomq:2.0.0` only as a quoted wire string inside a frozen figure). **NEVER Dragonfly**. 
**Valkey is the only engine.** Ground only in `docs/echo/bcs/content/bcs3.*` + `bcs4.*` + `bcsA.md` + `docs/echomq/specs/emq/emq.md` — figures verbatim.

**re0 SHIPPED — 6 pages all A+ STATUS: PASS, 6↔6 md bijection.** Home `index.html` is the **stylesheet
bootstrap** (defines the contract-sheet+redis-red `<style>`; the other 5 copy head/header/footer/scripts verbatim;
the BCS bootstrap happens once). Verified: figures verbatim (the claim script from bcs3.3, enqueue from bcs3.2,
EMQSTALE/EMQKIND, slots 105/4165/8507 vector 12739, connector 161192/454483/29456 ops/s, EchoCache 762ns/31us,
echomq:2.0.0 — all grep-confirmed in source); no font leak; BullMQ footprint = exactly 1; no Dragonfly; clamp
spaced; voice clean; scripts parse; live crawl 200.

**Gotchas learned:**
- **CLASS-NAME COLLISION `.top` (user-caught, fixed in the re0 models):** the BCS header is `<header class="top">` with a bare `.top{position:sticky;top:0;z-index:20}` rule, but the redis `.mod` cards reuse `<div class="top">` for their num+pill row — so the bare `.top` rule made EVERY `.mod .top` (worst on `.mod.work` workshop cards) its own sticky z-20 element FLOATING over the real header on scroll (cards' R1.xx num+pill appear ABOVE the header band). BCS never hits it (its cards are `.pcard`, no `.top` child). **Fix: scope the header rules to `header.top{…}` / `header.top .wrap{…}`** (not bare `.top`). Gate-INVISIBLE (all 10 gates passed with the bug live — it's a visual stacking bug). Verify via computed-style probe: `.mod .top` must be `position:static`, `header.top` `position:sticky`. Now baked into the 6 re0 models → re1–re5 copying them inherit the fix. (Tooling note: screenshots kept catching mid-scroll because `html{scroll-behavior:smooth}` animates `scrollTo` — add `html{scroll-behavior:auto !important}` or use computed-style probes, not screenshots.)
- **The cms `links` gate has a cross-course ALLOWLIST that knows `/elixir` but NOT `/bcs`/`/echomq`.** The reframe
  adds `/bcs`+`/echomq` doors → the gate MUST add the mounts (as the BCS gate does): `--routes-from /redis-patterns=html/redis-patterns --routes-from /echomq=html/echomq --routes-from /bcs=html/bcs --routes-from /elixir=elixir --chapter-alias r1=caching,…,r8=production-operations --require-refs`. (`--chapter-alias` is `--fix`-only → no new alias needed; the reframe edits existing routes.)
- **The original home VIOLATED the redis relink convention** (`/redis-write` Step 4: unbuilt=`<div class="mod">`, built=`<a class="mod">`) — it wired unbuilt R5–R8 as ANCHORS → dangling. The reframe FIXES this to BCS **full-links-PASS** (unbuilt = non-anchor cards) → true PASS, no fail-by-design manifest.
- The 10 cms gates are **theme-blind** (apollo.go pins only structural literals — `class="pager"`/`class="refs"`/`prefers-reduced-motion`/≥1 svg/no `/future`/forbidden-words; nothing on fonts/colors) → the dark→light swap can't fail a gate; identity is enforced only by the gate-INVISIBLE reads (font-leak grep, clamp, route-tag, stamp decode, scrub greps, figure provenance).
- Stamp namespace stays **`TSK…`** (the redis course's own; the home reuses `TSK0Nb1VTbfnu4`).
- Crash-recovery used AGAIN: the R0.3 agent died on a cert error (UNKNOWN_CERTIFICATE_VERIFICATION_ERROR) at the
  REPORT boundary but had already finished all 4 HTML + 4 md + the scrub — md-first + per-page gating made it
  durable; orchestrator did the full adversarial audit the crashed agent never reported.
- The home uses BCS `.refs{columns:2}` (its bootstrap origin); the landing+dives use the redis 2-div `.refs{display:grid;1fr 1fr}` — both pass `class="refs"`; minor internal divergence, left as-is.
- llms.txt sidecars are orchestrator-only (the fan-out agents don't touch them); refreshed root `llms.txt`
  (thesis + R2–R4 soon→built) + `overview/patterns-become-protocol/llms.txt` (scrubbed "53 BullMQ scripts"). The
  `overview/redis-under-portal/llms.txt` (1 BullMQ) is R0.2 = **re1** scope, left.

**The rung roadmap (decompose by chapter; 6+4+29+22+25+25=111):** re0 ✓ (home+landing+R0.3) · **re1 = R0.2
`redis-under-portal`** (hub+3 dives; the largest open content decision = whether R0.2's Portal-seam is *retold*
or *re-scoped*) · re2=R1 caching (EchoCache re-grounding, bcs4) · re3=R2 coordination · re4=R3 queues · re5=R4
time-delay-priority · then R5–R8 born reframed. Cross-rung invariant: from re1 every reframed page copies a PRIOR
reframed redis page of its surface (the re0 six are the models).

**Figure hover-select pattern (user-mandated, applied to all R0.3 figures):** every interactive figure follows
`/bcs/ideas/system-substrate` — a `.segbar` of buttons + an SVG whose `g[data-x]` groups highlight on **hover AND
click** (CSS `.fig.focus g{opacity:.3}` / `.on{opacity:1}` / `.on rect{stroke-width:2.6}`) through ONE pure
`select(key)` that toggles `.focus`/`.on`, syncs `aria-pressed`, fills a live `.readout`, wired to button `click`
+ group `mouseenter`/`mouseleave`. **Overlap bug + fix (user-caught):** long descriptions as centered SVG
`<text text-anchor="middle">` inside boxes COLLIDE with the box's left label when the SVG scales up
("theL3connector", "Va[L0]key") → fix = SHORT left-anchored label in the diagram, full detail moved to the
**readout** dataset; `text-anchor="middle"` count should be ~0 on a fixed figure. Exemplar:
`the-four-layers.html` `.lstack` (I built it; 3 fan-out agents applied it to the hub/immutable-core/door — all
A+, verified focus:true/onCount:1 via computed-style probe + screenshot). Keep ≥1 `<svg>` per page (svg gate).

**RM4 DONE (meta-files repointed to the reframe):** `.claude/skills/redis-course-writer/SKILL.md` +
`references/course-map.md` + `.claude/agents/redis-expert.md` + `.claude/commands/redis-write.md` all updated —
contract-sheet identity (model = reframed `html/redis-patterns/index.html`, R1–R4 "mid-migration until re2–re5"),
Valkey/EchoMQ/BCS grounding + the no-BullMQ/Dragonfly + "EchoMQ"-not-"2.0" naming law, the gate's cross-course
mounts, full-links-PASS non-anchor manifests, `header.top` scoping, the hover-select figure rule. The
redis-course-writer SKILL frontmatter now reads "BCS contract-sheet identity". **Open seam (flagged):**
`redis-patterns.roadmap.md` + the TOC + the chapter specs (R5–R8 grounding cells) still carry pre-reframe
v1-era grounding language — the meta-files defer to "the figure inventory licenses what may be quoted"; a
roadmap-level re-grounding pass for R5–R8 is owed (do at re2–re5 / operator).

**re1 SHIPPED (2026-06-13) — R0 complete in the contract-sheet identity.** R0.2 `redis-under-portal` (hub +
the-facade-seam/two-roles/reserved-tier + 4 md mirrors) reframed AND **retargeted to the EchoMQ program roadmap
`docs/echo_mq/emq.roadmap.md`** (the user's added axis): EchoMQ = `echo/apps/echo_mq`, the 2.0 Valkey-native
**convergence target** (born braced/branded/declared); the v1 line frozen `1.3.0` = the **push source** (the ONE
lineage note moved to `reserved-tier`, not the-immutable-core — one per page-SET, per module); the trading
platform = the named consumer; fleet living-status (Go sibling named, echomq-node strictly PROPOSED).
`reserved-tier` was the heaviest retarget: the stale "Portal reserves F7–F9 / EchoMQ-on-BullMQ /
RPOPLPUSH+moveToActive+wait/active lists" frame DELETED, replaced by the real bcs3.3 claim script (ZPOPMIN →
HINCRBY attempts-as-token → server-clock TIME lease) verbatim. All 4 pages A+ 10/10 gates, scrubs clean,
provenance grep-verified, live crawl 200. llms.txt sidecars (R0.2 + overview) rewritten to the retold narrative;
TOC legend de-staled (R0–R4 built) + re1 recorded. **PATH MOVE (cite this from now on):**
`docs/echomq/specs/emq/emq.md` NO LONGER EXISTS — the protocol canon is `docs/echo_mq/emq.design.md` + the
program `docs/echo_mq/emq.roadmap.md`; the reframe contract's figure inventory + the shipped R0.3 heronotes
still cite the old path (R0.3 sidecar fixed; the R0.3 PAGES still carry it — fix at a later touch).
Session-limit resume pattern worked: the agent died mid-batch (3/4 pages done), `SendMessage` to its agent-id
resumed it with full context; orchestrator verified the finished slices read-only meanwhile.

**re2 (`/redis-reconcile B1`, R1 `caching`, 29pp) SHIPPED — resume = re3 via `/redis-reconcile B2`** (R2
`coordination`, still dark-editorial; see EVOLVED at top for the B1 verify-catches and the fan-out pattern). Related:
[[redis-patterns-course]], [[bcs-course]],
[[echo-mq-three-movements]] (the program the retarget speaks).

## Archived index line (2026-06-12, index compaction)

/redis-patterns REFRAME: re-prefix rung seq (specs/reframe-echomq/) → BCS contract-sheet identity (redis-red accent) + Valkey/EchoMQ/EchoCache grounding, BullMQ dropped (1 lineage note), "Applied"→BCS arch; re0 SHIPPED (home+overview+R0.3, 6pp A+); gate adds /bcs+/echomq mounts; full-links-PASS (unbuilt=non-anchor); NO Dragonfly (emq.md bans it); resume = re1 (R0.2)
