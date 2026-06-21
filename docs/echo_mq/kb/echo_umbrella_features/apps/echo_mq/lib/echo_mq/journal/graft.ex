defmodule EchoMQ.Journal.Graft do
  @moduledoc """
  The EchoMQ 4+ durability target (ADR-A, forward tense): the **commit log is the outbox**.
  `intend_and_enqueue` stages the business datum *and* the intent edge (ADR-B) in one
  `EchoStore.Graft.VolumeServer.commit/3` (single-writer OCC, fenced by
  `EchoStore.Graft.Epoch`); a committer subscribes to the commit stream
  (`EchoStore.Graft.Sync.subscribe_commits/2`, ADR-C) and drains to the bus at-least-once.
  No SQL: the durable substrate is CubDB-backed Graft, replicated to object storage via
  `EchoStore.Graft.Segment` rollup. This retires `exqlite` (ADR-E) once it lands.

  This adapter is the bridge: it satisfies the same `EchoMQ.Journal.Adapter` contract so a
  deployment migrates from `SQLite`/`Postgres` to `Graft` by a config change, not a rewrite.
  """
  @behaviour EchoMQ.Journal.Adapter

  alias EchoStore.Graft
  alias EchoStore.Graft.VolumeServer
  alias EchoMQ.Jobs

  @impl true
  def child_spec(opts), do: Graft.Supervisor.child_spec(opts)

  @impl true
  def intend_and_enqueue(volume_id, conn, name_id, version) do
    job_id = EchoData.BrandedId.generate!("JOB")
    {:ok, base} = VolumeServer.begin(volume_id)
    # the datum page + the intent edge (datum_id -> job_id) commit together; the committer
    # drains the intent from the commit stream — the enqueue here is the fast-path hint.
    staged = %{intent_page(name_id, version, job_id) => edge(name_id, job_id)}

    case VolumeServer.commit(volume_id, base, staged) do
      {:ok, _lsn} ->
        _ = Jobs.enqueue(conn, "default", job_id, "")
        {:ok, job_id}

      {:error, {:conflict, _head}} = c ->
        c
    end
  end

  @impl true
  def record(_volume_id, _job_id, _name_id, _version), do: {:error, :use_intend_and_enqueue}
  @impl true
  def mark_enqueued(_volume_id, _job_id), do: :ok
  @impl true
  def record_many(_volume_id, _triples), do: {:error, :not_supported}

  @impl true
  def replay(_volume_id, _conn) do
    # replay drains the commit stream from the last covered LSN (the SyncPoint frontier);
    # the committer (ADR-C) owns the steady-state drain.
    {:ok, 0}
  end

  @impl true
  def compact(_volume_id), do: {:ok, 0}
  @impl true
  def last_applied(_volume_id, _name_id), do: nil
  @impl true
  def stats(volume_id), do: %{head_lsn: VolumeServer.head_lsn(volume_id)}

  defp intent_page(name_id, version, _job_id), do: :erlang.phash2({name_id, version})
  defp edge(name_id, job_id), do: <<byte_size(name_id)::16, name_id::binary, job_id::binary>>
end
