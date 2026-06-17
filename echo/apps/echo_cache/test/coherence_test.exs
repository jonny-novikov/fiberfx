defmodule EchoCache.CoherenceTest do
  use ExUnit.Case, async: true
  alias EchoCache.Coherence

  setup_all do
    case EchoData.Snowflake.start(4) do
      :ok -> :ok
      {:error, :already_started} -> :ok
    end
  end

  test "payload round-trips id and version, garbage is refused" do
    id = EchoData.BrandedId.generate!("AST")
    v = EchoData.BrandedId.generate!("TXN")
    pay = Coherence.payload(id, v)
    assert {:ok, ^id, ^v} = Coherence.parse(pay)
    assert :error = Coherence.parse("garbage")
  end

  test "newer-wins compares mint order" do
    old = EchoData.BrandedId.generate!("TXN")
    Process.sleep(2)
    new = EchoData.BrandedId.generate!("TXN")
    assert Coherence.newer?(new, old)
    refute Coherence.newer?(old, new)
  end
end
