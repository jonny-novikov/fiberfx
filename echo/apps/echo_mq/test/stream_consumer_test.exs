defmodule EchoMQ.StreamConsumerTest do
  @moduledoc """
  emq3.3 -- S2 the readers, part 1: the reader LAW (EchoMQ.StreamConsumer), the
  BEAM consumer group + the polyglot seam. The `:valkey` proof of the at-least-once
  grouped-delivery contract: a group drains every entry at least once
  (US1/INV1); a crash re-delivers via drain-PEL-first (SELF, US2/INV2) or the
  XAUTOCLAIM beat (a dead PEER, US2/INV2); the handler is the exact
  %{id, payload, attempts, group} mirror with `attempts` the XPENDING
  delivery-count (US3/INV3); the lazy-ensure group door swallows only BUSYGROUP,
  is LOUD on WRONGTYPE, raises on a missing :group_start, and ships no
  destructive verb (US5/INV4); the stored "id" field is the canonical receipt a
  raw connector recovers (US4/INV5); and a re-claimed entry is delivered OUT of
  mint order -- the order-theorem PEL exception EXERCISED, not asserted in prose
  (US6/INV6).

  Determinism posture (the load-bearing difference from emq3.2): a NEW SUPERVISED
  PROCESS (a `spawn_link` loop holding a private blocking lane + a lease-like PEL
  recovery) AND a branded-id mint path the proofs drive -> the >=100 determinism
  loop is MANDATORY (a same-millisecond mint collision or a process-timing race
  flakes only across runs). The crash points are DETERMINISTIC (a {:error, _}
  verdict leaves an entry un-acked; a Process.exit/:kill of the loop holding
  un-acked entries) -- no real-time sleep gates a verdict.

  `:valkey`-tagged (a live RESP3 connection on 6390). Each test runs on its own
  per-queue sub-namespace and purges what it mints (the stream key
  emq:{q}:stream:<name> shares the {q} hashtag, so the per-queue KEYS sweep
  catches it).
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoMQ.{Connector, Stream, StreamConsumer}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq33.sc#{System.unique_integer([:positive])}"

    # the purge rides its own disposable connection (a connector under test can
    # race teardown). The stream key emq:{q}:stream:<name> shares the {q} hashtag,
    # so the per-queue KEYS sweep deletes it + its server-side group state.
    on_exit(fn -> purge(q) end)

    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  defp wait_until(pred, tries \\ 600) do
    cond do
      pred.() -> :ok
      tries == 0 -> flunk("condition never held")
      true ->
        Process.sleep(5)
        wait_until(pred, tries - 1)
    end
  end

  # the count of entries still pending for the group (the PEL size).
  defp pel_size(conn, key, group) do
    case Connector.command(conn, ["XPENDING", key, group]) do
      {:ok, [n | _]} -> n
      _ -> 0
    end
  end

  describe "US1/INV1 -- a group delivers every entry at least once; a crash re-delivers" do
    test "every appended entry is delivered >= 1 and the :ok entries retire from the PEL", %{conn: conn, q: q} do
      parent = self()
      key = Stream.stream_key(q, "s")

      receipts = for i <- 1..5, do: ok!(Stream.append(conn, q, "s", [{"seq", "v#{i}"}]))

      handler = fn job ->
        send(parent, {:handled, job.id})
        :ok
      end

      {:ok, c} =
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "c1",
          group_start: :head,
          handler: handler,
          conn: own_lane(),
          beat_ms: 50,
          min_idle_ms: 30_000
        )

      # every appended entry is delivered to the handler at least once
      for r <- receipts, do: assert_receive({:handled, ^r}, 3_000)

      # all acked -> the PEL drains to empty
      wait_until(fn -> pel_size(conn, key, "grp") == 0 end)

      assert :ok = StreamConsumer.stop(c)
    end

    test "an {:error, _} entry is LEFT un-acked and re-delivered (at-least-once, no vacuous ack-everything)", %{conn: conn, q: q} do
      parent = self()

      poison = ok!(Stream.append(conn, q, "s", [{"seq", "poison"}]))
      good = ok!(Stream.append(conn, q, "s", [{"seq", "good"}]))

      # the poison entry returns {:error, _} (left un-acked); the good entry :ok.
      # min_idle_ms 0 so the XAUTOCLAIM beat re-delivers the un-acked poison to
      # the SAME consumer (a re-claim) -- a positive re-delivery proof.
      handler = fn job ->
        send(parent, {:handled, job.id, job.attempts})
        if job.id == poison, do: ({:error, :left_unacked}), else: :ok
      end

      {:ok, c} =
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "c1",
          group_start: :head,
          handler: handler,
          conn: own_lane(),
          beat_ms: 30,
          min_idle_ms: 0
        )

      # the good entry retires; the poison is re-delivered (the SAME branded id,
      # never an ack-everything no-op) with a higher attempts (the delivery-count)
      assert_receive {:handled, ^good, _}, 3_000
      assert_receive {:handled, ^poison, 1}, 3_000
      assert_receive {:handled, ^poison, attempts2}, 3_000
      assert attempts2 >= 2

      assert :ok = StreamConsumer.stop(c)
    end
  end

  describe "US2/INV2 -- drain-PEL-first recovers SELF; the XAUTOCLAIM beat recovers a dead PEER" do
    test "a killed consumer restarts and handles its OWN un-acked backlog FIRST, before a new tail entry", %{conn: conn, q: q} do
      parent = self()
      key = Stream.stream_key(q, "s")

      # three entries appended; the FIRST consumer instance reads them, leaves
      # them un-acked (an {:error, _} verdict), then is killed -- they sit in c1's
      # PEL. min_idle_ms huge so NO XAUTOCLAIM masks the PEL-drain under test.
      backlog = for i <- 1..3, do: ok!(Stream.append(conn, q, "s", [{"seq", "b#{i}"}]))

      first_handler = fn job ->
        send(parent, {:first, job.id})
        {:error, :leave_unacked}
      end

      {:ok, c1} =
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "c1",
          group_start: :head,
          handler: first_handler,
          conn: own_lane(),
          beat_ms: 1_000,
          min_idle_ms: 600_000
        )

      # the first instance read all three (left un-acked) -> they are in c1's PEL
      for b <- backlog, do: assert_receive({:first, ^b}, 3_000)
      wait_until(fn -> pel_size(conn, key, "grp") == 3 end)

      # kill the loop holding the un-acked entries (a crash, not a clean stop).
      # unlink first so the :kill does not propagate to the test process (the
      # consumer is spawn_link'd to its starter -- a real crash under a
      # supervisor would not take the test down).
      Process.unlink(c1)
      Process.exit(c1, :kill)
      wait_until(fn -> not Process.alive?(c1) end)

      # append a NEW tail entry AFTER the crash -- it must NOT be handled before
      # the recovered backlog (the drain-PEL-first guarantee).
      tail = ok!(Stream.append(conn, q, "s", [{"seq", "tail"}]))

      # restart with the SAME consumer name "c1" -- its first deliveries must be
      # its OWN prior un-acked backlog (recovered via the `0` PEL-drain), in
      # order, BEFORE the new tail.
      second_handler = fn job ->
        send(parent, {:second, job.id})
        :ok
      end

      {:ok, c2} =
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "c1",
          group_start: :head,
          handler: second_handler,
          conn: own_lane(),
          beat_ms: 50,
          min_idle_ms: 600_000
        )

      # the FIRST entries the restarted consumer handles are its OWN backlog (by
      # branded id), recovered BEFORE the new tail -- the PEL-drain is structural.
      recovered = for _ <- backlog, do: assert_receive_second()
      assert recovered == backlog
      assert_receive {:second, ^tail}, 3_000

      assert :ok = StreamConsumer.stop(c2)
    end

    test "the XAUTOCLAIM beat recovers a DEAD PEER's idle backlog (not this consumer's PEL-drain)", %{conn: conn, q: q} do
      parent = self()
      key = Stream.stream_key(q, "s")

      # a dead PEER "dead" reads two entries via a RAW XREADGROUP (so they sit in
      # dead's PEL) and never acks them -- dead never restarts, so its PEL is
      # never self-drained. The live consumer "rescuer" must reclaim them via the
      # XAUTOCLAIM beat (min_idle_ms 0 -> reclaim immediately).
      orphan_a = ok!(Stream.append(conn, q, "s", [{"seq", "orphan_a"}]))
      orphan_b = ok!(Stream.append(conn, q, "s", [{"seq", "orphan_b"}]))

      {:ok, "OK"} = Connector.command(conn, ["XGROUP", "CREATE", key, "grp", "0"])
      # the dead peer reads both (they enter dead's PEL), then "dies" (no restart)
      {:ok, _} = Connector.command(conn, ["XREADGROUP", "GROUP", "grp", "dead", "COUNT", "10", "STREAMS", key, ">"])
      wait_until(fn -> pel_size(conn, key, "grp") == 2 end)

      handler = fn job ->
        send(parent, {:rescued, job.id})
        :ok
      end

      {:ok, rescuer} =
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "rescuer",
          # the group already exists (BUSYGROUP swallowed); :head is moot here
          group_start: :head,
          handler: handler,
          conn: own_lane(),
          beat_ms: 30,
          min_idle_ms: 0
        )

      # the rescuer reclaims the dead peer's orphaned entries via the XAUTOCLAIM
      # beat -- a re-delivery the rescuer's OWN PEL-drain could never do (the
      # orphans were never in the rescuer's PEL)
      assert_receive {:rescued, ^orphan_a}, 3_000
      assert_receive {:rescued, ^orphan_b}, 3_000
      wait_until(fn -> pel_size(conn, key, "grp") == 0 end)

      assert :ok = StreamConsumer.stop(rescuer)
    end
  end

  describe "US3/INV3 -- the exact-mirror handler + the attempts <-> XPENDING delivery-count mapping" do
    test "the handler map has exactly {id, payload, attempts, group}; attempts is the delivery-count", %{conn: conn, q: q} do
      parent = self()

      r = ok!(Stream.append(conn, q, "s", [{"seq", "v"}, {"extra", "x"}]))

      # leave the entry un-acked the first time so it is re-delivered (attempts 2)
      handler = fn job ->
        send(parent, {:job, job})
        if job.attempts == 1, do: {:error, :once}, else: :ok
      end

      {:ok, c} =
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "c1",
          group_start: :head,
          handler: handler,
          conn: own_lane(),
          beat_ms: 30,
          min_idle_ms: 0
        )

      # first delivery: the exact key set, attempts 1, the branded id + payload map
      assert_receive {:job, first}, 3_000
      assert Map.keys(first) |> Enum.sort() == [:attempts, :group, :id, :payload]
      assert first.id == r
      assert first.group == "grp"
      assert first.payload == %{"seq" => "v", "extra" => "x"}
      assert first.attempts == 1

      # re-delivery: attempts == 2 (the XPENDING delivery-count, NOT a failure count)
      assert_receive {:job, second}, 3_000
      assert second.id == r
      assert second.attempts == 2

      assert :ok = StreamConsumer.stop(c)
    end

    test "a raising handler converts to a leave-un-acked and the loop SURVIVES", %{conn: conn, q: q} do
      parent = self()

      r = ok!(Stream.append(conn, q, "s", [{"seq", "boom"}]))
      good = ok!(Stream.append(conn, q, "s", [{"seq", "ok"}]))

      handler = fn job ->
        send(parent, {:saw, job.id, job.attempts})
        cond do
          job.id == r and job.attempts == 1 -> raise "boom"
          true -> :ok
        end
      end

      {:ok, c} =
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "c1",
          group_start: :head,
          handler: handler,
          conn: own_lane(),
          beat_ms: 30,
          min_idle_ms: 0
        )

      # the raise on attempt 1 did NOT crash the loop: the good entry settles AND
      # the raised entry is re-delivered (left un-acked) and then completes
      assert_receive {:saw, ^r, 1}, 3_000
      assert_receive {:saw, ^good, _}, 3_000
      assert_receive {:saw, ^r, two}, 3_000
      assert two >= 2
      assert Process.alive?(c)

      assert :ok = StreamConsumer.stop(c)
    end
  end

  describe "US5/INV4 -- the lazy-ensure group door" do
    test "a fresh group is created on first start (MKSTREAM); a second start is a no-op (BUSYGROUP swallowed)", %{conn: conn, q: q} do
      key = Stream.stream_key(q, "s")
      # the stream key does not exist yet -- MKSTREAM covers the empty stream
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", key])

      {:ok, c1} = start_noop(q, "s", "grp", "c1")
      # the start_link spawns the loop async; wait for ensure_group! to run --
      # the group now exists (and MKSTREAM created the stream)
      wait_until(fn -> Connector.command(conn, ["EXISTS", key]) == {:ok, 1} end)
      assert {:ok, groups} = Connector.command(conn, ["XINFO", "GROUPS", key])
      assert length(groups) == 1

      # a SECOND consumer on the same group starts fine (BUSYGROUP swallowed)
      {:ok, c2} = start_noop(q, "s", "grp", "c2")
      assert Process.alive?(c2)

      assert :ok = StreamConsumer.stop(c1)
      assert :ok = StreamConsumer.stop(c2)
    end

    test "a start against a key holding a NON-stream type fails LOUD (WRONGTYPE not swallowed)", %{conn: conn, q: q} do
      key = Stream.stream_key(q, "s")
      # plant a STRING at the stream key -> XGROUP CREATE answers WRONGTYPE
      {:ok, "OK"} = Connector.command(conn, ["SET", key, "not-a-stream"])

      # start_link spawns the loop; the door raise crashes it. Trap exits so the
      # linked crash arrives as a message, not a test-process kill.
      Process.flag(:trap_exit, true)
      {:ok, pid} = start_noop(q, "s", "grp", "c1")
      assert_receive {:EXIT, ^pid, reason}, 3_000
      refute reason == :normal
      Process.flag(:trap_exit, false)
    end

    test "start_link with no :group_start raises; a malformed value raises", %{q: q} do
      assert_raise KeyError, fn ->
        StreamConsumer.start_link(queue: q, stream: "s", group: "grp", consumer: "c1", handler: fn _ -> :ok end, conn: own_lane())
      end

      assert_raise ArgumentError, fn ->
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "c1",
          group_start: :bogus,
          handler: fn _ -> :ok end,
          conn: own_lane()
        )
      end
    end

    test "no destructive group-tear-down verb exists in lib/ (the INV4 grep == 0)", _ctx do
      # the brief's literal check: grep -rE "XGROUP.*DESTROY|group_destroy" lib/ == 0
      # (zero matching lines). grep exit 1 == no matches; 0 == a match (a failure).
      {out, status} =
        System.cmd("grep", ["-rE", "XGROUP.*DESTROY|group_destroy", "lib/"], stderr_to_stdout: true)

      matched_lines = out |> String.split("\n", trim: true) |> length()
      assert matched_lines == 0, "destructive verb token found in lib/:\n#{out}"
      assert status == 1
    end
  end

  describe "US4/INV5 -- the polyglot seam (the stored id field is the canonical receipt a stock client redeems)" do
    test "a raw-connector XREADGROUP recovers the EXACT branded receipt; a raw XACK settles the same group state", %{conn: conn, q: q} do
      key = Stream.stream_key(q, "s")

      # append via the BEAM writer, capturing the branded receipt R
      r = ok!(Stream.append(conn, q, "s", [{"k", "v"}]))

      # a NON-BEAM read: raw XGROUP CREATE + raw XREADGROUP through the bare
      # Connector (no Stream/StreamConsumer helpers) -- a stock Redis client
      {:ok, "OK"} = Connector.command(conn, ["XGROUP", "CREATE", key, "grp", "0"])
      {:ok, reply} = Connector.command(conn, ["XREADGROUP", "GROUP", "grp", "polyglot", "COUNT", "10", "STREAMS", key, ">"])

      [xadd_id, fields] = first_entry(reply, key)
      # the stored "id" field equals the branded receipt R -- the canonical id a
      # non-BEAM client recovers from a stock read (no re-encoding)
      assert field_value(fields, "id") == r

      # a raw XACK through the bare Connector settles the entry against the SAME
      # group state -> the PEL drains (the BEAM and non-BEAM sides share one group)
      assert {:ok, 1} = Connector.command(conn, ["XACK", key, "grp", xadd_id])
      assert pel_size(conn, key, "grp") == 0
    end
  end

  describe "US6/INV6 -- the order-theorem PEL exception (a re-claim is delivered OUT of mint order)" do
    test "a re-claimed entry's branded id is LOWER than entries already delivered to the same consumer", %{conn: conn, q: q} do
      parent = self()

      # the FIRST (oldest, lowest-id) entry is the one we leave un-acked then
      # re-claim AFTER a newer entry has already been delivered -- so its
      # *delivery* arrives out of *mint* order.
      e1 = ok!(Stream.append(conn, q, "s", [{"seq", "1"}]))
      e2 = ok!(Stream.append(conn, q, "s", [{"seq", "2"}]))
      e3 = ok!(Stream.append(conn, q, "s", [{"seq", "3"}]))
      assert e1 < e2 and e2 < e3

      # e1 returns {:error, _} on its FIRST delivery (left un-acked); e2/e3 :ok.
      # min_idle_ms 0 so the XAUTOCLAIM beat re-claims e1 AFTER e2/e3 are handled.
      handler = fn job ->
        send(parent, {:delivered, job.id})
        if job.id == e1 and not seen_redelivery?(job.attempts), do: {:error, :hold}, else: :ok
      end

      {:ok, c} =
        StreamConsumer.start_link(
          queue: q,
          stream: "s",
          group: "grp",
          consumer: "c1",
          group_start: :head,
          handler: handler,
          conn: own_lane(),
          beat_ms: 30,
          min_idle_ms: 0
        )

      # collect the delivery ORDER until e1 is re-delivered
      order = collect_until_redelivery([], e1)
      assert :ok = StreamConsumer.stop(c)

      # e1 (the lowest branded id) is delivered, then e2 and/or e3 (higher ids),
      # then e1 AGAIN (the re-claim) -- so the re-claimed e1 arrives AFTER a
      # higher-id entry: delivery is OUT of mint order. Find the re-claim index.
      redeliver_idx = order |> Enum.with_index() |> Enum.filter(fn {id, _} -> id == e1 end) |> List.last() |> elem(1)
      already = Enum.take(order, redeliver_idx)
      # at least one entry already delivered before the e1 re-claim has a HIGHER
      # branded id than e1 -- the order-theorem exception, exercised
      assert Enum.any?(already, fn id -> id > e1 end)
    end
  end

  # -- helpers --------------------------------------------------------------

  # an exclusive private connector lane for one consumer (the :conn option).
  defp own_lane do
    {:ok, c} = Connector.start_link(port: 6390)
    c
  end

  defp start_noop(q, stream, group, consumer) do
    StreamConsumer.start_link(
      queue: q,
      stream: stream,
      group: group,
      consumer: consumer,
      group_start: :head,
      handler: fn _ -> :ok end,
      conn: own_lane(),
      beat_ms: 1_000,
      min_idle_ms: 600_000
    )
  end

  defp ok!({:ok, v}), do: v

  defp assert_receive_second do
    receive do
      {:second, id} -> id
    after
      3_000 -> flunk("no :second message")
    end
  end

  # pull the first [xadd_id, fields] entry off an XREADGROUP reply (RESP3 map or
  # RESP2 nested-array stream->entries form).
  defp first_entry(reply, key) when is_map(reply), do: reply |> Map.get(key) |> hd()

  defp first_entry(reply, key) when is_list(reply) do
    {^key, [entry | _]} = List.keyfind(reply, key, 0)
    entry
  end

  defp field_value([k, v | _], k), do: v
  defp field_value([_k, _v | rest], target), do: field_value(rest, target)
  defp field_value(_, _), do: nil

  # the redelivery test's stateless predicates (attempts is the delivery-count;
  # attempts >= 2 means a re-delivery, so e1 should ack the second time).
  defp seen_redelivery?(attempts), do: attempts >= 2

  # Collect the delivery ORDER (a list in delivery order) until e1 appears a
  # SECOND time (its re-claim). e1 is delivered FIRST (group_start :head, mint
  # order), then e2/e3, then e1 again (the XAUTOCLAIM re-claim of the un-acked e1).
  defp collect_until_redelivery(acc, e1) do
    receive do
      {:delivered, id} ->
        acc = acc ++ [id]
        seen_e1 = Enum.count(acc, &(&1 == e1))
        if seen_e1 >= 2, do: acc, else: collect_until_redelivery(acc, e1)
    after
      4_000 -> flunk("e1 was never re-delivered: #{inspect(acc)}")
    end
  end
end
