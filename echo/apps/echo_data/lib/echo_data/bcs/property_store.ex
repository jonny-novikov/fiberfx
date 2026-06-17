defmodule EchoData.Bcs.PropertyStore do
  @moduledoc """
  A BCS system in skeleton: a GenServer owning one private ordered_set
  property table keyed by the 14-byte branded string. Rung bcs1.1.
  """

  use GenServer

  alias EchoData.{BrandedId, Bcs}

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    ns = Keyword.fetch!(opts, :namespace)
    GenServer.start_link(__MODULE__, ns, name: name)
  end

  def put(store, id, value) when is_binary(id), do: GenServer.call(store, {:put, id, value})

  def get(store, id) when is_binary(id), do: GenServer.call(store, {:get, id})

  def page_desc(store, n) when is_integer(n) and n > 0,
    do: GenServer.call(store, {:page_desc, n})

  def record_entity(store, id) when is_binary(id), do: GenServer.cast(store, {:entity, id})

  @doc """
  Ascending ids in [lo, hi) — Chapter 1.5's synthetic cursors landed on the
  ordered_set. Bounds are branded ids (synthetic via min_for or real) and are
  gated like any ingress. Added by the Chapter 2.2 architecture review.
  """
  def window(store, lo, hi) when is_binary(lo) and is_binary(hi),
    do: GenServer.call(store, {:window, lo, hi})

  @spec placement(binary()) :: {:ok, non_neg_integer()} | {:error, :invalid}
  def placement(id) when is_binary(id) do
    case BrandedId.parse(id) do
      {:ok, _ns, snow} -> {:ok, BrandedId.hash32(snow)}
      :error -> {:error, :invalid}
    end
  end

  @impl true
  def init(ns) do
    {:ok, _mode} = BrandedId.self_check!()
    table = :ets.new(:bcs_props, [:ordered_set, :private])
    {:ok, %{ns: ns, table: table}}
  end

  @impl true
  def handle_call({:put, id, value}, _from, s) do
    case Bcs.gate(id, s.ns) do
      {:ok, _snow} ->
        :ets.insert(s.table, {id, value})
        {:reply, :ok, s}

      {:error, _} = err ->
        {:reply, err, s}
    end
  end

  def handle_call({:get, id}, _from, s) do
    case Bcs.gate(id, s.ns) do
      {:ok, _snow} ->
        case :ets.lookup(s.table, id) do
          [{^id, value}] -> {:reply, {:ok, value}, s}
          [] -> {:reply, {:error, :not_found}, s}
        end

      {:error, _} = err ->
        {:reply, err, s}
    end
  end

  def handle_call({:window, lo, hi}, _from, s) do
    with {:ok, _} <- EchoData.Bcs.gate(lo, s.ns),
         {:ok, _} <- EchoData.Bcs.gate(hi, s.ns) do
      spec = [{{:"$1", :_}, [{:>=, :"$1", {:const, lo}}, {:<, :"$1", {:const, hi}}], [:"$1"]}]
      {:reply, {:ok, :ets.select(s.table, spec)}, s}
    else
      {:error, _} = err -> {:reply, err, s}
    end
  end

  def handle_call({:page_desc, n}, _from, s) do
    {:reply, {:ok, walk_desc(s.table, :ets.last(s.table), n)}, s}
  end

  @impl true
  def handle_cast({:entity, id}, s) do
    case Bcs.gate(id, s.ns) do
      {:ok, _snow} -> :ets.insert(s.table, {id, true})
      {:error, _} -> :ok
    end

    {:noreply, s}
  end

  defp walk_desc(_table, :"$end_of_table", _n), do: []
  defp walk_desc(_table, _key, 0), do: []

  defp walk_desc(table, key, n),
    do: [key | walk_desc(table, :ets.prev(table, key), n - 1)]
end
