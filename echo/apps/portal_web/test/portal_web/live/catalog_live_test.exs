defmodule PortalWeb.CatalogLiveTest do
  @moduledoc """
  LiveViewTest for `PortalWeb.CatalogLive` (F6.6) — the interactive `/courses` index.

  One test per F6.6 story's Given/When/Then: US0 (the live `/courses` route mounts and
  supersedes the static index), US1 (search-as-I-type narrows via the facade), US2
  (inline create inserts the row in place, a title-only submit surfaces the inline slug
  error), US3 (the two-stage disconnected/connected mount both paint), US4 (the list is
  a `phx-update="stream"`), US5 (the row reuses `course_card`, the view names only
  `Portal`).

  ## Isolation — path (b) with a per-test empty table (the §4 PK-collision fix)

  This umbrella shares ONE `Portal.Repo` across every app's suite, and the `:portal`
  `test_helper.exs` deliberately flips it to **`:auto` mode** after the `:portal` suite
  (F6.4): the out-of-band `Portal.Engine` process holds no sandbox owner, so `:manual`
  would crash it with a `DBConnection.OwnershipError`. Full `Phoenix.Ecto.SQL.Sandbox`
  wiring for the LiveView would have to flip that mode back and thread allowance through
  the LiveView process — fighting the F6.4 decision and touching production wiring — so
  it is out of proportion to this rung. So, like the sibling `PortalWeb.CourseControllerTest`,
  `Portal.create_course/1` here COMMITS (no rollback).

  The catch a committed-state suite hits — and the §4 hazard, now via the **Postgres
  primary key**: `create_course/1` mints `Portal.ID.new("CRS")` OUTSIDE the single-writer
  engine (a direct `Repo.insert`), and the `:bigint` id IS the PK with NO
  `unique_constraint(:id)` declared. So two same-millisecond seq-0 mints from two fresh
  processes (`@node = 1` fixes the worker — echo/CLAUDE.md §4) produce the SAME PK, and
  the second insert RAISES (`Ecto.ConstraintError`, not a graceful changeset error) — a
  flake the determinism loop surfaces (a single run, even multi-seed, does not). The
  reset trio in `ConnCase` cannot fix it: it empties the in-memory Store/event-log, not
  the committed `courses` table.

  The fix that makes the loop deterministic with NO production change: a `setup` that
  `delete_all`s `courses` so **each test starts from an EMPTY table**. A fresh seq-0
  mint at ms T then inserts into an empty table — even if a later test re-mints the same
  id, the prior row was already deleted, so no PK conflict can occur. The clean table is
  this suite's own (the engine/enroll tests never read `courses`), and `async: false`
  serializes it. Assertions stay **presence-of-my-row** (never count-based) for clarity,
  with a per-test token so titles are self-evidently unique.
  """
  use PortalWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias Portal.Catalog.Course

  # Each test owns an EMPTY `courses` table (the §4 PK-collision fix above). The Repo
  # runs :auto for this suite, so this committed delete is the deterministic substitute
  # for a sandbox rollback; the engine/enroll tests never touch `courses`, so clearing
  # it here isolates only this suite. A test naming `Portal.Repo` is test infrastructure
  # (the `:portal` DataCase does the same); it does NOT relax the production INV1 that
  # the WEB names only `Portal` — that is asserted by the US5 source guard below.
  setup do
    Portal.Repo.delete_all(Course)
    :ok
  end

  # A per-test token: titles are self-evidently unique (and a `unique_constraint(:title)`
  # can never trip on a prior test's row, which `setup` has deleted). Strong-random so it
  # also serves as a search term that matches nothing else.
  defp token, do: Base.encode16(:crypto.strong_rand_bytes(8))

  describe "US0 — one live URL for the catalog" do
    test "live /courses mounts CatalogLive and renders the catalog (US0)", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/courses")

      # The mounted module IS CatalogLive — the live index, not the static one.
      assert view.module == PortalWeb.CatalogLive

      # The disconnected first paint (the `live/2` return's third element) already carries
      # the catalog: the heading, the search box, and the create form.
      assert html =~ "Courses"
      assert has_element?(view, "[data-search-form]")
      assert has_element?(view, "[data-create-form]")
    end

    test "the live index supersedes the static GET /courses (US0)", %{conn: conn} do
      # The bare GET /courses is now served by the LiveView, not a controller :index — so
      # the disconnected render carries the interactive surfaces (search + create) that
      # only CatalogLive renders.
      conn = get(conn, ~p"/courses")
      body = html_response(conn, 200)

      assert body =~ "data-search-form"
      assert body =~ "data-create-form"
    end
  end

  describe "US1 — search as I type" do
    test "search narrows the list to the matching row via Portal.search_courses (US1)", %{
      conn: conn
    } do
      hit = token()
      miss = token()
      {:ok, kept} = Portal.create_course(%{title: "Keep #{hit}", slug: "keep-#{hit}"})
      {:ok, dropped} = Portal.create_course(%{title: "Drop #{miss}", slug: "drop-#{miss}"})

      {:ok, view, _html} = live(conn, ~p"/courses")

      # phx-change="search" fires handle_event("search", %{"q" => …}); rendering the
      # change with a query that matches only `kept` narrows the streamed list.
      rendered = render_change(element(view, "[data-search-form]"), %{"q" => "Keep #{hit}"})

      assert rendered =~ "Keep #{hit}"
      # The narrowing filter DROPS the non-matching row (stream reset: true), so the other
      # course is gone from the rendered list.
      refute rendered =~ "Drop #{miss}"

      # The matching row is present as a stream child / course_card; the dropped one is not.
      assert has_element?(view, ~s{[data-course-card]}, "Keep #{hit}")
      refute has_element?(view, ~s{[data-course-card]}, "Drop #{miss}")
      assert kept.title == "Keep #{hit}"
      assert dropped.title == "Drop #{miss}"
    end

    test "a search token that matches nothing renders no matching row (US1)", %{conn: conn} do
      {:ok, _course} = Portal.create_course(%{title: "Present #{token()}", slug: "p-#{token()}"})
      {:ok, view, _html} = live(conn, ~p"/courses")

      # A token that cannot occur in any committed title (path (b) — never assert an empty
      # catalog; assert ABSENCE of an impossible token as a ROW instead). The token echoes
      # in the controlled search input (`value={@query}`), so the absence is asserted on a
      # course card, not the whole render.
      never = "ZZZ-NO-MATCH-#{token()}"
      render_change(element(view, "[data-search-form]"), %{"q" => never})

      refute has_element?(view, "#courses [data-course-card]", never)
    end
  end

  describe "US2 — create without a reload" do
    test "a valid submit inserts the new row in place without a reload (US2)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/courses")

      tok = token()
      title = "Created #{tok}"

      rendered =
        view
        |> element("[data-create-form]")
        |> render_submit(%{"course" => %{"title" => title, "slug" => "created-#{tok}"}})

      # On {:ok, _} the view stream_inserts the new row at the top — it appears without a
      # reload (the OBSERVABLE post-condition of the success branch). The view also
      # `put_flash`es "Course created.", but this hand-built umbrella has no root layout
      # `<.flash_group>` rendering `@flash`, so the flash text is set on the socket and
      # never painted — asserting it here would be a false-green. The visible flash is a
      # layout concern outside F6.6; the success branch is proven by the inserted row.
      assert rendered =~ title
      assert has_element?(view, "#courses [data-course-card]", title)
    end

    test "a title-only submit re-renders the inline per-field errors (the slug can't be blank) (US2)",
         %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/courses")

      # slug omitted → Course.changeset/2's validate_required([:title, :slug]) rejects with
      # {:error, %Ecto.Changeset{}}; the view assigns to_form(changeset) and the F6.3 error
      # renders inline through the field's <ul data-field-errors> (INV5 — the view adds no
      # validation of its own).
      rendered =
        view
        |> element("[data-create-form]")
        |> render_submit(%{"course" => %{"title" => "Valid Title #{token()}"}})

      assert rendered =~ "data-field-errors"
      # The slug field's "can't be blank" (HEEx-escapes the apostrophe).
      assert rendered =~ "be blank"
      assert has_element?(view, "[data-field-errors]")
    end
  end

  describe "US3 — fast first paint (two-stage mount)" do
    test "the disconnected HTTP render paints the catalog at 200 (US3)", %{conn: conn} do
      # The first request renders WITHOUT a socket: a plain GET returns the full catalog
      # HTML (the indexable first paint) at 200.
      conn = get(conn, ~p"/courses")
      body = html_response(conn, 200)

      assert body =~ "Courses"
      assert body =~ "data-course-list"
    end

    test "the connected mount also paints the catalog (US3)", %{conn: conn} do
      # Once the socket connects, the connected mount takes over and paints the same
      # surfaces. `live/2` returns the CONNECTED view; rendering it proves the connected
      # stage paints (both stages assign the same stream + form, so the renders match).
      {:ok, view, _html} = live(conn, ~p"/courses")

      assert render(view) =~ "Courses"
      assert has_element?(view, "[data-course-list][phx-update=stream]")
    end
  end

  describe "US4 — large lists stay light (stream)" do
    test "the list container is phx-update=stream (US4)", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/courses")

      # The list is a stream: the container carries phx-update="stream" (rows live in the
      # DOM with server-side ids, never as a list in socket memory).
      assert html =~ ~s{phx-update="stream"}
      assert has_element?(view, "#courses[phx-update=stream]")
    end

    test "a created course appears via the stream (US4)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/courses")

      tok = token()
      title = "Streamed #{tok}"

      rendered =
        view
        |> element("[data-create-form]")
        |> render_submit(%{"course" => %{"title" => title, "slug" => "streamed-#{tok}"}})

      # stream_insert(_, at: 0) places the new row in the stream container — it shows up as
      # a course_card inside the #courses stream without a reload.
      assert rendered =~ title
      assert has_element?(view, "#courses [data-course-card]", title)
    end
  end

  describe "US5 — one interactive surface over the facade" do
    test "a row reuses the F6.5 course_card markup (US5)", %{conn: conn} do
      tok = token()
      {:ok, course} = Portal.create_course(%{title: "Reused #{tok}", slug: "reused-#{tok}"})

      {:ok, view, _html} = live(conn, ~p"/courses")

      # The streamed row is the reused <.course_card> (its data-course-card article with
      # the ~p show link), not duplicated row markup (INV6).
      assert has_element?(view, ~s{[data-course-card] [data-course-link]}, course.title)
      assert render(view) =~ ~p"/courses/#{course.id}"
    end

    test "the view source names only the Portal facade, no boundary leaks (US5)" do
      # Inspection-level guard (the deep grep is Apollo's): the view's CODE names only
      # `Portal`, never the Engine, a Repo, a context module, or GenServer.call. The
      # moduledoc/@doc heredocs intentionally NAME those forbidden surfaces in prose ("not
      # `Portal.Engine`, not a `Repo`…"), so the guard strips the doc blocks and `#`
      # comments first and asserts on the remaining code only. Anchored to this test
      # file's dir (CWD under `mix test` is the umbrella root, not the app) so the read
      # resolves regardless of where the suite is invoked.
      code =
        Path.join([__DIR__, "..", "..", "..", "lib", "portal_web", "live", "catalog_live.ex"])
        |> File.read!()
        |> strip_docs_and_comments()

      # The view DOES name the facade in code (the positive property).
      assert code =~ "Portal.search_courses"
      assert code =~ "Portal.create_course"
      # …and names nothing below the boundary in code (the negative property).
      refute code =~ "Portal.Engine"
      refute code =~ "Portal.Catalog."
      refute code =~ "Portal.Store"
      refute code =~ "Portal.Repo"
      refute code =~ "Repo."
      refute code =~ "GenServer.call"
    end
  end

  # Reduce a module source to its code lines: drop the `@moduledoc`/`@doc` heredoc blocks
  # (which legitimately mention the forbidden surfaces in prose) and `#` comment lines, so
  # the US5 facade-only guard inspects CALL SITES, not documentation.
  defp strip_docs_and_comments(source) do
    {kept, _in_doc?} =
      source
      |> String.split("\n")
      |> Enum.reduce({[], false}, fn line, {acc, in_doc?} ->
        trimmed = String.trim_leading(line)

        cond do
          # End of a doc heredoc.
          in_doc? and trimmed == "\"\"\"" -> {acc, false}
          # Inside a doc heredoc — drop the line.
          in_doc? -> {acc, true}
          # Start of a doc heredoc (`@moduledoc """` / `@doc """`).
          String.match?(trimmed, ~r/^@(module)?doc\s+"""/) -> {acc, true}
          # A whole-line `#` comment — drop it.
          String.starts_with?(trimmed, "#") -> {acc, in_doc?}
          # A code line — keep it.
          true -> {[line | acc], in_doc?}
        end
      end)

    kept |> Enum.reverse() |> Enum.join("\n")
  end
end
