# BCS.3 · spec of record

> The authoritative spec for the B3 chapter (**The Bus — EchoMQ, Valkey-native**, `/bcs/bus`): deliverables,
> invariants, the module ladder with the fixed dive partition, the acceptance stories folded in, and the
> Definition of Done. **All seven modules are manuscript-ready** — Part III is fully written — built in waves
> of ≤2 per `/bcs-write` run. Chapter doc: [`bcs.3.md`](bcs.3.md) · agent guide (with the verified grounding
> bank): [`bcs.3.llms.md`](bcs.3.llms.md).

## Deliverables

- **BCS.3-D1 — The chapter landing.** `html/bcs/bus/index.html` (+ md mirror `../markdown/bus/index.md`):
  Part III's teaching arc (the six laws of the part → the seven modules) over seven module cards (unbuilt ones
  non-anchor `soon`), an "Up next" grid (B4–B8 per current build state), ≥1 interactive, References, pager
  (prev `/bcs/elixir-core`, next the first built hub), full chrome. Orchestrator-only; bootstraps its design
  from the built B2 chapter landing. [US: BCS.3-US1]
- **BCS.3-D2 — Seven module hubs.** One per ladder row, each: the module's framing from its manuscript chapter,
  its three dive cards, ≥1 interactive, a frozen-transcript evidence block (the rung record), References, pager
  (prev = chapter landing, next = own first dive). [US: BCS.3-US1]
- **BCS.3-D3 — Twenty-one dives.** `<module>/<sub>.html` per the ladder's dive column (three per module), each a
  full lesson: the manuscript's material for that slice, ≥2 interactives, verbatim evidence, References, a pager
  chaining hub → dive1 → dive2 → dive3 → hub. [US: BCS.3-US1]
- **BCS.3-D4 — The relink + sync + verification.** The course landing's B3 card flips to a live link (footer
  column too) when the chapter's first batch ships, the chapter landing's module cards flip per batch,
  `bcs.toc.md` tracks built modules, and every batch passes the verification sequence in
  [`bcs.3.llms.md`](bcs.3.llms.md). [US: BCS.3-US2]

## The module ladder (the fixed dive partition — D-B3.1)

| Module | Slug · route under `/bcs/bus/` | Manuscript | What it adds | Dives |
|---|---|---|---|---|
| **B3.1** | `fence-and-keyspace` | `bcs3.1.md` | the connector substrate as the part's vocabulary; the `PASS 5/5` rung (F1–F5) | `the-key-grammar` (F1 the map — `emq:{q}:<type>`, the 17-byte prefix, `{emq}:` reserved for deployment facts; F2 the gate at the job position — wellformedness at the key, kind policy at the script) · `the-fence-live` (F3 `GET {emq}:version answers echomq:2.0.0` through the fenced connector itself — the self-referential proof; F4 binary discipline — CRLF/NUL payloads `500/500` through real job keys) · `the-co-location-law` (F5 the hashtag is the queue — `{orders}` all answer `slot 105`, `{fills}` `4165`, `vector 12739 holds`; multi-key scripts stay single-slot legal on the clustered day) |
| **B3.2** | `jobs-are-entities` | `bcs3.2.md` | `JOB` registered (D-10); work as a kind; the `PASS 5/5` rung (J1–J5) | `the-job-row` (the boot line — the registry grows by one; J1 the surface `enqueue, browse, pending_size`; the three-field hash `state/attempts/payload` — no `enqueued_at`, the two-clocks law already placed it) · `enqueue-one-script` (the ten-line Lua quoted whole; J2 idempotency — `duplicate` as a success shape; J3 the `EMQKIND` wire class discovered live — "the key let it pass, the law did not"; policy before existence before write) · `the-orders-dividend` (J4 the score-zero pending zset — FIFO + browse + time index in one, `301 pending, no second index anywhere`; J5 the cargo law — `ORD0Nt6z93U3dY` and a quantity, never a row) |
| **B3.3** | `state-machine` | `bcs3.3.md` | four states, four transitions, two pumps, every one a single script; the `PASS 6/6` rung (L1–L6) | `claim-the-token-mint` (L1 the surface — five new verbs; L2 the happy path; the claim script quoted whole — server `TIME`, `HINCRBY` minting the token, the constructed-key exception sanctioned by the co-location law) · `the-fencing-token` (L3 the zombie — token 99 earns `EMQSTALE`, "the lease holder's work survives the zombie's complete"; L4 two lives one counter — retry → schedule → promote → token 2; Kleppmann's monotonic-token argument) · `the-morgue-and-the-reaper` (L5 `attempts 2 against max 2 is the morgue: state dead, last_error kept`; L6 the 40 ms lease reaped — "crash recovery is one zset scan on the server's clock"; completion deletes, pre-stating 3.5) |
| **B3.4** | `fair-lanes` | `bcs3.4.md` | fairness as a construction; the `PASS 8/8` rung (G1–G8) | `the-ring-and-the-rotation` (G1 the six verbs + the supervised consumer; G2 twelve claims, four full turns, strict rotation; G3 the headline — the quiet lane's last job at `position 40 of 420` vs the flat queue's first at `position 401 -- rotation is the refusal`; DRR as the prior art) · `ceilings-and-pauses` (G4 `limit 2 holds` — the ceiling parks the lane, one complete reopens it; G5 pause/resume — backlog intact at depth 3, "stopping new claims and killing live work are different verbs") · `park-dont-poll` (G6 the economics — `0 commands` parked vs `37` polled, the wake answers in `0 ms`; G7 the loop owns the rhythm — reap and promote on the beat; G8 the reap window closed — "no ghost in the lane, none in pending") |
| **B3.5** | `bus-meets-stores` | `bcs3.5.md` | the loop closed — commands out of entities, results back into properties; the `PASS 6/6` rung (B1–B6) | `the-round-trip` (B1 the surface grows `stop`; B2 a fill leaves as two names and two numbers and lands as two property writes — "the row on the bus gone"; completion-deletes collected) · `exactly-once-by-name` (B3 the torn middle — `qty 12 once, never 17`; the provenance guard — a row that remembers the names it has absorbed; Helland's recipient-remembers, answered with a name) · `one-more-owner` (B4 the tree drill — the consumer killed mid-fill, restored alone, `qty lands 15 exactly once with token 2`; B5 the audit dividend — five fills page newest-first carrying the `JOB` that wrote them; B6 stop is a drain on both paths) |
| **B3.6** | `conformance` | `bcs3.6.md` | the referee's table; the `PASS 6/6` rung (C1–C6) + `CONFORMANCE 14/14` | `the-committed-harness` (C1/C2 — fourteen wire-level contracts a port can drive verbatim; the harness drew blood on day one — the cold-cache `NOSCRIPT` defect, fixed and pinned with `SCRIPT FLUSH`) · `the-referee-habit` (the derive lines committed before the measurements; C3 the bus inside its bands — `11422` sequential, `78980` batched; the confessed miss — the rival's batched band re-derived in the open) · `the-rivals-numbers` (the asymmetry stated first; C5 the four ratios — sequential `11422/s vs 619/s`, batched `78980/s vs 13716/s`, median `0.3 ms vs 8.8 ms`, drain `6092/s vs 944/s` — "the rival's slower row is the durable one"; C6 the advantage in its own row — `Ecto.Multi`, rollback erases both, "the bus cannot say this sentence") |
| **B3.7** | `the-connector` | `bcsA.md` (Appendix A) | the substrate the part stands on; the connector gate (`emq_connector_check.out`, `PASS 8/8`) | `resp-one-pass` (RESP2 encode as iodata, one-pass parse, `:incomplete` continuation, errors as values; pipelining as the primitive — the pending FIFO, `10000-command pipeline returned 1..10000 in order`) · `the-typed-fence` (the fence typed and fatal — `{:error, {:version_fence, got}}`; EVALSHA-first declared-keys scripts — `script_loads=1`; the keyspace composing with the canon — `job_key/2` refusing what `valid?/1` rejects) · `measured-on-the-wire` (`29456` sequential vs `454483` pipelined vs `161192` EVALSHA ops/s; `prefix = 17 bytes`; `slot 105 == 105` vs `8507`, vector `12739`; the supervised restart re-fencing) |

Pager chain: chapter landing pager prev `/bcs/elixir-core` · next the first built hub; hub prev = chapter
landing, next = own first dive; dives chain hub → dive1 → dive2 → dive3 → back to the hub.

## Invariants

- **BCS.3-INV1 (figures verbatim)** — every number, id, gate line, key shape, Lua line, and transcript line is
  quoted exactly as the grounding bank in [`bcs.3.llms.md`](bcs.3.llms.md) records it from the committed
  sources; each module's rung record is quoted character for character in a source-labelled `figure.frozen`
  block on its hub. Agents cite the bank and the sources, re-derive nothing, invent nothing.
- **BCS.3-INV2 (full links PASS at every state)** — unbuilt routes are never anchored: module cards flip to
  links only when their batch is green; concurrent-wave siblings defer cross-links (orchestrator restores them
  post-wave); the course-landing relink follows the first green batch.
- **BCS.3-INV3 (identity)** — every page copies the contract-sheet system from a built BCS page (bootstrap: a
  built B2 page of the same surface); none of the dark-editorial MUST-NOT tokens appear.
- **BCS.3-INV4 (chrome + stamps)** — segmented clickable route-tag, canonical 3-column footer, a fresh `BCS…`
  stamp per page (minted + decode-verified), the static timestamp dd updated.
- **BCS.3-INV5 (md-first)** — `docs/echo/bcs/markdown/bus/<route>.md` exists for every page, authored before
  its HTML.
- **BCS.3-INV6 (living status + boundaries)** — nothing under `content/` is edited; Appendix B, EMQ 3.0
  Streams (D-3), and Parts V–VIII take the living-status voice; protocol depth doors to `/echomq`, substrate
  patterns to `/redis-patterns`, the umbrella to `/elixir` (D-B3.5).
- **BCS.3-INV7 (the asymmetry travels)** — any page quoting a B3.6 rival figure also carries the record's
  asymmetry line (D-B3.3).

## Acceptance stories (folded)

- **BCS.3-US1 — The reader.** As a reader who has B1's contract and B2's stores, I want Part III's bus taught
  as a chapter — landing → module → dive — with the manuscript's own rung evidence on every page, so that the
  keyspace grammar, the idempotent enqueue, the fencing token, constructed fairness, the provenance guard, and
  the referee's two-column page are learnable without opening the repository.
  - Given a batch ships, when I open `/bcs/bus`, then its modules are live cards and their dives resolve; when I
    open any dive, then its figures match the committed outputs character for character.
  - Given JavaScript is disabled, when I open any B3 page, then every section is readable and the interactives
    degrade to static diagrams.
  - Encodes BCS.3-INV1, BCS.3-INV3. Priority: must · Size: 8 · Implements: BCS.3-D1, BCS.3-D2, BCS.3-D3.
- **BCS.3-US2 — The Operator.** As the Operator, I want every batch gated and the views synced, so that the
  course's living maps stay truthful.
  - Given any page in a batch, when the gate command runs, then it reports STATUS: PASS on all ten gates.
  - Given a batch completes, when I open `/bcs`, then the B3 card state is truthful and `bcs.toc.md` matches the
    tree.
  - Encodes BCS.3-INV2, BCS.3-INV4, BCS.3-INV5. Priority: must · Size: 3 · Implements: BCS.3-D4.
- **BCS.3-US3 — The authoring agent.** As a module agent, I want a brief that names my manuscript chapter, my
  dives, my verified figures, my sources, and my pager, so that I build without re-deriving structure or facts.
  - Given [`bcs.3.llms.md`](bcs.3.llms.md), when I author my module, then every fact I cite appears in the bank
    or in the named manuscript file, and my pages touch only my module's routes.
  - Encodes BCS.3-INV1, BCS.3-INV6, BCS.3-INV7. Priority: must · Size: 2 · Implements: BCS.3-D2, BCS.3-D3.

Coverage: D1→US1 · D2→US1,US3 · D3→US1,US3 · D4→US2.

## Definition of Done (the full chapter)

- [ ] 29 md mirrors under `docs/echo/bcs/markdown/bus/` (landing + 7 hubs + 21 dives), each authored before its
  HTML.
- [ ] 29 pages under `html/bcs/bus/`, each STATUS: PASS via the exact command in
  [`bcs.3.llms.md`](bcs.3.llms.md).
- [ ] Figure-provenance audit: every number on every page re-found in its committed source — the seven records
  (six rungs + the connector gate) quoted verbatim.
- [ ] Identity audit: `grep -rn 'Cormorant\|Manrope\|PT Serif' html/bcs/bus/` empty; no `.chap`/`.mods`/`.mod`.
- [ ] 29 fresh `BCS…` stamps, each decode-verified.
- [ ] Course landing relinked (B3 card + footer) and chapter landing relinked per batch, re-gated PASS;
  `bcs.toc.md` synced.
- [ ] Live crawl: every new route 200 on `:8765`; `/bcs` still 200.
- [ ] No manuscript file, ledger, shared asset, or sibling-course file touched. No git commands run.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.3.md
