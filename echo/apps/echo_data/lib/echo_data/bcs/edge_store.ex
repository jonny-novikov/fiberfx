defmodule EchoData.Bcs.EdgeStore do
  @moduledoc """
  A relation as a system: one owning process, one kind of edge, both ends
  gated. *Portfolio holds asset* is a row keyed by the tuple of names --
  `{subject, object}` -- never an id list embedded in either endpoint.
  The store owns its own indexes: a forward table for traversal from the
  subject and a reverse table for traversal from the object, maintained
  together by the single owner, exported to nobody. Chapter 2.5.
  """

  use GenServer

  alias EchoData.{Bcs, BrandedId}

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Creates or updates the edge subject->object with the given props."
  def link(store, subj, obj, props \\ %{}) when is_binary(subj) and is_binary(obj),
    do: GenServer.call(store, {:link, subj, obj, props})

  @doc "Removes the edge in both directions."
  def unlink(store, subj, obj) when is_binary(subj) and is_binary(obj),
    do: GenServer.call(store, {:unlink, subj, obj})

  @doc "The edge's props, if it exists."
  def props(store, subj, obj) when is_binary(subj) and is_binary(obj),
    do: GenServer.call(store, {:props, subj, obj})

  @doc "Forward traversal: `{object, props}` ascending by object, optionally limited."
  def from(store, subj, limit \\ :all) when is_binary(subj),
    do: GenServer.call(store, {:from, subj, limit})

  @doc "Reverse traversal: `{subject, props}` ascending by subject, optionally limited."
  def to(store, obj, limit \\ :all) when is_binary(obj),
    do: GenServer.call(store, {:to, obj, limit})

  @doc "Forward edge count for a subject."
  def degree(store, subj) when is_binary(subj),
    do: GenServer.call(store, {:degree, subj})

  @impl true
  def init(opts) do
    {:ok, _mode} = BrandedId.self_check!()

    {:ok,
     %{
       relation: Keyword.fetch!(opts, :relation),
       subject_ns: Keyword.fetch!(opts, :subject_ns),
       object_ns: Keyword.fetch!(opts, :object_ns),
       fwd: :ets.new(:edges_fwd, [:ordered_set, :private]),
       rev: :ets.new(:edges_rev, [:ordered_set, :private])
     }}
  end

  @impl true
  def handle_call({:link, s, o, p}, _from, st) do
    with {:ok, _} <- Bcs.gate(s, st.subject_ns),
         {:ok, _} <- Bcs.gate(o, st.object_ns) do
      :ets.insert(st.fwd, {{s, o}, p})
      :ets.insert(st.rev, {{o, s}, p})
      {:reply, :ok, st}
    else
      {:error, _} = err -> {:reply, err, st}
    end
  end

  def handle_call({:unlink, s, o}, _from, st) do
    with {:ok, _} <- Bcs.gate(s, st.subject_ns),
         {:ok, _} <- Bcs.gate(o, st.object_ns) do
      if :ets.member(st.fwd, {s, o}) do
        :ets.delete(st.fwd, {s, o})
        :ets.delete(st.rev, {o, s})
        {:reply, :ok, st}
      else
        {:reply, {:error, :not_found}, st}
      end
    else
      {:error, _} = err -> {:reply, err, st}
    end
  end

  def handle_call({:props, s, o}, _from, st) do
    with {:ok, _} <- Bcs.gate(s, st.subject_ns),
         {:ok, _} <- Bcs.gate(o, st.object_ns) do
      case :ets.lookup(st.fwd, {s, o}) do
        [{_, p}] -> {:reply, {:ok, p}, st}
        [] -> {:reply, {:error, :not_found}, st}
      end
    else
      {:error, _} = err -> {:reply, err, st}
    end
  end

  def handle_call({:from, s, limit}, _from, st) do
    with {:ok, _} <- Bcs.gate(s, st.subject_ns) do
      spec = [{{{s, :"$1"}, :"$2"}, [], [{{:"$1", :"$2"}}]}]
      {:reply, {:ok, take(st.fwd, spec, limit)}, st}
    else
      {:error, _} = err -> {:reply, err, st}
    end
  end

  def handle_call({:to, o, limit}, _from, st) do
    with {:ok, _} <- Bcs.gate(o, st.object_ns) do
      spec = [{{{o, :"$1"}, :"$2"}, [], [{{:"$1", :"$2"}}]}]
      {:reply, {:ok, take(st.rev, spec, limit)}, st}
    else
      {:error, _} = err -> {:reply, err, st}
    end
  end

  def handle_call({:degree, s}, _from, st) do
    with {:ok, _} <- Bcs.gate(s, st.subject_ns) do
      {:reply, {:ok, :ets.select_count(st.fwd, [{{{s, :_}, :_}, [], [true]}])}, st}
    else
      {:error, _} = err -> {:reply, err, st}
    end
  end

  defp take(t, spec, :all), do: :ets.select(t, spec)

  defp take(t, spec, n) when is_integer(n) and n > 0 do
    case :ets.select(t, spec, n) do
      {res, _cont} -> res
      :"$end_of_table" -> []
    end
  end
end
