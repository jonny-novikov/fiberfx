# BCS · Appendix B specs — The EchoMQ connector specification

<show-structure depth="2"/>

This is the normative companion to [Appendix B](bcsB.md): what the connector *must* do, stated as invariants with their evidence; the rung ladder that certifies the current implementation; the conformance set a port must clear; and the development ladder ahead, each step with its acceptance shape and none with code. The spec is versioned with the wire: it describes the component behind `echomq:2.0.0`, and a breaking change to any invariant below rides a wire-version bump through the fence — the amendment mechanism is the component's own.

## Identity and scope

The unit under specification is `EchoMQ.Connector` with its codec `EchoMQ.RESP`, its script carrier `EchoMQ.Script`, and its dispatcher `EchoMQ.Pool`, at `runtimes/elixir/lib/echo_mq/`. In scope: connection lifecycle, protocol negotiation, the reply discipline, script execution, flow control, failure semantics, and observability. Out of scope: queue semantics (`EchoMQ.Jobs`, specified by Part III's chapters), key grammar (`EchoMQ.Keyspace`, Chapter 3.1's law), and cluster topology (the F1 rung below).

## The 5W, normative

**Why.** Every byte EchoMQ moves crosses this component; its correctness budget is therefore the system's. The connector exists so that the layers above may assume an ordered, fenced, bounded, observable wire and spend their own complexity elsewhere.

**What.** A pipelined RESP client: commands encode as arrays of bulk strings; replies route in order off a pending FIFO; scripts execute EVALSHA-first; the version fence precedes the first useful command; flow is bounded; failures are typed values, never silent retries.

**Who.** `EchoMQ.Jobs` and every future bundle above it; supervisors, which may start, stop, and restart it freely under the guarantees below; operators, who read `stats/1` and `CLIENT LIST`; and ports in other runtimes, which inherit the conformance set rather than the source.

**When.** One connector per blocking consumer (the lane law), pools for shared request traffic, explicit `protocol:` only when a deployment demands it, and the fence always — there is no unfenced mode.

**Where.** Single Valkey instance by Part III's stated topology; the slot function and the co-location grammar keep every shape cluster-legal in advance, and F1 is the promotion path.

## Invariants

**INV-C1 — The fence precedes use.** No application command is accepted before `{emq}:version` is claimed or verified as `echomq:2.0.0`; a mismatch is a typed, fatal `{:version_fence, got}` at boot and at every reconnect. Evidence: legacy C1 (`{:version_fence, bogus:9.9.9}`), re-fence in the death drill (P6).

**INV-C2 — Replies are FIFO; pushes are not replies.** Pipeline replies route to callers strictly in submission order; push frames never consume a pending slot, on a busy wire or a quiet one. Evidence: C5 (`10000-command pipeline returned 1..10000 in order`), R3 (`the FIFO never saw it, five PONGs came back aligned`).

**INV-C3 — One load per script per connection.** Script execution is EVALSHA-first with at most one `SCRIPT LOAD` on NOSCRIPT, SHA-asserted. Evidence: C4 (`script_loads=1`).

**INV-C4 — Fail, never replay.** On socket loss every in-flight caller receives `{:error, :disconnected}` and no command is ever retransmitted by the connector. Evidence: design (the `down/1` path) plus the death drill's adjacency; the explicit in-flight-delivery gate is rung F4 below, and until it lands this invariant is marked *design-asserted, drill-adjacent* — the spec keeps the asterisk visible.

**INV-C5 — Bounded in flight.** The pending depth never exceeds `max_pending`; the excess caller receives `{:error, :overloaded}` immediately. Evidence: P4 (`31 callers queued and served, 69 refused :overloaded`).

**INV-C6 — A timed-out caller cannot misalign the wire.** Abandoned calls leave their pending entry to consume its reply; subsequent callers receive their own. Evidence: P5 (`the late reply lands nowhere, the next five PINGs answer PONG in order`).

**INV-C7 — The boot ladder is ordered and typed.** Authentication (HELLO-folded or `AUTH`), then `SELECT`, then `CLIENT SETNAME`, then the fence; each refusal is typed (`{:auth_refused, _}`, `{:boot_refused, step, _}`) and fatal. Evidence: P8 (`CLIENT INFO shows db=2, GETNAME answers emq-prod`), R5 (one round trip on a protected server).

**INV-C8 — Liveness is probed, not assumed.** A quiet connected wire is PINGed every `heartbeat_ms` (when positive), so a dead peer is discovered within one beat plus TCP's own notice. Evidence: P6 (`the heartbeat noticed in 0 ms, backoff reconnected in 153 ms`).

**INV-C9 — Shutdown answers everyone.** `terminate/2` replies `{:error, :closed}` to every waiter before the socket closes. Evidence: P7.

**INV-C10 — Protocol is negotiated and reported.** `:auto` attempts HELLO 3 and falls back to the RESP2 ladder; explicit `3` is strict, explicit `2` skips; `stats.protocol` states the live generation. Evidence: R1, R4, R5.

**INV-C11 — The push contract.** Out-of-band frames are delivered as `{:emq_push, payload}` to `push_to` when set, counted always, dropped silently never miscounted. Evidence: R3 (`the push counter holds the receipt`).

**INV-C12 — Zero dependencies.** The component compiles against the standard library and the identity canon alone; `:telemetry` is dispatched only through `function_exported` and its absence costs nothing. Evidence: the compile lane and the dependency-free repo it lives in.

**INV-C13 — Stats tell the truth.** Counters are monotonic per connection lifetime; `status` reflects the socket; `pending`, `overloads`, and `pushes` are exact. Evidence: P1, P3 (`pipelines 80/81/81/80`), P6 (`reconnects=1`).

**INV-C14 — Blocking verbs get their own lane.** No blocking command is issued through a pooled member; parked consumers own dedicated connectors. Evidence: P2's isolation measurement (`one connection answers PING in 290 ms, the pool in 0 ms`); enforcement is convention here and a candidate guard in F2.

## The certified ladder

Three rungs stand, each frozen the day it ran: the appendix rung (`emq_connector_check.exs`, `PASS 8/8` — codec, fence, keys, slots, one-load, ordering, throughput, restart), the production rung (`emq_connector_prod_check.exs`, `PASS 9/9` — re-certification, surfaces, fan-out and isolation, spread, bounds, alignment, death, shutdown, authenticated boot), and the protocol rung (`emq_connector_resp3_check.exs`, `PASS 7/7` — tower re-certification, negotiation, shapes by probe, the push law, fallback, folded auth, the untouched machine). The chaining is deliberate: each later rung re-runs its predecessors as its first gate, so the ladder certifies as a tower, not as siblings.

## Conformance for ports

A connector port in another runtime conforms when it clears, against a live engine: the fence's three behaviors (claim on fresh, verify on match, typed-fatal on mismatch); FIFO reply order across a 10,000-command pipeline; one load per script with SHA assertion; the overload refusal at its declared bound; the push law if it speaks RESP3 (out of band, counted); and the boot ladder's order with typed refusals. The Lua bundle needs no port — same bytes, same SHA, same semantics — which is why this set is about the wire, not the scripts.

## Future development — the F ladder

**F1 — Cluster redirects** (the clustered day). `MOVED`/`ASK` handling, slot-table maintenance, and promotion of `Keyspace.slot/1` from arithmetic to routing. Acceptance: a three-node drill with a slot migration mid-pipeline and zero misrouted replies; the co-location grammar means application scripts need no edits. Priority: when topology changes, not before.

**F2 — Health-aware pool routing.** Members in `:reconnecting` are skipped by dispatch; optionally, the pool refuses blocking verbs to enforce INV-C14 by mechanism instead of convention. Acceptance: kill one member's process under load; zero caller errors attributable to routing; spread recovers on member return.

**F3 — Pool resize.** Runtime grow and shrink under the supervisor with an atomic size swap. Acceptance: resize under sustained load with zero lost or double-routed callers.

**F4 — The disconnect-delivery gate.** Closes INV-C4's evidence: an in-flight pipeline against a peer killed mid-reply receives `{:error, :disconnected}`, asserted explicitly. Acceptance: the drill plus the assertion; the invariant's marker upgrades from design-asserted to gated. Priority: first of the ladder — it is one gate and it retires a spec asterisk.

**F5 — The Functions evaluation.** Valkey Functions offer server-persisted, named, versioned logic against EVAL's volatile cache; the rung evaluates `FCALL` against the bundle's EVALSHA discipline — cache-loss behavior, replication, versioning against the fence — and produces a decision, not a migration. Acceptance: a comparison record and a recorded decision either way.

**F6 — Client-side caching integration.** Formalize the `{:emq_push, ["invalidate", keys]}` contract into an invalidation hook for an L1 cache above the connector — the tracking drill of R3 grown into a consumer protocol. Acceptance: a cache layer observing invalidation within one push of the write, gated end to end.

**F7 — TLS transport.** An `:ssl` lane behind a transport option, fence and ladder unchanged above it. Acceptance: the boot ladder and a pipeline gate over TLS against a certificate-bearing instance.

**F8 — The live fallback drill.** `:auto`'s downgrade is currently exercised by construction (HELLO exists on every 8.x engine); this rung runs it against a HELLO-refusing peer. Acceptance: negotiation lands on protocol 2 with the RESP2 ladder completing and the fence holding.

Each F-rung waits for its own review gate; none rides another's diff. The ladder's order above is priority order: F4 first because it is cheap and closes an asterisk, F1 only when the topology demands it.

## Amendment lane

This specification amends the way the contract does: invariant changes that any conforming port could observe are breaking, and breaking changes ride a wire-version bump — the fence turns the deployment over in one move, exactly as designed. Additive invariants and new F-rungs amend in place with their evidence attached.

