defmodule EchoDataTest do
  use ExUnit.Case, async: true
  doctest EchoData

  alias EchoData.{Base62, Snowflake, BrandedChamp}

  describe "Base62" do
    test "encodes and decodes correctly" do
      values = [0, 1, 61, 62, 3844, 12345678901234, 9_007_199_254_740_991]

      for value <- values do
        encoded = Base62.encode(value)
        assert {:ok, ^value} = Base62.decode(encoded)
      end
    end

    test "encodes to 11 characters" do
      assert Base62.encode(0) == "00000000000"
      assert Base62.encode(61) == "0000000000z"
      assert byte_size(Base62.encode(12345678901234)) == 11
    end

    test "validates Base62 strings" do
      assert Base62.valid?("0K48QjihpC4")
      refute Base62.valid?("invalid!")
      refute Base62.valid?("too_long_string")
    end
  end

  describe "Snowflake" do
    test "generates unique snowflakes" do
      snowflakes = for _ <- 1..100, do: Snowflake.generate()
      assert length(Enum.uniq(snowflakes)) == 100
    end

    test "extracts components correctly" do
      snowflake = Snowflake.generate(worker_id: 42, sequence: 123)
      components = Snowflake.extract(snowflake)

      assert components.worker_id == 42
      assert components.sequence == 123
      assert %DateTime{} = components.timestamp
    end

    test "builds from components" do
      datetime = ~U[2024-06-15 12:30:00.000Z]
      snowflake = Snowflake.build(datetime, 1, 0)

      assert Snowflake.timestamp(snowflake) == datetime
      assert Snowflake.worker_id(snowflake) == 1
      assert Snowflake.sequence(snowflake) == 0
    end

    test "compares chronologically" do
      older = Snowflake.build(~U[2024-01-01 00:00:00.000Z], 0, 0)
      newer = Snowflake.build(~U[2024-01-02 00:00:00.000Z], 0, 0)

      assert Snowflake.compare(older, newer) == :lt
      assert Snowflake.compare(newer, older) == :gt
      assert Snowflake.compare(older, older) == :eq
    end
  end

  describe "BrandedChamp" do
    test "creates empty CHAMP" do
      champ = BrandedChamp.new()
      assert BrandedChamp.size(champ) == 0
      assert BrandedChamp.empty?(champ)
    end

    test "puts and fetches values" do
      champ = BrandedChamp.new()
      snowflake = Snowflake.generate()
      id = "PLR" <> Base62.encode(snowflake)

      champ = BrandedChamp.put(champ, id, %{name: "Alice"})
      assert {:ok, %{name: "Alice"}} = BrandedChamp.fetch(champ, id)
    end

    test "handles multiple namespaces" do
      champ = BrandedChamp.new()

      id1 = "PLR" <> Base62.encode(Snowflake.generate())
      id2 = "ROM" <> Base62.encode(Snowflake.generate())

      champ =
        champ
        |> BrandedChamp.put(id1, %{type: :player})
        |> BrandedChamp.put(id2, %{type: :room})

      assert BrandedChamp.size(champ) == 2
      assert ["PLR", "ROM"] = BrandedChamp.namespaces(champ) |> Enum.sort()
    end

    test "get_namespace returns only matching entries" do
      champ = BrandedChamp.new()

      player_ids = for _ <- 1..3 do
        "PLR" <> Base62.encode(Snowflake.generate())
      end

      room_id = "ROM" <> Base62.encode(Snowflake.generate())

      champ =
        player_ids
        |> Enum.reduce(champ, &BrandedChamp.put(&2, &1, %{type: :player}))
        |> BrandedChamp.put(room_id, %{type: :room})

      players = BrandedChamp.get_namespace(champ, "PLR")
      assert length(players) == 3

      rooms = BrandedChamp.get_namespace(champ, "ROM")
      assert length(rooms) == 1
    end

    test "deletes values" do
      champ = BrandedChamp.new()
      id = "PLR" <> Base62.encode(Snowflake.generate())

      champ = BrandedChamp.put(champ, id, %{name: "Alice"})
      assert BrandedChamp.has_key?(champ, id)

      champ = BrandedChamp.delete(champ, id)
      refute BrandedChamp.has_key?(champ, id)
    end

    test "implements Access protocol" do
      champ = BrandedChamp.new()
      id = "PLR" <> Base62.encode(Snowflake.generate())

      champ = BrandedChamp.put(champ, id, %{name: "Alice"})
      assert champ[id] == %{name: "Alice"}
    end

    test "implements Enumerable protocol" do
      champ = BrandedChamp.new()

      ids = for _ <- 1..5 do
        "PLR" <> Base62.encode(Snowflake.generate())
      end

      champ =
        ids
        |> Enum.with_index()
        |> Enum.reduce(champ, fn {id, i}, acc ->
          BrandedChamp.put(acc, id, %{index: i})
        end)

      assert Enum.count(champ) == 5
      assert Enum.all?(champ, fn {_id, %{index: i}} -> is_integer(i) end)
    end
  end
end
