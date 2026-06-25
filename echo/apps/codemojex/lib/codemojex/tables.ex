defmodule Codemojex.Tables do
  @moduledoc """
  The EchoStore near-cache tier, made first-class for production.

  Two declared L1-over-L2 caches sit in front of Postgres on the scoring hot
  path, each keyed by a branded id and each holding an entity that is immutable
  for its life — so the cache never goes stale and the coherence mode is
  `:none`:

    * `:cm_games` (`GAM`) — a game and its secret, read on every guess score.
    * `:cm_emojisets` (`EMS`) — an emoji set's layout, read alongside the game.

  A third table holds the auth sessions and is the FIRST mutable one:

    * `:cm_sessions` (`SES`) — a verified player's session (cm.4), keyed by a
      `SES` branded id, holding a JSON `{plr, platform, …}` value. Because a
      session is mutable and revocable, its coherence mode is `:tracking` (RESP3
      `CLIENT TRACKING`): Valkey itself pushes an invalidation on any write or
      `DEL` to `ecc:{sessions}:`, so a revoked session is evicted from every
      BEAM holder's L1 immediately — the property that makes revocation a
      security guarantee, not best-effort. (`:none` here would be a defect: a
      revoked `SES` surviving in L1 would keep authenticating.) The value is
      JSON, not `term_to_binary`, so a forward Go lightweight edge can read the
      same row.

  A read is a caller-side `:ets.lookup` against the table's public, read-
  concurrent ETS table; a miss coalesces onto one in-flight fill that checks L2
  (the shared Valkey) and falls through to the loader (the relational system of
  record). Both layers are then written under the table's TTL.

  The `EchoStore.Directory` the tables register into is supervised first under
  `:rest_for_one`, so if it ever restarts the tables restart with it and re-
  register — the cache roster cannot silently empty out from under the readers.

  The durable page tier (the Graft committer, EchoStore folding to Tigris) is a
  separate concern, wired in `Codemojex.Application` when a `:graft_volume` is
  configured.
  """
  use Supervisor

  alias Codemojex.Store

  @games :cm_games
  @sets :cm_emojisets
  @sessions :cm_sessions

  @doc "The games near-cache name (`GAM`)."
  def games_table, do: @games
  @doc "The emoji-sets near-cache name (`EMS`)."
  def sets_table, do: @sets
  @doc "The auth-sessions table name (`SES`) — the first mutable one (`:tracking`)."
  def sessions_table, do: @sessions

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 6390)
    connector = [port: port, protocol: 3]

    games_ttl = Application.get_env(:codemojex, :games_cache_ttl_ms, 600_000)
    sets_ttl = Application.get_env(:codemojex, :sets_cache_ttl_ms, 3_600_000)
    # The SES lifetime (sliding): a resolve re-puts the row, re-stamping the
    # version + PX deadline, so an active player never re-handshakes mid-play.
    # A generous default; Operator-tunable.
    sessions_ttl = Application.get_env(:codemojex, :sessions_ttl_ms, 86_400_000)

    children = [
      # The cache directory the tables register into. Started first so a restart
      # cascades to the tables below (rest_for_one) and they re-register, rather
      # than leaving the roster pointing at a dead ETS owner.
      %{
        id: EchoStore.Directory,
        start: {GenServer, :start_link, [EchoStore.Directory, :ok, [name: EchoStore.Directory]]}
      },
      Supervisor.child_spec(
        {EchoStore.Table,
         name: @games,
         kind: "GAM",
         loader: &load_game/1,
         coherence: :none,
         ttl_ms: games_ttl,
         max_size: 50_000,
         connector: connector},
        id: :cm_games_table
      ),
      Supervisor.child_spec(
        {EchoStore.Table,
         name: @sets,
         kind: "EMS",
         loader: &load_set/1,
         coherence: :none,
         ttl_ms: sets_ttl,
         max_size: 10_000,
         connector: connector},
        id: :cm_emojisets_table
      ),
      # The auth sessions — the FIRST mutable table (cm.4). `:tracking` so a
      # revoke (a DEL on ecc:{sessions}:<SES>) is pushed by Valkey and evicts the
      # row from every BEAM holder's L1 immediately. The loader is a clean miss
      # (a SES has no relational system of record — it lives only in Valkey), so
      # an unknown/expired/revoked SES is a fetch miss → the :auth plug 401s.
      Supervisor.child_spec(
        {EchoStore.Table,
         name: @sessions,
         kind: "SES",
         loader: &load_session/1,
         coherence: :tracking,
         ttl_ms: sessions_ttl,
         max_size: 100_000,
         connector: connector},
        id: :cm_sessions_table
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  # --- loaders: the relational system of record, framed for the cache --------
  # The loader runs on an L2 miss. It returns `{:ok, binary, version}` with the
  # entity's own 14-byte branded id as the version, so the L2 frame carries the
  # name the value belongs to; `{:error, :not_found}` is a clean miss.

  @doc false
  def load_game(<<_::binary-14>> = game_id) do
    case Store.game(game_id) do
      nil -> {:error, :not_found}
      map -> {:ok, :erlang.term_to_binary(map), game_id}
    end
  end

  @doc false
  def load_set(<<_::binary-14>> = set_id) do
    case Store.set(set_id) do
      nil -> {:error, :not_found}
      %Codemojex.EmojiSet{} = set -> {:ok, :erlang.term_to_binary(set), set_id}
    end
  end

  # A SES has no relational system of record — it lives only in Valkey (ephemeral).
  # The loader therefore answers a CLEAN MISS for any id not already in L1/L2, so a
  # fetch for an unknown/expired/revoked SES is a miss → `Codemojex.Session.resolve/1`
  # maps it to `{:error, :unknown}` → the plug 401s. (Contrast the games loader, which
  # falls through to Postgres; a session has no such floor.)
  @doc false
  def load_session(<<_::binary-14>> = _ses), do: {:error, :not_found}
end
