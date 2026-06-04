defmodule Portal.Catalog.CourseID do
  @moduledoc """
  Ecto.Type bridging the branded-string `:id` SURFACE to the `:bigint` column (F6.3-INV3).

  Course-specific: hardcodes the `"CRS"` namespace. The schema's `:id` surfaces as the
  14-char branded string (the frozen `Portal.ID` convention); the column is the
  canonical `:bigint` Snowflake integer. This type encode/decodes at the boundary:

  - `cast/1` accepts the branded-string surface (`Portal.ID.valid?/1`).
  - `dump/1` strips the brand to the `:bigint` integer for the column / a WHERE.
  - `load/1` composes the branded string back from the column integer.

  Round-trip identity: `EchoData.Base62.encode/2` defaults to width-11, so for any
  branded id minted as `"CRS" <> Base62.encode(snowflake)`, `load(dump(b)) == b` and
  `dump(load(i)) == i` (base62.ex:80-89, id.ex:26-28,56). There is NO Portal/EchoData
  function that rebuilds a branded string from a raw integer, so `load/1` composes it
  literally — and NOT via `Portal.ID.new/1`, which would mint a fresh, different id.
  """
  use Ecto.Type

  @impl true
  def type, do: :integer

  @impl true
  def cast(v) when is_binary(v) do
    if Portal.ID.valid?(v), do: {:ok, v}, else: :error
  end

  def cast(_), do: :error

  @impl true
  def dump(branded) when is_binary(branded) do
    {:ok, Portal.ID.snowflake(branded)}
  end

  def dump(_), do: :error

  @impl true
  def load(int) when is_integer(int) do
    {:ok, "CRS" <> EchoData.Base62.encode(int)}
  end

  def load(_), do: :error
end
