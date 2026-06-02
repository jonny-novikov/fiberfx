defmodule Portal.LearningTest do
  # Not async: writes to the shared Portal.Store.
  use ExUnit.Case, async: false

  alias Portal.Learning
  alias Portal.Learning.Enrollment

  test "enroll/2 mints an ENR id, persists progress 0, and lists it" do
    user_id = Portal.ID.new("USR")
    course_id = Portal.ID.new("CRS")
    # enroll/2 now checks the course exists (F5.4) — seed it in the store first.
    :ok = Portal.Store.put(%Portal.Catalog.Course{id: course_id, title: "Elixir", slug: "elixir"})

    assert {:ok, %Enrollment{} = e} = Learning.enroll(user_id, course_id)

    assert Portal.ID.valid?(e.id) and Portal.ID.namespace(e.id) == "ENR"
    assert e.user_id == user_id and e.course_id == course_id
    assert e.progress == 0

    assert {:ok, ^e} = Portal.Store.get("ENR", e.id)
    assert e in Learning.courses_of(user_id)
  end
end
