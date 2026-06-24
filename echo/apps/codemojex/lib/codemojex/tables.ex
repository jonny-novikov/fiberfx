defmodule Codemojex.Tables do
  @moduledoc """
  The EchoStore near-cache tier, made first-class for production.

  Two declared L1-over-L2 caches sit in front of Postgres on the scoring hot
  path, each keyed by a branded id and each holding an entity that is immutable
  for its life — so the cache never goes stale and the coherence mode is
  `:none`:

    * `:cm_rounds` (`RND`) — a round and its secret, read on every guess score.
    * `:cm_emojisets` (`EMS`) — an emoji set's layout, read alongside the round.

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

  @rounds :cm_rounds
  @sets :cm_emojisets

  @doc "The rounds near-cache name (`RND`)."
  def rounds_table, do: @rounds
  @doc "The emoji-sets near-cache name (`EMS`)."
  def sets_table, do: @sets

  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, 6390)
    connector = [port: port, protocol: 3]

    rounds_ttl = Application.get_env(:codemojex, :rounds_cache_ttl_ms, 600_000)
    sets_ttl = Application.get_env(:codemojex, :sets_cache_ttl_ms, 3_600_000)

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
         name: @rounds,
         kind: "RND",
         loader: &load_round/1,
         coherence: :none,
         ttl_ms: rounds_ttl,
         max_size: 50_000,
         connector: connector},
        id: :cm_rounds_table
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
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  # --- loaders: the relational system of record, framed for the cache --------
  # The loader runs on an L2 miss. It returns `{:ok, binary, version}` with the
  # entity's own 14-byte branded id as the version, so the L2 frame carries the
  # name the value belongs to; `{:error, :not_found}` is a clean miss.

  @doc false
  def load_round(<<_::binary-14>> = round_id) do
    case Store.round(round_id) do
      nil -> {:error, :not_found}
      map -> {:ok, :erlang.term_to_binary(map), round_id}
    end
  end

  @doc false
  def load_set(<<_::binary-14>> = set_id) do
    case Store.set(set_id) do
      nil -> {:error, :not_found}
      %Codemojex.EmojiSet{} = set -> {:ok, :erlang.term_to_binary(set), set_id}
    end
  end
end
