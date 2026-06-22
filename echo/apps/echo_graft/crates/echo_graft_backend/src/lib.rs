//! `echo_graft_backend` — the supervised `EchoMQ` participant driving the `echo_graft` Rust
//! page-engine (eg.4).
//!
//! The engine does blocking object-storage + LSM I/O, so it runs as a backend process
//! addressed over `EchoMQ` rather than an in-VM NIF: an engine crash becomes a supervised
//! restart, not a downed orchestrator. This crate is the Rust half — a **session + dispatch +
//! publish shell** with NO engine logic of its own:
//!
//!   * [`session::Session`] — the version handshake, the request→dispatch→reply path, and
//!     the per-push change-feed republish.
//!   * [`dispatch`] — the 1:1 translation of each `echo_graft_proto` request onto the real
//!     [`echo_graft::rt::runtime::Runtime`] method map, with the closed error taxonomy.
//!   * [`feed_sink::BusFeed`] — the [`echo_graft::feed::ChangeFeed`] that publishes each
//!     event on `egraft:feed:{vol}` through an abstract [`transport::FeedSink`].
//!   * [`transport`] — the abstract publish capability (the engine carries no valkey
//!     client; the live bus is driven from the BEAM). The in-process
//!     [`transport::InMemorySink`] proves the round-trip.
//!   * [`backpressure::Backpressure`] — the per-Volume in-flight cap that isolates a hot
//!     Volume's flood (S-7), with a stated reject-on-overflow policy.
//!
//! ## eg.5 — the low-latency write tier + the live binding
//!
//!   * [`shaper::Shaper`] — the pure, clock-injected batch-shaping core (flush on `min_size`
//!     OR `timeout`; S-3).
//!   * [`buffer::WriteBuffer`] — the bounded, durable local-fsync group-commit buffer in front
//!     of the eg.2 remote commit (one fsync per batch, rolled up via `volume_push`; S-1/4/5/6).
//!   * `live::LiveBackend` (step 4) — the live Valkey :6390 RESP3 transport (the ruled A-2 raw
//!     socket reusing the proto codec) that binds [`session::Session`] to a real bus and consults
//!     the [`backpressure::Backpressure`] cap on the live path (S-7/S-8); the live LEG is
//!     env-gated at the test layer.
//!
//! The wire is `echo_graft_proto` (byte-frozen, version-negotiated); the BEAM client is
//! `EchoStore.GraftBackend`, a coexisting peer beside the untouched native
//! `EchoStore.Graft.*` engine.

#![forbid(unsafe_code)]

pub mod backpressure;
pub mod buffer;
pub mod dispatch;
pub mod feed_sink;
pub mod live;
pub mod session;
pub mod shaper;
pub mod transport;

pub use backpressure::{Backpressure, DEFAULT_MAX_IN_FLIGHT, Permit};
pub use buffer::{BufferErr, LossWindow, Pending, WriteBuffer};
pub use echo_graft_proto::{Mode, PROTO_MAX, PROTO_MIN};
pub use live::{LiveBackend, LiveConfig, LiveErr};
pub use session::{Handshake, Session, negotiate};
pub use shaper::{FlushReason, Shaper};
pub use transport::{FeedSink, InMemorySink, Published};
