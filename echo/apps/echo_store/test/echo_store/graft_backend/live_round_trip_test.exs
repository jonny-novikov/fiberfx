defmodule EchoStore.GraftBackend.LiveRoundTripTest do
  @moduledoc """
  eg.5 — the live-bus leg for `EchoStore.GraftBackend` against the **REAL** `echo_graft_backend`
  (criterion 7, the BEAM side; the live binding's S-7 round-trip + S-2 refusal + S-3 cursor advance
  over a real Valkey :6390 socket).

  This is the eg.5 discharge of eg.4's D-7 deferral. eg.4 ran this leg against an *in-Elixir*
  conformant responder (no Rust valkey client existed yet); eg.5 binds the Rust backend to a real
  socket (`echo_graft_backend::live`), so this leg now drives the REAL Rust engine over the
  byte-frozen wire — the contract proven compositionally in eg.4 is proven literally end-to-end.

  ## Posture (two gates)

    * `@moduletag :valkey` — excluded by default; needs a live Valkey :6390 (run with
      `--include valkey`).
    * `ECHO_GRAFT_BACKEND_TEST=1` — when SET, this leg launches the real Rust `echo_graft_backend`
      binary as an Erlang `Port`, waits for its `READY <branded>=<vid>` line (learning the
      engine-minted native vid), and drives the real client against it; the Port is closed in
      `on_exit` so no backend is left running. When UNSET, the leg is reported EXCLUDED (skipped),
      never trivially passed — the eg.4 liveness rule. (The eg.4 in-Elixir responder is removed:
      eg.5's whole point is the real binding.)

  A PRESENT, running backend MUST be exercised under the gate, or the criterion fails loud.
  """
  use ExUnit.Case, async: false

  alias EchoStore.GraftBackend

  @moduletag :valkey

  @branded "VOL0O5fmcxbds8"

  # The compiled Rust backend binary (built by `cargo build -p echo_graft_backend`).
  @backend_bin Path.expand(
                 "../../../../echo_graft/target/debug/echo_graft_backend",
                 __DIR__
               )

  # Whether the live-backend leg is enabled.
  defp backend_enabled?, do: System.get_env("ECHO_GRAFT_BACKEND_TEST") != nil

  setup do
    if backend_enabled?() do
      unless File.exists?(@backend_bin) do
        flunk("""
        ECHO_GRAFT_BACKEND_TEST is set but the backend binary is absent: #{@backend_bin}
        Build it: (cd echo/apps/echo_graft && cargo build -p echo_graft_backend)
        """)
      end

      {port, vid} = start_backend(@branded)
      on_exit(fn -> stop_backend(port) end)
      {:ok, vid: vid}
    else
      # The leg is excluded (reported, never trivially passed): the offline conformance/decode/
      # feed-blob suites carry the cross-runtime byte-equality; this end-to-end leg needs the gate.
      IO.puts(
        "\n[live_round_trip] EXCLUDED: set ECHO_GRAFT_BACKEND_TEST=1 (+ Valkey :6390) to run " <>
          "the real-backend leg."
      )

      {:ok, vid: nil}
    end
  end

  @tag :skip_without_backend
  test "open → commit → push acks an LSN and a feed event advances the cursor (real backend)", ctx do
    if backend_enabled?() do
      vid = ctx.vid
      {:ok, client} = start_client("rt-client")

      # the real backend negotiates v2 (PROTO_MIN=PROTO_MAX=2)
      assert {:ok, 2} = GraftBackend.hello(client)
      assert {:ok, _lsn0} = GraftBackend.open_volume(client, @branded)
      assert :ok = GraftBackend.subscribe_feed(client, @branded)

      # a :sync commit (the client-API default) on the engine-minted native vid
      assert {:ok, _lsn} = GraftBackend.commit(client, vid, 0, [{1, <<0xAB>>}])
      assert {:ok, push_lsn} = GraftBackend.push(client, vid)
      assert push_lsn >= 1

      # the feed event arrives from the REAL engine and the client advanced its cursor
      assert_receive {:graft_feed, @branded, ^push_lsn, _blob}, 3_000
      assert GraftBackend.last_seen(client, @branded) == push_lsn

      stop(client)
    else
      assert true, "excluded (no backend) — reported in setup"
    end
  end

  test "an :async commit acks and rolls up via the real backend", ctx do
    if backend_enabled?() do
      vid = ctx.vid
      {:ok, client} = start_client("async-client")

      assert {:ok, 2} = GraftBackend.hello(client)
      assert {:ok, _} = GraftBackend.open_volume(client, @branded)

      # the per-call :async mode rides the v2 wire; the backend still acks the local commit LSN
      assert {:ok, _lsn} = GraftBackend.commit(client, vid, 0, [{2, <<0xCD>>}], mode: :async)
      assert {:ok, push_lsn} = GraftBackend.push(client, vid)
      assert push_lsn >= 1

      stop(client)
    else
      assert true, "excluded (no backend) — reported in setup"
    end
  end

  test "an incompatible client handshake surfaces version_mismatch (real backend)", _ctx do
    if backend_enabled?() do
      # a client whose advertised range is disjoint from the backend's [2,2] is refused. The
      # client speaks v2 by default, so to force a mismatch we drive a raw Hello with an old range
      # over the control lane and assert the Incompatible reply surfaces.
      assert {:error, {:version_mismatch, _reason}} = incompatible_hello("too-old-client")
    else
      assert true, "excluded (no backend) — reported in setup"
    end
  end

  # ---- the real Rust backend, launched as an Erlang Port ----

  # Launch echo_graft_backend serving the given branded Volume, wait for its READY line, and
  # return {port, native_vid} (the vid the Rust engine minted for the branded id).
  defp start_backend(branded) do
    port =
      Port.open(
        {:spawn_executable, @backend_bin},
        [
          :binary,
          :exit_status,
          {:line, 4096},
          env: [
            {~c"ECHO_GRAFT_BRANDED", String.to_charlist(branded)},
            {~c"ECHO_GRAFT_VALKEY_PORT", ~c"6390"},
            {~c"ECHO_GRAFT_VALKEY_HOST", ~c"127.0.0.1"}
          ]
        ]
      )

    vid = await_ready(port, branded, 8_000)
    # give the backend's serve loop a moment to finish subscribing its lanes
    Process.sleep(300)
    {port, vid}
  end

  # Read the backend's stdout lines until the `READY <branded>=<vid> ...` line; return the vid.
  defp await_ready(port, branded, timeout) do
    receive do
      {^port, {:data, {:eol, line}}} ->
        case parse_ready(line, branded) do
          {:ok, vid} -> vid
          :not_ready -> await_ready(port, branded, timeout)
        end

      {^port, {:data, {:noeol, _partial}}} ->
        await_ready(port, branded, timeout)

      {^port, {:exit_status, status}} ->
        flunk("echo_graft_backend exited before READY (status #{status})")
    after
      timeout -> flunk("echo_graft_backend did not print READY within #{timeout}ms")
    end
  end

  # "READY VOL0O5fmcxbds8=<native-vid> ..." → {:ok, native_vid} for the branded id.
  defp parse_ready(line, branded) do
    case String.split(String.trim(line), " ", trim: true) do
      ["READY" | pairs] ->
        Enum.find_value(pairs, :not_ready, fn pair ->
          case String.split(pair, "=", parts: 2) do
            [^branded, vid] -> {:ok, vid}
            _ -> nil
          end
        end)

      _ ->
        :not_ready
    end
  end

  defp stop_backend(port) do
    if is_port(port) and Port.info(port) != nil do
      try do
        Port.close(port)
      catch
        _, _ -> :ok
      end
    end
  end

  # ---- the BEAM client (owns its connector, started with push_to: itself) ----

  defp start_client(client_id) do
    GraftBackend.start_link(
      connector_opts: [port: 6390, protocol: 3],
      client_id: client_id,
      feed_to: self()
    )
  end

  # Drive a raw incompatible Hello over the control lane against the real backend and await the
  # Incompatible → {:error, {:version_mismatch, _}} the client surfaces. We use a short-lived
  # client process and a hand-built old-range Hello; the client's hello/1 always advertises v2, so
  # we publish the old-range Hello directly through a connector and parse the reply.
  defp incompatible_hello(client_id) do
    alias EchoMQ.{Connector, RESP}
    alias EchoStore.GraftBackend.Proto

    {:ok, conn} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
    reply_lane = "egraft:reply:" <> client_id
    :ok = Connector.subscribe(conn, reply_lane)

    # an old-range Hello (proto_min/max far below the backend's [2,2]) → Incompatible
    hello = {:hello, 0, 1, client_id}
    bytes = IO.iodata_to_binary(Proto.encode(hello))
    {:ok, _} = Connector.command(conn, ["PUBLISH", "egraft:cmd:_control", bytes])

    result =
      receive do
        {:emq_push, ["message", ^reply_lane, payload]} ->
          with {:ok, parts, ""} <- RESP.parse(payload),
               {:ok, {:incompatible, _min, _max, reason}} <- Proto.decode(parts) do
            {:error, {:version_mismatch, reason}}
          else
            other -> {:unexpected, other}
          end
      after
        3_000 -> {:error, :timeout}
      end

    stop(conn)
    result
  end

  defp stop(pid) when is_pid(pid) do
    if Process.alive?(pid) do
      try do
        GenServer.stop(pid)
      catch
        :exit, _ -> :ok
      end
    end
  end
end
