# BCS.1 · agent guide

> How to build the B1 batch (`/bcs/ideas`): requirements, do-NOTs, the **verified grounding bank** (the senior
> read every figure below directly in the manuscript chapters — cite from here and the named sources; re-derive
> nothing, invent nothing), per-module briefs, and the verification commands. Spec of record:
> [`bcs.1.specs.md`](bcs.1.specs.md) · chapter doc: [`bcs.1.md`](bcs.1.md).

## References

- The triad: [`bcs.1.md`](bcs.1.md) · [`bcs.1.specs.md`](bcs.1.specs.md) (the module ladder + invariants + DoD).
- The course docs: [`../bcs.md`](../bcs.md) (contract; the identity MUST-NOT list) ·
  [`../bcs.toc.md`](../bcs.toc.md) · [`../bcs.roadmap.md`](../bcs.roadmap.md) (grounding map).
- The design exemplar: `html/bcs/index.html` (copy head/header/footer/scripts; the B0 anatomy in
  [`bcs.0.specs.md`](bcs.0.specs.md)).
- The manuscript chapters (each module's content spine, read-only):
  `../content/bcs1.md` (the Part preface — the chapter landing's spine) · `../content/bcs1.1.md` ·
  `bcs1.2.md` · `bcs1.3.md` · `bcs1.4.md` · `bcs1.5.md` · `bcs1.a1.md`; the canon `../content/contract.md` +
  `../content/vectors.json`; the chapter-side triads `../content/bcs1.1.specs.md`/`.llms.md` and
  `bcs1.3.specs.md`/`.llms.md` (the rungs' own specs — cite, never duplicate).

## Requirements

- **BCS.1-R1** — md mirror first (`docs/echo/bcs/markdown/ideas/<route>.md`), then the HTML, per page.
  [US: BCS.1-US1]
- **BCS.1-R2** — build each page to the ladder in [`bcs.1.specs.md`](bcs.1.specs.md); dives are fixed (D-B1.1),
  not redesigned. [US: BCS.1-US3]
- **BCS.1-R3** — every figure from the bank below or re-verified in the named `content/` file before use.
  [US: BCS.1-US1]
- **BCS.1-R4** — a fresh `BCS…` stamp per page: `apps/jonnify-cms/bin/cms stamp mint --ns BCS` →
  `stamp decode <id>` → update the panel's static timestamp dd. [US: BCS.1-US2]
- **BCS.1-R5** — gate every page with the command below; ship only at STATUS: PASS. [US: BCS.1-US2]

## Do NOT

- Do not copy dark-editorial tokens, fonts, or card classes; copy only built BCS pages (bootstrap: the B0
  exemplar).
- Do not anchor unbuilt routes; defer cross-links to concurrent siblings (the orchestrator restores them
  post-build).
- Do not edit `../content/**`, the course landing, the chapter landing (orchestrator-only), or the TOC.
- Do not fetch anything external; no storage APIs; honour `prefers-reduced-motion`.
- Do not write a figure absent from the bank and the sources; do not assert manuscript Parts IV–VIII or
  chapters 3.4–3.6 as written ("the manuscript plans…").
- Do not run git. Mind the gate traps: the word "just" in visible prose; the literal substring `/future`
  anywhere in the file.

## Per-module briefs + the verified grounding bank

Pager law (all modules): hub prev = `/bcs/ideas`, next = own first dive; dives chain hub → dive1 → … → back to
the hub. Crumbs mirror the route. `Related` links: the chapter landing, the sibling modules **within this
batch only after the orchestrator's restore pass**, and the doors (`/echomq`, `/redis-patterns`, `/elixir`)
where the content meets them.

### B1.1 `system-substrate` — teaches `../content/bcs1.1.md`

Dives: `the-six-gates` · `ownership-on-the-beam` · `the-owner-goroutine`.

Verified figures (source: `bcs1.1.md`, quoting `bcs_rung_1_1_check.out`):
- The transcript, verbatim — G1 reach-through (outside `lookup`/`insert` → `ArgumentError`; `info` reports
  `protection: :private` — metadata visible, data refused) · G2 traveling-object (map/tuple/integer ids →
  `FunctionClauseError` 3/3; inter-store message carried `{:entity, id}` only; `:burned` recorded
  `BRL0NsHLqGoDbd`) · G3 typed (rejects 4/4 as `:invalid`; `GRD` id on the `BRL` store → `{:error, :namespace}`;
  raising twin → `NamespaceError`) · G4 ordered (`page_desc(2000)` == byte-sort desc over 2000 minted ids;
  store holds no clock) · G5 placed (`placement(USR0KHTOWnGLuC)` → `234878118`) · G6 canon (`self_check!` →
  `{:ok, :native}`) · `PASS 6/6`.
- Surfaces: `EchoData.Bcs.gate/2` → `{:ok, snowflake}` | `{:error, :namespace | :invalid}` (+ a raising twin);
  `EchoData.Bcs.PropertyStore` — GenServer, one ETS table `:ordered_set, :private`, keyed by the 14-byte
  branded string; `EchoData.Bcs.Supervisor` — named stores, `one_for_one`.
- The recorded correction: the draft expected `:ets.info` on a private table to refuse outsiders; the platform
  returned full metadata — **"the BEAM guards data, not existence."** No second parser: `parse/1` reports
  `:error` without subclassification.
- Files: `content/echo_data/runtimes/elixir/lib/echo_data/bcs.ex`, `bcs/property_store.ex`,
  `bcs/supervisor.ex`, `bcs_rung_1_1_check.exs` + `.out`.

Sources (refs block): Erlang/OTP `ets` docs `https://www.erlang.org/doc/apps/stdlib/ets.html` · Go codewalk
"Share Memory By Communicating" `https://go.dev/doc/codewalk/sharemem/` · Chassaing (the decider Part VIII
rethinks) `https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider`.

### B1.2 `identity-contract` — teaches `../content/bcs1.2.md`

Dives: `the-namespace-discriminant` · `the-order-theorem` · `placement-not-security` ·
`the-minting-law-and-the-canon`.

Verified figures (source: `bcs1.2.md`; constants per `vectors.json`):
- Wire form: 14 bytes fixed; canonical vector `USR0KHTOWnGLuC`; largest payload `AzL8n0Y58m7` (62¹¹ exceeds
  2⁶³ — the range gate's reason); 65 bytes/key on the measured table; encode 5.14 ns in the canon's Rust.
- Discriminant carried twice: `BrandedId<"USR">` refused where `"CRS"` is required (one compiler error); the
  HTTP gate row `200 / 400 / 400 / 404` with the wrong-namespace 400 before any handler; the substrate's 4/4
  `:invalid` + `{:error, :namespace}`.
- Order theorem: Twitter 2010 promised "roughly sortable"; the contract hardens *roughly* into *exactly* per
  node; the streams window returned its predicted `40960` entries, first `1781000000010-28672`.
- hash32: one finalizer round from MurmurHash3 (xor-shift · the `fmix64` multiply constant · xor-shift ·
  truncate to 32); `234878118` reproduced by Elixir, Rust, C, TypeScript, wasm, Go, and SQL; `0.9586` ns in
  pure Go. **Placement, not security** — invertible round; truncation's 2³² preimages the only veil.
- Minting law: the counter state is timestamp + sequence ONLY — node bits excluded by normative text (an
  unfaithful port once folded them in; the contract encoded the lesson); a drained sequence borrows the next
  millisecond.
- Gate taxonomy: length · namespace · charset · range (the BEAM speaks it coarsely as `:invalid` — the
  no-second-parser decision). Canon: one Rust source, one C reference, one vector file, a conformance suite per
  runtime — membership is passing the suite.
- Carriage: Elixir `<<ns::binary-size(3), _::binary-size(11)>>` + the `~b` sigil (invalid literal fails the
  build); Go `type PrtID string` per namespace, minted by parsing constructors, the load-bearing gate at the
  channel edge.
- There is deliberately **no** `bcs1.2.specs.md` — one authority per fact (`contract.md` is the spec).

Sources: Appleby — SMHasher/MurmurHash3 `https://github.com/aappleby/smhasher` · King — Announcing Snowflake
`https://blog.twitter.com/engineering/en_us/a/2010/announcing-snowflake` · the canon (`../content/contract.md`,
named in prose, not linked as a route).

### B1.3 `id-system` — teaches `../content/bcs1.3.md`

Dives: `the-new-hash-table` · `the-measured-table` · `the-chooser` · `the-streams-horizon`.

Verified figures (source: `bcs1.3.md`, quoting `bench/valkey-id/` outputs):
- Setup: Redis 7.0.15 vs Valkey 9.1.0, both jemalloc 5.3.0, one million keys per shape, constant 8-byte value,
  `used_memory` delta per key.
- The table, verbatim rows (fmt · keylen · redis7 · valkey8.1 · saved): `brd14 14 88 65 23` ·
  `u64dec 19 104 73 31` · `uuid36 36 120 97 23` · `uuid16 16 104 65 39` · `ulid26 26 104 81 23` ·
  `emq26 26 104 81 23` · `brd14+ttl 14 128 99 29`.
- The 8.1 table: 64-byte buckets of up to seven entries; 8-byte metadata (one child-pointer bit, seven presence
  bits, seven one-byte secondary hashes — 1-in-256 false positives); the `dictEntry` gone — one allocation, two
  memory reads; incremental rehash / `SCAN` / sampling kept; keys ≥128 bytes pre-reserve an expire slot
  (`KEY_SIZE_TO_INCLUDE_EXPIRE_THRESHOLD`, `object.c:47`, the 8.1.8 tree). Publication headline ≈20 bytes saved
  per pair, ≈30 with TTL. jemalloc's 16-byte classes make cost a staircase.
- Findings: the branded form **ties binary UUID-16** (65 vs 65) while staying printable, typed, ordered;
  **beats its own decimal** (65 vs 73); canonical UUID-36 pays two classes (97 — 32 bytes/key, 3.2 GB per 10⁸
  keys before replication); the 26-byte `emq:{q}:job:` envelope lands at 81 — the prefix budget is a design
  surface (the chapter spec's INV-K2; decimal renderings banned from keys, INV-K1).
- The chooser: UUIDv7 the strongest outsider (ordered, uncoordinated; pays two classes as text, unreadable as
  binary, no namespace, no placement contract); the branded snowflake the only row with every column filled.
- Streams: `s_auto` 20 bytes/entry == `s_brd` 20 bytes/entry; window `[+10ms, +20ms)` returned `40960` of
  `40960` expected; first id `1781000000010-28672` (node 7 << 12 | seq 0); the injection `unix_ms(snow)` dash
  `low-22-bits(snow)` (the one stream-id scheme, INV-K4).
- Key recipes (quote from the chapter's How): Elixir `"emq:{" <> queue <> "}:job:" <>
  EchoData.Snowflake.next_branded("ORD")`; Go `"emq:{" + queue + "}:job:" + brandedid.MustEncode("ORD", snow)`.

Sources: Söderqvist — A new hash table `https://valkey.io/blog/new-hash-table/` · Valkey 8.1.0 GA
`https://valkey.io/blog/valkey-8-1-0-ga/` · Streams intro `https://valkey.io/topics/streams-intro/` · XADD
`https://valkey.io/commands/xadd/`. Door: the engine under EchoMQ → `/echomq`; the sorted-set/key patterns →
`/redis-patterns`.

### B1.4 `ecs-to-bcs` — teaches `../content/bcs1.4.md`

Dives: `the-handle-at-its-best` · `the-three-deaths` · `the-translation-table`.

Verified figures (source: `bcs1.4.md`):
- West 2007 (the founding component article): at five percent CPU cost, *"we allowed the components to store
  pointers to one another"* — the traveling pointer admitted under frame-rate duress.
- Weissflog 2018: *"the systems being the sole owner of their memory allocations"*; index-handles with a
  per-slot generation counter (the November 2018 update); the check *"isn't waterproof"* — detection, not
  prevention.
- The three deaths: the save file (handles → swizzling pass; generations serialize into noise) · the socket
  (entity 4117 on machine A names nothing on machine B; mapping tables at both ends — the dialect,
  self-inflicted) · the foreign store (a handle cannot be a foreign key → serials, `created_at` columns = the
  second clock, per-table shard keys = the routing table, and the silent join with no compiler in reach).
- The diagnosis: a handle is placement + liveness wearing identity's clothes; the minting law never reuses a
  name, so ABA is unrepresentable — generation counters rejected **by subsumption**.
- The translation table (the convention of record): entity → identity · component → property in some system's
  table · system → system with a hard boundary · world → the supervision tree + the bus · archetype → data
  composition (Part II, 2.4) · query across components → a message join by identity.
- The litmus: *must this id outlive the process?* Hybrids legitimate strictly behind the boundary.
- Reused figures (already banked): 65 bytes/key; `234878118` at `0.9586` ns; `200 / 400 / 400 / 404`; 2000
  mints paged in exact byte-sort order.

Sources: West — Evolve Your Hierarchy
`https://cowboyprogramming.com/2007/01/05/evolve-your-heirachy/` · Weissflog — Handles are the better pointers
`https://floooh.github.io/2018/06/17/handles-vs-pointers.html`.

### B1.5 `time-inside-the-name` — teaches `../content/bcs1.5.md`

Dives: `the-41-bit-horizon` · `the-law-of-two-clocks` · `the-floor-and-the-third-clock`.

Verified figures (source: `bcs1.5.md`; decode vector per `vectors.json`):
- The arithmetic: 41 bits of milliseconds above epoch `1704067200000` (2024-01-01) ≈ 69.7 years → exhausts
  **September 2093**; the successor epoch is a contract amendment + wire-version bump + drain-and-switch lane —
  a planned chapter, never an incident.
- The decode vector: `USR0NgWEfAEJfs` → snowflake `320636799581945856` → `unix_ms` `1780512970164`.
- **The law of two clocks:** identity time is the id's (when this architecture first named the entity); event
  time is data (someone else's clock, carried as a property). Lamport 1978: happened-before "define[s] a
  partial ordering of the events" — order is a construction, not a wall-clock reading.
- The monotonic mint floor (policy of record): a backwards wall clock (NTP step, VM migration) holds or borrows
  above the last-issued millisecond, never re-issues; fleet half = slewed corrections + monotonic sources.
- The third clock: a TTL is the **store's** time — `brd14+ttl 14 128 99 29` on the measured table (an expire is
  plus-34 bytes of object growth, not a second table); retention sweeps choose by id arithmetic, expiry
  executes by the store — deliberately unmerged.
- `min_for` cursors (quote from the chapter's How): Elixir
  `fn ms -> Bitwise.bsl(ms - 1_704_067_200_000, 22) end`; Go `uint64(ms-1704067200000) << 22`. The litmus:
  *whose clock is authoritative for this claim?* No `created_at` beside an id for "first named" — `unix_ms` is
  the accessor.

Sources: Lamport — Time, Clocks, and the Ordering of Events
`https://dl.acm.org/doi/10.1145/359545.359563` · Valkey Streams intro
`https://valkey.io/topics/streams-intro/`.

### B1.6 `branding-beats-its-own-integer` — teaches `../content/bcs1.a1.md`

Dives: `the-two-renderings` · `the-five-runtimes` · `the-whole-system-accounting`.

Verified figures (source: `bcs1.a1.md`, quoting `bench/branding-vs-decimal/` outputs):
- The derivation: the branded rendering is exactly 11 divmods by 62 into fixed positions 3–13 of a 14-byte
  buffer + a 3-byte namespace copy; the decimal rendering is ~19 divmods by 10 into a width known only at the
  end.
- The measured table (branded · decimal · output file): C (cc 13.3, `-O2`) `7.21` vs `20.49` ns/op (itoa) —
  **2.8×**, `c_bench.out` · Rust 1.75 `5.14` vs `21.77` itoa / `31.61` `to_string` — **4.2×** / 6.1×,
  `rust_bench.out` · Go 1.22.2 `40.02` vs `48.29` `FormatUint` / `25.87` `AppendUint` (a split across API
  regimes — allocation, not alphabet; the append-style branded encode is a recorded follow-up, not a claim),
  `go_bench.out` · Elixir (native) `132.5` vs `133.6` — a tie, `elixir_bench.out` · Node 22 (pure TS) `381` vs
  `45.6` (BigInt `toString`) — the one loss, **8.4×**, in exactly the place the contract prescribes the wasm
  crossing (the `encode` export is the carried follow-up), `node_bench.out`.
- The five surfaces, with file:line (quote verbatim): `contract/include/branded_id.h:37` ·
  `contract/branded-id-rs/src/lib.rs:71` · `runtimes/go/brandedid/brandedid.go:40` ·
  `runtimes/elixir/lib/echo_data/branded_id.ex:67` · `runtimes/node/branded_id.ts:82`.
- The whole-system accounting: per-life return fixed — 8 bytes per key at rest (65 vs 73), 5 bytes on every
  wire hop; the worst case amortizes — a Node service minting ten thousand ids a second spends 3.35
  milliseconds of CPU per second, a third of one percent of a core.

Sources: Söderqvist — A new hash table `https://valkey.io/blog/new-hash-table/` (the size-class step the
storage rows ride); the storage record is Chapter 1.3's (`/bcs/ideas/id-system` once built — the sibling link
the orchestrator restores).

## Agent stories

- **BCS.1-AS1 [implements BCS.1-US3]** — Per module: author the md mirrors (hub + dives), then the pages,
  copying the design from the named model. Acceptance gate: every figure on the pages appears in this bank or
  the named manuscript file, character for character.
- **BCS.1-AS2 [implements BCS.1-US1]** — Interactives per surface: hub ≥1, dive ≥2, pure functions over the
  module's own fixed dataset (the transcript lines, the table rows, the cursors), live readout, static
  degrade.
- **BCS.1-AS3 [implements BCS.1-US2]** — Gate, then self-audit: figure provenance, identity leak, clamp
  spacing, route-tag form, stamp decode, md mirror present.

## Build order

1. Orchestrator: chapter landing (`/bcs/ideas`) from this triad — gate it.
2. Wave 1 (≤2 agents): B1.1 + B1.2. Wave 2: B1.3 + B1.4. Wave 3: B1.5 + B1.6. (Defer cross-sibling links;
   restore after each wave lands.)
3. Orchestrator: restore deferred links → relink the course landing (B1 card + footer) → sync
   [`../bcs.toc.md`](../bcs.toc.md) → final verification.

## The verification sequence

```bash
# Gate (per page; all ten must PASS)
FLAGS="--routes-from /bcs=html/bcs --routes-from /echomq=html/echomq --routes-from /redis-patterns=html/redis-patterns --routes-from /elixir=elixir --chapter-alias b1=ideas,b2=elixir-core,b3=bus,b4=cache,b5=go,b6=node,b7=fly,b8=trading --require-refs"
apps/jonnify-cms/bin/cms check ${=FLAGS} html/bcs/ideas/<path>.html

# Stamp (per page)
apps/jonnify-cms/bin/cms stamp mint --ns BCS && apps/jonnify-cms/bin/cms stamp decode <id>

# Batch audits (all must return nothing)
grep -rn '/future' html/bcs/ideas/
grep -rnEi '\b(revolutionary|blazing|magical|simply|just|obviously|effortless)\b' html/bcs/ideas/
grep -rn 'localStorage\|sessionStorage\|Cormorant\|Manrope\|PT Serif' html/bcs/ideas/
grep -rnE 'clamp\([^)]*[0-9](\+|-)[0-9]' html/bcs/ideas/
grep -rnE '\b(store|gate|connector|system|boundary|bus|id) (sees?|wants?|knows?|decides?)\b' html/bcs/ideas/

# Live crawl (server on :8765; 000 = server down, not route missing)
curl -s -o /dev/null -w '%{http_code}\n' localhost:8765/bcs/ideas
```

## Comprehensive prompt

Build your assigned B1 module of the BCS course. Read [`bcs.1.specs.md`](bcs.1.specs.md) (your module's row in
the ladder is your structure — do not redesign it), your manuscript chapter under `../content/`, and your
module's section of this guide (your verified figures and sources). Author the md mirrors first
(`docs/echo/bcs/markdown/ideas/<route>.md`), then the pages, copying the contract-sheet design from the named
built BCS page — never another course. Quote every figure verbatim from the bank; render evidence in
source-labelled `figure.frozen` blocks; mint and decode-verify a fresh `BCS…` stamp per page; keep every
internal link resolving (defer sibling links per your brief). Gate each page with the command above; ship only
at STATUS: PASS. Touch only your module's routes. Never run git.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.1.md · Spec: ./bcs.1.specs.md
