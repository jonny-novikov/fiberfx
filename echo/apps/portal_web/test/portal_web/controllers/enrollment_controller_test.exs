defmodule PortalWeb.EnrollmentControllerTest do
  @moduledoc """
  ConnTest for the write route `post "/enroll"` (F6.2-US6, F6.2-D1).

  Proves the POST reaches `EnrollmentController.create/2` and issues `Portal.enroll/2`:
  a success redirects to the user's course list, and a non-existent course yields the
  closed-set `:course_not_found` failure at `422`. The full enroll UI is F6.4.
  """
  use PortalWeb.ConnCase, async: false

  alias Portal.Accounts.User
  alias Portal.Catalog.Course

  test "a valid enroll redirects to the user's course list (F6.2-US6)", %{conn: conn} do
    user = %User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada"}
    course = %Course{id: Portal.ID.new("CRS"), title: "Elixir", slug: "elixir"}
    :ok = Portal.Store.put(user)
    :ok = Portal.Store.put(course)

    conn = post(conn, ~p"/enroll", %{"user_id" => user.id, "course_id" => course.id})

    assert redirected_to(conn) == ~p"/courses/#{user.id}"
  end

  test "enrolling into a non-existent course renders the closed-set 422", %{conn: conn} do
    user = %User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada"}
    :ok = Portal.Store.put(user)

    conn = post(conn, ~p"/enroll", %{"user_id" => user.id, "course_id" => Portal.ID.new("CRS")})

    assert html_response(conn, 422) =~ "course not found"
  end
end
