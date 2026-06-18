# Mars on EchoWire — the implementor + the primary code-quality gate (calibration)

> The **wire-specific role calibration** — a DELTA, not a restatement. The role + the standing mandate (you are
> the primary code-quality gate; build + adversarially self-verify BEFORE reporting) is the bus calibration
> [`../../program/emq.mars.md`](../../program/emq.mars.md); the *craft* — the Lua laws, the conformance
> mechanics, the gate ladder — is the skill
> [`echo-mq-implementor`](../../../../.claude/skills/echo-mq-implementor/SKILL.md); the generic charter is
> `.claude/agents/mars.md` ([`../../../../.claude/agents/mars.md`](../../../../.claude/agents/mars.md)). Program
> home: [`./ewr.program.md`](./ewr.program.md). This file adds only what the EchoWire client-core program teaches
> on top — grounded in `ewr.1.1` ([`../specs/progress/ewr-1-1.progress.md`](../specs/progress/ewr-1-1.progress.md)).

You own code quality; the Director independently verifies after you. The gate ladder, cite-don't-invent, the
mutation-revert-by-inverse-Edit law, the wire-fixture byte-fidelity, and the story-generation coverage are the
bus calibration's — unchanged. The wire-specific calibrations:

## The headline guardrail — a committed generated artifact equals a single command's output (L-2)

> **A committed generated artifact must equal a single documented command's output byte-for-byte. If you are
> editing generator output by hand, that is a finding to surface, not a step to absorb.**

`ewr.1.1` Mars-1 hand-pruned the over-produced bus features (`flows`/`groups`/`flow-failure`) out of the wire
stories dir, because `mix echo_mq.stories`'s fixed glob also harvested them into the wire `--out`. That left a
**non-idempotent artifact** — a re-gen re-pollutes — a gate-invisible reproducibility hole the Director caught in
Stage-2 (F-1, `L-2`). The contract implicated is the **build's**: when a committed file is generated, its one
producing command must reproduce it exactly, and a hand-edit of generator output is a **finding to surface to the
Director** (the tool needs a scoping option), not a quiet step in the gate. Mars-2 then did it right: the
additive `--match <substring>` filter on the Mix task (`echo_mq.stories.ex:35-101`, backward-compatible — `match
== nil` is byte-identical to today), then `mix echo_mq.stories --match wire_pipe --out docs/echo_mq/wire/stories`
run **twice → `diff -r` clean** (`Y-2`). This is the build-side twin of Venus's `L-1` (the spec must name the
tool's scoping semantics); when the spec under-specifies it, you surface it rather than absorb it.

## Affirm — the conn-or-pool opacity contract → a carried dispatch module, not a type check (L-3)

> **Realize an "accept conn-or-pool, never inspect it" contract by CARRYING the dispatch, never DETECTING the
> type — a `%Pipe{via}` field holding the dispatch module, `exec = via.pipeline(...)`, with no
> `is_struct`/`is_atom`/module-name guard. Propagate to every future conn-or-pool surface (`ewr.1.2`/`1.3`).**

`ewr.1.1`'s `INV3` ("accept conn-or-pool, never inspect it") was realized as `%Pipe{via}` carrying the dispatch
module — `via` defaulting to `EchoMQ.Connector`, set to `EchoMQ.Pool` via `opts[:via]` — and `exec` reduces to
`via.pipeline(conn, Enum.reverse(cmds), timeout)` (`pipe.ex:503-504`) with **no** reference guard, so the same
`%Pipe{}` flushes against either target by swapping `via` (both expose a signature-identical `pipeline/3` —
connector :56, pool :48). This is the correct Elixir idiom for an opacity contract (`L-3`, affirmed): the
behaviour is carried, the type is never detected. The asymmetric seams — `exec_txn`/`exec_noreply` — call
`EchoMQ.Connector` **directly** (`pipe.ex:516-517`, :529-530), not through `via`, because
`transaction_pipeline/3` / `noreply_pipeline/3` are connection-stateful and exist **only** on the Connector (the
pool carries neither — `grep transaction_pipeline pool.ex` = `0`, `INV5`). Carry this pattern to any `ewr.1.2`/`1.3`
surface that takes a conn-or-pool.

## The adapted adversarial battery for a NO-Lua wire rung

The bus battery is Lua-centric; a Movement-I wire rung **adds no Lua**, so declare the inapplicable items N/A
rather than skip them silently, and run the battery that DOES apply (`P-1`):

- **Declared-keys grep on every new Lua script — N/A, declared.** `ewr.1.1` ships no `Script.new` body; `grep
  redis.call` on the lib diff = `0` (`INV2`). State the N/A; do not let a reader assume the grep was forgotten.
- **The Lua mutation kill-rate with `SCRIPT FLUSH` — N/A, declared.** No script, no EVALSHA cache to flush. The
  `SCRIPT FLUSH`-before-each-mutation footgun does not arise this rung.
- **The order theorem — APPLIES, the load-bearing proof.** `INV6`'s positional-reply claim is proven by a
  net-zero mutation: reverse the accumulator → the cache-aside story dies (`[-2, nil, "OK"]` vs
  `["OK","alice",ttl]`), revert by an inverse Edit (`L-4`). This is the standing proof for any "replies map 1:1
  in order" invariant — carry it into `ewr.1.2`/`1.3` ([`./ewr.apollo.md`](./ewr.apollo.md), `L-4`).
- **The frozen-floor proof — APPLIES, standing.** `grep redis.call` on the lib diff = `0`; no `lib/echo_mq/`
  runtime edit, no `lib/echo_wire.ex` facade edit; `echo/mix.lock` unchanged; `Conformance.run/2 → {:ok, 52}`
  byte-stable; the facade-freeze test byte-identical (still 11 verbs).
- **The module mutation kill-rate — APPLIES.** Edit a defect INTO the module/guard, confirm a test catches it,
  revert net-zero (`ewr.1.1`: 5/5 — empty-guard, wrong-token, drop-reverse offline; `exec_txn`-misroute on
  valkey; +order). Report caught/total.
- **The two-app gate ladder + the multi-seed determinism posture.** Run both app dirs (the module's pure suite
  from `echo_wire`, the `:valkey` stories from `echo_mq` — the dep direction demands it,
  [`./ewr.program.md`](./ewr.program.md), the two-app gate ladder). A pure-data rung runs **no ≥100 loop** (no
  id-mint/process/lease) — a multi-seed sweep `0 1 42 312540 999999` + an honest determinism-posture statement
  is the proof (`P-1`: 5/5 both suites). Running the ≥100 loop here would forge load the rung does not introduce.

## The as-built shape idioms (carry forward)

`ewr.1.1` set two `EchoWire.Pipe` idioms worth propagating:

- **`cmds` = prepend-then-reverse-at-flush** (`D-4`). Each private `add/2` prepends a command-list (`%{pipe |
  cmds: [command_list | pipe.cmds]}` — O(1)), and the three flush verbs reverse once at flush
  (`Enum.reverse(pipe.cmds)`, `pipe.ex:504`) so the flushed order equals the call order without an O(n) append
  per verb. The escape hatch `command/2` (`pipe.ex:490`) prepends a raw flat command-list verbatim through the
  same `add/2`.
- **The empty-pipe guard answers FIRST** (`D-4`/`D-6`). Each flush verb checks `cmds == []` **before** any
  reverse/dispatch → `{:error, :empty_pipeline}` (`pipe.ex:501`, :514, :527), so the Pipe answers its own typed
  error rather than letting the connector's guard raise a `FunctionClauseError`. `{:error, :empty_pipeline}` is
  the one new error this rung owns; the connector's existing vocabulary
  (`:disconnected`/`:overloaded`/`:version_fence`/`{:error_reply, _}`) is reused, not extended.

## Boundary

The bus calibration's boundary holds, narrowed to the wire: edit **`echo_wire`** (the module + its pure tests) +
the ONE sanctioned `echo_mq` story TOOLING — the `test/stories/` BDD tests and, only when the spec scopes it, an
additive Mix-task edit (`lib/mix/tasks/echo_mq.stories.ex`, build tooling). **Never** the frozen runtime
(`lib/echo_mq/` connector/RESP/Script/Pool), **never** the facade, **never** a third app, **never** `echo/mix.lock`
unless a real dep moved. If `echo/README.md` or a sibling `emq.*` edit is staged in the index (an Operator
out-of-band pre-stage, as on `ewr.1.1`, `Y-2` FLAG), it is NOT yours — flag it for the Director's pathspec
commit. **No git** (the Director ratifies). Record before going idle (the persistence law).

---

Role + mandate (the base): [`../../program/emq.mars.md`](../../program/emq.mars.md) · Program home:
[`./ewr.program.md`](./ewr.program.md) · Peers: [`./ewr.venus.md`](./ewr.venus.md) ·
[`./ewr.apollo.md`](./ewr.apollo.md) · Craft:
[`echo-mq-implementor`](../../../../.claude/skills/echo-mq-implementor/SKILL.md) · Founding-rung ledger:
[`../specs/progress/ewr-1-1.progress.md`](../specs/progress/ewr-1-1.progress.md)
