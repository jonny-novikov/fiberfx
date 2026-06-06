defmodule EchoMQTest do
  use ExUnit.Case, async: true

  describe "version/0" do
    test "returns current version string" do
      assert is_binary(EchoMQ.version())
      assert EchoMQ.version() =~ ~r/^\d+\.\d+\.\d+$/
    end

    test "returns 1.3.0" do
      assert EchoMQ.version() == "1.3.0"
    end
  end

  describe "library_name/0" do
    test "returns echomq for Redis compatibility" do
      assert EchoMQ.library_name() == "echomq"
    end

    test "returns a string" do
      assert is_binary(EchoMQ.library_name())
    end
  end
end
