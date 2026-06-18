# EchoMQ 2.0 — the design (the single source of truth)

> Rung numbers in this file name the pre-program ladder; read them through the old→new bridge in
> [`./emq.roadmap.md`](./emq.roadmap.md). Artifacts marked "deleted with the old spec home" remain
> recoverable from git history.

## 0 · Genesis — why EchoMQ was born

EchoMQ began as a protocol with **proven requirements**: the Branded Component System's Part III derives the same keyspace
discipline from first principles and gates it against Valkey 9.1.0 with a committed reference implementation —
the braced co-location grammar, the gated branded job position, the deployment-scoped version fence, the
fenced state machine. BCS D-1 names the framing that settled a mid-flight detour: the v2 protocol's
load-bearing properties "were never engine folklore but cluster-and-scripting discipline." What 2.0 is FOR,
stated once: **owning the wire** (break once, then additive minors under written change rules); **the BCS law**
(identities as the only cargo; the job position is gated identity, fourteen bytes whose byte order is mint
order); **the gated protocol** (conformance is a parse; refusals are typed; the engine story is enforced, not
narrated); and **the Valkey 8+ substrate** (one stated engine line, measured where claimed — the new hash table
puts the branded form on the cheapest printable step, `bcs.id-system.md`; scripting, replication-by-effects,
and the cluster grammar are the disciplines the protocol rides).

## 1 · The supersession set — the lock history, complete

The locked decisions, every chain explicit. "Locked" names exactly these (the C-2 lock-hygiene rule:
everything else is a design ground, cited to its section or ledger entry, revisitable only through the
Operator, never cited as Operator-locked).

### S-1 — Keyspace canon = braced `emq:{q}:`, per bcs3.1

**The chain.** The founding runbook locked the braced form. A mid-build Operator revision unbraced it (the
prior phase's D-18/D-19/D-20) while retiring the second-engine row entirely. The **Branded Component System
Part III** then re-derived the braced grammar from first principles and rung-gated it (bcs3.1 §What-F5: the
co-location law — every key of one queue answers one slot, by grammar; the hash-tag mechanism per
valkey.io/topics/cluster-spec), and the Operator's 2026-06-11 ruling **restored the braced canon as LOCKED**:
per-queue `emq:{q}:<type>` (closed registry), per-job `emq:{q}:job:<branded-id>` (registered subkeys as
`job:<id>:<sub>`), dedup `emq:{q}:de:<dedupId>`, and the deployment reserve `{emq}:` (`{emq}:version`,
`{emq}:locks`, `{emq}:bundle`, `{emq}:migration:<q>`). The unbraced revisions are SUPERSEDED in their grammar
clauses. What survives of them: the v1-detection-breadth ruling (the fence probes what v1 deployments WROTE —
unbraced and braced twins both); the matrix call (Valkey the sole standing row); the lock-status convention.
What regrades: the cluster-posture clause. The deployment posture stays the standalone engine at 2.0
(bcs3.md: single-instance is the part's stated topology; the slot function committed and parked), but
single-slot legality of every per-queue script is again **structural, by grammar** — the clustered day needs
no wire break. The old "hashtag re-introduction is a 3.0" clause is moot, not violated: the v2 line has no
release, so the respelling precedes the first ship. The empty-segment reserve of the unbraced interlude
retires; the braced reserve is disjoint from every per-queue key **at the first byte** (`emq:{` vs `{emq}:`),
and the `emq`-rejected queue-name rule gains a sharper ground: no queue can share the reserve's hashtag. The
17-byte grammar budget binds (bcsA INV-K2: `emq:{` 5 + `orders` 6 + `}:` 2 + `job:` 4 = 17 before the 14-byte
payload).

### S-2 — Branded `JOB` ids at 2.0, per bcs3.1/bcs3.2

**The chain.** The founding phase resolved job identity to producer-minted integer Snowflakes with
config-assigned node ids (the B′ arm — §11.2), decimal strings on the wire, branding edge-only. The BCS
supersedes the **form**: bcs3.2 D-10 registers `JOB` ("work is a kind: minted, gated, browsed, audited"),
bcs3.1 §What-F2 places the wellformedness gate at the key builder ("a fourteen-byte decimal and a fourteen-byte
slug both raise before any wire is touched"), and the Operator's ruling makes it LOCKED. The Snowflake mint
machinery survives unchanged; the wire and key form is the fourteen-byte branded id. The full ADR is §2.

### S-3 — The break, the freeze, the fence (standing from the founding phase)

`meta.version`  → `echomq:2.0.0` behind the two-way typed boot fence;
an explicit migration path; **the fork happens exactly once, at emq.1**. After it, additive registration rides
protocol minors; a wire break or computed-floor raise is a major.

### S-4 — Valkey is a GATE, not prose

One stated engine line — **Valkey 8+, current stable** (the line tracked, never version-pinned in prose; matrix
rows pin exact versions per run; the BCS records measured 8.1.x) — enforced two ways: Given-When-Then
acceptance criteria across the spec corpus (§7; carried by the `./specs/emq.N.stories.md` triads — `emq.0`
and `emq.1` authored; the pre-move carriers were deleted with the old spec home) and the
engine-hygiene machine gate in the conformance suite (§8). Honest-row reporting stands: a host without Valkey
runs the probes on plain Redis and reports them as that row, never as the truth row.

### S-5 — Eradication to ZERO, repo-wide

The superseded second-engine target's name (any case), era tag, brand-domain suffix, URL env gate, and Lua flag
header appear NOWHERE in tracked files. The rewording rule where decision semantics must survive: *"the
superseded second-engine target."* Under the D-3 directive, the design-history tier is **distilled and
removed**, not reworded — this file is the distillate. The doctrine and remaining scrub tiers are §9.

### S-6 — Declared keys, self-justified (standing)

Every Lua key is declared in `KEYS[]` or derived in-script only from a declared `KEYS[n]` root by the
registered grammar — an EchoMQ invariant on auditability and the closed grammar alone (the A-1 binary lint
rule), now ALSO slot-sound under braces (every derivable key shares the declared root's slot — the co-location
law sanctions the derivation it once merely permitted).

**The slot-rooted-ARGV clarification (Operator-ratified 2026-06-14 — emq-3 @extend_locks A-1-wording, Apollo
Y-3 §4).** A derived key MAY also be rooted in an **ARGV operand that provably carries the same braced `{q}`
slot as a declared `KEYS[n]`**, the slot-soundness OBLIGATION discharged explicitly (the derived key's hashtag
is identical to a declared key's — checkable by the grammar, `Keyspace.queue_key/2` composing one `{q}` span).
This is **not an exemption** (S-6 binds unchanged — the property the declared-keys rule exists to guarantee,
all of a script's keys on one slot, must still hold and be reviewer-nameable); it codifies the established
`Jobs.*` convention for a **variadic** job-id set — the as-built `@extend_locks`
(`local jk = ARGV[1] .. 'job:' .. id`, `ARGV[1] = emq:{q}:` carrying the slot of the declared
`KEYS[1] = emq:{q}:active`; every id gated `Keyspace.job_key/2` host-side before the wire), used precisely and
only where the id set is dynamic-at-author-time (the singular `@extend_lock` still declares both keys
`KEYS = [active, job_key]`). The A-1 lint enforces the slot-soundness obligation on every ARGV-rooted derived
key; emq.8 lints the corpus against this ruled wording.

### S-7 — Process locks (standing)

AAW LAWS govern; no-invent (BCS requirements cited to file+section; as-built claims to the tree; engine
capabilities to valkey.io); peers run no git; the Director commits by pathspec; the Operator commits
out-of-band mid-flight (watch for `AM`-status files).

## 2 · ADR — the branded-id mandate

**Context.** As-built (pre-regrade): the job key builder concatenates any string into the job position with no
identity gate; ids cross the wire as decimal Snowflake strings or custom strings; branding is edge-only under a
generic namespace. The BCS requirements: the job position takes a **branded id, gated before any wire**
(bcs3.1 §How — `job_key/2` raises unless `EchoData.BrandedId.valid?/1`; the reference
`echo_mq/keyspace.ex:17-24` is committed, rung-gated code), and the kind law is **server-side in the enqueue
script** with a typed wire refusal (bcs3.2 §What — the script's first act refuses a non-`JOB` namespace with
`EMQKIND`). The division of labor is named so no later chapter blurs it: *"the key function owns wellformedness
… while kind policy (which namespaces a queue admits) belongs to the enqueue script, because keys are grammar
and scripts are law"* (bcs3.1 §What-F2). `echo_data` is already an in-umbrella dep
(`echo/apps/echo_mq/mix.exs:25`), so the gate costs no dependency edge.

**The namespace-admission question (both chapters cited).** bcs3.1's committed F1 line shows an `ORD…` id in
the job position — that rung ran **before** D-10 registered `JOB`, and its gate checks *wellformedness only*,
by design; the line proves the gate, not a kind policy. bcs3.2 then registers `JOB` and its enqueue script
refuses any non-`JOB` namespace. The two are consistent under the F2 division.

**Alternatives.** (1) Baseline — keep decimal ids and the ungated builder: rejected — violates the lock, leaves
the job position an open string, forfeits the order theorem (byte order = mint order → browse with no second
index, bcs3.2), and pays more storage (the branded-14 form costs 65 B/key vs decimal-19's 73 on the 8.1 table —
`bcs.id-system.md` §Measured). (2) Gate kind at the key builder too: rejected on bcs3.1's own division — kind
refusal at the key is a client-side exception in one runtime; at the script it is a typed wire reply every
runtime receives identically ("the key let it pass, the law did not" — bcs3.2's rung learned it live).
(3) Queue-configured admitted-kind set in meta: deferred — no present requirement names a second kind; the
change is cleanly additive later (a protocol minor). (4) **The bcs3.2 form — wellformedness at the builder,
the `JOB` constant in the script: CHOSEN.**

**Decision.** Per-job key `emq:{q}:job:<branded-id>`; subkeys `job:<id>:<sub>` (the locked segment spelling).
The key builder gates with `EchoData.BrandedId.valid?/1` (`echo_data/branded_id.ex:95`) and **raises before any
wire** — wellformedness only, kind-blind. Every add script's **first act** refuses a non-`JOB` id with the
`EMQKIND` first-word wire class, before existence, before any write (*policy before existence before write* —
bcs3.2's normative act order). The mint produces **`JOB`-branded ids**; the **fourteen-byte branded form is the
wire form** everywhere a job id travels; the decimal rendering is internal arithmetic. **Custom job ids retire
from the job position** (D3 ruling DQ-4): producer-chosen idempotency keys ride `emq:{q}:de:<dedupId>` (charset
`[A-Za-z0-9._-]{1,255}`); the branded id is the receipt. Fencing refusals adopt the `EMQSTALE` first word at
existing stale-token sites; the attempts-as-token unification is emq.2's (§4).

**Consequences.** Grammatical disjointness (`job:` vs the structure types) stays load-bearing for parse
totality; the parse *simplifies* (a branded id carries no `:`). **Migration must brand**: numeric v1 ids brand
order-preserving (`JOB` + base62(integer) — injective, numerically disjoint from any realistic Snowflake);
non-numeric v1 custom ids refuse through the existing typed lane (`{:error, {:unmigratable_job_ids, ids}}` —
drain first); set/list members carrying ids rewrite in the same pass. The branding lane is the one Track-B
surface pre-authorized to escalate to a Mars seat (ledger D-2). The pre-regrade keys test that asserted the old
segment with a custom id in the job position is rewritten, not verified.

## 3 · ADR — the fence merge (staged, deployment-only)

**Context.** Two fences with different scopes. **The BCS deployment fence** (bcsA §The design): on every
connect — first boot and every reconnect — the connector reads `{emq}:version`, claims it `SET NX` when absent,
verifies the read-back, and refuses typed on any other value; committed `PASS 8/8` against Valkey 9.1.0.
bcs3.1 names the placement law: the version fence lives under `{emq}:` *"precisely because it is the one fact
that is about the deployment rather than about any queue."*.

**Alternatives.** (1) Baseline — per-queue `meta.version` only, `{emq}:version` unwritten: rejected — a
registered reserve member that never exists, against bcsA's placement law; and bcs3.md's second law ("the fence
before the first command … at connect and again at every reconnect") is connect-scoped — a per-queue boot
preflight cannot express it. (2) Dual authority, permanent: rejected — two writable copies of one wire-version
fact is a drift surface; the per-queue copy answers no question the deployment fact plus the per-queue
**journal** cannot. (3) **Deployment-only, staged: CHOSEN.**

**Decision.** `{emq}:version` = `echomq:2.0.0` is the version authority — claimed `SET NX` on a fresh store,
read-back-verified, refused typed on mismatch, re-checked at every connect and reconnect (the bcsA mechanics).
**Staging:** at the `emq-design2` rung (Track B, mechanical) the existing per-queue flow re-keys braced
unchanged in logic, `{emq}:version` is **written at `record_bundle`** (`SET NX` + read-back) and **consumed
immediately by the truth-row probe** (never declared-but-unconsumed), and `{emq}:locks` is registered
reserved-by-name (bcs3.1's F1 line establishes its existence; no chapter gives mechanics; inventing them would
violate no-invent — populated by the rung that needs it). At **emq.2** (the re-founded convergence rung) the
refusal moves to connect; `:version_major_mismatch`/`:foreign_version` re-aim their read to `{emq}:version`;
per-queue `meta.version` retires (write-stops; read-tolerated); `metaEnsureVersion` **retargets** to the
`{emq}:version` claim (the monotone raise is exactly what minor-tolerance needs — the emq.2 brief's ADR);
the tombstone discrimination folds into the sentinel sweep (tombstone + journal-`completed` on this store ⇒
proceed; tombstone + no `{emq}:version` + no journal ⇒ the config points at the drained source — refuse).
**All five fence codes survive the merge** — the vocabulary is unchanged; two codes re-aim their read.
**The sweep under braces is unchanged** in logic, and the braced canon *shrinks* a residual: a v1 deployment at
prefix `"emq"` writes `emq:<q>:wait`, no longer shape-identical to v2's `emq:{q}:wait` — the blind spot narrows
back to the triple-opt-in class (prefix-`"emq"` + braced names + `skip_meta_update`), the irreducible
unversioned-keyspace case, routed through the operator's `v1_prefix` declaration. The other named residual
stands: a never-upgraded `1.3.0` binary is structurally unfenceable; its protection is the runbook ordering
plus the migration tool's terminal DELETE.

## 4 · The BCS gap matrix — the convergence ladder

The full 34-row disposition of every BCS Part-III invariant against the as-built tree, authored at D1 of the
`emq-design2` rung and corrected at D2 (ledger D-1): **13 rows CLOSE at the emq-design2 rung** (the floor:
braced grammar · the branded gate + `job:` segment + `EMQKIND` · the four-member `{emq}:` reserve +
`{emq}:version` written/probed · `EMQSTALE` at existing refusal sites · the 17-byte budget probe · the
engine-hygiene gate · the migration branding lane · the cargo-law spec carriage), **5 HOLD** (verify: the
closed registry, the queue-name rule, backoff-above-the-wire, the declared-keys law — already converged,
stronger than bcsA's form — and the EVALSHA load-SHA assert), and **16 RE-AIM** into four named clusters:

1. **The state machine + the connect fence** (rows 1, 16–18, 21, 23–29 + the fold rows 2, 31) → **emq.2,
   re-founded by the Operator's D3 directive as "the BCS state machine"** (ledger D-2): the three-field job
   hash (`state, attempts, payload`), the four sorted sets (`pending` score-zero-forever / `active`
   lease-deadline-scored / `schedule` run-at-scored / `dead`), eight verbs over six scripts (the reference
   `echo_mq/jobs.ex` carries 3.2's enqueue + 3.3's five constants), `attempts` as the fencing token with
   `EMQSTALE`, completion-deletes, the morgue with `last_error`, the two pumps, lex browse, **the server-clock
   law** (the D3 ruling DQ-2c: `TIME` in transition scripts — bcs3.3's law, sound under effects replication;
   the no-clock lint retires at emq.2 and only there; ARGV-time holds until then — one corpus, one direction),
   and the §3 staging's second step. The triad is re-derived (Track A, landed); the build is gated on the
   emq-design2 D5 close (the rung runbook — formerly `emq.2.prompt.md`, deleted with the old spec home;
   re-issued under `./specs/` when the program roadmap schedules the rung).
2. **Fair lanes** (row 4 ⇄ the manuscript's planned chapter 3.4) — the displaced groups family; its rung slot
   is **RULED: the program ladder's emq.4** (the Stage-1b checkpoint; `./emq.roadmap.md` seam 2, CLOSED).
3. **Proof + benchmark** (rows 5, 6) → emq.6 (⇄ the planned 3.6).
4. **The substrate adoptions** (rows 14, 34) → the standing umbrella-adoption follow-up
   (`bcs.progress.md`'s carried list): the client-side slot function and the BCS connector question — out of
   the bus's 2.0 scope at the standalone posture. The connector half has since LANDED: Movement 0 (rung
   emq.0) extracted the BCS wire — `EchoMQ.{RESP, Connector, Script}`, names frozen, the `EchoWire` facade —
   to `echo/apps/echo_wire`, and the bus rides it. The fence's `Keyspace` read stays in `echo_mq`; that
   cross-app seam is carried to the scheduler rung's opening design gate (the emq-0 run ledger, D-10).

The row numbers below are load-bearing citations (the D-2 ruling, the emq.2 runbook, and the triads cite them);
the table is therefore carried in full. As-built anchors were verified at the rung's D1 against the
pre-regrade tree; Track B regrades exactly those surfaces, and the D5 reconcile differ trues the residue.

| # | BCS requirement (source) | As-built state at D1 | Disposition |
|---|---|---|---|
| 1 | Six laws · *one transition, one script* (bcs3.md §Laws) | One script per transition holds across the bundle; the transition SET is v1-shaped | **RE-AIMS → emq.2**; the per-script law HOLDS |
| 2 | Six laws · *the fence before the first command, at connect* (bcs3.md; bcsA) | Per-queue boot preflight; no connect fence; `{emq}:version` unwritten | **CLOSES partially** (write + probe) / **RE-AIMS** the connect refusal → emq.2 |
| 3 | Six laws · *jobs are entities* (bcs3.md; bcs3.2) | Decimal/custom ids, ungated builder; no lex browse | **CLOSES** the id mandate (§2) / **RE-AIMS** browsing (rows 17–18) |
| 4 | Six laws · *park, don't poll* (bcs3.md; the planned 3.4) | The v1 poll/marker fetch model | **RE-AIMS** → the fair-lanes rung |
| 5 | Six laws · *delivery semantics named per surface* (bcs3.md) | Partially stated | **RE-AIMS** — stated in the corpus; per-surface naming rides each rung |
| 6 | Six laws · *rivals measured, advantages printed* (bcs3.md; the planned 3.6) | Nothing run | **RE-AIMS** → emq.6 |
| 7 | bcs3.1 · braced per-queue grammar (§What-F1) | Unbraced base; braced expectations already in tests (red by design) | **CLOSES** — the floor |
| 8 | bcs3.1 · job position gated at the builder (§What-F2, §How) | No gate | **CLOSES** — §2; the floor |
| 9 | bcs3.1 · the grammar is closed (§Decisions) | Closed registry + raising getter | **HOLDS** — verify under braces |
| 10 | bcs3.1 · the `{emq}:` reserve, four members (§What-F1; the lock) | Two empty-segment members; no `version`/`locks` | **CLOSES** — re-key + register + write `version` (§3) |
| 11 | bcs3.1 · the co-location law (§What-F5, §Decisions) | Shared root, no slot meaning unbraced | **CLOSES** — braces restore the ground; the A-1 lint already enforces one-root |
| 12 | bcs3.1/bcsA · the 17-byte budget (INV-K2) | Holds by arithmetic; unprobed | **CLOSES** — the probe gains the assert |
| 13 | bcs3.1 · wellformedness at the key, policy at the script (§Decisions) | Neither half for ids | **CLOSES** — §2 |
| 14 | bcs3.1 · the slot function, committed and parked (§What-F5) | Absent from the bus | **RE-AIMS** → the umbrella-adoption follow-up |
| 15 | bcs3.1 · queue-name charset + `emq` rejected | Holds | **HOLDS** — justification sharpens under braces |
| 16 | bcs3.2 · the three-field job hash; no `enqueued_at` (§What) | The v1-shaped multi-field hash | **RE-AIMS → emq.2** (wire-visible; the §11.11 governance edge) |
| 17 | bcs3.2 · pending = score-zero ZSET of ids; lex = mint (§What, §Decisions) | wait LIST + prioritized ZSET + counter | **RE-AIMS → emq.2** |
| 18 | bcs3.2 · order-theorem browse (`BYLEX REV`) (§What-J4) | No lex browse | **RE-AIMS → emq.2** |
| 19 | bcs3.2 · enqueue: policy before existence before write (§Decisions) | Single-script adds; no kind act | **CLOSES** the kind act (§2); the act-order audit at emq.2 |
| 20 | bcs3.2 · `EMQKIND` (§What, §Decisions) | Absent | **CLOSES** — §2/§5; the floor |
| 21 | bcs3.2 · `duplicate` is a success shape (§Decisions) | Event-surfaced, not the BCS vocabulary | **RE-AIMS → emq.2** (ruled there: `{:ok, :duplicate}` + the event carries) |
| 22 | bcs3.2/bcs3.md · the cargo law | Caller discipline, unstated | **CLOSES** the spec carriage |
| 23 | bcs3.3 · four sorted sets with score semantics (§What) | v1-shaped structures | **RE-AIMS → emq.2** |
| 24 | bcs3.3 · claim mints the token by `HINCRBY attempts` (§What) | The v1 lock-token model | **RE-AIMS → emq.2** |
| 25 | bcs3.3 · attempts IS the token; `EMQSTALE` (§What, §Decisions) | No `EMQSTALE`; stale refusals exist unworded | **CLOSES** the class word at existing sites (§5) / **RE-AIMS** the unification → emq.2 |
| 26 | bcs3.3 · the server clock owns leases (§Decisions; valkey.io/topics/replication) | The corpus banned engine-clock reads | **RE-AIMS → emq.2 as RULED** (DQ-2c: adopt there; the lint flips there) |
| 27 | bcs3.3 · completion deletes (§Decisions) | Retention semantics | **RE-AIMS → emq.2** |
| 28 | bcs3.3 · one constructed key, sanctioned, never generalized (§Decisions) | The broader registered derivation grammar | **RE-AIMS** narrowing → emq.2; braces restore the sanction's ground NOW |
| 29 | bcs3.3 · the morgue + the two pumps (§What) | v1-shaped failed/stalled machinery | **RE-AIMS → emq.2** |
| 30 | bcs3.3 · backoff above the wire (§When) | Holds (host-side policy, literal delays) | **HOLDS** — verify at emq.2 |
| 31 | bcsA · `{emq}:version` claimed `SET NX`, verified, typed (§The design) | Absent | **CLOSES** write + probe / **RE-AIMS** connect refusal (§3) |
| 32 | bcsA · every script key declared (§The design) | Holds, stronger (declared-or-rooted + A-1 + numkeys) | **HOLDS** |
| 33 | bcsA · EVALSHA-first; the load-SHA assert (§The design) | Self-heal present; the SHA assert unverified | **HOLDS** — verify at the convergence reconcile |
| 34 | bcsA · the RESP/connector substrate (§The design) | The bus rides its own client; the BCS connector is the committed reference | **RE-AIMS** → the umbrella-adoption follow-up |

One genuine requirements-vs-corpus fork was surfaced by the matrix and ruled: bcs3.3 mandates `TIME` inside
the claim script while the founding corpus banned engine-clock reads — both citing the same replication
doctrine; the BCS position is rung-gated and adopts at emq.2 (DQ-2c, row 26).

## 5 · ADR — the wire-class vocabulary

**Context.** bcs3.2 establishes the convention from a live wire fact: the engine wraps class-less custom
errors in its generic `ERR` prefix, so *"every typed refusal a bundle script issues leads with its class word,
never riding the generic `ERR`"*. Two classes exist in the requirements: **`EMQKIND`** (kind refusal at
enqueue) and **`EMQSTALE`** (fencing-token refusal — bcs3.3: "the wire-class family grows by one").

**Alternatives.** (1) No classes — match server errors by message text: rejected by bcs3.2's own live failure.
(2) Fold wire refusals into the fence union as sixth/seventh codes: rejected — the union is closed to
keyspace/version boot-contact outcomes (the founding D-10/D-21 class separation); wire classes are per-call
runtime replies that must exist on the wire for every runtime. (3) **A separate closed registry: CHOSEN.**

**Decision.** The protocol carries a **closed wire-class registry** beside the key grammar: at 2.0 exactly
`EMQKIND` and `EMQSTALE`; format `EMQ<CLASS> <detail>` via `redis.error_reply`; **adding a wire class is an
additive protocol minor**, registered with its conformance probe in the same change. Client-side: one mapping
seam per runtime (`"EMQKIND" <> _ → {:error, :kind}`; `"EMQSTALE" <> _ → {:error, :stale}`); an unrecognized
`EMQ*` first word passes through untyped (forward-compatible with minors). **The five-code fence union stands,
unextended.** The cross-layer rule, stated once for all three channels: fence codes for boot keyspace/version
contact · wire classes for server-issued per-call refusals · configuration-class errors for operator config.

## 6 · The grammar, restated total for braces

```
key         := per-queue | reserve
per-queue   := "emq:{" q "}:" suffix
reserve     := "{emq}:" unit
unit        := "version" | "locks" | "bundle" | "migration:" q     (CLOSED, 4 members)
suffix      := type                                                 (CLOSED registry)
             | "metrics:" ("completed" | "failed") [":data"]
             | "job:" jid [":" sub]    sub ∈ {lock, logs, dependencies,
                                              processed, failed, unsuccessful}
             | "de:" did
q           := ^[A-Za-z0-9._-]{1,128}$  and  q ≠ "emq"
jid         := a branded id (EchoData.BrandedId.valid?/1 — 3 uppercase + base62, 14 bytes)
did         := ^[A-Za-z0-9._-]{1,255}$
```

**The totality property.** (a) **First-byte disjointness**: a per-queue key begins `emq:{`, a reserve key
begins `{emq}:` — no string is both; everything else is `{:unclassified, _}`. (b) **Unambiguous queue
extraction**: the queue name is the span between the first `{` and the first `}`; the name grammar excludes
both braces. (c) **Unambiguous suffix split**: `job:`/`de:` are not registry members; a `jid` carries no `:`,
so `job:<id>:<sub>` splits deterministically and `sub` membership is a closed check. (d) **Reserve closure**:
four members; `{emq}:` followed by anything else is unclassified. (e) **The round-trip property**: for every
valid `(q, part)` tuple, build → parse → parts equal; and every per-queue key of `q` carries exactly the
hashtag `q`, every reserve key the hashtag `emq`, with `q ≠ "emq"` keeping the slot families disjoint. The
emq.2 reform **extends the closed registry** (`pending`/`schedule`/`dead` join; the v1-shaped lifecycle types
retire) without touching the grammar's shape.

## 7 · The GWT gate text (live in the corpus)

The chapter-scoped Given-When-Then block ("The Valkey gate — specification by example") was a standing section
of the pre-move chapter index `emq.md`, deleted with the old spec home; the block re-homes in the `./specs/`
triads as the program authors them. Its content: honest-row reporting both ways; the engine-hygiene allowlist
{Valkey, Redis-as-the-historical-row} with assembled patterns; `GET {emq}:version` = `echomq:2.0.0` after
`record_bundle`; the 17-byte budget; grammar totality with the four-member reserve. Its per-rung twin — the
standing story **`EMQ.N-US-GATE`** — was present in all six pre-move `emq.N.stories.md` files (Track A,
verified 6/6 at the old home) and rides every `./specs/emq.N.stories.md` triad as it is authored
(`emq.0.stories.md` carries `EMQ.0-US-GATE`; `emq.1.stories.md` carries `EMQ.1-US-GATE`).
GWT presence is itself a D5 structural gate.

## 8 · The machine gate — the engine-allowlist hygiene test

**Mechanism decision.** Allowlist-complement (detect "engine-name-shaped" tokens generically) was steelmanned
and rejected — no decidable detector exists. **Chosen: the assembled deny-list** — the known banned token
classes (the name case-insensitively, which subsumes the brand-domain suffix; the URL env gate; the Lua flag
header; the era tag), each pattern built by string concatenation at run time so the test's own source carries
no banned token. Ships at `test/conformance/engine_hygiene_test.exs` (Track B), scanning
`lib/ test/ priv/ guides/`, running in the default suite, engine-free. The fragment-pair table and skeleton as
authored:

```elixir
@banned [
  {"dra", "gonfly", :insensitive},   # the engine name; covers the brand-domain suffix
  {"DRA", "GONFLY_URL", :sensitive}, # the URL env gate
  {"--!", "df", :sensitive},         # the Lua flag header
  {"DF-", "era", :sensitive}         # the era-abbreviation tag
]
# for each file under lib/ test/ priv/ guides/: assemble a <> b, downcase when
# :insensitive, assert zero contains-hits; the assembled needle never appears
# contiguously in this file's own source.
```

The repo-wide D5 gate is the same assembled-pattern grep at the git level; this test is the **standing**
in-tree gate after D5 closes. The one banned *filename* surface (the second-engine probe file) is deleted
outright in Track B — pre-sanctioned by the founding phase's probe-retirement line.

## 9 · The eradication doctrine + the scrub plan (as amended by D-3)

**Doctrine.** The five token classes reach **zero mentions across tracked files**. Where decision semantics
must survive: *"the superseded second-engine target"*; entries are reworded, never deleted — except the
design-history tier, which the **D-3 directive supersedes from reword to distill-and-remove** (this file is the
distillate; the Director deletes the absorbed artifacts and merges the two ledgers into one and the two
registries into one; the merged ledger is hand-maintained thereafter).

**The verified inventory** (re-derived from the tree; the D5 gate is the grep, not the list): 66 name-token
files + 2 era-tag-only = **68**. Tiers: **0 · code** (Track B — the probe-file delete, the env-gate strip, the
assembled-needle lint regrade, the era-tagged test name, the migration guide's residual section; verified by
the pure slices + the §8 gate) · **1 · design history** (~205 hits across eight files — **OBE per D-3**:
distilled here, then deleted) · **2 · BCS records** (3 files, the phrase swap) · **3 · course surfaces**
(html/echomq + markdown mirrors, html+docs redis-patterns, the portal_web template; `cms check` A+ per touched
page; three runbook-listed files were already deleted out-of-band) · **4 · defs + misc** (the agent/skill
defs, the valkey docs, the Go store fixture — no Go test asserts the token, re-run `go test ./internal/store/`
— plus `docs/aaw/mcp/aaw-mcp.progress.md:503`, found in the tree, absent from the original inventory) · **the
echo_flame wipe** (the three dangling-reference files, same pass).

## 10 · The decision sheet — RULED (the D3 gate, ledger D-2)

| # | Question | The ruling |
| --- | --- | --- |
| DQ-1 | The fence merge | **Deployment-only, staged** (§3): `{emq}:version` written at `record_bundle` + probed at the emq-design2 rung; connect-refusal + `meta.version` retirement at emq.2; all five codes survive |
| DQ-2a | The convergence line | **13 close / 5 hold / 16 re-aim** into the four clusters (§4) |
| DQ-2b | The rung floor | Confirmed: zero tokens + braced grammar + the branded gate (+ `job:` segment, `JOB` mint, `EMQKIND`) + the 4-member reserve + green tests |
| DQ-2c | The clock fork | The BCS server-clock law (`TIME` in transition scripts) **adopts at emq.2**; the no-clock lint survives until then and retires there |
| DQ-3 | Wire classes | The closed registry (`EMQKIND`, `EMQSTALE`; first-word convention; additive-minor growth with probe); the fence union stands unextended |
| DQ-4 | Subkeys/dedup/totality + custom ids | Approved, **including the custom-id retirement** from the job position (absorbed by branded idempotency + `de:`) |
| R-1 | The deleted framing doc | Its reversal content re-homed into the rewritten `emq.md` (done, Track A; that index since deleted with the old spec home) |
| R-2 | The migration branding lane | The Mars seat **pre-authorized** for Track B escalation |
| R-3 | Inventory deltas | Acknowledged (68 files; the out-of-band deletions; the new tier-4 file) |
| + | **emq.2 re-founded** | The Operator's directive: "the BCS state machine" — the triad re-derived in Track A; the build gated on this rung's D5 close. Amendment window: any DQ ruling may be amended until Track B's wire changes commit at D5 |

## 11 · Standing decisions distilled from the founding phase

The founding Design Phase (dual independent architects with opposed lenses → cross-review → independent
evaluation, BUILD-GRADE with six corrections → Director synthesis → Operator approval) produced these binding
decisions, restated token-free with their grounds:

1. **S-1** · the v2 prefix is emq;
2. **Job identity = the B′ arm** — Snowflake, config-assigned node ids, **no store lease** (no node-ids
   registry key exists; the explicit→config→host-derived resolution chain is the as-built primitive's own);
   the per-queue `INCR` counter retired; the boot-time advisory collision check is a named deliverable
   (refuse on invalid configured id as a configuration error; loud resolved-id log; connected-node duplicate
   warning; the runtime collision symptom — a duplicated-job signal on a fresh mint — documented). The lease
   arm was recorded as dominated and dis-recommended. **The wire form half of this decision is superseded by
   §2** (branded `JOB`); the mint machinery stands.
3. **F-B · the strict pair** — queue names `^[A-Za-z0-9._-]{1,128}$`, ASCII-strict, braces rejected never
   normalized; dedup-id charset aligned at 1–255.
4. **F-C · replace-on-main** — the v2 script set replaces `priv/scripts/` on main; the v1 bundle lives on the
   `1.3.x` maintenance branch; the migration tool carries its own frozen v1 key-name table.
5. **The v1-side fence = the terminal `1.3.1` fence-only patch** — the entire diff is the mirror preflight
   (refuse `:v2_keyspace` on a v2-stamped keyspace; refuse `:migration_tombstone` on its own tombstoned meta).
6. **F-2 · matrix cadence** — the truth row at every rung close + on engine stable-line GA, advisory between;
   rows append-only.
7. **`%EchoMQ.FenceError{}`** — the struct name (a boot-fence union deserves a fence name; the wider name
   stays free), the tombstone as a distinct fifth CODE (a distinct stamped value deserves a distinct typed
   outcome), fields `queue/found/expected/probe`, `@enforce_keys`.
8. **Probe-id scheme** — A-1…A-4 for the static analyzer (A-1 KEYS-root · A-2 the manifest triangle · A-3 the
   dialect lint · A-4 the derivation grammar) + P-n for the dynamic probe classes; dual citation (probe id +
   matrix row id) once the suite exists.
9. **The bundle contract** — one script per transition; structured headers; the Elixir-side manifest; the
   manifest↔header↔filename `-<numkeys>` triple cross-check refusing at load; the bundle content hash (ordered
   per-script SHAs) at `{emq}:bundle`; numkeys enforced at the call seam. **The registered derivation
   grammar** (a build-pass realization, fold-in confirmed): from the declared queue base, exactly the per-job
   key, its registered subkeys, the dedup key, and the closed structure types — nothing else derivable.
10. **Deferral families, typed never silent** — the parent/flow and scheduler script families are not in the
    2.0 bundle (their v1 forms root key operands in data values, structurally inexpressible under the
    declared-keys invariant); calls land on the existing typed `{:error, {:script_not_found, name}}`; an
    A-1-compatible flow design is real design work for the family rungs. Dead vendored scripts excluded
    permanently. **Dedup at the build** = simple NX+TTL (the v1 replace/extend modes were unreachable from
    this runtime; the twin event dropped at the break; richer modes = additive minors).
11. **The job-hash governance edge** — at 2.0 the v1 hash schema carried verbatim; field reform was priced as
    a next-major. **The emq.2 re-founding exercises exactly that edge** (the three-field row): the in-place
    v2→v2 treatment and the wire-semver call are §10 seam 1, settled with the Operator BEFORE that build;
    the likely resolution ground is the no-release precondition (the v2 line has never shipped).
12. **The escalation protocol (standing)** — any peer that meets a spec⇄design, spec⇄spec, or spec⇄as-built
    contradiction STOPS and escalates; the design is the authority; the architect seat owns the spec
    correction; hygiene (a deterministic re-grep/probe) closes every escalation, run by the corrector AND the
    Director. Born from the live mid-build catch where a spec-carried probe-ordering clause contradicted the
    conformance-truth locks: an implementor faithfully built a spec defect, and the catch came from the
    Operator's review — the class ("an ordering clause that contradicts a later substrate pivot") rides the
    reconcile checklist.
13. **The v1 maintenance-line defects (recorded, not v2 work)** — the v1 keys module's doc examples print a
    prefix its own default contradicts; the wrapper↔script mis-pairs found at the build (a retry wrapper
    aimed at the wrong transition; three argument-order drifts) were closed by construction in v2.

## 12 · The engine-feature ADRs — the break's unlocked surface, on Valkey 8+

Establishing EchoMQ 2.0 put the modern engine surface in reach. Each candidate was
dispositioned with verified citations; the founding decisions are re-grounded here for the single-engine,
braced, Valkey-8+ canon (where a founding rejection rested on the superseded second-engine target's
capabilities, the new ground is stated — a decision that outlives its original reason needs a reason that
lives).

1. **Script transport: `EVALSHA` + `NOSCRIPT` self-heal retained; `FUNCTION` not adopted at 2.0.**
   `FUNCTION`/`FCALL` is real on the engine line ("Since: 7.0.0" — valkey.io/commands/function-load/), and its
   steelman is strong: server-side libraries survive `SCRIPT FLUSH` (the `NOSCRIPT` race class disappears),
   name-based invocation, atomic library replace. The founding rejection's deciding fact (the superseded
   second-engine target did not implement it) is RETIRED with that target; the decision **stands on new
   grounds**: the hybrid is rejected independently (two transports double the conformance surface for
   identical transitions); the self-heal pattern is hardened in-tree and load-bearing; the bundle's identity
   and contract already live client-side (the content hash at `{emq}:bundle` + the manifest triple
   cross-check), so a server-side library registry adds state without adding contract; and the scripts'
   `KEYS`/`ARGV` contracts are transport-neutral, so the switch buys zero wire value. **Reopening condition:**
   a minor-version transport discussion (never a wire change) when an operational need names the `SCRIPT
   FLUSH` race as a real cost.
2. **Multi-key pops (`LMPOP`/`ZMPOP`): not adopted.** Availability is not the blocker ("Since: 7.0.0" —
   valkey.io/commands/zmpop/); necessity is. Every v2 state transition is one Lua script — atomic on the
   engine ("Valkey guarantees the script's atomic execution" — valkey.io/topics/eval-intro/) — so a
   client-side pop would BYPASS the script layer's event and bookkeeping path: a second, weaker transition
   path is the opposite of a wire contract. The founding analysis also noted the v1 worker's multi-source pop
   spans two structure types; **under the emq.2 machine the ground strengthens and simplifies** — claim IS
   `ZPOPMIN` inside the claim script (bcs3.3's token mint), so the client-side variant has no role at all.
   Count-variant pops remain the 6.2-level surface the batch family builds on at its rung. The rest of the
   candidate family, closed out with it: **`EXPIRETIME` is tool latitude only** — the migration tool may read
   absolute expiries where available, but the core wire's TTL carriage is `PTTL`/`PEXPIRE` (nothing outside the
   computed floor enters the core); **`OBJECT` has no protocol use**; and the engine-side atomicity-disable and
   per-script undeclared-key exemption mechanisms (the latter a flag of the superseded second-engine target)
   are **forbidden by the invariant** — no exemption mechanism exists at any grain (§1 S-6).
3. **Sharded pub/sub (`SSUBSCRIBE`): deferred to the cache rung's invalidation bus.** Verified: shard channels
   are slot-routed, "all the specified shard channels need to belong to a single slot" per call
   (valkey.io/commands/ssubscribe/). Rejected for the core event channel: pub/sub delivery is
   fire-and-forget, while the per-queue event stream is replayable history with ids and range reads (the
   interop harness's completion read rides it; under emq.2's completion-deletes the event record is the
   durable receipt — the stream's value RISES). **The braced canon strengthens the deferral's landing zone**:
   a queue's shard channel co-locates with its keys by the same hashtag — the slot-routing match the unbraced
   interlude lost. The reopening is addressed: the cache rung's invalidation transport evaluation.
4. **Hash-field TTL (`HEXPIRE` family): out of the 2.0 core; the first queued wire candidate for the next
   protocol major.** The availability map as verified at the founding phase: the engine line ships it at
   9.0.0+ ("Since: 9.0.0"); Redis OSS at 7.4.0 (outside the BSD-era shelf). **On the stated Valkey 9+ line the
   exclusion is also a floor fact**: a 2.0 core feature must run on 8.x. The matrix carries the capability
   column; adoption is a next-major wire discussion (per-field lock/lease TTLs are the obvious consumer).
5. **The engine floor and ceiling.** The 2.0 core's command surface is bounded by the **7.0-level ceiling**
   (nothing newer enters the core wire inside the 2.x line) and the **actual floor is computed** (the P6 probe
   derives it from the bundle's command inventory and records it in every matrix row; expected ≈ the 6.2-level
   surface — `LMOVE` the newest expected core command after the `HMSET`→`HSET`, `RPOPLPUSH`→`LMOVE`
   modernization; deprecated forms do not enter a fresh protocol). The floor number in documentation is always
   quoted FROM the matrix row, never asserted free-standing; **a computed-floor raise is a protocol minor at
   minimum**. Documented rows: Valkey current stable (the truth row, gating) and Redis 7.2.x recorded as the
   BSD-era licensing shelf (the historical row) — the honest-reporting mechanism the gate text enforces.
6. **The Lua dialect, the API table, and replication.** Lua 5.1 (the engine's interpreter); the bundle's only
   API table is **`redis.call`/`redis.pcall`** — the engine's docs canonically name `server.call`/`server.pcall`
   (valkey.io/topics/eval-intro/), and the alias's availability on the truth row is asserted by the suite's
   first run, never by prose; zero engine-specific headers (the bundle is plain Lua); the engine replicates
   scripts **by effects** (MULTI/EXEC to replicas + AOF — valkey.io/topics/replication/), which makes BOTH
   clock conventions sound — ARGV-time (the emq.1 bundle as built) and the BCS server-clock law (`TIME` inside
   transition scripts under the frozen-time rule) — so the clock question was ruled on requirements, not
   replication: the server clock owns leases from emq.2 (DQ-2c), one corpus, one direction.
7. **Durability posture.** One documented posture: AOF, `everysec` default with the engine's stated bound,
   `always` named; the two-variant SIGKILL restart probe runs on the truth row only; `WAITAOF` is an
   instrument where available, never floor-bearing, never a wire guarantee.

---

> **Forward.** This canon is the **2.x line** (S-1..S-7). The next major — **EchoMQ 3.0, the Stream
> Tier** — is specified in [`./emq.streams.md`](./emq.streams.md); the shipped per-rung record is
> [`./emq.changelog.md`](./emq.changelog.md); the delivery plan is [`./emq.roadmap.md`](./emq.roadmap.md).

