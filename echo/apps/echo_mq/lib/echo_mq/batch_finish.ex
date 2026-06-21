defmodule EchoMQ.BatchFinish do
  @moduledoc """
  The batch RESOLVE half's pure partition core: a claimed batch resolves as a
  partition `%{completed, retried, dead, delayed}` over its members, with no
  process, no clock, and no I/O. The `EchoMQ.BatchShaper.Core` sibling
  (`batch_shaper/core.ex`) on the RESOLVE side that the shaper is on the START
  side -- emq.5.2 split the flush decision OUT of the `EchoMQ.BatchConsumer`
  process so the central START decision is pure and doctested; emq.5.4 applies
  the same split to the central RESOLVE decision. emq.5.4.

  The claim half (emq.5.1/5.2/5.3) gives the worker ways to CLAIM a batch; the
  partition is the REPORT of where every member of a resolved batch went, made
  an EXHAUSTIVE, DISJOINT classification so "the batch resolved" is a closure
  over checks, not prose: every claimed member lands in EXACTLY one bucket
  (exhaustive -- no member dropped, no member invented), and no member lands in
  two (disjoint).

  The verdict vocabulary is the emq.5.2 `:ok | {:error, reason}` map extended
  with the `{:delay, ms}` variant (the `EchoMQ.BatchConsumer.settle/3` third
  branch). A member's bucket is read from the OUTCOME of its transition, not
  asserted by the caller -- in particular `dead` EMERGES when the byte-frozen
  `EchoMQ.Jobs.retry/7` returns `{:ok, :dead}` at the attempts cap
  (`jobs.ex:807-834`), so a member the handler asked to `{:error, reason}`
  (retry) but which had exhausted its attempts lands in `dead`, NOT `retried`.
  `partition/2` consumes a `%{id => {verdict, outcome}}` map -- the asked
  verdict (which transition was attempted) paired with the verdict's resolved
  outcome (`EchoMQ.Jobs.complete/5`/`retry/7`/`delay/6` returns) -- and routes:

    * `{:ok, :ok}` -> `completed` (a `:ok` verdict whose `complete/5` returned
      `:ok`);
    * `{{:delay, _ms}, :ok}` -> `delayed` (a `{:delay, ms}` verdict whose
      `delay/6` returned `:ok`);
    * `{{:error, _reason}, {:ok, :dead}}` -> `dead` (a retry that hit the cap
      -- the OUTCOME, not the verdict);
    * `{{:error, _reason}, _other}` -> `retried` (a retry that scheduled, or a
      stale/gone outcome -- the member is no longer the caller's to complete,
      so it is reported retried, never silently completed).

  A member ABSENT from the outcome map lands fail-safe in `retried` (the
  emq.5.2 "missing verdict" discipline -- unprocessed work is never reported
  completed). The buckets hold the member ids in input order.
  """

  @typedoc "A member's asked verdict (the emq.5.2 vocabulary + the emq.5.4 `{:delay, ms}` variant)."
  @type verdict :: :ok | {:error, term()} | {:delay, non_neg_integer()}

  @typedoc "The resolved outcome of a member's transition (a `complete/5`/`retry/7`/`delay/6` return)."
  @type outcome :: term()

  @typedoc "The exhaustive, disjoint partition over a resolved batch's members."
  @type partition :: %{
          completed: [binary()],
          retried: [binary()],
          dead: [binary()],
          delayed: [binary()]
        }

  @doc """
  Partition a claimed batch over its resolved outcomes.

  `member_ids` is the list of claimed member ids (the order the buckets
  preserve). `resolved` is a `%{id => {verdict, outcome}}` map -- the asked
  verdict (the emq.5.2 vocabulary + `{:delay, ms}`) paired with that verdict's
  resolved outcome (a `complete/5`/`retry/7`/`delay/6` return). Returns the
  partition `%{completed, retried, dead, delayed}`, EXHAUSTIVE (every id in
  `member_ids` appears in exactly one bucket) and DISJOINT (no id in two).

  A member absent from `resolved` lands fail-safe in `retried` (the emq.5.2
  "missing verdict" -- unprocessed work is never reported completed). `dead`
  EMERGES from a retry whose outcome is `{:ok, :dead}` (the attempts cap), NOT
  from a caller verdict.

      iex> EchoMQ.BatchFinish.partition(
      ...>   ["JOBa", "JOBb", "JOBc", "JOBd"],
      ...>   %{
      ...>     "JOBa" => {:ok, :ok},
      ...>     "JOBb" => {{:error, "boom"}, {:ok, :scheduled}},
      ...>     "JOBc" => {{:error, "boom"}, {:ok, :dead}},
      ...>     "JOBd" => {{:delay, 5_000}, :ok}
      ...>   }
      ...> )
      %{completed: ["JOBa"], retried: ["JOBb"], dead: ["JOBc"], delayed: ["JOBd"]}

      iex> EchoMQ.BatchFinish.partition(
      ...>   ["JOBa", "JOBb"],
      ...>   %{"JOBa" => {:ok, :ok}}
      ...> )
      %{completed: ["JOBa"], retried: ["JOBb"], dead: [], delayed: []}
  """
  @spec partition([binary()], %{optional(binary()) => {verdict(), outcome()}}) :: partition()
  def partition(member_ids, resolved) when is_list(member_ids) and is_map(resolved) do
    empty = %{completed: [], retried: [], dead: [], delayed: []}

    member_ids
    |> Enum.reduce(empty, fn id, acc ->
      bucket = classify(Map.get(resolved, id, :missing))
      Map.update!(acc, bucket, &[id | &1])
    end)
    |> Map.new(fn {bucket, ids} -> {bucket, Enum.reverse(ids)} end)
  end

  # The bucket of one member, from the {verdict, outcome} pair. `dead` is read
  # from the retry OUTCOME ({:ok, :dead}), never the verdict; a stale/gone retry
  # outcome reports retried (the member is no longer the caller's, never
  # silently completed); an absent member fail-safe-retries (the emq.5.2
  # "missing verdict"). Pure -- a total function over the vocabulary.
  defp classify({:ok, :ok}), do: :completed
  defp classify({{:delay, _ms}, :ok}), do: :delayed
  defp classify({{:error, _reason}, {:ok, :dead}}), do: :dead
  defp classify({{:error, _reason}, _outcome}), do: :retried
  # a member absent from the outcome map -- fail-safe retried (unprocessed work
  # is never reported completed); any unrecognized pair is reported retried for
  # the same fail-safe reason (never a silent complete).
  defp classify(_other), do: :retried
end
