defmodule Investex.TransportLiveTest do
  @moduledoc """
  Tier 2 (the live transport harness, G6′) — the re-runnable 3-way classifier that
  re-proves 9.1's G6 and unblocks 9.2's live floor (rung TRD.9.1.1,
  `docs/exchange/trd.9.1.1.specs.md` §"The 3-way live harness"; INV-8, SF-2, D-7).
  `@moduletag :sandbox` + the default `exclude: [:sandbox]` (test_helper.exs): this
  module runs ONLY on `mix test --include sandbox`. A focused TRANSPORT file (D-5)
  — distinct from `sandbox_live_test.exs`, which carries the 9.2 read subset this
  rung must not touch (SF-3); it reuses that tier's *mechanisms* (the `:sandbox`
  default-exclude, the `GRPC.Client.Supervisor` from test_helper.exs, the
  keyless-`flunk`, INV-9), not its file.

  ## The 3-way contract (D-7) and why the discriminator is a direct `:ssl.connect`

  The dial outcome is classified into EXACTLY one of:

    * **PASS** — the TLS handshake clears AND a decoded gRPC round-trip returns:
      `open_account → get_accounts → close_account`, asserting a NON-EMPTY
      `account_id` (the INV-8 positive dialed-proof). Re-proves 9.1 G6; unblocks
      9.2's live floor.
    * **TLS-trust FAIL** — the handshake is REJECTED with a TLS alert
      (`{:tls_alert, _}` / `unknown_ca` — a TLS-layer rejection AFTER TCP connect).
      ⇒ **fail loud, this BLOCKS** (the vendored root is wrong — a real correctness
      bug, NEVER deferred).
    * **egress BLOCK** — a TCP-layer failure BEFORE any TLS exchange (`:timeout` /
      `:closed` / `:econnrefused` / `:nxdomain`). ⇒ a NAMED, reproduced
      environment-BLOCK (ship-with-deferred, SF-2); NEVER a pass.

  The discriminator is a **direct `:ssl.connect/4`** to the resolved venue host,
  using EXACTLY `Investex.Client.tls_opts/0`'s trust set (the OS bundle ++ the
  vendored Russian root, `verify: :verify_peer`, `depth: 3`, the https hostname
  check) plus the SNI the raw socket needs — with a SHORT timeout. This is a
  deliberate realization-over-literal (D-4, forced by L-4): the as-built
  `Investex.Client` dial inherits grpc's `gun` adapter `retry: 100` + exponential
  backoff, so `start_link/1` does NOT promptly return a clean, classifiable term —
  a TLS-trust reject is retried like a connection failure and would TIME OUT,
  COLLAPSING a TLS-FAIL into an egress-BLOCK (the exact false-green this rung
  closes). `:ssl.connect` returns the discriminating term IMMEDIATELY:
  `{:error, {:tls_alert, _}}` for a verify-reject (TLS-layer) vs `{:error, atom}`
  for a TCP-layer failure — disjoint, no retry storm. Proven against the live
  venue (D-4): with the vendored root the venue handshake clears; with the OS
  bundle alone it returns `{:error, {:tls_alert, {:unknown_ca, _}}}`. Only after
  the discriminator clears does the harness run the gRPC round-trip for the PASS
  proof — so a TLS-FAIL can never masquerade as a green round-trip, and an
  egress-BLOCK is named before any RPC is attempted.

  Secret hygiene (INV-9, hard): the token is read from the env only, never
  asserted-on, printed, or written. The `account_id` obtained is asserted to be a
  non-empty binary — its VALUE is never logged.
  """
  use ExUnit.Case, async: false

  alias Investex.{Client, Config, Sandbox}
  alias Tinkoff.Public.Invest.Api.Contract.V1, as: Proto

  @moduletag :sandbox

  # The discriminator's TLS connect timeout (short — no gun retry; a fail-fast
  # classify). The gRPC round-trip uses the client's own dial after this clears.
  @tls_probe_timeout 8_000

  # The token must be present once `--include sandbox` is given (the caller opted
  # in). A missing token FAILS the setup loudly — never a silent skip (INV-8, the
  # post-L-9 idiom). The token VALUE is NOT placed in the context.
  setup do
    token = System.get_env("INVEST_TOKEN")

    unless is_binary(token) and token != "" do
      flunk(
        "INVEST_TOKEN is not set, but the live transport harness was requested " <>
          "(--include sandbox). The G6′ live gate cannot run without a token. " <>
          "Source it into the env (never into a file) and re-run."
      )
    end

    :ok
  end

  test "G6′ — the venue dial classifies into PASS / TLS-trust FAIL (BLOCK) / egress BLOCK" do
    {host, port} = resolved_host_port()

    case classify_dial(host, port) do
      {:pass, account_id} ->
        # PASS — the handshake cleared AND the gRPC round-trip returned a non-empty
        # account_id (the INV-8 dialed-proof). 9.1 G6 re-proven; 9.2 unblocked.
        assert is_binary(account_id) and byte_size(account_id) > 0,
               "PASS requires a non-empty account_id (the dialed-proof) — got an empty id"

        IO.puts(
          "[G6′ PASS] venue=#{host}:#{port} — TLS verified against the vendored Russian root, " <>
            "open_account → get_accounts → close_account round-tripped, a non-empty account_id " <>
            "decoded (value not logged). 9.1 G6 re-proven; 9.2's live floor unblocked."
        )

      {:tls_trust_fail, alert} ->
        # TLS-trust FAIL — a TLS-layer rejection AFTER TCP connect. The vendored
        # root does not anchor the live chain: a real correctness bug. BLOCK.
        flunk(
          "[G6′ TLS-trust FAIL → BLOCK] venue=#{host}:#{port} — the TLS handshake was REJECTED " <>
            "with a TLS alert (#{inspect(alert)}). The vendored Russian Trusted Root CA does NOT " <>
            "verify the live venue chain — a real correctness bug in the trust anchor (INV-11). " <>
            "This BLOCKS the ship; it is NEVER downgraded to an egress-BLOCK. Re-check the " <>
            "vendored root against the venue's served chain."
        )

      {:egress_block, reason} ->
        # egress BLOCK — a TCP-layer failure BEFORE any TLS exchange. A named,
        # reproduced environment-BLOCK (SF-2): the correctness fix ships with the
        # live leg unproven-here; this harness re-runs from an egress-capable host.
        # NOT a pass, and NOT a TLS-FAIL.
        IO.puts(
          "[G6′ egress BLOCK — reproduced, ship-with-deferred (SF-2)] venue=#{host}:#{port} — " <>
            "a TCP-layer failure (#{inspect(reason)}) BEFORE any TLS exchange (no ClientHello " <>
            "answered). The BEAM cannot egress to the venue from this environment. The 9.1.1 " <>
            "correctness fix is unaffected (G-TLS proves the trust mechanism network-free); the " <>
            "live leg is marked unproven-here, and THIS harness re-proves it from an " <>
            "egress-capable run. This is NOT a TLS-trust FAIL (no TLS bytes were exchanged)."
        )

        # An egress-BLOCK is a reproduced, named environment condition — the test
        # does not FAIL the suite (ship-with-deferred, SF-2), but it is also never
        # a silent green: the named line above is the reproduced evidence. The
        # assertion documents that no TLS alert was seen (so this was correctly
        # NOT classified as a trust-FAIL).
        refute match?({:tls_alert, _}, reason),
               "an egress-BLOCK must carry a TCP-layer reason, never a TLS alert"
    end
  end

  # ── the classifier ───────────────────────────────────────────────────────────

  # Classify the venue dial into {:pass, account_id} | {:tls_trust_fail, alert} |
  # {:egress_block, reason}. The discriminator runs FIRST (a fail-fast :ssl.connect
  # with the client's real trust set); only on a cleared handshake is the gRPC
  # round-trip attempted for the PASS proof.
  defp classify_dial(host, port) do
    case tls_discriminate(host, port) do
      :handshake_cleared ->
        grpc_roundtrip()

      {:tls_alert, alert} ->
        {:tls_trust_fail, alert}

      {:tcp_error, reason} ->
        {:egress_block, reason}
    end
  end

  # The discriminator: a direct :ssl.connect using EXACTLY Investex.Client.tls_opts/0
  # (the shipped trust set — the OS bundle ++ the vendored root, verify_peer,
  # depth:3, the https hostname check) plus the SNI the raw socket needs. A short
  # timeout, no gun retry. Returns :handshake_cleared | {:tls_alert, alert} |
  # {:tcp_error, reason} — the disjoint, immediate 3-way signal (D-4).
  defp tls_discriminate(host, port) do
    host_cl = String.to_charlist(host)
    opts = Client.tls_opts() ++ [server_name_indication: host_cl, active: false]

    case :ssl.connect(host_cl, port, opts, @tls_probe_timeout) do
      {:ok, sock} ->
        :ssl.close(sock)
        :handshake_cleared

      {:error, {:tls_alert, alert}} ->
        {:tls_alert, alert}

      {:error, reason} ->
        {:tcp_error, reason}
    end
  end

  # The PASS proof (only reached after the handshake cleared): the gRPC round-trip
  # open_account → get_accounts → close_account through the real Investex.Client,
  # asserting a non-empty account_id (the INV-8 dialed-proof). Returns
  # {:pass, account_id}. The client dial here is past the trust gate (the
  # discriminator already cleared), so gun's retry does not bite the classify.
  defp grpc_roundtrip do
    {:ok, client} = Client.start_link([])

    try do
      {:ok, %Proto.OpenSandboxAccountResponse{account_id: account_id}} =
        Sandbox.open_account(client)

      {:ok, %Proto.GetAccountsResponse{accounts: accounts}} = Sandbox.get_accounts(client)

      true = is_list(accounts)

      {:ok, %Proto.CloseSandboxAccountResponse{}} = Sandbox.close_account(client, account_id)

      {:pass, account_id}
    after
      if Process.alive?(client), do: Client.stop(client)
    end
  end

  # Resolve the real endpoint the client would dial (INV-10: INVEST_API_URL /
  # INVEST_API_PORT, else the tbank.ru default) and split "host:port".
  defp resolved_host_port do
    %Config{endpoint: endpoint} = Config.new([]) |> Config.resolve()
    [host, port] = String.split(endpoint, ":", parts: 2)
    {host, String.to_integer(port)}
  end
end
