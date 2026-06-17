# MCP4 · config, ports & the wire contract

> The boot surface of the aaw MCP server v2 made honest and files-truth: identity by flags, policy in a
> tree-visible `.aaw/config.json` read through on every evaluation (no environment layer), an
> all-or-nothing dual-stack bind with a diagnosed `PORT_BUSY`, a three-state `-wire-check` strict by
> default that validates `.mcp.json` and never writes it, the computed `wire_contract` verdict the MCP2
> console deliberately omitted, and the `model` deferral closed. Adds no tool.

## Goal

The fourth rung of the build ladder, inside milestone M2: fix the server's boot identity, policy, port,
and wire surfaces. Boot identity becomes flags-only (`-addr`, `-workspace`, `-log-level`, `-stdio`,
`-wire-check`); runtime policy (the liveness window W, the director threshold K, the quiet cap, the
default `ttl_days`, the audit dedup window, the lint token list) moves from named constants in code into
the Operator-edited `.aaw/config.json`, read through on every evaluation so an edit applies with no
restart — no environment layer, no per-knob policy flags, precedence file > built-in default reported per
knob in `probe.effective_config`. The dual-stack loopback bind becomes all-or-nothing with a diagnosed
`PORT_BUSY` that names the holder, closing the family-split the PoC's continue-on-one-family left open.
A three-state `-wire-check` (strict default) validates the workspace `.mcp.json` against the bound
address and never generates or edits it; the `wire_contract` verdict — the field MCP2 deliberately
omitted because no rung had computed one — is now computed and surfaced in `probe` and `aaw_status`. The
`model` deferral closes formally, pinned record-only with the continuity rule. The boot banner and the
`probe` observability fields ship, and the two named build tasks land: the W-3 `.gitignore` conversion
and the F-2 doc edit (Operator-fenced, under the standing grant). The tool surface stays 18.

## Rationale (5W)

- **Why**   — the developer pays today's cost in silent boot drift: two instances can each hold one
  loopback family behind one URL (the PoC binds continue-on-one-family, `cmd/aaw/main.go:518-521` — a
  family that fails to bind is logged and skipped, fatal only at zero listeners, `:531-532`); policy
  lives as named constants in `internal/signals/signals.go:23-32`, untunable without a rebuild; and
  the boot identity surface is two flags (`-addr`, `-workspace` — `main.go:32-33`). The agent pays at
  the first stale dial: the wire contract between the committed `.mcp.json` and the bound address is
  unchecked, so a drifted entry fails only when a session dials it — and no in-band field reports the
  verdict. A boot that is not honest about its address, its policy, and its wire contract is a silent
  drift surface for both audiences.
- **What**  — the five identity flags; the `.aaw/config.json` policy read-through (no env, no per-knob
  flags) with `probe.effective_config`; the all-or-nothing bind + diagnosed `PORT_BUSY`; the three-state
  `-wire-check` (strict default) validating `.mcp.json`; the computed `wire_contract` verdict in
  `probe`/`aaw_status`; the `model` deferral closed; the boot banner + `probe` observability fields; and
  the named build tasks W-3 (`.gitignore`) and F-2 (the bootstrap doc edit).
- **Who**   — two audiences, named. **The developer** — the human who boots and maintains the server:
  tunes W/K/cap in the committed `.aaw/config.json` with no restart, owns `.mcp.json` and the F-2
  grant, runs more than one workspace against honest all-or-nothing binds with a diagnosed refusal,
  and audits formations with the `model` evidence on the record. **The agent** — the server's primary
  users: the session peers whose dials ride the wire contract the check validates, and who read the
  boot surface in-band — the computed `wire_contract` verdict and `effective_config` with winning
  sources arrive in the `probe`/`aaw_status` calls they already make.
- **When**  — the rung after MCP3; it depends on MCP1's flock and bind surfaces, MCP2's console rows
  (where the verdict and the `model` evidence surface), and MCP3's error vocabulary (it emits the
  reserved `PORT_BUSY` / `WIRE_MISMATCH` codes — `internal/gates/gates.go:37-38`, already members of
  the closed set at `:58-59`; never a parallel error path). mcp8's cutover probe dials the boot surface this
  rung fixes (the transport posture + C-1 probe ride mcp8 — the D-14 displacement); M2 closes at
  mcp5, the Reconcile tool rung.
- **Where** — `apps/aaw/cmd/aaw/main.go` (the flags, the bind loop, the banner, the `aaw_status`/`probe`
  shapes), a new `apps/aaw/internal/config/` (the flags + the policy read-through + effective-config),
  `apps/aaw/internal/signals/` (the policy consumers re-pointed from the named constants to the
  read-through), `apps/aaw/internal/store/` (the `model` pinning), plus `.gitignore` (the W-3 two-line
  conversion) and `.claude/commands/x.md` (the F-2 line, Operator-fenced). No `apps/mcp-go` change —
  the SDK seam belongs to mcp8's probe.

## Scope

- **In**  — the identity flags `-addr`, `-workspace`, `-log-level`, `-stdio`, `-wire-check`; the
  `.aaw/config.json` policy read-through (W=45, K=3, cap=240, default `ttl_days`, audit dedup window,
  the lint token list) with no env and no per-knob flags, precedence file > built-in default reported in
  `probe.effective_config`; all-or-nothing dual-stack bind + capped (~500 ms) holder probe + diagnosed
  `PORT_BUSY` (refusal-path only, no port hunting); the three-state `-wire-check`
  (strict|warn|skip, strict default) with the `agree|mismatch|absent|unparseable|skipped` verdict + the
  `WIRE_MISMATCH` boot refusal; the computed `wire_contract` verdict surfaced in `probe` + `aaw_status`;
  the `model` deferral closed — pinned additive, record-only, with the continuity rule; the boot banner
  + `started_at`/listeners/instance id/per-scope `reopened_at` on `probe`; the W-3 `.gitignore`
  conversion (`.aaw/` → `.aaw/*` + `!.aaw/config.json`) and the F-2 doc line as named build tasks.
- **Out** — **the transport posture and the C-1 build-gate probe are mcp8's rung** (displaced from
  mcp5 by the D-14 Reconcile-tool promotion; the stateless configuration, the live harness dial, the
  stateful flip, and the O-1 ratification all leave with it);
  the `aaw audit` CLI (mcp7); `tool_x_resonance` and the `channel_*` family (mcp6/mcp7); any new tool;
  any change to the ledger grammar, the entry header, the MCP2 signal rules, or the MCP3 vocabulary
  beyond emitting the two reserved boot codes. Each is deferred to the named rung.

## Deliverables

- **MCP4-D1** — **identity by flags, policy by the tree-visible file, no env** (design AD-8): the five
  identity flags locate the workspace and listener before any file plane exists; the policy constants
  move from `internal/signals/signals.go:23-32` into the Operator-edited `.aaw/config.json`, read
  through on every evaluation so an edit applies with no restart; **no environment layer, no per-knob
  policy flags** (D-6(c)); precedence file > built-in default, reported per knob with its winning source
  in `probe.effective_config`; the config file is never written by the server. The **W-3 `.gitignore`
  conversion** — the directory-form ignore (`.gitignore:201`) becomes the glob pair `.aaw/*` +
  `!.aaw/config.json` (a bare negation under a directory-form ignore is a git no-op — D-9) — is a named
  build task making the policy file committable.
- **MCP4-D2** — **all-or-nothing dual-stack bind + diagnosed refusal** (design AD-9): for host
  `localhost`, bind both loopback families or refuse with `PORT_BUSY` — replacing the
  continue-on-one-family lenience (`cmd/aaw/main.go:518-521`); on refusal, one capped (~500 ms) MCP
  probe of the occupied port — refusal-path only, never a pre-bind check — names the holder (an aaw
  instance's workspace + version, or a foreign process with `lsof` guidance). No automatic port hunting:
  a server that silently moves breaks its own wire contract.
- **MCP4-D3** — the **three-state `-wire-check`** (strict default) + the **computed `wire_contract`
  verdict**: validate the workspace `.mcp.json` `aaw` entry against the bound address; verdict
  `agree | mismatch | absent | unparseable | skipped`; `strict` refuses boot on `mismatch`/`unparseable`
  with `WIRE_MISMATCH` (printing the fix in both directions), `warn` proceeds loudly, `skip` opts out
  reported as `skipped`. The server **never generates or edits** `.mcp.json`. The verdict is surfaced in
  `probe` and `aaw_status` — closing the deferral MCP2 pinned (`cmd/aaw/main.go:166` omits the field
  until a rung computes one; this is that rung), and `mismatch` is reachable only under `warn`.
- **MCP4-D4** — the **`model` deferral closed** (LAW-2 evidence, design AD-4). [RECONCILE] The field
  itself LANDED EARLY in MCP2's harden pass — `SpawnIn.Model` (`cmd/aaw/main.go:85`),
  `RegisterIn.Model` (`:98`), `LivenessRow.Model` (`:150`, surfaced at `:424`), applied with
  empty-keeps-stored continuity (`internal/store/store.go:364`, `:391`) — additive, record-only. This
  rung closes the deferral formally: the continuity rule (a re-spawn/re-register without `model` keeps
  the stored value) and the additive shape are pinned by running tests, and no behavior branches on the
  field.
- **MCP4-D5** — the **boot banner and the `probe` observability fields** (design AD-11): one banner line
  per listener plus the wire verdict and the resolved absolute workspace (extending the as-built
  per-listener log, `cmd/aaw/main.go:536`); `probe` carries `started_at`, the listener addresses, the
  instance id, per-scope `reopened_at`, `effective_config` with winning sources, and `wire_contract`.
  Plus the **F-2 doc edit** as a named build task: the `.claude/commands/x.md:123` bootstrap signature
  gains a `ledger_dir` argument — the protocol docs are Operator-fenced, so the one-line edit lands only
  under the standing grant and must not survive the build unfixed in either direction (the O-2 item:
  surfaced for the Operator, not decided here; absent the grant, the edit is held and reported).

## Invariants

- **MCP4-INV1** — **never a family-split.** For `localhost` the server binds both loopback families or
  refuses with `PORT_BUSY`; it never serves on one family while another instance holds the other.
- **MCP4-INV2** — **no env, policy is files-truth.** No environment variable and no per-knob policy
  flag affects behavior; policy reads through `.aaw/config.json` so an edit applies on the next
  evaluation with no restart, and `probe.effective_config` reports each knob's winning source.
- **MCP4-INV3** — **the wire contract is validated, never written.** The server never generates or edits
  `.mcp.json`; `-wire-check strict` refuses boot on `mismatch`/`unparseable` (`WIRE_MISMATCH`); the
  verdict `probe`/`aaw_status` report is the one the boot computed — `mismatch` is reachable only under
  `warn`, and no constant or defaulted verdict is ever reported.
- **MCP4-INV4** — **`model` is additive record-only.** No behavior branches on `model`; it is recorded
  on spawn/register and surfaced in the status row; an absent `model` on re-spawn/re-register keeps the
  stored value; a client holding MCP3 shapes stays valid.

## Definition of Done

- [ ] the five identity flags exist; policy reads through `.aaw/config.json` (W/K/cap/ttl/dedup/lint
      list), no env, no per-knob flags; an edit applies with no restart; `probe.effective_config`
      reports winning sources; the W-3 `.gitignore` conversion is in place (MCP4-D1, MCP4-INV2).
- [ ] `localhost` binds both loopback families or refuses `PORT_BUSY`; the refusal-path holder probe
      names an aaw holder by workspace+version or guides for a foreign process; no port hunting
      (MCP4-D2, MCP4-INV1).
- [ ] `-wire-check` is three-state, strict by default; `mismatch`/`unparseable` refuse boot with
      `WIRE_MISMATCH` printing the fix in both directions; the computed verdict is surfaced in
      `probe`/`aaw_status`; the server never writes `.mcp.json` (MCP4-D3, MCP4-INV3).
- [ ] the `model` continuity and additive-shape tests pin the as-built field record-only; re-spawn
      without `model` keeps the stored value (MCP4-D4, MCP4-INV4).
- [ ] the boot banner ships (one line per listener + wire verdict + resolved absolute workspace);
      `probe` carries `started_at`, listeners, instance id, per-scope `reopened_at`,
      `effective_config`, `wire_contract` (MCP4-D5).
- [ ] the F-2 doc line (`.claude/commands/x.md:123` gains `ledger_dir`) lands under the standing
      Operator grant, or is held and reported — never silently dropped, never made without the grant
      (MCP4-D5).
- [ ] MCP4-INV1–INV4 are pinned by running tests: a two-instance family-split refusal test (INV1); a
      config-read-through test — edit applies, no env honored (INV2); a wire-verdict matrix
      agree/mismatch/absent/unparseable/skipped (INV3); a `model` additive/continuity test (INV4).
- [ ] the tool surface is 18; a deferred-schema client holding MCP3 shapes stays valid; `aaw selftest`
      is green and the live scopes still parse and append — demoable.

Stories: ./mcp4.stories.md · Agent brief: ./mcp4.llms.md · Index: ./mcp.md · Roadmap: ../aaw.mcp.roadmap.md · Approach: ../../../elixir/specs/specs.approach.md
