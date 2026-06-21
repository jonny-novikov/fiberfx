defmodule EchoStore.GraftBackend.FeedBlob do
  @moduledoc """
  A minimal, read-only peek into the OPAQUE eg.3 `FeedEvent` bilrost blob (eg.4).

  The change-feed event rides the wire as an opaque bilrost blob by contract — this client
  never re-encodes it and forwards it whole to the subscriber. But to keep its replay cursor
  it needs two fields: the Volume's **branded id** (field 1) and the advancing **LSN**
  (field 3). Rather than depend on a full bilrost decoder, this module reads just those two
  by walking the blob's fields, and is otherwise blind to the event's shape (`log_id`, `ts`,
  any future additive field stay opaque).

  ## bilrost wire (as-built, pinned against the eg.3 fixture)

  A field is `<key-varint><value>`. The key's low 2 bits are the wire type; the high bits are
  a **field-number delta** (bilrost delta-encodes ascending field numbers — NOT absolute, so
  a running counter is advanced by the delta on each key). Wire types used by `FeedEvent`:

    * `0` — varint value (`lsn`, `ts`).
    * `1` — length-delimited: a length varint then that many bytes (`volume_branded_id`,
      `log_id`).

  The `FeedEvent` always emits fields 1..4 in order, so each delta is 1. This reads field 1
  (string) and field 3 (varint) and ignores the rest. An unparseable blob yields `:error`,
  and the caller drops it from the cursor (the opaque forward still happened upstream).
  """

  @wiretype_varint 0
  @wiretype_len 1

  @doc """
  The `{:ok, branded_id, lsn}` carried by a `FeedEvent` blob, or `:error` if the blob does not
  parse or is missing field 1 / field 3.
  """
  @spec branded_and_lsn(binary()) :: {:ok, binary(), non_neg_integer()} | :error
  def branded_and_lsn(blob) when is_binary(blob) do
    case walk(blob, 0, %{}) do
      {:ok, fields} ->
        case {Map.fetch(fields, 1), Map.fetch(fields, 3)} do
          {{:ok, branded}, {:ok, lsn}} when is_binary(branded) and is_integer(lsn) ->
            {:ok, branded, lsn}

          _ ->
            :error
        end

      :error ->
        :error
    end
  end

  def branded_and_lsn(_), do: :error

  # Walk every field, accumulating field_number => value. `field` is the running field number
  # (advanced by the key's delta). Stops cleanly at end of input.
  defp walk(<<>>, _field, acc), do: {:ok, acc}

  defp walk(bin, field, acc) do
    case take_varint(bin) do
      {:ok, key, rest} ->
        wiretype = Bitwise.band(key, 0x03)
        delta = Bitwise.bsr(key, 2)
        field = field + delta
        read_value(wiretype, rest, field, acc)

      :error ->
        :error
    end
  end

  defp read_value(@wiretype_varint, bin, field, acc) do
    case take_varint(bin) do
      {:ok, value, rest} -> walk(rest, field, Map.put(acc, field, value))
      :error -> :error
    end
  end

  defp read_value(@wiretype_len, bin, field, acc) do
    with {:ok, len, rest} <- take_varint(bin),
         <<data::binary-size(len), rest2::binary>> <- rest do
      walk(rest2, field, Map.put(acc, field, data))
    else
      _ -> :error
    end
  end

  # An unknown wire type (2 = fixed-32, 3 = fixed-64 in some encoders) is not used by
  # FeedEvent; treat as unparseable rather than guess.
  defp read_value(_other, _bin, _field, _acc), do: :error

  # A LEB128 unsigned varint: 7 bits per byte, high bit = continuation.
  defp take_varint(bin), do: take_varint(bin, 0, 0)

  defp take_varint(<<byte, rest::binary>>, shift, acc) when byte < 0x80 do
    {:ok, acc + Bitwise.bsl(byte, shift), rest}
  end

  defp take_varint(<<byte, rest::binary>>, shift, acc) when shift < 64 do
    take_varint(rest, shift + 7, acc + Bitwise.bsl(Bitwise.band(byte, 0x7F), shift))
  end

  defp take_varint(_, _, _), do: :error
end
