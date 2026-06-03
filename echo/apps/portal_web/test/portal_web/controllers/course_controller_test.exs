defmodule PortalWeb.CourseControllerTest do
  @moduledoc """
  ConnTest for the F6.1 course controller (F6.1-US1, US2, US5).

  Drives the real plug pipeline (endpoint → router → controller → view) with
  `server: false` (no bound port). `async: false` plus the `Portal.Store`/stream/
  engine reset in `PortalWeb.ConnCase` give per-test fold isolation against the
  branded-id collision hazard (echo/CLAUDE.md §4).
  """
  use PortalWeb.ConnCase, async: false

  alias Portal.Accounts.User
  alias Portal.Catalog.Course

  describe "GET /health" do
    test "returns 200 with body \"ok\" and touches no domain (F6.1-R6)", %{conn: conn} do
      conn = get(conn, ~p"/health")
      assert response(conn, 200) == "ok"
    end
  end

  describe "GET /courses/:user_id" do
    test "a known enrolled user renders that user's course row (F6.1-US2)", %{conn: conn} do
      # Seed a real User + Course in the Store, then enroll through the facade so the
      # dual-write %Enrollment{} read model has the row courses_of/1 reads.
      user = %User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada"}
      course = %Course{id: Portal.ID.new("CRS"), title: "Elixir", slug: "elixir"}
      :ok = Portal.Store.put(user)
      :ok = Portal.Store.put(course)
      {:ok, _enrollment} = Portal.enroll(user.id, course.id)

      conn = get(conn, ~p"/courses/#{user.id}")
      body = html_response(conn, 200)

      # The rendered row carries the enrolled course id and its progress (0 at F6.1).
      assert body =~ course.id
      assert body =~ "0%"
      refute body =~ "No courses yet."
    end

    test "an unknown user id renders the empty state at 200, never a 500 (F6.1-US5)", %{conn: conn} do
      # courses_of/1 is total at F6.1: an unknown id yields {:ok, []} → empty state.
      conn = get(conn, ~p"/courses/#{Portal.ID.new("USR")}")
      body = html_response(conn, 200)
      assert body =~ "No courses yet."
    end

    test "a malformed user id still renders the empty state at 200 (F6.1-US5)", %{conn: conn} do
      # "USR1" passes namespace/1 but fails valid?/1; the total facade returns no rows,
      # so the page is a clean 200 empty state — not a 422 and not a 500.
      conn = get(conn, ~p"/courses/USR1")
      body = html_response(conn, 200)
      assert body =~ "No courses yet."
    end
  end

  describe "the defensive 422 error-render path (F6.1-INV4, D-2)" do
    # courses_of/1 is success-only at F6.1, so the {:error, %Portal.Error{}} arm is
    # not request-reachable; it is proven here by INJECTING a %Portal.Error{} straight
    # into render_outcome/2 (the controller's error clause), exercising the 422 render
    # of the :error template. This path goes live-reachable when the facade gains
    # id-validation (a later F6 rung).
    test "an injected %Portal.Error{} renders 422 with the closed-set message", %{conn: conn} do
      error = %Portal.Error{code: :course_not_found, message: "course not found"}

      # render/3 negotiates on the format and the controller's view; a real request
      # gets both from the :browser pipeline (`plug :accepts`) and the controller
      # action wiring, so set them directly for this unit-level call into the error
      # clause.
      conn =
        conn
        |> Phoenix.Controller.put_format("html")
        |> Phoenix.Controller.put_view(html: PortalWeb.CourseHTML)

      conn = PortalWeb.CourseController.render_outcome(conn, {:error, error})

      assert conn.status == 422
      assert html_response(conn, 422) =~ "course not found"
    end

    test "the :error template renders the message from assigns only (F6.1-R5)" do
      error = %Portal.Error{code: :already_enrolled, message: "already enrolled in this course"}

      rendered =
        Phoenix.Template.render_to_string(PortalWeb.CourseHTML, "error", "html", error: error)

      assert rendered =~ "already enrolled in this course"
    end
  end
end
