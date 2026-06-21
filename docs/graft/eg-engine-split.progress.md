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
