defmodule EchoMQ.JobsExtendTest do
  @moduledoc """
  The v1 lock-extension Lua coverage (`worker_integration_test.exs` "Lua
  scripts" -- `extend_lock script works` / `extend_lock fails with wrong token`)
  ADOPTED for the v2 `EchoMQ.Jobs.extend_lock/5` + `extend_locks/4` (emq.2.3-D4,
  the Operator's "tests v1 adopted and verified").

  Re-derived against the v2 surface, NEVER the v1 mechanism:
  - the v1 `extend_lock` script SET a `…:lock` STRING token `PX <ttl>` and SREM'd
    a `stalled` SET, and "extension worked" was the script answering `1`. The v2
    lease IS the active-ZSET score (the `@claim` re-score), so the extension
    re-scores THAT member (`extend_lock/5`) -- never a separate `:lock` string.
  - so "the lease was extended" is no longer a lock-string's existence; it is the
    REAPER'S verdict: a job whose active score was re-scored past `now` is NOT
    reclaimed by `reap/2`. The v2 drill therefore asserts the stronger,
    behavior-true gate -- claim a SHORT lease, extend it past the original
    deadline, run `reap/2`, the job is STILL active (an alive worker keeps its
    job). The CAPABILITY ("a long-but-alive worker is not reaped mid-work") is
    what is verified.
  - the v1 wrong-token verdict (the script answers `0`) becomes the v2 typed
    `{:error, :stale}` (the `EMQSTALE` fencing-token wire class -- the existing
    class, no new one; the `complete/4` pattern). A gone row answers
    `{:error, :gone}`.
  - the clock is the server's (`TIME` inside the script) -- never the v1 caller
    clock.

  `:valkey`-tagged; per-test sub-queues + the disposable-purge idiom
  (`jobs_test.exs`).
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq23.extend#{System.unique_integer([:positive])}"

    # the purge rides its own disposable connection; AND the setup conn is
    # STOPPED at test end (not just left to die with the test process) -- a
    # connector lingering into teardown can RECONNECT into a sibling suite's
    # global-state window (connector_test's version-fence mutation) and die
    # {:version_fence, …}, the determinism-gate race (L-9). (Mars-1 Stage-3.)
    on_exit(fn ->
      stop_conn(conn)
      purge(q)
    end)

    %{conn: conn, q: q}
  end

  defp stop_conn(conn) do
    try do
      GenServer.stop(conn)
    catch
      :exit, _ -> :ok
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  # The active-set score of an id (its lease deadline in ms), or nil if absent.
  # RESP3 returns a ZSET score as a native Double (an Elixir float); RESP2 a
  # bulk string -- normalize both to the integer ms deadline.
  defp active_score(conn, q, id) do
    case Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "active"), id]) do
      {:ok, nil} -> nil
      {:ok, score} when is_float(score) -> trunc(score)
      {:ok, score} when is_integer(score) -> score
      {:ok, score} when is_binary(score) -> String.to_integer(score)
    end
  end

  describe "extend_lock/5 (the v1 `extend_lock script works`, re-derived)" do
    test "an extended lease survives the reaper past its ORIGINAL deadline", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "long-but-alive")

      # claim a SHORT lease (30ms): the original deadline is now+30
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 30)
      before = active_score(conn, q, id)
      assert is_integer(before)

      # the worker is alive: extend the lease to a fresh 60s deadline BEFORE the
      # 30ms elapses (re-scores the active member under the server TIME)
      assert :ok = Jobs.extend_lock(conn, q, id, 1, 60_000)
      after_score = active_score(conn, q, id)
      assert after_score > before

      # let the ORIGINAL 30ms deadline pass; the reaper scans expired leases
      Process.sleep(60)
      assert {:ok, 0} = Jobs.reap(conn, q)

      # the job was NOT reclaimed -- it is still active, held by its live worker,
      # and its current token (1) still settles
      assert {:ok, "active"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"])
      assert :ok = Jobs.complete(conn, q, id, 1)
    end

    test "the extension re-scores the active member to a fresh server-clock deadline (never a :lock string)",
         %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 1_000)

      before = active_score(conn, q, id)
      assert :ok = Jobs.extend_lock(conn, q, id, 1, 30_000)
      after_score = active_score(conn, q, id)

      # the lease moved FORWARD (the active score is the lease; the extension
      # re-scored it) -- and no `:lock` string was written as the lease clock
      assert after_score > before
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id) <> ":lock"])
    end
  end

  describe "extend_lock/5 token fence (the v1 `extend_lock fails with wrong token`, re-derived)" do
    test "a stale token refuses EMQSTALE -> {:error, :stale} and does NOT re-score", %{
      conn: conn,
      q: q
    } do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 1_000)

      before = active_score(conn, q, id)

      # token 99 is not the holder's token (1) -> the existing EMQSTALE class
      assert {:error, :stale} = Jobs.extend_lock(conn, q, id, 99, 60_000)

      # the lease is UNCHANGED -- a stale extension re-scores nothing
      assert active_score(conn, q, id) == before
    end

    test "extending a gone row answers {:error, :gone}", %{conn: conn, q: q} do
      id = BrandedId.generate!("JOB")
      # never enqueued -> no row, no attempts field
      assert {:error, :gone} = Jobs.extend_lock(conn, q, id, 1, 60_000)
    end

    test "an ill-formed id raises at the key builder before the wire (INV5)", %{conn: conn, q: q} do
      assert_raise ArgumentError, fn ->
        Jobs.extend_lock(conn, q, "not-a-branded-id", 1, 60_000)
      end
    end
  end

  describe "extend_locks/4 batch (the v1 `extendLocks` capability, re-derived)" do
    test "answers {:ok, failed} naming only the ids it could NOT extend", %{conn: conn, q: q} do
      live = BrandedId.generate!("JOB")
      stale = BrandedId.generate!("JOB")
      gone = BrandedId.generate!("JOB")

      {:ok, :enqueued} = Jobs.enqueue(conn, q, live, "a")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, stale, "b")
      {:ok, {^live, _, 1}} = Jobs.claim(conn, q, 1_000)
      {:ok, {^stale, _, 1}} = Jobs.claim(conn, q, 1_000)

      live_before = active_score(conn, q, live)

      # live: correct token; stale: wrong token; gone: never enqueued
      held = [{live, 1}, {stale, 99}, {gone, 1}]
      assert {:ok, failed} = Jobs.extend_locks(conn, q, held, 60_000)

      # only the live id was extended; the stale + gone ids are the failures
      assert Enum.sort(failed) == Enum.sort([stale, gone])
      assert active_score(conn, q, live) > live_before
    end

    test "an empty batch answers {:ok, []} and touches nothing", %{conn: conn, q: q} do
      assert {:ok, []} = Jobs.extend_locks(conn, q, [], 60_000)
    end

    test "a whole batch of live holders answers {:ok, []}", %{conn: conn, q: q} do
      ids =
        for _ <- 1..3 do
          id = BrandedId.generate!("JOB")
          {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
          {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 1_000)
          id
        end

      held = Enum.map(ids, fn id -> {id, 1} end)
      assert {:ok, []} = Jobs.extend_locks(conn, q, held, 60_000)

      # every member's lease moved to the fresh 60s deadline -> none reaped
      Process.sleep(20)
      assert {:ok, 0} = Jobs.reap(conn, q)
    end

    test "an ill-formed id in the batch raises at the key builder before the wire (INV5)", %{
      conn: conn,
      q: q
    } do
      ok = BrandedId.generate!("JOB")

      assert_raise ArgumentError, fn ->
        Jobs.extend_locks(conn, q, [{ok, 1}, {"not-branded", 1}], 60_000)
      end
    end
  end
end
