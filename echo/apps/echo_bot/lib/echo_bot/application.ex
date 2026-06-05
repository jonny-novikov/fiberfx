defmodule EchoBot.Application do
  @moduledoc """
  The standalone engine application (F10.1-INV2). A third umbrella app boots a supervision tree
  here, beside the umbrella's two existing supervised apps, but with **no** dependency on either:
  `EchoBot.Application` names, starts, and touches no other app, so the engine boots whether or not
  the rest of the umbrella is running (F10.1-INV1).

  `start/2` loads the single bot definition from the YAML v1.0 file (the path resolved from
  application config) and supervises the loaded bot's updater under `:one_for_one`,
  `EchoBot.Supervisor`. A bot crash restarts in isolation under this tree and never reaches
  another app's tree. The supervisor keeps the OTP default `max_restarts` — there is no LiveView
  socket pool in this app, so a raised web-specific `max_restarts` does not apply here.

  The updater mode is config-selected (`config :echo_bot, :updater`): `:polling` boots the live
  long-poll updater (dev), `:fake` boots the no-op updates source (test, F10.1-INV6), and `:none`
  (the base default) boots the supervisor with no bot — so a bare `iex -S mix` with no token set
  starts the engine without a live poll. The bot is loaded only for `:polling`/`:fake`.
  """

  use Application

  require Logger

  alias EchoBot.Bot
  alias EchoBot.Config

  @impl true
  def start(_type, _args) do
    children = bot_children(updater_mode())
    Supervisor.start_link(children, strategy: :one_for_one, name: EchoBot.Supervisor)
  end

  # `:none` (base default) → no bot child, the engine app still boots. `:fake` (test) → load and
  # supervise the bot under the no-op updater. `:polling` (dev) → load and supervise the live
  # long-poll updater.
  defp bot_children(:none), do: []

  defp bot_children(:fake) do
    [Bot.child_spec(Config.load!(Config.bot_config_path()), :fake)]
  end

  # In dev polling, a missing/empty token (e.g. a bare `iex -S mix` with the env var unset) is a
  # loud WARNING that starts no bot — not a boot crash — so the engine app still comes up
  # (F10.1-INV1). The live demo sets the real token in `token_env`; the bot then supervises.
  defp bot_children(:polling) do
    case Config.load(Config.bot_config_path()) do
      {:ok, definition} ->
        [Bot.child_spec(definition, :polling)]

      {:error, reason} ->
        Logger.warning(
          "echo_bot polling updater not started: #{inspect(reason)}. " <>
            "Set the bot's token_env environment variable to run the live dev bot."
        )

        []
    end
  end

  defp updater_mode, do: Application.get_env(:echo_bot, :updater, :none)
end
