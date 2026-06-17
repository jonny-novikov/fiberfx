defmodule EchoMQ.ConnectorTest do
  @moduledoc """
  The wire column of the Connector row (echo2-migration.md §5) plus the
  three Stage-1c verbs (the extension rows): the version fence claimed or
  verified and fatal on mismatch, command/pipeline ordering, EVALSHA-first
  with the cold-cache load-and-retry mapping (connector.ex:84-88), the
  RESP3 push family, the stats counter names, and `wire_version/0`.

  PLACEMENT: this suite lives in `apps/echo_mq/test/` rather than the wire
  app's own tree because the connector's fence reads
  `EchoMQ.Keyspace.version_key/0` at runtime and `keyspace.ex` lives in
  echo_mq — a per-app echo_wire run loads only the dependency-free wire
  app, so no echo_wire-local test can connect. Here both apps are in the
  dep closure (echo_mq depends on echo_wire).

  The fence tests MUTATE the shared `{emq}:version` key — the whole module
  is `async: false`, the key is snapshotted in setup, and the restore net
  is a raw `redis-cli` in `on_exit` (a fenced connector cannot reconnect
  through a broken fence to restore it).
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoMQ.{Connector, Keyspace, Script}

  # test-started conns die with the test process (the OTP parent-exit
  # protocol) — cleanup rides its own disposable connection
  defp connect(opts \\ []) do
    {:ok, conn} = Connector.start_link([port: 6390] ++ opts)
    conn
  end

  defp fresh_key(_conn) do
    key = "emq:{emq0.conn#{System.unique_integer([:positive])}}:probe"

    on_exit(fn ->
      {:ok, conn} = Connector.start_link(port: 6390)
      {:ok, _} = Connector.command(conn, ["DEL", key])
      GenServer.stop(conn)
    end)

    key
  end

  test "wire_version/0 is the fence value" do
    assert Connector.wire_version() == "echomq:2.0.0"
  end

  # The fence tests mutate `{emq}:version` -- a GLOBAL deployment-reserve key
  # (NOT queue-scoped) that the connector's `fence/2` reads at EVERY boot. The
  # module is `async: false`, which serializes it against other SYNC tests but
  # NOT against the `async: true` pool (max_cases > 1): while a fence test holds
  # the key poisoned (e.g. "echomq:0.0.1"), a concurrently-booting async test
  # reads it and refuses `{:version_fence, …}`. The ≥100 determinism loop
  # surfaced this pre-existing emq.1-era global-state race (~1-2%).
  #
  # The fix isolates WHICH `{emq}:version` the fence tests touch: every
  # connection in this block runs on a high, otherwise-unused LOGICAL DB
  # (`database: @fence_db`). `fence/2` SELECTs that DB and reads/claims the key
  # THERE, so the poison lands on db-#{@fence_db}'s key -- invisible to every
  # other test (all on db 0). The real fence logic (SET NX + read-back +
  # refusal) is still exercised against an isolated key namespace; no
  # concurrency change, no test excluded, no coverage lost. db-#{@fence_db} is
  # FLUSHDB-cleaned in on_exit via the helper itself (no out-of-process
  # redis-cli). (Mars-2 Stage-3 harden.)
  @fence_db 15

  describe "the version fence (mutates {emq}:version on an isolated logical DB)" do
    setup do
      # Trap exits for the WHOLE fence-test lifecycle (not just from an
      # assertion onward): a db-15 fencing connector that boots clean here, then
      # blips its TCP and re-fences on :reconnect into a sibling test's poisoned
      # {emq}:version, dies {:stop, {:version_fence,…}} -- which propagates as a
      # LINKED exit. Trapping in setup catches it for every fence test, so the
      # version_fence stop is delivered as a message, not a failing exit signal
      # (the iter-5/73 linked-exit propagation -- Mars-1 S4).
      Process.flag(:trap_exit, true)

      helper = connect(database: @fence_db)
      # start from a clean, claim-free fence on the isolated DB
      {:ok, _} = Connector.command(helper, ["FLUSHDB"])
      on_exit(fn -> fence_db_flush() end)
      %{helper: helper}
    end

    test "an unclaimed fence is claimed at boot", %{helper: helper} do
      {:ok, _} = Connector.command(helper, ["DEL", Keyspace.version_key()])

      conn = connect(database: @fence_db)
      assert {:ok, "echomq:2.0.0"} = Connector.command(conn, ["GET", Keyspace.version_key()])
    end

    test "a matching fence is verified and the connection lives", %{helper: helper} do
      # claim the fence on the isolated DB first, then a second boot verifies it
      claimer = connect(database: @fence_db)
      assert {:ok, "echomq:2.0.0"} = Connector.command(claimer, ["GET", Keyspace.version_key()])

      conn = connect(database: @fence_db)
      assert Connector.stats(conn).status == :connected
      _ = helper
    end

    test "a mismatched fence is fatal at boot", %{helper: helper} do
      {:ok, "OK"} = Connector.command(helper, ["SET", Keyspace.version_key(), "echomq:0.0.1"])

      # the describe's setup traps exits for the whole lifecycle (B1)

      assert {:error, {:version_fence, "echomq:0.0.1"}} =
               Connector.start_link(port: 6390, database: @fence_db)

      # Clear the poisoned key SYNCHRONOUSLY, in-body, so the isolated DB is left
      # claim-free regardless of on_exit ordering (an on_exit FLUSHDB can lag
      # into a sibling fence test's setup -- the same global-state lag, now on
      # db-#{@fence_db}). With the key cleared here, every fence test starts from
      # a known state under the synchronous setup FLUSHDB.
      {:ok, _} = Connector.command(helper, ["DEL", Keyspace.version_key()])
    end
  end

  # Clean the isolated fence DB with a RAW redis-cli -- never a fencing
  # Connector. A `Connector.start_link(database: @fence_db)` re-fences against
  # {emq}:version at boot, so if a test left db-#{@fence_db} POISONED (e.g. a
  # body crashed before its in-body DEL), the cleaner itself would die
  # {:version_fence,…} and never FLUSHDB -- the anti-pattern the module
  # docstring forbids (a fenced connector cannot reconnect through a broken
  # fence to restore it). A raw FLUSHDB cannot be fenced, so this cleans db-15
  # after EVERY fence test, crash or not (the canonical restore -- Mars-1 S4).
  defp fence_db_flush do
    {_, 0} =
      System.cmd("redis-cli", ["-p", "6390", "-n", Integer.to_string(@fence_db), "flushdb"],
        stderr_to_stdout: true
      )
  end

  test "pipeline/3 answers every reply in command order" do
    conn = connect()
    key = fresh_key(conn)

    assert {:ok, ["OK", 2, "2"]} =
             Connector.pipeline(conn, [["SET", key, "1"], ["INCR", key], ["GET", key]])
  end

  test "command/3 is a pipeline of one" do
    conn = connect()
    key = fresh_key(conn)

    assert {:ok, "OK"} = Connector.command(conn, ["SET", key, "v"])
    assert {:ok, "v"} = Connector.command(conn, ["GET", key])
    assert {:ok, nil} = Connector.command(conn, ["GET", key <> ".absent"])
  end

  test "eval/5 runs EVALSHA-first and loads on a cold cache" do
    conn = connect()
    key = fresh_key(conn)
    script = Script.new(:emq0_probe, "return redis.call('SET', KEYS[1], ARGV[1])")

    {:ok, _} = Connector.command(conn, ["SCRIPT", "FLUSH"])

    assert {:ok, "OK"} = Connector.eval(conn, script, [key], ["cold"])
    assert Connector.stats(conn).script_loads == 1
    assert {:ok, "cold"} = Connector.command(conn, ["GET", key])

    # warm cache: no further load
    assert {:ok, "OK"} = Connector.eval(conn, script, [key], ["warm"])
    assert Connector.stats(conn).script_loads == 1
  end

  test "eval/5 maps a server error reply identically on the load-and-retry path" do
    conn = connect()
    failing = Script.new(:emq0_boom, "return redis.error_reply('EMQTEST boom')")

    {:ok, _} = Connector.command(conn, ["SCRIPT", "FLUSH"])

    # cold cache: NOSCRIPT -> load -> retry must answer the typed server error
    assert {:error, {:server, "EMQTEST boom"}} = Connector.eval(conn, failing, [], [])

    # warm cache: the first attempt answers the same shape
    assert {:error, {:server, "EMQTEST boom"}} = Connector.eval(conn, failing, [], [])
  end

  test "push_command/3 refuses a RESP2 connection" do
    conn = connect(protocol: 2)

    assert Connector.subscribe(conn, "emq0.chan") == {:error, :requires_resp3}
  end

  test "subscribe/2 rides the RESP3 push path to push_to" do
    chan = "emq0.chan#{System.unique_integer([:positive])}"
    sub = connect(protocol: 3, push_to: self())
    pub = connect()

    assert :ok = Connector.subscribe(sub, chan)
    assert {:ok, 1} = Connector.command(pub, ["PUBLISH", chan, "ping"])

    assert_receive {:emq_push, ["message", ^chan, "ping"]}, 1_000
  end

  test "noreply_pipeline/3 answers :ok with the effect landed reply-free" do
    conn = connect()
    key = fresh_key(conn)

    assert :ok = Connector.noreply_pipeline(conn, [["SET", key, "silent"], ["APPEND", key, "!"]])
    assert {:ok, "silent!"} = Connector.command(conn, ["GET", key])
  end

  test "transaction_pipeline/3 answers the EXEC replies under MULTI/EXEC" do
    conn = connect()
    key = fresh_key(conn)

    assert {:ok, ["OK", 2, "2"]} =
             Connector.transaction_pipeline(conn, [
               ["SET", key, "1"],
               ["INCR", key],
               ["GET", key]
             ])
  end

  test "stats/1 carries the counter names" do
    conn = connect()
    {:ok, _} = Connector.command(conn, ["PING"])

    stats = Connector.stats(conn)

    assert Map.keys(stats) |> Enum.sort() == [
             :bytes_out,
             :commands,
             :evalsha_calls,
             :label,
             :overloads,
             :pending,
             :pipelines,
             :protocol,
             :pushes,
             :reconnects,
             :replies,
             :script_loads,
             :status,
             :wire_errors
           ]

    assert stats.status == :connected
    assert stats.commands >= 1
    assert stats.replies >= 1
    assert stats.bytes_out > 0
  end
end
