//! The 1:1 request dispatch onto the real `echo_graft::Runtime` (eg.4).
//!
//! Every arm here grounds in the [`Runtime`] method map (`runtime.rs`): the backend adds NO
//! engine logic, only translation between the `echo_graft_proto` wire and the engine's
//! native types, plus the closed error mapping. The handshake (`Hello`/`Welcome`/…) and the
//! feed publish are handled by [`crate::session::Session`]; this module handles the
//! correlation-id request/response verbs.

use bytes::Bytes;
use echo_graft::{
    GraftErr, LogicalErr,
    core::{
        LogId, PageIdx, VolumeId,
        lsn::LSN,
        page::{PAGESIZE, Page},
    },
    identity::BrandedId,
    rt::runtime::Runtime,
    volume_reader::VolumeRead,
    volume_writer::VolumeWrite,
};
use echo_graft_proto::{ErrKind, Mode, Msg};
use std::str::FromStr;

/// Dispatch one decoded request message onto `rt`, returning the response message to send
/// back on the command lane. Only the request variants are handled here; a non-request (a
/// handshake or a response/feed echoed back) is a protocol misuse mapped to an
/// `unavailable` error so the session never panics on unexpected input.
///
/// Each request echoes its `corr` on the response. Engine errors map to the closed
/// [`ErrKind`] taxonomy by `map_err`; nothing else can leave this function.
pub fn dispatch(rt: &Runtime, msg: &Msg) -> Msg {
    match msg {
        Msg::OpenVolume { corr, branded, local, remote } => {
            open_volume(rt, *corr, branded, local.as_deref(), remote.as_deref())
        }
        Msg::ResolveBranded { corr, branded } => resolve_branded(rt, *corr, branded),
        Msg::Commit { corr, vid, base, mode, pages } => commit(rt, *corr, vid, *base, *mode, pages),
        Msg::Push { corr, vid } => push(rt, *corr, vid),
        Msg::Pull { corr, vid } => pull(rt, *corr, vid),
        Msg::Read { corr, vid, pageidx } => read(rt, *corr, vid, *pageidx),
        Msg::Snapshot { corr, vid } => snapshot(rt, *corr, vid),
        Msg::GetCommit { corr, log, lsn } => get_commit(rt, *corr, log, *lsn),
        // A handshake or a response/feed arriving on the request path is misuse; refuse it
        // without touching a Volume. `corr` is unknown for the tagless ones, so use 0.
        other => Msg::Err {
            corr: corr_of(other),
            kind: ErrKind::Unavailable,
            detail: "not a request message on the command lane".to_owned(),
        },
    }
}

/// `OpenVolume` → `volume_open_branded` (`runtime.rs:185`). Acks the head LSN (0 for a fresh
/// Volume — `remote_commit` is `None` until the first push).
fn open_volume(
    rt: &Runtime,
    corr: u64,
    branded: &str,
    local: Option<&str>,
    remote: Option<&str>,
) -> Msg {
    let branded = match BrandedId::parse(branded) {
        Ok(b) => b,
        Err(e) => return err(corr, ErrKind::NotFound, format!("bad branded id: {e}")),
    };
    let local = match opt_log(local) {
        Ok(l) => l,
        Err(d) => return err(corr, ErrKind::NotFound, d),
    };
    let remote = match opt_log(remote) {
        Ok(r) => r,
        Err(d) => return err(corr, ErrKind::NotFound, d),
    };
    match rt.volume_open_branded(&branded, local, remote) {
        Ok(volume) => Msg::Ack {
            corr,
            lsn: volume.remote_commit().map_or(0, LSN::to_u64),
        },
        Err(e) => map_err(corr, e),
    }
}

/// `ResolveBranded` → `resolve_branded` (`runtime.rs:198`). Acks the native vid via `Pages`
/// (the only string-bearing response), or `not_found` if the mapping is absent.
fn resolve_branded(rt: &Runtime, corr: u64, branded: &str) -> Msg {
    let branded = match BrandedId::parse(branded) {
        Ok(b) => b,
        Err(e) => return err(corr, ErrKind::NotFound, format!("bad branded id: {e}")),
    };
    match rt.resolve_branded(&branded) {
        Ok(Some(vid)) => Msg::Pages { corr, data: vid.to_string().into_bytes() },
        Ok(None) => err(corr, ErrKind::NotFound, "no such branded volume".to_owned()),
        Err(e) => map_err(corr, e),
    }
}

/// `Commit` → `volume_writer(vid)` then `write_page`×N then `commit` (`runtime.rs:298`,
/// `volume_writer.rs:68-92`). Acks the resulting head LSN.
///
/// The per-call durability [`Mode`] is a *host* signal — it chooses WHEN the host acks relative
/// to the remote rollup (`:sync` waits for `volume_push`; `:async` acks on the local fsync); it
/// does NOT change what this 1:1 dispatch does to the engine. The dispatch always performs the
/// LOCAL commit and acks the local head LSN (the remote push is the separate `Push` verb / the
/// buffer's rollup). `mode` is accepted here so the v2 request is well-formed and faithful; the
/// mode's guarantee is enforced where the push happens (the buffer, S-2). It is threaded into the
/// diagnostics only.
///
/// REALIZATION (cited deviation from the naive "wire bytes → Page"): the proto carries
/// arbitrary-length page `bytes`, but `Page` is fixed `PAGESIZE` (4 KiB, `page.rs:11`;
/// `Page::from_buf` rejects any other length, `page.rs:44`). A short page is right-padded
/// with zeros to `PAGESIZE` (the engine's own empty-page fill); an over-`PAGESIZE` page is a
/// malformed request refused with `unavailable` — never a panic.
fn commit(rt: &Runtime, corr: u64, vid: &str, base: u64, mode: Mode, pages: &[(u32, Vec<u8>)]) -> Msg {
    let vid = match parse_vid(vid) {
        Ok(v) => v,
        Err(d) => return err(corr, ErrKind::NotFound, d),
    };
    // Both `base` and `mode` are advisory in this thin dispatch: the writer is built from the
    // Volume's current snapshot (the engine's own base), a stale base surfaces as the OCC
    // conflict at `commit`, and the mode is a host ack-timing signal (the push is separate). They
    // are threaded only into the detail for diagnostics.
    let _ = (base, mode);
    let mut writer = match rt.volume_writer(vid) {
        Ok(w) => w,
        Err(e) => return map_err(corr, e),
    };
    for (idx, bytes) in pages {
        let pageidx = match PageIdx::try_from(*idx) {
            Ok(p) => p,
            Err(_) => return err(corr, ErrKind::Unavailable, format!("bad page index {idx}")),
        };
        let page = match to_page(bytes) {
            Ok(p) => p,
            Err(d) => return err(corr, ErrKind::Unavailable, d),
        };
        if let Err(e) = writer.write_page(pageidx, page) {
            return map_err(corr, e);
        }
    }
    match writer.commit() {
        Ok(reader) => Msg::Ack {
            corr,
            lsn: reader.snapshot().head().map_or(0, |(_, lsn)| lsn.to_u64()),
        },
        Err(e) => map_err(corr, e),
    }
}

/// `Push` → `volume_push` (`runtime.rs:239`) — the conditional-write fence + feed publish.
/// Acks the post-push remote head LSN (0 if nothing advanced).
fn push(rt: &Runtime, corr: u64, vid: &str) -> Msg {
    let vid = match parse_vid(vid) {
        Ok(v) => v,
        Err(d) => return err(corr, ErrKind::NotFound, d),
    };
    match rt.volume_push(vid.clone()) {
        Ok(()) => match rt.volume_get(&vid) {
            Ok(volume) => Msg::Ack { corr, lsn: volume.remote_commit().map_or(0, LSN::to_u64) },
            Err(e) => map_err(corr, e),
        },
        Err(e) => map_err(corr, e),
    }
}

/// `Pull` → `volume_pull` (`runtime.rs:223`). Acks the post-pull remote head LSN.
fn pull(rt: &Runtime, corr: u64, vid: &str) -> Msg {
    let vid = match parse_vid(vid) {
        Ok(v) => v,
        Err(d) => return err(corr, ErrKind::NotFound, d),
    };
    match rt.volume_pull(vid.clone()) {
        Ok(()) => match rt.volume_get(&vid) {
            Ok(volume) => Msg::Ack { corr, lsn: volume.remote_commit().map_or(0, LSN::to_u64) },
            Err(e) => map_err(corr, e),
        },
        Err(e) => map_err(corr, e),
    }
}

/// `Read` → `volume_reader(vid)` then `read_page` (`runtime.rs:293`, `:91`). Returns the raw
/// page bytes in `Pages` (only ever a `Read`-requested page crosses the bus as raw bytes).
fn read(rt: &Runtime, corr: u64, vid: &str, pageidx: u32) -> Msg {
    let vid = match parse_vid(vid) {
        Ok(v) => v,
        Err(d) => return err(corr, ErrKind::NotFound, d),
    };
    let pageidx = match PageIdx::try_from(pageidx) {
        Ok(p) => p,
        Err(_) => return err(corr, ErrKind::Unavailable, format!("bad page index {pageidx}")),
    };
    let reader = match rt.volume_reader(vid) {
        Ok(r) => r,
        Err(e) => return map_err(corr, e),
    };
    match reader.read_page(pageidx) {
        Ok(page) => Msg::Pages { corr, data: page.into_bytes().to_vec() },
        Err(e) => map_err(corr, e),
    }
}

/// `Snapshot` → `volume_snapshot(vid)` (`runtime.rs:289`). Returns the head LSN + page count.
fn snapshot(rt: &Runtime, corr: u64, vid: &str) -> Msg {
    let vid = match parse_vid(vid) {
        Ok(v) => v,
        Err(d) => return err(corr, ErrKind::NotFound, d),
    };
    match rt.volume_snapshot(&vid) {
        Ok(snapshot) => Msg::SnapshotResp {
            corr,
            lsn: snapshot.head().map_or(0, |(_, lsn)| lsn.to_u64()),
            pages: snapshot.page_count.to_u32(),
        },
        Err(e) => map_err(corr, e),
    }
}

/// `GetCommit` → `get_commit(&LogId, LSN)` (`runtime.rs:310`). Acks the LSN when the commit
/// exists; `not_found` when it does not.
fn get_commit(rt: &Runtime, corr: u64, log: &str, lsn: u64) -> Msg {
    let log = match LogId::from_str(log) {
        Ok(l) => l,
        Err(_) => return err(corr, ErrKind::NotFound, format!("bad log id {log}")),
    };
    let lsn_typed = match LSN::try_from(lsn) {
        Ok(l) => l,
        Err(_) => return err(corr, ErrKind::NotFound, format!("bad lsn {lsn}")),
    };
    match rt.get_commit(&log, lsn_typed) {
        Ok(Some(_commit)) => Msg::Ack { corr, lsn },
        Ok(None) => err(corr, ErrKind::NotFound, "no such commit".to_owned()),
        Err(e) => map_err(corr, e),
    }
}

// ---- translation helpers ----

/// Parse a native vid string; a bad id is `not_found` (a vid that does not address a Volume).
fn parse_vid(vid: &str) -> Result<VolumeId, String> {
    VolumeId::from_str(vid).map_err(|_| format!("bad volume id {vid}"))
}

/// Parse an optional Log id; the empty string means "mint one" (absent on the wire).
fn opt_log(s: Option<&str>) -> Result<Option<LogId>, String> {
    match s {
        None => Ok(None),
        Some(l) => LogId::from_str(l).map(Some).map_err(|_| format!("bad log id {l}")),
    }
}

/// Translate wire page bytes into a fixed-`PAGESIZE` `Page` (the realization above). Short →
/// zero-padded; exact → as-is; over-`PAGESIZE` → an error string.
fn to_page(bytes: &[u8]) -> Result<Page, String> {
    let size = PAGESIZE.as_usize();
    if bytes.len() > size {
        return Err(format!("page over {size} bytes ({})", bytes.len()));
    }
    let mut buf = Vec::with_capacity(size);
    buf.extend_from_slice(bytes);
    buf.resize(size, 0);
    Page::from_buf(Bytes::from(buf)).map_err(|e| e.to_string())
}

/// Map an engine [`GraftErr`] to the closed proto error taxonomy and build the `Err`
/// response. The detail carries the engine's own message for diagnostics; the kind is
/// [`err_kind_of`].
fn map_err(corr: u64, e: GraftErr) -> Msg {
    err(corr, err_kind_of(&e), e.to_string())
}

/// The closed [`ErrKind`] an engine [`GraftErr`] maps to. The mapping is total:
///   * a lost OCC / fence (`VolumeConcurrentWrite`) → `conflict`
///   * a missing Volume (`VolumeNotFound`) → `not_found`
///   * everything else (storage / remote / recovery / divergence) → `unavailable`
///
/// Exposed so the wire kind is a runnable assertion (the engine conflict is proven by a
/// concurrent-commit race; this pins what crosses the wire).
#[must_use]
pub fn err_kind_of(e: &GraftErr) -> ErrKind {
    match e {
        GraftErr::Logical(LogicalErr::VolumeConcurrentWrite(_)) => ErrKind::Conflict,
        GraftErr::Logical(LogicalErr::VolumeNotFound(_)) => ErrKind::NotFound,
        _ => ErrKind::Unavailable,
    }
}

/// Build an `Err` response.
fn err(corr: u64, kind: ErrKind, detail: String) -> Msg {
    Msg::Err { corr, kind, detail }
}

/// The `corr` carried by a message, or 0 for a tagless one (the handshake / feed carry none).
/// Used wherever a refusal must echo the request's correlation id without a full decode — the
/// dispatch's misuse refusal here, the session's not-established refusal, and the live path's
/// cap refusal. Crate-shared so the closed `Msg` mapping lives in exactly one place.
pub(crate) fn corr_of(msg: &Msg) -> u64 {
    match msg {
        Msg::OpenVolume { corr, .. }
        | Msg::ResolveBranded { corr, .. }
        | Msg::Commit { corr, .. }
        | Msg::Push { corr, .. }
        | Msg::Pull { corr, .. }
        | Msg::Read { corr, .. }
        | Msg::Snapshot { corr, .. }
        | Msg::GetCommit { corr, .. }
        | Msg::Ack { corr, .. }
        | Msg::Pages { corr, .. }
        | Msg::SnapshotResp { corr, .. }
        | Msg::Err { corr, .. } => *corr,
        Msg::Hello { .. } | Msg::Welcome { .. } | Msg::Incompatible { .. } | Msg::Feed { .. } => 0,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    // The `to_page` realization (the wire carries arbitrary-length page bytes; `Page` is a
    // fixed `PAGESIZE`). These pin all three branches the dispatch relies on — the unit half
    // of REMEDIATE-1 (the round-trip half is the session-level test in `tests/round_trip.rs`).

    #[test]
    fn to_page_exact_size_is_unchanged() {
        let size = PAGESIZE.as_usize();
        let bytes = vec![0xAB_u8; size];
        let page = to_page(&bytes).expect("exact-PAGESIZE page is accepted");
        assert_eq!(page.len(), size);
        // every byte preserved verbatim
        assert_eq!(page.into_bytes().as_ref(), bytes.as_slice());
    }

    #[test]
    fn to_page_short_is_zero_padded_to_pagesize() {
        let size = PAGESIZE.as_usize();
        let page = to_page(&[0x01, 0x02, 0x03]).expect("a short page is padded, not rejected");
        assert_eq!(page.len(), size, "padded up to PAGESIZE");
        let out = page.into_bytes();
        // the prefix is the supplied bytes; the remainder is zero-filled
        assert_eq!(&out[..3], &[0x01, 0x02, 0x03]);
        assert!(out[3..].iter().all(|&b| b == 0), "the tail is zero-filled");
    }

    #[test]
    fn to_page_empty_is_the_empty_page() {
        let size = PAGESIZE.as_usize();
        let page = to_page(&[]).expect("an empty page is the all-zero page");
        assert_eq!(page.len(), size);
        assert!(page.is_empty(), "an empty wire page is the engine's EMPTY page");
    }

    #[test]
    fn to_page_over_pagesize_is_err_no_panic() {
        let size = PAGESIZE.as_usize();
        let oversized = vec![0xFF_u8; size + 1];
        // the anti-panic branch: one byte over PAGESIZE is rejected as an Err, never a panic
        let err = to_page(&oversized).expect_err("an over-PAGESIZE page is rejected");
        assert!(err.contains("over"), "the detail names the over-size cause: {err}");
    }
}
