defmodule Portal.EntitiesTest do
  use ExUnit.Case, async: true

  alias Portal.Accounts.{User, Session}
  alias Portal.Catalog.{Course, Lesson, Page}
  alias Portal.Enrollment.{Enrollment, Progress}

  # Real, well-formed branded ids — never the "USR1" placeholder.
  defp id(ns), do: Portal.ID.new(ns)

  test "every entity builds when all enforced keys are present" do
    assert %User{name: "Ada"} = %User{id: id("USR"), email: "a@b.c", name: "Ada"}
    assert %Session{token: "t"} = %Session{id: id("SES"), user_id: id("USR"), token: "t"}
    assert %Course{slug: "elixir"} = %Course{id: id("CRS"), title: "Elixir", slug: "elixir"}
    assert %Lesson{title: "Intro"} = %Lesson{id: id("LSN"), course_id: id("CRS"), title: "Intro"}
    assert %Page{body: "..."} = %Page{id: id("PGE"), lesson_id: id("LSN"), body: "..."}

    assert %Enrollment{progress: 0} = %Enrollment{
             id: id("ENR"),
             user_id: id("USR"),
             course_id: id("CRS")
           }

    assert %Progress{percent: 0} =
             %Progress{id: id("PRG"), enrollment_id: id("ENR"), lesson_id: id("LSN"), percent: 0}
  end

  test "omitting an enforced key raises at build time" do
    assert_raise ArgumentError, fn -> struct!(User, id: id("USR"), email: "a@b.c") end
    assert_raise ArgumentError, fn -> struct!(Course, id: id("CRS"), title: "Elixir") end
    assert_raise ArgumentError, fn -> struct!(Enrollment, id: id("ENR"), user_id: id("USR")) end
  end

  test "Enrollment defaults progress to 0" do
    assert %Enrollment{id: id("ENR"), user_id: id("USR"), course_id: id("CRS")}.progress == 0
  end
end
