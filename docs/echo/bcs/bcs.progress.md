# BCS course — progress
<show-structure depth="2"/>

Status of the served course at `/bcs`. The shape is **Landing → Chapters (B0–B8) → 3 Dives each**. Each chapter ships an HTML chapter page, three HTML dive pages, and one Writerside transcript `bcs.<N>.md`. Every HTML page passes `course_lint` (slug · svg · no-dump · doors · grounding · balance, exit 0); every transcript passes the voice `sweep` (exit 0).

The chapter map was re-derived from the fiberfx repo (`echo/apps`, `docs/echo_mq/emq.roadmap.md`): the apps are `echo_data`, `echo_mq`, `echo_store`, `echo_graft`, `echo_wire`, `echo_bot`, `codemojex` — there is **no `echo_cache` app** (the cache is an EchoMQ family, `emq.7`), so the durable-store chapter is **EchoStore**, and the integration, game, and deployment chapters land on **codemojex**.

## Summary

- **Landing**: built.
- **Chapters complete**: **6 standard** (B0, B1, B3, B4, B5, B6 — page + 3 dives + transcript) plus **B2**, the special 3-level chapter (landing → 6 modules → 3 dives each); **B2.1 built** (module + 3 dives), B2.2–B2.6 ahead.
- **Dives written**: **21** across the standard chapters (B0/B1/B3/B4/B5/B6 × 3) plus **B2.1.1–B2.1.3** under module B2.1. B2 alone targets 6 modules × 3 dives = 18 dives + 6 module pages + 1 landing.
- **Transcripts**: `bcs.0.md`, `bcs.1.md`, `bcs.2.md`, `bcs.3.md`, `bcs.4.md`, `bcs.5.md`, `bcs.6.md`.
- **Next**: the BCS served course is complete end to end — B0–B8 all built and linked, B8 with 4 dives (the release and the image, Valkey on a Fly machine, EchoMQ setup and monitoring, the fly.toml and the local stack). B7 (Codemojex) complete at 6 / 6 modules, 18 dives.

## Chapters

| chapter | route | source | chapter page | dives | transcript |
|---|---|---|---|---|---|
| Landing | `/bcs` | — | done | — | — |
| B0 · Overview | `/bcs/overview` | — | done | 3 / 3 done | `bcs.0.md` done |
| B1 · Ideas Behind | `/bcs/ideas` | — | done | 3 / 3 done | `bcs.1.md` done |
| B2 · The Elixir BCS Core (6 modules) | `/bcs/elixir-core` | `echo_data/bcs` | landing done | B2.1 of 6 done | `bcs.2.md` done |
| B3 · The Bus | `/bcs/bus` | `echo_mq` | done | 3 / 3 done | `bcs.3.md` done |
| B4 · EchoStore | `/bcs/store` | `echo_store` | done | 3 / 3 done | `bcs.4.md` done |
| B5 · The Persistence Floor | `/bcs/persistence` | `echo_store/graft`, `echo_graft` | done | 3 / 3 done | `bcs.5.md` done |
| B6 · Putting It All Together | `/bcs/together` | the umbrella | done | 3 / 3 done | `bcs.6.md` done |
| B7 · Codemojex (reference game) | `/bcs/codemojex` | `echo/apps/codemojex` + `docs/` | complete | 6 / 6 modules | all 18 dives shipped |
| &nbsp;&nbsp;B7.1 · The Game as Branded Systems (module) | `…/codemojex/branded-systems` | every entity a branded id; the four layers; the privacy boundary across both modes | `234878118` |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.1.1 · Branded ids are the keys | `…/branded-systems/ids-are-the-keys` | the id is the PK in Postgres and the address everywhere; placement 234878118 | `234878118` |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.1.2 · The four layers | `…/branded-systems/the-four-layers` | Postgres record, EchoStore cache, EchoMQ tier, Phoenix surface; money and secret on the floor | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.1.3 · The privacy boundary | `…/branded-systems/the-privacy-boundary` | own attempts/best/leaderboard cross; secret and others' guesses never; blind withholds the score | — |
| &nbsp;&nbsp;B7.2 · Rooms, Modes, and the Secret (module) | `…/codemojex/rooms-and-modes` | a room is a template carrying a mode; a game snapshots it and pins the secret; commit-reveal in blind mode | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.2.1 · Room as template and mode | `…/rooms-and-modes/template-and-mode` | ROM template + mode + policies; GAM snapshots it; RMP reified membership with alias | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.2.2 · The emoji set | `…/rooms-and-modes/the-emoji-set` | EMS cells from an RSC sprite sheet; XXYY codes; Golden Rooms draw from a reduced set | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.2.3 · The secret and its commitment | `…/rooms-and-modes/secret-and-commitment` | six distinct codes, immutable; blind mode commits at open and reveals at close, provably fair | — |
| &nbsp;&nbsp;B7.3 · Guesses on Fair Lanes (module) | `…/codemojex/guesses-on-fair-lanes` | a guess validated and locked, charged under an all-pay rule, enqueued as a branded job, served in rotation to one score worker | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.3.1 · The guess and the lock | `…/guesses-on-fair-lanes/the-guess-and-the-lock` | six distinct codes checked from cache; a Valkey lock allows one move in flight; invalid or locked refused before charge | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.3.2 · Charged, then enqueued | `…/guesses-on-fair-lanes/charged-then-enqueued` | wallet charged in a transaction on the room&#8217;s currency path; all-pay, paid per attempt; job carries ids and guess, no score or secret | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.3.3 · Fair lanes and the worker | `…/guesses-on-fair-lanes/fair-lanes-and-the-worker` | PLR lanes served in rotation behind a starvation gate; one score worker; live broadcasts a scored event, blind stays silent | — |
| &nbsp;&nbsp;B7.4 · Scoring, Tiers, and Settlement (module) | `…/codemojex/scoring-and-settlement` | distance per position to a total out of 600 across thirty tiers; scoring a policy; settlement by mode | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.4.1 · Distance and points | `…/scoring-and-settlement/distance-and-points` | per secret emoji, gap by position maps to points 100 down to 0; scoring a policy, linear or simplified | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.4.2 · The total and thirty tiers | `…/scoring-and-settlement/the-total-and-thirty-tiers` | six sum to a total out of 600; thirty bands twenty wide; leaderboard a sorted set in Valkey by best total | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.4.3 · Settlement strategies | `…/scoring-and-settlement/settlement-strategies` | live continuous standings vs sealed batch top-K at close; idempotent claim so a winner is paid once | — |
| &nbsp;&nbsp;B7.5 · The Economy and the Bank (module) | `…/codemojex/the-economy` | three currencies on separate paths; a transactional wallet; a per-game bank funded by the pool, paid after a published rake | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.5.1 · Three currencies | `…/the-economy/three-currencies` | Keys paid (bought with Stars), Clips free (no value), Diamonds prizes (convert to keys 10:1) | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.5.2 · The transactional wallet | `…/the-economy/the-transactional-wallet` | wallet keyed by USR; balance derived from an append-only TXN ledger; moves as one all-or-nothing transaction | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.5.3 · The bank, the pool, and the rake | `…/the-economy/the-bank-the-pool-and-the-rake` | BNK escrow per game; pool funded by all-pay attempts; published transparent rake, not hidden house players | — |
| &nbsp;&nbsp;B7.6 · The Live Surface on Phoenix (module) | `…/codemojex/the-live-surface` | a thin JSON facade of commands and privacy-safe views; a channel on PubSub; one supervised app on Fly | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.6.1 · The JSON API | `…/the-live-surface/the-json-api` | a guess returns 202 with scoring behind the boundary; privacy-safe views; no per-room process | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.6.2 · Channels and PubSub | `…/the-live-surface/channels-and-pubsub` | the worker publishes a scored event on PubSub; a game channel forwards it; live pushes, blind stays silent | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B7.6.3 · Production on Fly | `…/the-live-surface/production-on-fly` | one supervised Application (Repo, PubSub, bus+workers, endpoint); no ephemeral tier; deployed as Machines on Fly | — |
| B8 · Production on Fly | `/bcs/fly` | `Dockerfile` + `fly.toml` + `docker-compose.yml` | complete | 4 / 4 dives | built |
| &nbsp;&nbsp;&nbsp;&nbsp;B8.1 · The release and the image | `…/the-release-and-the-image` | mix release codemojex; native codec; echo_store/echo_bot/echo_graft excluded | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B8.2 · Valkey on a Fly machine | `…/valkey-on-a-fly-machine` | dedicated machine, noeviction; appendonly everysec (~1s loss); kernel tuning (THP, overcommit, swappiness) | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B8.3 · EchoMQ setup and monitoring | `…/echomq-setup-and-monitoring` | supervised bus + RESP3 connector; 4 lane consumers; queue-depth + dashboard + lease monitoring | — |
| &nbsp;&nbsp;&nbsp;&nbsp;B8.4 · The fly.toml and the local stack | `…/the-fly-config-and-the-local-stack` | fly.toml (rolling, IPv6, /health, 4000); docker-compose (Postgres 6432, Valkey 6390) | — |

Routes and dive slugs for B7 are fixed in codemojex.roadmap.md; B8 remains provisional until authored.

## Chapter intent (from the repo analysis)

- **B3 · The Bus** — `echo_mq` v2.6.3, the Valkey-native bus: the braced/branded keyspace, `Jobs`/`Lanes`/`Flows`/`Consumer`, and the 3.0 Stream Tier (`EchoMQ.Stream`/`StreamConsumer`, emq3.1–3.4 shipped).
- **B4 · EchoStore** — `echo_store`: the declared near-cache (Part IV). L1 ETS over the shared L2 Valkey, cache-aside with one fill per herd, `EchoStore.Coherence` by mint-time version over a broadcast lane (the Disruptor-shaped `EchoStore.Ring`) and a job lane.
- **B5 · The Persistence Floor** — the durable Graft engine beneath the cache: `EchoStore.Graft` (the append-only page log on CubDB) and the Rust `echo_graft`, streamed to Tigris via `Graft.Remote.Tigris`, where `EchoStore.StreamArchive` folds trimmed streams as deep history.
- **B6 · Putting It All Together** — the umbrella as one running system: BCS systems over the bus over the store, end to end (replaces the former B6 Go and B7 Node).
- **B7 · Codemojex BCS** — a forward future-vision: the multiplayer Telegram game re-seen on BCS, on the real skeleton in `echo/apps/codemojex` (workers draining `EchoMQ.Lanes`, entities as branded ids, state in stores).
- **B8 · Production on Fly** — Codemojex in production: the container, Valkey, and the `fly.toml`, on the deployment patterns under `go/` and `docs/valkey/valkey.fly.md`.

## Dives — written

| dive | route | figure (the idea it draws) | grounded figure |
|---|---|---|---|
| B0.1 · The one relocation | `/bcs/overview/the-relocation` | the boundary moving from the object to the system | — |
| B0.2 · Identity as a contract | `/bcs/overview/identity-as-contract` | the name with its four guarantees | `234878118` |
| B0.3 · The stack and the floor | `/bcs/overview/stack-and-floor` | `echo_data`/`echo_mq`/`echo_store` over the durable floor | — |
| B1.1 · The system substrate | `/bcs/ideas/the-substrate` | a process owning a private table that is a timeline | — |
| B1.2 · The identity contract | `/bcs/ideas/the-contract` | four integer failures, each retired by a property | `234878118` |
| B1.3 · From ECS to BCS | `/bcs/ideas/ecs-to-bcs` | an index dying at three walls; the name crossing | — |
| B2.1 · A System Is an OTP Application (module, 6 dives) | `/bcs/elixir-core/otp-application` | shape + complete source: application.ex, supervisor.ex, property_store.ex | `234878118` |
| &nbsp;&nbsp;B2.1.1 · The boundary is the export list | `…/otp-application/the-boundary` | public fns are the surface; the table is `:private`; id + message cross | — |
| &nbsp;&nbsp;B2.1.2 · The supervision tree | `…/otp-application/the-supervision-tree` | `one_for_one` over named stores; crash restarts clean in isolation | — |
| &nbsp;&nbsp;B2.1.3 · The supervisor owns existence, not data | `…/otp-application/existence-not-data` | lifecycle vs state; restart rehydrates from store + floor by id | — |
| &nbsp;&nbsp;B2.1.4 · The application boots the contract | `…/otp-application/the-application` | application.ex in full: Snowflake, contract self-check, one_for_one root | `234878118` |
| &nbsp;&nbsp;B2.1.5 · The supervisor names the systems | `…/otp-application/the-supervisor` | supervisor.ex in full: {name, namespace} pairs to named children | — |
| &nbsp;&nbsp;B2.1.6 · The property store, in full | `…/otp-application/the-property-store` | property_store.ex in full: export list, gated ingress, :private :ordered_set | — |
| B2.2 · Property Stores on ETS (module) | `/bcs/elixir-core/property-stores` | one ordered_set keyed by the branded id; key order is mint order; TTL structural | — |
| &nbsp;&nbsp;B2.2.1 · The branded id is the only key | `…/property-stores/the-only-key` | one key, the branded id; no surrogate, no timestamp column | — |
| &nbsp;&nbsp;B2.2.2 · Key order is time order | `…/property-stores/key-order-is-time-order` | mint-ordered snowflakes; latest-N, window, cursor as range ops | — |
| &nbsp;&nbsp;B2.2.3 · TTL as structure, not bookkeeping | `…/property-stores/ttl-as-structure` | a bucket from the snowflake; expiry drops whole buckets | — |
| B2.3 · The CHAMP Property Database (module) | `/bcs/elixir-core/the-champ-database` | persistent forest of tries; structural sharing; contract-hash placement; an L0 tier rebuilt from the floor | `234878118` |
| &nbsp;&nbsp;B2.3.1 · Structural sharing | `…/the-champ-database/structural-sharing` | a new version copies only the path; untouched subtrees shared; snapshots cost nothing | — |
| &nbsp;&nbsp;B2.3.2 · The contract hash is the placement | `…/the-champ-database/the-placement-hash` | hash32 single-sourced; 5-bit fragments, 32-way; same placement across runtimes | `234878118` |
| &nbsp;&nbsp;B2.3.3 · A tier, not a source of truth | `…/the-champ-database/a-tier-not-a-truth` | ChampView folds the Graft log; BrandedMap by default, CHAMP for placement-as-contract | — |
| B2.4 · Archetypes and Composition (module) | `/bcs/elixir-core/archetypes` | archetypes are ARC-namespace data; composition a pure fold over :extends; one parent, no diamond | — |
| &nbsp;&nbsp;B2.4.1 · Archetypes are data | `…/archetypes/archetypes-are-data` | an ARC entity is a property bundle; :extends one parent; entity = id + overrides | — |
| &nbsp;&nbsp;B2.4.2 · Composition is a pure fold | `…/archetypes/composition-is-a-fold` | compose/2 merges the chain, overrides last; resolve/3 takes an injected fetch | — |
| &nbsp;&nbsp;B2.4.3 · One parent, no diamond | `…/archetypes/one-parent-no-diamond` | single :extends = a chain; max_depth and cycle guards; always terminates | — |
| B2.5 · Relations Are Systems (module) | `/bcs/elixir-core/relations` | an edge is its own owning process keyed by {subject, object}; both ends gated; dual private indexes | — |
| &nbsp;&nbsp;B2.5.1 · A relation is a system | `…/relations/a-relation-is-a-system` | one owning GenServer per edge; keyed by the tuple; neither endpoint carries a list | — |
| &nbsp;&nbsp;B2.5.2 · Both ends are gated | `…/relations/both-ends-gated` | link gates subject_ns and object_ns before writing; the key is the validated pair | — |
| &nbsp;&nbsp;B2.5.3 · Dual private indexes | `…/relations/dual-indexes` | fwd {s,o} for from, rev {o,s} for to; written together by one owner; degree counts fwd | — |
| B2.6 · Gates and Acceleration at the Boundary (module) | `/bcs/elixir-core/gates` | the namespace gate admits one kind; optional native codec with a pure fallback proven equal at boot | `234878118` |
| &nbsp;&nbsp;B2.6.1 · The gate admits one namespace | `…/gates/the-gate` | Bcs.gate: match → {:ok, snowflake}; wrong ns → :namespace; unparseable → :invalid; one parser | — |
| &nbsp;&nbsp;B2.6.2 · A native codec with a pure fallback | `…/gates/the-native-codec` | EchoData.Native NIF (Rust+C) for decode/encode/hash32; pure Elixir when absent; BrandedId routes | — |
| &nbsp;&nbsp;B2.6.3 · One contract, proven at the boundary | `…/gates/one-contract` | both paths must produce placement 234878118; the boot self-check asserts it and returns the mode | `234878118` |
| B3.1 · The keyspace | `/bcs/bus/the-keyspace` | a bus key born braced, branded, declared | — |
| B3.2 · Jobs and lanes | `/bcs/bus/jobs-and-lanes` | a leased job lifecycle, fair lanes, a flow | — |
| B3.3 · The Stream Tier | `/bcs/bus/the-stream-tier` | an append-only log: written, read, trimmed | — |
| B4.1 · The declared near-cache | `/bcs/store/the-near-cache` | a declared directory over L1 ETS and L2 Valkey | — |
| B4.2 · One fill per herd | `/bcs/store/one-fill-per-herd` | caller-side hits, one coalesced fill, jittered TTL | — |
| B4.3 · Coherence | `/bcs/store/coherence` | two-id invalidation, newer-wins, broadcast + job lanes | — |
| B5.1 · The single-writer engine | `/bcs/persistence/the-engine` | writers serialized through one volume onto an append-only B-tree | — |
| B5.2 · The lazy reader | `/bcs/persistence/the-lazy-reader` | pages pulled on demand at a snapshot, the head from ETS | — |
| B5.3 · The portable remote | `/bcs/persistence/the-remote` | a streamer to Tigris, the commit-LSN cursor, the stream archive | — |
| B6.1 · One umbrella, four systems | `/bcs/together/the-umbrella` | a dependency graph booting after the contract self-check | — |
| B6.2 · One write, all the way down | `/bcs/together/the-write-path` | a store write through the outbox, a lane, a flow, to the floor | — |
| B6.3 · One read, all the way up | `/bcs/together/the-read-path` | a caller-side hit, then a fill down the four-tier ladder | — |

## Standing rules in force

- **Structure**: a chapter is exactly three dives; no module layer; B0 is Overview; the course runs B0–B8.
- **Figures**: one interactive `.anat` figure per page; it draws the idea from `rect`/`path` shapes with word labels — never a numbered node-arc.
- **Grounding**: a number appears only if a committed `.out` or source asserts it; the only figures used so far are the `self_check!` contract vectors.
- **Transcript**: every chapter ships `bcs.<N>.md` with the full prose of the chapter and its three dives, generated from the same prose as the pages.

## Legend

- **done** — built, gated, present in outputs.
- **pending** — not yet authored.
