//! echo/fx — Rust compute primitives compiled to wasm for the Mercury Node side.
//!
//! What is real and grounded here is the **identity layer**: the BrandedId codec
//! and the Snowflake minter, ported to match the `EchoData.BrandedId` /
//! `EchoData.Snowflake` contract (3-char namespace + width-11 base62 of a 63-bit
//! snowflake; `ts(41) << 22 | node(10) << 12 | seq(12)`, epoch 2024-01-01).
//!
//! `hash32` is the routing hash. The algorithm here (MurmurHash3 x86_32) follows
//! the established branded convention used by the Go `branded` package, but it is
//! marked PARITY: it MUST be cross-checked against `EchoData.BrandedId.hash32/1`
//! before it places a lane in production. Identity parity is a self-check, never
//! an assumption.
//!
//! The fusion + work-stealing scheduler is NOT in this crate. A single wasm
//! instance is one V8 isolate with its own linear memory; cross-core work cannot
//! share a Rust deque. The per-isolate compute lives here; the cross-core
//! scheduler lives in TypeScript over Node Cluster + SharedArrayBuffer (see the
//! roadmap). `fused_sum_of_squares` below is a loop-fusion *demonstration* of the
//! per-isolate primitive, not the scheduler.

use wasm_bindgen::prelude::*;

const BASE62: &[u8; 62] = b"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
const WIDTH: usize = 11;
const EPOCH_MS: u64 = 1_704_067_200_000; // 2024-01-01T00:00:00Z

const TS_BITS: u64 = 41;
const NODE_BITS: u64 = 10;
const SEQ_BITS: u64 = 12;
const NODE_SHIFT: u64 = SEQ_BITS; // 12
const TS_SHIFT: u64 = NODE_BITS + SEQ_BITS; // 22
const MAX_SEQ: u64 = (1 << SEQ_BITS) - 1; // 4095
const MAX_NODE: u64 = (1 << NODE_BITS) - 1; // 1023

// ── base62 (width 11) ────────────────────────────────────────────────────────

fn base62_lookup(b: u8) -> Option<u64> {
    match b {
        b'0'..=b'9' => Some((b - b'0') as u64),
        b'A'..=b'Z' => Some((b - b'A' + 10) as u64),
        b'a'..=b'z' => Some((b - b'a' + 36) as u64),
        _ => None,
    }
}

fn encode_base62(mut n: u64) -> [u8; WIDTH] {
    let mut out = [b'0'; WIDTH];
    let mut i = WIDTH;
    while n > 0 && i > 0 {
        i -= 1;
        out[i] = BASE62[(n % 62) as usize];
        n /= 62;
    }
    out
}

fn decode_base62(s: &[u8]) -> Result<u64, JsError> {
    if s.len() != WIDTH {
        return Err(JsError::new("base62 segment must be 11 chars"));
    }
    let mut n: u64 = 0;
    for &b in s {
        let d = base62_lookup(b).ok_or_else(|| JsError::new("non-base62 char in id"))?;
        n = n
            .checked_mul(62)
            .and_then(|v| v.checked_add(d))
            .ok_or_else(|| JsError::new("base62 overflow"))?;
    }
    Ok(n)
}

// ── namespace ─────────────────────────────────────────────────────────────────

fn check_namespace(ns: &str) -> Result<(), JsError> {
    let b = ns.as_bytes();
    if b.len() != 3 || !b.iter().all(|c| c.is_ascii_uppercase()) {
        return Err(JsError::new("namespace must be 3 uppercase ASCII letters"));
    }
    Ok(())
}

// ── BrandedId codec ───────────────────────────────────────────────────────────

/// Encode a namespace + 63-bit snowflake into a 14-char branded id.
#[wasm_bindgen]
pub fn encode(namespace: &str, snowflake: u64) -> Result<String, JsError> {
    check_namespace(namespace)?;
    if snowflake >> 63 != 0 {
        return Err(JsError::new("snowflake exceeds 63 bits"));
    }
    let mut s = String::with_capacity(14);
    s.push_str(namespace);
    s.push_str(std::str::from_utf8(&encode_base62(snowflake)).unwrap());
    Ok(s)
}

/// A decoded branded id.
#[wasm_bindgen(getter_with_clone)]
pub struct Decoded {
    pub namespace: String,
    pub snowflake: u64,
    pub timestamp_ms: u64,
    pub node: u64,
    pub seq: u64,
}

/// Decode a 14-char branded id back to its parts.
#[wasm_bindgen]
pub fn decode(id: &str) -> Result<Decoded, JsError> {
    let b = id.as_bytes();
    if b.len() != 14 {
        return Err(JsError::new("branded id must be 14 chars"));
    }
    let namespace = std::str::from_utf8(&b[0..3]).unwrap().to_string();
    check_namespace(&namespace)?;
    let snowflake = decode_base62(&b[3..14])?;
    Ok(Decoded {
        namespace,
        snowflake,
        timestamp_ms: (snowflake >> TS_SHIFT) + EPOCH_MS,
        node: (snowflake >> NODE_SHIFT) & MAX_NODE,
        seq: snowflake & MAX_SEQ,
    })
}

/// Shape + charset check. Returns false rather than raising.
#[wasm_bindgen]
pub fn validate(id: &str) -> bool {
    let b = id.as_bytes();
    b.len() == 14
        && b[0..3].iter().all(|c| c.is_ascii_uppercase())
        && b[3..14].iter().all(|&c| base62_lookup(c).is_some())
}

// ── routing hash (PARITY: cross-check vs EchoData.BrandedId.hash32/1) ─────────

/// MurmurHash3 x86_32, seed 0, over the id bytes. PARITY-pending.
#[wasm_bindgen]
pub fn hash32(id: &str) -> u32 {
    murmur3_32(id.as_bytes(), 0)
}

fn murmur3_32(data: &[u8], seed: u32) -> u32 {
    const C1: u32 = 0xcc9e_2d51;
    const C2: u32 = 0x1b87_3593;
    let mut h = seed;
    let nblocks = data.len() / 4;
    for i in 0..nblocks {
        let k = u32::from_le_bytes([
            data[i * 4],
            data[i * 4 + 1],
            data[i * 4 + 2],
            data[i * 4 + 3],
        ]);
        let k = k.wrapping_mul(C1).rotate_left(15).wrapping_mul(C2);
        h ^= k;
        h = h.rotate_left(13).wrapping_mul(5).wrapping_add(0xe654_6b64);
    }
    let tail = &data[nblocks * 4..];
    let mut k1: u32 = 0;
    if tail.len() >= 3 {
        k1 ^= (tail[2] as u32) << 16;
    }
    if tail.len() >= 2 {
        k1 ^= (tail[1] as u32) << 8;
    }
    if !tail.is_empty() {
        k1 ^= tail[0] as u32;
        k1 = k1.wrapping_mul(C1).rotate_left(15).wrapping_mul(C2);
        h ^= k1;
    }
    h ^= data.len() as u32;
    h ^= h >> 16;
    h = h.wrapping_mul(0x85eb_ca6b);
    h ^= h >> 13;
    h = h.wrapping_mul(0xc2b2_ae35);
    h ^= h >> 16;
    h
}

// ── Snowflake minter (per-isolate; one node id per Cluster worker) ───────────

/// A lock-free-by-isolation minter. wasm is single-threaded per instance, so no
/// atomics are needed inside one isolate; each Node Cluster worker constructs a
/// minter with its own `node` id, which is what keeps cross-worker ids disjoint.
#[wasm_bindgen]
pub struct Minter {
    node: u64,
    last_ts: u64,
    seq: u64,
}

#[wasm_bindgen]
impl Minter {
    #[wasm_bindgen(constructor)]
    pub fn new(node: u16) -> Result<Minter, JsError> {
        if node as u64 > MAX_NODE {
            return Err(JsError::new("node id exceeds 10 bits (max 1023)"));
        }
        Ok(Minter {
            node: node as u64,
            last_ts: 0,
            seq: 0,
        })
    }

    /// Mint a 63-bit snowflake from a millisecond clock (pass `Date.now()`).
    pub fn mint_snowflake(&mut self, now_ms: f64) -> Result<u64, JsError> {
        if now_ms < 0.0 {
            return Err(JsError::new("now_ms must be non-negative"));
        }
        let mut ts = now_ms as u64;
        if ts < self.last_ts {
            // clock regression — hold at last_ts rather than minting backwards
            ts = self.last_ts;
        }
        if ts == self.last_ts {
            self.seq += 1;
            if self.seq > MAX_SEQ {
                // sequence exhausted this ms — spin to the next ms
                self.seq = 0;
                ts += 1;
            }
        } else {
            self.seq = 0;
        }
        self.last_ts = ts;
        let delta = ts - EPOCH_MS;
        if delta >> TS_BITS != 0 {
            return Err(JsError::new("timestamp exceeds 41 bits past epoch"));
        }
        Ok((delta << TS_SHIFT) | (self.node << NODE_SHIFT) | self.seq)
    }

    /// Mint a full branded id for a namespace.
    pub fn mint(&mut self, namespace: &str, now_ms: f64) -> Result<String, JsError> {
        let sf = self.mint_snowflake(now_ms)?;
        encode(namespace, sf)
    }
}

// ── fusion DEMONSTRATION (per-isolate, single pass, no intermediates) ─────────

/// Fused map(square) → filter(> threshold) → fold(sum), one pass over the slice.
/// This is the per-isolate fusion primitive in miniature: no intermediate arrays
/// cross the wasm boundary, and the whole pipeline runs in linear memory. The
/// cross-core scheduler that fans slices to Cluster workers lives in TypeScript.
#[wasm_bindgen]
pub fn fused_sum_of_squares(values: &[u32], threshold: u32) -> u64 {
    let mut acc: u64 = 0;
    for &v in values {
        let sq = (v as u64) * (v as u64);
        if sq > threshold as u64 {
            acc += sq;
        }
    }
    acc
}

// ── tests ─────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn roundtrip() {
        let sf: u64 = 123_456_789_012;
        let id = encode("USR", sf).unwrap();
        assert_eq!(id.len(), 14);
        assert_eq!(&id[0..3], "USR");
        let d = decode(&id).unwrap();
        assert_eq!(d.namespace, "USR");
        assert_eq!(d.snowflake, sf);
    }

    #[test]
    fn validate_shape() {
        assert!(validate("USR0ONWgLPPGbY"));
        assert!(!validate("plr0ONWgLPPGbY"));
        assert!(!validate("USR0ONWgLPPGb")); // 13 chars
    }

    #[test]
    fn minter_is_monotonic_and_branded() {
        let mut m = Minter::new(7).unwrap();
        let a = m.mint_snowflake(1_704_067_200_001.0).unwrap();
        let b = m.mint_snowflake(1_704_067_200_001.0).unwrap();
        assert!(b > a, "same-ms ids must increase by sequence");
        let id = m.mint("USR", 1_704_067_200_002.0).unwrap();
        assert!(validate(&id));
        let d = decode(&id).unwrap();
        assert_eq!(d.node, 7);
    }

    #[test]
    fn fusion_demo() {
        // squares: 1,4,9,16,25 ; > 5 keeps 9,16,25 → 50
        assert_eq!(fused_sum_of_squares(&[1, 2, 3, 4, 5], 5), 50);
    }
}
