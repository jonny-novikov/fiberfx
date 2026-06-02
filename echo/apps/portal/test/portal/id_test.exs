defmodule Portal.IDTest do
  use ExUnit.Case, async: true

  test "new/1 mints a 3-letter namespace + 11-char Base62 (14 chars total)" do
    id = Portal.ID.new("ENR")
    assert String.starts_with?(id, "ENR")
    assert String.length(id) == 14
    assert Portal.ID.namespace(id) == "ENR"
  end

  test "snowflake/1 round-trips new/1 to the canonical integer" do
    id = Portal.ID.new("ENR")
    sf = Portal.ID.snowflake(id)
    assert is_integer(sf) and sf >= 0
    assert "ENR" <> EchoData.Base62.encode(sf) == id
  end

  test "at/1 returns the mint time as a UTC DateTime" do
    before = DateTime.utc_now()
    at = Portal.ID.at(Portal.ID.new("USR"))
    assert %DateTime{time_zone: "Etc/UTC"} = at
    assert abs(DateTime.diff(at, before, :second)) <= 2
  end

  test "ids minted in the same millisecond are distinct" do
    ids = for _ <- 1..100, do: Portal.ID.new("ENR")
    assert length(Enum.uniq(ids)) == 100
  end

  test ~S(valid?/1 accepts minted ids and rejects malformed placeholders like "USR1") do
    assert Portal.ID.valid?(Portal.ID.new("ENR"))
    refute Portal.ID.valid?("USR1")
    refute Portal.ID.valid?("ENR")
    refute Portal.ID.valid?("usr0NepbCmCG3d")
    refute Portal.ID.valid?(42)
  end
end
