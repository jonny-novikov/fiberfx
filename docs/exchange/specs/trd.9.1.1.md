# TRD.9.1.1 · The Transport Fix — endpoint + Russian-CA TLS trust

<show-structure depth="2"/>

> A corrective slice of rung TRD.9.1 ([`trd.9.1.specs.md`](trd.9.1.specs.md)). This chapter narrates;
> [`trd.9.1.1.specs.md`](trd.9.1.1.specs.md) is authoritative for the slice; the runbook is
> [`trd.9.1.1.prompt.md`](trd.9.1.1.prompt.md). **Status: PROPOSED.** It fixes the as-built `echo/apps/investex`
> transport in place — two real defects — vendors and pins the one missing trust anchor, re-proves 9.1's G6 through a
> 3-way live harness, and corrects the false-green G6 record. **Framing (propagate this clause): third person for any
> agent; no gendered pronouns; no perceptual or interior-state verbs; no first-person narration.** **Secret hygiene
> (INV-9, hard): the `INVEST_TOKEN` value appears in nothing this rung writes — read it from the environment only.**

## Overview

TRD.9.1 shipped the transport spine and recorded a passing live G6 — but the as-built transport **cannot dial the
live venue**, and that G6 record is a false-green. TRD.9.1.1 is the smallest correct change that makes the dial real,
plus the harness that proves it honestly and the reconcile that corrects the record. Two defects, two fixes, one
network-free trust proof, one 3-way live harness, one rung gate. No new dependency, no shim, no 9.2 file touched.

## The two defects

**DEFECT A — the stale endpoint.** `Investex.Config` hardcodes the default
`sandbox-invest-public-api.tinkoff.ru:443` (`config.ex:20`) and `resolve/1` lifts **only** `INVEST_TOKEN`
(`config.ex:89-91`), ignoring `INVEST_API_URL` and `INVEST_API_PORT`. The live host is
`sandbox-invest-public-api.tbank.ru:443` — the T-Bank rebrand. The old name is a sinkhole / stale alias, so the dial
never reaches the venue and the endpoint is structurally un-overridable from the environment.

**DEFECT B — the missing trust anchor.** `Investex.Client.tls_opts/0` dials `verify_peer` against
`:public_key.cacerts_get()` (`client.ex:184-193`) — the OS trust bundle, which holds **0 Russian roots**. The venue's
leaf chains **leaf → Russian Trusted Sub CA → Russian Trusted Root CA**, a self-signed root absent from that bundle, so
every verifying handshake is rejected and `init/1` takes the `{:stop, {:dial_failed, _}}` path. Even with the endpoint
fixed, the handshake would still fail.

Together the two make a genuine round-trip impossible: the wrong host, and — even reaching the right one — an untrusted
root. The Go SDK (`investgo/client.go:72-73`) dials with an empty `tls.Config{}` (the host system pool, verify on) and
vendors no Russian CA — it works only because a Russian host already trusts the root; its own default endpoint
(`client.go:120-121`) is the same stale `…tinkoff.ru`, overridden to `tbank.ru` only by an env setting.

## The fix (the smallest correct change)

**A — env-resolve the endpoint.** `resolve/1` reads `INVEST_API_URL` + `INVEST_API_PORT` and composes `host:port` into
`:endpoint`; the default becomes `sandbox-invest-public-api.tbank.ru:443`. Precedence: an explicit `:endpoint` opt
wins, then the env, then the default. The doctest and `config_test.exs` update to the new default — a deliberate
surface change, no backward-compat alias (INV-10). This matches the Go SDK's actual runtime behavior, which is itself
env-driven.

**B — vendor and pin the venue root.** A `Russian Trusted Root CA` PEM is vendored at
`priv/certs/russian_trusted_root_ca.pem`, read at runtime and **appended** to `:public_key.cacerts_get()`;
`verify: :verify_peer` + `depth: 3` + the hostname check are **kept** — `verify_none` never appears (INV-11). The root
is pinned by SHA-256 `D2:6D:2D:02:31:B7:C3:9F:92:CC:73:85:12:BA:54:10:35:19:E4:40:5D:68:B5:BD:70:3E:97:88:CA:8E:CF:31`
(`C=RU, O=The Ministry of Digital Development and Communications, CN=Russian Trusted Root CA`), and the vendored bytes
are fingerprint-matched before use — never the server-served bytes blind, which would trust the very thing being
authenticated. The Director's de-risk confirmed: trusting *only* this root yields `ssl_verify_result=0` against the
venue's real IP (178.130.128.33), and the venue serves the Sub CA on the wire, so only the root is vendored — the
existing `depth: 3` builds leaf→sub→root. This is the BEAM-native equivalent of "the host already trusts it," keeping
peer verification rather than weakening it.

This is a **security / supply-chain** change — it alters TLS peer-verification trust and vendors a foreign
state-operated root CA into the repo — which is why the rung is HIGH risk and carries a dedicated Apollo evaluator.

## Proving it — network-free, then live

**The network-free trust proof (G-TLS).** A deterministic Tier-1 test proves the *mechanism* without the venue: the
vendored root's DER is present in the `cacerts` the client builds, and a loopback TLS handshake — a tiny `:ssl` server
presenting a cert chained to the vendored root — clears under `tls_opts/0` **only because** the vendored root is
trusted. So the trust is proven on every run, egress or not; a mutation (corrupt the PEM, or drop the append) turns it
red.

**The 3-way live harness (G6′).** With the token and the endpoint settings sourced from the environment, a re-runnable
harness dials the venue and classifies the outcome into exactly one of three: **PASS** (the handshake clears and a
decoded gRPC response returns a non-empty `account_id` — `open → get_accounts → close`); **TLS-trust FAIL** (the
handshake is rejected — a cert / `unknown_ca` / `{:tls_alert, _}` shape — which **blocks** the ship, because the
vendored root is wrong); **egress BLOCK** (a TCP-layer timeout or refusal before any TLS exchange — a named, reproduced
environment block that ships-with-deferred, the harness standing to prove the live leg from an egress-capable run). The
classifier distinguishes a trust rejection from an egress block by the TLS layer and never collapses one into the
other — that collapse is the exact false-green class this rung closes.

## The corrected record

The prior 9.1 record marked G6 "ACTUALLY DIALS … a STANDING result" with per-seed millisecond timings
(`trd.9.1.specs.md:368-383`; the narrative twin in `trd.progress.md`). Against the as-built transport that result was
structurally impossible — the dial reached a sinkholed stale host with no Russian CA, so a real non-empty `account_id`
could never have returned, and the live floor was never genuinely met. The earlier 9.1 Apollo loop fixed a *different*
false-green (an `async` OS-env token clobber that no-op'd the gate) and correctly hardened the gate's own-liveness — but
the gate's letter (assert a non-empty `account_id`) was being satisfied by a dial that could not have run as recorded,
because the env was masking the transport failure as a different shape. The lesson the reconcile records: own-liveness
on a live gate is necessary but not sufficient — the substrate the gate dials must be independently de-risked. This
rung marks the old record corrected and re-proves G6 genuinely through the harness, after the fix lands.

## The boundary

The slice touches only the transport: `config.ex`, `client.ex`, the vendored PEM, their tests, the live harness, and
the rung gate — plus the spec slice, the 9.1 reconcile, and the ledger. No 9.2 file, no read-service / order / stream
module, and no other transport public surface (`Retry`, `Money`, `Error`, `Caller`, `Users`, `Sandbox` are unchanged).
No new dependency: reading a PEM and appending DER to `cacerts` is OTP stdlib, so `echo/mix.lock` is not touched. On a
genuine live PASS the rung unblocks TRD.9.2's live floor, which ships next, separately.

## Map

Authoritative spec: [`trd.9.1.1.specs.md`](trd.9.1.1.specs.md). The runbook:
[`trd.9.1.1.prompt.md`](trd.9.1.1.prompt.md). The transport spine fixed in place:
[`trd.9.1.specs.md`](trd.9.1.specs.md) · [`trd.9.1.md`](trd.9.1.md). The held next rung:
[`trd.9.2.specs.md`](trd.9.2.specs.md). The suite ledger: [`trd.progress.md`](trd.progress.md); the rung ledger
`docs/exchange/trd-9-1-1.progress.md`. The as-built code: `echo/apps/investex/lib/investex/{config,client}.ex`. The
parity source: `github.local/invest-api-go-sdk/investgo/{client,config}.go`.
