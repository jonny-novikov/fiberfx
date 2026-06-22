# EchoMQ 3.0 — The Stream Tier (emq3.3 → emq3.6) · Director synthesis of the two-architect debate

> **The Director's job here is to STAGE the disagreement, not average it**
> ([`aaw.architect-approach.md`](../../../aaw/aaw.architect-approach.md) §The multi-architect debate). Two
> architects designed the same forks across emq3.3–emq3.6 from divergent lenses — **Lens A** (consumer /
> operability, [`streams.design.A-consumer-lens.md`](./streams.design.A-consumer-lens.md)) and **Lens B**
> (spec-steward / invariants, [`streams.design.B-steward-lens.md`](./streams.design.B-steward-lens.md)) —
> independently, neither reading the other. This doc consolidates the result for **independent Operator
> review**. The three judgments stay separate: *the architects argued, the Director synthesizes, the Operator
> rules.* No fork below is decided.

---

## §0 · The result in one line

**Nine of ten open forks CONVERGED** — the two opposite-optimizing lenses reached the *same* arm independently,
each for its own reason. **One fork DIVERGED** — F3.4-A, the retention-trim cadence, on a genuine
safety-vs-coupling axis. The convergence includes the **highest-stakes cross-engine fork** (F3.5-A, the archive
fold into the native `EchoStore.Graft` engine), which is the strongest single signal the debate produced.

**Consequence for the build:** every **emq3.3** fork converged, so **emq3.3 is fully ruled and build-ready
now**. The single divergence (F3.4-A) is an **emq3.4** decision that emq3.3's freeze deliberately does not
foreclose — it can be ruled at emq3.4's threshold without blocking the near-term build.

---

## §1 · Cross-lens fork ledger (the diff)

| Fork | Lens A (consumer) | Lens B (steward) | Verdict | Synthesis note |
|---|---|---|---|---|
| **F3.3-A** XGROUP lifecycle | A1 lazy ensure-on-start (`:group_start` declared) | A1 lazy ensure-on-start (BUSYGROUP-only swallow; no destructive `group_destroy`) | **CONVERGED** | Lazy ensure; declare the start position as an explicit `start_link` option; swallow ONLY `BUSYGROUP` (a `WRONGTYPE` is loud); defer any destructive `group_destroy` to the retention/archive family. Zero new frozen public verb. |
| **F3.3-B** restart read + handler | B1 PEL-first + handler-identical | B-i-1 drain-PEL-first + B-ii-1 exact mirror | **CONVERGED** | Drain own PEL (`XREADGROUP … 0`) first, then `>`; handler is the job `Consumer`'s `%{id, payload, attempts, group}` → `:ok` \| `{:error, reason}` EXACTLY. **Both lenses independently required** the `attempts` ↔ `XPENDING` delivery-count mapping be a **NAMED invariant**, not assumed. |
| **F3.3-C** conformance grain | C1 +1 capability | C1 +1 capability | **CONVERGED** | One `stream_group` scenario; the deep proofs (crash→reclaim, PEL-drain, parity) ride property/loop tests. **Both** add the guard: the one scenario must POSITIVELY prove re-delivery (an un-acked entry actually re-handed), never a no-op. Re-probe the live count at reconcile. |
| **F3.4-A** WHERE the trim lives | **A3 consumer-beat** (primary) + A2 verb as its public face | **A2 dedicated `trim/_` surface** driven by a separate/named cadence | **DIVERGED** | The one live fork — see §3. Reconcilable core: **both** want a dedicated public `trim/_` verb + a declared policy; they differ on the **default cadence** that drives it. |
| **F3.4-B** policy declaration | B1 registered per-stream (keyspace key, cleanup named) | B2 registered map, or B3 keyspace key if polyglot-visible | **CONVERGED** | A per-stream **declared** policy (not a per-call default); `MAXLEN ~` approx default, exact opt-in; `MINID` by mint-instant via `Snowflake.min_for/1`. Open sub-call: ETS map vs keyspace key — turns on whether a **polyglot reader must SEE** the policy (the subkey's cleanup must be named either way). |
| **F3.5-A** fold mechanism | A1 dedicated fold-consumer | A1 dedicated fold-consumer over `commit/3` | **CONVERGED** (highest stakes) | A dedicated `StreamConsumer` in fold mode commits each trimmed slice to the native engine via its PUBLIC `EchoStore.Graft.VolumeServer.commit/3` — **COEXIST honored literally, no engine edit**. **fold-before-trim** ordering makes a crash re-archive (idempotent), never trim un-archived data. |
| **F3.5-B** merge watermark | B1 scalar watermark from Graft frontier | scalar `W` from the engine's committed extent | **CONVERGED** | Deep read = segments below `W` (Graft) ++ live tail at/above `W` (stream); `W` is a branded id **derived from the archive's own folded frontier** (no drift-prone side index, no new subkey). No-gap/no-overlap is a *consequence* of fold-before-trim + the order theorem. |
| **F3.6-A** time-travel surface | A1 `read_since`/`read_between` DateTime | A1 `read_since`/`read_between` | **CONVERGED** | DateTime-bounded reads mapping to `XRANGE` bounds via the shipped `Snowflake.min_for/1`; **half-open `[dt1, dt2)`** convention fixed; per-stream (per-namespace); sub-ms ties break by the full branded id. Correctness is a corollary of emq3.2's real-Unix-ms id. |
| **F3.6-B** Table hydration | B1 latest-per-key tail → `Table.put/4` | B1 bus-side changelog → Table public surface | **CONVERGED** | A bus-side latest-per-key reduction over the stream tail (newer-id-wins = the staleness fence's law) writes the branded id as the 14-byte version into the Table's PUBLIC `put/4`/`apply_batch/2`; bounded to **hydrate-from-the-watermark-forward**; gated by **hydrate-then-fence == loader truth**. |

---

## §2 · The convergences — the build-ready decision set

Because the two opposite-optimizing lenses agree, these carry high confidence. Stated as the surface each rung
would freeze.

**emq3.3 (S2 the readers — BUILD-READY):**
- A new sibling `EchoMQ.StreamConsumer` (SETTLED), holding a private connector lane, reading `XREADGROUP GROUP … >`.
- **Group lifecycle:** lazy ensure-on-start (`XGROUP CREATE … MKSTREAM`, swallow only `BUSYGROUP`); the start
  position (`$` new-only vs `0` replay) is a **declared `start_link` option**, never a default. No destructive verb.
- **Recovery:** drain-own-PEL-first (`… 0`) then `>`, complementary to the SETTLED `XAUTOCLAIM`-on-beat reclaim
  (PEL-drain recovers SELF on restart; the beat recovers PEERS that never restart).
- **Handler:** the exact `%{id, payload, attempts, group}` → `:ok` \| `{:error, reason}` mirror, with the
  `attempts` ↔ `XPENDING` delivery-count mapping written as a NAMED invariant.
- **Conformance:** +1 `stream_group` scenario that positively proves re-delivery; deep proofs ride property/loop.
- **Polyglot:** the raw-connector parity test (SETTLED) proving the stored `id` field is the canonical receipt.

**emq3.4 (retention as policy):**
- A dedicated public `EchoMQ.Stream.trim/_` verb over `XTRIM` (both lenses) + a **declared per-stream policy**
  (approx `MAXLEN ~` default, mint-instant `MINID`). **Open: the default cadence — see §3.**

**emq3.5 (the archive — COEXIST):**
- A dedicated fold `StreamConsumer` committing trimmed slices to the native engine's public `commit/3`
  (UNTOUCHED engine), **fold-before-trim** for crash safety.
- The merge-read cut is a single branded-id watermark `W` derived from Graft's folded frontier.

**emq3.6 (time-travel + hydration):**
- `read_since`/`read_between` DateTime reads over `Snowflake.min_for/1`, half-open, per-stream.
- Table hydration via latest-per-key over the tail into the Table's public surface, watermark-bounded,
  gated by hydrate-then-fence == loader truth.

---

## §3 · The one divergence (staged, not averaged) — F3.4-A: the retention-trim cadence

Both lenses **reject** trim-on-append as the default (it would mutate the frozen emq3.2 `append/4`). Both
**agree** emq3.4 ships a dedicated public `trim/_` verb + a declared policy. The divergence is narrowed to the
**default cadence that drives the trim**:

| | **Lens A — A3 consumer-beat drives the trim** | **Lens B — a separate/named cadence drives the trim** |
|---|---|---|
| **The arm** | The `StreamConsumer` (and the emq3.5 fold consumer) calls `trim/_` on its own beat when a policy is registered; `trim/_` is the public face of that beat. | `trim/_` is the frozen mechanism; the cadence is a separately-named decision (an opt-in `EchoMQ.Pump`-style child, or the consumer beat calling the public `trim/_`). |
| **Load-bearing reason** | **Fold safety** — folding and trimming in ONE beat makes the trim watermark == the fold watermark by construction, so the trim can never outrun the fold and drop un-archived data. | **Invariant cleanliness** — retention is a property of the STREAM, not of whether a consumer happens to run; coupling a SAFETY property (bounded memory) to a LIVENESS fact (a consumer is up) is the silent-no-op class the steward refuses. |
| **The cost it accepts** | A stream with no draining consumer never trims (Lens A parks trim-on-append as a declared opt-in for that case). | A fast crash-restart's own backlog and the un-consumed-stream case need the cadence wired explicitly, or memory grows. |
| **Pre-empts** | "Don't couple safety to liveness" → answers: the coupling IS the fold-safety; the un-consumed case is a named opt-in. | "A verb nobody calls doesn't bound memory" → answers: A2 separates *how* to trim (frozen, tested once) from *when* (a named operational policy). |

**Why it does not block emq3.3:** the forward-compatibility thread (both docs §5/§forward) shows emq3.3 freezes
**no** retention behavior — retention stays a clean additive surface whichever cadence wins. So F3.4-A is an
**emq3.4-threshold decision**, surfaced now, ruled later.

**Director's framing for the ruling (advice, not a decision):** the fold-safety Lens A invokes is genuinely an
**emq3.5 fold-consumer** property (the fold consumer trims after it folds) — which **both lenses already agree
on** under F3.5-A. That suggests a reconciliation the Operator may prefer: ship emq3.4's `trim/_` verb + policy
(converged), let **general retention cadence** be the named/opt-in decision (Lens B), and let the **emq3.5 fold
consumer specifically** do fold-before-trim on its own beat (converged at F3.5-A). That keeps general retention
un-coupled from consumer liveness AND keeps the archive's trim fold-safe — taking the load-bearing half of each
arm. **Surfaced for the Operator; not ruled here.**

---

## §4 · A consensus finding both lenses raised — name the PEL re-claim exception to the order theorem

Lens B's central catch, which Lens A's handler design implicitly honors: a consumer **group** adds a second
ordering axis the writer's order theorem never had — **per-consumer delivery order under re-claim** (the PEL).
The stream itself stays id-ordered (`XRANGE`/`XREADGROUP … >` still hand entries in mint order), but a
*re-claimed* entry returns to a consumer **out of real-time delivery order** — the honest cost of at-least-once.
**emq3.3's triad must NAME exactly where the order theorem continues to hold and where it cannot**, or a spec
asserting "order preserved" is a false-green. This is a Venus canon point for the emq3.3 build, endorsed by both
lenses.

---

## §5 · Consolidated recommended next actions (for Operator ratification)

1. **Build emq3.3 to the converged decision set (§2).** Every emq3.3 fork is ruled by the convergence. Risk is
   **HIGH** (a new supervised process + a blocking `XREADGROUP` surface + crash re-delivery) → **Apollo
   mandatory**, the **≥100 determinism loop** on the consumer suite, and the full mutation battery in the
   Director's verify. Label `echomq:2.6.2` (within-family patch); `@wire_version` frozen `echomq:2.4.2`;
   conformance +1 `stream_group` (additive-minor).
2. **Fold two named invariants into emq3.3's triad:** (a) the `attempts` ↔ delivery-count mapping (§1, F3.3-B);
   (b) the PEL re-claim exception to the order theorem (§4).
3. **Carry this KB forward as the emq3.4–3.6 design reference.** Rule **F3.4-A** (the trim cadence, §3) at
   emq3.4's pre-build threshold — emq3.3 forecloses nothing.

## §6 · What stays open (the Operator's, surfaced not decided)

- **F3.4-A** — the retention-trim cadence (§3), an emq3.4 decision.
- **F3.4-B sub-call** — the policy lives in an ETS map vs a keyspace key (turns on polyglot visibility).
- **The `echomq:3.0.0` cutover ratification** — deferred, declared when the tier is whole (the
  defer-the-fence-cutover pattern); never auto-claimed by a rung.
- The parked tier seams (object payloads on streams, the log-tier exit, exactly-once) — carried unchanged from
  [`emq.streams.md`](../../emq.streams.md) §Seams.

---

*Director synthesis. The architects argued (Lens A, Lens B); this doc staged the agreement and the one
disagreement; the Operator rules. Convergence is confidence; the single divergence is the signal.*
