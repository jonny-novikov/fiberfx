defmodule EchoCache.CoherenceExtendTest do
  @moduledoc """
  The rest of the Coherence row's pure column (echo2-migration.md §5),
  extending the migrated floor `coherence_test.exs` (payload round-trip,
  same-kind mint order), which stays byte-unmodified: the channel and
  queue shapes, mint order ACROSS namespaces, the equal-id case, and the
  parse refusals beyond plain garbage.
  """
  use ExUnit.Case, async: true

  alias EchoCache.Coherence

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  test "channel/1 is the table's broadcast channel" do
    assert Coherence.channel("users") == "ecc:{users}:coh"
  end

  test "queue/1 is the table's coherence job queue" do
    assert Coherence.queue("users") == "ecc.coh.users"
  end

  test "newer?/2 compares mint order across namespaces" do
    older = EchoData.BrandedId.generate!("AST")
    Process.sleep(2)
    newer = EchoData.BrandedId.generate!("TXN")

    assert Coherence.newer?(newer, older)
    refute Coherence.newer?(older, newer)
  end

  test "newer?/2 answers false for the same id" do
    id = EchoData.BrandedId.generate!("TXN")
    refute Coherence.newer?(id, id)
  end

  test "parse/1 refuses a well-framed payload of invalid ids" do
    bogus = String.duplicate("A", 14) <> ":" <> String.duplicate("B", 14)
    assert Coherence.parse(bogus) == :error
  end

  test "parse/1 refuses a short frame" do
    assert Coherence.parse("AST:short") == :error
  end

  test "payload/2 refuses arguments that are not exactly fourteen bytes" do
    id = EchoData.BrandedId.generate!("AST")

    assert_raise FunctionClauseError, fn -> Coherence.payload("short", id) end
    assert_raise FunctionClauseError, fn -> Coherence.payload(id, "way-too-long-to-be-an-id") end
  end
end
