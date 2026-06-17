defmodule EchoBot.Platform.Telegram do
  @moduledoc """
  The Telegram platform adapter — adapter #1 of the `EchoBot.Platform` behaviour.

  This is the **only** module under `apps/echo_bot/lib/` that names a vendored module
  (F10.1-INV4): it wraps the vendored ex_gram copy (`ExGram.Client`, `ExGram.Model`,
  `ExGram.Updater`) and exposes the engine-neutral surface the behaviour defines. The engine
  core reaches the vendored code only through here; later rungs (F10.6) replace the vendored
  internals behind this unchanged wrap.

  The updater is selectable per environment via the `:mode` option: `:polling` boots the live
  long-poll updater (`ExGram.Updater.Polling`); `:fake` boots the no-op source
  (`ExGram.Updater.Noup`, the `:noup` analog) so tests run with no live Telegram (F10.1-INV6).
  """

  @behaviour EchoBot.Platform

  alias EchoBot.Platform.Update, as: PlatformUpdate
  alias ExGram.Client
  alias ExGram.Model
  alias ExGram.Updater

  @doc """
  The supervisable updater child for a Telegram bot. Required opts: `:sink` (the 1-arity routing
  function the updater calls per inbound update), `:name`. `:mode` (default `:polling`) selects
  the updater; `:token` is required for `:polling` (live calls) and ignored for `:fake`.

  The injected `sink` is the engine's routing function over a raw `ExGram.Model.Update`; this
  adapter normalizes the raw update to `EchoBot.Platform.Update` before the sink runs, so the
  engine core never names a vendored type.
  """
  @impl EchoBot.Platform
  def child_spec(opts) do
    mode = Keyword.get(opts, :mode, :polling)
    sink = Keyword.fetch!(opts, :sink)
    name = Keyword.fetch!(opts, :name)

    # The adapter wraps the engine's routing sink so it receives the NORMALIZED, platform-neutral
    # update — the vendored decode happens here, inside the only module that names the copy.
    wrapped_sink = fn %Model.Update{} = raw -> sink.(normalize(raw)) end

    case mode do
      :fake ->
        %{
          id: name,
          start: {Updater.Noup, :start_link, [[sink: wrapped_sink, name: name]]}
        }

      :polling ->
        token = Keyword.fetch!(opts, :token)

        %{
          id: name,
          start: {Updater.Polling, :start_link, [[token: token, sink: wrapped_sink, name: name]]}
        }
    end
  end

  @doc "Send one reply `text` to the Telegram `chat_id`, via the vendored client's `sendMessage`."
  @impl EchoBot.Platform
  def send_reply(token, chat_id, text) do
    case Client.send_message(token, chat_id, text) do
      {:ok, _message} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "The command word the normalized update carries (e.g. `\"start\"`), or `nil`."
  @impl EchoBot.Platform
  def command(%PlatformUpdate{command: command}), do: command

  @doc "The Telegram `chat_id` the normalized update names as its reply target."
  @impl EchoBot.Platform
  def chat_ref(%PlatformUpdate{chat_ref: chat_ref}), do: chat_ref

  @doc """
  Normalize a raw `ExGram.Model.Update` into the platform-neutral `EchoBot.Platform.Update`.
  Parses a leading `/command` from the message text (stripping any `@botname` suffix); a
  message without a command leaves `command: nil`. Public so the fake-updater test posture can
  construct a normalized update from a raw Telegram map (decode → normalize) with no live poll.
  """
  @spec normalize(Model.Update.t()) :: PlatformUpdate.t()
  def normalize(%Model.Update{update_id: update_id, message: message}) do
    {command, args, text, chat_ref} = parse_message(message)

    %PlatformUpdate{
      update_id: update_id,
      chat_ref: chat_ref,
      command: command,
      args: args,
      text: text
    }
  end

  @doc """
  Decode a raw Telegram update map and normalize it in one step — the fake-updater test entry
  point (a constructed JSON-shaped map → a routed `EchoBot.Platform.Update`), wrapping the
  vendored decoder so no test names `ExGram.*` directly.
  """
  @spec decode_and_normalize(map()) :: PlatformUpdate.t()
  def decode_and_normalize(raw_map) when is_map(raw_map) do
    raw_map |> Model.decode_update() |> normalize()
  end

  # A message-less update (e.g. an edited-channel-post placeholder) routes to no command.
  defp parse_message(nil), do: {nil, [], nil, nil}

  defp parse_message(%Model.Message{text: text, chat: %Model.Chat{id: chat_id}}) do
    {command, args} = parse_command(text)
    {command, args, text, chat_id}
  end

  # "/start arg1 arg2" → {"start", ["arg1", "arg2"]}; "/help@bot" → {"help", []}; non-command → nil.
  defp parse_command(nil), do: {nil, []}

  defp parse_command(text) when is_binary(text) do
    case String.split(text, ~r/\s+/, trim: true) do
      ["/" <> word | rest] ->
        command = word |> String.split("@", parts: 2) |> List.first()
        {command, rest}

      _ ->
        {nil, []}
    end
  end
end
