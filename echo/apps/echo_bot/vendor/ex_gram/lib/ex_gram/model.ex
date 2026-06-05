defmodule ExGram.Model do
  @moduledoc """
  The Telegram update/message shapes and their decoders — the minimal vendored subset.

  Vendored from ex_gram (github.com/rockneurotiko/ex_gram) as owned source; see
  `vendor/ex_gram/README.md`. Only the fields F10.1 routes on are carried — the update
  envelope, the message, the chat, and the sender. The full upstream model module is
  auto-generated from the Bot API; this is a hand-narrowed slice.

  Reached ONLY through `EchoBot.Platform.Telegram` (F10.1-INV4).
  """

  defmodule Chat do
    @moduledoc "A Telegram chat — the reply target."
    @enforce_keys [:id]
    defstruct [:id, :type, :title, :username]

    @type t :: %__MODULE__{
            id: integer(),
            type: String.t() | nil,
            title: String.t() | nil,
            username: String.t() | nil
          }
  end

  defmodule User do
    @moduledoc "A Telegram user — the message sender."
    @enforce_keys [:id]
    defstruct [:id, :is_bot, :first_name, :username]

    @type t :: %__MODULE__{
            id: integer(),
            is_bot: boolean() | nil,
            first_name: String.t() | nil,
            username: String.t() | nil
          }
  end

  defmodule Message do
    @moduledoc "A Telegram message — `text` carries the command line."
    @enforce_keys [:message_id, :chat]
    defstruct [:message_id, :chat, :from, :text, :date]

    @type t :: %__MODULE__{
            message_id: integer(),
            chat: Chat.t(),
            from: User.t() | nil,
            text: String.t() | nil,
            date: integer() | nil
          }
  end

  defmodule Update do
    @moduledoc """
    A Telegram update envelope. `update_id` is the idempotency key Telegram may resend;
    `message` carries the routed command at F10.1.
    """
    @enforce_keys [:update_id]
    defstruct [:update_id, :message]

    @type t :: %__MODULE__{update_id: integer(), message: Message.t() | nil}
  end

  @doc """
  Decode one raw `getUpdates` map into an `Update` struct. Unknown fields are dropped;
  a `message`-less update decodes with `message: nil`.
  """
  @spec decode_update(map()) :: Update.t()
  def decode_update(%{"update_id" => update_id} = raw) do
    %Update{
      update_id: update_id,
      message: decode_message(Map.get(raw, "message"))
    }
  end

  @doc "Decode a raw message map (or `nil`) into a `Message` struct (or `nil`)."
  @spec decode_message(map() | nil) :: Message.t() | nil
  def decode_message(nil), do: nil

  def decode_message(%{"message_id" => message_id, "chat" => chat} = raw) do
    %Message{
      message_id: message_id,
      chat: decode_chat(chat),
      from: decode_user(Map.get(raw, "from")),
      text: Map.get(raw, "text"),
      date: Map.get(raw, "date")
    }
  end

  @doc "Decode a raw chat map into a `Chat` struct."
  @spec decode_chat(map()) :: Chat.t()
  def decode_chat(%{"id" => id} = raw) do
    %Chat{
      id: id,
      type: Map.get(raw, "type"),
      title: Map.get(raw, "title"),
      username: Map.get(raw, "username")
    }
  end

  @doc "Decode a raw user map (or `nil`) into a `User` struct (or `nil`)."
  @spec decode_user(map() | nil) :: User.t() | nil
  def decode_user(nil), do: nil

  def decode_user(%{"id" => id} = raw) do
    %User{
      id: id,
      is_bot: Map.get(raw, "is_bot"),
      first_name: Map.get(raw, "first_name"),
      username: Map.get(raw, "username")
    }
  end
end
