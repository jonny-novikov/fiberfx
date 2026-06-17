---
name: fsharp-course
description: "/fsharp \"F# In Depth\" — C0+C1+C2+C4 COMPLETE; C3 for-elixir 3/9; C4 Algorithms 12/12 (every dive an EchoMQ-in-F# block grounded in the NEW echo_fs port); C0–C5 (50 mods); dark-editorial+violet; /fsharp-write + fsharp-expert; resume = C3.04–09 then C5 DevOps (ibbs)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 74619602-0eb8-44e7-9b03-800faa5f2e61
---

The **/fsharp "F# In Depth"** course (course letter **C**) — bootstrapped 2026-06-14. A folder-routed
**English** course under `html/fsharp/` (NOT `html/ru/`), wired like the other English courses:
`main.go` (`fsharpDir` + `FSHARP_DIR` env + `/fsharp` + `/fsharp/*` via `serveDirTree`), `Dockerfile`
(`COPY html/fsharp/`), `Makefile` (`FSHARP_DIR` + start/run exports + help), `cmd/sitemap/main.go`
(`{"fsharp", htmlRoot, "/fsharp"}` in the `folderRouted` slice), and the `html/llms.txt` F# section.

**Identity:** dark-editorial — the Elixir course's tokens + an F# **violet** accent
(`--fsharp:#b48ee0; --fsharp-bright:#d2b8f5`); model page `html/fsharp/index.html`. NOT the
redis/BCS contract-sheet. Google-Fonts loaded (matches Elixir, not the redis "nothing fetched" rule).

**Curriculum (C0–C5, 50 modules):** C0 History (2 mods, 3 dives each), C1 F# Language (9×3),
C2 F# for C# developers (9×3), **C3 F# for Elixir developers (9×3** — the Elixir-community parallel to C2;
valid F# beside real Elixir; cross-links `/elixir`**)**, **C4 Algorithms & Data Structures (12×3** —
re-derives the Elixir **E4** chapter `/elixir/algorithms` in F#, each dive carrying an _EchoMQ in F#_ block;
F#'s actor = `MailboxProcessor`**)**, C5 Pragmatic Programming — DevOps Tools (9, single-page; the ibbs
practical project + workshop). Slugs: `history · language · for-csharp · for-elixir · algorithms · devops`.
**C4 carries 3 dives per module (the EchoMQ-block directive); C5 stays single pages.**

**Grounding (no-invent):** C0 = documented history; C1/C2 = valid idiomatic F# (+ real C#); C3 = valid F#
beside real Elixir; **C4 = parity with `/elixir/algorithms` (E4) + an _EchoMQ in F#_ block per dive grounded
in the NEW `echo_fs` port** (see below); **C5 = the REAL ibbs codebase at `/Users/jonny/dev/ibbs`**
(F#/.NET `DevOps.sln`: `DevOps.Tools`→analysis.dll · `DevOps.Sfera`→sfera.dll · `DevOps.Server` ·
Fable `web/client-fs` · xUnit 104 tests) — quote verbatim, verify on disk, invent nothing.

**Authoring infra (the /redis-write pattern):** spec system `docs/fsharp/`
(fsharp.toc/roadmap/progress/README + specs/fsharp.md); skill `fsharp-course-writer`; command
`/fsharp-write <chapter> <module>…`; agent `fsharp-expert`. Ten jonnify-cms gates via
`apps/jonnify-cms/bin/cms check --routes-from /fsharp=html/fsharp --require-refs <page>`.

**Status:** home built + **C0 · History COMPLETE 2026-06-14** (2 mods/6 dives, 8pp A+) + **C1 · F#
Language COMPLETE 2026-06-14** (9 mods/27 dives, all A+). C1.01–03 (values/bindings/functions) shipped
first; **C1.04–09 shipped via the senior-writer prompt-pack fan-out** (below): C1.04 `pipe-and-compose`
[`the-pipe`/`composition`/`building-pipelines`] + C1.05 `pattern-matching`
[`match-expressions`/`guards-and-destructuring`/`active-patterns`] + C1.06 `unions-and-records`
[`records`/`discriminated-unions`/`illegal-states`] + C1.07 `collections`
[`list-array-seq`/`transforming`/`map-and-set`] + C1.08 `option-result` [`option`/`result`/`railway`]
+ C1.09 `computation-expressions` lab [`builders`/`async`/`build-your-own`]. All 9 C1 cards relinked
`soon`→`built` on the home + landing; C1 arc front door reads `built`. **The route-mirrored markdown
source-of-record under `docs/fsharp/markdown/<route>.md` is backfilled for all 47 published C0+C1 pages**
(exact HTML↔markdown bijection — home + 2 chapter landings + 11 hubs + 33 dives; a faithful DIGEST, not a
verbatim dump: code blocks + `// val it :` echoes copied verbatim, but secondary inline comments / trailing
examples trimmed, per the pre-existing C1.05 exemplar set; authored via the backfill prompt-pack
`docs/fsharp/specs/markdown-backfill.prompt.md` + 10 fsharp-expert agents, 3 manifest pages by the
orchestrator). **Author each NEW module's markdown alongside its HTML for C2–C4** (the skill's step-2
option) so the set never falls behind again.

**C2 · F# for C# developers COMPLETE 2026-06-14 (9/9, 37 pages).** Shipped in two `/fsharp-write
for-csharp` batches: C2.01 modules-vs-classes + C2.02 immutability + C2.03 option-and-result (opening),
then C2.04 unions-vs-inheritance + C2.05 recursion-and-fold + C2.06 function-types + C2.07 seq-vs-linq +
C2.08 interop + C2.09 mixed-solution lab (close). C2 grounds in valid **C# beside F#** (the `.lbl`
side-by-side device from `fsharp-is-born.html`); the markdown source-of-record was authored ALONGSIDE the
HTML (**84/84 full-course bijection** — the standing rule held). Packs: `c2.shared.prompt.md` +
`c201`–`c203` (opening); `c2b.shared.prompt.md` + `c204`–`c209` (close) — each carrying the pre-verified
C#/F# echo table (F# via `dotnet fsi 9.0.303`, C# via `dotnet script`; the C2.09 agent compiled a full
`[<EntryPoint>] main` with `dotnet build`, 0 warnings). **Captured C2 nuances (reuse for C3+):** the
.NET 9 `System.Int32.TryParse` **FS0041** overload trap on an INFERRED parameter — annotate `(s: string)`
(a literal arg works); the **FS0025** exhaustiveness warning on a DU `match` (the closed-world guarantee
inheritance can't give — C2.04); a top-level `let x` redefinition is **FS0037**, NOT shadowing (needs a
nested scope — function body / FSI cell). **The cms `links` gate needs the `/redis-patterns` mount** for
any F# page (the canonical footer links it); module pages gate with `/fsharp`+`/elixir`+`/redis-patterns`,
the home with all five (it footer-links `/bcs`+`/echomq` too). **Resume = C3.04–C3.09** (the remaining
for-elixir modules) **then C5 · DevOps Tools** (`/fsharp/devops`, the ibbs capstone; order in
fsharp.roadmap.md). C4 Algorithms is DONE — see below.

**C3 · F# for Elixir developers — OPENED 3/9 (2026-06-15).** Landing (the Elixir↔F# Rosetta interactive) +
C3.01 two-runtimes / C3.02 static-types / C3.03 pattern-matching (hub + 3 dives each, A+). Remaining:
C3.04 the-pipe · C3.05 data-modeling · C3.06 errors · C3.07 concurrency · C3.08 polymorphism · C3.09
tooling (lab). Valid F# beside real Elixir; cross-link the matching `/elixir` module.

**C4 · Algorithms & Data Structures — COMPLETE 12/12 (2026-06-15, 48 pages, all A+).** Built in 4 fan-out
waves of 3 modules: lists · trees · sorting · maps · hamt · champ · identifiers · persistence ·
branded-champ · recipes · dynamic-programming · lab. Each re-derives its Elixir **E4** sibling in F#
(cross-linked + efficiency notes) and **every dive carries an _EchoMQ in F#_ block** grounded in a real
`echo_fs/EchoMQ/` surface (living-status voice; the Valkey `Connector` "coming soon"). **Two honesty
guardrails** enforced via per-agent briefs + an adversarial grep: no page claims F#'s `Map`/`echo_fs` IS a
HAMT/CHAMP (taught as the technique/production form; `Store.Rows` is a `Map` stand-in). Landing = the
mint-ordered-claim interactive (authored by the orchestrator first). The C4 structural reconcile
(single-page → 3 dives) updated TOC + contract + roadmap FIRST. The C4→echo_fs surface map lives in
`fsharp.roadmap.md`. cms gate adds the `/echomq` mount (the landing + dives link it).

**echo_fs — the F# EchoMQ port (NEW 2026-06-15, the C4 grounding).** `echo_fs/echo.sln` at the **repo
root** (sibling of `echo/`), an F# port skeleton of `echo/apps/echo_mq`: `EchoMQ` (library, 11 .fs) +
`EchoMQ.Tests` (xUnit — **`dotnet test` 30/30 green**, net9.0, dotnet 9.0.303). Modules:
`Base62`/`Snowflake`/`BrandedId` (the branded `JOB` id), `Keyspace` (`emq:{q}:<type>` + CRC16 slot, vector
`slot "123456789"=12739`), `Backoff` (pure `base·2^(n-1)` clamped), `Job`/`Store` (in-memory four-set
lifecycle, mint-ordered pending `Set`), `Lanes` (ring rotate), `Jobs` (verbs), `Broker` (the single-writer
`MailboxProcessor` — the C4.09 centerpiece, with a 200-parallel-post test), `Admin`. The in-memory core is
REAL + tested; the Valkey transport `EchoMQ.Connector` is the deliberate "coming soon" seam (the legit
forward-looking part of the EchoMQ blocks). `bin/`+`obj/` gitignored. F# compiles top-down so `<Compile>`
order is dependency order. (Trap: `Assert.Equal` overload ambiguity on an `int list` arg — annotate or use
`List.isEmpty`; and `PostAndReply` inside an `async` on the thread-pool STARVES it — use `PostAndAsyncReply`.)

**echo_fs EXPANDED to a 3-package solution 2026-06-15** via `/echo-mq-ship` (an "uncommon invocation" — an
F# redirect of the Elixir echo_mq ship skill; a **reverse spec-write**): + **EchoConnector** (= `echo_wire`:
`Resp` RESP3 codec + `Script` SHA1 + `IConnector` abstraction + a hermetic `MemoryConnector` + `Wire`
facade; **dependency-free**, carries the `WireVersion="echomq:2.0.0"` fence) + **EchoCache** (= `echo_cache`:
`ecc:{table}:id` keyspace, order-theorem `Coherence`, in-memory L1 `Table` w/ versioned newer-wins, the
declared-cache directory, Ring/Journal/Shadow skeletons; deps EchoConnector+EchoMQ). **62 tests green**
(EchoMQ 30 · EchoConnector 18 · EchoCache 14), hermetic (no Valkey needed). **NB (recalibrated 2026-06-15 after
the Operator flagged an over-claim): echo_fs is an IN-MEMORY MODEL — there is NO Lua and NO Valkey client in it;
the EchoMQ PROTOCOL (the Lua transitions on a Valkey wire) is NOT implemented (that is the efs.3 transport). "Tests
green" certifies the in-memory model + the pure primitives, NOT a running bus. Don't say echo_fs "ships the bus" /
"works" — say "in-memory model; protocol not implemented". Docs + the C4 EchoMQ-blocks carry this caveat.** Authored the reverse-spec docs
**`docs/echo_fs/`** (echo_fs.md front door + efs.design/roadmap/progress/references/testing) + **`docs/echo_fs/specs/`**
(efs.0 EchoMQ · efs.connector · efs.cache · efs.valkey). **Next rung efs.3 = the real Valkey socket transport**
(the ONE non-hermetic seam — same `IConnector`, swaps in with no caller change). Adapted the echo-mq-ship
skill: NO Elixir lead-team (its echo-mq-* skills don't fit F#), NO LAW-4 commit (operator commits) — senior-solo
authored + `dotnet test` as the gate. Dep arrows mirror the umbrella (echo_wire dep-free; echo_cache→both).

**The senior-writer prompt-pack pattern (use for C2/C3/C4 batches):** the orchestrator (senior writer)
PRE-VERIFIES the batch's signature F# through real `dotnet fsi`, then writes
`docs/fsharp/specs/c<N>.shared.prompt.md` (chapter narrative + contract + a verified-FSI echo table +
model pages + the two layout rules) + one `docs/fsharp/specs/c<N>MM.prompt.md` per module (3 dives, the
exact pre-verified F#, the interactive concept per page, the verified cross-course Related route, the
pager titles). Each `fsharp-expert` reads BOTH. This front-loads the three things parallel agents get
wrong: grounding (verified snippets, zero invention), the **link race** (N agents gate concurrently —
none may link a sibling-in-batch route; pin Related to own dives + an already-built module + a verified
`/elixir` route), and house-style consistency. C1.04–09 result: 24pp A+ first pass, 0 gate-invisible
defects (the only fixes were ~3 perceptual-verb slips/module, all agent-self-caught).

**Two captured F# traps (real `dotnet fsi 9.0.303`) — brief future agents:** (1) `Ok 5 |> Result.map (…)`
unannotated throws **FS0030 value restriction** (`it` is generic `Result<int,'_a>`) — annotate
`((Ok 5): Result<int,string>) |> …`; (2) a multi-case active pattern `(|Even|Odd|)` has type
`int -> Choice<unit,unit>` (case names act as patterns, not as DU values). Plus the standing lesson:
verify every snippet against the REPL. **Signature-display divergence (note):** C0–C2 used the name-less
form (`val inc : int -> int`); the **C4 batch used the form `dotnet fsi 9.0.303` ACTUALLY prints**
(parameter-named, `val inc: n: int -> int`) — both are valid F#; C4 chose fidelity to real FSI output.
Standardize on one form if a later pass wants course-wide consistency.

**Two durable gotchas for any /fsharp-write run:**
1. **The chapter landing may already exist** (a prior bootstrap/run authored C0's `history/index.html`).
   Reconcile, don't overwrite — and it is the **model page for that chapter's dives** (it carries the
   sub-page CSS the home `index.html` lacks: `.crumbs`, `.toc-mini`, `.refs`, `.bridge`, `.dive`,
   `.deflist`, `.note`, `pre.code .rdx/.step`). Point fan-out agents at the landing, not the home.
2. **The cms `links` gate is an EXACT-STRING match that does NOT strip fragments** (apollo.go gateLinks):
   a bare `#frag` is skipped, but `/fsharp#c0` is checked literally → dangles. So footer "Chapters"
   links on sub-pages must point at REAL routes (the contextual footer), never `/route#frag`. Every
   page's footer links the four sibling courses (`/elixir /redis-patterns /bcs /echomq`), so gate with
   ALL FIVE `--routes-from` mounts + `--require-refs` (the home is the one refs-exempt page).

Pattern siblings: [[redis-patterns-course]], [[bcs-course]], [[agile-course-canonical-route]],
[[logic-course]].
