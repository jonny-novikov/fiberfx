defmodule Portal.EventStore.Postgres do
  @moduledoc """
  The Postgres `Portal.EventStore` adapter (F6.3) — the durable production edge over
  the `:events` table, the counterpart of `Portal.EventStore.InMemory`, interchangeable
  by `config :portal, :event_store` (F5.8-INV4 / F6.3-INV5).

  Implements the exact F5 behaviour — `append/2 :: :ok | {:error, term}` and
  `read_stream/1 :: {:ok, [struct]} | {:error, term}` — so the engine and the
  in-memory adapter are swap-for-swap (the swap is config-only, no caller changes).

  `append/2` writes its event batch ATOMICALLY (F6.3-INV4 / D8): the per-row `:seq`
  is numbered from the current `max(seq)` for the stream and the whole batch goes in
  one `Repo.transaction` + `Repo.insert_all`, so concurrent appends never interleave
  and a mid-batch failure rolls back fully. (In prod the single-writer engine is the
  only appender, so contention is not a runtime hazard — the transaction guarantees
  correctness regardless.) The ONLY module in the persistence layer that names `Repo`
  for the event log.

  Each domain event struct (a `@derive Jason.Encoder` fact) is stored as `:type` =
  its struct module name and `:data` = its JSON round-trip map (the jsonb column);
  `read_stream/1` returns the `%Event{}` rows ordered by `:seq`.
  """
  @behaviour Portal.EventStore

  import Ecto.Query, only: [from: 2]

  alias Portal.EventStore.Event
  alias Portal.Repo

  @impl Portal.EventStore
  def append(stream, events) when is_binary(stream) and is_list(events) do
    Repo.transaction(fn ->
      base = current_max_seq(stream)
      rows = build_rows(stream, events, base)
      {_count, _} = Repo.insert_all(Event, rows)
      :ok
    end)
    |> case do
      {:ok, :ok} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @impl Portal.EventStore
  def read_stream(stream) when is_binary(stream) do
    {:ok, Repo.all(from(e in Event, where: e.stream == ^stream, order_by: e.seq))}
  end

  # The current highest :seq for the stream (0 when empty), read inside the append
  # transaction so the batch numbers monotonically from there.
  defp current_max_seq(stream) do
    Repo.one(from(e in Event, where: e.stream == ^stream, select: coalesce(max(e.seq), 0)))
  end

  # Number the batch from base+1, minting a fresh bigint Snowflake id per row and
  # serializing each event struct to {:type, :data}. :inserted_at is set explicitly
  # because insert_all does not run schema timestamps autogeneration.
  defp build_rows(stream, events, base) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    events
    |> Enum.with_index(base + 1)
    |> Enum.map(fn {event, seq} ->
      %{
        id: EchoData.Snowflake.generate(worker_id: 1),
        stream: stream,
        seq: seq,
        type: to_string(event.__struct__),
        data: event |> Jason.encode!() |> Jason.decode!(),
        inserted_at: now
      }
    end)
  end
end
