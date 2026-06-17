# echomq-protocol-record-hash — AAW scope ledger

## {echomq-protocol-record-hash-decisions} Decisions

### D-1 — The record-hash grounding floor (verified, all real code; no [RECONCILE])

VERIFIED in echo/apps/echo_mq/lib/echo_mq/jobs.ex + keyspace.ex + emq.design.md:
- The record key: EchoMQ.Keyspace.job_key/2 → emq:{q}:j:<id>  (job_key builds queue_key(queue,"job:") <> branded; the public key form is emq:{q}:job:<id> as the @claim/@complete/promote scripts derive it, p .. 'job:' .. id; the brief states emq:{q}:j:<id> — the ACTUAL on-disk form is emq:{q}:job:<id>. I teach the REAL form: job_key/2 → queue_key(queue,"job:") <> id → emq:{q}:job:<id>. NOT the brief's :j: shorthand.)
- The job record is a Valkey HASH written by the @enqueue Lua: HSET KEYS[1], 'state','pending', 'attempts','0', 'payload', ARGV[2] → EXACTLY THREE FIELDS at creation: state, attempts, payload. Confirmed; no others in @enqueue. (emq.design.md line 213-214: "the three-field job hash (state, attempts, payload)".)
- state: lifecycle position. @enqueue writes 'pending'; @claim HSET 'active'; @schedule 'scheduled'; @retry 'dead'/'scheduled'; reprocess 'pending'. The state machine on one field.
- attempts: the retry fence AND the fencing token. @enqueue '0'; @claim HINCRBY attempts 1 (mints the token, returned to the worker); @complete/@retry/@extend_lock check att ~= ARGV[2] → EMQSTALE. emq.design.md line 216: "attempts as the fencing token".
- payload: opaque caller cargo (ARGV[2]). Never interpreted by the wire. emq.design.md line 260: "the cargo law". @claim returns HGET payload to the worker verbatim.
- HONEST extension fields (written by OTHER transitions, not @enqueue): last_error (HSET by @retry on failure), progress (HSET by update_progress), group (lane membership), parent/parent_queue/parent_policy (flow children). I name the three-field CORE row as the record; note that lifecycle transitions add a small fixed set of further fields — true to code, no invention.

BRIDGE: brief says R7 data-modeling → the EchoMQ record. Door map confirms R7→E1 secondary. R7 (data-modeling) is NOT built on disk (html/redis-patterns has only caching/coordination/queues/time-delay-priority/overview). So the .bridge <strong>-names R7 (no href) and hard-links the BUILT /redis-patterns + /redis-patterns/overview/patterns-become-protocol. INV: link only built redis routes.

DISCIPLINES: as-shipped no versions; extract-and-annotate (Elixir fn + two-beat Lua, no file:line); zero [RECONCILE] in HTML (all real); no-invent (never echo/apps/echomq frozen tree).

## {echomq-protocol-record-hash-complete} Complete

### Z-1 — Module the-record-hash BUILT (hub + 3 dives), all gates PASS

DELIVERED (8 files):
- html/echomq/protocol/the-record-hash/{index, the-hash-and-its-fields, the-state-and-attempts, the-payload}.html
- docs/echo_mq/course/markdown/protocol/the-record-hash/{index, the-hash-and-its-fields, the-state-and-attempts, the-payload}.md (md-first source-of-record)

GATES: all four pages STATUS: PASS — 10/10 each (containers, svg, no-future, voice, storage, motion, degrade, links, pager, refs). links PASS on all incl. the hub (the 4 footer sibling hubs the-owned-keyspace/the-lua-layer/immutability-and-branded-ids/workshop EXIST on disk → no dangle).

GATE-INVISIBLE (read-verified): node --check OK on all 8 inline scripts; no version label; no file:line; frozen-tree scrub = 0; zero [RECONCILE] in HTML; clamp spaced; every Lua block paired with a named handle (@enqueue/@claim); route-tags segmented+correct; pager loop closed (hub→fields→state→payload→hub, hub prev=/echomq/protocol); crumbs EchoMQ › The Protocol › The record hash › <dive>; no perceptual verb on a component (the one "understand" is the opaque-cargo NEGATION).

GROUNDING (byte-exact vs echo/apps/echo_mq/lib/echo_mq/jobs.ex + keyspace.ex): @enqueue HSET state/attempts/payload (3 fields, verified line 21); @claim body (HINCRBY token mint, lines 127-136); @complete fencing att~=ARGV[2]→EMQSTALE (lines 178-180); enqueue/4, claim/3 Elixir extracts; job_key/2 → emq:{q}:job:<id>. Surfaces cited = EchoMQ.Jobs.enqueue/4, .claim/3, EchoMQ.Keyspace.job_key/2 — all real, correct arity.

BRIDGE: R7 Data Modeling (NOT built on disk → <strong>-named, no href) → the EchoMQ record; hard-links the BUILT /redis-patterns + /redis-patterns/overview/patterns-become-protocol. [RECONCILE] re-point lives in md only.

INTERACTIVES: hub 1 (field picker); each dive 2 (hero + main): fields=field-picker+HGET-by-name; state=transition→state + token-fence(EMQSTALE); payload=round-trip + opaque-vs-protocol. All pure fns over fixed datasets, live aria-live readouts, degrade, reduced-motion, no storage.
