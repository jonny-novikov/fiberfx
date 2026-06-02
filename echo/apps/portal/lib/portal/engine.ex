defmodule Portal.Engine do
  @moduledoc """
  The boundary between the web layer and the domain.

  The web calls **only** `dispatch/1` (writes) and `query/2` (reads); the
  contexts and store are reached through this GenServer and never directly. F5.3
  makes the boundary real by delegating to the F5.2 contexts; the public surface
  is unchanged from F5.1, so the web layer is insulated from the internal
  rewrites that follow (F5.5 events, F5.6 fold).
  """
  use GenServer

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @doc "Run a write command (e.g. enroll)."
  @spec dispatch(map()) :: {:ok, term()} | {:error, atom()}
  def dispatch(command) when is_map(command), do: GenServer.call(__MODULE__, {:dispatch, command})

  @doc "Run a read query (e.g. :lesson, :courses_of)."
  @spec query(atom(), term()) :: {:ok, term()} | :error | [term()]
  def query(name, arg) when is_atom(name), do: GenServer.call(__MODULE__, {:query, name, arg})

  @impl true
  def init(:ok), do: {:ok, %{}}

  @impl true
  def handle_call({:dispatch, command}, _from, state) do
    {:reply, dispatch_command(command), state}
  end

  def handle_call({:query, name, arg}, _from, state) do
    {:reply, run_query(name, arg), state}
  end

  defp dispatch_command(%{type: :enroll, user_id: user_id, course_id: course_id}) do
    Portal.Learning.enroll(user_id, course_id)
  end

  defp dispatch_command(_command), do: {:error, :unknown_command}

  defp run_query(:lesson, id), do: Portal.Catalog.lesson(id)
  defp run_query(:courses_of, user_id), do: Portal.Learning.courses_of(user_id)
  defp run_query(_name, _arg), do: {:error, :unknown_query}
end
