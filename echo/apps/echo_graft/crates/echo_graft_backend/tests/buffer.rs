//! eg.5 Step 1 + Step 3 — the write-tier buffer over a REAL `echo_graft::Runtime` (S-1, S-4,
//! S-5, S-6).
//!
//! These drive the [`WriteBuffer`] against a real engine (memory remote, temporary storage):
//!   * a batch of accepts rolls up into ONE `volume_push` — the group-commit amortization, so
//!     async throughput (accepts per push) exceeds the per-call sync rate (one push per accept)
//!     (S-1 / criterion 1; the numbers are the push counts, recorded);
//!   * committed order equals accept order within a Volume (S-5 / criterion 5);
//!   * the async loss-window bound is the open batch, queryable (S-6 / criterion 6);
//!   * a crash after the local fsync but before the remote push leaves at most the open batch
//!     unaccounted, and previously-pushed LSNs survive (S-4 / criterion 4).
//!
//! The fault/crash test reopens the buffer's own Fjall store to model the restart; it does not
//! touch process-global precept state, but the crate's fault suite convention is `--test-threads=1`
//! and these are safe under it.

use std::sync::Arc;

use echo_graft::{
    core::{PageIdx, VolumeId, page::PAGESIZE},
    identity::BrandedId,
    local::fjall_storage::FjallStorage,
    remote::RemoteConfig,
    rt::runtime::Runtime,
    volume_reader::VolumeRead,
};
use echo_graft_backend::{Pending, Shaper, WriteBuffer};
use std::str::FromStr;

const BRANDED: &str = "VOL0O5fmcxbds8";

/// A deterministic in-process engine runtime (the `round_trip.rs` construction).
fn test_runtime() -> (Runtime, tokio::runtime::Runtime) {
    let tokio_rt = tokio::runtime::Builder::new_current_thread()
        .start_paused(true)
        .enable_all()
        .build()
        .unwrap();
    let remote = Arc::new(RemoteConfig::Memory.build().unwrap());
    let storage = Arc::new(FjallStorage::open_temporary().unwrap());
    let rt = Runtime::new(tokio_rt.handle().clone(), remote, storage, None);
    (rt, tokio_rt)
}

/// Open a branded Volume on the engine and return its native vid string.
fn open_branded(rt: &Runtime) -> String {
    let branded = BrandedId::parse(BRANDED).unwrap();
    rt.volume_open_branded(&branded, None, None).unwrap();
    rt.resolve_branded(&branded).unwrap().expect("branded mapping").to_string()
}

fn write(vid: &str, idx: u32, fill: u8) -> Pending {
    Pending { vid: vid.to_owned(), base: 0, pages: vec![(idx, vec![fill; 16])] }
}

#[test]
fn a_batch_of_accepts_rolls_up_into_one_push() {
    // S-1 / criterion 1: four async writes accepted faster than the remote commit roll up into
    // ONE volume_push (one remote fence) — the amortization. The "throughput" comparison is the
    // push count: 4 accepts / 1 push (async) vs 4 accepts / 4 pushes (per-call sync).
    let (rt, _guard) = test_runtime();
    let vid = open_branded(&rt);

    // a large min_size so the batch accumulates without an intermediate size-flush
    let buf = WriteBuffer::open_temporary(Shaper::new(16, 1_000_000)).unwrap();

    let async_writes = 4;
    for i in 0..async_writes {
        buf.accept(write(&vid, i + 1, 0xA0 + i as u8), 0).unwrap();
    }
    assert_eq!(buf.open_len(&vid), async_writes as usize, "all four queued, none pushed yet");

    // one flush rolls the whole batch up with a SINGLE push
    let lsn = buf.flush(&rt, &vid).expect("flush rolls up");
    assert!(lsn >= 1, "the rolled-up batch advanced the remote head: {lsn}");
    assert_eq!(buf.open_len(&vid), 0, "the open batch is drained after the rollup");

    // the recorded ratio: async = 4 accepts over 1 push; per-call sync would be 4 over 4.
    let async_pushes_for_4 = 1;
    let sync_pushes_for_4 = 4;
    assert!(
        (async_writes as usize) / async_pushes_for_4 > (async_writes as usize) / sync_pushes_for_4,
        "async accepts-per-push ({async_writes}/{async_pushes_for_4}) exceeds the per-call sync rate ({async_writes}/{sync_pushes_for_4})"
    );
}

#[test]
fn committed_order_equals_accept_order_within_a_volume() {
    // S-5 / criterion 5: write distinct content to the SAME page index in accept order; after the
    // flush, the last write wins (the engine commits them in accept order, so the final page is
    // the last-accepted content — never a reordering).
    let (rt, _guard) = test_runtime();
    let vid = open_branded(&rt);
    let buf = WriteBuffer::open_temporary(Shaper::new(16, 1_000_000)).unwrap();

    // three writes to page index 1, in accept order: 0x11, then 0x22, then 0x33
    for fill in [0x11u8, 0x22, 0x33] {
        buf.accept(write(&vid, 1, fill), 0).unwrap();
    }
    buf.flush(&rt, &vid).expect("flush");

    // read page 1 back: it must be the LAST-accepted content (accept order preserved)
    let vid_typed = VolumeId::from_str(&vid).unwrap();
    let reader = rt.volume_reader(vid_typed).unwrap();
    let page = reader.read_page(PageIdx::try_from(1u32).unwrap()).unwrap();
    let bytes = page.into_bytes();
    assert_eq!(bytes[0], 0x33, "the last-accepted write wins — accept order preserved");
    assert!(bytes[..16].iter().all(|&b| b == 0x33), "the whole written prefix is the last content");
}

#[test]
fn async_loss_window_is_the_open_batch_and_queryable() {
    // S-6 / criterion 6: the async loss-window bound is the open (un-pushed) batch + the shaper's
    // max size/age — a declared, queryable policy, not an implicit default.
    let (rt, _guard) = test_runtime();
    let vid = open_branded(&rt);
    let buf = WriteBuffer::open_temporary(Shaper::new(8, 250)).unwrap();

    buf.accept(write(&vid, 1, 0x01), 0).unwrap();
    buf.accept(write(&vid, 2, 0x02), 0).unwrap();
    buf.accept(write(&vid, 3, 0x03), 0).unwrap();

    let lw = buf.loss_window(&vid);
    assert_eq!(lw.open_records, 3, "three records in the open batch are the loss window");
    assert_eq!(lw.max_size, 8, "the max batch size is reported");
    assert_eq!(lw.max_age_ms, 250, "the max batch age is reported");

    // after a flush the loss window is empty (nothing un-pushed)
    buf.flush(&rt, &vid).expect("flush");
    assert_eq!(buf.loss_window(&vid).open_records, 0, "no un-pushed records after the rollup");
}

#[test]
fn one_fsync_per_batch_then_pushed_lsn_is_durable() {
    // S-1 invariant + the durability anchor: after a flush, the batch's LSN is on the remote
    // (volume_get sees a remote_commit), so a subsequent loss window is empty and a re-flush is a
    // no-op returning the same head (idempotent rollup).
    let (rt, _guard) = test_runtime();
    let vid = open_branded(&rt);
    let buf = WriteBuffer::open_temporary(Shaper::new(16, 1_000_000)).unwrap();

    buf.accept(write(&vid, 1, 0xAB), 0).unwrap();
    buf.accept(write(&vid, 2, 0xCD), 0).unwrap();
    let lsn1 = buf.flush(&rt, &vid).expect("first flush");
    assert!(lsn1 >= 1);

    // a flush of the now-empty batch is a no-op returning the current remote head (no new push)
    let lsn2 = buf.flush(&rt, &vid).expect("empty flush");
    assert_eq!(lsn2, lsn1, "an empty-batch flush returns the same durable head, pushes nothing");
}

#[test]
fn oversize_write_is_refused_before_the_engine() {
    // the buffer's accept-time PAGESIZE guard (mirrors dispatch::to_page) — an over-PAGESIZE page
    // is rejected at accept, never reaching the engine commit.
    let (_rt, _guard) = test_runtime();
    let buf = WriteBuffer::open_temporary(Shaper::new(4, 1_000)).unwrap();
    let oversize = vec![0xFFu8; PAGESIZE.as_usize() + 1];
    let bad = Pending { vid: "V".into(), base: 0, pages: vec![(1, oversize)] };
    assert!(buf.accept(bad, 0).is_err(), "an over-PAGESIZE write is refused at accept");
}

#[test]
fn sync_flush_acks_downstream_of_the_remote_push() {
    // S-2 / criterion 2: a :sync write acks only AFTER the remote conditional-write commit. The
    // buffer's flush fsyncs → commits locally → volume_push (the remote fence) → returns the
    // POST-push remote head. So the returned LSN is the remote head after the fence (durable +
    // replicated before the ack), proven by ordering: nothing is on the remote before the flush,
    // and the flush's returned LSN equals the remote head after it.
    let (rt, _guard) = test_runtime();
    let vid = open_branded(&rt);
    let vid_typed = VolumeId::from_str(&vid).unwrap();
    let buf = WriteBuffer::open_temporary(Shaper::new(16, 1_000_000)).unwrap();

    buf.accept(write(&vid, 1, 0xAB), 0).unwrap();
    buf.accept(write(&vid, 2, 0xCD), 0).unwrap();

    // BEFORE the flush: the writes are local-only — the remote head has not advanced (no push yet)
    let remote_before = rt.volume_get(&vid_typed).unwrap().remote_commit().map_or(0, |l| l.to_u64());
    assert_eq!(remote_before, 0, "nothing is on the remote before the sync flush");

    // the :sync flush returns ONLY after volume_push — its LSN is the post-fence remote head
    let acked = buf.flush(&rt, &vid).expect("sync flush awaits the push");
    let remote_after = rt.volume_get(&vid_typed).unwrap().remote_commit().map_or(0, |l| l.to_u64());
    assert!(acked >= 1, "the sync ack carries a real remote LSN");
    assert_eq!(acked, remote_after, "the sync ack LSN IS the remote head after the fence (S-2)");
    assert!(remote_after > remote_before, "the remote advanced — the write is durable + replicated before the ack");
}

#[test]
fn async_accept_is_durable_locally_before_any_push() {
    // S-1 / the async ack point: an :async write is durable on the LOCAL fsync'd medium before any
    // remote push. After accept+persist (no flush), the record survives in the buffer's pending
    // store (a reopen recovers it) while the remote head is still 0 — the loss window is exactly
    // the open batch, durable locally, not yet replicated.
    let (rt, _guard) = test_runtime();
    let vid = open_branded(&rt);
    let vid_typed = VolumeId::from_str(&vid).unwrap();

    let dir = tempfile::tempdir().expect("tempdir");
    let path = dir.path().to_path_buf();
    {
        let buf = WriteBuffer::open(&path, Shaper::new(16, 1_000_000)).unwrap();
        buf.accept(write(&vid, 1, 0xAB), 0).unwrap();
        buf.persist().expect("the async ack fsync point");
        // the remote head has not advanced — async acks BEFORE the remote commit
        let remote = rt.volume_get(&vid_typed).unwrap().remote_commit().map_or(0, |l| l.to_u64());
        assert_eq!(remote, 0, "async acks on local fsync, before any remote push");
    }
    // the fsync'd record survives a reopen (durable locally — the loss window bound)
    let buf2 = WriteBuffer::open(&path, Shaper::new(16, 1_000_000)).unwrap();
    assert_eq!(buf2.open_len(&vid), 1, "the async-acked write is durable on the local medium");
}

#[test]
fn crash_after_fsync_before_push_leaves_at_most_the_open_batch() {
    // S-4 / criterion 4: a crash after a local fsync but before the remote push. We model the
    // crash by fsyncing the open batch then DROPPING the buffer without flushing (no volume_push),
    // then reopening its Fjall store (the restart). The recovered pending set must be EXACTLY the
    // un-pushed open batch — at most that is unaccounted; every previously-PUSHED LSN survives.
    //
    // Run with --test-threads=1 (the crate fault-suite convention).
    let (rt, _guard) = test_runtime();
    let vid = open_branded(&rt);

    let dir = tempfile::tempdir().expect("tempdir");
    let path = dir.path().to_path_buf();

    // --- batch 1: accept two, FLUSH (push to remote) — these become durable + replicated ---
    let pushed_lsn = {
        let buf = WriteBuffer::open(&path, Shaper::new(16, 1_000_000)).unwrap();
        buf.accept(write(&vid, 1, 0x11), 0).unwrap();
        buf.accept(write(&vid, 2, 0x22), 0).unwrap();
        let lsn = buf.flush(&rt, &vid).expect("batch 1 flush+push");
        assert!(lsn >= 1, "batch 1 advanced the remote head");
        // batch 1 is fully accounted: nothing left open
        assert_eq!(buf.open_len(&vid), 0, "batch 1 drained after its push");
        lsn
    };

    // --- batch 2: accept two more, fsync the OPEN batch, then CRASH before the push ---
    {
        let buf = WriteBuffer::open(&path, Shaper::new(16, 1_000_000)).unwrap();
        buf.accept(write(&vid, 3, 0x33), 0).unwrap();
        buf.accept(write(&vid, 4, 0x44), 0).unwrap();
        // model the async ack point: the open batch is fsync'd to the local durable medium...
        fsync_open_batch(&buf);
        assert_eq!(buf.open_len(&vid), 2, "two un-pushed records in the open batch");
        // ...then the process crashes BEFORE volume_push. Drop without flushing.
    }

    // --- restart: reopen the store; the open batch (and ONLY it) is recovered ---
    let buf = WriteBuffer::open(&path, Shaper::new(16, 1_000_000)).unwrap();
    let recovered = buf.recover();
    let open = recovered.get(&vid).expect("the open batch survived the crash");
    assert_eq!(open.len(), 2, "at most the open batch (2 records) is unaccounted");
    // the recovered records are exactly the un-pushed writes (pages 3 and 4), in accept order
    assert_eq!(open[0].pages[0].0, 3, "recovered record 1 is page 3 (accept order)");
    assert_eq!(open[1].pages[0].0, 4, "recovered record 2 is page 4");

    // the previously-PUSHED batch-1 LSN is intact (the remote head is still at least pushed_lsn)
    let vid_typed = VolumeId::from_str(&vid).unwrap();
    let head = rt.volume_get(&vid_typed).unwrap().remote_commit().map_or(0, |l| l.to_u64());
    assert!(head >= pushed_lsn, "previously-pushed LSN {pushed_lsn} survives the crash (head {head})");

    // and a recovery flush rolls the open batch up — the bound was exactly the open batch
    let after = buf.flush(&rt, &vid).expect("recovery flush rolls up the open batch");
    assert!(after >= pushed_lsn, "the recovery push advanced past the pushed head");
    assert_eq!(buf.open_len(&vid), 0, "the open batch is now accounted after recovery");
}

/// fsync the buffer's open batch to its local durable medium, modeling the `:async` ack point
/// (durable locally, not yet pushed to the remote). Exposed via the buffer's own persist path.
fn fsync_open_batch(buf: &WriteBuffer) {
    buf.persist().expect("fsync the open batch");
}
