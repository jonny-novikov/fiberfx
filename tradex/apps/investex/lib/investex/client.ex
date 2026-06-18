defmodule Investex.Client do
  @moduledoc """
  The one supervised process that owns the venue connection (rung TRD.9.1,
  `docs/exchange/trd.9.1.specs.md` §Surface; INV-5).

  `Investex.Client` is a `GenServer` that owns the TLS `GRPC.Channel` and the
  resolved `Investex.Config`, and it attaches the per-RPC `authorization: "Bearer
  <token>"` and `x-app-name: <app_name>` metadata **in one place** (the Go
  `Client{conn, Config}` + the bearer/app-name dial, client.go:26-31,37-39,
  72-78). The per-service modules (`Investex.Users`, `Investex.Sandbox`) are
  stateless given a client handle: they read the channel and the request
  metadata from this process and never hold a connection themselves.

  investex is **lib-only** (no `mod:` in `mix.exs`) — so `:investex` boots no
  connection by merely being loaded. The **consumer's** supervision tree (or a
  test) starts the client with `start_link/1`; that is the only path that opens
  a socket. This keeps the master invariant from TRD.2.1 intact: the venue dial
  is an explicit, supervised act, not an app-start side effect.

  ## TLS posture

  `start_link/1` resolves the `Config` (lifting `INVEST_TOKEN` from the env,
  INV-9) and dials `config.endpoint` over TLS with `verify: :verify_peer` — the
  production-correct posture; the insecure no-verify mode appears nowhere
  (INV-11). The trust
  anchors are the OTP system trust store (`:public_key.cacerts_get/0`) **plus a
  vendored `Russian Trusted Root CA`** appended to it (INV-11): the venue's leaf
  chains leaf → `Russian Trusted Sub CA` → `Russian Trusted Root CA`, a
  self-signed root absent from every non-Russian host trust store (0 Russian
  roots on this machine), so a verify against the OS bundle alone is rejected.
  The root is vendored at `priv/certs/russian_trusted_root_ca.pem`, **pinned** by
  SHA-256 `D2:6D:…:CF:31` and fingerprint-matched before vendoring (never the
  server-served bytes blind); `tls_opts/0` reads it at runtime and appends its
  DER to the bundle, keeping `depth: 3` (so the existing chain build is
  leaf→sub→root). This is the BEAM-native equivalent of the Go SDK's empty
  `tls.Config{}` working only because a Russian host already trusts the root
  (client.go:72-78). The bearer token rides as per-RPC metadata (below), never
  in a log or the process name. The vendored PEM is a PUBLIC certificate, not a
  secret — it carries no token (INV-9 unaffected).
  """

  use GenServer

  alias Investex.Config

  @typedoc "A handle to a running client — a pid or a registered name."
  @type t :: GenServer.server()

  defmodule State do
    @moduledoc false
    # The held state: the dialed channel, the resolved config, and the
    # pre-built request metadata map (Bearer + x-app-name) so every RPC reads
    # one frozen header set (client.go:37-39,72-78).
    @enforce_keys [:channel, :config, :metadata]
    defstruct [:channel, :config, :metadata]
  end

  @doc """
  Starts the supervised client: resolves the config (env token, INV-9), dials
  the endpoint over TLS, and holds the channel + the per-RPC metadata. Accepts a
  `%Investex.Config{}` or a keyword/map of `Config.new/1` opts (plus an optional
  `:name` for a registered handle).

  Returns `{:ok, pid}` on a successful dial, `{:error, term}` if the dial fails.
  Started by the **consumer** or a test — never by `:investex` (lib-only, INV-5).
  """
  @spec start_link(Config.t() | keyword() | map()) :: GenServer.on_start()
  def start_link(%Config{} = config), do: GenServer.start_link(__MODULE__, config)

  def start_link(opts) when is_list(opts) or is_map(opts) do
    {name, opts} = pop_name(opts)
    config = Config.new(opts)
    GenServer.start_link(__MODULE__, config, name: name)
  end

  @doc """
  Returns the resolved `GRPC.Channel` the per-service functions call with
  (INV-5 — the channel lives in this one process).
  """
  @spec channel(t()) :: GRPC.Channel.t()
  def channel(client), do: GenServer.call(client, :channel)

  @doc """
  Returns the frozen per-RPC metadata map (`authorization` + `x-app-name`) the
  per-service functions attach to every call (client.go:37-39,72-78). The map is
  built once at dial; the bearer value is never logged or named.
  """
  @spec request_metadata(t()) :: %{String.t() => String.t()}
  def request_metadata(client), do: GenServer.call(client, :request_metadata)

  @doc """
  Closes the connection and stops the client (`Stop()` closes the conn,
  client.go:271-274).
  """
  @spec stop(t()) :: :ok
  def stop(client), do: GenServer.stop(client)

  # ── GenServer ──────────────────────────────────────────────────────────────

  @impl GenServer
  def init(%Config{} = config) do
    config = Config.resolve(config)

    case dial(config) do
      {:ok, channel} ->
        {:ok, %State{channel: channel, config: config, metadata: metadata(config)}}

      {:error, reason} ->
        {:stop, {:dial_failed, reason}}
    end
  end

  @impl GenServer
  def handle_call(:channel, _from, %State{channel: channel} = state) do
    {:reply, channel, state}
  end

  @impl GenServer
  def handle_call(:request_metadata, _from, %State{metadata: metadata} = state) do
    {:reply, metadata, state}
  end

  @impl GenServer
  def terminate(_reason, %State{channel: channel}) do
    # Close the conn on shutdown (client.go:271-274), cleanly and QUIETLY.
    #
    # `GRPC.Stub.disconnect/1` is NOT used (L-8): it is a `GenServer.call` into
    # the grpc connection process, whose 0.11.5 `handle_call({:disconnect,…})`
    # (connection.ex:258) pattern-matches every `real_channels` entry as
    # `{:ok, ch}` while a multi-address dial stores `{:error, _}` for any address
    # that did not connect (build_real_channels) — so it raises a
    # `FunctionClauseError` IN THE CONNECTION PROCESS and logs a full
    # `[error] GenServer … terminating` crash report. A `try/rescue` around the
    # caller cannot suppress a crash in the callee process; the prior fix masked
    # the test outcome, not the stderr flood.
    #
    # Instead: resolve the connection process (registered globally by its ref,
    # connection.ex:323) and terminate it through its DynamicSupervisor. A
    # supervised `:shutdown` runs the connection's own `terminate` (the gun
    # adapter closes the socket, gun.ex:83-86) with NO buggy disconnect
    # handle_call — the socket closes and nothing crashes. Best-effort: if the
    # process is already gone, there is nothing to do.
    close_connection(channel)
    :ok
  end

  # Dial the endpoint over TLS with verify_peer against the OTP system trust
  # store PLUS the vendored Russian Trusted Root CA (INV-11; client.go:72-78;
  # grpc.md endpoints). The endpoint is "host:443".
  #
  # PRECONDITION (L-6): grpc 0.11.x requires `GRPC.Client.Supervisor` (the
  # DynamicSupervisor that holds each connection process) to be RUNNING before
  # `GRPC.Stub.connect/2`, and the `:grpc` application does NOT start it. Because
  # investex is lib-only (no application supervision tree of its own), the
  # CONSUMER supervises `{GRPC.Client.Supervisor, []}` in its own tree (and the
  # suite starts it in `test/test_helper.exs`) — it must outlive any single
  # Client, so it is NOT started from `init` (that would link it to one
  # ephemeral client and tear it down with it). `ensure_grpc_supervisor/0`
  # raises a clear, token-free message if the precondition is unmet.
  defp dial(%Config{endpoint: endpoint}) do
    ensure_grpc_supervisor()
    cred = GRPC.Credential.new(ssl: tls_opts())
    GRPC.Stub.connect(endpoint, cred: cred)
  end

  # Fail fast with a clear, secret-free message if the consumer has not started
  # the grpc client supervisor (L-6). Better than the opaque connect-time raise.
  defp ensure_grpc_supervisor do
    if is_nil(Process.whereis(GRPC.Client.Supervisor)) do
      raise "GRPC.Client.Supervisor is not running — supervise {GRPC.Client.Supervisor, []} " <>
              "in the consumer tree before starting Investex.Client (investex is lib-only)."
    end
  end

  # Terminate the connection process cleanly through its DynamicSupervisor,
  # bypassing grpc 0.11.5's crashing `disconnect` handle_call (L-8). The
  # connection is registered globally by the channel ref (connection.ex:323);
  # resolve it and `terminate_child` so a supervised `:shutdown` closes the gun
  # socket with no crash report. Quiet and best-effort — a missing supervisor or
  # an already-dead connection is a no-op.
  defp close_connection(%GRPC.Channel{ref: ref}) when not is_nil(ref) do
    sup = Process.whereis(GRPC.Client.Supervisor)
    pid = :global.whereis_name({GRPC.Client.Connection, ref})

    if is_pid(sup) and is_pid(pid) do
      _ = DynamicSupervisor.terminate_child(sup, pid)
    end

    :ok
  end

  defp close_connection(_channel), do: :ok

  # The relative path of the vendored Russian Trusted Root CA under priv/ (INV-11).
  @russian_root_ca_rel "certs/russian_trusted_root_ca.pem"

  # verify_peer against the system CA bundle (:public_key.cacerts_get/0 — the
  # OTP-managed trust store) PLUS the vendored Russian Trusted Root CA appended
  # to it (INV-11), so the venue's leaf→sub→root chain verifies even though no
  # Russian root is in the OS bundle. depth: 3 builds leaf→sub→root; the
  # customize_hostname_check keeps hostname verification on the shared endpoint.
  # The insecure no-verify mode is NEVER used (INV-11).
  #
  # `@doc false`: VM-public so the G-TLS Tier-1 trust proof (client_test.exs) can
  # assert the vendored root's DER is in the `:cacerts` this builds — giving the
  # gate real teeth (dropping the `++` append turns G-TLS red). Excluded from the
  # docs; not part of the supported surface.
  @doc false
  @spec tls_opts() :: keyword()
  def tls_opts do
    [
      verify: :verify_peer,
      cacerts: :public_key.cacerts_get() ++ [russian_root_ca_der()],
      depth: 3,
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]
  end

  # Read the vendored Russian Trusted Root CA at runtime and return its DER
  # (INV-11). The PEM lives under the app's priv dir; :public_key.pem_decode
  # yields a single {:Certificate, der, :not_encrypted} entry (the file's comment
  # preamble is ignored by the PEM parser) and the bare DER binary is what `:ssl`
  # accepts in the `cacerts` list (alongside the OTP bundle's {:cert, der}
  # entries). Read once per dial — the dial is once per client, so re-reading on
  # each call is cheap and avoids any compile-time embedding of the bytes.
  defp russian_root_ca_der do
    pem =
      :code.priv_dir(:investex)
      |> Path.join(@russian_root_ca_rel)
      |> File.read!()

    [{:Certificate, der, :not_encrypted}] = :public_key.pem_decode(pem)
    der
  end

  # The frozen per-RPC metadata: Bearer + x-app-name (client.go:37-39,72-78).
  # Built once from the resolved config; the token VALUE lives only here, in the
  # held state, never in a log line or the process name (INV-9).
  defp metadata(%Config{token: token, app_name: app_name}) do
    %{"authorization" => "Bearer #{token}", "x-app-name" => app_name}
  end

  # Pull an optional :name for a registered handle out of the start opts.
  defp pop_name(opts) when is_list(opts), do: Keyword.pop(opts, :name)

  defp pop_name(opts) when is_map(opts) do
    {Map.get(opts, :name), Map.delete(opts, :name)}
  end
end
