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
//! The wire is `echo_graft_proto` (byte-frozen, version-negotiated); the BEAM client is
//! `EchoStore.GraftBackend`, a coexisting peer beside the untouched native
//! `EchoStore.Graft.*` engine.

#![forbid(unsafe_code)]

pub mod backpressure;
pub mod dispatch;
pub mod feed_sink;
pub mod session;
pub mod transport;

pub use backpressure::{Backpressure, DEFAULT_MAX_IN_FLIGHT, Permit};
pub use echo_graft_proto::{PROTO_MAX, PROTO_MIN};
pub use session::{Handshake, Session, negotiate};
pub use transport::{FeedSink, InMemorySink, Published};
