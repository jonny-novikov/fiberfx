defmodule EchoMQ.Journal.Postgres do
  @moduledoc """
  A Postgres outbox adapter. The intent rides the **host application's own**
  `Repo.transaction/1`, so the enqueue intent commits atomically with the business row in
  the same Postgres transaction — Oban's strongest property, recovered for a
  Postgres-resident consumer **without** moving the queue onto Postgres.

  Why this beats Oban-on-Postgres for the balanced deployment: Oban runs the *entire* queue
  on Postgres — every fetch, heartbeat, ack, prune, and the jobs themselves — so Postgres is
  both the throughput ceiling and the single point of failure. Here Postgres holds **only the
  outbox `intents`** (one small insert per triggering write); the bus, the dequeue, the
  retries, and the history stay on Valkey. A single-instance Postgres becomes a low-rate,
  mostly-idle durability anchor, and a reliable Valkey carries the work — the single-instance-DB
  risk is mitigated by giving Postgres far less to do.

  Config:

      config :echo_mq, EchoMQ.Journal, adapter: EchoMQ.Journal.Postgres, repo: MyApp.Repo
  """
  @behaviour EchoMQ.Journal.Adapter

  alias EchoMQ.Journal.Postgres.Intent
  alias EchoMQ.{Jobs, Journal}
  import Ecto.Query

  # The adapter is stateless: `journal` is the configured Repo. No GenServer needed —
  # Postgres connection pooling is the host Repo's job.
  @impl true
  def child_spec(_opts), do: %{id: __MODULE__, start: {Function, :identity, [:ignore]}}

  defp repo(repo) when is_atom(repo), do: repo
  defp repo(_), do: Keyword.fetch!(Journal.config(), :repo)

  @impl true
  def intend_and_enqueue(repo, conn, name_id, version) do
    job_id = EchoData.BrandedId.generate!("JOB")

    repo(repo).transaction(fn ->
      :ok = record(repo, job_id, name_id, version)
      # The business write the caller is making belongs in THIS transaction too — that is
      # the atomic boundary. The enqueue itself is at-least-once: a crash after commit and
      # before the bus call is covered by replay/2, and bus dedup absorbs the duplicate.
      case Jobs.enqueue(conn, "default", job_id, "") do
        {:ok, _} -> mark_enqueued(repo, job_id)
        {:error, reason} -> repo(repo).rollback(reason)
      end
    end)
    |> case do
      {:ok, :ok} -> {:ok, job_id}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def record(repo, job_id, name_id, version) do
    %Intent{}
    |> Intent.changeset(%{job_id: job_id, name_id: name_id, version: version, enqueued: false})
    |> repo(repo).insert(on_conflict: :nothing, conflict_target: :job_id)

    :ok
  end

  @impl true
  def mark_enqueued(repo, job_id) do
    from(i in Intent, where: i.job_id == ^job_id) |> repo(repo).update_all(set: [enqueued: true])
    :ok
  end

  @impl true
  def record_many(repo, triples) do
    rows =
      Enum.map(triples, fn {job_id, name_id, version} ->
        %{job_id: job_id, name_id: name_id, version: version, enqueued: false,
          recorded_at: DateTime.utc_now()}
      end)

    repo(repo).insert_all(Intent, rows, on_conflict: :nothing, conflict_target: :job_id)
    :ok
  end

  @impl true
  def replay(repo, conn) do
    not_covered = from(i in Intent, where: i.enqueued == false, order_by: [asc: i.id])

    n =
      repo(repo).all(not_covered)
      |> Enum.reduce(0, fn i, acc ->
        case Jobs.enqueue(conn, "default", i.job_id, "") do
          {:ok, _} -> mark_enqueued(repo, i.job_id) && acc + 1
          _ -> acc
        end
      end)

    {:ok, n}
  end

  @impl true
  def compact(repo) do
    {n, _} = from(i in Intent, where: i.enqueued == true) |> repo(repo).delete_all()
    {:ok, n}
  end

  @impl true
  def last_applied(_repo, _name_id), do: nil
  @impl true
  def stats(repo), do: %{intents: repo(repo).aggregate(Intent, :count, :id)}
end
