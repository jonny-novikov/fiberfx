defmodule PortalWeb.EnrollmentControllerTest do
  @moduledoc """
  ConnTest for the enrollment controller (F6.2-US6, F6.2-D1 + F6.5-D0).

  Covers both actions `EnrollmentController` owns after the F6.5 reconcile:

    * `create/2` — the write route `post "/enroll"`: a success redirects to the joined
      course's catalog `:show`, and a non-existent course yields the closed-set
      `:course_not_found` failure at `422`.
    * `index/2` — the protected read `get "/my/courses"`: the enrolled-list read MOVED
      here from `CourseController`, so the learner's-courses tests and the defensive
      `422` error-render tests moved with it. The read targets the protected route
      (session-injected `user_id`, no path param) — the pre-F6.5 public
      `/courses/:user_id` is gone.

  `async: false` plus the `Portal.Store`/stream/engine reset in `PortalWeb.ConnCase`
  give per-test fold isolation against the branded-id collision hazard
  (echo/CLAUDE.md §4). `portal_web` has no Ecto sandbox, so a `Portal.create_course/1`
  insert COMMITS; each seed uses a strong-random title token so the
  `unique_constraint(:title)` never collides with a prior run's committed row.
  """
  use PortalWeb.ConnCase, async: false

  alias Portal.Accounts.User

  describe "POST /enroll (the write route)" do
    test "a valid enroll redirects to the joined course's catalog page (F6.2-US6)", %{conn: conn} do
      user = %User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada"}
      :ok = Portal.Store.put(user)
      # Since F6.4 the Catalog is Repo-backed: seed the course through the facade
      # (`Portal.create_course/1`) so the engine's enroll gate (`Catalog.fetch_course/1`
      # -> Repo) sees it. The test still names only `Portal` (INV2), never a context/Repo.
      tok = Base.encode16(:crypto.strong_rand_bytes(8))
      {:ok, course} = Portal.create_course(%{title: "Elixir #{tok}", slug: "elixir-#{tok}"})

      conn = post(conn, ~p"/enroll", %{"user_id" => user.id, "course_id" => course.id})

      # Since the F6.5 reconcile the redirect targets the joined course's catalog
      # `:show` (`~p"/courses/#{course.id}"`), not a learner-courses path.
      assert redirected_to(conn) == ~p"/courses/#{course.id}"
    end

    test "enrolling into a non-existent course renders the closed-set 422", %{conn: conn} do
      user = %User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada"}
      :ok = Portal.Store.put(user)

      conn = post(conn, ~p"/enroll", %{"user_id" => user.id, "course_id" => Portal.ID.new("CRS")})

      assert html_response(conn, 422) =~ "course not found"
    end
  end

  describe "GET /my/courses (the protected enrolled read, F6.5-D0)" do
    # The read moved here from CourseController; the route is now the PROTECTED
    # `/my/courses` (session `user_id`, no path param). Since F6.8.1 the gate
    # (`PortalWeb.UserAuth`) loads `current_user` (a %User{} via Portal.Auth) and
    # `EnrollmentController.index` reads the loaded user's id; a session id that does
    # NOT resolve to a real user is no longer authenticated (F6.8.1-INV5) and redirects
    # to `/login` rather than being admitted to an empty state (the pre-F6.8.1 behavior).
    test "a known enrolled user renders that user's course row (F6.1-US2)", %{conn: conn} do
      # Seed a real User (Store) + Course, then enroll through the facade so the
      # dual-write %Enrolled{} read model has the row courses_of/1 reads. Since F6.4
      # the Catalog is Repo-backed: the course is seeded via `Portal.create_course/1`
      # (the engine's enroll gate reads it through the Repo). The test names only
      # `Portal` (INV2), never a context/Repo.
      user = %User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada"}
      :ok = Portal.Store.put(user)
      tok = Base.encode16(:crypto.strong_rand_bytes(8))
      {:ok, course} = Portal.create_course(%{title: "Elixir #{tok}", slug: "elixir-#{tok}"})
      {:ok, _enrollment} = Portal.enroll(user.id, course.id)

      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get(~p"/my/courses")

      body = html_response(conn, 200)

      # The rendered row carries the enrolled course id and its progress (0 at F6.1).
      assert body =~ course.id
      assert body =~ "0%"
      refute body =~ "No courses yet."
    end

    test "an unresolvable user id is not authenticated and redirects to /login (F6.8.1-INV5)", %{
      conn: conn
    } do
      # A well-formed but unseeded USR id does not resolve to a real %User{}, so since
      # F6.8.1 the gate treats the request as anonymous and redirects to /login (never a
      # 500, and no longer the pre-F6.8.1 admit-to-empty-state). The protected action is
      # not reached.
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: Portal.ID.new("USR")})
        |> get(~p"/my/courses")

      # Rejected by a clean redirect, NOT a 500 and NOT the pre-F6.8.1 admit-to-empty-
      # state: the gate halts on the unloaded user (INV5), so the status is a redirect.
      assert conn.status in [302, 303]
      assert redirected_to(conn) == ~p"/login"
      assert conn.halted == true
    end

    test "a malformed user id is not authenticated and redirects to /login (F6.8.1-INV5)", %{
      conn: conn
    } do
      # "USR1" passes namespace/1 but fails valid?/1; Portal.Auth.user/1 yields :error, so
      # the gate redirects to /login — not a 422, not a 500, not an admitted empty state.
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: "USR1"})
        |> get(~p"/my/courses")

      # A malformed id must not crash the gate — a redirect status, never a 500.
      assert conn.status in [302, 303]
      assert redirected_to(conn) == ~p"/login"
      assert conn.halted == true
    end
  end

  describe "the defensive 422 error-render path (F6.1-INV4, D-2)" do
    # courses_of/1 is success-only at F6.1, so the {:error, %Portal.Error{}} arm is
    # not request-reachable; it is proven here by INJECTING a %Portal.Error{} straight
    # into render_outcome/2 (the controller's error clause), exercising the 422 render
    # of the :error template. The read + its error template moved to EnrollmentController
    # / EnrollmentHTML in the F6.5 reconcile. This path goes live-reachable when the
    # facade gains id-validation (a later F6 rung).
    test "an injected %Portal.Error{} renders 422 with the closed-set message", %{conn: conn} do
      error = %Portal.Error{code: :course_not_found, message: "course not found"}

      # render/3 negotiates on the format and the controller's view; a real request
      # gets both from the :browser pipeline (`plug :accepts`) and the controller
      # action wiring, so set them directly for this unit-level call into the error
      # clause.
      conn =
        conn
        |> Phoenix.Controller.put_format("html")
        |> Phoenix.Controller.put_view(html: PortalWeb.EnrollmentHTML)

      conn = PortalWeb.EnrollmentController.render_outcome(conn, {:error, error})

      assert conn.status == 422
      assert html_response(conn, 422) =~ "course not found"
    end

    test "the :error template renders the message from assigns only (F6.1-R5)" do
      error = %Portal.Error{code: :already_enrolled, message: "already enrolled in this course"}

      rendered =
        Phoenix.Template.render_to_string(PortalWeb.EnrollmentHTML, "error", "html", error: error)

      assert rendered =~ "already enrolled in this course"
    end
  end
end
