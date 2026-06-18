defmodule Codemojex.RateLimiter do
  @moduledoc """
  A token-bucket rate limiter sized for Telegram's send limits, used by the notification
  worker before every `sendMessage`.

  Telegram enforces roughly **30 messages/second** in aggregate to different chats and about
  **one message/second to a single chat** (short bursts tolerated). This limiter models both:
  a global bucket and a per-chat bucket, and a send is allowed only when *both* grant a token.
  `take/2` returns `:ok` (tokens taken from both buckets) or `{:wait, ms}` — the smallest delay
  after which a retry can succeed — which the worker turns into a delayed re-enqueue
  (`EchoMQ.Jobs.enqueue_in/5`). Buckets refill lazily from elapsed time, so the limiter holds
  no timers and one process serves every chat.

  Defaults (overridable via `start_link` opts): global rate 30/s burst 30; per-chat rate 1/s
  burst 3. Idle per-chat buckets are evicted on access once full, so memory tracks active
  chats, not all chats ever seen.
  """
  use GenServer

  @type t :: GenServer.server()

  defmodule Bucket do
    @moduledoc false
    @enforce_keys [:tokens, :updated_ms, :rate, :burst]
    defstruct [:tokens, :updated_ms, :rate, :burst]
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Try to take one token for `chat_id`. Returns `:ok` when both the global and the per-chat
  bucket grant, else `{:wait, ms}` with the minimum wait before a retry could succeed.
  """
  @spec take(t(), integer() | binary()) :: :ok | {:wait, non_neg_integer()}
  def take(server \\ __MODULE__, chat_id) do
    GenServer.call(server, {:take, to_string(chat_id)})
  end

  @impl true
  def init(opts) do
    now = now_ms()

    state = %{
      global: %Bucket{
        tokens: Keyword.get(opts, :global_burst, 30) * 1.0,
        updated_ms: now,
        rate: Keyword.get(opts, :global_rate, 30),
        burst: Keyword.get(opts, :global_burst, 30)
      },
      per_chat: %{},
      chat_rate: Keyword.get(opts, :chat_rate, 1),
      chat_burst: Keyword.get(opts, :chat_burst, 3)
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:take, chat_id}, _from, state) do
    now = now_ms()
    global = refill(state.global, now)
    chat = refill(chat_bucket(state, chat_id), now)

    cond do
      global.tokens < 1.0 ->
        {:reply, {:wait, wait_ms(global)}, %{state | global: global, per_chat: put_chat(state, chat_id, chat)}}

      chat.tokens < 1.0 ->
        {:reply, {:wait, wait_ms(chat)}, %{state | global: global, per_chat: put_chat(state, chat_id, chat)}}

      true ->
        global = %{global | tokens: global.tokens - 1.0}
        chat = %{chat | tokens: chat.tokens - 1.0}
        {:reply, :ok, %{state | global: global, per_chat: put_chat(state, chat_id, chat)}}
    end
  end

  # --- token-bucket math -----------------------------------------------------

  defp refill(%Bucket{} = b, now) do
    elapsed = max(now - b.updated_ms, 0)
    refilled = min(b.burst * 1.0, b.tokens + elapsed * b.rate / 1000.0)
    %{b | tokens: refilled, updated_ms: now}
  end

  # ms until the bucket has at least one token, given its refill rate.
  defp wait_ms(%Bucket{tokens: t, rate: rate}) when rate > 0 do
    deficit = 1.0 - t
    ceil(deficit / rate * 1000.0)
  end

  defp chat_bucket(state, chat_id) do
    Map.get_lazy(state.per_chat, chat_id, fn ->
      %Bucket{tokens: state.chat_burst * 1.0, updated_ms: now_ms(), rate: state.chat_rate, burst: state.chat_burst}
    end)
  end

  # Evict a chat bucket once it has refilled to full (idle); keep it otherwise.
  defp put_chat(state, chat_id, %Bucket{tokens: t, burst: burst}) when t >= burst,
    do: Map.delete(state.per_chat, chat_id)

  defp put_chat(state, chat_id, bucket), do: Map.put(state.per_chat, chat_id, bucket)

  defp now_ms, do: System.monotonic_time(:millisecond)
end
