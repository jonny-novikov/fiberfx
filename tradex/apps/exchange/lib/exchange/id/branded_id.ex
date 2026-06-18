defmodule Exchange.Id.BrandedId do
  @moduledoc """
  The branded ID contract: `3 x [A-Z]` namespace ++ `base62(snowflake)` padded
  to 11 — 14 bytes, fixed. One module owns the codec; everything else (the
  Gateway, the Decider) calls through here.

  Inlined into `exchange` (pure Elixir) from `EchoData.BrandedId` when the trading
  apps were extracted to their own umbrella. The optional NIF (`EchoData.Native`)
  and the trie-hash helpers (`hash32/1`, the `parse_hash` variant) were dropped —
  the trading slice needs only the codec (parse/encode/namespace) — but the wire
  format is identical to `echo_data`'s, so the brand is the same one the rest of
  the BCS stack would mint and validate.

      iex> Exchange.Id.BrandedId.encode!("USR", 274557032793636864)
      "USR0KHTOWnGLuC"
      iex> Exchange.Id.BrandedId.parse("USR0KHTOWnGLuC")
      {:ok, "USR", 274557032793636864}
  """

  alias Exchange.Id.Base62

  @type t :: <<_::112>>

  defguard is_branded(id) when is_binary(id) and byte_size(id) == 14

  @doc "Parses a branded ID into `{:ok, namespace, snowflake}` or `:error`."
  @spec parse(binary()) :: {:ok, binary(), non_neg_integer()} | :error
  def parse(id) when is_branded(id), do: pure_parse(id)
  def parse(_), do: :error

  @doc "Decodes the snowflake out of a branded ID, or `:error`."
  @spec decode(binary()) :: {:ok, non_neg_integer()} | :error
  def decode(id) do
    with {:ok, _ns, snow} <- parse(id), do: {:ok, snow}
  end

  @spec encode(binary(), non_neg_integer()) :: {:ok, t()} | :error
  def encode(<<_::binary-size(3)>> = ns, snow)
      when is_integer(snow) and snow >= 0 and snow <= 9_223_372_036_854_775_807 do
    if valid_ns?(ns), do: {:ok, ns <> Base62.encode(snow)}, else: :error
  end

  def encode(_, _), do: :error

  def encode!(ns, snow) do
    case encode(ns, snow) do
      {:ok, id} -> id
      :error -> raise ArgumentError, "invalid namespace or snowflake: #{inspect({ns, snow})}"
    end
  end

  @doc "True when `id` is a well-formed branded ID."
  @spec valid?(term()) :: boolean()
  def valid?(id), do: parse(id) != :error

  @doc "The 3-letter namespace of a branded ID."
  @spec namespace(t()) :: binary()
  def namespace(id) when is_branded(id), do: binary_part(id, 0, 3)

  defp valid_ns?(<<a, b, c>>), do: a in ?A..?Z and b in ?A..?Z and c in ?A..?Z

  defp pure_parse(<<ns::binary-size(3), payload::binary-size(11)>>) do
    with true <- valid_ns?(ns),
         {:ok, snow} <- Base62.decode(payload) do
      {:ok, ns, snow}
    else
      _ -> :error
    end
  end
end
