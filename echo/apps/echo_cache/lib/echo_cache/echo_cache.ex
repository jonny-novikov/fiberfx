defmodule EchoCache do
  @moduledoc """
  The declared near-cache layer: L1 ETS tables in front of the L2 Valkey
  the systems already share. Part IV's first law — the cache is declared,
  not discovered — lives here: every table registers its full specification
  in the directory at start, the operator enumerates every cache in the
  node with `tables/0`, and a cache absent from the directory does not
  exist. The directory monitors its tables, so a crashed cache leaves the
  roster the moment it leaves the node.
  """

  @directory :echo_cache_directory

  @doc "Every declared cache on this node, as `{name, spec}` pairs."
  @spec tables() :: [{atom(), map()}]
  def tables do
    case :ets.whereis(@directory) do
      :undefined -> []
      _ -> :ets.tab2list(@directory) |> Enum.sort()
    end
  end

  @doc "The declared specification of one cache, or :error."
  @spec spec(atom()) :: {:ok, map()} | :error
  def spec(name) when is_atom(name) do
    case :ets.whereis(@directory) do
      :undefined ->
        :error

      _ ->
        case :ets.lookup(@directory, name) do
          [{^name, spec}] -> {:ok, spec}
          [] -> :error
        end
    end
  end

  @doc false
  def directory_table, do: @directory

  defmodule Directory do
    @moduledoc false
    use GenServer

    def ensure do
      case Process.whereis(__MODULE__) do
        nil ->
          case GenServer.start(__MODULE__, :ok, name: __MODULE__) do
            {:ok, pid} -> {:ok, pid}
            {:error, {:already_started, pid}} -> {:ok, pid}
          end

        pid ->
          {:ok, pid}
      end
    end

    def register(name, spec, owner) do
      {:ok, _} = ensure()
      GenServer.call(__MODULE__, {:register, name, spec, owner})
    end

    def unregister(name) do
      case Process.whereis(__MODULE__) do
        nil -> :ok
        _ -> GenServer.call(__MODULE__, {:unregister, name})
      end
    end

    @impl true
    def init(:ok) do
      :ets.new(EchoCache.directory_table(), [
        :set,
        :public,
        :named_table,
        read_concurrency: true
      ])

      {:ok, %{monitors: %{}}}
    end

    @impl true
    def handle_call({:register, name, spec, owner}, _from, state) do
      ref = Process.monitor(owner)
      :ets.insert(EchoCache.directory_table(), {name, spec})
      {:reply, :ok, %{state | monitors: Map.put(state.monitors, ref, name)}}
    end

    def handle_call({:unregister, name}, _from, state) do
      :ets.delete(EchoCache.directory_table(), name)
      {:reply, :ok, state}
    end

    @impl true
    def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
      {name, monitors} = Map.pop(state.monitors, ref)
      if name, do: :ets.delete(EchoCache.directory_table(), name)
      {:noreply, %{state | monitors: monitors}}
    end
  end
end
