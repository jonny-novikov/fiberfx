defmodule PortalWeb.CatalogComponents do
  @moduledoc """
  Catalog function components (F6.5-D2/D3/R9).

  The declared, reusable markup units the catalog templates compose: `course_card/1`
  (one catalog row), `panel/1` (a slot-based frame), and a minimal local `input/1`
  (a text field + inline per-field changeset error). `input/1` lives here, NOT in a
  generated `CoreComponents` — this umbrella was hand-built without `mix phx.gen.*`,
  so no `CoreComponents` exists (F6.5-INV8), and one create form earns one minimal
  input rather than a kitchen-sink module. `<.form>`/`<.link>` come from
  `Phoenix.Component`; they are not redefined here. Every link is a verified `~p`
  route (F6.5-INV3); user data is HEEx-escaped (F6.5-INV2).

  Uses `Phoenix.Component` + `PortalWeb`'s verified routes DIRECTLY, not
  `use PortalWeb, :html` — the `:html` macro imports THIS module (the slot a generated
  app's `CoreComponents` import fills), so `use PortalWeb, :html` here would be a
  self-import while the module is being defined (the same reason a generated
  `CoreComponents` uses `Phoenix.Component` directly).
  """
  use Phoenix.Component
  use PortalWeb, :verified_routes

  @doc """
  One catalog course as an `<article>`: the title as a `~p` link to the catalog
  `:show`, plus a published badge when `course.published` (F6.5-D2). `attr`s are
  declared so a missing required `:course` is a compile warning (F6.5-INV4). Called
  with `:for` from the index over `@courses`.
  """
  attr(:course, :map, required: true)
  attr(:class, :string, default: "")

  def course_card(assigns) do
    ~H"""
    <article class={["course-card", @class]} data-course-card>
      <.link navigate={~p"/courses/#{@course.id}"} data-course-link>{@course.title}</.link>
      <span :if={@course.published} data-published-badge>Published</span>
    </article>
    """
  end

  @doc """
  A slot-based frame: renders caller content via `render_slot/1` inside a `<section>`
  (F6.5-D3). The default `:inner_block` slot makes `<.panel>…</.panel>` wrap any
  markup.
  """
  slot(:inner_block, required: true)

  def panel(assigns) do
    ~H"""
    <section class="panel" data-panel>
      {render_slot(@inner_block)}
    </section>
    """
  end

  @doc """
  A minimal text input bound to a `Phoenix.HTML.FormField` (F6.5-R9). Renders an
  optional `<label>`, the `<input>` wired to `@field.id`/`@field.name`/`@field.value`,
  and an inline per-field error list from `@field.errors`. Self-contained — it has no
  `<.label>`/`<.error>` partners and references no `CoreComponents` or unexported
  `Phoenix.Component` `input` (F6.5-INV8). The view adds no validation; the errors
  come straight from the F6.3 changeset carried on the field (F6.5-INV5/INV6).
  """
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:type, :string, default: "text")

  def input(assigns) do
    ~H"""
    <div class="field" data-field>
      <label :if={@label} for={@field.id}>{@label}</label>
      <input
        type={@type}
        id={@field.id}
        name={@field.name}
        value={Phoenix.HTML.Form.normalize_value(@type, @field.value)}
      />
      <ul :if={@field.errors != []} data-field-errors>
        <li :for={{msg, _opts} <- @field.errors}>{msg}</li>
      </ul>
    </div>
    """
  end
end
