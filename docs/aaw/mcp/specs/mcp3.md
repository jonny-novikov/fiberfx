# MCP3 · the error vocabulary + the ledger-grammar formalization

> The contract surfaces of the aaw MCP server v2: every domain refusal carries a code from one closed,
> append-only vocabulary, rendered `aaw: <CODE>: <detail>` in the tool result — replacing the PoC's
> free-text `fmt.Errorf` strings, so a caller (and a test) can branch on the code, not on substring
> luck — and the design-§8 EBNF becomes the implemented single authority for the ledger grammar:
> lenient parse, strict emit, the reserved prefix vocabulary, unknown prefixes reported and never
> gating. Over the MCP2 surface, adding no tool.

## Goal

The third rung of the build ladder, hardening both contract surfaces the evidence rungs report through.
First, the refusals: every refusal the server returns becomes a typed, named value from a single closed
set (design §9, sixteen codes), rendered `aaw: <CODE>: <detail>` in the `IsError` tool result. Every
existing free-text refusal in `aaw_init`, `aaw_spawn`, `agent_register`, `agent_send`,
`agent_heartbeat`, the eleven ledger writers, and `aaw_status` is re-expressed on the vocabulary; the
`created` output flag resolves its one v1 ambiguity additively (`scope_created` + `ledger_created`,
`created` kept as alias); and the selftest plus a new in-process round-trip tier assert the **exact
code**, so a code regression is caught by a running check. Second, the grammar: the design §8 EBNF
becomes the implemented single authority for "well-formed ledger" — the parse stays lenient (`#`/`##`
section heads, `##`/`###` entry heads; hand-written history is first-class), the emission stays strict
(the locked canonical form), the reserved prefix vocabulary is declared in one home, and unknown hand
prefixes are surfaced in `aaw_status` parse-health — reported, never gating. One boundary gate from the
roadmap row has **no as-built sensor** and is built new here: path containment (`PATH_ESCAPE` at the
init/spawn doors, with the `CONTAINMENT` advisory as its rider — MCP3-D8). The tool surface stays 18 —
this rung ships contracts, not capability. Build formation: **standard tier** (D-10) — one implementor
build pass → one second-context refine (a resumed-implementor harden or an evaluator verify, not both)
→ the Director gate + one pathspec commit (the tier rule lives in the roadmap's "How the roadmap
runs").

## Rationale (5W)

- **Why**   — the PoC raises refusals as bare strings (`cmd/aaw/main.go:276,293,333,417,420` and the
  store's parse/containment/gate errors): a client cannot distinguish "scope not initialized" from
  "slug invalid" without matching English, a renamed message silently breaks a branch, and the
  selftest can only assert `IsError` true/false, not which gate fired. And the ledger grammar lives as
  scattered regex literals (`internal/store/ledger.go:51,200,212`) with no declared single authority:
  the lenient/strict discipline is as-built behavior, but no one home states the grammar, no closed
  prefix set is declared, and an unknown hand prefix is invisible in status. A process that gates work
  must name its refusals, and the file it gates by must have a formal grammar.
- **What**  — one closed `aaw: <CODE>: <detail>` vocabulary in a single home, codes append-only; every
  domain refusal re-expressed on it; the new containment boundary gate (`PATH_ESCAPE` at the doors,
  the `CONTAINMENT` advisory rider on legacy rows); the `created` alias resolution; exact-code
  assertions in the selftest and a new in-process protocol tier; and the §8 EBNF formalized — the
  lenient parse faces and strict emit faces ratified and pinned, the reserved prefix vocabulary
  declared, unknown-prefix reporting added to parse-health.
- **Who**   — the harness and the Director (which branch on a refusal class and read parse-health), the
  Operator (who reads a named refusal in a log and hand-writes ledger entries that must stay
  first-class), and the maintainer who needs the gate set and the grammar pinned by checks that assert
  the code and the bytes, not the prose.
- **When**  — the rung after MCP2; it depends on the MCP1 store discipline (whose committed goldens are
  the grammar's regression floor) and the MCP2 tool surface, and on nothing later. The boot refusals
  `PORT_BUSY` / `WIRE_MISMATCH` are reserved in the set here and emitted by MCP4; `ARTIFACTS_REQUIRED`
  is reserved and emitted by the resonance rung.
- **Where** — `apps/aaw/cmd/aaw/main.go` (every refusal site, the door checks, the parse-health
  surfacing, the selftest), a new `apps/aaw/internal/gates/` (the code constants + the render helper +
  the containment predicate — the AD-12 gate-plane package the roadmap's mcp3 diff boundary names),
  `apps/aaw/internal/store/` (the store/ledger refusals and the grammar home: the declared prefix
  vocabulary, the unknown-prefix collection), and a new in-process round-trip test. The locked entry
  header, the section-tag form, the numbering rule, and every tool schema (beyond the additive
  parse-health field) are untouched — formalization pins the as-built grammar, it does not redesign
  it.

## Scope

- **In**  — the closed code set (design §9) as Go constants in one home, with the `aaw: <CODE>: <detail>`
  render; the sweep re-expressing every as-built domain refusal on it (`SLUG_INVALID`,
  `NOT_INITIALIZED`, `LEDGER_DIR_REQUIRED`, `LEDGER_DIR_CONFLICT`, `PARENT_NOT_FOUND`,
  `AGENT_UNKNOWN`, `NOT_REGISTERED`, `GATE_Z_REQUIRES_D`, `ARG_MISSING`, `CORRUPT_STATE`); the **new
  containment boundary gate** (`PATH_ESCAPE` at the `aaw_init`/`aaw_spawn` doors, the `CONTAINMENT`
  advisory rider on legacy out-of-tree scopes, and the selftest's workspace-derived ledger dir —
  MCP3-D8); the documented reservation of `INSTANCE_LOCKED` (the live MCP1 boot refusal, its literal
  folded into the same set), `PORT_BUSY`, `WIRE_MISMATCH` (MCP4 boot refusals), `ARTIFACTS_REQUIRED`
  (the resonance tool), and `ARCHIVED` (MCP7's archival rung); the `created` → `scope_created` +
  `ledger_created` additive resolution; the exact-code selftest upgrade; the in-process
  (`NewInMemoryTransports`) round-trip tier asserting each in-band code once; **and the §8 grammar
  formalization** — the lenient parse faces (`#`/`##` sections, `##`/`###` entries) and the
  strict emit faces ratified as the single declared authority, the reserved prefix vocabulary
  (`T A V D L S C E P Z Y R`) as a closed declared set, the unknown-prefix collection surfaced
  additively in `aaw_status` parse-health, and the lenient-in/strict-out golden over the committed
  exemplars.
- **Out** — any new tool, parameter (beyond the additive `scope_created`/`ledger_created` outputs and
  the additive parse-health field), or new liveness/channel/resonance behavior; new signal RULES
  beyond the one `CONTAINMENT` emit site the containment gate carries (MCP3-D8); the `ARCHIVED`
  write-refusal and its re-open path (`reopened_at`) — MCP7's archival rung ships both together; the
  boot-refusal emission for `PORT_BUSY`/`WIRE_MISMATCH` and the wire-contract check (MCP4);
  configuration and the policy file (MCP4); **any grammar change** — the locked
  `### <PREFIX>-<n> — <title>` entry header, the `{<scope>-<channel>}` section tag, and the
  whole-file numbering rule are ratified as-is; a new entry prefix or section form would be a design
  §8 amendment, not a rung decision. Each deferral goes to the named rung.

## Deliverables

- **MCP3-D1** — a single error home `apps/aaw/internal/gates/gates.go` (the AD-12 gate-plane package;
  the roadmap's mcp3 diff boundary names `internal/gates/`, and the MCP3-D8 containment predicate
  homes beside the codes): the closed code set as exported constants (design §9), and
  `Errorf(code, format, args…) error` rendering `aaw: <CODE>: <detail>`; a `Code(err) string`
  extractor for the tests. Codes are append-only — the set is closed and a new code is a new
  constant, never a rename or a removal.
- **MCP3-D2** — every as-built **domain refusal** re-expressed on the vocabulary: the `ARG_MISSING`
  sites (`cmd/aaw/main.go:276,293,333,417`, plus the non-director-spawn-without-`parent_id` refusal,
  `internal/store/store.go:332` — a required parameter is empty, so `ARG_MISSING`, not
  `PARENT_NOT_FOUND`); `SLUG_INVALID` at both raise sites (`cmd/aaw/main.go:420` and the init-side
  check, `store.go:149` — §9's raised-by column names init and the ledger writers); and the
  store/ledger refusals (scope-not-initialized → `NOT_INITIALIZED`, `store.go:215`; first-init
  without dir → `LEDGER_DIR_REQUIRED`, `store.go:166`; re-init dir mismatch → `LEDGER_DIR_CONFLICT`,
  `store.go:160`; missing parent → `PARENT_NOT_FOUND`, `store.go:329`; unknown heartbeat name →
  `AGENT_UNKNOWN`, `store.go:454`; unregistered recipient → `NOT_REGISTERED`, `store.go:390`; zero-D
  complete → `GATE_Z_REQUIRES_D`, `internal/store/ledger.go:186`; unparseable index/registry →
  `CORRUPT_STATE`, `store.go:124,257`). No domain refusal returns a bare `fmt.Errorf` string. The
  `unknown stream` error (`ledger.go:128`) is unreachable from the tool surface — the closed streams
  table fixes every stream string — and stays a documented internal invariant error, exempt from the
  grep gate.
- **MCP3-D3** — the `created` output resolution, additive and break-free: `InitScope` returns
  `scope_created` (the index row was new) and `ledger_created` (the file was absent and a header
  written); `InitOut` carries both plus `created` kept as a documented alias of `scope_created` (its v1
  meaning, `cmd/aaw/main.go:63`). No existing field is renamed or retyped.
- **MCP3-D4** — the boot refusal and the reserved codes documented in the same closed set:
  `INSTANCE_LOCKED` is **already live at HEAD** (`internal/store/lock.go:38`, printed as
  `aaw: INSTANCE_LOCKED: <detail>` through `cmd/aaw/main.go:455`'s `aaw: %v` prefix) — its literal
  folds into the one home as the boot-time, non-tool-result member, behavior unchanged; `PORT_BUSY`
  and `WIRE_MISMATCH` (MCP4 boot refusals), `ARTIFACTS_REQUIRED` (the resonance tool), and `ARCHIVED`
  (MCP7's lazy-archival rung, which ships the write-refusal WITH its re-open path — a refusal with no
  re-open would strand a lapsed-TTL scope; at HEAD the TTL is a status-only hint,
  `internal/store/store.go:539-551`) are declared constants with no live emitter this rung —
  reserved, so the set is whole and append-only across rungs.
- **MCP3-D5** — exact-code verification: the `aaw selftest` upgraded so every refusal it triggers
  asserts its specific code (not `IsError` alone); and a new in-process tier
  (`mcp.NewInMemoryTransports`, `apps/aaw/internal/store/` or a new test file) exercising every tool and
  refusing every domain gate at least once with its exact §9 code asserted.
- **MCP3-D6** — the **§8 EBNF as the implemented single grammar authority**: the as-built lenient parse
  faces — the entry head `^#{2,3} ([A-Z]+)-(\d+)\b` (`internal/store/ledger.go:51`) and the section
  head `^#{1,2} {<scope>-<channel>}` (`ledger.go:200`) — and the strict emit faces — `###` entry heads
  (`ledger.go:193`), `##` section heads created at EOF (`ledger.go:207`), the splice that preserves
  every byte outside it (`ledger.go:212-236`), whole-file numbering (`nextN`, `ledger.go:71`) — are
  ratified, declared as the grammar in one home beside the **reserved prefix vocabulary** (the closed
  v2 entry set `T A V D L S C E P Z Y R`, design §8), and pinned by a lenient-in/strict-out golden: a
  hand heading matching `^#{2,3} [A-Z]+-[0-9]+` is an entry by definition; emission never widens the
  lenient forms.
- **MCP3-D7** — **unknown-prefix reporting in parse-health**: prefixes outside the reserved set (a hand
  `### ADR-3`) are tolerated as first-class entries, collected at parse, and surfaced by `aaw_status`
  as an additive parse-health field (`unknown_prefixes`, separate from the closed-prefix tallies) —
  reported, never gating. The as-built console carries `parse_ok`/`parse_error`/`entry_count`
  (`cmd/aaw/main.go:167-169`) and no unknown-prefix field; this rung adds it additively.
- **MCP3-D8** — the **containment boundary gate, built new this rung** (no as-built sensor exists:
  `resolve`, `internal/store/store.go:196-201`, joins and cleans only; the §9 `PATH_ESCAPE` row has
  had no raise site): at the door, a first-init `ledger_dir` (`aaw_init`) and a spawn-declared
  `deliverable` (`aaw_spawn`) are absolutized against the workspace, cleaned, and must sit under the
  workspace root — else the call refuses `aaw: PATH_ESCAPE: <detail>` and creates nothing. Existing
  index rows are honored: no retro-refusal on reads or appends to an already-initialized scope.
  **Rider:** a write through any tool to a legacy scope whose `ledger_dir` sits outside the workspace
  root emits one deduplicated `CONTAINMENT` advisory line (the AD-5 signal; the constant has had no
  call site since MCP2 — `internal/signals/signals.go:40`) — reported, never refused. **Selftest
  fallout, fixed here:** the as-built selftest creates its ledger dir out-of-root
  (`os.MkdirTemp("", …)`, `cmd/aaw/main.go:539`), which this gate would refuse — the selftest derives
  its ledger dir from `probe.workspace` (`cmd/aaw/main.go:389`) and the old out-of-root dir becomes
  the `PATH_ESCAPE` exact-code assertion.

## Invariants

- **MCP3-INV1** — **every domain refusal is a code.** No tool returns a bare `fmt.Errorf` string as an
  `IsError` result; each is `aaw: <CODE>: <detail>` with `<CODE>` from the closed set.
- **MCP3-INV2** — **the set is closed and append-only.** The code vocabulary lives in one home; a rung
  may add a constant, never rename, retype, or remove one — a removed or renamed code is a breaking
  change the design forbids.
- **MCP3-INV3** — **the `created` resolution does not break.** A caller reading `created` observes
  `scope_created`'s value (the v1 meaning); `scope_created` and `ledger_created` are additive new keys,
  so a client holding MCP2 shapes stays valid.
- **MCP3-INV4** — **codes are pinned by a running check.** The selftest and the in-process tier assert
  the exact code per refusal class, so a code regression fails a test rather than passing silently.
- **MCP3-INV5** — **protocol failures stay the SDK's.** Malformed JSON-RPC and unknown-tool errors are
  not domain refusals and keep the SDK's handling; the vocabulary covers domain refusals only.
- **MCP3-INV6** — **lenient in, strict out.** Parsing a ledger that holds lenient forms (`#`-level
  section heads, `##`-level entry heads) and appending to it preserves every prior entry's bytes
  verbatim and emits only the strict canonical form (`##` section, `###` entry) for the new content —
  the preservation invariant the MCP1 goldens pin, restated as the grammar's law; numbering continues
  across hand-written and tool-written entries alike.
- **MCP3-INV7** — **unknown prefixes never gate.** An entry under an unreserved prefix parses, is
  reported in parse-health, and never causes a refusal — and it never alters the Z-gate's semantics
  (the gate counts `D-<n>` entries only).
- **MCP3-INV8** — **containment refuses at the door, never retroactively.** A new out-of-root path
  refuses `PATH_ESCAPE` before any row or file is created; an already-initialized scope keeps reading
  and appending, with writes to a legacy out-of-tree scope carrying the deduplicated `CONTAINMENT`
  advisory line — a signal, never a block.

## Definition of Done

- [ ] `internal/gates/` holds the closed code set as constants, the `aaw: <CODE>: <detail>` render +
      a `Code` extractor, and the containment predicate (MCP3-D1, MCP3-D8).
- [ ] every as-built domain refusal is re-expressed on a code; a grep finds no bare-string `fmt.Errorf`
      returned as a tool-result error (the `ledger.go:128` internal invariant error exempt as
      documented) (MCP3-D2, MCP3-INV1).
- [ ] `InitOut` carries `scope_created` + `ledger_created`; `created` is kept as a documented alias of
      `scope_created` (MCP3-D3, MCP3-INV3).
- [ ] `INSTANCE_LOCKED` folds its live boot literal into the home (behavior unchanged); `PORT_BUSY`,
      `WIRE_MISMATCH`, `ARTIFACTS_REQUIRED`, `ARCHIVED` are declared with no live emitter this rung —
      the set is whole and append-only (MCP3-D4, MCP3-INV2).
- [ ] an out-of-root `ledger_dir`/`deliverable` refuses `aaw: PATH_ESCAPE: …` at the door, creating
      nothing; a legacy out-of-tree scope keeps working and its writes carry one deduplicated
      `CONTAINMENT` advisory; the selftest derives its ledger dir from `probe.workspace` and asserts
      `PATH_ESCAPE` on the out-of-root form (MCP3-D8, MCP3-INV8).
- [ ] the selftest asserts the exact code for every refusal it triggers; an in-process round-trip tier
      refuses every domain gate once with its exact §9 code (MCP3-D5, MCP3-INV4).
- [ ] the §8 grammar is declared in one home — the lenient parse faces, the strict emit faces, and the
      reserved prefix vocabulary (`T A V D L S C E P Z Y R`) — and the lenient-in/strict-out golden
      passes over the committed exemplars: prior bytes preserved verbatim, new emission strictly
      canonical, numbering continued (MCP3-D6, MCP3-INV6).
- [ ] a hand-written `### ADR-3` heading is tolerated, surfaced in `aaw_status` parse-health as an
      unknown prefix (additive field), and gates nothing (MCP3-D7, MCP3-INV7).
- [ ] the tool surface is unchanged (18); a deferred-schema client holding MCP2 shapes stays valid;
      `aaw selftest` is green and the live scopes still parse and append — demoable.

Stories: ./mcp3.stories.md · Agent brief: ./mcp3.llms.md · Index: ./mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
