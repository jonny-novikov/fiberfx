//! The abstract transport the backend speaks over (eg.4).
//!
//! `echo_graft_backend` is addressed over `EchoMQ`, but the engine crate carries **no**
//! valkey/redis client dependency — the live bus is driven from the BEAM
//! (`EchoStore.GraftBackend` over `EchoMQ.Connector`). So the backend depends only on the
//! *capability* it needs, not a concrete client:
//!
//!   * [`FeedSink`] — publish a message on a named lane (the `egraft:feed:{vol}` lane,
//!     fire-and-forget; the change-feed direction).
//!
//! A live deployment binds these to real bus PUBLISH / command-lane I/O; the in-process
//! conformance proves the round-trip with channel-backed implementors ([`InMemorySink`]).
//! The wire bytes that cross either binding are produced by `echo_graft_proto`, so the
//! transport never sees anything but already-framed `Msg` bytes — it cannot disagree with the
//! BEAM side on encoding.

use std::sync::Arc;

use parking_lot::Mutex;

/// A publish-only sink for change-feed frames. `publish` carries the lane string
/// (`egraft:feed:{vol}`, from `echo_graft::feed::lane_for`) and the already-encoded message
/// bytes; a live binding maps this to a bus `PUBLISH`, fire-and-forget.
pub trait FeedSink: Send + Sync {
    /// Publish `frame` on `lane`. A sink never blocks the engine: a slow or absent
    /// subscriber must not stall a commit (the feed is at-least-once on advance, not a
    /// transactional leg).
    fn publish(&self, lane: &str, frame: &[u8]);
}

/// One published frame, captured for assertions: the lane and the raw bytes.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Published {
    /// The lane the frame went out on (`egraft:feed:{vol}`).
    pub lane: String,
    /// The encoded `echo_graft_proto` `Msg::Feed` bytes.
    pub frame: Vec<u8>,
}

/// An in-memory [`FeedSink`] that records every publish, for the in-process round-trip
/// proof. A live deployment swaps this for a bus-backed sink; the backend code is identical.
#[derive(Clone, Debug, Default)]
pub struct InMemorySink {
    published: Arc<Mutex<Vec<Published>>>,
}

impl InMemorySink {
    /// A fresh sink with no recorded frames.
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Every frame published so far, in publish order.
    #[must_use]
    pub fn drain(&self) -> Vec<Published> {
        self.published.lock().clone()
    }

    /// The number of frames published on a given lane.
    #[must_use]
    pub fn count_on(&self, lane: &str) -> usize {
        self.published.lock().iter().filter(|p| p.lane == lane).count()
    }
}

impl FeedSink for InMemorySink {
    fn publish(&self, lane: &str, frame: &[u8]) {
        self.published.lock().push(Published {
            lane: lane.to_owned(),
            frame: frame.to_vec(),
        });
    }
}
