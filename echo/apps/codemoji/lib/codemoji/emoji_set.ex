defmodule Codemoji.EmojiSet do
  @moduledoc """
  An emoji set is a sprite grid, not Unicode. An "emoji" is a code: its cell index
  on the set's sprite (`0..count-1`). A round draws its secret — six distinct
  codes — from one set, so the keyboard a player taps and the secret they chase
  are indices into the same `EMS` component. A set is immutable for a round's
  life, which is why the read-hot cache can hold it under the round's own version.
  """
  alias EchoData.BrandedId

  @code_length 6

  @enforce_keys [:id, :category, :cols, :rows]
  defstruct [:id, :category, :cols, :rows, :sprite]

  @type code :: non_neg_integer()
  @type t :: %__MODULE__{
          id: BrandedId.t(),
          category: binary(),
          cols: pos_integer(),
          rows: pos_integer(),
          sprite: binary() | nil
        }

  @doc "Mint a new emoji set (`EMS`). `sprite` is the sprite asset reference."
  @spec new(binary(), pos_integer(), pos_integer(), binary() | nil) :: t
  def new(category, cols, rows, sprite \\ nil) when cols > 0 and rows > 0 do
    %__MODULE__{id: BrandedId.generate!("EMS"), category: category, cols: cols, rows: rows, sprite: sprite}
  end

  @doc "Number of selectable cells."
  @spec count(t) :: pos_integer()
  def count(%__MODULE__{cols: c, rows: r}), do: c * r

  @doc "Every code, `0..count-1` — the round's keyboard."
  @spec codes(t) :: [code()]
  def codes(%__MODULE__{} = set), do: Enum.to_list(0..(count(set) - 1))

  @doc "Is `code` a cell of this set?"
  @spec valid_code?(t, term()) :: boolean()
  def valid_code?(%__MODULE__{} = set, code) when is_integer(code), do: code >= 0 and code < count(set)
  def valid_code?(_, _), do: false

  @doc "Draw a secret: six distinct codes (unique, as the rules require)."
  @spec secret(t) :: [code()]
  def secret(%__MODULE__{} = set), do: set |> codes() |> Enum.take_random(@code_length)

  @doc "A well-formed secret: six codes, all valid, all distinct."
  @spec valid_secret?(t, [code()]) :: boolean()
  def valid_secret?(%__MODULE__{} = set, secret) do
    length(secret) == @code_length and Enum.all?(secret, &valid_code?(set, &1)) and Enum.uniq(secret) == secret
  end

  @doc "A well-formed guess: six codes, all valid (a guess may repeat a code)."
  @spec valid_guess?(t, [code()]) :: boolean()
  def valid_guess?(%__MODULE__{} = set, guess) do
    length(guess) == @code_length and Enum.all?(guess, &valid_code?(set, &1))
  end

  def code_length, do: @code_length
end
