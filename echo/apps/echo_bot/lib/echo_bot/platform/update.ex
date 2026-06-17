defmodule EchoBot.Platform.Update do
  @moduledoc """
  The platform-neutral update the engine routes on (F10.1-INV3).

  An adapter decodes its platform's raw update into this struct so the handler/router and the
  engine core hold no platform-specific type. `command` is the matched command word (e.g.
  `"start"` for the message text `"/start"`), `update_id` is the idempotency key a platform may
  resend, and `chat_ref` is the opaque reply target the adapter carries through.
  """

  @enforce_keys [:update_id, :chat_ref]
  defstruct [:update_id, :chat_ref, :command, :args, :text]

  @type t :: %__MODULE__{
          update_id: integer(),
          chat_ref: term(),
          command: String.t() | nil,
          args: [String.t()],
          text: String.t() | nil
        }
end
