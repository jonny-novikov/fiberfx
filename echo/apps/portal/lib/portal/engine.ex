defmodule Portal.Engine do
  @moduledoc """
  The boundary between the web layer and the domain.

  The web calls **only** `dispatch/1` (writes) and `query/2` (reads); everything
  below — contexts, the store — is reached through this GenServer and never
  directly. F5.1 stubs both calls with `{:error, :not_implemented}`; F5.3 makes
  them real by delegating to the F5.2 domain. The public surface
  (`dispatch/1`, `query/2`) is stable across every rung, so the web layer is
  insulated from the internal rewrites that follow (F5.5 events, F5.6 fold).
  """
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc "Run a write command. F5.1: stubbed."
  @spec dispatch(map()) :: {:ok, term()} | {:error, atom()}
  def dispatch(command) when is_map(command) do
    GenServer.call(__MODULE__, {:dispatch, command})
  end

  @doc "Run a read query. F5.1: stubbed."
  @spec query(atom(), term()) :: {:ok, term()} | {:error, atom()}
  def query(name, arg) when is_atom(name) do
    GenServer.call(__MODULE__, {:query, name, arg})
  end

  @impl true
  def init(:ok), do: {:ok, %{}}

  @impl true
  def handle_call({:dispatch, _command}, _from, state) do
    {:reply, {:error, :not_implemented}, state}
  end

  def handle_call({:query, _name, _arg}, _from, state) do
    {:reply, {:error, :not_implemented}, state}
  end
end
