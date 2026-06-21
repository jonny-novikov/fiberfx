//! The `EchoMQ` change-feed (eg.3).
//!
//! Every durable commit (a remote-Log LSN advance) publishes one [`FeedEvent`] so
//! consumers see a Volume advance without polling object storage. The LSN is the
//! synchronization cursor; the feed carrying it is the mechanism: a subscriber
//! that reconnects with its last-seen LSN replays every later event in order.
//!
//! eg.3 defines the feed against an **in-process stub** ([`InMemoryFeed`]); the
//! live `EchoMQ` transport (the `egraft:feed:{volume}` lane on the bus) arrives in
//! eg.4. The [`FeedEvent`] encoding is byte-frozen here so the wire never drifts.

use std::collections::BTreeMap;

use bilrost::Message;
use parking_lot::Mutex;

/// The byte-frozen change-feed event schema.
///
/// Declared fields (bilrost tags are part of the frozen wire — additive-only):
///   1. `volume_branded_id` — the external branded id of the advancing Volume.
///   2. `log_id` — the remote Log's native id (the replication-cursor coordinate
///      paired with `lsn` for `get_commit(log, lsn)` pulls).
///   3. `lsn` — the remote commit LSN that just became durable.
///   4. `ts` — wall-clock publish time, epoch milliseconds.
#[derive(Clone, Debug, PartialEq, Eq, Default, Message)]
pub struct FeedEvent {
    #[bilrost(1)]
    pub volume_branded_id: String,

    #[bilrost(2)]
    pub log_id: String,

    #[bilrost(3)]
    pub lsn: u64,

    #[bilrost(4)]
    pub ts: u64,
}

/// The `EchoMQ` lane a Volume's feed publishes on. The keying (by branded Volume id)
/// is the eg.3 contract; eg.4 carries this exact string over the bus.
pub fn lane_for(volume_branded_id: &str) -> String {
    format!("egraft:feed:{volume_branded_id}")
}

/// A change-feed sink. eg.3 ships the in-process [`InMemoryFeed`]; eg.4 will add
/// an `EchoMQ`-backed implementor behind the same trait.
pub trait ChangeFeed: Send + Sync {
    fn publish(&self, event: FeedEvent);
}

/// The in-process change-feed stub: per-Volume buffers ordered by LSN, with
/// idempotent (exactly-once-per-LSN) insertion so a replayed or retried publish
/// never duplicates or leaves a gap.
#[derive(Debug, Default)]
pub struct InMemoryFeed {
    /// `volume_branded_id` → events, kept sorted ascending by `lsn`.
    inner: Mutex<BTreeMap<String, Vec<FeedEvent>>>,
}

impl InMemoryFeed {
    pub fn new() -> Self {
        Self::default()
    }

    /// Replay: every event for `volume_branded_id` with `lsn` strictly greater
    /// than `last_seen_lsn`, in monotone LSN order with no gaps. A fresh
    /// subscriber passes `0` to receive the whole history.
    pub fn events_since(&self, volume_branded_id: &str, last_seen_lsn: u64) -> Vec<FeedEvent> {
        let guard = self.inner.lock();
        guard
            .get(volume_branded_id)
            .map(|evs| {
                evs.iter()
                    .filter(|e| e.lsn > last_seen_lsn)
                    .cloned()
                    .collect()
            })
            .unwrap_or_default()
    }

    /// All events published for a Volume, in LSN order.
    pub fn all(&self, volume_branded_id: &str) -> Vec<FeedEvent> {
        self.events_since(volume_branded_id, 0)
    }

    /// The number of events published for a Volume.
    pub fn len(&self, volume_branded_id: &str) -> usize {
        self.inner
            .lock()
            .get(volume_branded_id)
            .map_or(0, |v| v.len())
    }

    /// Whether a Volume has any published events.
    pub fn is_empty(&self, volume_branded_id: &str) -> bool {
        self.len(volume_branded_id) == 0
    }
}

impl ChangeFeed for InMemoryFeed {
    fn publish(&self, event: FeedEvent) {
        let mut guard = self.inner.lock();
        let entry = guard.entry(event.volume_branded_id.clone()).or_default();
        // Insert ordered by LSN; ignore an already-present LSN so publication is
        // idempotent (criterion 2 — exactly one event per LSN, even on retry).
        match entry.binary_search_by_key(&event.lsn, |e| e.lsn) {
            Ok(_) => {}
            Err(pos) => entry.insert(pos, event),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use bilrost::OwnedMessage;
    use test_log::test;

    fn ev(branded: &str, lsn: u64) -> FeedEvent {
        FeedEvent {
            volume_branded_id: branded.to_owned(),
            log_id: "74ggc11XPe-3tpZminfUtzHG".to_owned(),
            lsn,
            ts: 0,
        }
    }

    #[test]
    fn lane_format() {
        assert_eq!(lane_for("VOL0O5fmcxbds8"), "egraft:feed:VOL0O5fmcxbds8");
    }

    #[test]
    fn publish_is_ordered_and_idempotent() {
        let feed = InMemoryFeed::new();
        // out-of-order publish, plus a duplicate LSN
        feed.publish(ev("VOL0O5fmcxbds8", 3));
        feed.publish(ev("VOL0O5fmcxbds8", 1));
        feed.publish(ev("VOL0O5fmcxbds8", 2));
        feed.publish(ev("VOL0O5fmcxbds8", 2)); // duplicate — ignored

        let all = feed.all("VOL0O5fmcxbds8");
        assert_eq!(all.iter().map(|e| e.lsn).collect::<Vec<_>>(), vec![1, 2, 3]);

        // replay from a last-seen LSN: strictly-greater, monotone, no gaps
        let since = feed.events_since("VOL0O5fmcxbds8", 1);
        assert_eq!(since.iter().map(|e| e.lsn).collect::<Vec<_>>(), vec![2, 3]);

        // a different volume is isolated
        assert!(feed.is_empty("VOLaaaaaaaaaaa"));
    }

    #[test]
    fn feed_event_round_trips() {
        let event = ev("VOL0O5fmcxbds8", 7);
        let bytes = event.encode_to_bytes();
        let decoded = FeedEvent::decode(bytes).unwrap();
        assert_eq!(decoded, event);
    }

    /// Criterion #5 — the on-wire encoding of a fixed event is byte-frozen. If
    /// this fails, the change-feed wire drifted: bump a protocol version, never
    /// silently re-encode.
    #[test]
    fn feed_event_encoding_is_byte_frozen() {
        let event = FeedEvent {
            volume_branded_id: "VOL0O5fmcxbds8".to_owned(),
            log_id: "74ggc11XPe-3tpZminfUtzHG".to_owned(),
            lsn: 7,
            ts: 1_700_000_000_000,
        };
        let bytes = event.encode_to_bytes();
        // bilrost fixture captured 2026-06-21 (eg.3): field 1 branded id (len 14),
        // field 2 log_id (len 24), field 3 lsn=7, field 4 ts=1_700_000_000_000.
        const FIXTURE: &[u8] = &[
            0x05, 0x0e, 0x56, 0x4f, 0x4c, 0x30, 0x4f, 0x35, 0x66, 0x6d, 0x63, 0x78, 0x62, 0x64,
            0x73, 0x38, 0x05, 0x18, 0x37, 0x34, 0x67, 0x67, 0x63, 0x31, 0x31, 0x58, 0x50, 0x65,
            0x2d, 0x33, 0x74, 0x70, 0x5a, 0x6d, 0x69, 0x6e, 0x66, 0x55, 0x74, 0x7a, 0x48, 0x47,
            0x04, 0x07, 0x04, 0x80, 0xcf, 0x94, 0xfe, 0xbb, 0x30,
        ];
        assert_eq!(
            bytes.as_ref(),
            FIXTURE,
            "FeedEvent wire encoding drifted: {:02x?}",
            bytes.as_ref()
        );
        // and it still round-trips from the frozen bytes
        assert_eq!(FeedEvent::decode(bytes).unwrap(), event);
    }
}
