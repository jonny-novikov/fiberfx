# F# In Depth — course map (quick reference)

The C0–C5 chapter/route/status map and the resume point. The authoritative tree is
`docs/fsharp/fsharp.toc.md`; the live status is `docs/fsharp/fsharp.progress.md`; the grounding is
`docs/fsharp/fsharp.roadmap.md`. This file is the at-a-glance copy the skill and agents read first.

Course letter **C** · served at **`/fsharp`** · dark-editorial identity + F# violet accent
(`--fsharp:#b48ee0`) · model page `html/fsharp/index.html`.

| Chapter | Route | Modules | Dives | Grounding | Status |
|---|---|---:|---|---|---|
| C0 · History | `/fsharp/history` | 2 | 3 each | documented ML/.NET history | **built** |
| C1 · F# Language | `/fsharp/language` | 9 | 3 each | valid idiomatic F# | **built** |
| C2 · F# for C# developers | `/fsharp/for-csharp` | 9 | 3 each | valid F# + real C# | **built** |
| C3 · F# for Elixir developers | `/fsharp/for-elixir` | 9 | 3 each | valid F# + real Elixir; cross-links /elixir | landing built |
| C4 · Algorithms & Data Structures | `/fsharp/algorithms` | 12 | — | valid F# at parity with Elixir E4 (+ efficiency notes) | soon |
| C5 · Pragmatic Programming — DevOps Tools | `/fsharp/devops` | 9 | — | the real `ibbs` codebase | soon |

**Course home `/fsharp` — built** (the C0–C5 landing map). 50 modules planned, 20 built (C0 · History, C1 · F# Language, and C2 · F# for C# developers all complete; C3 · F# for Elixir developers landing built — its modules next).

## Chapter slugs & module slugs

See `docs/fsharp/fsharp.toc.md` for the full per-module slug list. The chapter slugs are
`history · language · for-csharp · for-elixir · algorithms · devops`.

## C5 grounding (the ibbs codebase)

`/Users/jonny/dev/ibbs` — `DevOps.sln`: `src/DevOps.Tools` (`analysis.dll` — parser, aggregation,
`Monitoring.fs`), `src/DevOps.Sfera` (`sfera.dll` — auth + PRs + branches), `src/DevOps.Server`
(`devops-server` — host, JSON API, Html builder, the `fs` sub-command), `web/client-fs` (Fable
F#→JS: `Ui/Api/Dashboard/Database/Releases/App`), `tests/DevOps.Tools.Tests` (xUnit, 104 tests).
The per-module map is in `docs/fsharp/fsharp.roadmap.md`. **Verify every cited surface on disk.**

## Resume point

**C0 · History — complete** (2 modules, 6 dives). **C1 · F# Language — complete** (9 modules, 27 dives).
**C2 · F# for C# developers — complete** (9 modules, 27 dives; valid C# beside F#, every snippet verified
against `dotnet fsi` / `dotnet script`). **C3 · F# for Elixir developers — landing built** (the chapter
front door; its 9 modules are `soon`). 20 teaching modules / 85 pages built.
**Next: C3 · F# for Elixir developers modules** (`/fsharp/for-elixir`, 9 modules × 3 dives) — the
Elixir-community bridge: two-runtimes → static-types → pattern-matching → the-pipe → data-modeling →
errors → concurrency → polymorphism → tooling (lab). Ground each in valid F# **beside real Elixir** and
cross-link the matching `/elixir` module. Then **C4 · Algorithms** (`/fsharp/algorithms`, 12 modules —
reflects Elixir **E4** with cross-links + implementation/efficiency notes) and **C5 · DevOps Tools**
(`/fsharp/devops`, the `ibbs` capstone). Author with `/fsharp-write for-elixir two-runtimes …`
(cross-course mount `/elixir=elixir`; pre-verify F# against `dotnet fsi`; markdown alongside the HTML).
