---
title: "Dive 10.1 — The byte-frozen wire & the handshake"
id: ep-m10-d1
status: established
route: "/echo-persistence/engines/beam-rust-contract/the-byte-frozen-wire"
kind: "module 10 · dive 10.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive version-negotiation SVG; no machine numbers."
grounded-in: "docs/graft/specs/graft.4.md (the declared-keys table, version-negotiation contract, fixtures)"
renders-to: "engines/beam-rust-contract/the-byte-frozen-wire.html"
---

# The byte-frozen wire & the handshake { id="ep-m10-d1" }

> _A cross-runtime contract has two failure modes a single-runtime one never has: the two sides can disagree about what the bytes mean, or about which version of the bytes they speak. `echo_graft_proto` closes both — one frozen encoding per message pinned to a fixture both runtimes assert against, and a version handshake that refuses a mismatch before it can touch a Volume._

**Interactive figure.** A version axis with ticks v1, v2, v3. A fixed backend range bar spans v1–v2; a client range bar is set by the controls. On overlap a dashed marker highlights the selected protocol version (the minimum of the two maxima) and a `Welcome` is shown; on a disjoint range an `Incompatible` is shown with the note that no Volume is touched.

## §1 Refuse before you touch anything { id="hs" }

The handshake is the first message and its only job is to make a later silent disagreement impossible. `PROTO_MIN`/`PROTO_MAX` are `u32` constants compiled into `echo_graft_proto` and mirrored on the Elixir side from one source. The client opens with `Hello{proto_min, proto_max, client}`; if the ranges overlap the backend selects `proto = min(client.proto_max, backend.PROTO_MAX)` and replies `Welcome{proto}`, and that number is echoed onto the session and fixes which fixture generation is authoritative. If the ranges are disjoint the backend replies `Incompatible{proto_min, proto_max, reason}` and performs no Volume operation — and the test that proves it is a negative: assert the engine's Volume set is byte-identical before and after the refused connect, so a no-op can never pass for the letter of the rule. A future wire change bumps `PROTO_MAX` and ships the new fixtures alongside the old, which stay byte-frozen, so an old client keeps negotiating an old version forever.

## §2 One encoding, two readers { id="wire" }

Past the handshake, every message is small, declared, and frozen. A message is RESP3 — an array of bulk strings produced by the real Elixir codec `EchoMQ.RESP.encode/1`, the same codec the rest of EchoMQ uses — and the Rust side encodes the identical bytes. The request set is just `OpenVolume`, `ResolveBranded`, `Commit`, `Push`, `Pull`, `Read`, `Snapshot`, `GetCommit`; the responses are `Ack`, `Pages`, `SnapshotResp`, `Err`; and the change-feed event rides as an opaque eg.3 blob, already byte-frozen, so the wire wraps it as one bulk string and never re-encodes its fields — two freeze-points that compose without duplication. The error enum is closed by construction: `conflict` (the OCC / fence loser), `not_found` (an unknown Volume or commit), `version_mismatch` (the handshake refusal), and `unavailable` (a transient backend or a refused malformed input such as an over-`PAGESIZE` page — never a panic). A new kind is a protocol-version bump, never a silent addition. The whole contract is held by one canonical fixture set — a committed file of `{message_name, hex_bytes}` mirrored byte-identically into both trees; the Rust conformance test encodes each message and asserts `== hex`, the Elixir conformance test does the same with `EchoMQ.RESP.encode/1`, and both decode the hex and assert the round-trip value. Neither side owns its own truth, and a fixture mismatch is a loud failure on both — the byte-frozen wire is the HIGH-risk mitigation that lets two runtimes evolve without skewing.

## §3 References & sources { id="refs" }

Echo records:
- graft specs / graft.4.md — the declared-keys table, the version-negotiation contract, the fixture set — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/specs/graft.4.md
- ewr.design.md — EchoWire / the EchoMQ.RESP codec the fixtures use — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/wire/design/ewr.design.md
- graft.roadmap.md — eg.4; byte-frozen wire as cross-cutting gate G3 — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md

External:
- RESP3 protocol — arrays and bulk strings — https://redis.io/docs/latest/develop/reference/protocol-spec/
- Semantic versioning — why a wire change is a major — https://semver.org/

---

_Pager: ← Module 10 — The BEAM↔Rust contract · Dive 10.2 — Commit, ack, and the feed advance →_
