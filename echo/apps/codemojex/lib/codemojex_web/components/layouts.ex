defmodule CodemojexWeb.Layouts do
  @moduledoc """
  The LiveView layouts. `root` is the HTML shell rendered once per HTTP request; it
  loads the LiveView client (`/assets/app.js`) and the lobby CSS — both Phoenix-
  served from this machine's priv/static. The React board bundle is deliberately
  absent here; it is fetched from static.codemoji.games at runtime by the EdgeReact
  hook. `app` wraps the live content with the flash group.
  """
  use CodemojexWeb, :html

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="ru" class="cm">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <.live_title default="Codemoji">{assigns[:page_title]}</.live_title>
        <script src="https://telegram.org/js/telegram-web-app.js"></script>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
        </script>
      </head>
      <body class="cm-body">
        {@inner_content}
      </body>
    </html>
    """
  end

  def app(assigns) do
    ~H"""
    <main class="cm-main">
      <.flash_group flash={@flash} />
      {@inner_content}
    </main>
    """
  end

  # A minimal flash group (no external component library pulled in).
  def flash_group(assigns) do
    ~H"""
    <div id="flash-group" class="flash-group">
      <p :if={msg = Phoenix.Flash.get(@flash, :info)} class="flash flash--info" phx-click={JS.hide(to: ".flash--info")}>
        {msg}
      </p>
      <p :if={msg = Phoenix.Flash.get(@flash, :error)} class="flash flash--error" phx-click={JS.hide(to: ".flash--error")}>
        {msg}
      </p>
    </div>
    """
  end
end
