defmodule EchoDataTest do
  use ExUnit.Case, async: true

  test "Base62 round-trips an integer" do
    n = 12_345_678_901_234
    assert {:ok, ^n} = EchoData.Base62.decode(EchoData.Base62.encode(n))
  end

  test "a generated snowflake round-trips through Base62 and carries a UTC timestamp" do
    sf = EchoData.Snowflake.generate(worker_id: 1)
    assert {:ok, ^sf} = EchoData.Base62.decode(EchoData.Base62.encode(sf))
    assert %DateTime{time_zone: "Etc/UTC"} = EchoData.Snowflake.timestamp(sf)
  end
end
