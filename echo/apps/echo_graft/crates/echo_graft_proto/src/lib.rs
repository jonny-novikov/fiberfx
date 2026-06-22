//! `echo_graft_proto` — the byte-frozen, version-negotiated wire for `echo_graft_backend` (eg.4).
//!
//! The Rust page-engine (`echo_graft`) runs as a supervised `EchoMQ` participant
//! (`echo_graft_backend`) driven from the BEAM by `EchoStore.GraftBackend`. This crate is the
//! CONTRACT between the two runtimes: every message has ONE frozen encoding, asserted
//! byte-for-byte by a conformance suite BOTH sides run against a single shared fixture set
//! (`tests/fixtures/wire.fixtures`, mirrored byte-identical into `apps/echo_store`).
//!
//! # Encoding
//!
//! A `RESP3` array of bulk strings, byte-identical to the Elixir `EchoMQ.RESP.encode/1` codec
//! (`apps/echo_wire/lib/echo_mq/resp.ex`). A message is `[tag, field, field, …]` where every
//! field is a bulk string and integers are their decimal ASCII. This is the flat `RESP3` subset
//! both sides share — nothing here emits a nested aggregate, because `EchoMQ.RESP.encode/1` is
//! itself flat, so the two implementations cannot disagree on structure; only the bytes remain to
//! be proven equal, which the shared fixture does.
//!
//! The eg.3 `FeedEvent` rides as an OPAQUE bilrost blob (already byte-frozen in `echo_graft::feed`):
//! the eg.4 wire wraps it as one bulk string and never re-encodes its fields, so the two
//! freeze-points compose without duplication.
//!
//! # Versioning
//!
//! `PROTO_MIN..=PROTO_MAX`, negotiated by the `Hello`/`Welcome`/`Incompatible` handshake. A wire
//! change bumps `PROTO_MAX` and ships new fixtures beside the old (which stay frozen).

#![forbid(unsafe_code)]

use std::fmt;

/// The lowest protocol version this build speaks. Bumped 1 → 2 by eg.5 (D-5: v1 is dropped — it
/// had zero deployed consumers, so the build speaks ONLY v2; a v1 peer fails the handshake by
/// design).
pub const PROTO_MIN: u32 = 2;
/// The highest protocol version this build speaks. v2 carries the per-call durability mode on the
/// `COMMIT` message (modified in place — there is no v1 decoder to preserve). A wire change is a
/// `PROTO_MAX` bump with regenerated fixtures, never a silent re-encode against a live peer.
pub const PROTO_MAX: u32 = 2;

// ===========================================================================
// RESP3 array-of-bulk-strings codec — the `EchoMQ.RESP` intersection
// ===========================================================================

/// A framing error decoding a `RESP3` array of bulk strings.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum RespErr {
    /// The buffer ended before the frame was complete.
    Truncated,
    /// A `CRLF` terminator was missing where the frame required one.
    BadFraming,
    /// A length or count header was not valid ASCII decimal.
    BadHeader,
    /// A frame prefix byte (`*` or `$`) was not the expected one.
    BadPrefix,
    /// Bytes remained after the array was fully decoded.
    Trailing,
}

impl fmt::Display for RespErr {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let s = match self {
            RespErr::Truncated => "RESP3 frame truncated",
            RespErr::BadFraming => "RESP3 frame missing CRLF terminator",
            RespErr::BadHeader => "RESP3 length/count header not ASCII decimal",
            RespErr::BadPrefix => "RESP3 frame prefix byte unexpected",
            RespErr::Trailing => "RESP3 trailing bytes after array",
        };
        f.write_str(s)
    }
}

impl std::error::Error for RespErr {}

/// Encode `parts` as a `RESP3` array of bulk strings — byte-identical to Elixir
/// `EchoMQ.RESP.encode/1`: `*N\r\n` then `$len\r\n<bytes>\r\n` per part.
#[must_use]
pub fn encode_parts(parts: &[Vec<u8>]) -> Vec<u8> {
    let mut out = Vec::new();
    out.push(b'*');
    out.extend_from_slice(parts.len().to_string().as_bytes());
    out.extend_from_slice(b"\r\n");
    for p in parts {
        out.push(b'$');
        out.extend_from_slice(p.len().to_string().as_bytes());
        out.extend_from_slice(b"\r\n");
        out.extend_from_slice(p);
        out.extend_from_slice(b"\r\n");
    }
    out
}

/// Decode a `RESP3` array of bulk strings into its parts. Accepts only the flat
/// array-of-bulk-strings subset the eg.4 wire uses (the `EchoMQ.RESP` intersection);
/// anything else is a [`RespErr`].
pub fn decode_parts(bytes: &[u8]) -> Result<Vec<Vec<u8>>, RespErr> {
    let mut pos = 0usize;
    let n = read_header(bytes, &mut pos, b'*')?;
    let mut parts = Vec::with_capacity(n);
    for _ in 0..n {
        let len = read_header(bytes, &mut pos, b'$')?;
        let end = pos.checked_add(len).ok_or(RespErr::BadHeader)?;
        if end + 2 > bytes.len() {
            return Err(RespErr::Truncated);
        }
        parts.push(bytes[pos..end].to_vec());
        pos = end;
        if &bytes[pos..pos + 2] != b"\r\n" {
            return Err(RespErr::BadFraming);
        }
        pos += 2;
    }
    if pos != bytes.len() {
        return Err(RespErr::Trailing);
    }
    Ok(parts)
}

/// Read a `<prefix><decimal>\r\n` header, advancing `pos` past the `CRLF`.
fn read_header(bytes: &[u8], pos: &mut usize, prefix: u8) -> Result<usize, RespErr> {
    match bytes.get(*pos) {
        None => return Err(RespErr::Truncated),
        Some(&b) if b != prefix => return Err(RespErr::BadPrefix),
        Some(_) => {}
    }
    *pos += 1;
    let start = *pos;
    while bytes.get(*pos).is_some_and(|&b| b != b'\r') {
        *pos += 1;
    }
    if bytes.get(*pos) != Some(&b'\r') || bytes.get(*pos + 1) != Some(&b'\n') {
        return Err(RespErr::Truncated);
    }
    let s = std::str::from_utf8(&bytes[start..*pos]).map_err(|_| RespErr::BadHeader)?;
    let n = s.parse::<usize>().map_err(|_| RespErr::BadHeader)?;
    *pos += 2;
    Ok(n)
}

// ===========================================================================
// The closed error taxonomy
// ===========================================================================

/// The closed error taxonomy carried by [`Msg::Err`]. A new kind is a protocol-version bump,
/// never a silent addition (criterion 5).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ErrKind {
    /// A concurrent write lost the local OCC or the remote conditional-write fence.
    Conflict,
    /// The addressed Volume / commit does not exist.
    NotFound,
    /// The handshake found no overlapping protocol version.
    VersionMismatch,
    /// The engine could not service the request (transport / storage / overload).
    Unavailable,
}

impl ErrKind {
    /// The wire token for this kind.
    #[must_use]
    pub fn as_str(self) -> &'static str {
        match self {
            ErrKind::Conflict => "conflict",
            ErrKind::NotFound => "not_found",
            ErrKind::VersionMismatch => "version_mismatch",
            ErrKind::Unavailable => "unavailable",
        }
    }

    /// Parse a wire token back into a kind, or `None` if unknown (a closed set).
    #[must_use]
    pub fn from_token(token: &[u8]) -> Option<Self> {
        match token {
            b"conflict" => Some(ErrKind::Conflict),
            b"not_found" => Some(ErrKind::NotFound),
            b"version_mismatch" => Some(ErrKind::VersionMismatch),
            b"unavailable" => Some(ErrKind::Unavailable),
            _ => None,
        }
    }
}

// ===========================================================================
// The per-call durability mode (eg.5, protocol v2)
// ===========================================================================

/// The per-call durability mode carried by the v2 [`Msg::Commit`] message. It is a *signal*
/// choosing WHEN a commit acks relative to the existing local-commit-vs-remote-push split — not a
/// new mechanism. The mode is ALWAYS on the wire (every v2 `COMMIT` carries it); the [`Mode::Sync`]
/// default (the safe durable+replicated-before-ack choice) is a client-API default, not a wire
/// default (D-5: v1 is dropped, so there is no mode-less `COMMIT` to default).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Mode {
    /// Ack on the local fsync of the open batch; the remote push rolls the batch up
    /// asynchronously. The loss window is the open (not-yet-pushed) batch.
    Async,
    /// Ack only after the remote conditional-write commit acks — durable and replicated before
    /// the ack returns. The v1 `COMMIT` default.
    Sync,
}

impl Mode {
    /// The wire token for this mode.
    #[must_use]
    pub fn as_str(self) -> &'static str {
        match self {
            Mode::Async => "async",
            Mode::Sync => "sync",
        }
    }

    /// Parse a wire token into a mode, or `None` if unknown (a closed set).
    #[must_use]
    pub fn from_token(token: &[u8]) -> Option<Self> {
        match token {
            b"async" => Some(Mode::Async),
            b"sync" => Some(Mode::Sync),
            _ => None,
        }
    }
}

// ===========================================================================
// The message set (the declared-keys table)
// ===========================================================================

/// An error decoding a [`Msg`] from wire bytes.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ProtoErr {
    /// The underlying `RESP3` framing was invalid.
    Resp(RespErr),
    /// The array was empty — no message tag.
    Empty,
    /// The message tag was not a known message.
    UnknownTag(Vec<u8>),
    /// A field was missing, surplus, or malformed.
    BadField(&'static str),
}

impl fmt::Display for ProtoErr {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ProtoErr::Resp(e) => write!(f, "RESP framing: {e}"),
            ProtoErr::Empty => f.write_str("empty message (no tag)"),
            ProtoErr::UnknownTag(t) => write!(f, "unknown message tag: {}", String::from_utf8_lossy(t)),
            ProtoErr::BadField(name) => write!(f, "bad or missing field: {name}"),
        }
    }
}

impl std::error::Error for ProtoErr {}

impl From<RespErr> for ProtoErr {
    fn from(e: RespErr) -> Self {
        ProtoErr::Resp(e)
    }
}

/// A protocol message. Each variant has ONE byte-frozen encoding; the full set is the eg.4
/// declared-keys table. Requests/responses carry a `corr` correlation id; the handshake and the
/// feed do not.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Msg {
    // ---- handshake ----
    /// Client → backend: the client's supported protocol-version range + a client tag.
    Hello {
        /// The client's lowest supported version.
        proto_min: u32,
        /// The client's highest supported version.
        proto_max: u32,
        /// A free-form client identifier (for logs).
        client: String,
    },
    /// Backend → client: the selected protocol version.
    Welcome {
        /// The version both sides will speak this session.
        proto: u32,
    },
    /// Backend → client: no overlapping version; the session is refused, no Volume touched.
    Incompatible {
        /// The backend's lowest supported version.
        proto_min: u32,
        /// The backend's highest supported version.
        proto_max: u32,
        /// A human-readable reason.
        reason: String,
    },

    // ---- requests ----
    /// Open (or resolve-and-open) a Volume by its external branded id.
    OpenVolume {
        /// Correlation id.
        corr: u64,
        /// The 14-char branded id.
        branded: String,
        /// Optional local Log id (absent = mint).
        local: Option<String>,
        /// Optional remote Log id (absent = mint).
        remote: Option<String>,
    },
    /// Resolve a branded id to its native Volume id, if known.
    ResolveBranded {
        /// Correlation id.
        corr: u64,
        /// The 14-char branded id.
        branded: String,
    },
    /// Stage pages from `base` and commit them with an explicit per-call durability [`Mode`]
    /// (protocol v2, eg.5). The `mode` is a fixed-position field between `base` and the page
    /// count; it is ALWAYS on the wire (the `:sync` default is a client-API default, not a wire
    /// default). v1 is dropped (D-5), so this evolved the message in place — there is no v1
    /// `COMMIT` shape to preserve.
    Commit {
        /// Correlation id.
        corr: u64,
        /// The native Volume id.
        vid: String,
        /// The base LSN the write extends.
        base: u64,
        /// The per-call durability mode (`async` | `sync`).
        mode: Mode,
        /// The staged pages as `(page_index, page_bytes)`.
        pages: Vec<(u32, Vec<u8>)>,
    },
    /// Push local commits to the remote (the conditional-write fence + the feed publish).
    Push {
        /// Correlation id.
        corr: u64,
        /// The native Volume id.
        vid: String,
    },
    /// Pull remote commits into the Volume.
    Pull {
        /// Correlation id.
        corr: u64,
        /// The native Volume id.
        vid: String,
    },
    /// Read one page at the Volume head (lazy-faulted backend-side).
    Read {
        /// Correlation id.
        corr: u64,
        /// The native Volume id.
        vid: String,
        /// The page index to read.
        pageidx: u32,
    },
    /// Fetch the Volume's current snapshot coordinates.
    Snapshot {
        /// Correlation id.
        corr: u64,
        /// The native Volume id.
        vid: String,
    },
    /// Fetch a specific commit from a Log by LSN.
    GetCommit {
        /// Correlation id.
        corr: u64,
        /// The Log id.
        log: String,
        /// The commit LSN.
        lsn: u64,
    },

    // ---- responses ----
    /// A success ack carrying the resulting LSN (e.g. of a commit).
    Ack {
        /// Correlation id (echoes the request).
        corr: u64,
        /// The resulting LSN.
        lsn: u64,
    },
    /// One page of data (only when a `Read` requested raw bytes).
    Pages {
        /// Correlation id (echoes the request).
        corr: u64,
        /// The raw page bytes.
        data: Vec<u8>,
    },
    /// A snapshot's head coordinates.
    SnapshotResp {
        /// Correlation id (echoes the request).
        corr: u64,
        /// The head LSN.
        lsn: u64,
        /// The page count at the head.
        pages: u32,
    },
    /// A typed error from the closed taxonomy.
    Err {
        /// Correlation id (echoes the request).
        corr: u64,
        /// The error kind.
        kind: ErrKind,
        /// A human-readable detail.
        detail: String,
    },

    // ---- feed (publish-only) ----
    /// A change-feed event — the eg.3 bilrost `FeedEvent`, carried OPAQUE.
    Feed {
        /// The eg.3 bilrost-encoded `FeedEvent` blob (never re-encoded here).
        blob: Vec<u8>,
    },
}

impl Msg {
    /// The flat list of bulk-string parts for this message (tag first).
    #[must_use]
    pub fn to_parts(&self) -> Vec<Vec<u8>> {
        match self {
            Msg::Hello { proto_min, proto_max, client } => {
                vec![tag("HELLO"), u32p(*proto_min), u32p(*proto_max), strp(client)]
            }
            Msg::Welcome { proto } => vec![tag("WELCOME"), u32p(*proto)],
            Msg::Incompatible { proto_min, proto_max, reason } => {
                vec![tag("INCOMPAT"), u32p(*proto_min), u32p(*proto_max), strp(reason)]
            }
            Msg::OpenVolume { corr, branded, local, remote } => {
                vec![tag("OPEN"), u64p(*corr), strp(branded), optp(local), optp(remote)]
            }
            Msg::ResolveBranded { corr, branded } => {
                vec![tag("RESOLVE"), u64p(*corr), strp(branded)]
            }
            Msg::Commit { corr, vid, base, mode, pages } => {
                // v2 shape: [COMMIT, corr, vid, base, mode, npages, (idx, page)*]. The mode token
                // sits between base and the page count; it is always present on the wire.
                let mut v = vec![
                    tag("COMMIT"),
                    u64p(*corr),
                    strp(vid),
                    u64p(*base),
                    tag(mode.as_str()),
                    u32p(pages.len() as u32),
                ];
                for (idx, page) in pages {
                    v.push(u32p(*idx));
                    v.push(page.clone());
                }
                v
            }
            Msg::Push { corr, vid } => vec![tag("PUSH"), u64p(*corr), strp(vid)],
            Msg::Pull { corr, vid } => vec![tag("PULL"), u64p(*corr), strp(vid)],
            Msg::Read { corr, vid, pageidx } => {
                vec![tag("READ"), u64p(*corr), strp(vid), u32p(*pageidx)]
            }
            Msg::Snapshot { corr, vid } => vec![tag("SNAP"), u64p(*corr), strp(vid)],
            Msg::GetCommit { corr, log, lsn } => {
                vec![tag("GETCOMMIT"), u64p(*corr), strp(log), u64p(*lsn)]
            }
            Msg::Ack { corr, lsn } => vec![tag("ACK"), u64p(*corr), u64p(*lsn)],
            Msg::Pages { corr, data } => vec![tag("PAGES"), u64p(*corr), data.clone()],
            Msg::SnapshotResp { corr, lsn, pages } => {
                vec![tag("SNAPRESP"), u64p(*corr), u64p(*lsn), u32p(*pages)]
            }
            Msg::Err { corr, kind, detail } => {
                vec![tag("ERR"), u64p(*corr), tag(kind.as_str()), strp(detail)]
            }
            Msg::Feed { blob } => vec![tag("FEED"), blob.clone()],
        }
    }

    /// Reconstruct a message from its decoded parts (tag first).
    pub fn from_parts(parts: &[Vec<u8>]) -> Result<Msg, ProtoErr> {
        let head = parts.first().ok_or(ProtoErr::Empty)?;
        let rest = &parts[1..];
        match head.as_slice() {
            b"HELLO" => {
                arity(rest, 3)?;
                Ok(Msg::Hello {
                    proto_min: f_u32(&rest[0], "proto_min")?,
                    proto_max: f_u32(&rest[1], "proto_max")?,
                    client: f_str(&rest[2], "client")?,
                })
            }
            b"WELCOME" => {
                arity(rest, 1)?;
                Ok(Msg::Welcome { proto: f_u32(&rest[0], "proto")? })
            }
            b"INCOMPAT" => {
                arity(rest, 3)?;
                Ok(Msg::Incompatible {
                    proto_min: f_u32(&rest[0], "proto_min")?,
                    proto_max: f_u32(&rest[1], "proto_max")?,
                    reason: f_str(&rest[2], "reason")?,
                })
            }
            b"OPEN" => {
                arity(rest, 4)?;
                Ok(Msg::OpenVolume {
                    corr: f_u64(&rest[0], "corr")?,
                    branded: f_str(&rest[1], "branded")?,
                    local: f_opt(&rest[2], "local")?,
                    remote: f_opt(&rest[3], "remote")?,
                })
            }
            b"RESOLVE" => {
                arity(rest, 2)?;
                Ok(Msg::ResolveBranded {
                    corr: f_u64(&rest[0], "corr")?,
                    branded: f_str(&rest[1], "branded")?,
                })
            }
            b"COMMIT" => {
                // v2: [corr, vid, base, mode, npages, (idx, page)*]. The mode token sits between
                // base and npages; the pages tail begins at index 5. (v1 is dropped — D-5.)
                if rest.len() < 5 {
                    return Err(ProtoErr::BadField("commit_arity"));
                }
                let corr = f_u64(&rest[0], "corr")?;
                let vid = f_str(&rest[1], "vid")?;
                let base = f_u64(&rest[2], "base")?;
                let mode = Mode::from_token(&rest[3]).ok_or(ProtoErr::BadField("commit_mode"))?;
                let npages = f_u32(&rest[4], "npages")? as usize;
                let tail = &rest[5..];
                if tail.len() != npages * 2 {
                    return Err(ProtoErr::BadField("pages_count"));
                }
                let mut pages = Vec::with_capacity(npages);
                for pair in tail.chunks_exact(2) {
                    pages.push((f_u32(&pair[0], "page_idx")?, pair[1].clone()));
                }
                Ok(Msg::Commit { corr, vid, base, mode, pages })
            }
            b"PUSH" => {
                arity(rest, 2)?;
                Ok(Msg::Push { corr: f_u64(&rest[0], "corr")?, vid: f_str(&rest[1], "vid")? })
            }
            b"PULL" => {
                arity(rest, 2)?;
                Ok(Msg::Pull { corr: f_u64(&rest[0], "corr")?, vid: f_str(&rest[1], "vid")? })
            }
            b"READ" => {
                arity(rest, 3)?;
                Ok(Msg::Read {
                    corr: f_u64(&rest[0], "corr")?,
                    vid: f_str(&rest[1], "vid")?,
                    pageidx: f_u32(&rest[2], "pageidx")?,
                })
            }
            b"SNAP" => {
                arity(rest, 2)?;
                Ok(Msg::Snapshot { corr: f_u64(&rest[0], "corr")?, vid: f_str(&rest[1], "vid")? })
            }
            b"GETCOMMIT" => {
                arity(rest, 3)?;
                Ok(Msg::GetCommit {
                    corr: f_u64(&rest[0], "corr")?,
                    log: f_str(&rest[1], "log")?,
                    lsn: f_u64(&rest[2], "lsn")?,
                })
            }
            b"ACK" => {
                arity(rest, 2)?;
                Ok(Msg::Ack { corr: f_u64(&rest[0], "corr")?, lsn: f_u64(&rest[1], "lsn")? })
            }
            b"PAGES" => {
                arity(rest, 2)?;
                Ok(Msg::Pages { corr: f_u64(&rest[0], "corr")?, data: rest[1].clone() })
            }
            b"SNAPRESP" => {
                arity(rest, 3)?;
                Ok(Msg::SnapshotResp {
                    corr: f_u64(&rest[0], "corr")?,
                    lsn: f_u64(&rest[1], "lsn")?,
                    pages: f_u32(&rest[2], "pages")?,
                })
            }
            b"ERR" => {
                arity(rest, 3)?;
                let kind = ErrKind::from_token(&rest[1]).ok_or(ProtoErr::BadField("err_kind"))?;
                Ok(Msg::Err { corr: f_u64(&rest[0], "corr")?, kind, detail: f_str(&rest[2], "detail")? })
            }
            b"FEED" => {
                arity(rest, 1)?;
                Ok(Msg::Feed { blob: rest[0].clone() })
            }
            other => Err(ProtoErr::UnknownTag(other.to_vec())),
        }
    }

    /// Encode this message to its frozen wire bytes.
    #[must_use]
    pub fn encode(&self) -> Vec<u8> {
        encode_parts(&self.to_parts())
    }

    /// Decode a message from wire bytes.
    pub fn decode(bytes: &[u8]) -> Result<Msg, ProtoErr> {
        Msg::from_parts(&decode_parts(bytes)?)
    }
}

// ---- part builders / field parsers ----

fn tag(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}
fn strp(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}
fn u32p(n: u32) -> Vec<u8> {
    n.to_string().into_bytes()
}
fn u64p(n: u64) -> Vec<u8> {
    n.to_string().into_bytes()
}
fn optp(o: &Option<String>) -> Vec<u8> {
    match o {
        Some(s) => s.as_bytes().to_vec(),
        None => Vec::new(),
    }
}

fn arity(rest: &[Vec<u8>], n: usize) -> Result<(), ProtoErr> {
    if rest.len() == n { Ok(()) } else { Err(ProtoErr::BadField("arity")) }
}
fn f_str(part: &[u8], field: &'static str) -> Result<String, ProtoErr> {
    String::from_utf8(part.to_vec()).map_err(|_| ProtoErr::BadField(field))
}
fn f_opt(part: &[u8], field: &'static str) -> Result<Option<String>, ProtoErr> {
    if part.is_empty() { Ok(None) } else { Ok(Some(f_str(part, field)?)) }
}
fn f_u64(part: &[u8], field: &'static str) -> Result<u64, ProtoErr> {
    std::str::from_utf8(part)
        .ok()
        .and_then(|s| s.parse::<u64>().ok())
        .ok_or(ProtoErr::BadField(field))
}
fn f_u32(part: &[u8], field: &'static str) -> Result<u32, ProtoErr> {
    std::str::from_utf8(part)
        .ok()
        .and_then(|s| s.parse::<u32>().ok())
        .ok_or(ProtoErr::BadField(field))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resp_matches_echo_mq_shape() {
        // EchoMQ.RESP.encode(["PING"]) == "*1\r\n$4\r\nPING\r\n"
        assert_eq!(encode_parts(&[b"PING".to_vec()]), b"*1\r\n$4\r\nPING\r\n");
        // integers bulk-encode as their decimal ASCII (resp.ex:26-27)
        assert_eq!(
            encode_parts(&[b"ACK".to_vec(), u64p(7), u64p(42)]),
            b"*3\r\n$3\r\nACK\r\n$1\r\n7\r\n$2\r\n42\r\n"
        );
    }

    #[test]
    fn round_trips_each_shape() {
        let samples = [
            Msg::Hello { proto_min: 2, proto_max: 2, client: "c".into() },
            Msg::Welcome { proto: 2 },
            Msg::Incompatible { proto_min: 2, proto_max: 3, reason: "x".into() },
            Msg::OpenVolume { corr: 1, branded: "VOL0O5fmcxbds8".into(), local: None, remote: Some("L".into()) },
            // both durability modes must round-trip on the v2 COMMIT
            Msg::Commit { corr: 2, vid: "v".into(), base: 0, mode: Mode::Sync, pages: vec![(1, vec![0xDE, 0xAD]), (9, vec![0x00])] },
            Msg::Commit { corr: 4, vid: "v".into(), base: 1, mode: Mode::Async, pages: vec![(2, vec![0x01])] },
            Msg::Read { corr: 3, vid: "v".into(), pageidx: 7 },
            Msg::Ack { corr: 2, lsn: 5 },
            Msg::Err { corr: 2, kind: ErrKind::Conflict, detail: "boom".into() },
            Msg::Feed { blob: vec![0x00, 0x0d, 0x0a, 0xff] }, // blob with embedded CRLF + non-utf8
        ];
        for m in samples {
            let bytes = m.encode();
            assert_eq!(Msg::decode(&bytes).expect("decode"), m, "round-trip drift");
        }
    }

    #[test]
    fn mode_tokens_are_closed() {
        for mode in [Mode::Async, Mode::Sync] {
            assert_eq!(Mode::from_token(mode.as_str().as_bytes()), Some(mode));
        }
        assert_eq!(Mode::from_token(b"eventually"), None, "the mode token set is closed");
    }

    #[test]
    fn commit_requires_a_known_mode_token() {
        // a COMMIT with an out-of-set mode token is a BadField, not a silent default
        let bad = b"*6\r\n$6\r\nCOMMIT\r\n$1\r\n9\r\n$1\r\nv\r\n$1\r\n0\r\n$5\r\nmaybe\r\n$1\r\n0\r\n";
        assert!(matches!(Msg::decode(bad), Err(ProtoErr::BadField("commit_mode"))));
    }

    #[test]
    fn blob_with_embedded_crlf_survives() {
        // a bulk string is length-delimited, so an embedded \r\n in the blob is data, not framing
        let m = Msg::Feed { blob: b"a\r\nb".to_vec() };
        assert_eq!(Msg::decode(&m.encode()).unwrap(), m);
    }

    #[test]
    fn unknown_tag_and_bad_field_error() {
        assert!(matches!(Msg::decode(b"*1\r\n$3\r\nZZZ\r\n"), Err(ProtoErr::UnknownTag(_))));
        // ACK with a non-numeric corr
        assert!(matches!(
            Msg::decode(b"*3\r\n$3\r\nACK\r\n$1\r\nx\r\n$1\r\n1\r\n"),
            Err(ProtoErr::BadField(_))
        ));
    }

    #[test]
    fn err_kind_tokens_are_closed() {
        for k in [ErrKind::Conflict, ErrKind::NotFound, ErrKind::VersionMismatch, ErrKind::Unavailable] {
            assert_eq!(ErrKind::from_token(k.as_str().as_bytes()), Some(k));
        }
        assert_eq!(ErrKind::from_token(b"teapot"), None);
    }
}
