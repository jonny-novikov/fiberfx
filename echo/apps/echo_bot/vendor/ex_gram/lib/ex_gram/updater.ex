defmodule ExGram.Updater do
  @moduledoc """
  The updater shape — the vendored long-poll loop and its `:noup` no-op analog.

  Vendored from ex_gram (github.com/rockneurotiko/ex_gram) as owned source; see
  `vendor/ex_gram/README.md`. ex_gram's updater methods are `:polling`, `:webhook`, and
  `:noup` (a no-op updates source for tests). F10.1 carries two: `ExGram.Updater.Polling`
  (long-poll `getUpdates`, decode, hand each `Update` to a sink) and `ExGram.Updater.Noup`
  (the no-op source — no live Telegram, the fake-updater test posture). Webhook is F10.5.

  Both are reached ONLY through `EchoBot.Platform.Telegram` (F10.1-INV4). The "sink" is an
  injected 1-arity function the adapter supplies, so the updater carries no engine-core
  type — the wrap, not the copy, holds the boundary.
  """

  defmodule Polling do
    @moduledoc """
    A long-poll updater process. Loops `getUpdates` with the running offset, decodes each
    raw map to an `ExGram.Model.Update`, and calls the injected `sink` with it. A consumed
    update advances the offset, so Telegram does not re-deliver it.
    """

    use GenServer

    alias ExGram.Client
    alias ExGram.Model

    @poll_timeout 30

    @doc """
    Start the polling loop. Required opts: `:token` (the bot token), `:sink` (a 1-arity fn
    invoked per decoded `Update`). `:name` optionally registers the process.
    """
    @spec start_link(keyword()) :: GenServer.on_start()
    def start_link(opts) do
      {name, opts} = Keyword.pop(opts, :name)
      gen_opts = if name, do: [name: name], else: []
      GenServer.start_link(__MODULE__, opts, gen_opts)
    end

    @impl true
    def init(opts) do
      token = Keyword.fetch!(opts, :token)
      sink = Keyword.fetch!(opts, :sink)
      state = %{token: token, sink: sink, offset: nil}
      # Drive the first poll out of init so the process is responsive immediately.
      {:ok, state, {:continue, :poll}}
    end

    @impl true
    def handle_continue(:poll, state), do: poll(state)

    @impl true
    def handle_info(:poll, state), do: poll(state)

    defp poll(state) do
      opts = [timeout: @poll_timeout]
      opts = if state.offset, do: Keyword.put(opts, :offset, state.offset), else: opts

      case Client.get_updates(state.token, opts) do
        {:ok, raw_updates} ->
          next_offset = dispatch(raw_updates, state)
          send(self(), :poll)
          {:noreply, %{state | offset: next_offset}}

        {:error, _reason} ->
          # On a transient transport error, back off briefly then resume; the supervisor
          # restarts only a crash, not a recoverable poll error.
          Process.send_after(self(), :poll, 1_000)
          {:noreply, state}
      end
    end

    # Hand each decoded update to the sink and compute the next offset (highest seen + 1).
    defp dispatch([], state), do: state.offset

    defp dispatch(raw_updates, state) do
      Enum.reduce(raw_updates, state.offset, fn raw, _acc ->
        update = Model.decode_update(raw)
        state.sink.(update)
        update.update_id + 1
      end)
    end
  end

  defmodule Noup do
    @moduledoc """
    The no-op updates source — ex_gram's `:noup` analog. Holds the injected `sink` and
    contacts no Telegram; tests inject updates by calling `deliver/2` directly, so the same
    handler code runs with no live platform (F10.1-INV6).
    """

    use GenServer

    @doc "Start the no-op updater. Required opt: `:sink` (a 1-arity fn). `:name` optional."
    @spec start_link(keyword()) :: GenServer.on_start()
    def start_link(opts) do
      {name, opts} = Keyword.pop(opts, :name)
      gen_opts = if name, do: [name: name], else: []
      GenServer.start_link(__MODULE__, opts, gen_opts)
    end

    @doc """
    Feed one constructed `ExGram.Model.Update` through the updater's sink — the test entry
    point standing in for a live `getUpdates` delivery. Synchronous so the reply is rendered
    before the call returns.
    """
    @spec deliver(GenServer.server(), ExGram.Model.Update.t()) :: term()
    def deliver(server, update), do: GenServer.call(server, {:deliver, update})

    @impl true
    def init(opts) do
      sink = Keyword.fetch!(opts, :sink)
      {:ok, %{sink: sink}}
    end

    @impl true
    def handle_call({:deliver, update}, _from, state) do
      {:reply, state.sink.(update), state}
    end
  end
end
