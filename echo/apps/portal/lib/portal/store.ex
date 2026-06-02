defmodule Portal.Store do
  @moduledoc """
  Minimal in-memory, namespace-partitioned key/value store — the stand-in for the
  F4 branded CHAMP.

  State is `%{namespace => %{branded_id => struct}}`; the public surface
  (`get/2`, `all/2`, `put/1`) is exactly the F4 contract, so the real CHAMP swaps
  in behind it with zero caller changes. GenServer-owned: writes are serialized
  through the mailbox; a stored struct carries its own branded id, whose 3-letter
  prefix selects the partition.

  In-memory ⇒ it empties on restart; durability arrives at F5.6/F5.8.
  """
  use GenServer

  @type kind :: String.t()

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "Fetch a struct by its namespace `kind` (3-letter brand) and branded id."
  @spec get(kind(), String.t()) :: {:ok, struct()} | :error
  def get(kind, id) when is_binary(kind) and is_binary(id) do
    GenServer.call(__MODULE__, {:get, kind, id})
  end

  @doc "List every struct stored under a namespace `kind`."
  @spec all(kind(), keyword()) :: [struct()]
  def all(kind, _opts \\ []) when is_binary(kind) do
    GenServer.call(__MODULE__, {:all, kind})
  end

  @doc "Store a struct under its own branded id (namespace derived from the id)."
  @spec put(struct()) :: :ok
  def put(%{id: id} = struct) when is_binary(id) do
    GenServer.call(__MODULE__, {:put, struct})
  end

  @doc """
  Clear every namespace, returning the store to empty.

  Synchronous, so a caller observes an empty store as soon as the call returns.
  Intended for test isolation (each test starts from `%{}`): the branded
  snowflake sequence resets per process, so without a per-test reset two tests
  minting in the same millisecond can collide on an id (see
  `Portal.EnrollContractTest`).
  """
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:get, kind, id}, _from, state) do
    {:reply, state |> Map.get(kind, %{}) |> Map.fetch(id), state}
  end

  def handle_call({:all, kind}, _from, state) do
    {:reply, state |> Map.get(kind, %{}) |> Map.values(), state}
  end

  def handle_call({:put, %{id: id} = struct}, _from, state) do
    kind = Portal.ID.namespace(id)
    {:reply, :ok, Map.update(state, kind, %{id => struct}, &Map.put(&1, id, struct))}
  end

  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{}}
  end
end
