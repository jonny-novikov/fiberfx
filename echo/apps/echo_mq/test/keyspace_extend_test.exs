defmodule EchoMQ.KeyspaceExtendTest do
  @moduledoc """
  The pure column of the Keyspace row (echo2-migration.md §5): the grammar,
  the job-key gate, the reserve base, the fence key, the prefix arithmetic,
  the committed slot vector, the one-queue slot family, and the hashtag
  cases. Extends the migrated floor `keyspace_test.exs`, which stays
  byte-unmodified.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Keyspace

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  test "queue_key/2 composes the braced per-queue grammar" do
    assert Keyspace.queue_key("q1", "pending") == "emq:{q1}:pending"
  end

  test "job_key/2 composes on a valid branded id" do
    id = EchoData.BrandedId.generate!("JOB")
    assert Keyspace.job_key("q1", id) == "emq:{q1}:job:" <> id
  end

  test "job_key/2 raises ArgumentError on a non-branded id" do
    assert_raise ArgumentError, "job_key requires a valid branded id", fn ->
      Keyspace.job_key("q1", "not-a-branded-id")
    end
  end

  test "reserve/1 composes under the braced cross-queue base" do
    assert Keyspace.reserve("locks") == "{emq}:locks"
  end

  test "version_key/0 is the reserved fence key" do
    assert Keyspace.version_key() == "{emq}:version"
  end

  test "prefix_bytes/2 counts the bytes a family spends before the payload" do
    assert Keyspace.prefix_bytes("q1", "job:") == byte_size("emq:{q1}:job:")
    assert Keyspace.prefix_bytes("q1", "pending") == byte_size("emq:{q1}:pending")
  end

  test "slot/1 matches the committed CRC16 vector" do
    assert Keyspace.slot("123456789") == 12_739
  end

  test "every key of one queue lands on one slot" do
    slots =
      for type <- ["pending", "active", "schedule", "dead", "ring", "wake", "job:"] do
        Keyspace.slot(Keyspace.queue_key("q7", type))
      end

    assert [_one] = Enum.uniq(slots)
  end

  test "hashtag/1 extracts the first braced tag" do
    assert Keyspace.hashtag("emq:{q1}:pending") == "q1"
  end

  test "hashtag/1 answers the whole key on empty braces" do
    assert Keyspace.hashtag("emq:{}:pending") == "emq:{}:pending"
  end

  test "hashtag/1 answers the whole key when no brace opens" do
    assert Keyspace.hashtag("123456789") == "123456789"
  end
end
