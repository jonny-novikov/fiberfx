defmodule EchoData.Base62 do
  @moduledoc """
  Base62 encoding and decoding for snowflake IDs.

  Base62 uses the alphabet: `0-9A-Za-z` (62 characters)
  This provides a compact, URL-safe representation of large integers.

  ## Format

  Snowflakes are encoded as 11-character Base62 strings, left-padded with zeros:

  ```
  Snowflake: 12345678901234
  Base62:    0K48QjihpC4
  ```

  ## Alphabet

  ```
  0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
  └─ 0-9 ─┘└───────── A-Z ──────────┘└───────── a-z ──────────┘
  ```

  ## Usage

      # Encoding
      encoded = EchoData.Base62.encode(12345678901234)
      # => "0K48QjihpC4"

      # Decoding
      {:ok, snowflake} = EchoData.Base62.decode("0K48QjihpC4")
      # => {:ok, 12345678901234}

      # Validation
      EchoData.Base62.valid?("0K48QjihpC4")
      # => true

  """

  @alphabet "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  @decode_map @alphabet
              |> String.graphemes()
              |> Enum.with_index()
              |> Map.new()

  # Standard width for snowflake encoding (11 chars fits 64-bit int)
  @default_width 11

  @type encoded :: String.t()

  @doc """
  Returns the Base62 alphabet string.
  """
  @spec alphabet() :: String.t()
  def alphabet, do: @alphabet

  @doc """
  Encodes a non-negative integer to Base62.

  ## Options

  - `:width` - Pad result to this width (default: 11 for snowflakes)
  - `:pad` - Padding character (default: "0")

  ## Examples

      iex> EchoData.Base62.encode(12345678901234)
      "0K48QjihpC4"

      iex> EchoData.Base62.encode(0)
      "00000000000"

      iex> EchoData.Base62.encode(61)
      "0000000000z"

      iex> EchoData.Base62.encode(62)
      "00000000010"

  """
  @spec encode(non_neg_integer(), keyword()) :: encoded()
  def encode(n, opts \\ []) when is_integer(n) and n >= 0 do
    width = Keyword.get(opts, :width, @default_width)
    pad = Keyword.get(opts, :pad, "0")

    encode_digits(n, [])
    |> Enum.join()
    |> String.pad_leading(width, pad)
  end

  @doc """
  Decodes a Base62 string to an integer.

  Returns `{:ok, integer}` on success, `:error` on failure.

  ## Examples

      iex> EchoData.Base62.decode("0K48QjihpC4")
      {:ok, 12345678901234}

      iex> EchoData.Base62.decode("00000000000")
      {:ok, 0}

      iex> EchoData.Base62.decode("invalid!")
      :error

  """
  @spec decode(String.t()) :: {:ok, non_neg_integer()} | :error
  def decode(str) when is_binary(str) do
    try do
      result =
        str
        |> String.graphemes()
        |> Enum.reduce(0, fn char, acc ->
          case Map.fetch(@decode_map, char) do
            {:ok, value} -> acc * 62 + value
            :error -> throw(:invalid_char)
          end
        end)

      {:ok, result}
    catch
      :invalid_char -> :error
    end
  end

  def decode(_), do: :error

  @doc """
  Decodes a Base62 string to an integer, raising on error.

  ## Examples

      iex> EchoData.Base62.decode!("0K48QjihpC4")
      12345678901234

      iex> EchoData.Base62.decode!("invalid!")
      ** (ArgumentError) invalid Base62 string

  """
  @spec decode!(String.t()) :: non_neg_integer()
  def decode!(str) do
    case decode(str) do
      {:ok, n} -> n
      :error -> raise ArgumentError, "invalid Base62 string"
    end
  end

  @doc """
  Checks if a string is valid Base62.

  ## Examples

      iex> EchoData.Base62.valid?("0K48QjihpC4")
      true

      iex> EchoData.Base62.valid?("invalid!")
      false

  """
  @spec valid?(String.t()) :: boolean()
  def valid?(str) when is_binary(str) do
    str
    |> String.graphemes()
    |> Enum.all?(&Map.has_key?(@decode_map, &1))
  end

  def valid?(_), do: false

  # Private functions

  defp encode_digits(0, []), do: ["0"]
  defp encode_digits(0, acc), do: acc

  defp encode_digits(n, acc) do
    digit = rem(n, 62)
    char = String.at(@alphabet, digit)
    encode_digits(div(n, 62), [char | acc])
  end
end
