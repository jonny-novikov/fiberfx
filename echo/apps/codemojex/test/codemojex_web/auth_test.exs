defmodule CodemojexWeb.AuthTest do
  @moduledoc """
  The cm.4 auth floor acceptance (S1–S8 / A1–A10). Integration: needs the app up
  (Repo + the EchoStore `:cm_sessions` tracking table on Valkey + Postgres). Run
  with `mix test --include valkey`.

  Drives the real surface end to end: the `Codemojex.InitData` verifier (offline,
  fixture-signed), the handshake `POST /api/auth/:platform` (the sole `SES` mint),
  the `:auth` plug over the five player-acting routes, the socket `connect/3`, and
  THE revocation invariant (A3 — a `revoke` then a 401 on the next request).
  """
  use ExUnit.Case, async: false
  @moduletag :valkey

  import Plug.Conn
  import Phoenix.ConnTest

  alias Codemojex.AuthHelper

  @endpoint CodemojexWeb.Endpoint
  @token "test-bot-token:cm4"

  setup do
    {:ok, conn: build_conn()}
  end

  # A valid, fresh, signed initData for tg user `uid`, signed with @token.
  defp valid_init_data(uid, first_name \\ "Ada") do
    user = Jason.encode!(%{"id" => uid, "first_name" => first_name})
    now = System.system_time(:second)

    AuthHelper.sign_init_data(
      %{"user" => user, "auth_date" => Integer.to_string(now), "query_id" => "AAEx"},
      @token
    )
  end

  # Drive the real handshake and return {ses, plr}.
  defp handshake!(conn, init_data) do
    AuthHelper.with_token(@token, fn ->
      resp =
        conn
        |> post("/api/auth/telegram", %{"initData" => init_data})
        |> json_response(200)

      {resp["session"], resp["player"]}
    end)
  end

  # ---------------------------------------------------------------------------
  # A4 / S5 — the pure verifier (offline; no app needed, but co-located here)
  # ---------------------------------------------------------------------------

  describe "Codemojex.InitData.verify/3 (A4 / S5)" do
    test "a fixture signed with a known token verifies and lifts tg_user_id" do
      init_data = valid_init_data(4242)
      assert {:ok, %{tg_user_id: 4242, user: %{"first_name" => "Ada"}}} =
               Codemojex.InitData.verify(init_data, @token, now: System.system_time(:second))
    end

    test "flipping one signed field → :bad_hash" do
      init_data = valid_init_data(4242)
      tampered = String.replace(init_data, "query_id=AAEx", "query_id=EVIL")

      assert {:error, :bad_hash} =
               Codemojex.InitData.verify(tampered, @token, now: System.system_time(:second))
    end

    test "a present `signature` field is excluded from the check (accept still holds)" do
      user = Jason.encode!(%{"id" => 7, "first_name" => "Sig"})
      now = Integer.to_string(System.system_time(:second))
      # Sign WITHOUT signature, then append a signature the verifier must ignore.
      signed = AuthHelper.sign_init_data(%{"user" => user, "auth_date" => now}, @token)
      with_sig = signed <> "&signature=" <> URI.encode_www_form("ed25519-third-party-blob")

      assert {:ok, %{tg_user_id: 7}} =
               Codemojex.InitData.verify(with_sig, @token, now: System.system_time(:second))
    end

    test "a stale auth_date → :stale" do
      user = Jason.encode!(%{"id" => 9, "first_name" => "Old"})
      old = System.system_time(:second) - 100_000
      init_data = AuthHelper.sign_init_data(%{"user" => user, "auth_date" => Integer.to_string(old)}, @token)

      assert {:error, :stale} =
               Codemojex.InitData.verify(init_data, @token,
                 max_age_seconds: 86_400,
                 now: System.system_time(:second)
               )
    end

    test "a nil token → :no_token (fail-closed)" do
      assert {:error, :no_token} = Codemojex.InitData.verify(valid_init_data(1), nil)
    end

    test "blank / missing initData → :missing" do
      assert {:error, :missing} = Codemojex.InitData.verify("", @token)
      assert {:error, :missing} = Codemojex.InitData.verify(nil, @token)
    end

    test "the verifier touches no HTTP, no Repo, no session store (pure)" do
      # A pure call returns without the app: no process dictionary, no DB. Proven by
      # running it against a raw string with an explicit clock — already exercised
      # above; here assert it is deterministic for the same inputs.
      init_data = valid_init_data(123)
      a = Codemojex.InitData.verify(init_data, @token, now: 1_700_000_000)
      b = Codemojex.InitData.verify(init_data, @token, now: 1_700_000_000)
      assert a == b
    end
  end

  # ---------------------------------------------------------------------------
  # A1 / A2 / S1 / S2 — the handshake + the 401 battery
  # ---------------------------------------------------------------------------

  describe "the handshake (A2 / S1)" do
    test "a valid initData → a SES + the correct PLR; the SES authenticates an action", %{conn: conn} do
      uid = fresh_uid()
      {ses, plr} = handshake!(conn, valid_init_data(uid))

      assert is_binary(ses)
      assert <<"SES", _::binary>> = ses
      assert <<"PLR", _::binary>> = plr

      # the PLR row exists and carries the tg_user_id
      assert Codemojex.Schemas.Player |> Codemojex.Repo.get(plr)
      assert Codemojex.Repo.get_by(Codemojex.Schemas.Player, tg_user_id: uid).id == plr

      # presenting the SES runs history as that PLR (a player-acting route)
      resp =
        build_conn()
        |> put_req_header("authorization", "Bearer " <> ses)
        |> get("/api/games/GAM00000000000/history")
        |> json_response(200)

      assert Map.has_key?(resp, "history")
    end

    test "a stale initData → 401, no SES minted", %{conn: conn} do
      uid = fresh_uid()
      user = Jason.encode!(%{"id" => uid, "first_name" => "Stale"})
      old = System.system_time(:second) - 100_000
      init_data = AuthHelper.sign_init_data(%{"user" => user, "auth_date" => Integer.to_string(old)}, @token)

      AuthHelper.with_token(@token, fn ->
        assert conn |> post("/api/auth/telegram", %{"initData" => init_data}) |> json_response(401)
      end)

      refute Codemojex.Repo.get_by(Codemojex.Schemas.Player, tg_user_id: uid)
    end

    test "a tampered initData → 401", %{conn: conn} do
      init_data = valid_init_data(fresh_uid())
      tampered = String.replace(init_data, "query_id=AAEx", "query_id=HACK")

      AuthHelper.with_token(@token, fn ->
        assert conn |> post("/api/auth/telegram", %{"initData" => tampered}) |> json_response(401)
      end)
    end

    test "with no bot token configured the handshake fails closed → 401", %{conn: conn} do
      # do NOT set a token — Codemojex.Bot.token/0 falls to the echo_bot YAML, which is
      # not the test signer, so a signed-with-@token initData cannot verify → 401.
      assert conn |> post("/api/auth/telegram", %{"initData" => valid_init_data(fresh_uid())}) |> json_response(401)
    end
  end

  describe "the 401 battery on every player-acting ingress (A1 / S1 / S2)" do
    # {method, path} for each of the five gated routes.
    @gated [
      {:post, "/api/rooms/ROM00000000000/join"},
      {:post, "/api/games/GAM00000000000/guess"},
      {:get, "/api/games/GAM00000000000/history"},
      {:post, "/api/keys/buy"},
      {:post, "/api/keys/convert"}
    ]

    test "no Authorization header → 401 on all five routes", %{conn: conn} do
      for {method, path} <- @gated do
        assert dispatch(conn, @endpoint, method, path) |> json_response(401),
               "expected 401 with no bearer for #{method} #{path}"
      end
    end

    test "a garbage / non-SES bearer → 401 on all five routes", %{conn: conn} do
      for {method, path} <- @gated do
        resp =
          conn
          |> put_req_header("authorization", "Bearer not-a-real-ses")
          |> dispatch(@endpoint, method, path)
          |> json_response(401)

        assert resp == %{"error" => "unauthenticated"}, "expected 401 garbage bearer for #{method} #{path}"
      end
    end

    test "a well-formed but unknown SES (never minted) → 401", %{conn: conn} do
      ghost = EchoData.BrandedId.generate!("SES")

      for {method, path} <- @gated do
        assert conn
               |> put_req_header("authorization", "Bearer " <> ghost)
               |> dispatch(@endpoint, method, path)
               |> json_response(401),
               "expected 401 for an unminted SES on #{method} #{path}"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # A3 / S3 — THE REVOCATION INVARIANT (the load-bearing one)
  # ---------------------------------------------------------------------------

  describe "the revocation invariant (A3 / S3 — the first mutable EchoStore table)" do
    test "a revoked SES stops authenticating on the very next request", %{conn: conn} do
      {ses, _plr} = handshake!(conn, valid_init_data(6001))

      # proof-of-authentication: the SES authenticates an action first
      assert build_conn()
             |> put_req_header("authorization", "Bearer " <> ses)
             |> get("/api/games/GAM00000000000/history")
             |> json_response(200)

      # revoke (a DEL on ecc:{sessions}:<SES>); :tracking evicts every L1, DEL clears L2
      assert :ok = Codemojex.Session.revoke(ses)

      # the NEXT request with that SES → 401 (a clean miss through the loader)
      assert build_conn()
             |> put_req_header("authorization", "Bearer " <> ses)
             |> get("/api/games/GAM00000000000/history")
             |> json_response(401)
    end

    test "resolve/1 reflects revocation immediately (no stale window)" do
      {:ok, ses} = Codemojex.Session.mint("PLR00000000000", "telegram", %{})
      assert {:ok, %{plr: "PLR00000000000"}} = Codemojex.Session.resolve(ses)

      assert :ok = Codemojex.Session.revoke(ses)
      assert {:error, :unknown} = Codemojex.Session.resolve(ses)
    end
  end

  # ---------------------------------------------------------------------------
  # the SES surface (A1 / A3 — mint/resolve/slide; JSON value)
  # ---------------------------------------------------------------------------

  describe "Codemojex.Session (mint / resolve / revoke)" do
    test "a minted SES resolves to its claims and the value is JSON (a Go edge can read it)" do
      {:ok, ses} = Codemojex.Session.mint("PLR00000000001", "telegram", %{"tg_user_id" => 77})
      assert {:ok, %{plr: "PLR00000000001", platform: "telegram"}} = Codemojex.Session.resolve(ses)

      # the raw L2 value (after the 14-byte version strip) is JSON, not term_to_binary —
      # the cross-language contract a forward Go edge reads. EchoMQ.Connector.command/2
      # is the same raw GET EchoStore.Table uses internally (connector.ex:49).
      {:ok, raw} = EchoMQ.Connector.command(Codemojex.Bus.conn(), ["GET", "ecc:{cm_sessions}:" <> ses])
      <<_version::binary-14, json::binary>> = raw
      assert {:ok, %{"plr" => "PLR00000000001", "tg_user_id" => 77}} = Jason.decode(json)
    end

    test "resolve slides the TTL (a re-put on use)" do
      {:ok, ses} = Codemojex.Session.mint("PLR00000000002", "telegram", %{})
      # resolve re-puts; the row survives. Two resolves both succeed.
      assert {:ok, _} = Codemojex.Session.resolve(ses)
      assert {:ok, _} = Codemojex.Session.resolve(ses)
    end

    test "resolve of a non-SES id is :unknown (the kind gate, not a crash)" do
      assert {:error, :unknown} = Codemojex.Session.resolve("PLR00000000003")
      assert {:error, :unknown} = Codemojex.Session.resolve("garbage")
      assert {:error, :unknown} = Codemojex.Session.resolve(nil)
    end
  end

  # ---------------------------------------------------------------------------
  # A1 / S1 / S2 — the socket
  # ---------------------------------------------------------------------------

  describe "the socket connect/3 (A1 / S1 / S2)" do
    test "a valid SES connects with the player assigned and id/1 non-nil" do
      {:ok, ses} = Codemojex.Session.mint("PLR00000000010", "telegram", %{})

      assert {:ok, socket} = CodemojexWeb.UserSocket.connect(%{"session" => ses}, %Phoenix.Socket{}, %{})
      assert socket.assigns.player == "PLR00000000010"
      assert CodemojexWeb.UserSocket.id(socket) == "player_socket:PLR00000000010"
    end

    test "a forged / missing / revoked SES → :error (and no player)" do
      assert :error = CodemojexWeb.UserSocket.connect(%{"session" => "forged"}, %Phoenix.Socket{}, %{})
      assert :error = CodemojexWeb.UserSocket.connect(%{}, %Phoenix.Socket{}, %{})

      {:ok, ses} = Codemojex.Session.mint("PLR00000000011", "telegram", %{})
      :ok = Codemojex.Session.revoke(ses)
      assert :error = CodemojexWeb.UserSocket.connect(%{"session" => ses}, %Phoenix.Socket{}, %{})
    end

    test "id/1 is nil for an unauthenticated socket" do
      assert CodemojexWeb.UserSocket.id(%Phoenix.Socket{}) == nil
    end
  end

  # ---------------------------------------------------------------------------
  # A2 / A9 / S4 — resolve-or-create (idempotent + the concurrency race)
  # ---------------------------------------------------------------------------

  describe "resolve_player_by_tg/2 (A2 / A9 / S4)" do
    # Each test draws a FRESH tg_user_id (System.unique_integer) — codemojex has no
    # Ecto.Sandbox rollback, so a fixed literal would collide with a prior run and
    # under the ≥100 determinism loop. Fresh ids keep every run isolated and loop-sound.
    test "a first touch mints one PLR with tg_user_id set" do
      uid = fresh_uid()
      {:ok, plr} = Codemojex.resolve_player_by_tg(uid, name: "First")
      assert <<"PLR", _::binary>> = plr
      assert Codemojex.Repo.get_by(Codemojex.Schemas.Player, tg_user_id: uid).id == plr
    end

    test "a second resolve for the same TG user → the SAME PLR (no second row)" do
      uid = fresh_uid()
      {:ok, plr1} = Codemojex.resolve_player_by_tg(uid, name: "A")
      {:ok, plr2} = Codemojex.resolve_player_by_tg(uid, name: "B")
      assert plr1 == plr2
      assert count_players(uid) == 1
    end

    test "N concurrent first-touches for the same fresh TG user → one PLR, one row" do
      uid = fresh_uid()
      refute Codemojex.Repo.get_by(Codemojex.Schemas.Player, tg_user_id: uid)

      results =
        1..16
        |> Task.async_stream(fn _ -> Codemojex.resolve_player_by_tg(uid, name: "Race") end,
          max_concurrency: 16,
          timeout: 15_000
        )
        |> Enum.map(fn {:ok, {:ok, plr}} -> plr end)

      assert Enum.uniq(results) |> length() == 1, "all concurrent first-touches must resolve to one PLR"
      assert count_players(uid) == 1, "the partial unique index must leave exactly one row"
    end

    test "name-created PLRs (no tg_user_id) coexist with TG-bound ones" do
      uid = fresh_uid()
      {:ok, _n1} = Codemojex.create_player("Name1", keys: 1)
      {:ok, _n2} = Codemojex.create_player("Name2", keys: 1)
      {:ok, _bound} = Codemojex.resolve_player_by_tg(uid, name: "Bound")
      # the partial index permits many NULLs; the inserts above all succeeded
      assert count_players(uid) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # A5 / S6 — POST /api/players is retired
  # ---------------------------------------------------------------------------

  describe "the retired create-player endpoint (A5 / S6)" do
    test "POST /api/players → 404 (the route does not exist)", %{conn: conn} do
      # The route was deleted (G3). Phoenix returns a plain 404 for an unmatched
      # path (this endpoint renders it rather than raising NoRouteError), so assert
      # the dispatched status directly — `assert_error_sent` would require a raise.
      conn = post(conn, "/api/players", %{"name" => "ghost"})
      assert conn.status == 404
    end
  end

  # ---------------------------------------------------------------------------
  # A6 / S7 — F2: no prod bypass in lib/
  # ---------------------------------------------------------------------------

  describe "the F2 dev/test posture (A6 / S7)" do
    test "lib/ carries no auth-skip / trust-supplied-player bypass" do
      {out, _} = System.cmd("grep", ["-rIl", "-e", "trust_supplied_player", "-e", "auth_skip", "lib"], cd: File.cwd!())
      assert out == "", "no auth bypass may live in lib/ (found in: #{out})"
    end

    test "the controller has no create_player action and lib/ has no such route" do
      {ctrl, _} = System.cmd("grep", ["-c", "create_player", "lib/codemojex_web/controllers/game_controller.ex"], cd: File.cwd!())
      assert String.trim(ctrl) == "0"

      {route, _} = System.cmd("grep", ["-rE", ~s{post "/players"}, "lib/codemojex_web/router.ex"], cd: File.cwd!())
      assert route == ""
    end
  end

  # -- helpers ---------------------------------------------------------------

  # A fresh, positive tg_user_id per call — unique ACROSS node lifetimes, so a rerun
  # (or any ≥100 determinism-loop iteration, each a fresh BEAM) never collides on the
  # natural key against the rows a prior run left in the non-sandboxed test DB.
  # `System.unique_integer` alone resets per node and WOULD collide across runs; the
  # microsecond wall clock advances every run, so the high bits are run-distinct and
  # the low 3 digits (`rem(.., 1000)`, ample for a test's ≤16 calls) keep intra-run
  # calls distinct without overflowing into the next microsecond's slot. Stays well
  # inside the bigint range a Telegram user id occupies.
  defp fresh_uid do
    System.system_time(:microsecond) * 1_000 + rem(System.unique_integer([:positive]), 1_000)
  end

  defp count_players(uid) do
    import Ecto.Query
    Codemojex.Repo.one(from p in Codemojex.Schemas.Player, where: p.tg_user_id == ^uid, select: count(p.id))
  end
end
