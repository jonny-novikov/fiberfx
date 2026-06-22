# emq3.2 — THE WRITER LAW · design + ADRs (Venus-A, the order-theorem lens)

> **Dual-architect design phase.** This is ONE of two independent designs for emq3.2 (the writer law of the
> EchoMQ 3.0 Stream Tier). Authored against the locked constraints + the as-built tree + the official Valkey
> docs — NOT against the sibling architect's draft. The Director synthesizes the two into a consensus; the
> triad derives from the approved design AFTER the Operator rules the forks. **NO triad here, NO code, NO git.**
> Forward-tense throughout ("emq3.2 builds…") for everything the rung adds; surfaces that already ship are
> cited present-tense against the re-probed tree.
>
> **Lens (the Director's brief):** lead with the ORDER THEOREM + the id-mapping correctness — reason "append ==
> mint order" to the ground FIRST (including under same-millisecond, multi-node branded-id mints), then build
> the rest of the writer law around it. ADR-1 is the core; ADR-2..6 follow from it.

---

## 0 · Context — what emq3.2 is, and the one question it must answer to the ground

emq3.1 (SHIPPED `7b44dc97`, conf **74**, label `echomq:2.6.0`) landed the **verb floor**: the five stream verbs
(`XADD`/`XRANGE`/`XREADGROUP`/`XACK`/`XAUTOCLAIM`) reach the certified connector as raw `parts` lists, round-trip
on Valkey 6390, pipeline in call order, and stay push-safe under RESP3 — proven by `stream_verbs_test.exs`. emq3.1
appends with the **server-minted `*` id** (sufficient to prove the plumbing); it builds NO module surface and mints
NO branded id (`emq3.1.md:19-22`, `stream_verbs_test.exs:18-27`).

emq3.2 is the **writer LAW above that floor**: the `EchoMQ.Stream` module (which does NOT yet exist — re-probed,
`find stream*.ex` empty; `events.ex:35-36` names it forward as its successor in committed code). Per the tier
canon (`emq.streams.md:69`): *"per-key hash-tagged streams, branded record ids, append == mint order; wrong-kind
refused at the door."* The gate sketch (`emq.streams.md:69`): *"append-order property: stream order == id sort,
every time; wrong-kind refused at the door."*

**The crux** — the carry-fact `emq.streams.md:57` ASSERTS but must be PROVEN: *"the branded id IS the stream
position — append == mint order, the order theorem extended to the log, no second index."* That is an assertion
until the **branded-record-id ↔ XADD-entry-id mapping** is reasoned rigorously. It is the entire risk of the rung,
because the two id systems have **different shapes and different native sort orders**:

| | The branded record id | The XADD entry id |
|---|---|---|
| Shape | 14 bytes: `3×[A-Z]` namespace ++ 11-char base62 payload (`branded_id.ex:3-4`) | `<ms>-<seq>`, two **64-bit** numbers (valkey.io/commands/xadd: *"Both quantities are 64-bit numbers"*) |
| Underlying value | a 63-bit snowflake `ts(41)<<<22 \| node(10)<<<12 \| seq(12)` (`snowflake.ex:3`, epoch 2024-01-01) | a `(ms, seq)` pair the stream stores in increasing order |
| Sort order | byte order of the 14-byte string (== snowflake int order, proven §ADR-1) | `(ms, seq)` lexicographic on the pair |
| Mint authority | host-side, coordination-free — *mint on any node, no registry* (the BCS law) | server-side under `*`; or caller-supplied explicit `<ms>-<seq>` |

The order theorem requires **THREE orders to coincide, every time**: branded-string byte order ≡ snowflake integer
order ≡ XADD entry-id order. ADR-1 reasons exactly when they coincide and what breaks them. Everything else in the
writer law (the kind door, the key, the API, conformance, the label, the risk) is downstream of getting ADR-1
right.

**Locked constraints I designed against (read, not redesigned):** `emq.streams.md` (the tier) · `emq3.1.md` +
`stream_verbs_test.exs` + `conformance.ex` (the as-built floor) · `emq.design.md` §0/§2/§6/§12 (the order theorem,
the branded-id ADR, the grammar, the engine-feature ADRs) · `snowflake.ex`/`branded_id.ex`/`base62.ex` (the
substrate) · valkey.io/commands/xadd + valkey.io/topics/streams-intro (the engine, cited never-from-memory).

---

## ADR-1 (THE CORE) — the branded record id ↔ the XADD entry id: map by FIELD CORRESPONDENCE

**Context.** A stream record carries a host-minted branded id (e.g. `EVT…`, an `EVT`-namespaced 14-byte form). To
append it so that *stream order == id sort == mint order*, emq3.2 must put it on the wire as an XADD id. XADD
offers three id modes (valkey.io/commands/xadd, valkey.io/topics/streams-intro):

1. **`*`** — server mints `<instance-ms>-<seq>`. *"the first part is the Unix time in milliseconds of the Valkey
   instance generating the ID … The second part is just a sequence number."* The id is the SERVER's, unrelated to
   the branded id.
2. **explicit `<ms>-<seq>`** — *"It is possible to specify a well-formed ID."* **Rejected if not strictly greater
   than the stream's top:** *"the user must specify an ID which is greater than any other ID currently inside the
   stream, otherwise the command will fail and return an error"* — verbatim error: `ERR The ID specified in XADD
   is equal or smaller than the target stream top item` (valkey.io/topics/streams-intro).
3. **`<ms>-*`** — fix the ms, server auto-increments the seq within it (*"the sequence portion of the ID will be
   automatically generated"*, Redis OSS 7+/Valkey).

The branded id decomposes (no NIF needed for the math — `snowflake.ex`): a snowflake is
`ts(41)<<<22 | node(10)<<<12 | seq(12)`, so

- `unix_ms(snowflake) = (snowflake >>> 22) + @epoch_ms` (`snowflake.ex:107`) — the real Unix-ms of the mint.
- the **low 22 bits** `snowflake &&& 0x3FFFFF` = `node<<<12 | seq` — the full sub-millisecond tail (node in bits
  12–21, seq in bits 0–11).

**The three candidate mappings, reasoned to the ground (probed live — `/tmp/order_probe.exs`, `mix run`):**

| Mapping | XADD id | Same-ms 1-node | Same-ms multi-node | XRANGE-by-time (emq3.6) | Verdict |
|---|---|---|---|---|---|
| **A1** `ms-tail22` | `"#{unix_ms}-#{snowflake &&& 0x3FFFFF}"` | strictly ↑ (tail 28672<28673) | **strictly ↑** (tail 12288<36865) | **PRESERVED** (ms field is real Unix-ms) | **CHOSEN** |
| A2 `ms-seq12` | `"#{unix_ms}-#{snowflake &&& 0xFFF}"` (node dropped) | strictly ↑ within a node | **COLLIDES** (two nodes, same ms+seq → identical id → 2nd XADD **rejected**) | preserved | rejected |
| B `whole-0` | `"#{snowflake}-0"` (snowflake int in the ms field) | strictly ↑ | strictly ↑ | **DESTROYED** (ms field is not a real ms) | rejected |
| C `*` + field | server `*`; branded id a stream FIELD | n/a (server order, not mint order) | n/a | preserved but **server order ≠ mint order** | rejected (forfeits the theorem) |

**Why A1 is the only mapping that satisfies the theorem (the proof obligation, discharged):**

The theorem needs `byte(branded_a) < byte(branded_b)  ⇔  xadd_id(a) < xadd_id(b)`, for every pair, including
same-ms multi-node. Two stacked facts make A1 sound:

1. **Branded byte order == snowflake integer order.** The branded id is `ns ++ base62₁₁(snowflake)`. Base62 here
   is the order-preserving fixed-width-11 codec — *"Lexicographic order equals numeric order"* (`base62.ex:5`),
   alphabet `0-9A-Za-z` whose bytes are themselves ascending (ASCII `0`<`9`<`A`<`Z`<`a`<`z`). So for a **fixed
   namespace** (all records of one stream share the brand), byte order of the 14-byte string == numeric order of
   the snowflake. (Cross-namespace ordering is not required — a stream's records are one kind, §ADR-2.)

2. **A1's XADD id is an order-preserving image of the snowflake integer.** Write `s = ms_part<<<22 | tail22`
   where `ms_part = s >>> 22` and `tail22 = s &&& 0x3FFFFF`. A1 emits `(ms_part + epoch_in_ms_units, tail22)` as
   the pair `(M, T)`. Because the snowflake packs ms in the HIGH bits and the tail in the LOW 22 bits with no
   overlap, `s_a < s_b  ⇔  (ms_part_a, tail22_a) < (ms_part_b, tail22_b)` lexicographically — which is exactly the
   pair XADD compares (XADD orders by `(ms, seq)`, and A1's seq IS `tail22`). The `+epoch` is a constant monotone
   shift on the first component, order-preserving. **∴ `s_a < s_b ⇔ xadd_id(a) < xadd_id(b)`. QED.**

   The same-ms multi-node case is the one that separates A1 from A2: when `ms_part_a == ms_part_b`, A1 falls back
   to comparing `tail22 = node<<<12|seq`, which is distinct across nodes (the 10-bit node field, bits 12–21) AND
   across same-node bursts (the 12-bit seq, the shared monotonic atomics cell `snowflake.ex:7-15,91-99` forces
   seq↑). A2 keeps only the seq → two nodes minting in the same ms with the same seq produce the SAME XADD id, and
   the 2nd append hits the rejection error. **A1 carries the node into the seq field precisely to keep the
   coordination-free "mint on any node" law (the BCS law) collision-free on the wire.** (Probe: A2's pathological
   pair `1782084948024-0` == `1782084948024-0`; A1's `…-12288` vs `…-36864`, distinct.)

**Why not the server `*` (Candidate C, the "store the branded id as a field" arm).** It is the simplest and it is
WRONG for this tier: the server's `<instance-ms>-<seq>` orders by the SERVER's clock and arrival, not the mint —
so two records minted `a < b` on different hosts can land `xadd(b) < xadd(a)` if `b` reaches the server first.
That forfeits the order theorem (`emq.streams.md:57`, the carry-fact), requires a SECOND index (the branded-id
field) to recover mint order, and breaks emq3.6's *"mint-instant → XRANGE bounds"* (the server ms ≠ the mint ms).
The whole tier's economy — *"the sequence is already minted … stream position, sort key, claim, and cache key
stay one value"* (`emq.streams.md:44-48`) — collapses to "the stream has its own position and the branded id is
a payload." Rejected on the design's own thesis.

**Decision.** emq3.2 appends with an **EXPLICIT XADD id derived from the branded record id by field
correspondence (A1)**: `xadd_id = "#{EchoData.Snowflake.unix_ms(snow)}-#{snow &&& 0x3FFFFF}"` where
`{:ok, snow} = EchoData.BrandedId.decode(branded_id)`. The 14-byte branded string is ALSO stored as a stream
**field** (e.g. `id` → the branded form) so a polyglot reader gets the canonical id without re-encoding (the
claims-only contract, `emq.streams.md:42`). The append is therefore: `XADD <key> <ms>-<tail22> id <branded> <…
payload fields>`. **Stream order == XADD-id order == snowflake order == branded byte order — one value, no second
index** (Appendix-F's property extended to the log, `emq.design.md:125`).

**The named failure modes (each gets an INV or a closed-error surface — §ADR-2/§5):**

- **F-A ` id ≤ stream top` rejection.** If a caller appends an id not strictly greater than the stream's current
  top, XADD returns `ERR The ID specified in XADD is equal or smaller than the target stream top item`
  (verbatim, valkey.io). Under A1 this happens ONLY if mint order is violated at the SOURCE — i.e. a branded id is
  appended out of mint order (a stale/replayed id after a newer one already landed), OR the Snowflake clock
  regressed AND the regression carry (`snowflake.ex:14-15`) did not advance past the last-appended tail. The
  writer law MUST surface this as a typed result (`{:error, :nonmonotonic}` — see §ADR-5), never swallow it: it is
  the wire telling the truth that "append == mint order" was violated upstream. This is the load-bearing
  liveness check — a stream that silently accepts an out-of-order append would break the theorem invisibly.
- **F-B same-ms seq exhaustion within a node.** The snowflake seq is 12-bit (4096/ms). Beyond 4096 same-ms mints
  the generator's carry borrows into the timestamp (`snowflake.ex:11-13`), so the snowflake (and thus `unix_ms`)
  advances a few ms ahead — A1 stays monotone (the ms component increments), no XADD collision. **No special
  handling needed; the substrate already preserves strict monotonicity.** (Documented so a reviewer does not
  re-derive it.)
- **F-C tail22 width vs the 64-bit XADD seq.** `tail22 ≤ 0x3FFFFF` (≈ 4.19M) ≪ the XADD seq ceiling
  `18446744073709551615` (valkey.io: 64-bit). **No overflow, with ~42 bits of headroom.** (If a future id layout
  widened the tail, the headroom remains enormous — a non-issue, recorded.)
- **F-D clock skew across nodes.** Two nodes with skewed wall-clocks can mint ids whose `ms` ordering disagrees
  with true wall-time order. This is a property of the BRANDED ID, not of A1 — A1 maps faithfully whatever the
  snowflake says. The theorem is "stream order == MINT order" (the snowflake's own order), not "== true global
  wall-time order"; the latter is not claimed (and cannot be, coordination-free). Stated honestly: **the stream
  reflects mint order exactly; mint order reflects each node's clock, bounded by the same Snowflake regression
  guard the rest of the system already trusts.** No new exposure.
- **F-E cross-namespace appends to one stream.** If a stream received two namespaces (`EVT…` and `ORD…`), byte
  order would compare the namespace bytes FIRST, breaking the snowflake-order ≡ byte-order step. **This is exactly
  why §ADR-2's kind law refuses a wrong-kind id at the door** — one stream, one brand keeps step 1 of the proof
  sound. (The two ADRs are joined: ADR-2 is what makes ADR-1's step-1 hold.)

**Consequences.** The append is host-derived and explicit (no `*`), so the writer owns the id math — a tiny pure
function, doctestable and exhaustively checkable (the order theorem as a property test). The stream needs NO
secondary index for mint order. emq3.6's time-travel is *free*: `unix_ms` IS the XADD ms field, so a mint-instant
window maps straight to `XRANGE <ms_lo> <ms_hi>`. The branded id stored as a field keeps the polyglot codec
trivial. The one cost: the writer must surface the `id ≤ top` rejection as a typed error (F-A) rather than retry —
accepted, because retrying would paper over a real mint-order violation.

---

## ADR-2 — the kind law: wrong-kind refused at the writer's FIRST act, HOST-SIDE (the `EMQKIND`-class analog)

**Context.** The JOB kind law (`emq.design.md:136-137`) refuses a non-`JOB` id as the enqueue **script's first
act**, a typed `EMQKIND` wire reply (*policy before existence before write*). But a stream append is **not a Lua
script** — emq3.1 issues `XADD` direct as a `parts` list, no script (`emq3.1.md:122-124`; ADR-3 keeps it
script-free). So the stream-record kind law cannot be "the script's first act." Two questions: (a) what brand does
a stream record carry, and (b) where/how is wrong-kind refused?

**(a) the brand.** A stream record is an **event** — a recorded, replayable occurrence (`emq.streams.md:24` "game
development wants recorded event streams"). The natural namespace is a 3-letter uppercase brand reserved for
stream records. **`EVT` is the strawman** (events) — but the SPECIFIC namespace string is a fork (FORK-3.2-2): the
brand is a wire-visible contract every polyglot reader sees, and whether the tier uses one brand (`EVT`) or admits
a per-stream configured brand is the Operator's call. The proof in ADR-1 needs only "ONE brand per stream," not a
specific letter.

**(b) the refusal.** The branded-id wellformedness gate already exists host-side: `BrandedId.valid?/1`
(`branded_id.ex:95`) and the keyspace builder `job_key/2` **raises** on a non-branded id (`keyspace.ex:18-24`).
For streams, the writer law adds a **kind** check on top of wellformedness — the record id must be (i) wellformed
AND (ii) of the admitted stream namespace. This is the stream-record analog of `EMQKIND`, but **host-side** (a
guard in `EchoMQ.Stream.append/_`), because there is no script to host a wire refusal and the connector path is
generic (no per-verb hook). Two refusal-shape arms (FORK-3.2-2's companion):

- **B1 (host raise, like `job_key/2`).** A non-`EVT` / non-branded id **raises `ArgumentError` before any wire** —
  symmetric with the shipped `keyspace.ex:18-24` job-key gate (wellformedness raises; the writer extends it with
  kind). Cheap, consistent with the as-built builder, fail-fast at the producer.
- **B2 (typed `{:error, :kind}` return).** The append returns `{:error, :kind}` (mirroring the client-side
  `EMQKIND → {:error, :kind}` mapping seam, `emq.design.md:278`) without raising — softer, composable in a
  pipeline.

**Decision (RECOMMEND, surfaced as FORK-3.2-2).** **One brand per stream (strawman `EVT`), refused HOST-SIDE by a
**raise** before any wire (B1)** — symmetric with the shipped `job_key/2` wellformedness gate (`keyspace.ex:18-24`,
the only as-built precedent for an id-shape gate at a key builder), extended from "is it branded?" to "is it the
admitted stream kind?" The refusal is *the writer's first act* (before the XADD), honoring *policy before
existence before write* in the host where the JOB law honors it in the script. **No new wire class** — `EMQKIND`
is a *script* refusal; the stream writer has no script, so it reuses the host raise the builder already
establishes, and adds NO `EMQ*` registry member (the closed wire-class registry stays `{EMQKIND, EMQSTALE}`,
`emq.design.md:275-279`; an additive wire class would be unjustified — there is no script to issue it).

**Consequences.** One stream = one brand keeps ADR-1's step-1 (byte order ≡ snowflake order) sound by construction
(F-E closed). The kind gate is pure + host-side → trivially unit-testable (a wrong-namespace id raises; a wrong
*shape* raises via `valid?/1`). No wire-class growth, no conformance-registry churn beyond the writer scenario.
The one asymmetry with JOB (host raise vs. script `EMQKIND` reply) is **inherent and correct**: a stream append
has no atomic server-side policy hook, and inventing one (wrapping XADD in a Lua script just to issue `EMQKIND`)
would add a script the tier explicitly avoids (ADR-3) for zero gain — the producer is in-process, so a host raise
reaches it identically to a wire reply.

---

## ADR-3 — the hash-tagged key: `emq:{q}:stream:<name>` formalized (declared-keys soundness, no new script)

**Context.** emq3.1 already founded the key TYPE: `emq:{q}:stream:<name>` via the total `Keyspace.queue_key(q,
"stream:" <> name)` (`keyspace.ex:13-15`, re-probed; `emq3.1.md` INV5; `stream_verbs_test.exs:69`). emq3.2 does
not re-found it — it **formalizes the writer's use of it** and discharges the declared-keys obligation for the
append.

**The grammar (already total).** `queue_key/2` builds `emq:{q}:<type>` for any `<type>` string with the hashtag
applied transparently (`keyspace.ex:14-15`). `stream:<name>` is a §6 braced type (the §6 registry,
`emq.design.md:286-298`, gains `stream:<name>` as a documentation act — NO code edit, the builder is total). The
stream shares the `{q}` hashtag slot with that queue's `pending`/`active`/`job:` keys: `slot(queue_key(q,
"stream:s")) == slot(queue_key(q, "pending"))` (same hashtag → same CRC16-XMODEM slot, `keyspace.ex:44-54`).

**Declared-keys soundness (S-6 / the A-1 law).** emq3.2 adds **NO new Lua script** — the append is `XADD <key>
<id> id <branded> …`, a direct `parts` list through the shipped `Connector.command/3` (ADR-4), exactly as emq3.1
proved. So the declared-keys law (*every Lua key in `KEYS[]` or derived from a declared `KEYS[n]` root*,
`emq.design.md` S-6) is **vacuously satisfied — there are no script keys**. The forward obligation is named for the
rungs that DO add scripts (emq3.3 group reads, emq3.5 archive fold): because the stream shares the `{q}` slot, a
later multi-key script touching `emq:{q}:stream:<name>` alongside `emq:{q}:pending` is **slot-sound by the braces**
(the A-1 root-sharing rule holds by construction). emq3.2 records this as the slot-soundness lemma the later
scripts inherit; it asserts no script key itself.

**The writer addresses the key how.** `EchoMQ.Stream` takes `(queue, stream_name)` (or a stream handle) and builds
the key via `Keyspace.queue_key(queue, "stream:" <> name)` — the SAME builder emq3.1 proved, no new key function.
The branded record id is the XADD *id* (ADR-1), NOT part of the key (a stream is one key holding many records,
unlike a job which is one key per id) — so there is **no `job:`-style per-record subkey** and therefore **no
subkey cleanup disposition to name** (the architect-skill §2 subkey-leak rule is N/A here: the stream is a single
key whose retention is emq3.4's `MAXLEN`/`MINID`, not a per-record subkey that outlives a parent row).

**Decision.** The writer addresses `emq:{q}:stream:<name>` via the shipped total `queue_key/2` (no grammar edit,
no new key function); §6 documents `stream:<name>` as a braced type (already begun at emq3.1); the stream is a
single braced key on the `{q}` slot; emq3.2 adds no script, so declared-keys is vacuous for this rung and the
slot-soundness lemma is recorded for the later script rungs. **The §6 grammar in `keyspace.ex` stays
byte-unedited** (`git diff keyspace.ex` empty — the INV).

**Consequences.** Cluster-correct by construction (one queue, one slot). No keyspace code churn. The retention
question (does the stream key grow unbounded?) is **out of scope — emq3.4** (`MAXLEN`/`MINID`); emq3.2's honest
bound is "the writer appends; retention is declared at emq3.4" — named, not discovered (the architect-skill
cleanup-disposition discipline, applied: the bound is named and correctly deferred).

---

## ADR-4 — the `EchoMQ.Stream` API surface (the writer law; the minimal read-back for the proof)

**Context.** emq3.2 builds the FIRST module of the tier: `EchoMQ.Stream` (does not exist — re-probed). It must
(a) append a branded record in mint order (ADR-1), (b) refuse wrong-kind at the door (ADR-2), (c) address the key
(ADR-3), and (d) expose JUST ENOUGH read-back to GATE the order theorem — the consumer-group lifecycle (groups,
`XREADGROUP`/`XACK`/`XAUTOCLAIM`, at-least-once, crash re-delivery) is **emq3.3, deferred** (`emq.streams.md:70`).

**The surface (sketch — arities/returns are the design's recommendation; the triad fixes them).** The id math is
spec'd as a **pure module**, not a private `defp` buried in IO — the architect-skill §2 verdict-surface rule
(*"a verdict/classification/shaping surface is specced as a pure module … exhaustive + disjoint … the process
method stays a thin router over the pure core"*; precedents `BatchShaper.Core`, `BatchFinish.partition/2`). The
order-theorem mapping is exactly such a surface:

- **`EchoMQ.Stream.Id` (pure, doctested).** The id correspondence, un-spoofable, exhaustively property-testable:
  - `xadd_id(branded :: binary()) :: {:ok, binary()} | {:error, :kind | :malformed}` — decodes the branded id
    (`BrandedId.decode/1`), checks the admitted namespace (ADR-2), returns `"#{unix_ms}-#{snow &&& 0x3FFFFF}"`
    (ADR-1). Pure, total over its input. **The order theorem is its property:** `branded_a < branded_b ⇒ xadd_id
    parts compare the same` (a StreamData/quickcheck property the rung carries).
  - (optionally) `min_id_for(DateTime) :: binary()` / `max_id_for(DateTime)` — the mint-instant→XRANGE-bound
    helpers (`Snowflake.min_for/1` already exists, `snowflake.ex:116-118`); emq3.2 MAY land the lower bound to
    seed emq3.6, or defer wholesale to emq3.6 (a minor scope fork — recommend: land `min_id_for` since
    `Snowflake.min_for` is free, defer the windowed read to emq3.6).
- **`EchoMQ.Stream` (the writer, a thin router over `Stream.Id` + the connector).**
  - `append(conn, queue, name, branded_id, fields :: map() | keyword()) :: {:ok, branded_id} | {:error,
    :kind | :malformed | :nonmonotonic | term()}` — the writer law: refuse wrong-kind (ADR-2, raise or typed per
    FORK-3.2-2) → derive the XADD id (`Stream.Id.xadd_id`) → `XADD <key> <id> id <branded> <fields…>` via
    `Connector.command/3` (ADR-1 stores the branded id as the `id` field). Returns the branded id as the receipt
    (mirroring `Jobs.enqueue` returning the job's branded id). The `id ≤ top` rejection (F-A) maps to
    `{:error, :nonmonotonic}` (§ADR-5).
  - `append!(…)` — the raising twin (FORK-3.2-2 B1 makes this the primary if "raise" wins; B2 makes `append/5` the
    primary and `append!` the raiser). Recommend BOTH, with the primary set by FORK-3.2-2.
  - `read(conn, queue, name, from \\ "-", to \\ "+", count \\ nil) :: {:ok, [{branded_id, fields_map}]} | {:error,
    term()}` — the **minimal read-back for the proof**: an `XRANGE` wrapper that parses the nested-array reply
    (`resp.ex` array branch, the shape `stream_verbs_test.exs:83` already asserts) into `{branded_id, fields}`
    tuples IN MINT ORDER. This is NOT the consumer group (emq3.3) — it is the un-grouped range read that PROVES
    "stream order == id sort" by reading appended records back and asserting their order equals their mint order.
    Recommend `read/3..6`; the branded id in each tuple comes from the stored `id` field (round-trips the append).
  - `append_batch(conn, queue, name, [{branded_id, fields}]) :: {:ok, [branded_id]} | {:error, term()}` — the
    pipelined writer (rides the shipped `Connector.pipeline/3`, emq3.1 INV3 proved the mechanism), appending N
    records with N explicit ids in mint order, returning the N branded receipts. Optional for emq3.2 (the single
    append + the order property is the law); recommend INCLUDE — it is the natural writer shape and emq3.1 already
    certified the pipeline, so it is cheap and proves the order theorem holds across a batch.

**What is OUT (deferred, named — the honest bounds).** Consumer groups + `XREADGROUP`/`XACK`/`XAUTOCLAIM` wrappers
+ at-least-once + crash re-delivery → **emq3.3** (`read/_` here is the un-grouped range read, not a group consumer).
Retention (`MAXLEN`/`MINID`) → **emq3.4** (`append/_` does not trim). The windowed time-travel read → **emq3.6**
(emq3.2 may land `min_id_for` as the seed, defers the read). Object/non-trivial payloads → claims-only is the law
(`emq.streams.md:42`); `fields` are flat string pairs.

**Decision.** Build `EchoMQ.Stream` (the writer + the minimal `XRANGE` read-back for the proof) as a thin router
over a **pure `EchoMQ.Stream.Id`** (the order-theorem mapping, doctested + property-tested), riding the shipped
connector `command/3`/`pipeline/3` (ZERO `echo_wire` edit, ADR-4 inherits emq3.1's FORK-3.1-A ground). Append uses
the explicit A1 id + the branded id as the `id` field; read returns `{branded_id, fields}` in mint order. The
consumer group is emq3.3.

**Consequences.** The writer law is one small module + one pure id core. The order theorem is a property test, not
a single example. The append path is script-free (ADR-3), so the v2 declared-keys/server-clock laws are vacuous
for this rung (no script, no lease). The read-back is deliberately minimal — enough to GATE the theorem, not the
consumer surface (that is emq3.3).

---

## ADR-5 — conformance + the determinism posture (the rung MINTS branded ids → the ≥100 loop APPLIES)

**Context.** emq3.1 added `stream_verbs` (73→74) and stated its honest posture: a multi-seed sweep, NOT the ≥100
loop, because the verb floor mints NO branded id and starts NO process (`emq3.1.md` INV8). **emq3.2 is
different** — it MINTS branded record ids (the append's whole point) and the order theorem's correctness hinges on
the same-millisecond mint behavior. So the same-ms branded-id mint hazard the ≥100 loop owns is **PRESENT**.

**The conformance scenario(s) (additive-minor, S-3/§5).** Prior **74** byte-unchanged → new total. The writer law
is one capability that the order theorem proves; recommend **+1 scenario `stream_append`** (the writer: append N
branded records, read them back in mint order, assert stream order == id sort == mint order; a wrong-kind id
refused at the door). The count delta is a fork companion (FORK-3.2-3): one scenario for the writer law, or a
decomposition (e.g. `stream_append` + `stream_kind_refusal` + `stream_append_order` = +3). **Recommend +1**
(`stream_append`, the writer law as one capability) to match emq3.1's "one scenario per plumbing capability"
precedent, with the order-property and kind-refusal as ASSERTIONS WITHIN that scenario — but flag +3 as the arm
the Operator may prefer for finer audit granularity. The scenario registers WITH its probe in the same change;
both pinning tests re-pin (`conformance_run_test.exs:61` `{:ok, 74}` → the new total +
`conformance_scenarios_test.exs` `@run_order`).

**The determinism posture (HONEST — the ≥100 loop, stated explicitly).** Because emq3.2 mints branded ids in the
append path, ratify with the **≥100 determinism loop** (`for i in $(seq 1 100); do TMPDIR=/tmp mix test
--include valkey || break; done`), NOT merely a multi-seed sweep. The hazard is precisely the same-ms,
multi-mint contention ADR-1's F-A/F-B reason about: a same-ms burst of appends must each derive a strictly-greater
XADD id, and a flaky id-mint collision would surface ONLY across runs. The loop must OWN the machine (no
concurrent liveness server — the program-law caveat). **This is the load-bearing posture difference from emq3.1**
and the rung's spec must state it: emq3.1 minted nothing (sweep sufficed); emq3.2 mints record ids (the loop is
required). An order-theorem PROPERTY test (StreamData over many mint sequences, including forced same-ms via the
`Snowflake.next/1` per-node path) complements the loop.

**Decision.** +1 conformance scenario `stream_append` (the writer law; order-property + kind-refusal as inner
assertions), prior 74 byte-unchanged → **75**, probe-registered, both pins re-set; the determinism posture is the
**≥100 loop** (the rung mints branded ids) PLUS an order-theorem property test. FORK-3.2-3 surfaces the +1-vs-+3
count delta.

**Consequences.** The order theorem is gated three ways: the in-scenario read-back assertion, the property test
(many sequences), and the ≥100 loop (the same-ms mint hazard). The posture is honestly stronger than emq3.1's
because the rung does strictly more (it mints).

---

## ADR-6 — the version label + the risk tier

**Context.** emq3.1 stepped a MINOR `2.5.2 → 2.6.0` (opening the Stream Tier family, FORK-3.1-C ruled). emq3.2 is
the SECOND rung of the family. The wire `@wire_version` is FROZEN at `echomq:2.4.2` (the deferred cutover,
`emq.streams.md:13-16`; emq3.1 INV6) — this is the `mix.exs` rung-LABEL plane only.

**The label (within the Stream Tier family — a within-family PATCH).** By the position-encoded convention (the
implementor skill; the precedent emq.5.1 `2.5.0` opened a family and reset the patch, then 5.2/5.3 stepped patches
`2.5.0`→`2.5.1`→`2.5.2` WITHIN the family): a within-family rung steps a **PATCH**, so emq3.2 steps `2.6.0 →
2.6.1`. The family was already opened by emq3.1's MINOR step; emq3.2 is not a new family, so it patches.
**Recommend `echomq:2.6.1`** (the `mix.exs` label; the `@wire_version` stays `echomq:2.4.2`, the deferred cutover,
unchanged). This is the lens-brief's "a within-family patch, e.g. `echomq:2.6.1`" — confirmed against the
convention.

**The risk tier (a MINT surface — NORMAL+ with the determinism loop, NOT HIGH).** emq3.2 mints branded record ids
and builds a new module (`EchoMQ.Stream`), but: it touches **no frozen line** (ZERO `echo_wire` edit — rides the
shipped connector, ADR-4 inherits FORK-3.1-A); it adds **no new script** (script-free append, ADR-3) → no
declared-keys/byte-freeze-Lua exposure; it performs **no destructive at-rest op** (append-only; retention is
emq3.4); it adds **no new wire class** (ADR-2 reuses the host raise) → no wire break, `@wire_version` frozen. The
ONE elevated property is the **id mint** → the ≥100 loop is mandatory (ADR-5) and the order theorem must be
proven, not asserted. **Recommend NORMAL+** (a mint surface): the gate is the order-theorem property test + the
≥100 loop, not the blast-radius mutation battery (no destructive op) and not the frozen-touch HIGH (no frozen
line). **Apollo is an OPTIONAL fast-finisher** (closure + stories) on this arm — NOT mandatory: emq3.2 is not a
new process/lease surface (no process — a host fn over the connector; no lease — no `TIME`, no fencing token),
not a destructive at-rest op, not a frozen-line touch (the three Apollo-mandatory triggers, program-law). The
mint hazard is covered by the ≥100 loop, which is a GATE, not an Apollo precondition. *(If the Operator judges the
order-theorem correctness high-enough stakes to want an independent adversarial verifier, Apollo becomes mandatory
— a reasonable Operator call given ADR-1 is the rung's whole risk; recommend OPTIONAL but flag the upgrade as the
Operator's discretion.)*

**Decision.** Label `echomq:2.6.1` (within-family patch; `@wire_version` frozen `echomq:2.4.2`). Risk **NORMAL+**
(a mint surface; the gate is the order-theorem property + the ≥100 loop). Apollo OPTIONAL (no
process/lease/destructive/frozen trigger), upgradeable to mandatory at the Operator's discretion given ADR-1's
stakes.

**Consequences.** The lineage marker is honest (a within-family patch, not a second family-open). The risk posture
matches the actual surface (a mint, not a frozen touch or a destructive op), and the determinism loop carries the
mint hazard.

---

## The forks the Operator must rule (four-part; the recommended arm is the strawman the design is authored to)

> ADR-1 is the core; FORK-3.2-1 is its companion (already reasoned to the ground — the recommendation is decisive,
> but the id-mapping is an identity/wire-contract decision, so it is the Operator's to ratify). The other three
> are the kind-brand/refusal shape, the conformance count delta, and (implicitly settled, surfaced for
> completeness) nothing else changes the wire.

### FORK-3.2-1 — the branded-record-id ↔ XADD-id mapping — RECOMMEND: A1 (explicit `ms-tail22`, field-correspondence)

- **Rationale.** THE rung's crux (ADR-1). Either the branded id maps to an EXPLICIT XADD id that preserves mint
  order on the wire (A1 — the order theorem holds, no second index, time-travel free), or the stream uses the
  server `*` id and stores the branded id as a field (C — the server's clock orders the stream, NOT mint order,
  forfeiting the theorem and forcing a second index). A1 is reasoned to the ground above: the only mapping where
  branded-byte-order ≡ snowflake-int-order ≡ XADD-id-order, AND it survives same-ms multi-node mints (the node
  field carried into the 22-bit seq), AND it preserves `unix_ms` as the XADD ms field (emq3.6 time-travel free).
  A2 (seq-only) collides across nodes; B (whole-snowflake-in-ms) destroys time-travel.
- **5W.** *What:* whether the append uses an explicit A1 id or the server `*`. *Who:* `EchoMQ.Stream.append` +
  the pure `Stream.Id`; every later Stream rung + every polyglot reader (the id they sort/range by). *When:* the
  writer law — the founding id contract of the whole tier (every record forever carries this mapping). *Where:*
  `EchoMQ.Stream.Id.xadd_id/1` (the pure mapping) + `append/_` (the XADD call). *Why:* the order theorem
  (`emq.streams.md:57`) is the tier's load-bearing economy — *"the sequence is already minted … one value, no
  second index."*
- **Steelman (the server `*` arm, C).** Using `*` is the SIMPLEST possible writer (no id math, no `id ≤ top`
  rejection to handle), it never fails on non-monotonic appends (the server always picks a fresh top), and the
  branded id lives safely as a field for any reader. For a tier that only needed "append + replay," `*` would
  suffice. **But** it forfeits the theorem the tier is BUILT on: the server orders by its own clock+arrival, so
  mint order ≠ stream order across hosts; recovering mint order needs a second index (the branded-id field, sorted
  separately); and emq3.6's *"mint-instant → XRANGE bounds"* breaks (the server ms ≠ the mint ms). The design's
  thesis — *"two committed mechanics make this tier cheaper here … the sequence is already minted"*
  (`emq.streams.md:44`) — is exactly what `*` throws away. A1's cost (handling the `id ≤ top` rejection as a typed
  error) is a FEATURE: it surfaces a real mint-order violation rather than hiding it.
- **Steward — RECOMMEND A1.** The order theorem is the tier's reason to exist here rather than on a generic broker;
  A1 is the only mapping that delivers it provably (the §ADR-1 proof, the live probe) and survives the
  coordination-free multi-node mint (the node carried into the seq). *Trade-off:* the writer must surface the
  `id ≤ top` rejection as `{:error, :nonmonotonic}` (F-A) rather than silently retry — accepted, because a silent
  retry would paper over a broken theorem. **A1; the server-`*` arm forfeits the rung's entire thesis.**

### FORK-3.2-2 — the stream-record brand + the wrong-kind refusal shape — RECOMMEND: one brand (`EVT`) refused HOST-SIDE by a raise (B1)

- **Rationale.** A stream record needs a namespace (ADR-2), and wrong-kind must be refused at the writer's first
  act (the JOB-law analog). Two sub-decisions: (a) the brand — one reserved namespace for all stream records
  (strawman `EVT`) vs. a per-stream configured brand; (b) the refusal shape — a host raise (like the shipped
  `job_key/2` gate, `keyspace.ex:18-24`) vs. a typed `{:error, :kind}` return. The proof in ADR-1 needs only "one
  brand per stream"; the specific letter and the refusal shape are contract choices.
- **5W.** *What:* the stream namespace string + whether wrong-kind raises or returns typed. *Who:* `EchoMQ.Stream`
  (the gate); every polyglot reader (the brand they see in the `id` field). *When:* the writer law (the brand is
  the record's wire identity forever). *Where:* `EchoMQ.Stream.Id.xadd_id` (the namespace check) + `append/_` (the
  refusal). *Why:* one brand per stream keeps ADR-1's byte-order≡snowflake-order step sound (F-E); the refusal
  shape sets the producer's error ergonomics.
- **Steelman (a per-stream configured brand + a typed return, the softer arm).** A per-stream brand would let
  different streams carry different record kinds (e.g. `ORD` for an order-event stream, `TRD` for trades) — richer
  domain typing; and a typed `{:error, :kind}` (no raise) composes in a `with` pipeline without a rescue. **But**
  the tier's demand is "recorded event streams" (`emq.streams.md:24`) — events, one kind; a per-stream brand is
  additive later (a configured admitted-namespace, exactly the JOB-law's deferred "queue-configured admitted-kind
  set," `emq.design.md:130`) and need not gate the founding writer. And the host-raise matches the ONLY as-built
  precedent for an id-shape gate (`keyspace.ex:18-24` raises) — a producer minting a wrong-kind id has a BUG, and
  fail-fast at the source (raise) is the shipped discipline; a typed return invites swallowing it. The raise vs.
  typed choice is genuinely the Operator's ergonomic call, so it is surfaced — but the design recommends the raise
  for symmetry with the shipped builder.
- **Steward — RECOMMEND one brand `EVT`, host-side raise (B1).** One brand (events) matches the tier's demand and
  keeps the proof sound; the host raise is symmetric with the shipped `job_key/2` wellformedness gate and
  fail-fasts a producer bug at the source; NO new wire class (the closed registry stays `{EMQKIND, EMQSTALE}` —
  the stream has no script to issue a wire class). *Trade-off:* a per-stream brand and a typed return are both
  cleanly additive later (the configured-namespace + a typed `append`); deferring them keeps the founding writer
  minimal. **`EVT` + host raise; the per-stream-brand/typed-return arm is a clean later addition, not a founding
  need.** *(If the Operator prefers a different brand letter or the typed return, ADR-2 + the `Stream.Id`
  namespace check + the `append` signature re-derive — surfaced.)*

### FORK-3.2-3 — the conformance count delta — RECOMMEND: +1 (`stream_append`, the writer law as one capability), 74 → 75

- **Rationale.** The writer law is gated by a conformance scenario (additive-minor, S-3/§5). One scenario for the
  writer capability (append N branded records, read back in mint order, assert the order theorem + a wrong-kind
  refusal — all as inner assertions) vs. a decomposition (`stream_append` + `stream_kind_refusal` +
  `stream_append_order`, +3). emq3.1's precedent: ONE scenario per plumbing capability (`stream_verbs`, +1, with
  the five verbs as inner assertions).
- **5W.** *What:* how many conformance scenarios the writer law registers. *Who:* the conformance harness (74 →
  the new total); both pinning tests. *When:* the writer law. *Where:* `conformance.ex` `scenarios/0` +
  `conformance_run_test.exs:61` + `conformance_scenarios_test.exs`. *Why:* the additive-minor bookkeeping; the
  count is the live total.
- **Steelman (the +3 decomposition).** A scenario per property (append, kind-refusal, order) gates each
  independently — finer audit granularity, and the order theorem gets its OWN named scenario line (a visible
  conformance row asserting "stream order == id sort"). **But** emq3.1's precedent is one scenario per capability
  with the sub-properties as inner assertions (`stream_verbs` bundled five verbs), and the writer law is ONE
  capability (append-in-mint-order); over-decomposing inflates the count without proving more than the bundled
  scenario's assertions already do. The order theorem is BEST proven by a property test (many sequences) +the ≥100
  loop (the mint hazard), not by a single conformance example — so a dedicated conformance row for it adds a name,
  not coverage.
- **Steward — RECOMMEND +1 (`stream_append`, 74 → 75).** One scenario matches emq3.1's per-capability precedent;
  the order theorem + kind-refusal are inner assertions of it, with the DEEP order proof carried by the property
  test + the ≥100 loop (ADR-5). *Trade-off:* +3 would give the order theorem a named conformance row — accepted
  against, because the property test proves it far more thoroughly than one example, and the per-capability count
  convention keeps the harness honest. **74 → 75 on this arm; +3 → 77 if the Operator prefers the decomposition
  (INV / stories re-derive — surfaced).**

> **No fork changes the wire.** The `@wire_version` stays frozen `echomq:2.4.2` (the deferred cutover) under every
> arm; emq3.2 adds NO new script (ADR-3 — the append is direct), NO new wire class (ADR-2 — host raise, the closed
> registry stands), NO destructive op (append-only — retention is emq3.4). The label is `echomq:2.6.1` (a
> within-family patch, ADR-6 — not itself a fork, the convention is unambiguous; surfaced for the lineage record).
> The risk tier is **NORMAL+** (a mint surface; the order-theorem property + the ≥100 loop is the gate); Apollo is
> OPTIONAL (no process/lease/destructive/frozen trigger), upgradeable to mandatory at the Operator's discretion
> given ADR-1 is the rung's whole risk.

---

## Surface citations (every claim grounded — a real module/file, `emq.streams.md`/`emq.design.md`, or `valkey.io`)

- **The order theorem / branded-id canon:** `emq.design.md:15-16` (byte order is mint order), `:125` (the order
  theorem → browse with no second index), `emq.streams.md:44-48,57` (the sequence is already minted; the tier's
  economy).
- **The substrate (the id math):** `snowflake.ex:3` (the `ts(41)<<<22|node(10)<<<12|seq(12)` layout), `:7-15`
  (the shared monotonic atomics cell, same-ms behavior), `:91-99` (`advance` — the CAS), `:107` (`unix_ms`),
  `:116-118` (`min_for` — the emq3.6 seed); `branded_id.ex:3-4` (the 14-byte form), `:55-57` (`decode`), `:95`
  (`valid?`), `:67-81` (`encode`); `base62.ex:5` (lexicographic order == numeric order, the order-preserving
  codec).
- **The keyspace (the stream key):** `keyspace.ex:13-15` (`queue_key/2`, total over `<type>`), `:18-24`
  (`job_key/2` — the only as-built id-shape gate that RAISES, the ADR-2 precedent), `:44-54` (`slot`/`hashtag`).
- **The as-built floor (what emq3.2 stands on):** `emq3.1.md` (the verb floor — FORK-3.1-A ride-generic),
  `stream_verbs_test.exs:69` (the stream key idiom), `:77-84` (XADD `*` id is `<ms>-<seq>`, the proven shape),
  `:144-167` (the pipelined batch in call order); `events.ex:35-36` (`EchoMQ.Stream` named forward in committed
  code); `conformance.ex` + `conformance_run_test.exs:61` (`{:ok, 74}` — the count to re-pin).
- **The engine (cited valkey.io, never memory):** valkey.io/commands/xadd (entry id is `<ms>-<seq>`, both 64-bit;
  explicit ids allowed; `<ms>-*` auto-seq form; rejects an id ≤ the stream top); valkey.io/topics/streams-intro
  (the verbatim rejection error `ERR The ID specified in XADD is equal or smaller than the target stream top
  item`; max id `18446744073709551615-18446744073709551615`; entries stored in increasing-ID order; `<ms>-*`
  example `0-*` → `0-3`).
- **The v2 laws bound unchanged:** `emq.design.md` §6 (braced grammar), S-6 (declared keys — vacuous here, no
  script), §5/S-3 (additive-minor / wire-class registry — no growth), §2 (the kind-law division). The master
  invariant binds emq3.2 unchanged; the wire is frozen.

---

## What I deliberately did NOT decide (the discipline)

- The id-mapping (FORK-3.2-1), the brand + refusal shape (FORK-3.2-2), and the count delta (FORK-3.2-3) are
  SURFACED with recommendations, NOT ruled — they are identity/wire-contract/bookkeeping decisions, the Operator's.
- I authored NO triad (the triad derives from the approved design after the forks are ruled).
- I did NOT consult the sibling architect's draft (dual-architect independence — convergence is confidence,
  divergence is a fork the Director surfaces).
- I wrote NO code and ran NO git (a probe script under `/tmp` only, to reason ADR-1 to the ground — not a tree
  edit).
