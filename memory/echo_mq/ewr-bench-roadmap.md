---
name: ewr-bench-roadmap
description: "The bench-derived EchoMQ wire-version ladder (docs/echo_mq/wire/ewr4.roadmap.md, Rungs 1-6 → echomq:2.5.0..3.0.0) — DISTINCT from the ewr.1.x EchoWire client-core; client floor + native expiry SHIPPED Solo; the SHIP-SUBSTANCE-ADDITIVELY-DEFER-THE-CUTOVER pattern (the antidote to the fence-pollution saga)"
project: echo_mq
metadata: 
  node_type: memory
  type: project
  originSessionId: f0fa8104-c521-496a-a94b-d45bdf1b5eaa
---

`docs/echo_mq/wire/ewr4.roadmap.md` = the **bench-derived EchoMQ improvement ladder** — Rungs 1-6 climbing
the wire-version fence (`2.5.0` client floor · `2.6.0` native expiry · `2.7.0` functions · `2.8.0` durability
dial · `2.9.0` read plane · `3.0.0` scale out). **DISTINCT from the `ewr.1.x` EchoWire client-core program**
([[ewr-wire-program]] — Pipe/Cmd/Result), though BOTH live under `docs/echo_mq/wire/` and BOTH use the `ewr.`
prefix. **Numbering collision to watch:** the Operator names a rung by its wire-version target — "ewr.2.6" =
Rung 2 native expiry = spec **ewr.4.2**; "2.5" = Rung 1 client floor = spec **ewr.4.1** (specs under
`docs/echo_mq/wire/specs/ewr.4/`).

**SHIPPED Solo (2026-06-19):**
- **ewr.4.1 client floor** — Pool-fronted enqueue via an opaque `via` dispatch (Connector default, Pool via
  opts), conformance 55→57 (`pool_enqueue`/`pool_order`); commits `5eca83fa` [echo_mq] + `d52bf08a` [echo_wire]
  (package label →2.5.0 only). RESP3 gotcha caught by the gate: `ZSCORE` returns the Double `0.0` (not `"0"`);
  match the codebase idiom `when s in [0, "0", +0.0]`.
- **ewr.2.6 native expiry** — fold the worker lock MARKER into the job hash as a `lock` FIELD with its own
  Valkey hash-field TTL (`HEXPIRE`/HFE, ≥7.4), written ALONGSIDE the retained `:lock` STRING marker this rung
  (belt-and-braces); `@remove_job` honors EITHER (one added `HEXISTS` on the declared `KEYS[1]` root, all other
  scripts byte-frozen); conformance 57→59 (`native_lock_field`/`native_lock_refuses`); commit `626e6674`.
  `HPEXPIREAT <past>` = a deterministic field-self-clear proof (no real-time wait); 100/100 determinism loop.

**THE LOAD-BEARING PATTERN (applied twice — the antidote to the fence-pollution saga that cost ~2h/~370k
tokens):** ship the rung's **substance additively + in-boundary (echo_mq only) + green**, and **DEFER the fence
cutover** (the `@wire_version` climb in the FROZEN `echo_wire/connector.ex:35` + the live-fence reset). WHY
defer: (1) climbing the fence on the shared `:6390` dev engine **bricks every other connection** until the live
`{emq}:version` is reset — a shared-state write the auto-classifier DENIES; (2) the cutover version NUMBER is
**contested** — ewr4.roadmap says `2.6.0`, but the Operator ruled the fence **follows the EchoMQ climb** (the
`2.4.x` line: `2.4.2` live, `2.4.3`=emq.4.3 metronome). So a **client-contract/additive rung defaults to NO
fence climb**; the cutover is a separate Operator-timed switch. The native-expiry roadmap itself sanctions this
("keep the sweeper belt-and-braces for one rung… remove in 2.7"), so ewr.2.6's field rides ALONGSIDE the string
marker; the cutover (field-only `remove_job` + string-marker retirement + the fence climb) is **2.7**.

Solo-ship rigor stays CONSTANT (only ceremony scales, per [[right-size-formation-and-write-only-artifacts]]):
per-app gate from the app dir, additive-minor law (prior scenarios byte-unchanged + git-verified, re-pin the
count in both pinning tests), Lua byte-freeze except the one sanctioned script, the ≥100 determinism loop for a
lease/lock/process suite, pathspec `git commit --only -- <files>` (the Operator stages out-of-band; `--only`
commits ONLY the named paths regardless of the index). See [[echo-mq-three-movements]] (the fence + version
climb) · [[ewr-wire-program]].
