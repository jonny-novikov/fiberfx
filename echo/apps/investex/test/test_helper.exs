# The two-tier harness (rung TRD.9.1, trd.9.1.specs.md INV-8 / G5).
#
# Tier 2 — the live sandbox suite (`@tag :sandbox`) — is EXCLUDED by default, so
# the plain `mix test` run is Tier 1 only: pure, network-free, deterministic
# (Config defaults, the Money round-trip + the read-response shapes, the Retry
# decision, the parity scaffold, the pass-through-fidelity check). The live tier
# runs only on `mix test --include sandbox` (the Stage-4 hard gate). Once that
# is given the caller HAS opted into the live gate, so it is a TRUE hard gate:
# a missing `INVEST_TOKEN` FAILS loudly (the setup `flunk`s) — never a silent
# skip (the post-L-9 idiom: default-exclude + a loud keyless flunk) — see
# test/sandbox_live_test.exs.

# The grpc client supervisor (L-6): grpc 0.11.x requires `GRPC.Client.Supervisor`
# to be running before any `GRPC.Stub.connect/2`, and the `:grpc` app does not
# start it. Because investex is lib-only, the SUITE starts it here, once — it
# persists for the whole run, independent of any single Investex.Client (a
# production consumer supervises `{GRPC.Client.Supervisor, []}` in its own tree).
# Idempotent: `{:ok, pid}` on `:already_started`. Tier-1 (network-free) tests
# never dial, so this is inert for them; it is the precondition the live tier
# needs.
{:ok, _grpc_sup} = GRPC.Client.Supervisor.start_link([])

ExUnit.start(exclude: [:sandbox])
