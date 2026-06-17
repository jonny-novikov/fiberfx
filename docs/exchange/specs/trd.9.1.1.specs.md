# TRD.9.1.1 · The Transport Fix — endpoint + Russian-CA TLS trust (specs)

<show-structure depth="2"/>

> Authoritative for rung **TRD.9.1.1** — the transport-fix slice that makes the `echo/apps/investex` venue client
> actually dial the live sandbox, and re-proves [`trd.9.1.specs.md`](trd.9.1.specs.md)'s G6 (a corrected false-green).
> The chapter ([`trd.9.1.1.md`](trd.9.1.1.md)) narrates it; the orchestration runbook is
> [`trd.9.1.1.prompt.md`](trd.9.1.1.prompt.md). The transport spine it fixes-in-place is
> [`trd.9.1.specs.md`](trd.9.1.specs.md) (shipped; reconciled by this rung, NOT rebuilt). **Status: PROPOSED.**
> Definition of done: a committed transcript at `echo/rungs/exchange/trd_9_1_1_check.out`, exit zero, every
> network-free gate line green; the vendored root pinned + fingerprint-matched; the 3-way live harness ran and its
> verdict reported truthfully (a genuine PASS re-proves 9.1 G6 and unblocks 9.2; a TLS-trust FAIL **blocks**; a
> reproduced egress-BLOCK ships-with-deferred per SF-2). Feedback edits this file, not the implementation. **Framing
> (propagate this clause): third person for any agent; no gendered pronouns; no perceptual or interior-state verbs; no
> first-person narration.** **Secret hygiene (INV-9, hard): the `INVEST_TOKEN` value appears in nothing this rung
> writes — read it from the environment only.**

## What TRD.9.1.1 is — and is not

TRD.9.1.1 is the **smallest correct change** that makes the 9.1 transport dial the live venue, plus the harness that
proves it and corrects 9.1's false-green G6 record. The as-built `echo/apps/investex` transport (shipped at TRD.9.1)
**cannot complete a verifying handshake** to the venue — two real defects — so the 9.1 G6 "live PASS" is a false-green
and 9.2's live floor is structurally unreachable. This rung fixes both as a transport-only edit, vendors and pins the
one missing trust anchor, and adds a re-runnable 3-way live transport harness that distinguishes a genuine round-trip
from a TLS-trust rejection from an egress block.

It is **pure-gated** (network-free, deterministic — the trust mechanism is proven without the venue) AND
**live-verified** through the 3-way harness (which reports honestly when the BEAM cannot egress, rather than
false-greening).

**In TRD.9.1.1 (this slice):**

- **DEFECT A — `Investex.Config`** (`config.ex:20,89-91`): `resolve/1` reads `INVEST_API_URL` + `INVEST_API_PORT` from
  the env and composes `host:port` into `:endpoint`; the default endpoint becomes
  `sandbox-invest-public-api.tbank.ru:443` (the T-Bank rebrand). The doctest (`config.ex:53-55`) + `config_test.exs`
  update to the new default — a deliberate surface change, **no shim, no backward-compat alias** (INV-10).
- **DEFECT B — `Investex.Client`** (`client.ex:181-193`): a **vendored** `Russian Trusted Root CA` PEM at
  `priv/certs/russian_trusted_root_ca.pem` (pinned by SHA-256), read at runtime and **appended** to
  `:public_key.cacerts_get()`; `verify: :verify_peer` + `depth: 3` + the hostname check **kept**; no `verify_none`
  (INV-11).
- **G-TLS — the network-free trust proof**: a Tier-1, deterministic test proving the *mechanism* without the venue —
  the vendored root's DER is present in the `cacerts` the client builds, AND (the strong form) a loopback TLS handshake
  that succeeds **only because** the vendored root is trusted. So the trust is proven on every run, egress or not.
- **G6′ — the 3-way live transport harness** (re-runnable): dials the venue and classifies the outcome into exactly
  one of **PASS** / **TLS-trust FAIL** (→ BLOCK) / **egress BLOCK** (→ reproduced-defer); re-proves 9.1's G6
  (`open → get_accounts → close`); never collapses a trust-FAIL into an egress-BLOCK.
- **The rung gate** `echo/rungs/exchange/trd_9_1_1_check.{exs,out}` (the `trd_9_1_check.exs` compiled-umbrella
  `mix run --no-start` pattern): the network-free gate lines — G-TLS, the endpoint env-resolution + the `tbank.ru`
  default, `grep verify_none` empty, G7 — one printed line each, nonzero exit on fail, the transcript committed.
- the **9.1 reconcile** ([`trd.9.1.specs.md`](trd.9.1.specs.md) + [`trd.9.1.md`](trd.9.1.md)): the endpoint default,
  the TLS-posture moduledoc claim, and the G6 false-green record corrected;
- gates **G-TLS, G6′, G5 (the pure suite stays network-free), G7 (no token anywhere)** + INV-5/8/9 (reaffirmed) and
  the new INV-10/INV-11.

**NOT in TRD.9.1.1 (the slice boundary — SF-3):**

- **No 9.2 file** is touched (no read-service module, no `parity_test.exs` growth, no read-tier live test) — 9.2 ships
  separately after this rung re-proves the dial.
- **No other transport public surface** is edited: `Investex.Retry`, `Investex.Money`, `Investex.Error`,
  `Investex.Caller`, `Investex.Users`, `Investex.Sandbox` are reused unchanged (this rung edits only `Config`'s endpoint
  resolution and `Client`'s `tls_opts/0` + dial trust).
- **No new dependency** (SF-4): reading a PEM (`File.read!` + `:public_key.pem_decode` → DER) and appending DER to
  `cacerts` is OTP stdlib; `echo/mix.lock` is **not** touched.
- **No order method, no `EchoData` ORD validation, no stream** — those are 9.3–9.5, unchanged by this rung.

The boundary is the Director's Stage-3 reconcile target: the diff names only `config.ex`, `client.ex`, the vendored
PEM, the touched tests, the rung gate, and the docs — no 9.2 / read-service / order / stream file, no edit to a
transport module's other public surface.

## The two defects (grounded — Mars cites these lines)

```text
DEFECT A — endpoint (config.ex)
  :20    @endpoint_default "sandbox-invest-public-api.tinkoff.ru:443"   # stale → tbank.ru (the T-Bank rebrand)
  :89-91 resolve/1 reads ONLY System.fetch_env!("INVEST_TOKEN")        # ignores INVEST_API_URL / INVEST_API_PORT
  :53-55 the doctest pins the stale default                            # updates WITH the surface (no shim)

DEFECT B — TLS trust (client.ex)
  :184-193 tls_opts/0: verify_peer + cacerts: :public_key.cacerts_get()  # the OS bundle — 0 Russian roots
  :89-94   init/1 → dial(config)                                          # the {:stop,{:dial_failed,_}} path on reject
```

The live host is `sandbox-invest-public-api.tbank.ru:443`; the venue's leaf chains **leaf → Russian Trusted Sub CA →
Russian Trusted Root CA** (a self-signed root absent from the host trust store — 0 Russian roots on this machine), so
every verifying handshake against the as-built `cacerts` is rejected.

**The Go SDK parity (read, not run).** `investgo/client.go:72-73` dials
`credentials.NewTLS(&tls.Config{})` — an **EMPTY** `tls.Config` = the host system cert pool, verify ON; it vendors **NO**
Russian CA and works only because a Russian host already trusts the root. Its own default endpoint
(`client.go:120-121`) is **also** the stale `…tinkoff.ru`; only an env / `.env.test` override (`INVEST_API_URL`) points
it at `tbank.ru`. So env-resolution (INV-10) matches the Go SDK's *actual runtime behavior*, and the vendored root
(INV-11) is the BEAM-native equivalent of "the host already trusts it" — keeping `verify_peer`, never weakening to
`verify_none`. `.env.test` (`github.local/invest-api-go-sdk/.env.test`, gitignored) supplies `INVEST_API_URL` /
`INVEST_API_PORT` / `INVEST_TOKEN` — **read the two non-secret settings at the live gate; never the token value, never
copy the file into the repo.**

## The locked decisions (each a `tool_x_decision` in `docs/exchange/trd-9-1-1.progress.md`)

These eight settle the rung; no open Operator fork remains (the Stage-1 gate is reachable).

1. **SF-1 — vendor the root in-repo, append to `cacerts`, keep `verify_peer` (D-1, Operator-chosen).** The
   `Russian Trusted Root CA` PEM under `echo/apps/investex/priv/certs/russian_trusted_root_ca.pem`, **appended** to
   `:public_key.cacerts_get()`; `verify: :verify_peer` + `depth: 3` + the hostname check kept; **no `verify_none`**. The
   root is **pinned**: `C=RU, O=The Ministry of Digital Development and Communications, CN=Russian Trusted Root CA`,
   **SHA-256 `D2:6D:2D:02:31:B7:C3:9F:92:CC:73:85:12:BA:54:10:35:19:E4:40:5D:68:B5:BD:70:3E:97:88:CA:8E:CF:31`** (the
   Director de-risk: trusting *only* this root yields `ssl_verify_result=0` against the venue's real IP
   178.130.128.33). Mars verifies the vendored bytes match this fingerprint — never the server-served bytes blind. The
   venue serves the Sub CA on the wire, so **only the root is vendored** (the existing `depth: 3` builds leaf→sub→root).
   Alternatives rejected: `verify_none` (weakens a financial client even in sandbox — Operator-rejected, V-1); a
   configurable `INVEST_CA_BUNDLE` (viable, not chosen — the in-repo pin is out-of-box + auditable, V-2).
2. **SF-2 — ship the fix + a re-runnable 3-way live harness that proves it when verifiable (D-2, Operator-chosen).** On
   a genuine live round-trip the harness PASSES (9.1 G6 re-proven). If the BEAM genuinely cannot egress (the 198.18.x
   split-tunnel may block `gun` even though `curl` reached the real IP), the harness records a **reproduced, named
   environment-BLOCK** — never a false-green — and the correctness fix ships with the live leg marked unproven-here,
   the harness standing to prove it from an egress-capable run. **The classifier MUST distinguish a TLS-trust rejection
   (a real bug → BLOCK) from an egress block (environment → ship-with-deferred).**
3. **SF-3 — scope is the transport only (D-3).** `config.ex`, `client.ex`, the vendored cert, their tests, the live
   harness, the rung gate + the spec slice + the 9.1 reconcile + the ledger. **No 9.2 file.** **No edit to a transport
   module's other public surface.** 9.2 ships separately after this rung re-proves the dial.
4. **SF-4 — no new dep (D-4).** Reading a PEM and appending DER to `cacerts` is `:public_key` / `File.read!` (OTP
   stdlib) — **no `mix.lock` change**; confirm none is swept into the commit.
5. **INV-10 — the endpoint is env-resolved (D-5).** `resolve/1` reads `INVEST_API_URL` + `INVEST_API_PORT`, default
   `sandbox-invest-public-api.tbank.ru:443`; precedence **explicit `:endpoint` opt > env > default**; the doctest +
   `config_test.exs` updated, no shim.
6. **INV-11 — the venue root is vendored + pinned (D-6).** The PEM under `priv/certs/`, pinned by the SHA-256 above,
   appended to `cacerts`; `verify_peer` kept; never `verify_none`.
7. **The harness 3-way contract (D-7).** PASS / TLS-trust-FAIL=BLOCK / egress-BLOCK=reproduced-defer; the classifier
   never collapses a trust-FAIL into an egress-BLOCK; the gate proves its own liveness (a present token dials with a
   positive proof; an absent token under `--include sandbox` flunks loud).
8. **The G6 false-green correction (D-8).** `trd.9.1.specs.md:368-383` (and the narrative twin in
   `trd.progress.md:239-254`) marked `[RECONCILE]` corrected-by-TRD.9.1.1: the as-built dialed the sinkholed stale host
   with no Russian CA, so a real non-empty `account_id` was structurally impossible and the live floor was never
   genuinely met.

## Invariants (the subset this slice gates)

Inherited from [`trd.9.specs.md`](trd.9.specs.md) / [`trd.9.1.specs.md`](trd.9.1.specs.md); the new ones are INV-10 and
INV-11; INV-5/8/9 are reaffirmed (and INV-8 sharpened for the live harness).

- **INV-10 — the endpoint is env-resolved (NEW, this slice; corrects DEFECT A).** `Investex.Config.resolve/1` reads
  `INVEST_API_URL` and `INVEST_API_PORT` from the environment and composes `host:port` into the `:endpoint` field; the
  default endpoint is `sandbox-invest-public-api.tbank.ru:443` (the `@endpoint_default` and the `new/1` `:endpoint`
  default). The precedence is **explicit `:endpoint` opt > env (URL+PORT) > default** — documented at the function. The
  doctest (`config.ex:53-55`) and `config_test.exs` reflect the new default; **no shim, no backward-compat alias** to
  the old `tinkoff.ru` literal. INV-9 token discipline is unchanged (the token is still env-only, the value written
  nowhere). *(Scoped: the resolution is pure given the env; the live tier exercises a real `INVEST_API_URL` /
  `INVEST_API_PORT` at the gate.)*
- **INV-11 — the venue root is vendored + pinned; `verify_peer` kept (NEW, this slice; corrects DEFECT B).** A
  `Russian Trusted Root CA` PEM is vendored at `priv/certs/russian_trusted_root_ca.pem`, its identity pinned by SHA-256
  `D2:6D:…:CF:31`. `Investex.Client.tls_opts/0` reads it at runtime (`:code.priv_dir(:investex)` + `File.read!` +
  `:public_key.pem_decode` → DER) and **appends** the DER to `:public_key.cacerts_get()`, keeping `verify: :verify_peer`
  + `depth: 3` + the hostname check. **`verify_none` never appears** in any tier. The vendored bytes are
  fingerprint-matched before use (never the server-served bytes blind). *(Scoped: G-TLS proves the trust mechanism
  network-free; a mutation — corrupt the PEM or drop the append — turns G-TLS red.)*
- **INV-5 — the client owns the channel (reaffirmed, UNCHANGED).** The supervised `Investex.Client` owns the
  `GRPC.Channel` and the resolved `Investex.Config`; investex stays lib-only (no `mod:`); the consumer supervises the
  client. This rung edits only `tls_opts/0` (the dial's trust anchors) — not the ownership model.
- **INV-8 — two test tiers, and the live tier proves its own liveness (reaffirmed; sharpened for G6′).** The pure
  default suite (`mix test` + the `--no-start` rung gate) is network-free and deterministic, with G-TLS added. The
  `@tag :sandbox` live tier is excluded by default; once the caller opts in with `--include sandbox` it is a TRUE hard
  gate responsible for its OWN liveness: (a) with `INVEST_TOKEN` present the harness MUST actually dial and assert a
  positive dialed-proof (a non-empty `account_id`), so a no-op self-skip cannot satisfy the gate's letter; (b) with the
  token **absent under `--include sandbox`** the suite **FAILS loudly** (the `setup` `flunk`s). **The harness's own
  rule (G6′, D-7): a TLS-trust rejection is a FAIL that BLOCKS; an egress block before any TLS exchange is a named,
  reproduced environment-BLOCK (ship-with-deferred), never a pass — and the two are never conflated.** A test must
  never decide its own runnability by reading process-global state a concurrent test can mutate (the L-9 class, removed
  by the default-exclude + the keyless-`flunk`).
- **INV-9 — secret hygiene (hard, reaffirmed byte-for-byte).** `INVEST_TOKEN` is read from the environment only
  (`System.get_env` / `System.fetch_env!`) — never hardcoded, committed, logged, or written into a transcript,
  fixture, gate `.out`, or any doc. `.env.test` stays in `github.local` (gitignored), read at test time, never copied
  into the repo. The token **value** appears in nothing this rung writes; account ids are not dumped raw into the
  ledger or a gate `.out`. The vendored PEM is a public CA certificate, **not** a secret — it carries no token.

## The as-built surfaces this rung touches (pinned — the smallest correct change)

### `Investex.Config` — the endpoint resolution (the only change: DEFECT A)

```elixir
# echo/apps/investex/lib/investex/config.ex — as-built, the lines this rung changes.
@endpoint_default "sandbox-invest-public-api.tinkoff.ru:443"   # :20  → "sandbox-invest-public-api.tbank.ru:443"
def resolve(%__MODULE__{} = config) do                         # :89
  %{config | token: System.fetch_env!("INVEST_TOKEN")}         # :90  → ALSO compose :endpoint from INVEST_API_URL + INVEST_API_PORT
end
#   iex> Investex.Config.new([])  → endpoint "sandbox-invest-public-api.tinkoff.ru:443"  (:53-55, the doctest)
#                                  → "sandbox-invest-public-api.tbank.ru:443"  (updated with the surface)
#   The precedence (INV-10): explicit :endpoint opt (new/1) > env (INVEST_API_URL + INVEST_API_PORT, resolve/1) > default.
#   Token discipline (INV-9) UNCHANGED: resolve/1 still lifts INVEST_TOKEN; the value is written nowhere.
```

The realization is Mars's (where the env-compose lives — in `resolve/1` beside the token lift, the natural seam; the
precedence enforced; an `INVEST_API_PORT` default of `443` if only `INVEST_API_URL` is set is Mars's call to document).
The spec pins the **contract**: `Config.new([]).endpoint == "sandbox-invest-public-api.tbank.ru:443"`; with the two env
vars set, the resolved endpoint reflects them; an explicit `:endpoint` opt overrides both.

### `Investex.Client` — the TLS trust (the only change: DEFECT B)

```elixir
# echo/apps/investex/lib/investex/client.ex — as-built tls_opts/0 (:184-193), the lines this rung changes.
defp tls_opts do
  [
    verify: :verify_peer,                                    # KEPT
    cacerts: :public_key.cacerts_get(),                      # :187 → cacerts_get() ++ [vendored_root_der]
    depth: 3,                                                # KEPT (builds leaf→sub→root)
    customize_hostname_check: [                              # KEPT
      match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
    ]
  ]
end
#   The vendored root (INV-11): :code.priv_dir(:investex) |> Path.join("certs/russian_trusted_root_ca.pem")
#   |> File.read! |> :public_key.pem_decode → the DER, APPENDED to :public_key.cacerts_get(). verify_peer KEPT.
#   The moduledoc §"TLS posture" (:20-27) + the comment (:181-183) update from "OTP system trust store" to the
#   vendored-root reality. grep -n verify_none client.ex stays EMPTY.
```

The realization is Mars's (a private helper that reads + decodes the PEM once; whether memoized at dial or read each
call — the dial is once-per-client, so either is fine). The spec pins the **contract**: the vendored root's DER ∈ the
`cacerts` list `tls_opts/0` builds; `verify: :verify_peer` and `depth: 3` unchanged; `verify_none` absent.

### The vendored certificate (NEW — `priv/` does not yet exist)

```text
# echo/apps/investex/priv/certs/russian_trusted_root_ca.pem  (NEW; priv/ is created by this rung)
#   The OFFICIAL Russian Trusted Root CA, PEM-encoded. Provenance recorded in a comment / the moduledoc.
#   PINNED: C=RU, O=The Ministry of Digital Development and Communications, CN=Russian Trusted Root CA
#           SHA-256 D2:6D:2D:02:31:B7:C3:9F:92:CC:73:85:12:BA:54:10:35:19:E4:40:5D:68:B5:BD:70:3E:97:88:CA:8E:CF:31
#   Mars VERIFIES the vendored bytes hash to this fingerprint before vendoring (never the server-served bytes blind —
#   that would trust the thing being authenticated). It is a PUBLIC certificate, not a secret (INV-9 unaffected).
```

### The test + gate files (the boundary this rung writes)

```text
# echo/apps/investex/test/config_test.exs   — UPDATE the default-endpoint assertion to tbank.ru; add the env-resolution
#                                              + precedence cases (explicit opt > env > default).
# echo/apps/investex/test/client_test.exs    — NEW (absent today): the G-TLS network-free trust proof — the vendored
#                                              root's DER ∈ tls_opts/0's cacerts; the strong-form loopback handshake that
#                                              clears ONLY because the vendored root is trusted; no verify_none.
# echo/apps/investex/test/sandbox_live_test.exs — EXTEND with the 3-way live harness (G6′) OR a focused
#   (or) test/transport_live_test.exs           — transport_live_test.exs; Mars realizes ONE, the Director stages only
#                                              the file written. Keep the @tag :sandbox default-exclude + the keyless flunk.
# echo/apps/investex/test/test_helper.exs    — touch ONLY if the loopback :ssl server / GRPC.Client.Supervisor wiring needs it.
# echo/rungs/exchange/trd_9_1_1_check.{exs,out} — NEW; the trd_9_1_check.exs compiled-umbrella `mix run --no-start`
#                                              pattern, re-pointed: G-TLS, the endpoint env-resolution + tbank.ru default,
#                                              grep verify_none empty, G7. One printed line each, nonzero exit, committed .out.
```

The `transport_live_test.exs` vs `sandbox_live_test.exs` choice is Mars's (the runbook pathspec lists both; the
Director stages only the file Mars actually touched). Extending the existing `sandbox_live_test.exs` keeps the live
tier in one place; a focused file isolates the transport harness — either satisfies G6′.

## The 3-way live harness (G6′ — the contract Mars builds to)

With `INVEST_TOKEN` + `INVEST_API_URL` / `INVEST_API_PORT` sourced into the env (`--include sandbox`), the harness
dials the venue and classifies the outcome into **exactly one** of three. The classifier's discriminator is the **TLS
layer**: a failure carrying a TLS alert / cert shape (after TCP connect) is a trust-FAIL; a failure with **no TLS bytes
exchanged** (a TCP-layer timeout / refusal) is an egress-BLOCK.

```text
(i)  PASS            the TLS handshake clears AND a decoded gRPC response returns:
                     open_account → get_accounts → close_account, asserting a NON-EMPTY account_id
                     (the INV-8 positive dialed-proof). ⇒ re-proves 9.1 G6; unblocks 9.2's live floor.

(ii) TLS-trust FAIL  the handshake is REJECTED — a cert / unknown_ca / {:tls_alert, _} shape (a TLS-layer
                     rejection AFTER TCP connect). ⇒ FAIL LOUD; this BLOCKS the ship (the vendored root is
                     wrong — a real correctness bug, NEVER deferred).

(iii) egress BLOCK   a TCP timeout / connection refused / sinkhole BEFORE any TLS exchange (no ClientHello
                     answered). ⇒ a NAMED, reproduced environment-BLOCK; the correctness fix ships with the
                     live leg marked unproven-here (ship-with-deferred, SF-2); NEVER a pass.
```

**The classifier MUST NOT collapse (ii) into (iii)** — that collapse (a real trust bug masquerading as "just the
environment") is the exact false-green class this rung closes. The realization (how the harness reads the failure shape
— matching the `gun` / `:ssl` error term, or a staged TCP-connect-then-TLS probe) is Mars's; the spec pins the
**contract** (the three disjoint outcomes, the TLS-vs-TCP discriminator, the positive dialed-proof on PASS, the loud
flunk when keyless) and its liveness.

## Acceptance gates (Tier-1 one printed line each; G6′ is the live harness)

- **G-TLS — the vendored root is trusted, proven network-free.** A Tier-1 deterministic test asserts the vendored
  root's DER is present in the `cacerts` list `Investex.Client.tls_opts/0` builds, AND (the strong form) a loopback TLS
  handshake — a tiny `:ssl` server presenting a cert chained to the vendored root, the client verifying against
  `tls_opts/0` — **succeeds only because** the vendored root is trusted; network-free; exit zero. *(INV-11.)*
- **G6′ — the 3-way live transport harness ran and reported truthfully.** With `INVEST_TOKEN` +
  `INVEST_API_URL`/`INVEST_API_PORT` set under `--include sandbox`, the harness dials the venue and classifies the
  outcome into **PASS** (handshake clears + a non-empty `account_id` decoded → 9.1 G6 re-proven, 9.2 unblocked) /
  **TLS-trust FAIL** (→ this BLOCKS the ship) / **egress BLOCK** (a TCP-layer failure before any TLS → a named,
  reproduced environment-BLOCK, ship-with-deferred). The classifier never conflates a trust-FAIL with an egress-BLOCK.
  *(INV-8, SF-2, D-7.)*
- **G5 — the pure suite is network-free and the sandbox tier is excluded by default.** The default `mix test` (and the
  `--no-start` rung gate, now including G-TLS) touches no network and is deterministic; the `@tag :sandbox` suite is
  **excluded by default**; the rung gate `trd_9_1_1_check.{exs,out}` is committed and reproducible (run twice,
  identical); exit zero. *(INV-8.)*
- **G7 — no token value anywhere.** A grep of the app, the tests, the vendored PEM, the gate `.out`, and the ledger
  for a token-shaped string finds none; the token is read from the environment only; account ids are not dumped raw.
  *(INV-9.)*
- **The endpoint provenance.** `Investex.Config` defaults to `sandbox-invest-public-api.tbank.ru:443` and resolves
  `INVEST_API_URL` + `INVEST_API_PORT` (INV-10) — gated as a network-free assertion in the rung gate.
- **The CA provenance.** The vendored PEM hashes to SHA-256 `D2:6D:…:CF:31` and `verify_none` appears nowhere
  (`grep -n verify_none` empty) — gated as a network-free assertion in the rung gate.

### Each gate as a Given/When/Then (the acceptance contract — a no-op must not satisfy its letter)

- **G-TLS.** *Given* the vendored `priv/certs/russian_trusted_root_ca.pem` and `Investex.Client.tls_opts/0`. *When*
  the Tier-1 trust proof runs. *Then* the vendored root's DER ∈ `tls_opts/0`'s `cacerts`, AND a loopback `:ssl`
  handshake against a cert chained to the vendored root clears under `tls_opts/0` (and a cert NOT so chained is
  rejected) — network-free, exit zero. **Liveness (the gate's teeth):** corrupt/replace the vendored PEM, or drop the
  `++` append so only the OS bundle is used → G-TLS turns RED (revert net-zero). The Director's Stage-3 mutation
  spot-check exercises this; Apollo re-runs it independently. A G-TLS that a tautology (e.g. asserting a constant)
  satisfies is underspecified.
- **G6′.** *Given* `INVEST_TOKEN` + `INVEST_API_URL`/`INVEST_API_PORT` in the env under `--include sandbox`. *When*
  the live harness dials the venue. *Then* it reports exactly one of PASS (a non-empty `account_id` decoded, the
  account opened and closed) / TLS-trust FAIL (a cert/`unknown_ca`/`{:tls_alert,_}` shape) / egress BLOCK (a TCP-layer
  timeout/refusal before any TLS). **Liveness (own-liveness, INV-8):** with the token **absent** under
  `--include sandbox` the `setup` `flunk`s loudly (never a silent skip); a TLS-trust FAIL is reported as FAIL (it
  BLOCKS), NOT downgraded to an egress-BLOCK; an egress BLOCK is reported with the reproduced evidence, NOT as green.
- **G5.** *Given* the committed `trd_9_1_1_check.exs`. *When* it runs twice via `mix run --no-start`. *Then* both runs
  print byte-identical `.out`, touch no network, exit zero; and a bare `mix test` excludes `:sandbox` (0 sandbox tests
  run). **Liveness:** a network call in any Tier-1 path, or a non-reproducible line, fails the gate.
- **G7.** *Given* the full 9.1.1 diff (`config.ex`, `client.ex`, the PEM, the tests, the gate `.out`) and the ledger.
  *When* grepped for a token-shaped string and for a raw account-id dump. *Then* none is found; the token is read from
  the env only. **Liveness:** a literal token, or a `.env.test` copied into the repo, or a raw account id in the
  `.out`/ledger, fails the grep.

## Coverage — every Deliverable → its gate (completion provable from the text)

| Deliverable | Story (in [`trd.9.1.1.md`](trd.9.1.1.md)) | Invariant(s) | Gate |
|---|---|---|---|
| DEFECT A fix — `Config` env-resolves the endpoint, default `tbank.ru` | the env-resolved-endpoint story | INV-10 | G5 (the endpoint provenance line), G6′ (live, uses the resolved endpoint) |
| DEFECT B fix — `Client` trusts the vendored pinned root, `verify_peer` kept | the vendored-trust story | INV-11 | G-TLS, G5 (the CA provenance line) |
| The vendored `Russian Trusted Root CA` PEM, fingerprint-matched | the pinned-provenance story | INV-11 | G-TLS, G5 (the `D2:6D:…:CF:31` + no-`verify_none` line) |
| The network-free trust proof (the loopback handshake) | the prove-trust-offline story | INV-11 | G-TLS |
| The 3-way live transport harness | the live-verification story | INV-8 | G6′ |
| The rung gate `trd_9_1_1_check.{exs,out}` (network-free, reproducible) | the deterministic-gate story | INV-8 | G5 |
| Secret hygiene (env-only, no raw ids, the PEM is not a secret) | the secret-hygiene story | INV-9 | G7 |
| The 9.1 G6 false-green correction | the corrected-record story | INV-8 | (the reconcile of `trd.9.1.specs.md`) |

## Definition of done

`Investex.Config.resolve/1` reads `INVEST_API_URL` + `INVEST_API_PORT` (default `…tbank.ru:443`), precedence
explicit-opt > env > default; the doctest + `config_test.exs` updated, no shim (INV-10). `Investex.Client` vendors the
pinned `Russian Trusted Root CA` (SHA-256 `D2:6D:…:CF:31`), appends it to `cacerts`, keeps `verify_peer` + `depth: 3`
(INV-11); `grep -n verify_none` empty. G-TLS proves the trust network-free (and a mutation — corrupt the PEM or drop
the append — kills it). The pure suite + the rung gate `trd_9_1_1_check.{exs,out}` are network-free, green, and
reproducible (run twice, identical), exit zero (G5). The 3-way live harness ran and its verdict is reported truthfully
— a genuine PASS re-proves 9.1 G6 and unblocks 9.2, OR a reproduced, named egress-BLOCK ships-with-deferred per SF-2
(a TLS-trust FAIL would BLOCK). The 9.1 G6 false-green record is corrected in `trd.9.1.specs.md` (and the narrative
twin in `trd.progress.md`). No token-shaped string anywhere (G7). `echo/mix.lock` unchanged (SF-4). The transport
boundary held (no 9.2 / read-service / order / stream file touched; no other transport public surface edited). Apollo
BUILD-GRADE.

## Map

Chapter: [`trd.9.1.1.md`](trd.9.1.1.md). The orchestration runbook: [`trd.9.1.1.prompt.md`](trd.9.1.1.prompt.md). The
transport spine fixed-in-place (reconciled, not rebuilt): [`trd.9.1.specs.md`](trd.9.1.specs.md) ·
[`trd.9.1.md`](trd.9.1.md). The held next rung whose live floor re-runs through this harness:
[`trd.9.2.specs.md`](trd.9.2.specs.md) · [`trd.9.2.prompt.md`](trd.9.2.prompt.md). System:
[`exchange.specs.md`](exchange.specs.md). Ledger: `docs/exchange/trd-9-1-1.progress.md`. The as-built code:
`echo/apps/investex/lib/investex/{config,client}.ex`. The parity / transport source:
`github.local/invest-api-go-sdk/investgo/{client,config}.go`; `.env.test` (gitignored — the non-secret
`INVEST_API_URL`/`INVEST_API_PORT` read at the live gate only).
