defmodule EchoStore.GraftBackend.LiveRoundTripTest do
  @moduledoc """
  eg.4 Step 7 — the live-bus leg for `EchoStore.GraftBackend` (criterion 1, BEAM side; the
  S-3 cursor advance + S-2 refusal over the real bus).

  This proves the BEAM client's bus mechanics end-to-end over a **real Valkey :6390**: it
  publishes requests on the command/control lanes, correlates replies on its own reply lane,
  subscribes to the feed lane, and advances its last-seen-LSN cursor — all over live pub/sub.

  The Rust `echo_graft_backend` speaks an abstract transport and is proven in-Rust (the
  `round_trip` integration test); it is not bus-bound in eg.4 (no Rust valkey client, no NIF).
  So the responder here is a small in-Elixir stand-in that decodes each request with the SAME
  byte-frozen `Proto` and replies on the wire — the cross-runtime wire equality is what the
  conformance suite already pins. This leg validates the COMPLEMENT: the client's live bus
  round-trip.

  Gated by the `:valkey` tag (excluded by default; run with `mix test --include valkey`),
  mirroring eg.2's live-leg posture — the offline conformance + decode + feed-blob legs always
  run; this end-to-end bus leg runs only when a live Valkey is present. An excluded test does
  NOT run (it is reported excluded) — never a trivially-passing stub.
  """
  use ExUnit.Case, async: false

  alias EchoMQ.{Connector, RESP}
  alias EchoStore.GraftBackend
  alias EchoStore.GraftBackend.Proto

  @moduletag :valkey

  @branded "VOL0O5fmcxbds8"
  @vid "3QJmnh7Yx2Kp9Wd5Lr8Tz4B"

  setup do
    {:ok, responder, responder_conn} = start_responder()

    on_exit(fn ->
      stop(responder)
      stop(responder_conn)
    end)

    :ok
  end

  test "open → commit → push acks an LSN and a feed event advances the cursor" do
    {:ok, client} = start_client("rt-client")

    assert {:ok, 1} = GraftBackend.hello(client)
    assert {:ok, _lsn0} = GraftBackend.open_volume(client, @branded)
    assert :ok = GraftBackend.subscribe_feed(client, @branded)

    assert {:ok, _lsn} = GraftBackend.commit(client, @vid, 0, [{1, <<0xAB>>}])
    assert {:ok, push_lsn} = GraftBackend.push(client, @vid)
    assert push_lsn >= 1

    # the feed event arrives and the client advanced its cursor to the pushed LSN
    assert_receive {:graft_feed, @branded, ^push_lsn, _blob}, 2_000
    assert GraftBackend.last_seen(client, @branded) == push_lsn

    stop(client)
  end

  test "an incompatible client handshake surfaces version_mismatch to the caller" do
    # the responder refuses the reserved id "bad-version-client" with Incompatible
    {:ok, bad} = start_client("bad-version-client")

    assert {:error, {:version_mismatch, _reason}} = GraftBackend.hello(bad)

    stop(bad)
  end

  # ---- client wiring (the client owns its connector, started with push_to: itself) ----

  defp start_client(client_id) do
    GraftBackend.start_link(
      connector_opts: [port: 6390, protocol: 3],
      client_id: client_id,
      feed_to: self()
    )
  end

  # ---- the in-Elixir conformant responder (a stand-in for echo_graft_backend over the bus) ----

  defp start_responder do
    parent = self()

    pid =
      spawn_link(fn ->
        {:ok, conn} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
        :ok = Connector.subscribe(conn, "egraft:cmd:_control")
        :ok = Connector.subscribe(conn, "egraft:cmd:" <> @vid)
        send(parent, {:responder_ready, conn})
        responder_loop(conn, %{lsn: 0, reply_lanes: %{}})
      end)

    receive do
      {:responder_ready, conn} -> {:ok, pid, conn}
    after
      2_000 -> {:error, :responder_timeout}
    end
  end

  defp responder_loop(conn, st) do
    receive do
      {:emq_push, ["message", _channel, payload]} ->
        responder_loop(conn, handle_request(conn, payload, st))

      {:emq_push, _other} ->
        responder_loop(conn, st)

      :stop ->
        :ok
    end
  end

  defp handle_request(conn, payload, st) do
    with {:ok, parts, ""} <- RESP.parse(payload),
         {:ok, msg} <- Proto.decode(parts) do
      dispatch_model(conn, msg, st)
    else
      _ -> st
    end
  end

  # The handshake carries the client id; record its reply lane + reply Welcome/Incompatible.
  defp dispatch_model(conn, {:hello, _min, _max, client_id}, st) do
    reply_lane = "egraft:reply:" <> client_id

    reply =
      if client_id == "bad-version-client",
        do: {:incompatible, Proto.proto_min(), Proto.proto_max(), "no overlapping protocol version"},
        else: {:welcome, 1}

    publish(conn, reply_lane, reply)
    %{st | reply_lanes: Map.put(st.reply_lanes, :last, reply_lane)}
  end

  defp dispatch_model(conn, {:open_volume, corr, _branded, _l, _r}, st) do
    publish(conn, last_lane(st), {:ack, corr, st.lsn})
    st
  end

  defp dispatch_model(conn, {:commit, corr, _vid, _base, _pages}, st) do
    lsn = st.lsn + 1
    publish(conn, last_lane(st), {:ack, corr, lsn})
    %{st | lsn: lsn}
  end

  defp dispatch_model(conn, {:push, corr, _vid}, st) do
    publish(conn, last_lane(st), {:ack, corr, st.lsn})
    # publish a feed event for the pushed LSN (an opaque eg.3-shaped FeedEvent blob)
    publish(conn, "egraft:feed:" <> @branded, {:feed, feed_blob(@branded, st.lsn)})
    st
  end

  defp dispatch_model(_conn, _other, st), do: st

  defp last_lane(st), do: Map.get(st.reply_lanes, :last)

  defp publish(conn, lane, msg) do
    bytes = IO.iodata_to_binary(Proto.encode(msg))
    Connector.command(conn, ["PUBLISH", lane, bytes])
  end

  # A bilrost FeedEvent blob carrying field 1 (branded) + field 3 (lsn) — the two the client
  # reads for its cursor (log_id/ts are not needed by the cursor; the client forwards the blob
  # opaque). field 1 key = (1<<2)|1 = 0x05 (len-delimited); field 3 key = (2<<2)|0 = 0x08
  # (varint, delta 2 advances the running field 1→3).
  defp feed_blob(branded, lsn) do
    <<0x05, byte_size(branded)>> <> branded <> <<0x08>> <> leb(lsn)
  end

  defp leb(n) when n < 0x80, do: <<n>>
  defp leb(n), do: <<Bitwise.bor(Bitwise.band(n, 0x7F), 0x80)>> <> leb(Bitwise.bsr(n, 7))

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
