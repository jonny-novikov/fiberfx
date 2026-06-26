defmodule CodemojexWeb.PageController do
  @moduledoc """
  The web home page: the Codemoji logo centered on a neutral-grey field. Plain HTML
  (not the JSON API) served via `html/2` — codemojex has no HTML layout/view tier.
  The logo is a Phoenix static asset (`priv/static/assets/cm-logo.png`, served by the
  endpoint's `Plug.Static` at `/assets`).
  """
  use CodemojexWeb, :controller

  @home_html """
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Codemojex</title>
    <style>
      html, body { margin: 0; height: 100%; }
      body {
        background: rgb(140, 140, 140);
        display: flex;
        align-items: center;
        justify-content: center;
      }
      img { max-width: 80vmin; max-height: 80vmin; height: auto; width: auto; }
    </style>
  </head>
  <body>
    <img src="/assets/cm-logo.png" alt="Codemoji" />
  </body>
  </html>
  """

  def home(conn, _params), do: html(conn, @home_html)
end
