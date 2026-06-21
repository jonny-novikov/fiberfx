defmodule EchoMQ.Journal.Memory do
  @moduledoc "An in-memory (ETS) outbox for tests — no infrastructure, no durability."
  @behaviour EchoMQ.Journal.Adapter
  use Agent
  alias EchoMQ.Jobs

  def start_link(opts), do: Agent.start_link(fn -> %{} end, name: opts[:name] || __MODULE__)
  @impl true
  def child_spec(opts), do: %{id: opts[:name] || __MODULE__, start: {__MODULE__, :start_link, [opts]}}

  @impl true
  def intend_and_enqueue(j, conn, name_id, version) do
    job_id = EchoData.BrandedId.generate!("JOB")
    :ok = record(j, job_id, name_id, version)
    {:ok, _} = Jobs.enqueue(conn, "default", job_id, "")
    :ok = mark_enqueued(j, job_id)
    {:ok, job_id}
  end

  @impl true
  def record(j, job_id, name_id, version) do
    Agent.update(j, &Map.put(&1, job_id, {name_id, version, false}))
  end

  @impl true
  def mark_enqueued(j, job_id) do
    Agent.update(j, fn m ->
      case m do
        %{^job_id => {n, v, _}} -> Map.put(m, job_id, {n, v, true})
        _ -> m
      end
    end)
  end

  @impl true
  def record_many(j, triples) do
    Enum.each(triples, fn {id, n, v} -> record(j, id, n, v) end)
  end

  @impl true
  def replay(j, conn) do
    pending = Agent.get(j, fn m -> for {id, {_, _, false}} <- m, do: id end)
    Enum.each(pending, fn id -> Jobs.enqueue(conn, "default", id, ""); mark_enqueued(j, id) end)
    {:ok, length(pending)}
  end

  @impl true
  def compact(j) do
    {kept, n} = Agent.get_and_update(j, fn m ->
      covered = for {id, {_, _, true}} <- m, into: MapSet.new(), do: id
      {{m, MapSet.size(covered)}, Map.drop(m, MapSet.to_list(covered))}
    end)
    _ = kept
    {:ok, n}
  end

  @impl true
  def last_applied(_j, _name_id), do: nil
  @impl true
  def stats(j), do: %{intents: Agent.get(j, &map_size/1)}
end
