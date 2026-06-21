//! The bus-backed change-feed (eg.4): a [`ChangeFeed`] that publishes each
//! [`FeedEvent`] onto its Volume's `egraft:feed:{vol}` lane instead of buffering in
//! memory.
//!
//! eg.3 left `RuntimeInner.feed` a concrete `Arc<InMemoryFeed>` (`runtime.rs:50`), so the
//! engine still records advances in memory; the backend reads those out per push and
//! republishes them here (see [`crate::session::Session`]). This type is the
//! `ChangeFeed`-shaped publish path the brief names — a frame is the eg.3 `FeedEvent`
//! carried OPAQUE inside an `echo_graft_proto` `Msg::Feed` (the two freeze-points compose,
//! no re-encode of the event's fields).

use echo_graft::feed::{ChangeFeed, FeedEvent, lane_for};
use echo_graft_proto::Msg;

use crate::transport::FeedSink;

/// A [`ChangeFeed`] that frames each event as a `Msg::Feed` (the bilrost `FeedEvent` rides
/// opaque) and publishes it on `egraft:feed:{volume_branded_id}` through a [`FeedSink`].
/// Distinct by construction from the native engine's `graft:{vol}:commits` lane — eg.4 only
/// ever names `egraft:feed:{vol}`.
pub struct BusFeed<S: FeedSink> {
    sink: S,
}

impl<S: FeedSink> BusFeed<S> {
    /// Wrap a sink as a change-feed.
    pub fn new(sink: S) -> Self {
        Self { sink }
    }

    /// Frame an event the way [`ChangeFeed::publish`] does, without sending — exposed so a
    /// test can assert the on-lane bytes equal `Msg::Feed{event.encode()}`.
    #[must_use]
    pub fn frame(event: &FeedEvent) -> (String, Vec<u8>) {
        use bilrost::Message;
        let lane = lane_for(&event.volume_branded_id);
        let blob = event.encode_to_vec();
        let frame = Msg::Feed { blob }.encode();
        (lane, frame)
    }
}

impl<S: FeedSink> ChangeFeed for BusFeed<S> {
    fn publish(&self, event: FeedEvent) {
        let (lane, frame) = Self::frame(&event);
        self.sink.publish(&lane, &frame);
    }
}
