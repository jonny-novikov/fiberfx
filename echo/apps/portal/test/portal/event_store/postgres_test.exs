defmodule Portal.EventStore.PostgresTest do
  @moduledoc """
  DB sandbox tests for the F6.3 Postgres event-store adapter (F6.3-AS4/AS5,
  US3/US5/INV4/INV5). The engine NEVER routes here in tests (`:event_store` stays
  InMemory) — the adapter is exercised DIRECTLY. Runs in the Ecto sandbox
  (Portal.DataCase), `async: true`.
  """
  use Portal.DataCase, async: true

  alias Portal.EventStore.Event
  alias Portal.EventStore.Postgres
  alias Portal.Learning.Events.LearnerEnrolled
  alias Portal.Repo

  defp event(user, course) do
    %LearnerEnrolled{
      user_id: user,
      course_id: course,
      at: ~U[2026-01-01 00:00:00Z]
    }
  end

  test "append/2 then read_stream/1 returns the events in :seq order" do
    e1 = event("USRaaaaaaaaaaa", "CRSaaaaaaaaaaa")
    e2 = event("USRbbbbbbbbbbb", "CRSbbbbbbbbbbb")
    e3 = event("USRccccccccccc", "CRSccccccccccc")

    assert :ok = Postgres.append("portal", [e1, e2, e3])
    assert {:ok, rows} = Postgres.read_stream("portal")

    assert Enum.map(rows, & &1.seq) == [1, 2, 3]

    assert Enum.map(rows, & &1.data["user_id"]) ==
             ["USRaaaaaaaaaaa", "USRbbbbbbbbbbb", "USRccccccccccc"]

    assert Enum.all?(rows, &(&1.type == to_string(LearnerEnrolled)))
  end

  test "a second append continues the :seq monotonically per stream" do
    assert :ok = Postgres.append("portal", [event("USRaaaaaaaaaaa", "CRSaaaaaaaaaaa")])
    assert :ok = Postgres.append("portal", [event("USRbbbbbbbbbbb", "CRSbbbbbbbbbbb")])

    {:ok, rows} = Postgres.read_stream("portal")
    assert Enum.map(rows, & &1.seq) == [1, 2]
  end

  test "read_stream/1 isolates by stream" do
    assert :ok = Postgres.append("portal", [event("USRaaaaaaaaaaa", "CRSaaaaaaaaaaa")])
    assert :ok = Postgres.append("other", [event("USRbbbbbbbbbbb", "CRSbbbbbbbbbbb")])

    assert {:ok, [row]} = Postgres.read_stream("portal")
    assert row.data["user_id"] == "USRaaaaaaaaaaa"
  end

  test "a multi-row write rolls back fully on a forced failing step (F6.3-INV4)" do
    # Seed one event so a pre-append set exists.
    :ok = Postgres.append("portal", [event("USRaaaaaaaaaaa", "CRSaaaaaaaaaaa")])
    {:ok, before} = Postgres.read_stream("portal")
    assert length(before) == 1

    now = DateTime.utc_now() |> DateTime.truncate(:second)

    row = %{
      id: EchoData.Snowflake.generate(worker_id: 1),
      stream: "portal",
      seq: 99,
      type: to_string(LearnerEnrolled),
      data: %{"user_id" => "USRbbbbbbbbbbb"},
      inserted_at: now
    }

    # An Ecto.Multi whose first step really inserts a row, then a forced-failing
    # step aborts. The whole transaction rolls back, so the inserted row is undone
    # (D8/INV4) and the Multi returns the canonical {:error, step, reason, changes}.
    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(:insert_row, Event, [row])
      |> Ecto.Multi.run(:boom, fn _repo, _changes -> {:error, :forced_failure} end)
      |> Repo.transaction()

    assert {:error, :boom, :forced_failure, _changes} = result

    # The DB is unchanged: the pre-append set is intact, the :insert_row row did not
    # survive the rollback.
    {:ok, after_rollback} = Postgres.read_stream("portal")
    assert after_rollback == before
  end

  test "a successful Ecto.Multi commits and returns {:ok, _} (F6.3-D8)" do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    row = %{
      id: EchoData.Snowflake.generate(worker_id: 1),
      stream: "portal",
      seq: 1,
      type: to_string(LearnerEnrolled),
      data: %{"user_id" => "USRaaaaaaaaaaa"},
      inserted_at: now
    }

    result =
      Ecto.Multi.new()
      |> Ecto.Multi.insert_all(:insert_row, Event, [row])
      |> Repo.transaction()

    assert {:ok, %{insert_row: {1, _}}} = result
    assert {:ok, [_]} = Postgres.read_stream("portal")
  end
end
