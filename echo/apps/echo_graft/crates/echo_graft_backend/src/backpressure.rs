//! Per-Volume backpressure (eg.4, S-7): bound a single hot Volume's in-flight commands so a
//! producer outrunning the engine cannot exhaust memory, **without** stalling other Volumes.
//!
//! Isolation is structural: each Volume's commands arrive on its own lane
//! (`egraft:cmd:{vol}`), so a flood on one `{vol}` is a different channel than another's and
//! can never head-of-line-block it. This gate adds the second half — a per-Volume cap on
//! *admitted-but-unfinished* commands. Over the cap, the policy is to **reject** (the proto
//! `unavailable` kind) rather than buffer without bound or block the dispatch thread; a
//! rejected client retries. The cap is per-Volume, so volume A hitting its cap leaves volume
//! B's budget untouched.
//!
//! ## The control lane is exempt by design
//!
//! The vid-less requests — the handshake (`Hello`) and the two open-time verbs
//! (`OpenVolume` / `ResolveBranded`, which carry a branded id but no native vid yet) — travel
//! on a single shared control lane (`egraft:cmd:_control`, defined client-side in
//! `EchoStore.GraftBackend`), **outside** this per-Volume isolation. That is intentional, not
//! an oversight: the control lane has no `{vol}` to key a cap on, and its traffic is
//! infrequent and bounded by construction (one handshake per session, one open per Volume
//! lifecycle) — it is not a sustained write path a producer can flood. The per-Volume cap
//! applies only to the hot `egraft:cmd:{vol}` lanes, where an unbounded commit producer is the
//! real hazard S-7 addresses. A future rung that needs control-plane backpressure would add a
//! separate, coarser bound there; eg.4 deliberately does not.

use std::collections::HashMap;

use parking_lot::Mutex;

/// The default per-Volume in-flight cap. Sized for a backend whose commits are object-storage
/// latency-bound: enough to keep the engine busy, small enough that a runaway producer is
/// back-pressured quickly.
pub const DEFAULT_MAX_IN_FLIGHT: u32 = 64;

/// A per-Volume in-flight limiter. Cheap to clone-share via the inner `Mutex`; an admission
/// takes a [`Permit`] whose drop releases the slot, so a slot is never leaked on an early
/// return or a panic in the dispatch.
#[derive(Debug)]
pub struct Backpressure {
    max_in_flight: u32,
    inner: Mutex<HashMap<String, u32>>,
}

impl Backpressure {
    /// A limiter with the given per-Volume cap.
    #[must_use]
    pub fn new(max_in_flight: u32) -> Self {
        Self { max_in_flight, inner: Mutex::new(HashMap::new()) }
    }

    /// A limiter with [`DEFAULT_MAX_IN_FLIGHT`].
    #[must_use]
    pub fn with_default() -> Self {
        Self::new(DEFAULT_MAX_IN_FLIGHT)
    }

    /// The per-Volume cap.
    #[must_use]
    pub fn max_in_flight(&self) -> u32 {
        self.max_in_flight
    }

    /// Try to admit one command for `vol`. Returns a [`Permit`] (release-on-drop) when the
    /// Volume is below its cap, or `None` when it is at the cap (the caller rejects the
    /// command with `unavailable`). A different Volume's count is never consulted, so an
    /// over-cap Volume cannot affect another's admission.
    pub fn admit<'a>(&'a self, vol: &str) -> Option<Permit<'a>> {
        let mut map = self.inner.lock();
        let count = map.entry(vol.to_owned()).or_insert(0);
        if *count >= self.max_in_flight {
            None
        } else {
            *count += 1;
            Some(Permit { bp: self, vol: vol.to_owned() })
        }
    }

    /// The current in-flight count for a Volume (0 if none admitted).
    #[must_use]
    pub fn in_flight(&self, vol: &str) -> u32 {
        self.inner.lock().get(vol).copied().unwrap_or(0)
    }

    fn release(&self, vol: &str) {
        let mut map = self.inner.lock();
        if let Some(count) = map.get_mut(vol) {
            *count = count.saturating_sub(1);
            if *count == 0 {
                map.remove(vol);
            }
        }
    }
}

impl Default for Backpressure {
    fn default() -> Self {
        Self::with_default()
    }
}

/// An admission permit. Holding it counts one in-flight command for its Volume; dropping it
/// releases the slot — so a slot is freed on every exit path (success, error, or panic).
#[derive(Debug)]
pub struct Permit<'a> {
    bp: &'a Backpressure,
    vol: String,
}

impl Drop for Permit<'_> {
    fn drop(&mut self) {
        self.bp.release(&self.vol);
    }
}
