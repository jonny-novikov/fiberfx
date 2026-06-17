defmodule EchoMQ.Cancel do
  @moduledoc """
  The cooperative cancellation token (worker-side): a primitive a long-running
  handler checks at a safe point so it stops its OWN work when asked, without a
  forced kill mid-transaction (the v1 `EchoMQ.CancellationToken` capability
  re-derived). emq.2.3-D7.

  (The module is `EchoMQ.Cancel`, not `EchoMQ.CancellationToken`: the frozen v1
  reference `apps/echomq` already defines `EchoMQ.CancellationToken`, and both
  apps load on one code path -- a same-named module would shadow the new bus
  non-deterministically. The capability is the v1 token's; the name is
  collision-free. emq.2.3 realization-over-literal, ledger L-1.)

  Host-side, NO wire identity: the token is a plain `make_ref()` and
  cancellation is a process message `{:emq_cancel, token, reason}` to the
  handler's mailbox. Cooperative -- a handler that never checks completes
  normally; the `^token` match ensures a handler only catches its OWN
  cancellation. `check/1` is a non-blocking `receive after 0`.

  This is the **worker-side** cooperative primitive ONLY. The **distributed**
  cancel -- a cancel issued from another node, coordinated across the cluster --
  is **emq.6** (ADR-2's family boundary); emq.2.3 ships the local token emq.6
  coordinates, it does not ship the distributed surface (INV7).
  """

  @type t :: reference()
  @type reason :: String.t() | atom() | nil

  defmodule Cancelled do
    @moduledoc """
    Raised by `EchoMQ.Cancel.check!/1` when the token is cancelled, so a
    checkpoint-style handler aborts at the check. Carries the cancel `reason`.
    """
    defexception [:reason]

    @impl true
    def message(%__MODULE__{reason: reason}), do: "job cancelled: #{inspect(reason)}"
  end

  @doc """
  Mint a new cancellation token: a unique reference that identifies a
  cancellation message. (the v1 `new/0`.)
  """
  @spec new() :: t()
  def new, do: make_ref()

  @doc """
  Flag the token cancelled: send `{:emq_cancel, token, reason}` to `pid`'s
  mailbox (the v1 `cancel/3`). The handler picks it up at its next `check/1`.
  The `reason` is optional. Answers `:ok`.
  """
  @spec cancel(pid(), t(), reason()) :: :ok
  def cancel(pid, token, reason \\ nil) when is_pid(pid) do
    send(pid, {:emq_cancel, token, reason})
    :ok
  end

  @doc """
  Non-blocking check (the v1 `check/1`): answer `{:cancelled, reason}` if a
  cancellation for THIS token is waiting in the current process mailbox, else
  `:ok`. O(1) -- a `receive after 0`. Consumes the cancellation message.
  """
  @spec check(t()) :: :ok | {:cancelled, reason()}
  def check(token) do
    receive do
      {:emq_cancel, ^token, reason} -> {:cancelled, reason}
    after
      0 -> :ok
    end
  end

  @doc """
  Check and raise `EchoMQ.Cancel.Cancelled` if cancelled (the v1 `check!/1`),
  for a checkpoint-style handler: call it at a safe point and the handler
  aborts at the check when cancelled, else continues. Answers `:ok`.
  """
  @spec check!(t()) :: :ok
  def check!(token) do
    case check(token) do
      :ok -> :ok
      {:cancelled, reason} -> raise Cancelled, reason: reason
    end
  end
end
