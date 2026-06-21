# eg-engine-split — AAW scope ledger

## {eg-engine-split-thinking} Thinking

### T-1 — The collision is two NATIVE engines sharing a name; the outbox is a third, separate concern.

As-built ground truth (every claim cited against source, no invented signatures):

RUST engine — apps/echo_graft/crates/echo_graft/src/rt/runtime.rs:
  Runtime is a full page-store: volume_open/volume_open_branded (runtime.rs:170,185), volume_writer/volume_reader (298,293), volume_push→run_action(RemoteCommit) (239-243), publish_feed_advance gated on remote-LSN advance (250-279), read_page with lazy FetchSegment fault (91-120), feed()→InMemoryFeed (83). Local=FjallStorage; remote=Arc<Remote> (OpenDAL, remote.rs:107-148, S3Compatible reads AWS_ENDPOINT_URL); fence=put_commit WriteOptions{if_not_exists:true}⇒ConditionNotMatch (remote.rs:195-211, 66-72). Feed wire byte-frozen (feed.rs:166), lane_for→"egraft:feed:{vol}" (feed.rs:42). BrandedId caller-supplied, NO Rust minter (identity.rs:10-12).

ELIXIR engine — apps/echo_store/lib/echo_store/graft/*:
  EchoStore.Graft (graft.ex) is ALSO a full page-store: VolumeServer single-writer mailbox = the write lock (volume_server.ex:2-8,129-159), commit OCC base_lsn!=head→{:error,{:conflict,head}} (131-133); Store on CubDB MVCC snapshots (store.ex:1-20), append in one tx (42-56), page_at reverse-select (60-72); Streamer real-time Tigris ship + bus notice, capped-backoff resume from watermark (streamer.ex:1-15,88-112); Reader L1 ETS→CubDB→lazy segment fetch (reader.ex:1-18,24-77); Committer commit-log-as-OUTBOX drain at-least-once (committer.ex:1-18,99-114); Epoch fencing token (epoch.ex:1-14); Divergence no-merge guard (divergence.ex:16-25); Remote.Tigris put_commit create-only If-None-Match (tigris.ex:37-44). IDs EchoData.Graft.Id VOL/SEG/CMT (id.ex). => DIRECT FUNCTIONAL TWIN of the Rust Runtime.

OUTBOX — a SEPARATE concern, do not conflate:
  EchoStore.Durability (durability.ex) = pluggable adapter facade; moduledoc: outbox intents are LOW-VOLUME, "a small, mostly-idle dependency, not the hot path Oban puts every dequeue through" (durability.ex:6-9); bus stays on Valkey. Adapter behaviour (adapter.ex). Durability.Graft (plugins/graft.ex) = ONE adapter: outbox-IS-the-commit-log, bring-your-own plugin, an intent = a page commit in a reserved high range @obx_base=1<<48 (plugins/graft.ex:1-33,46,82-92). Shipped core adapters: SQLite (exqlite) + Memory (ETS).

THE COLLISION: eg.4 spec (graft.4.md:28,40) names "EchoStore.Graft" as the thin Elixir CLIENT to the Rust sidecar — but that exact module IS the native Elixir engine (graft.ex). Namespace + architecture collision => build paused. Resolution is the Operator's call (coexist / supersede / native-canonical+Rust-research).

## {eg-engine-split-decisions} Decisions

### D-1 — Deliverables landed; collision surfaced for Operator (architect proposes, does not dispose).

WROTE: docs/graft/graft.engine-split.design.md — the full design: 5W+H, needs-vs-reality table (the consumer's hot path touches only the LOW-VOLUME outbox, already served natively no-foreign-engine → a full page-store engine is the wrong SIZE for the outbox; it earns its place on the page/Volume + replica-recovery need, a different consumer), the as-built capability map for BOTH engines + the outbox (every surface cited to a module/fn, zero invented signatures), the proposed split (COMPLEMENTARY: outbox/L1/bus/supervision stay BEAM-side in every option; DUPLICATED: the page/Volume engine role implemented twice), the 3 resolution options + recommendation, the reconciled eg.4 scope, and an Open-decisions block.

EDITED: docs/graft/specs/graft.4.md — Reconciliation banner (BLOCKED on D-1), client renamed EchoStore.Graft→EchoStore.GraftSidecar throughout, claim narrowed ("the sidecar integration for the RUST page-engine", not "the integration spine for all durability"), native engine declared untouched + feed lanes kept distinct (egraft:feed:{vol} vs graft:{vol}:commits), Open-decisions (Operator) table appended.

RECOMMENDATION: Option A (coexist) — native EchoStore.Graft.* stays canonical for the in-process/low-dep path; Rust apps/echo_graft serves raw-page/replica workloads under the non-colliding name EchoStore.GraftSidecar. Rationale: needs-vs-reality (nothing forces Rust onto the default path) + both investments win DIFFERENT workloads (not the same one) + reversibility (A keeps B/C open after the eg.6 shootout; B/C foreclose) + eg.4 unblocks today with a pure rename.

OPERATOR CALLS (surfaced, NOT decided): D-1 resolution A/B/C · D-2 client name · D-3 eg.4 claim · D-4 long-term convergence (defer to post-eg.6) · D-5 shootout shape (per-workload) · D-6 if-B-then-separate-retirement-rung. Did NOT pick D-1 — recommendation only.

NON-ACTIONS: no production code touched (Rust or Elixir); github.local/graft untouched; neither engine retired (the rename is a proposal contingent on D-1/D-2).

### D-2 — OPERATOR RULING APPLIED + build brief authored. eg.4 build-grade.

RULING: D-1 = Option A (COEXIST, both engines kept, native EchoStore.Graft.* canonical+untouched). D-2 = echo_graft_backend (Operator's name, OVERRIDES the architect's …Sidecar): Rust crate/binary echo_graft_backend, wire echo_graft_proto, Elixir client EchoStore.GraftBackend (peer, not replacement; EchoStore.Durability.GraftBackend noted as alt, default is EchoStore.GraftBackend). D-3 "drive the Rust page-engine" · D-4 defer post-eg.6 · D-5 per-workload shootout · D-6 N/A under A.

EDITED docs/graft/specs/graft.4.md — rewritten whole: status build-grade (BLOCKED cleared), all naming →echo_graft_backend/EchoStore.GraftBackend, claim narrowed, native engine + feed-lane distinctness declared, resolved decision ledger. PLUS the full build brief folded in: References (real surfaces, cited) · the Runtime 1:1 method map (volume_open_branded/volume_writer/volume_push/volume_pull/volume_reader+read_page/volume_snapshot/get_commit/feed, all runtime.rs lines) · 7 Agent stories S-1..S-7 one-per-criterion each Directive+Acceptance gate+invariant+real surface (S-1 commit-acks-then-feed asserts feed ARRIVES on advance AND none on no-op push = positive liveness; S-2 incompatible-refused asserts volume-set byte-identical = no-op-mustn't-satisfy) · Declared keys (16 proto msgs + egraft:cmd:{vol}/egraft:feed:{vol} lanes + corr id; closed error enum conflict/not_found/version_mismatch/unavailable) · Byte-frozen fixtures (RESP3 via REAL EchoMQ.RESP.encode/1+parse/1 resp.ex:21/45, FeedEvent rides as OPAQUE bilrost blob already frozen feed.rs:166, one fixture file two readers) · Version-negotiation (Hello/Welcome/Incompatible, no-op on refusal) · Gate ladder (Rust cargo+conformance+≥100 loop --test-threads=1; Elixir echo_store ladder TMPDIR=/tmp+warnings-as-errors+asdf-reprobe+Valkey:6390+byte-equality conformance vs SAME fixtures; live-bus env-gated per eg.2) · Build order 7 stop-and-verify steps (proto+fixtures→backend dispatch→handshake→client+conformance→reconnect→backpressure→live leg).

EDITED docs/graft/graft.engine-split.design.md — Operator-ruling banner at top, status Resolved, §0/§5/§6/§7/§8 naming + ruling applied; §2-§6 analysis preserved as rationale-of-record (pre-ruling voice flagged); §7 → resolved ledger.

VERIFY: msh specs docs/graft = 0 findings; naming audit clean (all residual 'sidecar' tokens intentional: frozen anchor id, RESOLVED-banner override notes, §5 strikethrough provenance, Option B/C option-bodies, 3 verbatim as-built quotes incl "Litestream sidecar"/roadmap:17/README:49-51). New names: 20 in graft.4.md, 12 in design.md. No production code touched, no git, github.local/graft untouched, native engine + Durability.Graft untouched.

## {eg-engine-split-progress} Progress

### P-1 — Rung delivered. Director not addressable by name → synthesis returned as the final assistant message (this was an Operator-direct task; the final message is relayed to the Operator). Deliverables: docs/graft/graft.engine-split.design.md (new) + docs/graft/specs/graft.4.md (reconciled). Link checker on docs/graft: 0 findings. Recommendation Option A (coexist + rename Rust client EchoStore.GraftSidecar); 6 Operator decisions surfaced, none decided by the architect. No production code touched; neither engine retired.


