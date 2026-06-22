defmodule EchoMQ.Stream.IdTest do
  @moduledoc """
  The writer law's pure-core proof (emq3.2, S1 the writer part 2): the order
  theorem IS the property of `EchoMQ.Stream.Id` (stream order == id sort ==
  mint order), proven by doctests + a DETERMINISTIC ExUnit enumeration over
  many mint sequences -- INCLUDING forced same-millisecond mints (the
  multi-writer interleave the theorem must survive).

  No new dependency (`stream_data` is NOT in echo_mq's `deps/0`, `mix.exs:28-32`
  -- the dep-graph-visibility rule): the property is a deterministic
  enumeration, re-runnable, no `ExUnitProperties`. The property is the SAME a
  StreamData arm would prove (the order theorem over many sequences); only the
  generator differs.

  Pure -- no `:valkey` tag, no process, no Snowflake mint hazard in the
  ASSERTIONS themselves (the forced same-ms mints exercise `Snowflake.next/1`,
  but the order theorem is asserted as a pure relation over the ids the mints
  produced).
  """
  use ExUnit.Case, async: true

  alias EchoData.{BrandedId, Snowflake}
  alias EchoMQ.Stream.Id

  doctest EchoMQ.Stream.Id

  setup_all do
    # the mint must be up for next/0,next/1 (the property's sequence source).
    :ok = Snowflake.start(7)
    :ok
  end

  # Compare two A1 XADD ids the way Valkey orders stream entries: by the
  # (ms, seq) pair as INTEGERS, NOT string-lexicographically ("...-9" vs
  # "...-10" sorts wrong as strings). Returns :lt | :eq | :gt.
  defp cmp_xadd(a, b) do
    [ma, sa] = a |> String.split("-") |> Enum.map(&String.to_integer/1)
    [mb, sb] = b |> String.split("-") |> Enum.map(&String.to_integer/1)
    cond do
      {ma, sa} < {mb, sb} -> :lt
      {ma, sa} > {mb, sb} -> :gt
      true -> :eq
    end
  end

  # The branded-string byte order (step 1 of the theorem) as :lt | :eq | :gt.
  defp cmp_bytes(a, b) do
    cond do
      a < b -> :lt
      a > b -> :gt
      true -> :eq
    end
  end

  describe "EMQ3.2-INV1b -- the order theorem over many mint sequences (deterministic)" do
    test "byte(branded_a) < byte(branded_b) <=> xadd_id(a) < xadd_id(b), for EVERY pair" do
      # a sequence of freshly-minted EVT ids -- successive mints over the shared
      # strictly-monotone :atomics cell, so byte order == mint order == call order.
      ids = for _ <- 1..200, do: BrandedId.encode!("EVT", Snowflake.next())

      pairs = for a <- ids, b <- ids, a != b, do: {a, b}
      assert pairs != []

      for {a, b} <- pairs do
        {:ok, xa} = Id.xadd_id(a)
        {:ok, xb} = Id.xadd_id(b)
        # the bi-conditional: the branded byte order and the XADD (ms,seq) order
        # agree on EVERY pair (a non-order-preserving mapping breaks some pair).
        assert cmp_bytes(a, b) == cmp_xadd(xa, xb),
               "order disagreement: #{a} vs #{b} -> bytes #{cmp_bytes(a, b)}, xadd #{cmp_xadd(xa, xb)}"
      end
    end

    test "FORCED same-millisecond mints stay strictly ordered (the multi-writer interleave)" do
      # next/1 takes a per-call node id over the SAME monotonic cell: a tight
      # loop with DISTINCT node ids produces snowflakes that SHARE a millisecond
      # (the cell ts advances slowly vs the loop) yet are strictly monotone (the
      # cell's max(now,last+1)). This is the multi-writer-into-one-stream
      # interleave -- carrying the node into the tail (A1) is what keeps these
      # distinct and ordered on the wire (the ms-seq12 alternative would collide).
      ids = for i <- 1..512, do: BrandedId.encode!("EVT", Snowflake.next(rem(i, 1024)))

      # prove the burst actually shares a millisecond (else the test is vacuous --
      # it would not exercise the same-ms tie-break the node field exists for).
      ms_values =
        for id <- ids do
          {:ok, snow} = BrandedId.decode(id)
          Snowflake.unix_ms(snow)
        end

      assert length(Enum.uniq(ms_values)) < length(ids),
             "the burst did not share any millisecond -- the same-ms tie-break is untested"

      # within the burst: strictly increasing branded bytes <=> strictly
      # increasing xadd ids, AND every xadd id is DISTINCT (no two records of one
      # stream collide on the wire -- the node field's whole job).
      xadd_ids =
        for id <- ids do
          {:ok, x} = Id.xadd_id(id)
          x
        end

      assert length(Enum.uniq(xadd_ids)) == length(xadd_ids),
             "two same-ms mints produced the SAME xadd id -- the node tail failed to disambiguate"

      # consecutive mints are strictly increasing in BOTH orders (the call order
      # is the mint order over the monotone cell).
      Enum.zip(ids, tl(ids))
      |> Enum.each(fn {a, b} ->
        {:ok, xa} = Id.xadd_id(a)
        {:ok, xb} = Id.xadd_id(b)
        assert cmp_bytes(a, b) == :lt, "branded bytes not strictly increasing: #{a} !< #{b}"
        assert cmp_xadd(xa, xb) == :lt, "xadd id not strictly increasing: #{xa} !< #{xb}"
      end)
    end

    test "the ms field is the REAL Unix-ms (not the raw epoch-relative ts) -- emq3.6 needs it" do
      # a reader maps a wall-clock DateTime to a bound via to_unix(:millisecond);
      # that lands on the right entries ONLY if the XADD ms field is true Unix-ms.
      id = BrandedId.encode!("EVT", Snowflake.next())
      {:ok, snow} = BrandedId.decode(id)
      {:ok, xadd} = Id.xadd_id(id)
      [ms, _seq] = String.split(xadd, "-")

      # the ms field equals Snowflake.unix_ms (the real Unix-ms), provably ABOVE
      # the epoch (a raw ts field would be epoch-relative -- a far smaller number).
      assert String.to_integer(ms) == Snowflake.unix_ms(snow)
      assert String.to_integer(ms) >= Snowflake.epoch_ms()
    end
  end

  describe "EMQ3.2-INV2/INV5 -- the kind predicate + the typed refusals (pure, total)" do
    test "xadd_id refuses a wrong-namespace id {:error, :kind} and a malformed id {:error, :malformed}" do
      snow = Snowflake.next()
      evt = BrandedId.encode!("EVT", snow)
      ord = BrandedId.encode!("ORD", snow)

      assert {:ok, _} = Id.xadd_id(evt)
      assert {:error, :kind} = Id.xadd_id(ord)
      assert {:error, :malformed} = Id.xadd_id("nope")
      assert {:error, :malformed} = Id.xadd_id("")
    end

    test "evt? is true only for a well-formed EVT id" do
      snow = Snowflake.next()
      assert Id.evt?(BrandedId.encode!("EVT", snow))
      refute Id.evt?(BrandedId.encode!("ORD", snow))
      refute Id.evt?("not-branded")
      refute Id.evt?(123)
    end

    test "the same payload across namespaces shares the xadd id when admitted (kind is the ONLY gate)" do
      # the EVT id and an ORD id of the SAME snowflake map to the SAME (ms,seq)
      # -- proof that A1 is over the snowflake alone; the namespace is the kind
      # door, not part of the ordering math (so step 1 is sound only within EVT).
      snow = Snowflake.next()
      {:ok, x} = Id.xadd_id(BrandedId.encode!("EVT", snow))
      assert x == "#{Snowflake.unix_ms(snow)}-#{Bitwise.band(snow, 0x3FFFFF)}"
    end
  end
end
