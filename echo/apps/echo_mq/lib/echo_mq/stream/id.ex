defmodule EchoMQ.Stream.Id do
  @moduledoc """
  The writer law's pure core (emq3.2, S1 the writer part 2): the
  branded-record-id ↔ XADD-entry-id correspondence, and nothing else.
  No process, no IO, no `Connector` -- the order math is the un-spoofable
  pure peer the writer routes through (the verdict-surface law; the
  precedents `EchoMQ.BatchShaper.Core` / `EchoMQ.BatchFinish.partition`).

  ## The A1 mapping (the ruled consensus, D-1)

  A branded record id maps to an EXPLICIT XADD id by FIELD CORRESPONDENCE
  over its 63-bit snowflake (`EchoData.BrandedId.decode/1`):

      xadd_id = "<ms>-<tail22>"
        ms     = EchoData.Snowflake.unix_ms(snow)   # the REAL Unix-ms of the mint
        tail22 = snow &&& 0x3FFFFF                   # the 22-bit node|seq tail

  The ms field is the **real Unix-ms** (`(snow >>> 22) + @epoch_ms`,
  `snowflake.ex:107`), NOT the raw epoch-relative `ts` field -- load-bearing
  for emq3.6's wall-clock `XRANGE` (a reader maps a `DateTime` to a bound via
  `DateTime.to_unix(dt, :millisecond)`, which lands on the right entries only
  if the XADD ms field is true Unix-ms). The seq field is the FULL 22-bit
  `node <<< 12 ||| seq` tail (`snowflake.ex:3`): carrying the **node** is what
  keeps the coordination-free "mint on any node" law collision-free on the
  wire (two writers in the same ms with the same seq stay distinct by node).

  ## The order theorem (this module's property)

  Stream order == id sort == mint order, for every pair of records of ONE
  namespace -- proven BY CONSTRUCTION, not by example:

    1. **Branded byte order == snowflake integer order.** The branded id is
       `ns ++ base62₁₁(snow)`; `EchoData.Base62` is the order-preserving
       fixed-width-11 codec (`base62.ex:4`: "Lexicographic order equals
       numeric order"; alphabet `0-9A-Za-z`, ascending bytes). For a FIXED
       namespace (one brand per stream -- D-2's kind door), byte order of the
       14-byte string == numeric order of the snowflake.

    2. **A1 is an order-preserving image of the snowflake integer.** Write
       `snow = ms_part <<< 22 ||| tail22`. A1 emits the pair
       `(ms_part + @epoch_ms, tail22)`. Because the snowflake packs the
       timestamp HIGH and the tail LOW-22 with NO overlap, `snow_a < snow_b`
       iff `(ms_part_a, tail22_a) < (ms_part_b, tail22_b)` lexicographically
       -- exactly the pair XADD compares. The `+@epoch_ms` is a constant
       monotone shift. ∴ `snow_a < snow_b ⇔ xadd_id(a) < xadd_id(b)`.

  Cross-namespace ordering is NEITHER required NOR sound (the namespace bytes
  compare first); the writer's kind door (`evt?/1`) refuses a foreign brand
  precisely so step 1 holds. ADR-1 and ADR-2 are JOINED.

      iex> EchoMQ.Stream.Id.xadd_id("EVT000xY9Wvvcd")
      {:ok, "1704117200000-1620567"}

      iex> EchoMQ.Stream.Id.xadd_id("ORD000xY9Wvvcd")
      {:error, :kind}

      iex> EchoMQ.Stream.Id.xadd_id("not-branded")
      {:error, :malformed}

      iex> EchoMQ.Stream.Id.evt?("EVT000xY9Wvvcd")
      true

      iex> EchoMQ.Stream.Id.evt?("ORD000xY9Wvvcd")
      false
  """

  import Bitwise

  alias EchoData.{BrandedId, Snowflake}

  @kind "EVT"
  @tail22 0x3FFFFF

  @doc "The admitted stream namespace -- one brand per stream (D-2)."
  @spec kind() :: binary()
  def kind, do: @kind

  @doc """
  The A1 XADD id of a branded record id: `{:ok, "<ms>-<tail22>"}`, or a typed
  refusal -- `{:error, :kind}` for a well-formed id of the wrong namespace,
  `{:error, :malformed}` for a non-branded id. Pure and total over its input;
  it RETURNS the refusal (the writer RAISES on it -- INV2). The `<ms>` is the
  real Unix-ms (`Snowflake.unix_ms/1`); the `<tail22>` is the 22-bit
  `node|seq` tail (`snow &&& 0x3FFFFF`). D-1, cite `snowflake.ex:107`/`:3`.
  """
  @spec xadd_id(binary()) :: {:ok, binary()} | {:error, :kind | :malformed}
  def xadd_id(branded) when is_binary(branded) do
    case BrandedId.parse(branded) do
      {:ok, @kind, snow} -> {:ok, "#{Snowflake.unix_ms(snow)}-#{snow &&& @tail22}"}
      {:ok, _other_ns, _snow} -> {:error, :kind}
      :error -> {:error, :malformed}
    end
  end

  @doc """
  The kind predicate: true iff `branded` is a well-formed branded id of the
  admitted stream namespace (`EVT`). The writer's host-side kind door calls
  this before any wire (INV2); one brand per stream keeps the order theorem's
  step 1 sound (base62 byte order == int order only WITHIN one namespace).
  """
  @spec evt?(binary()) :: boolean()
  def evt?(branded) when is_binary(branded) do
    match?({:ok, @kind, _snow}, BrandedId.parse(branded))
  end

  def evt?(_), do: false
end
