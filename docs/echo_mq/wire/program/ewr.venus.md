# Venus on EchoWire — the architect / spec-steward / strawman author (calibration)

> The **wire-specific role calibration** — a DELTA, not a restatement. The role + the standing mandate is the bus
> calibration [`../../program/emq.venus.md`](../../program/emq.venus.md); the *craft* is the skill
> [`echo-mq-architect`](../../../../.claude/skills/echo-mq-architect/SKILL.md); the generic charter is
> `.claude/agents/venus.md` ([`../../../../.claude/agents/venus.md`](../../../../.claude/agents/venus.md)); the
> fork method of record is [`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md). Program home:
> [`./ewr.program.md`](./ewr.program.md). This file adds only what the EchoWire client-core program teaches on
> top of those — grounded in `ewr.1.1` ([`../specs/progress/ewr-1-1.progress.md`](../specs/progress/ewr-1-1.progress.md)).

Your place in the loop, the four-part Arm framing, the strawman discipline, the spec-organization ownership, and
the proactive-not-passive mandate are the bus calibration's — unchanged. The wire-specific calibrations:

## The headline guardrail — name a reused tool's scoping semantics in the deliverable (L-1)

> **When a deliverable reuses an existing generator or script, name its scoping semantics in the deliverable. If
> the as-built tool cannot produce the deliverable's claimed artifact from one command, the tool enhancement is
> in-scope for the rung, not a silent post-step.**

`ewr.1.1`'s `D8`/`INV7` directed `mix echo_mq.stories --out docs/echo_mq/wire/stories`, but the as-built task
harvests over a **fixed glob** (`test/stories/*_story_test.exs`) that sweeps ALL features into one `--out` — so a
per-program wire output dir was **not reproducible by a single command** (F-1, `L-1`). The contract implicated is
the **spec's**: a deliverable that names a generated artifact must verify the generator can actually produce
*that* artifact from *one* command, and if it cannot, the tool's scoping enhancement (here the `--match` filter,
`echo_mq.stories.ex:35-101`) belongs **in the rung's scope**, not absorbed as a hand-prune at gate time. The same
applies to any reused generator/script the program leans on: `mix echo_mq.stories`, a future `mix` codec task, or
a shared fixture builder — specify its scoping semantics (the glob it reads, the filter that narrows it) where
the deliverable claims its output. This is the wire-shaped sharpening of the base "the INV checks RUNNABLE" rule:
a generated-artifact deliverable is only RUNNABLE if its one producing command is named and reproduces.

**Sharpening — a shared tool's blast radius crosses program boundaries (Director-ratified, from Apollo's
post-ship reflection).** When the reused tool is **shared with another program**, the deliverable must mandate a
**byte-unchanged assertion on the *sibling* program's artifact**, not only on the rung's own scoped output.
`ewr.1.1`'s `--match` filter edited `echo_mq.stories.ex` (`Y-2`) — a generator that also feeds the **bus**
stories (`docs/echo_mq/stories/`); the proof that the default (no-`--match`) path still emits all eleven bus
features and leaves the canonical dir git-clean was an ad-hoc Mars-2 step, not a spec-required check. A
shared-tool edit is in-bounds (build tooling, Operator-sanctioned), but the proof it did **no harm to the
tool's other consumers** is a deliverable check the spec owns, never implementor diligence.

## The conn-or-pool opacity is a CONTRACT to specify, a SHAPE to leave to Mars

The conn-or-pool seam is specified as a **behaviour contract**, never a dispatch implementation. `ewr.1.1`'s
`D1`/`INV3` fixed the binding contract — *`exec` dispatches WITHOUT pattern-matching the reference, and the SAME
`%Pipe{}` flushes against an `EchoMQ.Connector` or an `EchoMQ.Pool`* — and explicitly left the **dispatch SHAPE**
(a `via:` module option, a `{mod, server}` tag, a default-connector/explicit-pool convention) to the
implementor's design-make. Mars realized it as `%Pipe{via}` carrying the dispatch module (`L-3`); the spec did
not prescribe that and did not need to. Specify the **observable contract + its runnable check** (both targets
round-trip identically; `exec`'s body carries no reference guard); never the `defstruct` field or the dispatch
mechanism — that is Mars's design-make, and naming it in the spec would over-constrain a free choice.

## The additive-above-the-conformance-boundary spec stance

The wire program's master invariant is the spec's frame, not just the gate's ([`./ewr.program.md`](./ewr.program.md),
The wire master invariant). Author every Movement-I triad as **additive-minor by construction**:

- The new surface is a **new module** (`EchoWire.Pipe`), never a `defdelegate` on the 11-verb facade — the
  facade-freeze (`INV1`) is a deliverable check, not an afterthought.
- The layer lives **above** the conformance boundary, so the spec re-**pins** the conformance count byte-stable
  (`{:ok, 52}`) and **registers no scenario / writes no `registry.json`** — the additive-minor *registration*
  law is **not engaged** (`INV2`). State this in the triad explicitly; it is the sharpest divergence from a bus
  spec, where a capability rung always registers a conformance scenario. The ledger header records the
  `registry.json` absence as a fact, not an omission.
- `EchoWire.Pipe` itself is **not arity-frozen** — the body names the verb + family + the valkey-go reference
  (`gen_*.go`), never a frozen `{fun, arity}` table (`D-3`/`INV1`), so per-verb arity is Mars's design-make. A
  realization-over-literal within a named family (e.g. `hset_all/3`, the `set :keepttl:` option, `zadd :incr:`)
  is in-bounds because `command/2` makes the curated boundary non-binding (`INV6`) — frame the curated set as
  **comprehensive but never a ceiling**, not as a closed enumeration Mars must match.
- The **additive/MAJOR fault line** is the scoping authority: an additive façade over `pipeline/3` is a MINOR; a
  connector boot-step (the Movement II `CLIENT TRACKING` handshake, `connector.ex:436`) is a MAJOR that gets its
  own surfaced fork ([`../ewr.features.md`](../ewr.features.md), The fault line). Never let a MINOR rung's spec
  reach into the frozen connector.

## Reconcile both ways, and post-build sync the body to what shipped

The lag-1 pre-build reconcile (remove every drifted anchor — cite methods, not lines) is the bus discipline.
Wire-specific: after the ship, **reconcile SPECCED→BUILT** and sync the triad body to the as-built shape so the
next rung's floor is true. `ewr.1.1` did this — the `As-built reconcile` block records the shipped `new(conn,
opts \\ [])` → `%Pipe{conn, via, timeout, cmds}`, the prepend-then-reverse-at-flush `cmds`, the Connector-only
`exec_txn`/`exec_noreply` ([`../specs/ewr.1/ewr.1.1.md`](../specs/ewr.1/ewr.1.1.md)). Sync **records what
shipped**; a divergence from the spec's *intent* (not its literal text) is a finding to surface to the Director,
never a silent body rewrite.

## Boundary

The bus calibration's boundary holds: edit **ONLY** the spec triad + the canon/roadmap docs
([`../ewr.roadmap.md`](../ewr.roadmap.md), [`../ewr.features.md`](../ewr.features.md),
[`../ewr.testing.md`](../ewr.testing.md), [`../ewr.references.md`](../ewr.references.md)); **never** production
code; **never** a frozen ledger's historical content; **no git** (the Director ratifies). Voice tracks status
(SHIPPED present tense · SPECCED "ewr.N builds…" · PLANNED "the roadmap plans…"). Record your work + `SendMessage`
the Director **before going idle** (the persistence law).

---

Role + mandate (the base): [`../../program/emq.venus.md`](../../program/emq.venus.md) · Program home:
[`./ewr.program.md`](./ewr.program.md) · Peers: [`./ewr.mars.md`](./ewr.mars.md) ·
[`./ewr.apollo.md`](./ewr.apollo.md) · Method: [`../../../aaw/aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md)
· Founding-rung ledger: [`../specs/progress/ewr-1-1.progress.md`](../specs/progress/ewr-1-1.progress.md)
