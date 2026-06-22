//! The bounded, durable local-fsync write buffer (eg.5, S-1/S-4/S-5/S-6).
//!
//! The write tier accepts hot-path writes into a per-Volume buffer, fsyncs the open batch once
//! to a **local durable medium**, and rolls the batch up into one remote `volume_push`
//! (`runtime.rs:239`, the eg.2 conditional-write fence). Amortizing one fsync over a batch gives
//! low-latency durable writes with few syscalls; the async rollup gives replication.
//!
//! ## The medium (the ruled A-3 realization, cited)
//!
//! A-3 rules the buffer "rides the engine's existing durable Fjall store". The engine's
//! [`FjallStorage`](echo_graft::local::fjall_storage) is byte-frozen (the eg.5 boundary keeps
//! `crates/echo_graft` untouched) and its keyspaces + its `fjall_typed` wrapper are private, so
//! the buffer cannot write into the engine's store without editing the frozen engine. The
//! behavior-identical realization: this buffer owns its **own** `fjall::Database` + a single
//! `pending` keyspace — the SAME durable medium (an fsync is `Database::persist(SyncAll)`,
//! `db.rs:353`), inside the `echo_graft_backend` boundary. Deviation flagged: own-Database, not
//! the engine's private store.
//!
//! ## Durability + recovery (S-4)
//!
//! Each accepted write is appended to the `pending` keyspace and the batch is fsync'd on flush
//! (`PersistMode::SyncAll`). A record is removed only AFTER its batch's `volume_push` acks and
//! that removal is itself fsync'd — so a crash between the local fsync and the remote push leaves
//! the un-pushed records in `pending` (the "open batch"), and on restart [`WriteBuffer::recover`]
//! reads exactly that set. The bound is therefore: the unaccounted set ⊆ the open batch; every
//! previously-pushed LSN is already durable in the engine and removed from `pending`.
//!
//! ## Order (S-5)
//!
//! Records key on `{vid}\0{seq:020}` with a monotone per-buffer `seq`, so the keyspace's sort
//! order within a `{vid}` prefix IS accept order; a flush replays them in that order, and the
//! engine commits them in that order — committed order equals accept order.

use std::collections::BTreeMap;
use std::sync::atomic::{AtomicU64, Ordering};

use echo_graft::core::{PageIdx, VolumeId, page::PAGESIZE};
use echo_graft::rt::runtime::Runtime;
use echo_graft::volume_writer::VolumeWrite;
use fjall::{Database, KeyspaceCreateOptions, PersistMode};

use crate::shaper::{FlushReason, Shaper};

/// The keyspace name for the pending write records.
const PENDING: &str = "egraft_buffer_pending";

/// A single accepted-but-not-yet-rolled-up write: the staged pages of one logical commit for a
/// Volume. The `base` is advisory (the engine's own snapshot is the authoritative base; a stale
/// base surfaces as the OCC conflict at commit, mirroring `dispatch::commit`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Pending {
    /// The native Volume id this write targets.
    pub vid: String,
    /// The advisory base LSN the write extended (diagnostic only).
    pub base: u64,
    /// The staged pages as `(page_index, page_bytes)` — the wire `Commit.pages` shape.
    pub pages: Vec<(u32, Vec<u8>)>,
}

/// An error from the write buffer.
#[derive(Debug)]
pub enum BufferErr {
    /// The underlying Fjall store failed.
    Fjall(fjall::Error),
    /// A record could not be (de)serialized.
    Codec(&'static str),
    /// The engine rejected the rolled-up commit/push (carried as its display string + kind).
    Engine(echo_graft::GraftErr),
    /// A page index or page size was malformed.
    BadWrite(String),
}

impl std::fmt::Display for BufferErr {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BufferErr::Fjall(e) => write!(f, "buffer store: {e}"),
            BufferErr::Codec(s) => write!(f, "buffer record codec: {s}"),
            BufferErr::Engine(e) => write!(f, "buffer rollup: {e}"),
            BufferErr::BadWrite(s) => write!(f, "buffer bad write: {s}"),
        }
    }
}

impl std::error::Error for BufferErr {}

impl From<fjall::Error> for BufferErr {
    fn from(e: fjall::Error) -> Self {
        BufferErr::Fjall(e)
    }
}

/// A bounded, durable, per-Volume group-commit buffer over an own-`Database` `pending`
/// keyspace. Accept appends a durable record; flush fsyncs the batch, rolls it up through the
/// engine commit + one `volume_push`, then durably removes the flushed records.
pub struct WriteBuffer {
    db: Database,
    pending: fjall::Keyspace,
    seq: AtomicU64,
    shaper: Shaper,
    /// The first-accept clock per Volume (epoch ms), for the shaper's age trigger. Cleared
    /// when a Volume's batch flushes. Injected clock — never read from `SystemTime` here.
    first_ms: parking_lot::Mutex<BTreeMap<String, u64>>,
}

impl WriteBuffer {
    /// Open a buffer at `path` (its own Fjall database) with the given shaping policy. On reopen
    /// the `pending` keyspace is recovered as-is (durable records survive — S-4); the `seq`
    /// resumes past the highest pending key so a recovered buffer never reuses a key.
    pub fn open<P: AsRef<std::path::Path>>(path: P, shaper: Shaper) -> Result<Self, BufferErr> {
        let db = Database::builder(path).open()?;
        Self::from_db(db, shaper)
    }

    /// Open a temporary buffer (a tempdir Fjall database) — the test construction.
    pub fn open_temporary(shaper: Shaper) -> Result<Self, BufferErr> {
        let path = tempfile::tempdir().map_err(|e| BufferErr::Fjall(e.into()))?.keep();
        let db = Database::builder(path).temporary(true).open()?;
        Self::from_db(db, shaper)
    }

    fn from_db(db: Database, shaper: Shaper) -> Result<Self, BufferErr> {
        let pending = db.keyspace(PENDING, KeyspaceCreateOptions::default)?;
        // Resume seq past the highest existing pending key so a recovered buffer never collides.
        let resume = pending
            .iter()
            .filter_map(|g| g.into_inner().ok())
            .filter_map(|(k, _)| seq_of_key(&k))
            .max()
            .map_or(0, |m| m + 1);
        Ok(Self {
            db,
            pending,
            seq: AtomicU64::new(resume),
            shaper,
            first_ms: parking_lot::Mutex::new(BTreeMap::new()),
        })
    }

    /// The shaping policy in force.
    #[must_use]
    pub fn shaper(&self) -> &Shaper {
        &self.shaper
    }

    /// fsync the buffer's durable medium to disk (`PersistMode::SyncAll`). This is the local-fsync
    /// durability point an `:async` ack returns on: after it, every accepted-but-not-yet-flushed
    /// record survives a crash (it is in the fsync'd `pending` keyspace) — the loss window is
    /// exactly the open batch (S-4). The flush path fsyncs internally; this is the explicit
    /// async-ack fsync a caller invokes after a batch of accepts before returning to the client.
    pub fn persist(&self) -> Result<(), BufferErr> {
        self.db.persist(PersistMode::SyncAll)?;
        Ok(())
    }

    /// Accept one write into the Volume's open batch: append a durable record (NOT yet fsync'd —
    /// the fsync is amortized to the flush) and record the batch's first-accept clock. Returns
    /// the current open-batch length for that Volume after the accept, so a caller can consult
    /// the shaper. The page bytes are validated against `PAGESIZE` here (over-size is rejected
    /// before it ever reaches the engine), mirroring `dispatch::to_page`'s bound.
    pub fn accept(&self, write: Pending, now_ms: u64) -> Result<usize, BufferErr> {
        for (idx, bytes) in &write.pages {
            if bytes.len() > PAGESIZE.as_usize() {
                return Err(BufferErr::BadWrite(format!(
                    "page {idx} over {} bytes ({})",
                    PAGESIZE.as_usize(),
                    bytes.len()
                )));
            }
        }
        let seq = self.seq.fetch_add(1, Ordering::SeqCst);
        let key = record_key(&write.vid, seq);
        let val = encode_pending(&write);
        self.pending.insert(key, val)?;
        let mut first = self.first_ms.lock();
        first.entry(write.vid.clone()).or_insert(now_ms);
        Ok(self.open_len(&write.vid))
    }

    /// Whether the Volume's open batch should flush at `now_ms`, per the injected-clock shaper.
    #[must_use]
    pub fn should_flush(&self, vid: &str, now_ms: u64) -> Option<FlushReason> {
        let len = self.open_len(vid);
        let first = self.first_ms.lock().get(vid).copied().unwrap_or(now_ms);
        self.shaper.should_flush(len, first, now_ms)
    }

    /// The number of records in a Volume's open (not-yet-rolled-up) batch.
    #[must_use]
    pub fn open_len(&self, vid: &str) -> usize {
        self.pending_for(vid).len()
    }

    /// The loss-window bound for a Volume configured `:async` (S-6): the open-batch size and the
    /// shaper's max size/age. The records in the open batch are exactly what an `:async` ack has
    /// not yet pushed — so this is the declared, queryable bound, not an implicit default.
    #[must_use]
    pub fn loss_window(&self, vid: &str) -> LossWindow {
        LossWindow {
            open_records: self.open_len(vid),
            max_size: self.shaper.min_size(),
            max_age_ms: self.shaper.timeout_ms(),
        }
    }

    /// Flush a Volume's open batch: fsync the pending records, replay them through the engine in
    /// accept order (one `volume_writer`/`commit` per record), then ONE `volume_push` to roll the
    /// whole batch up to the remote, then durably remove the flushed records. Returns the post-push
    /// remote head LSN (the ack the caller surfaces). A flush of an empty batch is a no-op
    /// returning the Volume's current remote head.
    ///
    /// Order of durability (S-4): the fsync of `pending` happens BEFORE the push; the removal +
    /// its fsync happen AFTER the push acks. So a crash before the push leaves the records in
    /// `pending` (recovered on restart); a crash after the push but before removal leaves them too
    /// — a re-flush is idempotent on the engine (the pages re-commit to the same content; a stale
    /// base loses to OCC, not a double-apply of new state), and the records are then removed.
    pub fn flush(&self, rt: &Runtime, vid: &str) -> Result<u64, BufferErr> {
        let batch = self.pending_for(vid);
        if batch.is_empty() {
            return Ok(self.remote_head(rt, vid));
        }

        // (1) fsync the open batch to the local durable medium BEFORE any remote work.
        self.db.persist(PersistMode::SyncAll)?;

        // (2) replay each record through the engine in accept order: a per-record commit, then
        //     ONE push for the whole batch (the group-commit rollup).
        let vid_typed = parse_vid(vid)?;
        for (_key, rec) in &batch {
            self.apply_one(rt, &vid_typed, rec)?;
        }
        rt.volume_push(vid_typed.clone()).map_err(BufferErr::Engine)?;

        // (3) durably remove the flushed records (so they are not re-applied on restart) and
        //     clear the batch's first-accept clock.
        for (key, _rec) in &batch {
            self.pending.remove(key.clone())?;
        }
        self.db.persist(PersistMode::SyncAll)?;
        self.first_ms.lock().remove(vid);

        Ok(self.remote_head(rt, &vid_typed.to_string()))
    }

    /// Recover the open batch after a restart (S-4): the records still in `pending`, grouped by
    /// Volume, in accept order. This is exactly the set a crash-before-push left unaccounted; the
    /// caller (or a recovery sweep) re-flushes each Volume to roll them up.
    #[must_use]
    pub fn recover(&self) -> BTreeMap<String, Vec<Pending>> {
        let mut out: BTreeMap<String, Vec<Pending>> = BTreeMap::new();
        for guard in self.pending.iter() {
            let Ok((k, v)) = guard.into_inner() else { continue };
            let Some(vid) = vid_of_key(&k) else { continue };
            if let Some(rec) = decode_pending(&v) {
                out.entry(vid).or_default().push(rec);
            }
        }
        out
    }

    /// The records of a Volume's open batch as `(key, record)` in accept (key-sort) order.
    fn pending_for(&self, vid: &str) -> Vec<(Vec<u8>, Pending)> {
        let mut prefix = vid.as_bytes().to_vec();
        prefix.push(0);
        let mut out = Vec::new();
        for guard in self.pending.prefix(&prefix) {
            let Ok((k, v)) = guard.into_inner() else { continue };
            if let Some(rec) = decode_pending(&v) {
                out.push((k.to_vec(), rec));
            }
        }
        out
    }

    /// Replay one record through the engine: build a writer at the Volume's current snapshot,
    /// write each page (padded to PAGESIZE — the `dispatch::to_page` realization), and commit.
    fn apply_one(&self, rt: &Runtime, vid: &VolumeId, rec: &Pending) -> Result<(), BufferErr> {
        let mut writer = rt.volume_writer(vid.clone()).map_err(BufferErr::Engine)?;
        for (idx, bytes) in &rec.pages {
            let pageidx = PageIdx::try_from(*idx)
                .map_err(|_| BufferErr::BadWrite(format!("bad page index {idx}")))?;
            let page = to_page(bytes)?;
            writer.write_page(pageidx, page).map_err(BufferErr::Engine)?;
        }
        writer.commit().map_err(BufferErr::Engine)?;
        Ok(())
    }

    /// The Volume's current remote head LSN (0 if none / unknown).
    fn remote_head(&self, rt: &Runtime, vid: &str) -> u64 {
        let Ok(v) = parse_vid(vid) else { return 0 };
        rt.volume_get(&v)
            .ok()
            .and_then(|vol| vol.remote_commit())
            .map_or(0, |lsn| lsn.to_u64())
    }
}

/// The async loss-window bound for a Volume (S-6) — the declared, queryable policy.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct LossWindow {
    /// The records currently in the open (un-pushed) batch — what an async ack has not yet pushed.
    pub open_records: usize,
    /// The shaper's max batch size (the size bound a batch flushes at).
    pub max_size: usize,
    /// The shaper's max batch age in ms (the age bound a batch flushes at).
    pub max_age_ms: u64,
}

// ---- record codec (a small length-prefixed framing; the buffer owns its own at-rest format) ----

/// Encode a pending record: `base:u64-le | npages:u32-le | (idx:u32-le, len:u32-le, bytes)*`.
/// The vid is the key, not the value, so it is not duplicated here.
fn encode_pending(p: &Pending) -> Vec<u8> {
    let mut out = Vec::new();
    out.extend_from_slice(&p.base.to_le_bytes());
    out.extend_from_slice(&(p.pages.len() as u32).to_le_bytes());
    for (idx, bytes) in &p.pages {
        out.extend_from_slice(&idx.to_le_bytes());
        out.extend_from_slice(&(bytes.len() as u32).to_le_bytes());
        out.extend_from_slice(bytes);
    }
    out
}

/// Decode a pending record value (the `vid` is supplied by the caller from the key).
fn decode_pending_with_vid(vid: String, v: &[u8]) -> Option<Pending> {
    let mut pos = 0usize;
    let base = u64::from_le_bytes(v.get(pos..pos + 8)?.try_into().ok()?);
    pos += 8;
    let npages = u32::from_le_bytes(v.get(pos..pos + 4)?.try_into().ok()?) as usize;
    pos += 4;
    let mut pages = Vec::with_capacity(npages);
    for _ in 0..npages {
        let idx = u32::from_le_bytes(v.get(pos..pos + 4)?.try_into().ok()?);
        pos += 4;
        let len = u32::from_le_bytes(v.get(pos..pos + 4)?.try_into().ok()?) as usize;
        pos += 4;
        let bytes = v.get(pos..pos + len)?.to_vec();
        pos += len;
        pages.push((idx, bytes));
    }
    Some(Pending { vid, base, pages })
}

/// Decode a pending record value, leaving `Pending.vid` empty. The vid lives in the key, not the
/// value: `recover` groups the records under the key-derived vid (its map key) and `flush` reads
/// `pending_for(vid)` with the vid passed in, so neither consumer reads `Pending.vid` on a decoded
/// record. A thin wrapper keeping the codec symmetric with `encode_pending`.
fn decode_pending(v: &[u8]) -> Option<Pending> {
    decode_pending_with_vid(String::new(), v)
}

// ---- key layout: `{vid}\0{seq:020}` — vid-prefix groups a Volume; seq orders within it ----

fn record_key(vid: &str, seq: u64) -> Vec<u8> {
    let mut k = vid.as_bytes().to_vec();
    k.push(0);
    // 20-digit zero-padded decimal so byte-sort == numeric seq order (FIFO within a vid).
    k.extend_from_slice(format!("{seq:020}").as_bytes());
    k
}

/// The vid prefix of a record key (the bytes before the `\0`).
fn vid_of_key(key: &[u8]) -> Option<String> {
    let nul = key.iter().position(|&b| b == 0)?;
    std::str::from_utf8(&key[..nul]).ok().map(str::to_owned)
}

/// The seq suffix of a record key (the 20-digit decimal after the `\0`).
fn seq_of_key(key: &[u8]) -> Option<u64> {
    let nul = key.iter().position(|&b| b == 0)?;
    std::str::from_utf8(&key[nul + 1..]).ok()?.parse::<u64>().ok()
}

// ---- shared page realization (mirrors dispatch::to_page; the buffer commits real pages) ----

fn parse_vid(vid: &str) -> Result<VolumeId, BufferErr> {
    use std::str::FromStr;
    VolumeId::from_str(vid).map_err(|_| BufferErr::BadWrite(format!("bad volume id {vid}")))
}

fn to_page(bytes: &[u8]) -> Result<echo_graft::core::page::Page, BufferErr> {
    use bytes::Bytes;
    let size = PAGESIZE.as_usize();
    if bytes.len() > size {
        return Err(BufferErr::BadWrite(format!("page over {size} bytes ({})", bytes.len())));
    }
    let mut buf = Vec::with_capacity(size);
    buf.extend_from_slice(bytes);
    buf.resize(size, 0);
    echo_graft::core::page::Page::from_buf(Bytes::from(buf))
        .map_err(|e| BufferErr::BadWrite(e.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn rec(vid: &str, base: u64, pages: Vec<(u32, Vec<u8>)>) -> Pending {
        Pending { vid: vid.to_owned(), base, pages }
    }

    #[test]
    fn record_codec_round_trips() {
        let p = rec("VID", 7, vec![(1, vec![0xAB, 0xCD]), (9, vec![])]);
        let bytes = encode_pending(&p);
        let back = decode_pending_with_vid("VID".to_owned(), &bytes).expect("decode");
        assert_eq!(back, p);
    }

    #[test]
    fn key_orders_by_seq_within_a_vid() {
        // byte-sort of the keys must equal numeric seq order (the FIFO/S-5 property)
        let k0 = record_key("VID", 0);
        let k1 = record_key("VID", 1);
        let k10 = record_key("VID", 10);
        let k2 = record_key("VID", 2);
        let mut keys = [k10.clone(), k0.clone(), k2.clone(), k1.clone()];
        keys.sort();
        assert_eq!(keys, [k0, k1, k2, k10], "lexical key sort == numeric seq order");
    }

    #[test]
    fn key_roundtrips_vid_and_seq() {
        let k = record_key("3QJmnh7Yx2Kp9Wd5Lr8Tz4B", 42);
        assert_eq!(vid_of_key(&k).as_deref(), Some("3QJmnh7Yx2Kp9Wd5Lr8Tz4B"));
        assert_eq!(seq_of_key(&k), Some(42));
    }

    #[test]
    fn accept_appends_durably_and_open_len_tracks() {
        let buf = WriteBuffer::open_temporary(Shaper::new(4, 1_000)).expect("open");
        assert_eq!(buf.open_len("VID"), 0);
        let n1 = buf.accept(rec("VID", 0, vec![(1, vec![0x01])]), 100).expect("accept");
        assert_eq!(n1, 1);
        let n2 = buf.accept(rec("VID", 0, vec![(2, vec![0x02])]), 110).expect("accept");
        assert_eq!(n2, 2);
        assert_eq!(buf.open_len("VID"), 2);
        // a different Volume is isolated
        assert_eq!(buf.open_len("OTHER"), 0);
    }

    #[test]
    fn shaper_drives_flush_decision_on_the_buffer() {
        let buf = WriteBuffer::open_temporary(Shaper::new(3, 500)).expect("open");
        buf.accept(rec("VID", 0, vec![(1, vec![0x01])]), 1_000).expect("accept");
        // one record, not aged → hold
        assert_eq!(buf.should_flush("VID", 1_100), None);
        // aged past the timeout → Age
        assert_eq!(buf.should_flush("VID", 1_500), Some(FlushReason::Age));
        buf.accept(rec("VID", 0, vec![(2, vec![0x02])]), 1_100).expect("accept");
        buf.accept(rec("VID", 0, vec![(3, vec![0x03])]), 1_100).expect("accept");
        // three records → Size (regardless of age)
        assert_eq!(buf.should_flush("VID", 1_100), Some(FlushReason::Size));
    }

    #[test]
    fn loss_window_reports_the_open_batch_and_the_bounds() {
        let buf = WriteBuffer::open_temporary(Shaper::new(8, 250)).expect("open");
        buf.accept(rec("VID", 0, vec![(1, vec![0x01])]), 0).expect("accept");
        buf.accept(rec("VID", 0, vec![(2, vec![0x02])]), 0).expect("accept");
        let lw = buf.loss_window("VID");
        assert_eq!(lw.open_records, 2, "two un-pushed records");
        assert_eq!(lw.max_size, 8);
        assert_eq!(lw.max_age_ms, 250);
    }

    #[test]
    fn oversize_page_is_rejected_at_accept() {
        let buf = WriteBuffer::open_temporary(Shaper::new(4, 1_000)).expect("open");
        let oversize = vec![0xFF_u8; PAGESIZE.as_usize() + 1];
        let err = buf.accept(rec("VID", 0, vec![(1, oversize)]), 0).expect_err("over-size rejected");
        assert!(matches!(err, BufferErr::BadWrite(_)), "got {err:?}");
        // nothing was appended
        assert_eq!(buf.open_len("VID"), 0);
    }

    #[test]
    fn recover_groups_pending_by_vid_in_order() {
        let buf = WriteBuffer::open_temporary(Shaper::new(100, 100_000)).expect("open");
        buf.accept(rec("VIDA", 0, vec![(1, vec![0x01])]), 0).expect("accept");
        buf.accept(rec("VIDB", 0, vec![(7, vec![0x07])]), 0).expect("accept");
        buf.accept(rec("VIDA", 0, vec![(2, vec![0x02])]), 0).expect("accept");
        let recovered = buf.recover();
        let a = recovered.get("VIDA").expect("VIDA present");
        assert_eq!(a.len(), 2);
        assert_eq!(a[0].pages[0].0, 1, "accept order preserved within VIDA");
        assert_eq!(a[1].pages[0].0, 2);
        assert_eq!(recovered.get("VIDB").expect("VIDB present").len(), 1);
    }

    #[test]
    fn seq_resumes_past_pending_on_reopen() {
        let dir = tempfile::tempdir().expect("tempdir");
        let path = dir.path().to_path_buf();
        {
            let buf = WriteBuffer::open(&path, Shaper::new(100, 100_000)).expect("open");
            buf.accept(rec("VID", 0, vec![(1, vec![0x01])]), 0).expect("accept");
            buf.accept(rec("VID", 0, vec![(2, vec![0x02])]), 0).expect("accept");
            buf.db.persist(PersistMode::SyncAll).expect("fsync");
        }
        // reopen: the two pending records survive (S-4) and seq resumes (no key collision)
        let buf2 = WriteBuffer::open(&path, Shaper::new(100, 100_000)).expect("reopen");
        assert_eq!(buf2.open_len("VID"), 2, "pending records survived reopen");
        let next = buf2.seq.load(Ordering::SeqCst);
        assert_eq!(next, 2, "seq resumed past the highest pending key (0,1 → next 2)");
    }
}
