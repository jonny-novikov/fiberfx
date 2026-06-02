defmodule Portal.LearningTest do
  # Not async: writes to the shared Portal.Store.
  use ExUnit.Case, async: false

  alias Portal.Learning
  alias Portal.Learning.Enrollment

  test "enroll/2 mints an ENR id, persists progress 0, and lists it" do
    assert {:ok, %Enrollment{} = e} = Learning.enroll("USR1", "CRS1")

    assert String.starts_with?(e.id, "ENR")
    assert e.user_id == "USR1" and e.course_id == "CRS1"
    assert e.progress == 0

    assert {:ok, ^e} = Portal.Store.get("ENR", e.id)
    assert e in Learning.courses_of("USR1")
  end
end
