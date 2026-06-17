defmodule EchoMQ.ScriptTest do
  @moduledoc """
  The pure column of the Script row (echo2-migration.md §5): `new/2`
  precomputes the lowercase-hex SHA1 of the source, and the struct
  carries exactly the declared field set.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Script

  test "new/2 precomputes the lowercase-hex SHA1 of the source" do
    source = "return redis.call('GET', KEYS[1])"
    script = Script.new(:probe, source)

    assert script.name == :probe
    assert script.source == source
    assert script.sha == Base.encode16(:crypto.hash(:sha, source), case: :lower)
    assert byte_size(script.sha) == 40
    assert script.sha =~ ~r/^[0-9a-f]{40}$/
  end

  test "the struct carries exactly name, source, and sha" do
    script = Script.new(:probe, "return 1")

    assert Map.keys(Map.from_struct(script)) |> Enum.sort() == [:name, :sha, :source]
  end

  test "new/2 refuses a non-atom name and a non-binary source" do
    assert_raise FunctionClauseError, fn -> Script.new("probe", "return 1") end
    assert_raise FunctionClauseError, fn -> Script.new(:probe, :return_1) end
  end
end
