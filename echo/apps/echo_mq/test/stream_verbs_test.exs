defmodule EchoMQ.StreamVerbsTest do
  @moduledoc """
  emq3.1 -- S1 the writer, part 1: the stream-verb floor. The five stream verbs
  (XADD / XRANGE / XREADGROUP / XACK / XAUTOCLAIM) round-trip on the CERTIFIED
  connector, a pipelined XADD batch returns its ids in call order, and the
  in-band verbs do not disturb the out-of-band push routing under RESP3 -- the
  floor every later Stream rung (the writer law emq3.2, the readers emq3.3,
  retention emq3.4) stands on.

  The verbs ride the SHIPPED generic command path (FORK 3.1-A): each is a `parts`
  list through `EchoMQ.Connector.command/3` / `pipeline/3` -- the connector is
  ALREADY a generic RESP client (`EchoMQ.RESP.encode/1` is verb-agnostic, no
  whitelist), so the stream verbs reach the wire with NO connector edit. NO new
  module surface (that is emq3.2's `EchoMQ.Stream`); NO new `Script.new/2` (the
  verbs are issued direct, not via Lua). The stream key is the braced
  `emq:{q}:stream:<name>` built by the total `Keyspace.queue_key(q, "stream:" <>
  name)` -- a NEW Section 6 key type on the queue's hashtag slot, no grammar edit.

  The branded record id is emq3.2's writer law -- emq3.1 appends with the server
  `*` id (sufficient to prove the plumbing). Push-safety scopes to NON-blocking
  round-trips (FORK 3.1-D): NO XREADGROUP BLOCK -- the blocking consumer-group
  read holds the single-owner socket and lands at emq3.3 with the readers'
  blocking-read design.

  `:valkey`-tagged (a live RESP3 connection on 6390 + pub/sub). The proof mints
  NO branded id in the verb path (the append uses the server `*` id) and starts
  NO process -- the determinism posture is a multi-seed sweep, NOT the >=100 loop.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoMQ.{Connector, Events, Keyspace}

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    queue = "emq31.sv#{System.unique_integer([:positive])}"

    # the purge rides its OWN disposable connection (the events_integration idiom):
    # a connector under test can race teardown, so a purge bound to `conn` would
    # `catch :exit` and SILENTLY skip the DEL, leaking keys onto a queue name a
    # later VM run reuses. The stream key emq:{q}:stream:<name> shares the {q}
    # hashtag, so the per-queue purge (KEYS emq:{q}:*) sweeps it too.
    on_exit(fn ->
      stop_conn(conn)
      purge(queue)
    end)

    %{conn: conn, queue: queue}
  end

  defp stop_conn(conn) do
    try do
      GenServer.stop(conn)
    catch
      :exit, _ -> :ok
    end
  end

  defp purge(queue) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> queue <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    stop_conn(conn)
  end

  # the braced stream key the rung founds: emq:{q}:stream:<name> via the total
  # Keyspace.queue_key/2 -- a NEW Section 6 type on the queue's hashtag slot.
  defp stream_key(queue, name), do: Keyspace.queue_key(queue, "stream:" <> name)

  describe "US1 -- the five stream verbs round-trip on the certified connector" do
    test "XADD then XRANGE reads back the EXACT appended entry (a positive round-trip)", ctx do
      %{conn: conn, queue: queue} = ctx
      key = stream_key(queue, "s")

      # XADD answers a bulk entry-id string (the appended entry's id)
      assert {:ok, id} = Connector.command(conn, ["XADD", key, "*", "field", "value"])
      assert is_binary(id)
      # an XADD id is "<ms>-<seq>" -- positively the server-minted form
      assert id =~ ~r/^\d+-\d+$/

      # XRANGE - + reads back the EXACT [id, [field, value]] entry (a nested array)
      assert {:ok, [[^id, ["field", "value"]]]} =
               Connector.command(conn, ["XRANGE", key, "-", "+"])
    end

    test "XGROUP CREATE + XREADGROUP (no BLOCK) + XACK + XAUTOCLAIM round-trip positively", ctx do
      %{conn: conn, queue: queue} = ctx
      key = stream_key(queue, "g")

      # append a known entry, then create a group reading from the start
      assert {:ok, id} = Connector.command(conn, ["XADD", key, "*", "k", "v"])
      assert {:ok, "OK"} = Connector.command(conn, ["XGROUP", "CREATE", key, "grp", "0"])

      # XREADGROUP GROUP grp c1 COUNT 10 STREAMS key > (NO BLOCK) -- returns the
      # group's unseen entries for consumer c1; the entry is now pending against c1
      assert {:ok, read} =
               Connector.command(conn, [
                 "XREADGROUP",
                 "GROUP",
                 "grp",
                 "c1",
                 "COUNT",
                 "10",
                 "STREAMS",
                 key,
                 ">"
               ])

      # the reply carries the appended entry under the stream key (RESP3 maps the
      # stream->entries; RESP2 nests it as an array) -- assert the exact entry by id
      assert read_entry_id(read, key) == id

      # XACK acknowledges the genuinely-pending entry -> the integer count 1
      assert {:ok, 1} = Connector.command(conn, ["XACK", key, "grp", id])

      # a fresh entry, read by c1 (pending again), then XAUTOCLAIM re-claims it to
      # c2 with min-idle-time 0 -> the [next-cursor, claimed-entries, deleted-ids]
      # triple; the claimed entry is positively the one c1 left pending
      assert {:ok, id2} = Connector.command(conn, ["XADD", key, "*", "k2", "v2"])

      assert {:ok, _} =
               Connector.command(conn, [
                 "XREADGROUP",
                 "GROUP",
                 "grp",
                 "c1",
                 "COUNT",
                 "10",
                 "STREAMS",
                 key,
                 ">"
               ])

      assert {:ok, [_cursor, claimed, _deleted]} =
               Connector.command(conn, ["XAUTOCLAIM", key, "grp", "c2", "0", "0"])

      # the claimed-entries list carries id2 re-assigned to c2 (a positive re-claim)
      assert Enum.any?(claimed, fn [cid | _] -> cid == id2 end)
    end
  end

  describe "US2 -- the pipelined XADD batch (N entries, replies in call order)" do
    test "N appends in one pipeline return N ids in call order, read back in mint order", ctx do
      %{conn: conn, queue: queue} = ctx
      key = stream_key(queue, "batch")
      n = 4

      cmds = for i <- 1..n, do: ["XADD", key, "*", "seq", "v#{i}"]

      # the pipelined batch rides the shipped Connector.pipeline/3 -- the connector
      # is the SOLE owner of the wire (exec/1 on an EchoWire.Pipe is one
      # pipeline/3 call; no second pipelining mechanism)
      assert {:ok, ids} = Connector.pipeline(conn, cmds)
      assert length(ids) == n
      assert Enum.all?(ids, &is_binary/1)

      # XRANGE reads back exactly N entries in mint order; the server * ids are
      # monotonic, so the read-back order is the call order
      assert {:ok, entries} = Connector.command(conn, ["XRANGE", key, "-", "+"])
      assert length(entries) == n
      read_ids = for [eid | _] <- entries, do: eid
      assert read_ids == ids
      # and the payloads are in call order (v1..vN) -- a positive ordering proof
      read_vals = for [_eid, ["seq", v]] <- entries, do: v
      assert read_vals == for(i <- 1..n, do: "v#{i}")
    end
  end

  describe "US3 -- push-safety: in-band stream verbs do not disturb the out-of-band push routing" do
    test "in-band XADD/XRANGE/XACK round-trip while a concurrent push is delivered out of band", ctx do
      %{queue: queue} = ctx
      key = stream_key(queue, "ps")
      # the EchoMQ.Events pub/sub seam channel -- push frames arrive out of band
      # as {:emq_push, ["message", chan, payload]}, never on the reply FIFO
      chan = Events.channel(queue)

      # a RESP3 connection, subscribed to the channel and pushing to this process
      {:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
      :ok = Connector.subscribe(sub, chan)
      # let the SUBSCRIBE land before the publish (no lost-wakeup race) -- the
      # :events scenario idiom
      Process.sleep(50)

      # a SECOND connection is the publisher (the subscriber's wire must not carry
      # the publish in band)
      {:ok, pub} = Connector.start_link(port: 6390)

      verdict =
        try do
          # in-band XADD on the SUBSCRIBED connection (its reply rides the FIFO)
          assert {:ok, id} = Connector.command(sub, ["XADD", key, "*", "f", "v"])
          assert id =~ ~r/^\d+-\d+$/

          # a concurrent push on the channel -- delivered out of band
          assert {:ok, 1} = Connector.command(pub, ["PUBLISH", chan, "ping"])

          # in-band XRANGE on the SAME subscribed connection -- the reply is the
          # appended entry, the FIFO stays aligned (the push did not corrupt it)
          assert {:ok, [[^id, ["f", "v"]]]} =
                   Connector.command(sub, ["XRANGE", key, "-", "+"])

          # in-band XACK round-trips too (a group ack -- the third in-band verb).
          # XGROUP CREATE is non-blocking setup; XREADGROUP carries NO BLOCK arg.
          assert {:ok, "OK"} = Connector.command(sub, ["XGROUP", "CREATE", key, "g", "0"])

          assert {:ok, _} =
                   Connector.command(sub, [
                     "XREADGROUP",
                     "GROUP",
                     "g",
                     "c",
                     "STREAMS",
                     key,
                     ">"
                   ])

          assert {:ok, 1} = Connector.command(sub, ["XACK", key, "g", id])

          # the concurrent push WAS delivered out of band (the load-bearing
          # assertion -- a push-safety proof with no concurrent push proves nothing)
          assert_receive {:emq_push, ["message", ^chan, "ping"]}, 1_000
          :ok
        after
          stop_conn(sub)
          stop_conn(pub)
        end

      assert verdict == :ok
    end
  end

  # Pull the entry id from an XREADGROUP reply for `key`, tolerant of the RESP3
  # map shape (%{key => [[id, fields], ...]}) and the RESP2 nested-array shape
  # ([[key, [[id, fields], ...]]]) -- the connection-dependent stream->entries
  # form. Returns the first entry's id, or nil if the stream is absent/empty.
  defp read_entry_id(reply, key) when is_map(reply) do
    case Map.get(reply, key) do
      [[id | _] | _] -> id
      _ -> nil
    end
  end

  defp read_entry_id(reply, key) when is_list(reply) do
    case List.keyfind(reply, key, 0) do
      {^key, [[id | _] | _]} -> id
      _ -> nil
    end
  end

  defp read_entry_id(_reply, _key), do: nil
end
