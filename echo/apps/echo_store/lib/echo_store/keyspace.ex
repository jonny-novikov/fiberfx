defmodule EchoStore.Keyspace do
  @moduledoc """
  The cache's own keyspace: `ecc:{<table>}:<id>` — a fresh prefix beside
  `emq:`, never inside it, with the table name hashtagged so every key of
  one cache lands in one cluster slot on the day clustering arrives. The
  id in the key's value position is checked for shape before any key is
  composed; a malformed name never reaches the wire. The kind law — does
  this id's namespace match the table's declared kind — is enforced one
  layer up, where the declaration lives.
  """

  alias EchoData.BrandedId

  @spec key(binary(), binary()) :: binary()
  def key(table, id) when is_binary(table) and is_binary(id) do
    unless BrandedId.valid?(id) do
      raise ArgumentError, "invalid branded id in cache key position: #{inspect(id)}"
    end

    "ecc:{" <> table <> "}:" <> id
  end
end
