defmodule EchoMQ.RESP do
  @moduledoc """
  RESP codec for the EchoMQ connector, speaking both generations. Commands
  encode as arrays of bulk strings into iodata (no intermediate
  concatenation); replies parse in one pass over the accumulated buffer with
  `:incomplete` as the continuation signal. Server error replies are values
  (`{:error_reply, msg}`), not failures -- the connector decides their
  severity.

  RESP3 additions parse natively: maps (`%`) to maps, sets (`~`) to
  `MapSet`, doubles (`,`) to floats (with `:infinity`, `:neg_infinity`,
  `:nan`), booleans (`#`), nulls (`_`), big numbers (`(`) to integers,
  verbatim strings (`=`) to binaries with their format prefix stripped, and
  push frames (`>`) to `{:push, [..]}` -- a value the connector routes out
  of band, never into the reply FIFO.
  """

  @crlf "\r\n"

  @spec encode([binary() | integer() | atom() | iodata()]) :: iodata()
  def encode(parts) when is_list(parts) do
    [?*, Integer.to_string(length(parts)), @crlf | Enum.map(parts, &bulk/1)]
  end

  defp bulk(p) when is_binary(p), do: [?$, Integer.to_string(byte_size(p)), @crlf, p, @crlf]
  defp bulk(p) when is_integer(p), do: bulk(Integer.to_string(p))
  defp bulk(p) when is_atom(p), do: bulk(Atom.to_string(p))
  defp bulk(p) when is_list(p), do: bulk(IO.iodata_to_binary(p))

  @type reply ::
          binary()
          | integer()
          | float()
          | boolean()
          | nil
          | :infinity
          | :neg_infinity
          | :nan
          | [reply()]
          | %{optional(reply()) => reply()}
          | MapSet.t()
          | {:error_reply, binary()}
          | {:push, [reply()]}

  @spec parse(binary()) :: {:ok, reply(), binary()} | :incomplete | {:error, :bad_resp}
  def parse(<<?+, rest::binary>>), do: simple(rest, & &1)
  def parse(<<?-, rest::binary>>), do: simple(rest, &{:error_reply, &1})
  def parse(<<?:, rest::binary>>), do: simple(rest, &String.to_integer/1)

  def parse(<<?$, rest::binary>>), do: blob(rest, & &1)

  def parse(<<?=, rest::binary>>) do
    blob(rest, fn
      <<_fmt::binary-size(3), ":", body::binary>> -> body
      other -> other
    end)
  end

  def parse(<<?*, rest::binary>>), do: aggregate(rest, & &1)
  def parse(<<?>, rest::binary>>), do: aggregate(rest, &{:push, &1})
  def parse(<<?~, rest::binary>>), do: aggregate(rest, &MapSet.new/1)

  def parse(<<?%, rest::binary>>) do
    case line(rest) do
      {:line, n_s, r1} ->
        case items(r1, 2 * String.to_integer(n_s), []) do
          {:ok, flat, r2} -> {:ok, flat |> Enum.chunk_every(2) |> Map.new(fn [k, v] -> {k, v} end), r2}
          other -> other
        end

      :incomplete ->
        :incomplete
    end
  end

  def parse(<<?#, ?t, "\r\n", rest::binary>>), do: {:ok, true, rest}
  def parse(<<?#, ?f, "\r\n", rest::binary>>), do: {:ok, false, rest}
  def parse(<<?#, _::binary>>), do: :incomplete

  def parse(<<?_, "\r\n", rest::binary>>), do: {:ok, nil, rest}
  def parse(<<?_, _::binary>>), do: :incomplete

  def parse(<<?,, rest::binary>>), do: simple(rest, &double/1)
  def parse(<<?(, rest::binary>>), do: simple(rest, &String.to_integer/1)

  def parse(<<>>), do: :incomplete
  def parse(_), do: {:error, :bad_resp}

  defp double("inf"), do: :infinity
  defp double("-inf"), do: :neg_infinity
  defp double("nan"), do: :nan

  defp double(s) do
    case Float.parse(s) do
      {f, ""} -> f
      _ -> String.to_integer(s) * 1.0
    end
  end

  defp blob(rest, wrap) do
    case line(rest) do
      {:line, "-1", r1} ->
        {:ok, nil, r1}

      {:line, len_s, r1} ->
        len = String.to_integer(len_s)

        case r1 do
          <<v::binary-size(len), "\r\n", r2::binary>> -> {:ok, wrap.(v), r2}
          _ -> :incomplete
        end

      :incomplete ->
        :incomplete
    end
  end

  defp aggregate(rest, wrap) do
    case line(rest) do
      {:line, "-1", r1} ->
        {:ok, nil, r1}

      {:line, n_s, r1} ->
        case items(r1, String.to_integer(n_s), []) do
          {:ok, vals, r2} -> {:ok, wrap.(vals), r2}
          other -> other
        end

      :incomplete ->
        :incomplete
    end
  end

  defp items(buf, 0, acc), do: {:ok, Enum.reverse(acc), buf}

  defp items(buf, n, acc) do
    case parse(buf) do
      {:ok, v, rest} -> items(rest, n - 1, [v | acc])
      other -> other
    end
  end

  defp simple(rest, wrap) do
    case line(rest) do
      {:line, l, r} -> {:ok, wrap.(l), r}
      :incomplete -> :incomplete
    end
  end

  defp line(buf) do
    case :binary.match(buf, @crlf) do
      {pos, 2} ->
        <<l::binary-size(pos), _::binary-size(2), rest::binary>> = buf
        {:line, l, rest}

      :nomatch ->
        :incomplete
    end
  end
end
