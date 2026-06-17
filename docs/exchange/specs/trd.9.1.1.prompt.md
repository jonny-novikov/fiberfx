# TRD.9.1.1 · Transport fix — endpoint + Russian-CA TLS trust (x-mode runbook)

> The orchestration runbook for rung **TRD.9.1.1**, run through the aaw Flat-L2 lead-team WITH Apollo (HIGH risk).
> The authoritative scope for the run. The spec slice [`trd.9.1.1.specs.md`](trd.9.1.1.specs.md) (Venus authors it) is
> the build-grade contract; this file is the per-stage orchestration. **Framing (propagate): third person for any
> agent; no gendered pronouns; no perceptual or interior-state verbs; no first-person narration.** **Secret hygiene
> (INV-9, hard): the `INVEST_TOKEN` value appears in nothing this rung writes — env only.**

## The rung in one paragraph

The as-built `echo/apps/investex` transport (shipped at TRD.9.1) **cannot dial the live venue**, and the 9.1 G6
"live PASS" record is a false-green. Two real defects: **DEFECT A** — `Investex.Config` hardcodes the stale
`sandbox-invest-public-api.tinkoff.ru:443` (`config.ex:20`) and `resolve/1` lifts only `INVEST_TOKEN`, **ignoring**
`INVEST_API_URL`/`INVEST_API_PORT` (`config.ex:89-91`); the live host is `sandbox-invest-public-api.tbank.ru:443`
(the T-Bank rebrand). **DEFECT B** — `Investex.Client.tls_opts/0` dials `verify_peer` against
`:public_key.cacerts_get()` (`client.ex:184-193`), but the venue's leaf chains leaf → **Russian Trusted Sub CA** →
**Russian Trusted Root CA** (a self-signed root absent from the host trust store — 0 Russian roots on this machine),
so every verifying handshake is rejected. TRD.9.1.1 fixes both **as the smallest correct change**: Config reads the
two env vars (default `…tbank.ru:443`); the Client trusts a **vendored** `Russian Trusted Root CA` PEM (appended to
`cacerts`, `verify_peer` kept). It adds a **re-runnable 3-way live transport harness** (Operator decision Q2) that
distinguishes a genuine round-trip from a TLS-trust rejection from an egress block, re-proves 9.1's G6, and corrects
the false-green record. On a genuine live PASS it **unblocks TRD.9.2's live floor** (which ships next, separately).

## Mode

**Flat-L2 WITH Apollo.** Venus (spec slice + reconcile) → Mars-1 (build A+B + the vendored cert + the network-free
trust proof) → Director Stage-3 solo review → Mars-2 (harden + the live harness + the rung gate) → **Apollo
(MANDATORY — HIGH risk)** → Director ship (one LAW-4 pathspec commit) → Stage-6 fold.

## Risk tier — HIGH (Apollo mandatory)

The rung changes **TLS peer-verification trust** and **vendors a foreign state-operated root CA into the repo** — a
security / supply-chain dimension. Per x.md §11, a high-risk rung escalates to a dedicated Apollo evaluator with the
§11.2 charter, who resolves every ambiguity via `AskUserQuestion` before the Director's ship.

## Settled forks (no open Operator decision — the Stage-1 gate is reachable)

- **SF-1 — TLS trust (Operator-chosen: "Vendor the root in-repo").** Vendor the `Russian Trusted Root CA` PEM under
  `echo/apps/investex/priv/certs/` and **append** it to `:public_key.cacerts_get()`; keep `verify: :verify_peer`.
  No `verify_none`. The PEM is sourced from the **official** distribution and its identity **pinned** — the root is
  `C=RU, O=The Ministry of Digital Development and Communications, CN=Russian Trusted Root CA`, **SHA-256
  `D2:6D:2D:02:31:B7:C3:9F:92:CC:73:85:12:BA:54:10:35:19:E4:40:5D:68:B5:BD:70:3E:97:88:CA:8E:CF:31`** (Director
  de-risk, verified: trusting *only* this root yields `ssl_verify_result=0` against the venue's real IP
  178.130.128.33). Mars MUST verify the vendored bytes match this fingerprint — never vendor the server-served bytes
  blind (that trusts the thing being authenticated). The venue serves the Sub CA on the wire, so **only the root is
  vendored** (existing `depth: 3` builds leaf→sub→root).
- **SF-2 — no-egress posture (Operator-chosen: "Ship fix + a harness that proves it when verifiable").** The live
  verification is a re-runnable harness. On a genuine live round-trip it PASSES (9.1 G6 re-proven). If the BEAM
  genuinely cannot egress to the venue (the 198.18.x split-tunnel may block `gun` even though `curl` reached the real
  IP), the harness records a **reproduced, named environment-BLOCK** on the live leg — never a false-green — and the
  correctness fix ships with the live leg marked unproven-here, the harness standing to prove it from an
  egress-capable run. **The harness must distinguish a TLS-trust rejection (a real bug → BLOCK the ship) from an
  egress block (environment → ship-with-deferred).**
- **SF-3 — scope.** Its own rung, `trd.9.1.1`. Touches **only** the transport (`config.ex`, `client.ex`, the
  vendored cert, their tests, the live harness, the rung gate) + the spec slice + the 9.1 reconcile + the ledger.
  **Does NOT touch any 9.2 file** — 9.2 ships separately after this rung re-proves the dial.
- **SF-4 — no new dep.** Reading a PEM and appending DER to `cacerts` is `:public_key`/`File.read!` (OTP stdlib) —
  **no `mix.lock` change**; confirm none is swept into the commit.

## The two defects (grounded — Mars cites these lines)

```text
DEFECT A — endpoint (config.ex)
  :20    @endpoint_default "sandbox-invest-public-api.tinkoff.ru:443"   # stale → tbank.ru
  :89-91 resolve/1 reads ONLY System.fetch_env!("INVEST_TOKEN")        # ignores INVEST_API_URL / INVEST_API_PORT
  :53-55 the doctest pins the stale default                            # updates with the surface (no shim)

DEFECT B — TLS trust (client.ex)
  :184-193 tls_opts/0: verify_peer + cacerts: :public_key.cacerts_get()  # OS bundle, 0 Russian roots
  :89-94   init/1 → dial(config)                                          # the {:stop,{:dial_failed,_}} path on reject
```

The Go SDK parity reference: `investgo/client.go:72-73` dials `credentials.NewTLS(&tls.Config{})` (an EMPTY config =
the host system pool, verify ON — it vendors NO Russian CA; it relies on the host having the root). Its own default
endpoint (`client.go:120-121`) is ALSO the stale `…tinkoff.ru` — only an env/`.env.test` override points it at
`tbank.ru`. The `.env.test` (`github.local/invest-api-go-sdk/.env.test`, gitignored) supplies `INVEST_API_URL`,
`INVEST_API_PORT`, `INVEST_TOKEN` — **read the two non-secret settings at the live gate; never the token value, never
copy the file into the repo.**

## Stage 1 · Venus — the spec slice + the 9.1 reconcile (architect)

Author the **build-grade** spec slice and reconcile the transport spec to the corrected reality. Concretely:

- **Author `docs/exchange/trd.9.1.1.specs.md`** (authoritative; the `trd.9.2.specs.md` slice-form precedent): the
  two defects grounded at `file:line`; the A+B fix as the smallest correct change; SF-1..SF-4 as locked decisions
  (each a `tool_x_decision`); the new/changed invariants — **INV-10 (endpoint is env-resolved: `INVEST_API_URL` +
  `INVEST_API_PORT`, default `…tbank.ru:443`)** and **INV-11 (the venue root is vendored + pinned by fingerprint;
  `verify_peer` kept; never `verify_none`)** — woven into the existing INV-5/8/9; the gates **G-TLS (network-free
  trust proof), G6′ (the 3-way live harness), G5 (the pure suite stays network-free), G7 (no token anywhere)** + the
  endpoint/CA provenance; the definition of done. Decide the harness's 3-way contract (PASS / TLS-trust-FAIL=BLOCK /
  egress-BLOCK=reproduced-defer) at the spec level so Mars builds to it.
- **Author a concise `docs/exchange/trd.9.1.1.md`** (the chapter narrative — short; the fix, why, the corrected
  record).
- **Reconcile `docs/exchange/trd.9.1.specs.md`**: the §"Surface, pinned" endpoint default line (`:196`), the
  `Investex.Client` §"TLS posture" moduledoc claim ("verify_peer against the OTP system trust store"), and — the
  important one — **the G6 record at `:368-383`**: mark the prior "STANDING result / ACTUALLY DIALS" claim as a
  **false-green corrected by TRD.9.1.1** (the as-built dialed the stale sinkholed host with no Russian CA; a real
  account_id was structurally impossible; the live floor was never genuinely met). Reconcile `trd.9.1.md` if the
  narrative asserts the live PASS. Mark `trd.progress.md` (open TRD.9.1.1; note it re-proves 9.1 G6 and unblocks 9.2).
- **Lock D-n** for SF-1..SF-4, INV-10, INV-11, the harness 3-way contract, and the G6 false-green correction.

**Gate:** the slice is settled and internally consistent; every reconcile claim is MATCH or `[RECONCILE]`-marked; no
open fork; the harness contract is specified; the vendored-root provenance + fingerprint are in the spec.

## Stage 2 · Mars-1 — build A + B + the vendored cert + the network-free trust proof (implementor)

Build the **smallest correct change** to the spec slice; cite the spec line per public change; invent nothing; keep
the diff inside the transport boundary (SF-3). Concretely:

- **DEFECT A — `Investex.Config`.** `resolve/1` reads `INVEST_API_URL` + `INVEST_API_PORT` from the env (compose
  `host:port`); the default endpoint becomes `sandbox-invest-public-api.tbank.ru:443` (`@endpoint_default` + the
  `new/1` default). Keep the token discipline byte-for-byte (INV-9). Update the `config.ex` doctest + `config_test.exs`
  to the new default (a deliberate surface change — no shim, no backward-compat alias). Decide the precedence
  (explicit `:endpoint` opt > env > default) and document it.
- **DEFECT B — `Investex.Client`.** Vendor the `Russian Trusted Root CA` PEM at `priv/certs/russian_trusted_root_ca.pem`
  (sourced from the official distribution; **verify it matches SHA-256 `D2:6D:…:CF:31`** — record the provenance in a
  comment, never the server-served bytes blind). `tls_opts/0` reads the PEM at runtime (`:code.priv_dir(:investex)` +
  `File.read!` + `:public_key.pem_decode` → DER), **appends** it to `:public_key.cacerts_get()`, keeps
  `verify: :verify_peer` + `depth: 3` + the hostname check. No `verify_none`.
- **The network-free trust proof (G-TLS).** A Tier-1, deterministic test that proves the *mechanism* without the
  venue: assert the vendored root's DER is present in the `cacerts` the client builds, AND (the strong form) a
  loopback TLS handshake that succeeds **only because** the vendored root is trusted (e.g. a tiny `:ssl` server using
  a cert chained to the vendored root, the client verifying against `tls_opts/0`) — so the trust is proven on every
  run, egress or not. This is the spine of "harness until proved."
- **Compile `--warnings-as-errors` clean**; the pure suite (`cd echo/apps/investex && TMPDIR=/tmp mix test`) green and
  network-free; the diff stays inside the transport boundary (no read-service / order / stream / 9.2 file touched).

**Gate:** compiles clean; A+B realized + cited; the vendored cert present + fingerprint-matched; G-TLS proves trust
network-free; Tier-1 green; the boundary holds; the report names any realization-over-literal.

## Stage 3 · Director — solo review (reconcile + re-run + adversarial probe + mutation)

A real Stage-3 pass (never a glance): fresh-gate reconcile of the as-built A+B against the slice; an independent
re-run of the Tier-1 suite + the G-TLS proof; **≥1 adversarial probe** — e.g. corrupt/replace the vendored PEM and
confirm G-TLS turns RED (trust genuinely depends on the real root, not a tautology), and assert a `verify_none` did
not sneak in (`grep -n verify_none`); confirm `resolve/1` honors `INVEST_API_URL`/`INVEST_API_PORT` and the default
is `tbank.ru`; **a mutation spot-check** (Edit-in a bug — e.g. drop the `append` so only the OS bundle is used —
confirm G-TLS kills it, **revert net-zero**). Consolidate the REMEDIATE list. **The Director writes NO production
code (LAW-1a — every probe reverts clean).**

## Stage 4 · Mars-2 — harden + the live harness + the rung gate (implementor, resume Mars-1)

Close the Stage-3 findings (REMEDIATE loop, MAX=3), then:

- **The 3-way live transport harness (G6′, SF-2).** Extend the `@tag :sandbox` live tier (or a focused
  `transport_live_test.exs`) with a re-runnable probe that, with `INVEST_TOKEN` + `INVEST_API_URL`/`INVEST_API_PORT`
  sourced: dials the venue and classifies the outcome into exactly one of — **(i) PASS**: the TLS handshake clears
  AND a decoded gRPC response returns (a non-empty `account_id` from `open_account`, then `close_account`; the INV-8
  positive dialed-proof); **(ii) TLS-trust FAIL**: the handshake is rejected (a cert/`unknown_ca`/`{:tls_alert,_}`
  shape) → **fail loud, this BLOCKS** (the vendored root is wrong); **(iii) egress BLOCK**: a TCP timeout / refused /
  sinkhole before any TLS exchange → a named, reproduced environment-BLOCK (ship-with-deferred per SF-2), NEVER a
  pass. The classifier must not collapse (ii) into (iii). Keep the keyless-`flunk` (a requested live gate with no
  token FAILS loudly, INV-8) and secret hygiene (no token/account-id values logged, INV-9).
- **Re-prove 9.1's G6** through the same harness (open → get_accounts → close) — the genuine replacement for the
  corrected false-green.
- **The rung gate `echo/rungs/exchange/trd_9_1_1_check.exs` + `.out`** (the `trd_9_1_check.exs` compiled-umbrella
  `mix run --no-start` pattern): the network-free gate lines — G-TLS (vendored root in `cacerts`; the loopback trust
  proof), the endpoint is env-resolved + defaults to `tbank.ru`, no `verify_none`, G7 (no token). PASS k/k, exit 0,
  reproducible (run twice, identical).
- **Run the live tier** (`cd echo/apps/investex && set -a; . <.env.test>; set +a; TMPDIR=/tmp mix test --include
  sandbox`; `unset` after; never echo the token) and **report the harness's 3-way verdict honestly** — PASS, or a
  named egress-BLOCK with the reproduced evidence (NO raw account/instrument ids, NO token).
- The determinism loop on the touched suite; the boundary grep empty.

**Gate:** REMEDIATE closed; Tier-1 + G-TLS green; the rung gate PASS k/k reproducible; the live harness ran and its
3-way verdict is reported truthfully (a TLS-trust FAIL blocks; an egress BLOCK is reproduced + named, not green);
secret hygiene holds.

## ◇ Apollo — evaluator (MANDATORY, HIGH risk; runs between Stage 4 and Stage 5)

The §11.2 charter: the prompted-checks table (A+B realized; vendored root pinned to the fingerprint, not
server-served; `verify_peer` kept, no `verify_none`; G-TLS has teeth — proven by a real mutation kill; the live
harness's 3-way classifier is correct and cannot confuse a trust-FAIL with an egress-BLOCK; the false-green G6 record
is corrected; INV-9 secret hygiene structural; no `mix.lock` churn; the boundary held) + **≥1 un-prompted finding** +
**≥1 attack-that-held** (e.g. a malformed/empty PEM, a host with a different CA, a token-mutating async peer) + **a
mutation kill-rate**. Resolve every ambiguity via `AskUserQuestion` (especially: if the live leg is an egress-BLOCK,
confirm the Operator accepts the ship-with-deferred per SF-2, or rules hold). Spec-sync. Verdict **BUILD-GRADE /
BLOCKED** + mentor diffs (the false-green lesson → Mars/Apollo/Venus charters, under an explicit Operator grant only).

## Stage 5 · Director — ship (one LAW-4 pathspec commit)

Preconditions: Stage-3 findings closed; the Stage-4 gate green; **Apollo BUILD-GRADE** with every `AskUserQuestion`
resolved; ≥1 D-n locked; a Z-n written this turn. `git status --short` + `git diff --cached --name-only` reviewed;
`.git/rebase-merge`/`rebase-apply` checked; **`echo/mix.lock` NOT in the diff** (SF-4).

**LAW-4 pathspec** (exact — NEVER `git add -A`, NEVER a bare commit):

```
echo/apps/investex/lib/investex/config.ex
echo/apps/investex/lib/investex/client.ex
echo/apps/investex/priv/certs/russian_trusted_root_ca.pem
echo/apps/investex/test/config_test.exs
echo/apps/investex/test/client_test.exs
echo/apps/investex/test/transport_live_test.exs
echo/apps/investex/test/sandbox_live_test.exs
echo/apps/investex/test/test_helper.exs
echo/rungs/exchange/trd_9_1_1_check.exs
echo/rungs/exchange/trd_9_1_1_check.out
docs/exchange/trd.9.1.1.md
docs/exchange/trd.9.1.1.specs.md
docs/exchange/trd.9.1.1.prompt.md
docs/exchange/trd.9.1.specs.md
docs/exchange/trd.9.1.md
docs/exchange/trd.progress.md
docs/exchange/trd-9-1-1.progress.md
docs/exchange/trd-9-1-1.registry.json
```

(Mars realizes the exact test filenames; stage only the files Mars actually touched — drop any unwritten path from the
pathspec; add none outside it. Exclude any operator out-of-band path.) The message body cites the slug, the Z-n, the
D-n decisions, and the Y-n report.

## Stage 6 · fold forward

Mark `trd.9.1.1` shipped in `trd.progress.md`; record that 9.1 G6 is **genuinely** proven (or the live leg is a named
egress-BLOCK pending an egress-capable run, per SF-2); record the next gap = **return to TRD.9.2's live floor**
(now re-runnable through the harness) + ship 9.2 (its held Stage-5 commit). Surface the mentor diff (the false-green
lesson) for the Operator's grant.

## Acceptance (definition of done)

`Investex.Config.resolve/1` reads `INVEST_API_URL` + `INVEST_API_PORT` (default `…tbank.ru:443`); the doctest +
`config_test.exs` updated (INV-10). `Investex.Client` vendors the pinned `Russian Trusted Root CA`
(SHA-256 `D2:6D:…:CF:31`), appends it to `cacerts`, keeps `verify_peer` (INV-11); `grep -n verify_none` empty. G-TLS
proves the trust network-free (and a mutation kills it). The pure suite + the rung gate are network-free, green, and
reproducible (run twice identical), exit 0. The 3-way live harness ran and its verdict is reported truthfully — a
genuine PASS re-proves 9.1 G6 and unblocks 9.2, OR a reproduced, named egress-BLOCK ships-with-deferred per SF-2 (a
TLS-trust FAIL would BLOCK). The 9.1 G6 false-green record is corrected in `trd.9.1.specs.md`. No token-shaped string
anywhere (G7). `echo/mix.lock` unchanged (SF-4). The transport boundary held (no 9.2 / read-service / order / stream
file touched). Apollo BUILD-GRADE.

## Map

Spec slice: [`trd.9.1.1.specs.md`](trd.9.1.1.specs.md) · chapter [`trd.9.1.1.md`](trd.9.1.1.md). Reconciled:
[`trd.9.1.specs.md`](trd.9.1.specs.md) (the transport spine; the G6 false-green correction). The held next rung:
[`trd.9.2.prompt.md`](trd.9.2.prompt.md) (its live floor re-runs through this harness). Ledger:
`docs/exchange/trd-9-1-1.progress.md`. The parity/transport source: `github.local/invest-api-go-sdk/investgo/
{client,config}.go`; `.env.test` (gitignored — non-secret settings read at the live gate only).
```
