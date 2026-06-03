defmodule Portal.EventStore.Postgres do
  @moduledoc """
  The Postgres `Portal.EventStore` adapter (F5.8) — a **signature-only stub** at
  this rung. The production counterpart of `Portal.EventStore.InMemory`,
  interchangeable by `config :portal, :event_store` (F5.8-INV4).

  Both callbacks return `{:error, :not_implemented}` so the module satisfies the
  behaviour and the config switch compiles (`MIX_ENV=prod mix compile` stays green)
  with **no new dependency**: no `use Ecto.*`, no `postgrex`. The Ecto schema,
  migration, and the real append/read body are F6.3 — that rung adds the deps and
  fills the body behind this unchanged signature.
  """
  @behaviour Portal.EventStore

  @impl Portal.EventStore
  def append(_stream, _events), do: {:error, :not_implemented}

  @impl Portal.EventStore
  def read_stream(_stream), do: {:error, :not_implemented}
end
