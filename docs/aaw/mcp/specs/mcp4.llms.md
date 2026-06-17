# MCP4 · agent brief (llms)

> Implementation brief for a coding agent. References, traced requirements, the execution topology, and
> a self-contained build brief. Pairs with the spec mcp4.md and the stories mcp4.stories.md; this rung
> has no runbook — the comprehensive implementation prompt below is the complete build instruction.

## References

- `apps/aaw/cmd/aaw/main.go` — the boot surface, as built: `:32-33` the two existing identity flags
  (`-addr` default `localhost:8905`, `-workspace` default `.` — this rung adds `-log-level`, `-stdio`,
  `-wire-check`; the usage line at `:48` extends accordingly); `:511-533` the bind loop (`:518-521` the
  per-family continue-on-failure this rung replaces with all-or-nothing; `:531-532` the zero-listener
  fatal); `:536` the per-listener log line (the banner seed); `:395-431` the `aaw_status` console the
  verdict lands in (`:166` the comment pinning the deliberate `wire_contract` omission — the field this
  rung computes); `:433` the `probe` registration; `:566` the selftest 18-tool pin; `:85`/`:98`/`:150`
  the as-built `model` fields (`SpawnIn`/`RegisterIn`/`LivenessRow`, surfaced at `:424`).
- `apps/aaw/internal/signals/signals.go` — `:23-32` the policy constants (W=45 min, K=3, cap=240) whose
  doc comment names this rung's move: "Named constants until the config rung homes them in
  `.aaw/config.json`". Their consumers re-point at the read-through; the signal rules themselves are
  MCP2's and unchanged.
- `apps/aaw/internal/store/store.go` — `:50` `Agent.Model` (additive, `omitempty`); `:364`/`:391` the
  empty-keeps-stored continuity application in `SpawnAgent`/`RegisterAgent` — the as-built behavior
  this rung pins by test, not re-implements.
- `apps/aaw/internal/gates/gates.go` — `:37-38` the reserved `PORT_BUSY`/`WIRE_MISMATCH` constants
  (members of the closed set, `:58-59`): this rung's two boot refusals render through these constants
  in the contract form `aaw: <CODE>: <detail>` — the `INSTANCE_LOCKED` boot-refusal precedent
  (`apps/aaw/internal/store/lock.go:44`) — never through a parallel error path; no new code is minted.
- `.mcp.json` — the as-committed `aaw` entry the wire check validates: `"type": "streamable-http"`,
  `"url": "http://localhost:8905/"` (`:7-10`); the comparison target is the `url` host:port against
  the bound address.
- `.gitignore` — `:201` the directory-form `.aaw/` ignore: the W-3 site. The conversion is the glob pair
  `.aaw/*` + `!.aaw/config.json` (a bare negation under a directory-form ignore is a git no-op — D-9).
- `.claude/commands/x.md` — `:123` the bootstrap `aaw_init` signature: the F-2 site (Operator-fenced;
  the one-line edit adds `ledger_dir`, only under the standing grant).
- The design canon (settled): [`../aaw.mcp.design.md`](../aaw.mcp.design.md) — AD-8 (identity by flags,
  policy by the tree-visible file, no env, no per-knob overrides, `effective_config` with winning
  sources), AD-9 (all-or-nothing bind, diagnosed `PORT_BUSY`, the three-state `-wire-check`,
  validate-never-generate), AD-11 (the banner and `probe` observability fields), AD-4 (the `model`
  row field this rung closes).
- The run ledger [`../aaw.mcp.progress.md`](../aaw.mcp.progress.md) — D-6(c) (the no-env, no-per-knob
  composition), D-9 (the W-3 gitignore precision), F-2 (the fenced doc edit); the roadmap row
  [`../aaw.mcp.roadmap.md`](../aaw.mcp.roadmap.md) §mcp4; [the specs
  approach](../../../elixir/specs/specs.approach.md). Depends on MCP1 (the flock and bind surfaces),
  MCP2 (the console rows), and MCP3 (the reserved `PORT_BUSY`/`WIRE_MISMATCH` constants in
  `internal/gates/` — this rung emits them) — referenced by id; the transport posture and the C-1
  probe are mcp8's rung (displaced from mcp5 by the D-14 Reconcile-tool promotion) and appear nowhere
  in this brief's tasks.

## Requirements

- **MCP4-R1** — boot identity is flags-only: `-addr` (default `localhost:8905`), `-workspace` (default
  `.`), `-log-level`, `-stdio`, `-wire-check`; the flags locate the workspace and listener before any
  file plane exists; no environment variable is read anywhere in `apps/aaw`. [US: MCP4-US-D1]
- **MCP4-R2** — runtime policy (W, K, quiet cap, default `ttl_days`, audit dedup window, the lint token
  list) reads through `<workspace>/.aaw/config.json` on every evaluation — an edit applies with no
  restart; no per-knob policy flag exists; precedence is file > built-in default, reported per knob
  with its winning source in `probe.effective_config`; the server never writes the config file.
  [US: MCP4-US-D1]
- **MCP4-R3** — for host `localhost` the server binds both loopback families or refuses with
  `PORT_BUSY`; on refusal one capped (~500 ms) MCP probe of the occupied port — refusal-path only —
  names the holder (an aaw instance's workspace + version, or a foreign process with `lsof` guidance);
  no automatic port hunting. [US: MCP4-US-D2]
- **MCP4-R4** — `-wire-check` is three-state (`strict|warn|skip`), `strict` by default: validate the
  workspace `.mcp.json` `aaw` entry against the bound address; `strict` refuses boot on
  `mismatch`/`unparseable` with `WIRE_MISMATCH`, printing the fix in both directions; `warn` proceeds
  loudly; `skip` reports `skipped`; the server never generates or edits `.mcp.json`. [US: MCP4-US-D3]
- **MCP4-R5** — the computed `wire_contract` verdict (`agree|mismatch|absent|unparseable|skipped`) is
  surfaced in `probe` and `aaw_status` — the field MCP2 deliberately omitted; `mismatch` is reachable
  only under `warn`; no constant or defaulted verdict is ever reported. [US: MCP4-US-A1, MCP4-US-A2]
- **MCP4-R6** — the as-built `model` field is pinned record-only by tests: recorded at spawn/register,
  surfaced in the status liveness row, empty-keeps-stored on re-spawn/re-register, no behavior branch;
  every shape stays additive against MCP3 — a deferred-schema client holding MCP3 shapes stays valid.
  [US: MCP4-US-D4]
- **MCP4-R7** — the boot banner carries one line per listener + the wire verdict + the resolved
  absolute workspace; `probe` carries `started_at`, the listener addresses, the instance id, per-scope
  `reopened_at`, `effective_config`, and `wire_contract`; the W-3 `.gitignore` conversion lands; the
  F-2 doc line lands only under the standing Operator grant — absent the grant it is held and reported.
  [US: MCP4-US-D5, MCP4-US-A2]

## Execution topology

Runtime: boot parses the identity flags, acquires the MCP1 flock, binds all-or-nothing, computes the
wire verdict, and prints the banner; every policy evaluation reads through the config file; `probe` and
`aaw_status` report what the boot computed.

```text
boot ──flags(-addr -workspace -log-level -stdio -wire-check)──▶ flock ──▶ bind tcp4+tcp6 (all-or-nothing)
        │                                                                  └─ fail ──▶ holder probe (≤500 ms)
        │                                                                             ──▶ refuse PORT_BUSY
        ├──▶ wire check (.mcp.json vs bound addr) ──▶ agree | mismatch | absent | unparseable | skipped
        │        └─ strict: mismatch/unparseable ──▶ refuse WIRE_MISMATCH (fix printed both directions)
        └──▶ banner: one line per listener + wire verdict + absolute workspace
policy eval (signals, ttl, dedup, lint) ──read-through──▶ .aaw/config.json  (file > default; no env)
probe / aaw_status ──▶ effective_config (winning source per knob) + wire_contract + observability fields
```

Tasks (each step leaves the app compiling):

```text
1. internal/config: the flag set + the .aaw/config.json read-through + effective-config report
   ─▶ 2. re-point the policy consumers (signals W/K/cap, ttl default, dedup window, lint list)
         at the read-through; delete no constant name — defaults stay as the built-in layer
   ─▶ 3. bind all-or-nothing for localhost + the refusal-path holder probe + PORT_BUSY via gates
   ─▶ 4. wire check: parse .mcp.json, compare to the bound address, the three-state flag,
         WIRE_MISMATCH via gates; verdict carried to probe + aaw_status (additive fields)
   ─▶ 5. banner + probe fields (started_at, listeners, instance id, reopened_at, effective_config)
   ─▶ 6. W-3: .gitignore .aaw/ → .aaw/* + !.aaw/config.json; F-2: the x.md:123 ledger_dir line
         (under the standing grant — held + reported if absent)
   ─▶ 7. tests: config read-through (edit applies, no env honored) · two-instance family-split
         refusal · wire-verdict matrix (all five states) · model additive/continuity · banner/probe
         assertions · selftest green at 18 tools
```

Touched files: `apps/aaw/cmd/aaw/main.go`, `apps/aaw/internal/config/` (new),
`apps/aaw/internal/signals/` (consumers re-pointed), `apps/aaw/internal/store/**` (the `model`
pinning tests), `.gitignore` (the two W-3 lines), `.claude/commands/x.md` (the one F-2 line, under
grant), tests. No `apps/mcp-go` change.

## Agent stories

- **MCP4-AS1** [implements MCP4-US-D1] — Directive: add `internal/config/` — the five identity flags and
  the `.aaw/config.json` read-through (W, K, cap, `ttl_days`, dedup window, lint list; file > built-in
  default; never written by the server; no env read), with the per-knob winning-source report; re-point
  the policy consumers in `internal/signals/` and the TTL/dedup/lint sites; convert the `.gitignore`
  ignore to `.aaw/*` + `!.aaw/config.json`. Acceptance gate: a config edit applies on the next
  evaluation with no restart; a policy-named env var has no effect; `go build ./...` clean.
- **MCP4-AS2** [implements MCP4-US-D2] — Directive: make the `localhost` bind all-or-nothing — both
  loopback families or a `PORT_BUSY` refusal through the MCP3-reserved constant — and add the capped
  (~500 ms) refusal-path holder probe naming an aaw holder (workspace + version) or guiding `lsof` for
  a foreign one; no port hunting. Acceptance gate: a two-instance test shows the second boot refusing
  `PORT_BUSY` with the holder named, never a one-family bind.
- **MCP4-AS3** [implements MCP4-US-D3, MCP4-US-A1] — Directive: implement the three-state `-wire-check` (strict
  default) validating the workspace `.mcp.json` `aaw` entry against the bound address; refuse
  `mismatch`/`unparseable` under `strict` with `WIRE_MISMATCH` printing the fix in both directions;
  carry the computed verdict into `probe` and `aaw_status` as additive fields; never write `.mcp.json`.
  Acceptance gate: the wire-verdict matrix covers all five states; `mismatch` appears only under
  `warn`; a byte-comparison shows `.mcp.json` untouched across every state.
- **MCP4-AS4** [implements MCP4-US-D4] — Directive: pin the as-built `model` field with tests — recorded
  at spawn/register, surfaced in the status liveness row, empty-keeps-stored continuity, no behavior
  branch, additive against MCP3 shapes. The field exists (`store.go:50`, applied `:364`/`:391`); this
  story adds the running checks, not the field. Acceptance gate: the additive/continuity test is green;
  a grep shows no behavior branching on `Model`.
- **MCP4-AS5** [implements MCP4-US-D5, MCP4-US-A2] — Directive: extend the boot banner (one line per listener + wire
  verdict + resolved absolute workspace, extending `main.go:536`) and `probe` (`started_at`, listeners,
  instance id, per-scope `reopened_at`, `effective_config`, `wire_contract`); apply the F-2 one-line
  edit at `.claude/commands/x.md:123` only under the standing Operator grant — absent it, hold the edit
  and report. Acceptance gate: a banner/probe assertion over a clean boot; the F-2 line present under
  the grant or its hold reported in the build output.

## Execution plan — first two stories

1. **MCP4-AS1 — the config plane.** Add `internal/config/` (flags, read-through, effective-config);
   re-point `internal/signals/` W/K/cap and the ttl/dedup/lint sites; convert `.gitignore:201` to the
   W-3 pair. Gate: the read-through test (edit applies, no restart; env ignored) green;
   `go build ./...` clean.
2. **MCP4-AS2 — the honest bind.** Replace the per-family `continue` (`main.go:518-521`) with
   all-or-nothing for `localhost`; add the refusal-path holder probe + `PORT_BUSY` (the MCP3-reserved
   constant gains its emitter). Gate: the two-instance family-split refusal test green.

## Comprehensive implementation prompt

```text
Build MCP4 — config, ports & the wire contract — over the MCP3 surface. Edit apps/aaw plus the two
named out-of-package files only (.gitignore W-3; .claude/commands/x.md F-2 under the standing Operator
grant); do not touch apps/mcp-go; run no git. The transport posture and the C-1 probe are mcp8's rung:
build neither. Execute the agent stories in order, AS1 -> AS5.

AS1 — the config plane. New package apps/aaw/internal/config: the five identity flags (-addr default
localhost:8905, -workspace default ".", -log-level, -stdio, -wire-check) and the
<workspace>/.aaw/config.json policy read-through (liveness window W default 45 min, director threshold
K default 3, quiet cap default 240 min, default ttl_days, audit dedup window, lint token list). Read
the file on every evaluation — an Operator edit applies with no restart; the server NEVER writes it.
No environment layer; no per-knob policy flags. Precedence file > built-in default, reported per knob
with its winning source in probe.effective_config. Re-point the policy consumers (the W/K/cap
constants in apps/aaw/internal/signals/signals.go:23-32 and the ttl/dedup/lint sites) at the
read-through, keeping the built-in values as the default layer. Convert the .gitignore ignore
(.gitignore:201) from the directory form ".aaw/" to the pair ".aaw/*" + "!.aaw/config.json".

AS2 — the honest bind. For host localhost, bind BOTH loopback families (tcp4 127.0.0.1, tcp6 [::1]) or
refuse: replace the per-family continue at cmd/aaw/main.go:518-521 with all-or-nothing; on refusal run
one capped (~500 ms) MCP probe against the occupied port — refusal-path only, never pre-bind — and
name the holder (an aaw instance's workspace + version when it answers as one; lsof guidance when
foreign); refuse with the reserved PORT_BUSY constant (internal/gates/gates.go:37), rendered in the
contract form "aaw: PORT_BUSY: <detail>" the INSTANCE_LOCKED way (internal/store/lock.go:44) — never
a parallel error path. No automatic port hunting.

AS3 — the wire check. Three-state -wire-check, strict by default: parse the workspace .mcp.json aaw
entry (the as-committed form: "type": "streamable-http", "url": "http://localhost:8905/"; the url's
host:port is the comparison target) and compare it to the bound address; verdict
agree | mismatch | absent | unparseable | skipped. strict refuses boot on mismatch/unparseable with
the reserved WIRE_MISMATCH constant (internal/gates/gates.go:38, the same contract form), printing
the fix in both directions (edit .mcp.json to the bound address, or re-flag -addr to the committed
entry); warn proceeds loudly; skip reports skipped. Carry the computed verdict into probe and
aaw_status as additive fields (the StatusOut comment at cmd/aaw/main.go:166 pins the deliberate MCP2
omission this rung closes). The server never generates or edits .mcp.json.

AS4 — pin the model field. The field is as-built (store.go:50, applied :364/:391; params
main.go:85/:98; status row :150/:424): add the running checks — recorded at spawn/register, surfaced
in the status liveness row, empty-keeps-stored on re-spawn/re-register, no behavior branch, every
shape additive against MCP3.

AS5 — the honest boot. Banner: one line per listener + the wire verdict + the resolved absolute
workspace (extend main.go:536). probe: started_at, listener addresses, instance id, per-scope
reopened_at, effective_config with winning sources, wire_contract. F-2: under the standing Operator
grant, add ledger_dir to the bootstrap aaw_init signature at .claude/commands/x.md:123 — one line;
absent the grant, hold the edit and report the hold.

End on the gates: GOWORK=off go build ./... clean; GOWORK=off go vet ./apps/aaw/... clean;
GOWORK=off go test -race -count=1 ./apps/aaw/... green (config read-through incl. no-env · two-instance
family-split refusal · wire-verdict matrix all five states · model additive/continuity · banner/probe
assertions); aaw selftest green at 18 tools; the MCP1 goldens green; apps/mcp-go untouched; never git.
Report the modules changed, the gate results, the F-2 grant outcome (landed or held), and confirmation
that the tool surface stayed 18 and no transport-posture change was made.
```

Spec: mcp4.md · Stories: mcp4.stories.md · Index: mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
