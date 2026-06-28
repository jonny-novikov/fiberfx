defmodule Codemojex.Schemas.Webhook do
  @moduledoc """
  An inbound PUSH-rail-event idempotency record (cm.7, WHK — FORWARD, the first push
  rail, on-chain TON). For a push-confirmation rail an on-chain/processor event
  arrives DECOUPLED from an order, so it is recorded by (rail, event_id) UNIQUE at
  ingress and matched to an order before it drives a settlement. For the Stars launch
  WHK folds into the OTX (rail, external_id) index (cm-7 D-5) — successful_payment is
  order-coupled, deduped by OTX directly — so the `webhooks` TABLE is NOT created this
  rung (no migration creates it). This schema is the designed-forward shape, defined
  so the first push rail adds its table cleanly; it has no live call site this rung.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}

  schema "webhooks" do
    field :rail, :string
    field :event_id, :string
    field :order_id, :string
    field :processed_at, :utc_datetime_usec
    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(whk, attrs) do
    whk
    |> cast(attrs, [:id, :rail, :event_id, :order_id, :processed_at])
    |> validate_required([:id, :rail, :event_id])
    |> unique_constraint([:rail, :event_id], name: :webhooks_rail_event_once_index)
  end
end
