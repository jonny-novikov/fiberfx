# MCP3 · agent brief (llms)

> Implementation brief for a coding agent. References, traced requirements, the execution topology, and
> a self-contained build brief. Pairs with the spec mcp3.md and the stories mcp3.stories.md; this rung
> has no runbook — the comprehensive implementation prompt below is the complete build instruction.

## References

- `apps/aaw/cmd/aaw/main.go` — the refusal sites, as built: `:63` `InitOut.Created` (the v1 flag this
  rung resolves additively); `:261-266` `aaw_init` (returns the single `created` bool — to split into
  `scope_created`/`ledger_created`); `:276` / `:293` / `:333` / `:417` the `ARG_MISSING`-class bare
  strings; `:420` the slug refusal → `SLUG_INVALID`; `:539` the selftest's out-of-root
  `os.MkdirTemp("", …)` ledger dir (re-pointed at `probe.workspace`, `:389`, by the containment gate);
  `:455` the `aaw: %v` boot prefix that already renders `INSTANCE_LOCKED` in the contract form.
- `apps/aaw/internal/store/store.go` — `InitScope` (`:172` the row creation; the as-built refusals:
  slug `:149`, `LEDGER_DIR_CONFLICT` `:160`, `LEDGER_DIR_REQUIRED` `:166`), `GetScope` (`:215` →
  `NOT_INITIALIZED`), the index/registry parse failures (`:124`, `:257` → `CORRUPT_STATE`), the spawn
  gates (`:329` → `PARENT_NOT_FOUND`; `:332` missing `parent_id` → `ARG_MISSING`), `RecordMessage`
  (`:390` → `NOT_REGISTERED`), `Heartbeat` (`:454` → `AGENT_UNKNOWN`). **No containment sensor exists**
  — `resolve` (`:196-201`) joins and cleans only, so the `PATH_ESCAPE` gate is NEW this rung (MCP3-D8);
  `Archived` (`:539-551`) is a status-only hint ("no rung enforces it") — `ARCHIVED` is reserved for
  MCP7, not re-expressed here.
- `apps/aaw/internal/store/ledger.go` — the `GATE_Z_REQUIRES_D` refusal in the complete writer (`:186`)
  and the unreachable `unknown stream` internal error (`:128`, exempt from the grep gate); **and the
  as-built grammar engine this rung formalizes**:
  the lenient entry-head regex `^#{2,3} ([A-Z]+)-(\d+)\b` (`entryRe`, `:51`), whole-file numbering
  (`nextN`, `:71`), the title lift (`titleSplit`, `:87`), and the splice (`appendLocked`, `:170-240` —
  the lenient section regex `^#{1,2} {tag}` at `:200`, the strict `###` entry emit at `:193`, the
  strict `##` new-section emit at `:207`, the byte-preserving insert boundary at `:212-236`). The
  locked entry header and the emission forms are ratified as-is — formalization pins, never redesigns.
- `apps/aaw/internal/store/lock.go:38` — the live `INSTANCE_LOCKED` boot refusal (its literal folds
  into the constant home, behavior unchanged); `apps/aaw/internal/signals/signals.go:40` —
  `CodeContainment`, a constant with zero call sites since MCP2: the MCP3-D8 rider gives it its one
  emit site (advisory, deduplicated by the Emitter's window rule).
- The design canon (settled): [`../aaw.mcp.design.md`](../aaw.mcp.design.md) — §9 (the sixteen-code
  closed vocabulary, the table of code → raised-by → meaning), AD-7 (the error contract: `IsError`
  text `aaw: <CODE>: <detail>`, codes append-only, protocol failures stay the SDK's), AD-6 (the
  `created` alias + `ledger_created` resolution), **§8 (the EBNF grammar: parse-lenient / emit-strict,
  the reserved prefix vocabulary `T A V D L S C E P Z Y R`, whole-file numbering, the preservation
  invariant, unknown prefixes tolerated and reported, never gating)**.
- Upstream: the proposal `aaw.mcp.proposal.md` (R-1, R-9 the stable surface) — retired from the
  tree post-canon; readable via `git show 74d8a899:docs/aaw/mcp/aaw.mcp.proposal.md` — and
  [the specs approach](../../../elixir/specs/specs.approach.md). Depends on MCP1 (the
  store discipline) and MCP2 (the 18-tool surface) — referenced by id.

## Requirements

- **MCP3-R1** — a single home `internal/gates/gates.go` (the AD-12 gate-plane package the roadmap's
  mcp3 diff boundary names) declares the closed §9 code set as exported constants and renders
  `aaw: <CODE>: <detail>` via `Errorf(code, format, args…)`; a `Code(err)` extractor reads the code
  back for tests; the MCP3-R9 containment predicate homes in the same package; codes are append-only.
  [US: MCP3-US2]
- **MCP3-R2** — every as-built domain refusal in the tool handlers, the store, and the ledger returns
  a `gates` value with the matching closed code per the MCP3-D2 site map (`store.go:332` → `ARG_MISSING`;
  the init-side slug check `store.go:149` → `SLUG_INVALID`); no domain refusal returns a bare
  `fmt.Errorf` string; the unreachable `unknown stream` internal error (`ledger.go:128`) is documented
  and exempt from the grep gate. [US: MCP3-US1]
- **MCP3-R3** — `InitScope`/`aaw_init` return `scope_created` and `ledger_created`; `InitOut` carries
  both and keeps `created` as a documented alias of `scope_created`; no existing field is renamed or
  retyped. [US: MCP3-US3]
- **MCP3-R4** — `INSTANCE_LOCKED` folds its live boot literal (`lock.go:38`, already rendered
  `aaw: INSTANCE_LOCKED: <detail>` via `main.go:455`) into the constant home, behavior unchanged;
  `PORT_BUSY`, `WIRE_MISMATCH` (MCP4), `ARTIFACTS_REQUIRED` (resonance), and `ARCHIVED` (MCP7's
  archival rung — the write-refusal ships there WITH its re-open path) are declared constants with no
  live emitter this rung. [US: MCP3-US2]
- **MCP3-R5** — `aaw selftest` asserts the exact code for every refusal it triggers; a new in-process
  tier (`mcp.NewInMemoryTransports`) refuses every domain gate at least once with its exact §9 code
  asserted. [US: MCP3-US4]
- **MCP3-R6** — malformed-request and unknown-tool failures keep the SDK's protocol handling and never
  become an `aaw:` domain code; the tool surface stays 18 and additive. [US: MCP3-US5]
- **MCP3-R7** — the §8 grammar is declared in one home in the store: the lenient parse faces (sections
  `^#{1,2}`, entries `^#{2,3}`), the strict emit faces (`##` section, `###` entry), the whole-file
  numbering rule, and the reserved prefix vocabulary `T A V D L S C E P Z Y R` as a closed declared
  set; parsing a lenient ledger then appending preserves every prior entry's bytes verbatim and emits
  only the canonical form — pinned by a lenient-in/strict-out golden over the committed exemplars.
  [US: MCP3-US6]
- **MCP3-R8** — prefixes outside the reserved set are tolerated as first-class entries, collected at
  parse, and surfaced by `aaw_status` as an additive parse-health field (`unknown_prefixes`, separate
  from the closed-prefix tallies); they never cause a refusal and never alter the Z-gate's D-count
  semantics. [US: MCP3-US6]
- **MCP3-R9** — the containment boundary gate is built new: a first-init `ledger_dir` and a
  spawn-declared `deliverable`, absolutized and cleaned against the workspace, must sit under the
  workspace root or the call refuses `aaw: PATH_ESCAPE: <detail>`, creating nothing; existing index
  rows are honored (no retro-refusal on reads or appends); a write through any tool to a legacy
  out-of-tree scope emits one deduplicated `CONTAINMENT` advisory line (never a refusal); the selftest
  derives its ledger dir from `probe.workspace` and asserts `PATH_ESCAPE` on the old out-of-root form.
  [US: MCP3-US7]

## Execution topology

Runtime: a refusal flows handler/store → `gates.Errorf(CODE, …)` → the SDK renders it as the `IsError`
tool result text `aaw: <CODE>: <detail>`; the success path is unchanged. Codes and the containment
predicate live in one package; the tests read codes back through `gates.Code`.

```text
gate fails ──▶ gates.Errorf(CODE, "detail %s", x) ──▶ IsError result: "aaw: CODE: detail …"
success     ──▶ unchanged (typed Out struct)
door paths (init ledger_dir · spawn deliverable) ──Abs/Clean──▶ escapes root? ──▶ aaw: PATH_ESCAPE
legacy out-of-tree row ──any write──▶ proceeds + one CONTAINMENT advisory (dedup) — never refuses
test        ──▶ call tool ──▶ assert gates.Code(result) == EXPECTED   (selftest + in-process tier)
```

Tasks (each step leaves the app compiling):

```text
1. internal/gates: the closed code constants + Errorf render + Code extractor + the containment
   predicate
   ─▶ 2. sweep main.go refusals onto codes (ARG_MISSING, SLUG_INVALID, the gate sites)
   ─▶ 3. sweep store.go + ledger.go refusals onto codes (NOT_INITIALIZED, LEDGER_DIR_*,
         PARENT_NOT_FOUND, AGENT_UNKNOWN, NOT_REGISTERED, GATE_Z_REQUIRES_D, CORRUPT_STATE;
         store.go:332 → ARG_MISSING; store.go:149 → SLUG_INVALID; fold lock.go:38's
         INSTANCE_LOCKED literal)
   ─▶ 4. the containment gate: PATH_ESCAPE at the init/spawn doors + the CONTAINMENT advisory
         rider on legacy out-of-tree rows + the selftest ledger dir re-derived from
         probe.workspace
   ─▶ 5. created → scope_created + ledger_created (alias kept) in InitScope + InitOut
   ─▶ 6. reserve PORT_BUSY / WIRE_MISMATCH / ARTIFACTS_REQUIRED / ARCHIVED (no emitter)
   ─▶ 7. the grammar home: declare the reserved prefix set + the lenient/strict faces beside the
         engine; collect unknown prefixes at parse; surface unknown_prefixes in aaw_status
         (additive parse-health field)
   ─▶ 8. tests: selftest exact-code upgrade (incl. PATH_ESCAPE) + the in-process round-trip tier
         (every in-band gate once) + the lenient-in/strict-out golden + the unknown-prefix
         status assertion
```

Touched files: `apps/aaw/internal/gates/gates.go` (new — the codes, the render, the extractor, the
containment predicate), `apps/aaw/internal/gates/gates_test.go` (new — the closed-set + render +
extractor + containment-predicate test), `apps/aaw/cmd/aaw/main.go` (the handler sweep, the door
checks + the `CONTAINMENT` emit, the selftest), `apps/aaw/internal/store/store.go`,
`apps/aaw/internal/store/lock.go` (the `INSTANCE_LOCKED` literal fold),
`apps/aaw/internal/store/ledger.go` (the grammar home: the
declared prefix vocabulary + the unknown-prefix collection),
`apps/aaw/internal/store/mcp3_test.go` (new — the in-process round-trip tier + the init-alias test +
the lenient-in/strict-out golden + the unknown-prefix assertion). The MCP1 goldens under
`apps/aaw/internal/store/testdata/` are the grammar's
regression floor — read, never rewritten.

## Agent stories

- **MCP3-AS1** [implements MCP3-US2] — Directive: add `internal/gates/gates.go` with the sixteen §9
  codes as exported constants, `Errorf(code, format, args…) error` rendering `aaw: <CODE>: <detail>`,
  `Code(err) string`, and the containment predicate (a path, absolutized and cleaned against a root,
  reported under-root or escaping); add `gates_test.go` pinning the constant set, the render, and the
  predicate. Acceptance gate: the constant-set test is green; `go build ./...` clean.
- **MCP3-AS2** [implements MCP3-US1] — Directive: re-express every domain refusal in `cmd/aaw/main.go`
  on `gates` with the matching code (the `ARG_MISSING` sites, `SLUG_INVALID`, and the parent /
  recipient / Z-gate surfaces). Acceptance gate: a grep finds no bare-string `fmt.Errorf` returned as
  a tool-result error from a handler.
- **MCP3-AS3** [implements MCP3-US1] — Directive: re-express the store and ledger refusals
  (`NOT_INITIALIZED`, `LEDGER_DIR_REQUIRED`, `LEDGER_DIR_CONFLICT`, `PARENT_NOT_FOUND`,
  `AGENT_UNKNOWN`, `NOT_REGISTERED`, `GATE_Z_REQUIRES_D`, `CORRUPT_STATE`; `store.go:332` →
  `ARG_MISSING` — a required parameter is empty, not `PARENT_NOT_FOUND`; the init-side slug check
  `store.go:149` → `SLUG_INVALID`; fold `lock.go:38`'s `INSTANCE_LOCKED` literal into the constant —
  behavior unchanged; the `unknown stream` internal error, `ledger.go:128`, stays exempt as
  unreachable from the tool surface). Acceptance gate:
  each surfaces its code through the handler; the MCP1/MCP2 tests stay green.
- **MCP3-AS4** [implements MCP3-US3] — Directive: split `InitScope`'s return into `scope_created` +
  `ledger_created`; add both to `InitOut`; keep `created` as a documented alias of `scope_created`.
  Acceptance gate: a first-init-vs-reopen test asserts the three flags; no field renamed.
- **MCP3-AS5** [implements MCP3-US4, MCP3-US5] — Directive: upgrade the selftest to assert exact codes;
  add the in-process (`NewInMemoryTransports`) tier refusing every in-band domain gate once with its
  code (the eleven emittable codes: `SLUG_INVALID`, `NOT_INITIALIZED`, `LEDGER_DIR_REQUIRED`,
  `LEDGER_DIR_CONFLICT`, `PATH_ESCAPE`, `PARENT_NOT_FOUND`, `AGENT_UNKNOWN`, `NOT_REGISTERED`,
  `GATE_Z_REQUIRES_D`, `ARG_MISSING`, `CORRUPT_STATE`), plus
  an unknown-tool contrast showing the SDK protocol error is not an `aaw:` code. Acceptance gate: the
  tier is green; reserved codes (`PORT_BUSY`, `WIRE_MISMATCH`, `ARTIFACTS_REQUIRED`, `ARCHIVED`) have
  constants but no emitter.
- **MCP3-AS6** [implements MCP3-US6] — Directive: declare the §8 grammar in one home in the store —
  the reserved prefix vocabulary `T A V D L S C E P Z Y R` as a closed set beside the engine's lenient
  parse faces (`entryRe`, the section regex) and strict emit faces (the `###` entry head, the `##`
  new-section head); collect prefixes outside the reserved set at parse and surface them additively in
  `aaw_status` parse-health as `unknown_prefixes`; change no emission form and no entry header.
  Acceptance gate: the lenient-in/strict-out golden over the committed exemplars passes (prior bytes
  verbatim, new emission canonical, numbering continued); a fixture holding `### ADR-3` appends
  cleanly, reports `ADR` in parse-health, and refuses nothing.
- **MCP3-AS7** [implements MCP3-US7] — Directive: wire the containment gate at the doors — `aaw_init`'s
  first-init `ledger_dir` and `aaw_spawn`'s `deliverable` resolve through the `gates` predicate
  (absolutize against the workspace, clean) and refuse `aaw: PATH_ESCAPE: <detail>` when escaping the
  root, creating nothing; honor existing index rows (no retro-refusal on reads or appends); emit one
  deduplicated `CONTAINMENT` advisory line on any write to a legacy out-of-tree scope (the
  `signals.go:40` constant's first call site); re-derive the selftest ledger dir from
  `probe.workspace` and convert the old out-of-root temp dir into the `PATH_ESCAPE` exact-code
  assertion. Acceptance gate: the door-refusal and legacy-advisory tests are green; the selftest
  passes against a live server and asserts `PATH_ESCAPE`.

## Execution plan — first two stories

1. **MCP3-AS1 — the vocabulary.** Add `internal/gates/gates.go` (the constants, `Errorf`, `Code`, the
   containment predicate) and its test. Gate: the closed-set test green; `go build ./...` clean.
2. **MCP3-AS2 — the handler sweep.** Route `cmd/aaw/main.go`'s domain refusals through `gates`
   (`:276,293,333,417` → `ARG_MISSING`; `:420` → `SLUG_INVALID`; the gate sites → their codes). Gate: a
   grep shows no bare-string tool-result `fmt.Errorf` in the handlers; `go test ./... ` green.

## Comprehensive implementation prompt

```text
Build MCP3 — the closed error contract + the ledger-grammar formalization — over the MCP2 surface.
Edit apps/aaw only; do not touch apps/mcp-go; run no git. Execute the agent stories in the build
order AS1 -> AS2 -> AS3 -> AS7 -> AS4 -> AS6 -> AS5 (the verification tier closes the rung).

AS1 — the vocabulary. Add apps/aaw/internal/gates/gates.go (the gate-plane package the roadmap's diff
boundary names): the sixteen design-§9 codes as exported
string constants (SLUG_INVALID, NOT_INITIALIZED, LEDGER_DIR_REQUIRED, LEDGER_DIR_CONFLICT, PATH_ESCAPE,
PARENT_NOT_FOUND, AGENT_UNKNOWN, NOT_REGISTERED, GATE_Z_REQUIRES_D, ARCHIVED, ARG_MISSING,
ARTIFACTS_REQUIRED, CORRUPT_STATE, INSTANCE_LOCKED, PORT_BUSY, WIRE_MISMATCH); Errorf(code, format,
args...) error rendering exactly "aaw: <CODE>: <detail>"; Code(err) string reading the code back; and
the containment predicate (a path, absolutized against a root and cleaned, reported under-root or
escaping). Add gates_test.go pinning the constant set, the render format, and the predicate.

AS2/AS3 — the sweep. Re-express every as-built domain refusal in cmd/aaw/main.go,
internal/store/store.go, and internal/store/ledger.go through gates with the matching code, per the
spec's MCP3-D2 site map exactly: main.go:276,293,333,417 + store.go:332 -> ARG_MISSING (store.go:332
is a required-parameter-empty case, NOT PARENT_NOT_FOUND); main.go:420 + store.go:149 -> SLUG_INVALID;
store.go:215 -> NOT_INITIALIZED; store.go:166 -> LEDGER_DIR_REQUIRED; store.go:160 ->
LEDGER_DIR_CONFLICT; store.go:329 -> PARENT_NOT_FOUND; store.go:454 -> AGENT_UNKNOWN; store.go:390 ->
NOT_REGISTERED; ledger.go:186 -> GATE_Z_REQUIRES_D; store.go:124 + store.go:257 -> CORRUPT_STATE.
Fold lock.go:38's INSTANCE_LOCKED literal into the constant (behavior unchanged — the boot path
already prints aaw: INSTANCE_LOCKED: <detail> via main.go:455). Do NOT wire an ARCHIVED refusal: at
HEAD the TTL is a status-only hint and MCP7 ships the write-refusal with its re-open path. The
unknown-stream error (ledger.go:128) is unreachable from the tool surface and stays as is, exempt
from the grep gate. No domain
refusal returns a bare fmt.Errorf string. Leave the success paths and the typed Out structs unchanged.

AS7 — the containment gate (NEW behavior; no as-built sensor exists — store.go's resolve at :196-201
joins and cleans only). At the doors: aaw_init's first-init ledger_dir and aaw_spawn's deliverable
resolve through the gates predicate and refuse aaw: PATH_ESCAPE: <detail> when escaping the workspace
root, creating nothing. Existing index rows are honored — no retro-refusal on reads or appends to an
already-initialized scope. Rider: any write to a legacy scope whose ledger_dir sits outside the
workspace root emits ONE deduplicated CONTAINMENT advisory line to .claude/audit.log (the
signals.CodeContainment constant's first call site; the Emitter window dedup applies; advisory —
never refuse). Selftest fallout, fixed in this story: the selftest's os.MkdirTemp("", ...) ledger dir
(main.go:539) is out-of-root and the gate would refuse it — derive the selftest ledger dir from
probe.workspace (main.go:389) instead, and convert the old out-of-root dir into the PATH_ESCAPE
exact-code assertion.

AS4 — the created resolution. Split InitScope's single created bool into scope_created (the index row
was new) and ledger_created (the file was absent and a header written); add both to InitOut; keep
created as a documented alias of scope_created (its v1 meaning). Additive only — rename nothing.

AS5 — exact-code verification (closes the rung). Upgrade the selftest so every refusal it triggers
asserts its specific code via gates.Code, not IsError alone. Add an in-process tier using
mcp.NewInMemoryTransports that exercises every tool and refuses every in-band domain gate at least
once, asserting its exact code — the eleven emittable codes: SLUG_INVALID, NOT_INITIALIZED,
LEDGER_DIR_REQUIRED, LEDGER_DIR_CONFLICT, PATH_ESCAPE, PARENT_NOT_FOUND, AGENT_UNKNOWN,
NOT_REGISTERED, GATE_Z_REQUIRES_D, ARG_MISSING, CORRUPT_STATE — plus one
unknown-tool round-trip showing the SDK protocol error is NOT an aaw: domain code. The reserved codes
(PORT_BUSY, WIRE_MISMATCH, ARTIFACTS_REQUIRED, ARCHIVED) have constants but no live emitter this
rung; INSTANCE_LOCKED keeps its boot emitter only.

AS6 — the grammar formalization. Declare the design-§8 grammar in one home in the store: the reserved
prefix vocabulary T A V D L S C E P Z Y R as a closed declared set, beside the engine's lenient parse
faces (entryRe `^#{2,3} ([A-Z]+)-(\d+)\b` at internal/store/ledger.go:51; the section regex
`^#{1,2} {tag}` at :200) and strict emit faces (the `###` entry head at :193; the `##` new-section
head at :207). Collect prefixes outside the reserved set at parse and surface them additively in
aaw_status parse-health as unknown_prefixes (separate from the closed-prefix tallies; never gating;
the Z-gate keeps counting D-n entries only). Change NO emission form, NO entry header, NO numbering
rule — formalization pins the as-built grammar. Pin lenient-in/strict-out with a golden over the
committed exemplar ledgers: parse, append, assert every prior entry's bytes verbatim, the new emission
canonical, and per-prefix numbering continued across hand-written and tool-written entries; add a
fixture holding a hand `### ADR-3` heading and assert it appends cleanly, reports ADR in parse-health,
and refuses nothing.

End on the gates: GOWORK=off go build ./... clean; go vet ./... clean; go test -race -count=1 ./...
green; the selftest asserts exact codes at 18 tools (incl. the PATH_ESCAPE assertion) against a live
server; the in-process tier refuses every in-band gate with its code; a grep
finds no bare-string tool-result fmt.Errorf in the handlers/store (the documented ledger.go:128
exemption aside); the door-refusal + legacy-advisory containment tests and the lenient-in/strict-out
golden and the unknown-prefix assertion are green; the tool surface is 18 and apps/mcp-go is
untouched. Report the modules changed, the gate results, and confirmation that no code was renamed or
removed, no emission form changed, and the tool surface stayed 18.
```

Spec: mcp3.md · Stories: mcp3.stories.md · Index: mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
