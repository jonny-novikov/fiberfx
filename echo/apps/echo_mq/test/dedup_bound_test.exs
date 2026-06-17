defmodule EchoMQ.DedupBoundTest do
  @moduledoc """
  EMQ.2.4-D4 -- the `de:<dedupId>` orphan release, the declared-keys HONEST
  limit, asserted (not papered over). The bus's bounded-complete dedup release:

  - a parked `de:<dedup_id>` is released by `remove_job/4` (with the caller-
    supplied `dedup_id`) IFF its value equals the job id -- the v1 `removeJob`
    capability re-derived against declared keys (`remove_job/4`'s declared
    `de:<did>` slot, jobs.ex `@remove_job`);
  - a parked `de:<dedup_id>` is released at drain-time when the row it referred
    to is drained -- wait, the as-built drain deletes the ROW + `:logs`, NOT the
    `de:` family (the row stores no backref); so the HONEST limit is that drain
    does not chase the `de:` family either. The test asserts the AS-BUILT
    behavior, not an invented sweep.
  - an orphan `de:<did>` with no live referrer is acknowledged UN-SWEPT by
    obliterate (no `SCAN` of the `de:` family -- it would cross slots and break
    the A-1 declared-keys law (design §6/S-6); no stored backref -- it would
    change the three-field row the conformance set pins, INV1).

  Why a sweep / a backref is REJECTED (recorded, per US4):
  - a `SCAN emq:{q}:de:*` to find orphans is a multi-key cross-slot read the
    declared-keys law (A-1, design §6) forbids in a script, and a host-side
    SCAN over a live keyspace is unbounded + races concurrent parks;
  - a stored backref (the row carries the `dedup_id` so `remove_job` could find
    it without the caller) changes the as-built THREE-field row (state/attempts/
    payload) the conformance `mint` scenario pins byte-for-byte (INV1) -- a
    fourth field is a row-shape change, not an additive minor.

  So the dedup key release is BOUNDED-COMPLETE: released exactly where the
  caller's `dedup_id` is in hand (remove). An orphan is left un-swept, and that
  is the limit stated, not a false-complete (D4). Per-test sub-queues; Valkey
  6390 the truth row. EMQ.2.4-AS7 / EMQ.2.4-US4.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Admin, Connector, Jobs, Keyspace, Metrics}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq24.dedup#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  describe "remove_job/4 releases the caller-supplied dedup key (bounded-complete)" do
    test "a de: key whose value is the job id is released when the job is removed with its dedup_id",
         %{conn: conn, q: q} do
      did = "order-1001"
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), id])

      # before: the dedup key reads back the parked id
      assert {:ok, ^id} = Metrics.get_deduplication_job_id(conn, q, did)

      assert :ok = Jobs.remove_job(conn, q, id, did)

      # after: the job is gone AND the dedup key is released
      assert {:ok, :absent} = Metrics.get_job_state(conn, q, id)
      assert :absent = Metrics.get_deduplication_job_id(conn, q, did)
      assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.queue_key(q, "de:" <> did)])
    end

    test "remove_job/4 releases the de: key only when its value matches (not a foreign park)",
         %{conn: conn, q: q} do
      did = "order-1002"
      id = BrandedId.generate!("JOB")
      other = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      # the dedup key points at a DIFFERENT (other) job id, not `id`
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), other])

      assert :ok = Jobs.remove_job(conn, q, id, did)

      # `id` is gone, but the de: key (pointing at `other`) is NOT clobbered --
      # the release is value-fenced (only a key whose value IS this job releases)
      assert {:ok, :absent} = Metrics.get_job_state(conn, q, id)
      assert {:ok, ^other} = Metrics.get_deduplication_job_id(conn, q, did)
    end

    test "remove_job/3 without a dedup_id leaves a parked de: key in place (the caller holds the id)",
         %{conn: conn, q: q} do
      did = "order-1003"
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), id])

      # the caller removes WITHOUT passing dedup_id -> the row is gone, the de:
      # key survives as an orphan (the bounded-complete limit: no row backref to
      # discover it). This is the honest limit, asserted.
      assert :ok = Jobs.remove_job(conn, q, id)
      assert {:ok, :absent} = Metrics.get_job_state(conn, q, id)
      assert {:ok, ^id} = Metrics.get_deduplication_job_id(conn, q, did)
    end
  end

  describe "the orphan de: key is acknowledged un-swept (the declared-keys honest limit)" do
    test "obliterate clears the structure keys but does NOT SCAN the de: family for orphans",
         %{conn: conn, q: q} do
      # an orphan dedup key with no live referrer (the job it referred to is gone)
      did = "orphan-7"
      gone = BrandedId.generate!("JOB")
      {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), gone])

      # a live pending job so the queue has real structure to obliterate
      live = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, live, "w")

      :ok = Admin.pause(conn, q)
      :ok = Admin.obliterate(conn, q)

      # the live job and every state set are gone (obliterate cleared the
      # structure)...
      assert {:ok, :absent} = Metrics.get_job_state(conn, q, live)
      assert {:ok, %{"pending" => 0}} = Metrics.get_counts(conn, q, ["pending"])

      # ...but the orphan de: key survives: obliterate does not SCAN the de:
      # family (the declared-keys honest limit -- no slot-crossing SCAN, no
      # stored backref). The limit is asserted, NOT papered over.
      assert {:ok, ^gone} = Metrics.get_deduplication_job_id(conn, q, did)
    end
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end
end
