//! The pure, clock-injected batch-shaping core (eg.5, S-3).
//!
//! The write tier amortizes one local fsync over a batch of accepted writes, then rolls the
//! batch up into one remote `volume_push`. *When* a batch flushes is the shaping decision, and
//! it is kept here — pure, with no I/O and no real clock — so the flush trigger is deterministic
//! under test (the criterion-3 requirement: "no dependence on real time").
//!
//! The trigger is `min(size_reached, age_reached)`: a batch flushes as soon as it reaches
//! `min_size` accepted records OR ages past `timeout` since its first record, whichever comes
//! first. The clock is a parameter (`now_ms`), never `SystemTime::now()`, so a test advances a
//! synthetic clock and observes the exact trigger boundary. This mirrors the `echo_mq` program's
//! `BatchShaper.Core` (the eg.5.2 precedent), realized here in Rust.

/// Why a batch flushed — surfaced so a caller (and a test) can assert which trigger fired.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FlushReason {
    /// The batch reached `min_size` accepted records.
    Size,
    /// The batch aged past `timeout` since its first record.
    Age,
}

/// The pure shaping policy: a `min_size` threshold and a `timeout` age bound. Holds no records
/// and no clock — it answers "should the open batch flush now?" from the batch's size and age.
#[derive(Debug, Clone, Copy)]
pub struct Shaper {
    min_size: usize,
    timeout_ms: u64,
}

impl Shaper {
    /// A shaper that flushes at `min_size` records or `timeout_ms` of age. A `min_size` of 0 is
    /// clamped to 1 (a batch must hold at least one record to flush on size), and a `timeout_ms`
    /// of 0 means "flush as soon as the batch is non-empty on the next tick" (age-0).
    #[must_use]
    pub fn new(min_size: usize, timeout_ms: u64) -> Self {
        Self { min_size: min_size.max(1), timeout_ms }
    }

    /// The size threshold (after the `max(1)` clamp).
    #[must_use]
    pub fn min_size(&self) -> usize {
        self.min_size
    }

    /// The age bound in milliseconds.
    #[must_use]
    pub fn timeout_ms(&self) -> u64 {
        self.timeout_ms
    }

    /// Decide whether an open batch of `len` records, whose first record arrived at
    /// `first_ms`, should flush at the current clock `now_ms`. Returns the reason if it should,
    /// or `None` if it should keep accumulating. An empty batch (`len == 0`) never flushes.
    ///
    /// The trigger is `min(size_reached, age_reached)`: size is checked first so a batch that
    /// is simultaneously full and aged reports `Size` (a stable tie-break), but either alone
    /// fires. No real clock is read — `now_ms` is the injected time.
    #[must_use]
    pub fn should_flush(&self, len: usize, first_ms: u64, now_ms: u64) -> Option<FlushReason> {
        if len == 0 {
            return None;
        }
        if len >= self.min_size {
            return Some(FlushReason::Size);
        }
        if now_ms.saturating_sub(first_ms) >= self.timeout_ms {
            return Some(FlushReason::Age);
        }
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_batch_never_flushes() {
        let s = Shaper::new(4, 1_000);
        assert_eq!(s.should_flush(0, 0, 10_000), None, "an empty batch never flushes");
    }

    #[test]
    fn flushes_on_size_before_timeout() {
        let s = Shaper::new(3, 1_000);
        // two records, well within the timeout → keep accumulating
        assert_eq!(s.should_flush(2, 100, 200), None);
        // the third record reaches min_size at the SAME instant → flush on size, not time
        assert_eq!(s.should_flush(3, 100, 200), Some(FlushReason::Size));
    }

    #[test]
    fn flushes_on_timeout_before_size() {
        let s = Shaper::new(10, 500);
        // one record, not yet aged → hold
        assert_eq!(s.should_flush(1, 1_000, 1_400), None);
        // aged exactly to the timeout boundary → flush on age (size never reached)
        assert_eq!(s.should_flush(1, 1_000, 1_500), Some(FlushReason::Age));
        // and past it
        assert_eq!(s.should_flush(2, 1_000, 9_999), Some(FlushReason::Age));
    }

    #[test]
    fn the_trigger_is_deterministic_in_the_injected_clock() {
        // S-3: the SAME (len, first, now) always yields the SAME verdict — no real time read.
        let s = Shaper::new(5, 250);
        for _ in 0..1_000 {
            assert_eq!(s.should_flush(3, 10, 200), None);
            assert_eq!(s.should_flush(3, 10, 260), Some(FlushReason::Age));
            assert_eq!(s.should_flush(5, 10, 11), Some(FlushReason::Size));
        }
    }

    #[test]
    fn size_wins_the_tie_when_full_and_aged() {
        // full AND aged at once → Size (the documented stable tie-break)
        let s = Shaper::new(2, 100);
        assert_eq!(s.should_flush(2, 0, 100), Some(FlushReason::Size));
    }

    #[test]
    fn min_size_zero_is_clamped_to_one() {
        let s = Shaper::new(0, 1_000);
        assert_eq!(s.min_size(), 1);
        // a single record immediately satisfies the clamped min_size
        assert_eq!(s.should_flush(1, 0, 0), Some(FlushReason::Size));
    }

    #[test]
    fn timeout_zero_flushes_a_nonempty_batch_at_once() {
        let s = Shaper::new(100, 0);
        // age-0: any non-empty batch flushes on the next decision (age >= 0 always holds)
        assert_eq!(s.should_flush(1, 5, 5), Some(FlushReason::Age));
    }
}
