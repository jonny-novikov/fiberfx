defmodule Codemoji.EmojiSet do
  @moduledoc """
  An emoji set is a sprite sheet plus the subset of cells a room exposes. A code
  is `XXYY` — column then row, two digits each — addressing one cell at
  `(-x*cell_size, -y*cell_size)` on the sheet, exactly as the frontend renders it.
  A round draws its secret — six distinct codes — from the set's `codes`, so the
  keyboard a player taps and the secret they chase index the same `EMS` snapshot.
  The set is immutable for a round's life, which is why the read-hot cache holds
  it under the round's own version.
  """
  alias EchoData.BrandedId

  @code_length 6

  @enforce_keys [:id, :name, :cols, :rows, :cell_size, :codes]
  defstruct [:id, :name, :cols, :rows, :cell_size, :sprite_url, :codes]

  @type code :: <<_::32>>
  @type t :: %__MODULE__{
          id: BrandedId.t(),
          name: binary(),
          cols: pos_integer(),
          rows: pos_integer(),
          cell_size: pos_integer(),
          sprite_url: binary() | nil,
          codes: [code()]
        }

  @doc """
  Mint an emoji set (`EMS`). `:codes` is the room's keyboard subset as `XXYY`
  strings; when omitted, every cell of the grid is used.
  """
  def new(name, cols, rows, opts \\ []) when cols > 0 and rows > 0 do
    %__MODULE__{
      id: BrandedId.generate!("EMS"),
      name: name,
      cols: cols,
      rows: rows,
      cell_size: Keyword.get(opts, :cell_size, 144),
      sprite_url: Keyword.get(opts, :sprite_url),
      codes: Keyword.get(opts, :codes) || all_cells(cols, rows)
    }
  end

  @doc ~S|`"0305"` → `{3, 5}` (column, row).|
  def xy(<<x::binary-2, y::binary-2>>), do: {String.to_integer(x), String.to_integer(y)}

  @doc ~S|`{3, 5}` → `"0305"`.|
  def code(x, y) when x >= 0 and y >= 0, do: pad(x) <> pad(y)

  @doc "Background offset in pixels for `code` at this set's cell size."
  def bg_position(%__MODULE__{cell_size: c}, code) do
    {x, y} = xy(code)
    {-x * c, -y * c}
  end

  @doc "Every cell of the grid as `XXYY`, row-major."
  def all_cells(cols, rows), do: for(y <- 0..(rows - 1), x <- 0..(cols - 1), do: code(x, y))

  @doc "Is `code` one of this set's exposed cells?"
  def valid_code?(%__MODULE__{codes: codes}, code), do: code in codes

  @doc "Draw a secret: six distinct codes from the keyboard."
  def secret(%__MODULE__{codes: codes}), do: Enum.take_random(codes, @code_length)

  @doc "A well-formed secret: six codes, all in the set, all distinct."
  def valid_secret?(%__MODULE__{} = set, secret) do
    length(secret) == @code_length and Enum.all?(secret, &valid_code?(set, &1)) and Enum.uniq(secret) == secret
  end

  @doc "A well-formed guess: six codes, all in the set."
  def valid_guess?(%__MODULE__{} = set, guess) do
    length(guess) == @code_length and Enum.all?(guess, &valid_code?(set, &1))
  end

  @doc """
  The player-facing snapshot — the keyboard the frontend needs, and nothing the
  secret could leak from: codes, sprite, cell size, grid.
  """
  def snapshot(%__MODULE__{} = set) do
    %{
      codes: set.codes,
      sprite_url: set.sprite_url,
      cell_size: set.cell_size,
      cols: set.cols,
      rows: set.rows,
      count: length(set.codes)
    }
  end

  def code_length, do: @code_length

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")
end
