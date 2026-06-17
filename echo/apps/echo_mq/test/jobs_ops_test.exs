defmodule EchoMQ.JobsOpsTest do
  @moduledoc """
  The wire column of the operator plane's job-mutation verbs (emq.2.2 D5–D9):
  update_data, update_progress, add_log/get_job_logs, remove_job, and
  reprocess_job, on per-test sub-queues with the baseline purge idiom.
  Acceptance is read through the emq.2.1 read lens (`EchoMQ.Metrics`).
  AS-5 / AS-6 / AS-7 / AS-8 / AS-9.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Connector, Jobs, Keyspace, Metrics}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq22.ops#{System.unique_integer([:positive])}"
    on_exit(fn -> purge(q) end)
    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    stop_quietly(conn)
  end

  # stop a connection tolerating it being already dead -- a subscriber shares
  # the suite with the resubscribe scenario (which kills connections), so a
  # bare GenServer.stop is a latent flake (the conformance_run_test idiom)
  defp stop_quietly(conn) do
    GenServer.stop(conn)
  catch
    :exit, _ -> :ok
  end

  # -- D5: update_data ------------------------------------------------------

  test "update_data/4 replaces the payload; the read lens sees the new value", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "old")

    assert :ok = Jobs.update_data(conn, q, id, "new")
    assert {:ok, %{"payload" => "new"}} = Metrics.get_job(conn, q, id)
  end

  test "update_data/4 refuses a missing job with :gone, changing nothing", %{conn: conn, q: q} do
    missing = BrandedId.generate!("JOB")
    assert {:error, :gone} = Jobs.update_data(conn, q, missing, "x")
    assert :absent = Metrics.get_job(conn, q, missing)
  end

  test "update_data/4 raises at the key builder for an ill-formed id", %{conn: conn, q: q} do
    assert_raise ArgumentError, fn -> Jobs.update_data(conn, q, "not-branded", "x") end
  end

  # -- D6: update_progress --------------------------------------------------

  test "update_progress/4 writes the progress field; a missing job is :gone", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

    assert :ok = Jobs.update_progress(conn, q, id, "75")
    assert {:ok, "75"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "progress"])

    missing = BrandedId.generate!("JOB")
    assert {:error, :gone} = Jobs.update_progress(conn, q, missing, "1")
  end

  test "update_progress/4 emits the registered progress event on emq:{q}:events", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

    # subscribe BEFORE the update (no lost-wakeup), receive bounded (no flake)
    chan = "emq:{" <> q <> "}:events"
    {:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
    on_exit(fn -> stop_quietly(sub) end)
    :ok = Connector.subscribe(sub, chan)

    assert :ok = Jobs.update_progress(conn, q, id, "42")

    payload =
      receive do
        {:emq_push, ["message", ^chan, p]} -> p
      after
        2_000 -> flunk("no progress event received within 2s")
      end

    # the registered contract: a cjson object carrying event/job/progress
    # (asserted by field, not byte order -- cjson key order is unspecified)
    assert String.contains?(payload, ~s("event":"progress"))
    assert String.contains?(payload, id)
    assert String.contains?(payload, ~s("progress":"42"))
  end

  test "update_progress/4 of a missing job emits NO event (the refusal changes nothing)", %{conn: conn, q: q} do
    chan = "emq:{" <> q <> "}:events"
    {:ok, sub} = Connector.start_link(port: 6390, protocol: 3, push_to: self())
    on_exit(fn -> stop_quietly(sub) end)
    :ok = Connector.subscribe(sub, chan)

    missing = BrandedId.generate!("JOB")
    assert {:error, :gone} = Jobs.update_progress(conn, q, missing, "1")

    refute_receive {:emq_push, ["message", ^chan, _]}, 300
  end

  # -- D7: add_log / get_job_logs -------------------------------------------

  test "add_log/5 appends in order, get_job_logs/3 reads it, keep-N trims to the last N", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

    assert {:ok, 1} = Jobs.add_log(conn, q, id, "a")
    assert {:ok, 2} = Jobs.add_log(conn, q, id, "b")
    assert {:ok, 3} = Jobs.add_log(conn, q, id, "c")
    assert {:ok, ["a", "b", "c"]} = Jobs.get_job_logs(conn, q, id)

    # keep-2 trims to the last two
    assert {:ok, 2} = Jobs.add_log(conn, q, id, "d", 2)
    assert {:ok, ["c", "d"]} = Jobs.get_job_logs(conn, q, id)
  end

  test "get_job_logs/3 of a job with no logs is empty; a missing job is :gone", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    assert {:ok, []} = Jobs.get_job_logs(conn, q, id)

    missing = BrandedId.generate!("JOB")
    assert {:error, :gone} = Jobs.get_job_logs(conn, q, missing)
    assert {:error, :gone} = Jobs.add_log(conn, q, missing, "x")
  end

  # -- D8: remove_job -------------------------------------------------------

  test "remove_job/4 removes an unlocked job from its set and releases a held dedup key", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    did = "order-99"
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, _} = Jobs.add_log(conn, q, id, "diag")
    {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), id])

    assert :ok = Jobs.remove_job(conn, q, id, did)
    assert {:ok, :absent} = Metrics.get_job_state(conn, q, id)
    # the row and its logs subkey are gone
    assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id) <> ":logs"])
    # the dedup key whose value was this id is released
    assert :absent = Metrics.get_deduplication_job_id(conn, q, did)
  end

  test "remove_job/4 finds the job in whichever set holds it (dead)", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, id, 1, 10, 1, "x")
    assert {:ok, :dead} = Metrics.get_job_state(conn, q, id)

    assert :ok = Jobs.remove_job(conn, q, id)
    assert {:ok, :absent} = Metrics.get_job_state(conn, q, id)
  end

  test "remove_job/4 refuses a locked job with :locked, leaving it untouched", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, _} = Connector.command(conn, ["SET", Keyspace.job_key(q, id) <> ":lock", "worker-7"])

    assert {:error, :locked} = Jobs.remove_job(conn, q, id)
    # the job is untouched -- still pending, row intact
    assert {:ok, :pending} = Metrics.get_job_state(conn, q, id)
    assert {:ok, %{"payload" => "w"}} = Metrics.get_job(conn, q, id)
  end

  test "remove_job/4 with no dedup_id does not release any dedup key", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    did = "keep-me"
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    # a dedup key that does NOT belong to this job stays put
    {:ok, _} = Connector.command(conn, ["SET", Keyspace.queue_key(q, "de:" <> did), "OTHERID"])

    assert :ok = Jobs.remove_job(conn, q, id)
    assert {:ok, "OTHERID"} = Metrics.get_deduplication_job_id(conn, q, did)
  end

  test "remove_job/4 of a missing job is :gone", %{conn: conn, q: q} do
    missing = BrandedId.generate!("JOB")
    assert {:error, :gone} = Jobs.remove_job(conn, q, missing)
  end

  # -- D9: reprocess_job ----------------------------------------------------

  test "reprocess_job/3 moves a dead job to pending and clears last_error", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, id, 1, 10, 1, "boom")
    assert {:ok, "boom"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "last_error"])

    assert :ok = Jobs.reprocess_job(conn, q, id)
    assert {:ok, :pending} = Metrics.get_job_state(conn, q, id)
    assert {:ok, %{"state" => "pending"}} = Metrics.get_job(conn, q, id)
    assert {:ok, nil} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "last_error"])
    # a reprocessed job is claimable again
    assert {:ok, {^id, "w", 2}} = Jobs.claim(conn, q, 60_000)
  end

  test "reprocess_job/3 refuses a job NOT in dead with :not_dead, changing nothing", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")

    assert {:error, :not_dead} = Jobs.reprocess_job(conn, q, id)
    assert {:ok, :pending} = Metrics.get_job_state(conn, q, id)
  end

  test "reprocess_job/3 of a missing job is :gone", %{conn: conn, q: q} do
    missing = BrandedId.generate!("JOB")
    assert {:error, :gone} = Jobs.reprocess_job(conn, q, missing)
  end

  test "a reprocessed job stays unclaimable while the queue is paused (the D2 seam)", %{conn: conn, q: q} do
    id = BrandedId.generate!("JOB")
    {:ok, :enqueued} = Jobs.enqueue(conn, q, id, "w")
    {:ok, {^id, _, 1}} = Jobs.claim(conn, q, 60_000)
    {:ok, :dead} = Jobs.retry(conn, q, id, 1, 10, 1, "x")

    :ok = EchoMQ.Admin.pause(conn, q)
    assert :ok = Jobs.reprocess_job(conn, q, id)
    # it landed pending...
    assert {:ok, :pending} = Metrics.get_job_state(conn, q, id)
    # ...but the paused queue serves nothing
    assert :empty = Jobs.claim(conn, q, 60_000)
  end
end
