defmodule PortalWeb.Presence do
  @moduledoc """
  Cluster-correct viewer tracking for the live catalog (F6.7-D5/R5/INV4).

  `use Phoenix.Presence` generates a CRDT-backed tracker over `Portal.PubSub` (the
  supervised PubSub server started in `Portal.Application`, F6.7-D1): `track/3` records a
  presence on a topic under a key, and the resulting `"presence_diff"` broadcasts let
  every node merge a count that is correct across the cluster — an ORSWOT delta-CRDT, not
  a single-node counter (INV4). `CatalogLive` tracks each connected socket under a unique
  key on the `"courses"` topic and recomputes a `viewers` count from `list/1` on each
  diff, so the count reflects connect and disconnect across nodes.

  This is a WEB-TIER process: its child lands in `PortalWeb.Application`
  (`application.ex`), NOT `Portal.Application`. `Portal.PubSub` lives in the `:portal`
  app, which boots first via the `:portal_web` → `:portal` app dependency, so the PubSub
  server this Presence names is up before this child starts. `Phoenix.Presence` ships
  inside `phoenix`, so it adds no dependency (F6.7-INV5: the only new `:portal_web` child
  is this module).

  ## Framing

  No gendered pronouns for agents; no perceptual or interior-state verbs; no first-person
  narration — carried from the F6.7 spec triad into this artifact.
  """
  use Phoenix.Presence,
    otp_app: :portal_web,
    pubsub_server: Portal.PubSub
end
