//! eg.4 — the Rust side of the cross-runtime conformance suite (criteria 5 + 6).
//!
//! Every `echo_graft_proto` message has ONE byte-frozen encoding, pinned in
//! `tests/fixtures/wire.fixtures` (`<name>\t<hex>` per line). This test:
//!   * #5 — asserts each canonical message encodes to its frozen bytes (and round-trips), so the
//!     wire cannot drift silently; the only sanctioned change is a `PROTO_MAX` bump + new fixtures.
//!   * #6 — the SAME fixture file is mirrored byte-identical into `apps/echo_store`, where the
//!     Elixir conformance test asserts `EchoMQ.RESP.encode/1` produces the identical bytes. Neither
//!     side owns its own truth: the fixture is authoritative for both.
//!
//! Regenerate (after a sanctioned wire change / version bump):
//!   REGEN_FIXTURES=1 cargo test -p echo_graft_proto --test conformance
//! then mirror the file into `apps/echo_store/test/fixtures/graft_backend/wire.fixtures`
//! (the Elixir test fails loudly if the two diverge).

use std::collections::BTreeMap;

use echo_graft_proto::{ErrKind, Msg, PROTO_MAX, PROTO_MIN};

const FIXTURES: &str = concat!(env!("CARGO_MANIFEST_DIR"), "/tests/fixtures/wire.fixtures");

// ---- the canonical test vectors (mirrored exactly in the Elixir conformance test) ----

const VID: &str = "3QJmnh7Yx2Kp9Wd5Lr8Tz4B"; // a fixed 24-char base58 test Volume id
const BRANDED: &str = "VOL0O5fmcxbds8"; // the eg.3 branded-id vector
const LOG: &str = "74ggc11XPe-3tpZminfUtzHG"; // the eg.3 Log-id vector
const PAGE: &[u8] = &[0xDE, 0xAD, 0xBE, 0xEF];

/// The eg.3 `FeedEvent` bilrost fixture (51 bytes), carried OPAQUE by the eg.4 wire.
/// Byte-identical to `echo_graft::feed::tests::feed_event_encoding_is_byte_frozen`.
const FEED_BLOB: &[u8] = &[
    0x05, 0x0e, 0x56, 0x4f, 0x4c, 0x30, 0x4f, 0x35, 0x66, 0x6d, 0x63, 0x78, 0x62, 0x64, 0x73, 0x38,
    0x05, 0x18, 0x37, 0x34, 0x67, 0x67, 0x63, 0x31, 0x31, 0x58, 0x50, 0x65, 0x2d, 0x33, 0x74, 0x70,
    0x5a, 0x6d, 0x69, 0x6e, 0x66, 0x55, 0x74, 0x7a, 0x48, 0x47, 0x04, 0x07, 0x04, 0x80, 0xcf, 0x94,
    0xfe, 0xbb, 0x30,
];

fn canonical() -> Vec<(&'static str, Msg)> {
    vec![
        ("hello", Msg::Hello { proto_min: PROTO_MIN, proto_max: PROTO_MAX, client: "echo_store".into() }),
        ("welcome", Msg::Welcome { proto: 1 }),
        ("incompatible", Msg::Incompatible { proto_min: 2, proto_max: 3, reason: "no overlapping protocol version".into() }),
        ("open_volume", Msg::OpenVolume { corr: 7, branded: BRANDED.into(), local: None, remote: Some(LOG.into()) }),
        ("resolve_branded", Msg::ResolveBranded { corr: 8, branded: BRANDED.into() }),
        ("commit", Msg::Commit { corr: 9, vid: VID.into(), base: 3, pages: vec![(1, PAGE.to_vec())] }),
        ("push", Msg::Push { corr: 10, vid: VID.into() }),
        ("pull", Msg::Pull { corr: 11, vid: VID.into() }),
        ("read", Msg::Read { corr: 12, vid: VID.into(), pageidx: 1 }),
        ("snapshot", Msg::Snapshot { corr: 13, vid: VID.into() }),
        ("get_commit", Msg::GetCommit { corr: 14, log: LOG.into(), lsn: 42 }),
        ("ack", Msg::Ack { corr: 9, lsn: 4 }),
        ("pages", Msg::Pages { corr: 12, data: PAGE.to_vec() }),
        ("snapshot_resp", Msg::SnapshotResp { corr: 13, lsn: 4, pages: 2 }),
        ("err", Msg::Err { corr: 9, kind: ErrKind::Conflict, detail: "concurrent write to Volume".into() }),
        ("feed_event", Msg::Feed { blob: FEED_BLOB.to_vec() }),
    ]
}

fn to_hex(bytes: &[u8]) -> String {
    use std::fmt::Write;
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        write!(s, "{b:02x}").expect("write hex");
    }
    s
}

fn from_hex(s: &str) -> Vec<u8> {
    (0..s.len()).step_by(2).map(|i| u8::from_str_radix(&s[i..i + 2], 16).expect("hex digit")).collect()
}

fn parse_fixtures(text: &str) -> BTreeMap<String, String> {
    text.lines()
        .map(str::trim)
        .filter(|l| !l.is_empty() && !l.starts_with('#'))
        .map(|l| {
            let (name, hex) = l.split_once('\t').expect("fixture line is <name>\\t<hex>");
            (name.to_string(), hex.to_string())
        })
        .collect()
}

fn regenerate() {
    let mut out = String::new();
    out.push_str("# echo_graft_proto wire fixtures (eg.4) — GENERATED, byte-frozen. Do not hand-edit.\n");
    out.push_str("# format: <name>\\t<hex>   ·   proto version: see PROTO_MIN..=PROTO_MAX in the crate.\n");
    out.push_str("# regenerate: REGEN_FIXTURES=1 cargo test -p echo_graft_proto --test conformance\n");
    out.push_str("# the apps/echo_store mirror MUST stay byte-identical (the Elixir conformance test asserts it).\n");
    for (name, msg) in canonical() {
        out.push_str(name);
        out.push('\t');
        out.push_str(&to_hex(&msg.encode()));
        out.push('\n');
    }
    let dir = std::path::Path::new(FIXTURES).parent().expect("fixtures dir");
    std::fs::create_dir_all(dir).expect("create fixtures dir");
    std::fs::write(FIXTURES, out).expect("write fixtures");
}

#[test]
fn wire_is_byte_frozen_and_complete() {
    if std::env::var_os("REGEN_FIXTURES").is_some() {
        regenerate();
    }

    let text = std::fs::read_to_string(FIXTURES)
        .expect("tests/fixtures/wire.fixtures present (run REGEN_FIXTURES=1 once to generate)");
    let fixtures = parse_fixtures(&text);

    // every canonical message matches its frozen bytes AND round-trips from them
    for (name, msg) in canonical() {
        let want = fixtures
            .get(name)
            .unwrap_or_else(|| panic!("fixture missing for {name} — regenerate after adding a message"));
        assert_eq!(&to_hex(&msg.encode()), want, "ENCODE DRIFT for {name}: bump PROTO_MAX, do not silently re-encode");
        let bytes = from_hex(want);
        assert_eq!(Msg::decode(&bytes).expect("decode frozen bytes"), msg, "decode round-trip failed for {name}");
    }

    // no extra fixtures, no missing ones — the file IS the closed message set
    let names: std::collections::BTreeSet<&str> = canonical().iter().map(|(n, _)| *n).collect();
    let fixed: std::collections::BTreeSet<&str> = fixtures.keys().map(String::as_str).collect();
    assert_eq!(
        fixed,
        names.iter().copied().collect(),
        "fixture set and canonical message set diverge"
    );
}
