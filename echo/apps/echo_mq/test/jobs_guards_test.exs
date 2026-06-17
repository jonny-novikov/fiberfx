defmodule EchoMQ.JobsGuardsTest do
  @moduledoc """
  The pure column of the Jobs row (echo2-migration.md §5): the argument
  guards refuse before any wire work, so no connection is ever touched —
  the conn argument is a plain atom on purpose.
  """
  use ExUnit.Case, async: true

  alias EchoMQ.Jobs

  test "claim/3 refuses a zero lease (lease_ms > 0)" do
    assert_raise FunctionClauseError, fn -> Jobs.claim(:no_conn, "q", 0) end
  end

  test "claim/3 refuses a negative lease" do
    assert_raise FunctionClauseError, fn -> Jobs.claim(:no_conn, "q", -5) end
  end

  test "claim/3 refuses a non-integer lease" do
    assert_raise FunctionClauseError, fn -> Jobs.claim(:no_conn, "q", "1000") end
  end

  test "browse/3 refuses a zero n (n > 0)" do
    assert_raise FunctionClauseError, fn -> Jobs.browse(:no_conn, "q", 0) end
  end

  test "browse/3 refuses a non-integer n" do
    assert_raise FunctionClauseError, fn -> Jobs.browse(:no_conn, "q", :all) end
  end

  test "promote/3 refuses a non-positive batch (batch > 0)" do
    assert_raise FunctionClauseError, fn -> Jobs.promote(:no_conn, "q", 0) end
  end
end
