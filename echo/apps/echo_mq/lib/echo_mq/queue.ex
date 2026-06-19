defmodule EchoMQ.Queue do
  @moduledoc """
  Host-wiring for a metronome-coordinated consumer pool. A supervisor that
  starts ONE `EchoMQ.Metronome` (the single blocker + the one beat per queue)
  and N `EchoMQ.Consumer`s wired to it (each opt-in `:metronome`), so a host
  brings up a herd-free, fairly-served pool with one child spec under its own
  supervision tree. The metronome starts first and is registered by name, so a
  consumer resolves it at start.

  Host-started, no `mod:` auto-start (the library law -- `echo_mq` has no OTP
  application callback). The pool is one more opt-in plane: a host that wants a
  pool starts an `EchoMQ.Queue`; a host that wants a lone consumer starts an
  `EchoMQ.Consumer` standalone (no metronome). Modeled on `EchoMQ.Pool`'s
  `use Supervisor` + named-children discipline. emq.4.3.
  """

  use Supervisor

  alias EchoMQ.{Consumer, Metronome}

  @doc """
  Start a metronome-coordinated pool. Options:

    * `:queue` (required) -- the queue all members serve.
    * `:handler` (required) -- the consumer handler fun (the `EchoMQ.Consumer`
      contract: `%{id:, payload:, attempts:, group:}` -> `:ok | {:error, _}`).
    * `:size` -- the consumer count (default 4).
    * `:name` -- the supervisor's registered name (default `__MODULE__`); the
      metronome is registered as `metronome_name(name)`.
    * `:connector` -- connector options each member (the metronome + every
      consumer) uses to self-start its own dedicated lane (the blocking-verb
      discipline -- each process owns its connector).
    * `:beat_ms`, `:pump_batch` -- forwarded to the metronome (the one beat).
    * `:lease_ms`, `:retry_delay_ms`, `:max_attempts` -- forwarded to each
      consumer (the claim/settle policy).
  """
  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  A child spec for the host's supervision tree: a `:permanent` supervisor, so
  the whole pool restarts whole. The `:id` defaults to the registered name, so
  several pools (different queues) can sit side by side under one host
  supervisor.
  """
  def child_spec(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    %{
      id: Keyword.get(opts, :id, name),
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor,
      restart: :permanent,
      shutdown: :infinity
    }
  end

  @doc "The registered name of this pool's metronome (given the pool's name)."
  def metronome_name(pool_name \\ __MODULE__), do: :"#{pool_name}_metronome"

  @impl true
  def init(opts) do
    queue = Keyword.fetch!(opts, :queue)
    handler = Keyword.fetch!(opts, :handler)
    name = Keyword.get(opts, :name, __MODULE__)
    size = Keyword.get(opts, :size, 4)
    connector = Keyword.fetch!(opts, :connector)
    metronome = metronome_name(name)

    metronome_opts =
      [queue: queue, name: metronome, connector: connector]
      |> put_present(opts, :beat_ms)
      |> put_present(opts, :pump_batch)

    consumer_base =
      [queue: queue, handler: handler, metronome: metronome, connector: connector]
      |> put_present(opts, :lease_ms)
      |> put_present(opts, :beat_ms)
      |> put_present(opts, :retry_delay_ms)
      |> put_present(opts, :max_attempts)

    # the metronome first (its name must exist when a consumer registers), then
    # the N consumers -- each opt-in `:metronome`, each its own lane.
    metronome_child = Supervisor.child_spec({Metronome, metronome_opts}, id: :emq_metronome)

    consumer_children =
      for i <- 1..size do
        Supervisor.child_spec(
          {Consumer, Keyword.put(consumer_base, :id, {:emq_consumer, i})},
          id: {:emq_consumer, i}
        )
      end

    # rest_for_one: if the metronome restarts, the consumers (which hold its
    # name as their coordinator) restart after it and re-register cleanly; a
    # consumer crash restarts only that consumer.
    Supervisor.init([metronome_child | consumer_children], strategy: :rest_for_one)
  end

  # Forward an option to a child's opts only when the host set it, so each
  # child's own default (Consumer/Metronome) applies otherwise -- no default is
  # duplicated here.
  defp put_present(child_opts, opts, key) do
    case Keyword.fetch(opts, key) do
      {:ok, value} -> Keyword.put(child_opts, key, value)
      :error -> child_opts
    end
  end
end
