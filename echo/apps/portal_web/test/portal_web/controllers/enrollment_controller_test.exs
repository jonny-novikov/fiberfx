defmodule PortalWeb.EnrollmentControllerTest do
  @moduledoc """
  ConnTest for the write route `post "/enroll"` (F6.2-US6, F6.2-D1).

  Proves the POST reaches `EnrollmentController.create/2` and issues `Portal.enroll/2`:
  a success redirects to the user's course list, and a non-existent course yields the
  closed-set `:course_not_found` failure at `422`. The full enroll UI is F6.4.
  """
  use PortalWeb.ConnCase, async: false

  alias Portal.Accounts.User

  test "a valid enroll redirects to the user's course list (F6.2-US6)", %{conn: conn} do
    user = %User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada"}
    :ok = Portal.Store.put(user)
    # Since F6.4 the Catalog is Repo-backed: seed the course through the facade
    # (`Portal.create_course/1`) so the engine's enroll gate (`Catalog.fetch_course/1`
    # -> Repo) sees it. The test still names only `Portal` (INV2), never a context/Repo.
    # A strong-random title token: portal_web has no Ecto sandbox, so this insert
    # COMMITS — a resettable counter would collide with a prior run's committed row.
    tok = Base.encode16(:crypto.strong_rand_bytes(8))
    {:ok, course} = Portal.create_course(%{title: "Elixir #{tok}", slug: "elixir-#{tok}"})

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
