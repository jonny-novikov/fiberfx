# aaw MCP server — the testing view (reverse, as-built)

> How the **aaw** server (`2.0.0-min`) is proven *as it ships*: the `selftest` over-the-wire gate,
> the Go unit/property suite across the four planes, and the conventions the gate runs under.
> Grounded in the as-built tree at [`go/aaw/`](../../../go/aaw/) — re-probe before trusting any count
> (test names and line numbers drift). This document adds no contract; it records how the as-built
> surface defined in [`./aaw.design.md`](./aaw.design.md) is proven, and where the proof is thin.
> The forward four-tier conformance plan (its tiers, the mutation-kill-rate charter, the 22-tool
> pin) is the forward authority — [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md)
> §11 — linked, not restated.

Canon: the as-built design [`./aaw.design.md`](./aaw.design.md) · the forward conformance plan
[`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) §11 · the build guide
[`go/CLAUDE.md`](../../../go/CLAUDE.md) · the testing-discipline rules
[`../../aaw/aaw.rules.md`](../../aaw/aaw.rules.md) (The gates).

---

## 0 · How the gate runs

Per the build guide ([`go/CLAUDE.md`](../../../go/CLAUDE.md)), each Go server compiles and tests
**hermetically from its own `go.mod`** with **`GOWORK=off`** — never assuming the workspace:

```text
cd go/aaw
GOWORK=off go build ./...
GOWORK=off go vet  ./...
GOWORK=off go test ./...
```

`go.mod` pins `go 1.25.0` and `replace github.com/fiberfx/mcp-go/v2 => ../mcp-go`, so the suite
builds against the vendored SDK fork. The integration gate, `aaw selftest`, runs against a **live
server** over HTTP (it connects as an MCP client) — it is not part of `go test`; it is run after a
`serve` boot.

## 1 · The `selftest` gate — registration + a T→D→Z round-trip over the wire

`aaw selftest` is the "registered without errors" gate, run rather than claimed
(`cmd/aaw/main.go:744-862`, the `runSelftest` doc). It connects to a running server as an MCP client
and proves, in order:

1. **The 18-tool count over the wire** — `session.ListTools` returns exactly 18, or the gate fails:
   `if got, want := len(tools.Tools), 18; got != want { log.Fatalf(…) }` (`cmd/aaw/main.go:778`).
   This is the as-built count pin (the forward `mcp8` plan extends it to 22 over a hermetic
   workspace — forward §11 tier 4).
2. **A containment refusal at the door** — `aaw_init` with an out-of-root `ledger_dir` must refuse
   with the exact code `PATH_ESCAPE` (`cmd/aaw/main.go:852`).
3. **The LAW-4 `Z`-gate** — a premature `tool_x_complete` (`Z-0` before any `D`) must refuse with
   `GATE_Z_REQUIRES_D` (`cmd/aaw/main.go:856`).
4. **The T→D→Z ledger round-trip** — `tool_x_trace` (`T-1`, with an `actor`) → `tool_x_decision`
   (`D-1`) → `tool_x_complete` (`Z-1`) all succeed once a `D` is locked
   (`cmd/aaw/main.go:857-859`), plus the ledger dir resolving under `probe.workspace`
   (`cmd/aaw/main.go:828-837`).

On success it prints `SELFTEST PASS: 18 tools registered …; ledger round-trip ok (T→D→Z; exact-code
refusals GATE_Z_REQUIRES_D + PATH_ESCAPE; …)` (`cmd/aaw/main.go:862`). The selftest is **signal-silent
by design** — one attributed write, no `FAKE-N`/`V-SOLO` emission — so it does not pollute the audit
log.

## 2 · The Go suite — by plane

The `go test ./...` suite covers the four planes plus the boot surface. Counts are the test/fuzz
functions per file (re-probe — they drift):

### `internal/store` — the single-writer store, ledger, flock (the master invariant's home)

| Test | What it pins | `file:line` |
| --- | --- | --- |
| `TestWriteFileAtomicNeverTorn` | a concurrent reader never observes a torn file | `internal/store/atomic_test.go:14` |
| `TestWriteFileAtomicCrashLeavesPriorWhole` | a crash mid-write leaves the complete prior file | `internal/store/atomic_test.go:75` |
| `TestLedgerConcurrentAppendsGapFree` | concurrent `tool_x_*` appends number gap-free under the per-scope lock | `internal/store/ledger_test.go:107` |
| `TestExemplarLedgerParseCompat` | the committed exemplar ledger parses and continues numbering (the golden) | `internal/store/ledger_test.go:59` |
| `TestSpawnConcurrencyProperty` | concurrent `aaw_spawn` mints distinct sequential CCL-ids | `internal/store/store_test.go:34` |
| `TestSpawnCrossScopeParallel` | distinct scopes never contend | `internal/store/store_test.go:105` |
| `TestRespawnKeepsCCLID` | re-spawn of a name keeps its CCL-id (identity continuity) | `internal/store/store_test.go:139` |
| `TestMintSeedsFromLegacyRows` | `next_ccl` hydrates once from a legacy `len(agents)+1` shape | `internal/store/store_test.go:183` |
| `TestIndexReadThroughOutOfBand` | an out-of-band index edit is honored on the next call (the L-2 fix) | `internal/store/store_test.go:201` |
| `TestIndexCorruptMidServe` | a corrupt index refuses rather than overwrites (`CORRUPT_STATE`) | `internal/store/store_test.go:249` |
| `TestInstanceLockExcludesSecondAcquire` / `TestSecondServerProcessRefused` | the flock excludes a second instance (`INSTANCE_LOCKED`) | `internal/store/lock_test.go:22,79` |

Plus the `mcp2`/`mcp3`/`mcp4` store suites: attributed-append byte-identity
(`internal/store/mcp2_test.go:18`), the unregistered-actor-creates-no-row rule (`:86`), the
ledger-leads write order (`:115`), three-source liveness fusion (`:151`), the heartbeat (`:203`); the
`scope_created`/`ledger_created` split + `created` alias (`internal/store/mcp3_test.go:19`), the
lenient-parse/strict-emit grammar golden (`:156`), unknown-prefix tolerated-but-reported (`:265`);
the `model` record-only continuity (`internal/store/mcp4_test.go:41`) and additive shape (`:91`); the
in-process gate-console round-trip (`internal/store/mcp2_wire_test.go:84`).

### `internal/gates` — the closed error vocabulary + containment

| Test | What it pins | `file:line` |
| --- | --- | --- |
| `TestClosedCodeSet` | the 16 codes are exactly the closed set, names == wire literals | `internal/gates/gates_test.go:14` |
| `TestErrorfRenderAndCodeExtractor` | refusals render `aaw: <CODE>: <detail>` and the code extracts back | `internal/gates/gates_test.go:45` |
| `TestContainedPredicate` | `Contained(root, path)` admits in-root, refuses escapes (the `PATH_ESCAPE` predicate) | `internal/gates/gates_test.go:73` |

### `internal/config` — the boot/config plane + wire verdict

`TestRegisterFlagsDefaults` (the five flags' defaults — `internal/config/config_test.go:23`),
`TestValidWireCheck` (`:51`), `TestPolicyReadThroughEditApplies` (a `.aaw/config.json` edit applies
on the next call, no restart — `:91`), `TestPolicyDegradesToDefaults` (`:134`), `TestNoEnvLayer`
(no environment layer exists — `:164`), `TestWireVerdictMatrix` (the
`agree|mismatch|absent|unparseable|skipped` matrix — `:223`).

### `internal/signals` — the advisory signals

`TestPolicyConstants` (`internal/signals/signals_test.go:13`), `TestEmitFormatDedupAndOpen` (the
audit-log line format + per-`(scope,code,window)` dedup — `:41`), `TestVSolo1TwoClause` (both clauses
required — `:100`), `TestVSolo2Computation` (`V-SOLO-2` computed but never emitted — `:135`).

### `cmd/aaw` — the boot surface

`TestMCP3InProcessRoundTrip` (`cmd/aaw/main_test.go:26` — an in-process client round-trip), and the
mcp4 boot suite (`cmd/aaw/mcp4_test.go`): `TestBindLocalhostAllOrNothingForeignHolder` (`:36`),
`TestBindLocalhostRefusalNamesAawHolder` (`:68`), `TestWireRefusesMatrix` (`:105`), `TestBannerLine`
(`:122`), `TestMCP4InProcessBootSurface` (`:138`), `TestWireFixBothDirections` (`:386`),
`TestWireContractNeverDefaulted` (`:402`).

## 3 · What each invariant maps to (the reverse-mode discipline)

Per the reverse playbook, a reverse rung closes when every invariant maps to a running check
([`../../aaw/aaw.reverse.md`](../../aaw/aaw.reverse.md)):

| Invariant (as-built) | Running check |
| --- | --- |
| Files are truth — no torn write | `TestWriteFileAtomicNeverTorn` · `TestWriteFileAtomicCrashLeavesPriorWhole` |
| Ledger append-only + gap-free numbering | `TestLedgerConcurrentAppendsGapFree` · `TestExemplarLedgerParseCompat` |
| Read-through index honors out-of-band edits | `TestIndexReadThroughOutOfBand` |
| One instance per workspace | `TestInstanceLockExcludesSecondAcquire` · `TestSecondServerProcessRefused` |
| LAW-4 — `Z` requires `D` | `selftest` (`cmd/aaw/main.go:856`) + the `Z`-branch (`internal/store/ledger.go:241`) |
| Closed, append-only error vocabulary | `TestClosedCodeSet` · `TestErrorfRenderAndCodeExtractor` |
| `PATH_ESCAPE` containment | `TestContainedPredicate` + `selftest` (`cmd/aaw/main.go:852`) |
| All-or-nothing dual-stack bind | `TestBindLocalhostAllOrNothingForeignHolder` |
| Wire verdict never fabricated | `TestWireContractNeverDefaulted` · `TestWireVerdictMatrix` |
| Advisory signals never block | `internal/signals` doc (MCP2-INV3) + `TestVSolo1TwoClause` |
| 18-tool surface, additive-only | `selftest` count pin (`cmd/aaw/main.go:778`) |

## 4 · The honest gaps (forward-owned)

- **No four-tier conformance suite or mutation-kill-rate yet.** The forward design's tier-3
  (in-process protocol round-trips for *every* tool + *every* refusal) and tier-4 (the 22-tool
  selftest over a hermetic workspace + a `tools/list` golden schema snapshot) are the forward `mcp8`
  closure — [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) §11. As built, the
  in-process round-trips are partial (`main_test.go`, the `mcp2`/`mcp3` store wire tests) and the
  count pin is 18.
- **The message-channel + resonance + `aaw audit` surfaces are unbuilt**, so their checks do not
  exist in this tree — they arrive with forward `mcp7`. The closed code set already reserves
  `ARTIFACTS_REQUIRED` for resonance, so that addition is non-breaking.
- **No coverage baseline is captured.** The suite proves behavior by example/property; a line/branch
  number is not measured here.

---

## Map

- As-built design (the surface these tests prove): [`./aaw.design.md`](./aaw.design.md).
- As-built features / roadmap / dashboard: [`./aaw.features.md`](./aaw.features.md) ·
  [`./aaw.roadmap.md`](./aaw.roadmap.md) · [`./aaw.progress.md`](./aaw.progress.md).
- Forward conformance plan (the four tiers, the mutation charter):
  [`../../aaw/mcp/aaw.mcp.design.md`](../../aaw/mcp/aaw.mcp.design.md) §11.
- The gate discipline: [`../../aaw/aaw.rules.md`](../../aaw/aaw.rules.md) (The gates) ·
  the reverse playbook [`../../aaw/aaw.reverse.md`](../../aaw/aaw.reverse.md).
- Source + build guide: [`go/aaw/`](../../../go/aaw/) · [`go/CLAUDE.md`](../../../go/CLAUDE.md).
