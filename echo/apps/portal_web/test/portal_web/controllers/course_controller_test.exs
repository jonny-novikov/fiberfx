defmodule PortalWeb.CourseControllerTest do
  @moduledoc """
  ConnTest for the F6.5 catalog controller (F6.5-D1/D8/D9/INV5) plus the retained
  domain-free liveness route (F6.1-R6).

  `CourseController` is the pure catalog resource after the F6.5 reconcile: `index`
  (the list), `show` (one course), `new`/`create` (the form). The enrolled read and
  its defensive `422` moved to `EnrollmentController` (`/my/courses`), so those tests
  live in `enrollment_controller_test.exs` now.

  Drives the real plug pipeline (endpoint → router → controller → view) with
  `server: false` (no bound port). `async: false` plus the `Portal.Store`/stream/
  engine reset in `PortalWeb.ConnCase` give per-test fold isolation against the
  branded-id collision hazard (echo/CLAUDE.md §4).

  `portal_web` has NO Ecto sandbox, so a `Portal.create_course/1` insert COMMITS and
  the catalog (`list_courses/0`) is GLOBAL and accumulates across runs. The list and
  empty state are therefore proven by a DIRECT TEMPLATE RENDER (the DB is never empty
  after any create test), mirroring the `:error` template-render pattern; the
  request-level tests seed with a strong-random title token so `unique_constraint(:title)`
  never collides with a prior run's committed row.
  """
  use PortalWeb.ConnCase, async: false

  alias Portal.Catalog.Course

  # A strong-random title token: `portal_web` has no Ecto sandbox, so a create COMMITS —
  # a resettable counter would collide with a prior run's committed row.
  defp token, do: Base.encode16(:crypto.strong_rand_bytes(8))

  describe "GET /health" do
    test "returns 200 with body \"ok\" and touches no domain (F6.1-R6)", %{conn: conn} do
      conn = get(conn, ~p"/health")
      assert response(conn, 200) == "ok"
    end
  end

  describe "the index template (F6.5-D1, rendered directly)" do
    # The catalog list + empty state are proven by direct template render, not a route:
    # the global Repo is never empty after any create test, so a `get ~p"/courses"`
    # could not assert the empty state. Phoenix.Template.render_to_string mirrors the
    # existing :error template test pattern (no port, no domain call).
    test "an empty catalog renders the empty state" do
      rendered =
        Phoenix.Template.render_to_string(PortalWeb.CourseHTML, "index", "html", courses: [])

      assert rendered =~ "No courses yet."
    end

    test "a catalog row renders the title, the ~p show link, and the published badge" do
      # A %Course{} struct literal (data, not a facade bypass) carrying published: true,
      # the only way to exercise the badge's :if branch — `create_course/1` defaults
      # published to false. The id is a real branded CRS id so the ~p link is exact.
      course = %Course{
        id: Portal.ID.new("CRS"),
        title: "Pattern Matching",
        slug: "pattern-matching",
        published: true
      }

      rendered =
        Phoenix.Template.render_to_string(PortalWeb.CourseHTML, "index", "html",
          courses: [course]
        )

      assert rendered =~ "Pattern Matching"
      assert rendered =~ ~p"/courses/#{course.id}"
      assert rendered =~ "data-published-badge"
      refute rendered =~ "No courses yet."
    end
  end

  describe "GET /courses/:id (show, F6.5-D8)" do
    test "renders the course title at 200", %{conn: conn} do
      tok = token()
      {:ok, course} = Portal.create_course(%{title: "Elixir #{tok}", slug: "elixir-#{tok}"})

      conn = get(conn, ~p"/courses/#{course.id}")
      body = html_response(conn, 200)

      assert body =~ "Elixir #{tok}"
    end
  end

  describe "GET /courses/new (the create form, F6.5-D9)" do
    test "renders both required field inputs at 200", %{conn: conn} do
      conn = get(conn, ~p"/courses/new")
      body = html_response(conn, 200)

      # The form (`<.form action={~p"/courses"}>`) renders both validate_required fields
      # through the local <.input> (each a `data-field`), so a title-only form can never
      # validate. Asserting the labels + the field wrapper proves both inputs render.
      assert body =~ "data-field"
      assert body =~ "Title"
      assert body =~ "Slug"
    end
  end

  describe "POST /courses (create, F6.5-D5/INV5)" do
    test "valid params create the course and redirect to its show page", %{conn: conn} do
      tok = token()

      conn =
        post(conn, ~p"/courses", %{
          "course" => %{"title" => "Elixir #{tok}", "slug" => "elixir-#{tok}"}
        })

      # On {:ok, course} the controller redirects to the catalog :show.
      assert redirected_to(conn) =~ "/courses/"
    end

    test "invalid params re-render the form at 200 with the inline field error (INV5)", %{
      conn: conn
    } do
      # title "ab" fails validate_length(min: 3) and slug "" fails validate_required, so
      # changeset/2 returns {:error, changeset}; the controller re-renders :new at 200
      # (never a redirect), surfacing the per-field error through `data-field-errors`.
      conn =
        post(conn, ~p"/courses", %{"course" => %{"title" => "ab", "slug" => ""}})

      body = html_response(conn, 200)
      assert body =~ "data-field-errors"
    end
  end
end
