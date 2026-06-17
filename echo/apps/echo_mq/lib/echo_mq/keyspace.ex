defmodule EchoMQ.Keyspace do
  @moduledoc """
  The v2 keyspace grammar. Per-queue keys are `emq:{q}:<type>` with the
  hashtag applied transparently — every key of one queue lands on one slot.
  The braced `{emq}:` base is reserved for cross-queue keys (the version
  fence lives there). Job keys compose with the identity canon: the branded
  payload is the long part by design, and it is gated before it is used.
  """

  @reserve "{emq}:"
  @version_key @reserve <> "version"

  @spec queue_key(binary(), binary()) :: binary()
  def queue_key(queue, type) when is_binary(queue) and is_binary(type),
    do: IO.iodata_to_binary(["emq:{", queue, "}:", type])

  @spec job_key(binary(), binary()) :: binary()
  def job_key(queue, branded) when is_binary(branded) do
    if EchoData.BrandedId.valid?(branded) do
      queue_key(queue, "job:") <> branded
    else
      raise ArgumentError, "job_key requires a valid branded id"
    end
  end

  @spec reserve(binary()) :: binary()
  def reserve(suffix) when is_binary(suffix), do: @reserve <> suffix

  @spec version_key() :: binary()
  def version_key, do: @version_key

  @doc "Bytes a key family spends before the branded payload begins."
  @spec prefix_bytes(binary(), binary()) :: non_neg_integer()
  def prefix_bytes(queue, type), do: byte_size(queue_key(queue, type))

  @doc """
  Cluster slot of a key, computed client-side: CRC16-XMODEM over the hashtag
  (the substring inside the first `{...}`, when present and non-empty) modulo
  16384 — the cluster specification's algorithm, so the connector can route
  and partition without a server round trip. Known vector:
  `slot("123456789") == 12739` (CRC16 0x31C3).
  """
  @spec slot(binary()) :: 0..16383
  def slot(key) when is_binary(key), do: rem(crc16(hashtag(key), 0), 16384)

  @spec hashtag(binary()) :: binary()
  def hashtag(key) do
    with [_, rest] <- :binary.split(key, "{"),
         [tag, _] when tag != "" <- :binary.split(rest, "}") do
      tag
    else
      _ -> key
    end
  end

  defp crc16(<<>>, crc), do: crc

  defp crc16(<<b, rest::binary>>, crc) do
    crc = Bitwise.band(Bitwise.bxor(crc, Bitwise.bsl(b, 8)), 0xFFFF)

    crc =
      Enum.reduce(1..8, crc, fn _, c ->
        shifted = Bitwise.band(Bitwise.bsl(c, 1), 0xFFFF)
        if Bitwise.band(c, 0x8000) != 0, do: Bitwise.bxor(shifted, 0x1021), else: shifted
      end)

    crc16(rest, crc)
  end
end
