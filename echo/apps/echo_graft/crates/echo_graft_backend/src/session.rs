//! The backend session (eg.4): the version handshake, the request→dispatch→reply path, and
//! the per-push change-feed republish.
//!
//! A [`Session`] wraps one [`Runtime`] and one [`FeedSink`]. The transport (a live bus
//! binding or the in-process test channels) hands it already-framed request bytes and takes
//! the response bytes back; the session never owns a socket. The handshake gates the session
//! (`Hello` → `Welcome`/`Incompatible`); a refused handshake performs NO Volume op (S-2).
//!
//! The feed: eg.3's `volume_push` records advances in the engine's in-memory feed
//! (`runtime.rs:267`); after each `Push` this session reads the newly-published events for
//! that Volume (`InMemoryFeed::events_since`) and republishes them on `egraft:feed:{vol}`
//! through the sink — the bus-backed `ChangeFeed` the brief names, without mutating the
//! byte-frozen Runtime.

use std::collections::HashMap;

use echo_graft::{feed::ChangeFeed, rt::runtime::Runtime};
use echo_graft_proto::{Msg, PROTO_MAX, PROTO_MIN, ProtoErr};

use crate::{dispatch, feed_sink::BusFeed, transport::FeedSink};

/// The outcome of a handshake.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Handshake {
    /// The session may proceed at the selected protocol version.
    Established(u32),
    /// No overlapping version; the session is refused. No Volume was touched.
    Refused,
}

/// One backend session: a `Runtime` + a feed sink + the per-Volume feed cursors used to
/// republish only the events a push newly made durable.
pub struct Session<S: FeedSink> {
    rt: Runtime,
    feed: BusFeed<S>,
    /// The protocol version selected at the handshake; `None` until established.
    proto: Option<u32>,
    /// Per-Volume last-republished LSN — so a push republishes each event exactly once
    /// onto the bus (the engine's in-memory feed is cumulative; this is the bus-side
    /// cursor). Keyed by branded id (the feed's key).
    republished: HashMap<String, u64>,
}

impl<S: FeedSink + Clone> Session<S> {
    /// Build a session over a runtime and a sink. The session starts un-negotiated; call
    /// [`Session::hello`] before any request.
    pub fn new(rt: Runtime, sink: S) -> Self {
        Self {
            rt,
            feed: BusFeed::new(sink),
            proto: None,
            republished: HashMap::new(),
        }
    }

    /// Whether the handshake has been established.
    #[must_use]
    pub fn is_established(&self) -> bool {
        self.proto.is_some()
    }

    /// Perform the version handshake from a client `Hello`. Selects
    /// `min(client.proto_max, PROTO_MAX)` when the ranges overlap and replies `Welcome`;
    /// otherwise replies `Incompatible` and performs **no** Volume operation (S-2). Any
    /// non-`Hello` first message is itself an `Incompatible` refusal (the session is not yet
    /// negotiated, so it cannot serve a request).
    pub fn hello(&mut self, msg: &Msg) -> (Handshake, Msg) {
        match msg {
            Msg::Hello { proto_min, proto_max, .. } => match negotiate(*proto_min, *proto_max) {
                Some(proto) => {
                    self.proto = Some(proto);
                    (Handshake::Established(proto), Msg::Welcome { proto })
                }
                None => (
                    Handshake::Refused,
                    Msg::Incompatible {
                        proto_min: PROTO_MIN,
                        proto_max: PROTO_MAX,
                        reason: "no overlapping protocol version".to_owned(),
                    },
                ),
            },
            _ => (
                Handshake::Refused,
                Msg::Incompatible {
                    proto_min: PROTO_MIN,
                    proto_max: PROTO_MAX,
                    reason: "expected Hello before any request".to_owned(),
                },
            ),
        }
    }

    /// Handle one request frame: decode, dispatch onto the runtime, republish any feed
    /// advance a `Push` produced, and return the response frame bytes.
    ///
    /// A request before the handshake is refused (`unavailable`) and touches no Volume. A
    /// frame that does not decode is a framing-level `unavailable` refusal.
    pub fn handle_frame(&mut self, frame: &[u8]) -> Vec<u8> {
        let msg = match Msg::decode(frame) {
            Ok(m) => m,
            Err(e) => return self.framing_refusal(&e).encode(),
        };
        self.handle(&msg).encode()
    }

    /// Handle one decoded request message (the typed path; `handle_frame` wraps it with
    /// codec framing). Exposed for the in-process round-trip proof.
    pub fn handle(&mut self, msg: &Msg) -> Msg {
        if self.proto.is_none() {
            return Msg::Err {
                corr: dispatch::corr_of(msg),
                kind: echo_graft_proto::ErrKind::Unavailable,
                detail: "session not established (handshake required)".to_owned(),
            };
        }
        let reply = dispatch::dispatch(&self.rt, msg);
        // A successful push may have advanced the engine's in-memory feed; republish the
        // new events onto the bus. Republish is keyed on the Volume the push named.
        if let (Msg::Push { vid, .. }, Msg::Ack { .. }) = (msg, &reply) {
            self.republish_after_push(vid);
        }
        reply
    }

    /// After a push acks, read the events the engine published for this Volume beyond the
    /// bus-side cursor and republish them, advancing the cursor. Monotone + gap-free,
    /// because `events_since` returns strictly-greater LSNs in order (`feed.rs:69-80`).
    fn republish_after_push(&mut self, vid: &str) {
        // Resolve the Volume's branded id (the feed key). A native vid that does not map to
        // a branded id participates in no feed — nothing to republish.
        let Some(branded) = self.branded_of(vid) else {
            return;
        };
        let last = self.republished.get(&branded).copied().unwrap_or(0);
        let events = self.rt.feed().events_since(&branded, last);
        let mut cursor = last;
        for event in events {
            cursor = cursor.max(event.lsn);
            self.feed.publish(event);
        }
        if cursor > last {
            self.republished.insert(branded, cursor);
        }
    }

    /// Replay every feed frame for a branded Volume after `last_seen_lsn`, as the encoded
    /// `Msg::Feed` frames a reconnecting client resubscribes to receive (S-3). The feed cursor
    /// (the client's last-seen LSN) is the recovery key: on a backend restart the client
    /// reconnects, resubscribes, and calls this with its cursor; the engine's
    /// `events_since(branded, last_seen)` (`feed.rs:69-80`) returns the strictly-greater LSNs
    /// in monotone, gap-free order, so the client observes no loss and no duplication beyond
    /// at-least-once.
    ///
    /// This also re-publishes those frames onto the bus (the live resubscribe delivery) and
    /// advances the bus cursor to the replayed head, so a subsequent push does not re-emit
    /// them.
    #[must_use]
    pub fn replay_since(&mut self, branded: &str, last_seen_lsn: u64) -> Vec<Vec<u8>> {
        let events = self.rt.feed().events_since(branded, last_seen_lsn);
        let mut frames = Vec::with_capacity(events.len());
        let mut cursor = self.republished.get(branded).copied().unwrap_or(0).max(last_seen_lsn);
        for event in events {
            cursor = cursor.max(event.lsn);
            let (_lane, frame) = BusFeed::<S>::frame(&event);
            frames.push(frame);
            self.feed.publish(event);
        }
        if cursor > 0 {
            self.republished.insert(branded.to_owned(), cursor);
        }
        frames
    }

    /// The branded id a native vid maps to, if any (via the Volume record).
    fn branded_of(&self, vid: &str) -> Option<String> {
        use echo_graft::core::VolumeId;
        use std::str::FromStr;
        let vid = VolumeId::from_str(vid).ok()?;
        self.rt.volume_get(&vid).ok()?.branded_id().map(str::to_owned)
    }

    /// A framing-level decode failure → an `unavailable` refusal with corr 0 (the corr is
    /// unknowable from an unparseable frame).
    fn framing_refusal(&self, e: &ProtoErr) -> Msg {
        Msg::Err {
            corr: 0,
            kind: echo_graft_proto::ErrKind::Unavailable,
            detail: format!("undecodable request frame: {e}"),
        }
    }
}

/// The version-overlap rule: the ranges `[PROTO_MIN, PROTO_MAX]` (this build) and
/// `[client_min, client_max]` overlap iff `client_min <= PROTO_MAX && PROTO_MIN <=
/// client_max`; the selected version is the highest both can speak,
/// `min(client_max, PROTO_MAX)`.
#[must_use]
pub fn negotiate(client_min: u32, client_max: u32) -> Option<u32> {
    if client_min <= PROTO_MAX && PROTO_MIN <= client_max {
        Some(client_max.min(PROTO_MAX))
    } else {
        None
    }
}

