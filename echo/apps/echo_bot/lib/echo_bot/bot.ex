defmodule EchoBot.Bot do
  @moduledoc """
  The bot seam — turns a loaded definition into a supervisable updater child (F10.1-D3/D6).

  `EchoBot.Bot` is engine-core: it names the `EchoBot.Platform` **behaviour**, never a concrete
  platform or a vendored module (F10.1-INV3, INV4). The loaded definition carries the selected
  `adapter` module (chosen from the YAML `platform`); `child_spec/2` asks the adapter for its
  updater child, injecting the routing sink that drives one update through the handler and back
  out as a reply.

  ## The routing sink (pure handler, then send)

  `route/3` runs the handler — a pure function of the update (F10.1-INV7) — to get a reply, then
  sends it through the adapter's `send_reply/3`. A re-delivered update produces the same single
  reply; the only effect is the outbound message, so idempotency holds by the handler's purity.
  `:noreply` (an unmatched update) sends nothing.
  """

  alias EchoBot.Config

  @doc """
  Build the supervisable updater child for a loaded bot definition. `mode` selects the updater
  (`:polling` for dev, `:fake` for tests). The child id/name is `EchoBot.Bot.<bot name>` so the
  supervisor restarts the bot's updater in isolation (F10.1-INV2).
  """
  @spec child_spec(Config.definition(), :polling | :fake) :: Supervisor.child_spec()
  def child_spec(definition, mode) do
    adapter = definition.adapter
    handler = definition.handler
    token = definition.token
    name = process_name(definition)

    sink = fn update -> route(adapter, handler, token, update) end

    adapter.child_spec(mode: mode, token: token, sink: sink, name: name)
  end

  @doc """
  The registered process name for a bot's updater, derived from its name. Test code addresses the
  fake updater through this to feed constructed updates.
  """
  @spec process_name(Config.definition()) :: atom()
  def process_name(definition), do: Module.concat(EchoBot.Bot, normalize_name(definition.name))

  @doc """
  Route one update: run the pure handler, and on `{:reply, text}` send it through the adapter.
  Returns the send result (or `:noreply` when the handler matched nothing). Public so the
  fake-updater test feeds updates straight through this seam.
  """
  @spec route(module(), module(), String.t(), EchoBot.Platform.Update.t()) ::
          :ok | :noreply | {:error, term()}
  def route(adapter, handler, token, update) do
    case handler.handle(update) do
      {:reply, text} ->
        chat_ref = adapter.chat_ref(update)
        adapter.send_reply(token, chat_ref, text)

      :noreply ->
        :noreply
    end
  end

  defp normalize_name(name) do
    name
    |> to_string()
    |> String.replace(~r/[^A-Za-z0-9]+/, "_")
  end
end
