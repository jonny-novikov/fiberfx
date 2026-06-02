defmodule Portal.EntitiesTest do
  use ExUnit.Case, async: true

  alias Portal.Accounts.{User, Session}
  alias Portal.Catalog.{Course, Lesson, Page}
  alias Portal.Learning.{Enrollment, Progress}

  test "every entity builds when all enforced keys are present" do
    assert %User{name: "Ada"} = %User{id: "USR1", email: "a@b.c", name: "Ada"}
    assert %Session{token: "t"} = %Session{id: "SES1", user_id: "USR1", token: "t"}
    assert %Course{slug: "elixir"} = %Course{id: "CRS1", title: "Elixir", slug: "elixir"}
    assert %Lesson{title: "Intro"} = %Lesson{id: "LSN1", course_id: "CRS1", title: "Intro"}
    assert %Page{body: "..."} = %Page{id: "PGE1", lesson_id: "LSN1", body: "..."}
    assert %Enrollment{course_id: "CRS1"} = %Enrollment{id: "ENR1", user_id: "USR1", course_id: "CRS1"}

    assert %Progress{percent: 0} =
             %Progress{id: "PRG1", enrollment_id: "ENR1", lesson_id: "LSN1", percent: 0}
  end

  test "omitting an enforced key raises at build time" do
    assert_raise ArgumentError, fn -> struct!(User, id: "USR1", email: "a@b.c") end
    assert_raise ArgumentError, fn -> struct!(Course, id: "CRS1", title: "Elixir") end
    assert_raise ArgumentError, fn -> struct!(Enrollment, id: "ENR1", user_id: "USR1") end
  end

  test "Enrollment defaults progress to 0" do
    assert %Enrollment{id: "ENR1", user_id: "USR1", course_id: "CRS1"}.progress == 0
  end
end
