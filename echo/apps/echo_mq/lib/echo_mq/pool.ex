defmodule EchoMQ.Pool do
  @moduledoc """
  A fixed pool of pipelined connectors with lock-free round-robin dispatch.
  Each member is already a pipeline, so a small pool multiplies throughput
  without checkout ceremony: callers hit the next member by an atomic
  counter and the member's own FIFO does the rest. One supervisor, N
  connectors, one dispatcher -- the appendix connector, multiplied.
  """

  use Supervisor

  alias EchoMQ.Connector

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    size = Keyword.get(opts, :size, 4)
    conn_opts = Keyword.drop(opts, [:name, :size])

    :persistent_term.put({__MODULE__, name}, {size, :atomics.new(1, [])})

    children =
      for i <- 1..size do
        Supervisor.child_spec(
          {Connector, conn_opts ++ [name: member(name, i), label: member(name, i)]},
          id: {:emq_pool_member, i}
        )
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "The pool's size."
  def size(name) do
    {size, _} = :persistent_term.get({__MODULE__, name})
    size
  end

  @doc "Round-robin command through the next member."
  def command(name, parts, timeout \\ 5_000), do: Connector.command(next(name), parts, timeout)

  @doc "Round-robin pipeline through the next member."
  def pipeline(name, cmds, timeout \\ 5_000), do: Connector.pipeline(next(name), cmds, timeout)

  @doc "Round-robin EVALSHA-first script execution through the next member."
  def eval(name, script, keys, argv, timeout \\ 5_000),
    do: Connector.eval(next(name), script, keys, argv, timeout)

  @doc "Per-member stats, keyed by member name."
  def stats(name) do
    {size, _} = :persistent_term.get({__MODULE__, name})
    Map.new(1..size, fn i -> {member(name, i), Connector.stats(member(name, i))} end)
  end

  defp next(name) do
    {size, at} = :persistent_term.get({__MODULE__, name})
    member(name, rem(:atomics.add_get(at, 1, 1), size) + 1)
  end

  defp member(name, i), do: :"#{name}_#{i}"
end
