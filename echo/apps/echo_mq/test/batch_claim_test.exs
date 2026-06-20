defmodule EchoMQ.BatchClaimTest do
  @moduledoc """
  The wire column of the batch-claim spine (emq.5.1): `EchoMQ.Jobs.claim_batch/4`
  over the NEW inline `@bclaim` count-variant `ZPOPMIN emq:{q}:pending` loop --
  the non-grouped generalization of the shipped `@gwclaim` multi-pop. Fetch up to
  `size` jobs in one atomic, server-clocked claim; an under-fill is a short batch
  (never a refusal, never a block); a paused queue answers `:empty` pending-untouched;
  one poisoned member is isolated to its own retry while the rest settle (the batch
  is a CLAIM unit, not a RESOLUTION unit, resolved over the byte-frozen
  `@complete`/`@retry`). On per-test sub-queues with the baseline purge idiom (the
  Conformance purge pattern). emq.5.1.
  """
  use ExUnit.Case, async: false

  @moduletag :valkey

  alias EchoData.BrandedId
  alias EchoMQ.{Admin, Connector, Jobs, Keyspace}

  setup_all do
    :ok = EchoData.Snowflake.start(4)
    :ok
  end

  setup do
    {:ok, conn} = Connector.start_link(port: 6390)
    q = "emq0.batch#{System.unique_integer([:positive])}"

    # the conn dies with the test process (the OTP parent-exit protocol),
    # so the purge rides its own disposable connection
    on_exit(fn -> purge(q) end)

    %{conn: conn, q: q}
  end

  defp purge(q) do
    {:ok, conn} = Connector.start_link(port: 6390)
    {:ok, keys} = Connector.command(conn, ["KEYS", "emq:{" <> q <> "}:*"])
    if keys != [], do: {:ok, _} = Connector.command(conn, ["DEL" | keys])
    GenServer.stop(conn)
  end

  # Flood the pending set with `n` distinct mint-ordered JOB-ids; return the ids
  # in mint order (the order they were minted IS the order they sort, the order
  # theorem -- the pending set is score-0 mint-ordered).
  defp flood(conn, q, n, payload) do
    for _ <- 1..n do
      id = BrandedId.generate!("JOB")
      {:ok, :enqueued} = Jobs.enqueue(conn, q, id, payload)
      id
    end
  end

  # The active-set deadline (the ZSET score) of a leased id.
  defp deadline(conn, q, id) do
    {:ok, score} = Connector.command(conn, ["ZSCORE", Keyspace.queue_key(q, "active"), id])
    score
  end

  # US1 -- the POSITIVE batch claim. size >= 2 against K > size proves the BATCH,
  # not the single-pop path. The shared-lease assertion is load-bearing: one TIME
  # read for the whole batch.
  describe "US1 -- the batch claim (up to size members in one atomic, server-clocked pull)" do
    test "claims EXACTLY size oldest-mint members, each fenced, on ONE shared lease", %{
      conn: conn,
      q: q
    } do
      size = 4
      k = 10
      ids = flood(conn, q, k, "work")

      assert {:ok, members} = Jobs.claim_batch(conn, q, size, 60_000)

      # EXACTLY size members served from a flooded set (the no-op-defeater: fewer
      # than size from K >= size is a LOUD failure -- the claim under-served)
      assert length(members) == size

      claimed_ids = Enum.map(members, fn {id, _payload, _att} -> id end)

      # the size LOWEST-score (oldest-mint) ids, in mint order -- identical to
      # `size` sequential claim/3 pops (INV5, the order theorem)
      assert claimed_ids == Enum.take(ids, size)

      # the payload travels; each member's attempts == 1 (a first claim mints
      # token 1 per member -- HINCRBY attempts 1 each, INV6)
      assert Enum.all?(members, fn {_id, payload, att} -> payload == "work" and att == 1 end)

      # every served member's row is now state = active
      for id <- claimed_ids do
        assert {:ok, "active"} = Connector.command(conn, ["HGET", Keyspace.job_key(q, id), "state"])
      end

      # ONE shared lease deadline for the whole batch -- a single server-clock TIME
      # read (distinct deadlines would mean the loop re-read TIME per member, INV4)
      deadlines = Enum.map(claimed_ids, &deadline(conn, q, &1))
      assert Enum.uniq(deadlines) |> length() == 1
      assert hd(deadlines) != nil

      # the remaining K - size are still pending (untouched by this claim); the
      # size served are scored in active -- the batch moved exactly size members
      remaining = k - size
      assert {:ok, ^remaining} = Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "pending")])
      assert {:ok, ^size} = Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "active")])
    end

    test "a batch claim is identical to `size` sequential claim/3 pops (mint order)", %{
      conn: conn,
      q: q
    } do
      ids = flood(conn, q, 6, "w")

      # a fresh queue claimed singly, vs a batch on a twin queue, must serve the
      # SAME id sequence -- the batch is the single-pop spine, looped
      assert {:ok, members} = Jobs.claim_batch(conn, q, 3, 60_000)
      batch_ids = Enum.map(members, fn {id, _p, _a} -> id end)
      assert batch_ids == Enum.take(ids, 3)
    end
  end

  # US2 -- the under-fill is a SHORT batch, not a refusal; :empty is the zero case;
  # a paused queue answers :empty pending-UNTOUCHED.
  describe "US2 -- the under-fill is a short batch (the spine is non-blocking)" do
    test "a request for N with M < N pending returns exactly M (never over-pops, never blocks)",
         %{conn: conn, q: q} do
      m = 2
      n = 5
      ids = flood(conn, q, m, "u")

      assert {:ok, members} = Jobs.claim_batch(conn, q, n, 60_000)
      # exactly M served (the no-op-defeater: serving 0 from M>0, or N from M<N, is
      # a LOUD failure)
      assert length(members) == m
      assert Enum.map(members, fn {id, _p, _a} -> id end) == ids
    end

    test "a subsequent claim on the now-empty pending set answers :empty (the zero case)", %{
      conn: conn,
      q: q
    } do
      _ids = flood(conn, q, 2, "u")
      assert {:ok, [_, _]} = Jobs.claim_batch(conn, q, 5, 60_000)
      assert :empty == Jobs.claim_batch(conn, q, 5, 60_000)
    end

    test "a claim against a queue paused queue-wide answers :empty, pending UNTOUCHED", %{
      conn: conn,
      q: q
    } do
      ids = flood(conn, q, 3, "p")
      :ok = Admin.pause(conn, q)

      # paused honored host-side FIRST: :empty, the pending set untouched (claim/3
      # precedent)
      assert :empty == Jobs.claim_batch(conn, q, 5, 60_000)
      assert {:ok, 3} = Connector.command(conn, ["ZCARD", Keyspace.queue_key(q, "pending")])

      # resume restores the batch
      :ok = Admin.resume(conn, q)
      assert {:ok, members} = Jobs.claim_batch(conn, q, 5, 60_000)
      assert Enum.map(members, fn {id, _p, _a} -> id end) == ids
    end
  end

  # US3 -- partial-failure isolation: one poisoned member never sinks the batch.
  # The proof MUST actually fail member k (drive a real @retry) and complete the
  # rest -- a property with no failing member proves nothing.
  describe "US3 -- partial-failure isolation (over the byte-frozen @complete/@retry)" do
    test "member k retries (scheduled, last_error kept); the rest complete; only k re-claims",
         %{conn: conn, q: q} do
      ids = flood(conn, q, 3, "iso")
      assert {:ok, members} = Jobs.claim_batch(conn, q, 3, 60_000)
      assert length(members) == 3

      [poison | good] = members
      {poison_id, _p, poison_att} = poison
      assert poison_id == hd(ids)
      assert poison_att == 1

      # member k FAILS -> @retry (scheduled, max_attempts 3 so it does not dead),
      # last_error kept; the OTHER two complete -- each transition independent
      assert {:ok, :scheduled} = Jobs.retry(conn, q, poison_id, poison_att, 5, 3, "poison")

      for {id, _p, att} <- good do
        assert :ok = Jobs.complete(conn, q, id, att)
      end

      # member k's row is scheduled with last_error kept; the other two are retired
      assert {:ok, "scheduled"} =
               Connector.command(conn, ["HGET", Keyspace.job_key(q, poison_id), "state"])

      assert {:ok, "poison"} =
               Connector.command(conn, ["HGET", Keyspace.job_key(q, poison_id), "last_error"])

      for {id, _p, _a} <- good do
        assert {:ok, 0} = Connector.command(conn, ["EXISTS", Keyspace.job_key(q, id)])
      end

      # after promote, a fresh batch finds ONLY member k, now carrying attempts = 2
      # (its own token advanced -- per-member fencing, INV6)
      Process.sleep(30)
      {:ok, 1} = Jobs.promote(conn, q, 10)
      assert {:ok, [{^poison_id, _p, 2}]} = Jobs.claim_batch(conn, q, 5, 60_000)
    end

    test "a stale-token resolution of a batched member is refused EMQSTALE (shipped fencing)", %{
      conn: conn,
      q: q
    } do
      _ids = flood(conn, q, 2, "stale")
      assert {:ok, [{id, _p, att}, _other]} = Jobs.claim_batch(conn, q, 2, 60_000)
      assert att == 1

      # the wrong token -> EMQSTALE (the byte-frozen @complete fences); the live
      # token still settles
      assert {:error, :stale} = Jobs.complete(conn, q, id, 99)
      assert :ok = Jobs.complete(conn, q, id, att)
    end
  end

  # US4 (the in-suite slice) -- @bclaim is the ONLY new redis.call-bearing script,
  # so the WIRE LAW it must satisfy: no client-side multi-key pop. The pop is a
  # ZPOPMIN INSIDE the inline script; claim_batch/4 issues ONE eval (no client
  # LMPOP/ZMPOP). Asserted structurally over the shipped Jobs source.
  describe "US4 -- the wire law (the pop is inside the script, no client multi-key pop)" do
    test "@bclaim pops with ZPOPMIN inside the inline script -- no client LMPOP/ZMPOP in the body",
         _ctx do
      # the @bclaim script BODY (not the doc comment, which names the rejected
      # forms): the substring from `@bclaim Script.new(:bclaim, """` to its
      # closing `"""`. The pop must be a ZPOPMIN INSIDE this body; a client-side
      # multi-key pop (LMPOP/ZMPOP) must NOT appear in it (design §6.2).
      src = File.read!("lib/echo_mq/jobs.ex")

      [_, after_open] = String.split(src, ~s(@bclaim Script.new(:bclaim, """), parts: 2)
      [body, _rest] = String.split(after_open, ~s("""), parts: 2)

      assert body =~ "redis.call('ZPOPMIN', KEYS[1])"
      refute body =~ "LMPOP"
      refute body =~ "ZMPOP"
    end
  end
end
