defmodule PortalWeb.CatalogLiveTest do
  @moduledoc """
  LiveViewTest for `PortalWeb.CatalogLive` (F6.6 + F6.7) — the interactive `/courses` index.

  One test per F6.6 story's Given/When/Then: US0 (the live `/courses` route mounts and
  supersedes the static index), US1 (search-as-I-type narrows via the facade), US2
  (inline create inserts the row in place, a title-only submit surfaces the inline slug
  error), US3 (the two-stage disconnected/connected mount both paint), US4 (the list is
  a `phx-update="stream"`), US5 (the row reuses `course_card`, the view names only
  `Portal`).

  ## F6.7 real-time (the harden pass — the Given/When/Then the build did not yet prove)

  The cross-client behavioral acceptance for F6.7, each driven by REAL processes (the
  `async: false` serialization + the empty-table `setup` below carry over unchanged):

  - F6.7-US1/D7 — the real proof: TWO `live/2` connections (two separate LiveView
    processes, each subscribed on its connected mount); a create in one appears in the
    SECOND without a reload (the broadcast → `stream_insert` cross-client path).
  - F6.7-US2/INV1 — a write that fails validation broadcasts NOTHING (`refute_receive`
    after subscribing the test process); a successful one DOES (`assert_receive`), so a
    subscriber learns only of facts that committed.
  - F6.7-US3/INV6 — an `update_course/2` broadcast replaces the row in place keyed on
    the id (the updated title shows, no duplicate row).
  - F6.7-US4/INV4 — `@viewers` (`data-viewers`) tracks connect via `PortalWeb.Presence`;
    the async `presence_diff` is polled (`eventually/2`), never a bare `Process.sleep`.
  - F6.7-Gate-#2 — the ratified live-search × broadcast gate: a broadcast course that
    does NOT match the active `@query` is gated OUT of the stream; one that matches is
    inserted.
  - F6.7-US6/INV2 — the source guard below also covers the F6.7-edited code paths
    (subscribe/track/handle_info name only `Portal` + the web-tier `PortalWeb.Presence`).

  The `async: false` (shared Repo + the §4 id hazard) ALSO fences the `"courses"` PubSub
  topic: tests run serialized, so a sibling test's `{:course_created, _}` can never reach
  another test's subscribed process — which is what makes US2's `refute_receive` sound
  (a `refute` cannot be made specific by matching, so only serialization closes the
  cross-test bleed).

  ## Framing

  No gendered pronouns for agents; no perceptual or interior-state verbs; no first-person
  narration — carried from the F6.7 spec triad into this artifact.

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

  describe "F6.7-US1 — see others' changes live (two LiveView processes)" do
    test "a create in one connected view appears in a SECOND without a reload (US1/D7)", %{
      conn: conn
    } do
      # Two SEPARATE LiveView processes, each subscribed to "courses" on its own connected
      # mount (the F6.7-D3 seam). This is D7's core claim: the second view never issues the
      # write, yet the broadcast → handle_info → stream_insert path patches its DOM.
      {:ok, _view_a, _html_a} = live(conn, ~p"/courses")
      {:ok, view_b, _html_b} = live(Phoenix.ConnTest.build_conn(), ~p"/courses")

      tok = token()
      title = "CrossClient #{tok}"

      # Precondition: the new course is in NEITHER view before the write.
      refute render(view_b) =~ title

      # The write through the facade (NOT through view_b) — its ok-only broadcast fans out
      # over Portal.PubSub to every subscribed client, including view_b.
      {:ok, _course} = Portal.create_course(%{title: title, slug: "cc-#{tok}"})

      # `render/1` synchronizes view_b's process mailbox, so the broadcast's handle_info has
      # run by the time it returns — no reload, no Process.sleep. The row is present as a
      # course_card in view_b's stream container (its OWN DOM was patched, INV3).
      assert render(view_b) =~ title
      assert has_element?(view_b, "#courses [data-course-card]", title)
    end
  end

  describe "F6.7-US2 — broadcasts are honest (INV1)" do
    test "a write that FAILS validation broadcasts nothing (INV1)" do
      # No `conn`: this story subscribes the TEST process to "courses" through the facade
      # and drives the writes DIRECTLY (no `live/2`), so the only broadcast producers are
      # these facade calls — which is what makes the `refute_receive` below sound.
      # Attempt a create AND an update that each fail Course.changeset/2 (title < 3 chars →
      # validate_length).
      Portal.subscribe("courses")

      {:error, %Ecto.Changeset{}} = Portal.create_course(%{title: "ab", slug: "x-#{token()}"})

      # An update needs an existing row to ride; create a valid one FIRST (which DOES
      # broadcast — drained below), then drive it to an invalid changeset.
      {:ok, course} = Portal.create_course(%{title: "Valid #{token()}", slug: "v-#{token()}"})
      {:error, %Ecto.Changeset{}} = Portal.update_course(course, %{title: "no"})

      # The ONE legitimate broadcast is the valid create; drain exactly it, then assert no
      # broadcast from either failed write arrives. No `live/2` view is mounted here, so the
      # only producers are these direct facade writes (and `async: false` fences sibling
      # suites off the topic), which is what makes the `refute_receive` sound.
      assert_receive {:course_created, %Course{id: created_id}}
      assert created_id == course.id

      refute_receive {:course_created, _}
      refute_receive {:course_updated, _}
    end

    test "a SUCCESSFUL write broadcasts the fact (INV1)" do
      # The other half of INV1: a committed write DOES emit. Subscribe, create, and receive
      # the specific row — matching on the returned id so the assertion is about THIS write.
      Portal.subscribe("courses")

      {:ok, created} = Portal.create_course(%{title: "Honest #{token()}", slug: "h-#{token()}"})
      assert_receive {:course_created, %Course{id: id}}
      assert id == created.id

      {:ok, updated} = Portal.update_course(created, %{title: "Honest Renamed #{token()}"})
      assert_receive {:course_updated, %Course{id: ^id, title: new_title}}
      assert new_title == updated.title
    end
  end

  describe "F6.7-US3 — updates replace in place (INV6)" do
    test "an update broadcast replaces the row keyed on id, with no duplicate (INV6)", %{
      conn: conn
    } do
      tok = token()
      {:ok, course} = Portal.create_course(%{title: "Before #{tok}", slug: "b-#{tok}"})

      {:ok, view, _html} = live(conn, ~p"/courses")

      # The row appears exactly once at mount.
      assert has_element?(view, "#courses [data-course-card]", "Before #{tok}")

      new_title = "After #{tok}"
      {:ok, _updated} = Portal.update_course(course, %{title: new_title})

      # The {:course_updated, _} broadcast → stream_insert (no `at:`) replaces in place.
      # `render/1` syncs the mailbox. The new title shows; the old one is gone.
      rendered = render(view)
      assert rendered =~ new_title
      refute rendered =~ "Before #{tok}"

      # No duplicate: the stream keys on the course id, so the count of course cards bearing
      # this course's `~p` show link is exactly one (the row was replaced, not appended).
      links =
        view
        |> render()
        |> count_substring(~p"/courses/#{course.id}")

      assert links == 1
    end
  end

  describe "F6.7-US4 — a live viewer count (INV4)" do
    test "data-viewers tracks connect across two views via Presence (US4/INV4)", %{conn: conn} do
      # The connected mount tracks the socket (PortalWeb.Presence.track/3) and seeds
      # @viewers from the roster; a SECOND connect broadcasts a "presence_diff" that
      # recomputes the first view's count to 2 (CRDT-backed, INV4).
      {:ok, view_a, _html_a} = live(conn, ~p"/courses")
      assert has_element?(view_a, "[data-viewers]", "1 viewing")

      {:ok, view_b, _html_b} = live(Phoenix.ConnTest.build_conn(), ~p"/courses")
      assert has_element?(view_b, "[data-viewers]", "2 viewing")

      # The presence_diff to view_a is async; poll its render (NOT a bare Process.sleep)
      # until the count reflects the second viewer.
      assert eventually(fn -> render(view_a) =~ "2 viewing" end),
             "view_a's data-viewers never reached 2 after the second connect"
    end
  end

  describe "F6.7-Gate-#2 — the live-search × broadcast gate (RECONCILE)" do
    test "a broadcast course NOT matching the active @query is gated OUT (Gate-#2)", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/courses")

      # Narrow the live filter to a token that the incoming broadcast will NOT contain.
      filter = token()
      render_change(element(view, "[data-search-form]"), %{"q" => "Keep #{filter}"})

      # A create whose title does not match the active @query: its {:course_created, _}
      # reaches this view, but `matches?/2` gates it OUT — the row must NOT be inserted, so
      # a real-time create never breaks the learner's narrowed view.
      other = token()
      other_title = "Unrelated #{other}"
      {:ok, _course} = Portal.create_course(%{title: other_title, slug: "u-#{other}"})

      # render/1 syncs the mailbox; the gated-out course is absent from the stream.
      refute render(view) =~ other_title
      refute has_element?(view, "#courses [data-course-card]", other_title)
    end

    test "a broadcast course MATCHING the active @query IS inserted (Gate-#2)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/courses")

      # Narrow to a shared stem the incoming broadcast WILL contain (case-insensitive, the
      # in-memory mirror of search_courses/1's `ilike`).
      stem = token()
      render_change(element(view, "[data-search-form]"), %{"q" => stem})

      matching_title = "Course #{String.downcase(stem)} live"
      {:ok, _course} = Portal.create_course(%{title: matching_title, slug: "m-#{stem}"})

      # The course matches the active @query, so the broadcast inserts it (at: 0) — it
      # appears in the stream without a reload.
      assert render(view) =~ matching_title
      assert has_element?(view, "#courses [data-course-card]", matching_title)
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

    test "the F6.7-edited real-time paths name only Portal + the web-tier Presence (US6/INV2)" do
      # F6.7-US6/INV2: the real-time code the harden pass exercises (subscribe on the
      # connected mount, track, the handle_info broadcast clauses) must reach real-time
      # ONLY through the facade — `Portal.subscribe/1` over `Portal.PubSub`, never
      # `Phoenix.PubSub` directly — plus the WEB-TIER `PortalWeb.Presence` (the one new
      # :portal_web child, INV5). Same doc/comment-stripped CODE inspection as US5.
      code =
        Path.join([__DIR__, "..", "..", "..", "lib", "portal_web", "live", "catalog_live.ex"])
        |> File.read!()
        |> strip_docs_and_comments()

      # The positive property: the view subscribes through the facade and tracks/​counts
      # through the web-tier Presence module.
      assert code =~ "Portal.subscribe"
      assert code =~ "PortalWeb.Presence.track"
      assert code =~ "PortalWeb.Presence.list"

      # The negative property: real-time never names the transport (`Phoenix.PubSub`) or
      # the context broadcast helper directly — those live BELOW the facade (INV2). The
      # `Phoenix.LiveView`/`Phoenix.Component` framework imports are not `Phoenix.PubSub`,
      # so this substring is exact.
      refute code =~ "Phoenix.PubSub"
      refute code =~ "Portal.broadcast"
    end
  end

  # Poll a predicate until it holds or the budget runs out (F6.7-US4) — the idiomatic
  # handling of an ASYNC `presence_diff` (a Presence track on one socket broadcasts the
  # diff that recomputes another view's `@viewers`). It re-evaluates `fun` between short
  # sleeps rather than a single bare `Process.sleep`, so it returns as soon as the diff has
  # landed and only waits the full budget on an actual failure. Returns true/false; the
  # caller asserts on it with a message. 50 × 10 ms = a 500 ms ceiling — ample for an
  # in-node CRDT diff, bounded so a regression fails fast rather than hanging.
  defp eventually(fun, tries \\ 50) do
    cond do
      fun.() ->
        true

      tries == 0 ->
        false

      true ->
        Process.sleep(10)
        eventually(fun, tries - 1)
    end
  end

  # Count non-overlapping occurrences of `needle` in `haystack` (F6.7-US3/INV6) — the
  # no-duplicate-row proof: an update broadcast must REPLACE the row keyed on the course
  # id, so the course's `~p` show link appears exactly once in the rendered stream, never
  # twice. A plain `=~` only proves presence; this proves multiplicity.
  defp count_substring(haystack, needle) do
    haystack |> String.split(needle) |> length() |> Kernel.-(1)
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
