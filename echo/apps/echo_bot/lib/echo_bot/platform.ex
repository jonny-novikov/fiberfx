defmodule EchoBot.Platform do
  @moduledoc """
  The platform-adapter behaviour — the engine's only platform surface (F10.1-INV3).

  The engine core names THIS behaviour, never a concrete platform. A platform (Telegram is
  adapter #1) is a module implementing these callbacks; the YAML's `platform` field selects
  one, so adding a second platform later is implementing this behaviour, not editing the core.
  No Telegram-only type or call appears here or in the core.

  ## The platform surface

  - `child_spec/1` — the updater child the engine supervises. The updater delivers each inbound
    update to the bot's `route` (the injected sink), and is selectable per environment: a live
    polling updater for dev, a fake (no-op) updates source for tests (`:fake` mode), so the same
    handler code runs with no live platform (F10.1-INV6).
  - `send_reply/3` — send one reply (`text`) to the `chat_ref` an update names, used by a handler
    reaching the platform through this behaviour rather than naming the vendored client.
  - `command/1` and `chat_ref/1` — the platform-neutral shape the engine routes on: extract the
    command word (e.g. `"start"`) and the reply target from a normalized update.

  ## The normalized update

  An adapter decodes its platform's raw update into the engine-neutral
  `EchoBot.Platform.Update` struct (`command`, `args`, `text`, `chat_ref`, `update_id`), so the
  handler/router and the engine core hold no platform-specific type.
  """

  @typedoc "The platform-neutral update the engine routes on."
  @type update :: EchoBot.Platform.Update.t()

  @typedoc "An opaque, platform-specific reply target carried on the update."
  @type chat_ref :: term()

  @doc """
  The supervisable updater child for a bot. `opts` carries at least `:token`, `:sink` (the
  1-arity routing function), `:mode` (`:polling` | `:fake`), and `:name`.
  """
  @callback child_spec(opts :: keyword()) :: Supervisor.child_spec()

  @doc "Send one reply `text` to `chat_ref`, using `token`. Returns `:ok` or `{:error, term}`."
  @callback send_reply(token :: String.t(), chat_ref :: chat_ref(), text :: String.t()) ::
              :ok | {:error, term()}

  @doc "The command word a normalized update carries (e.g. `\"start\"`), or `nil`."
  @callback command(update :: update()) :: String.t() | nil

  @doc "The reply target a normalized update names."
  @callback chat_ref(update :: update()) :: chat_ref()
end
