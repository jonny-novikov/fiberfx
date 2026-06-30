defmodule CodemojexWeb.GameBundleController do
  @moduledoc """
  Serves the React game island bytes same-origin (Arm B). `Codemojex.GameBundle` pulls
  the current content-hashed bundle from the edge and holds it in memory; this controller
  hands those bytes to the browser, which dynamic-imports them via the `EdgeReact` hook.

  The route is public (no session, no auth) and the filename is content-hashed, so the
  bytes are immutable — only the *pointer* moves, and that is resolved server-side. A
  hash this machine does not currently hold 404s (the pointer never names a missing file,
  and a stale name should not be served).
  """
  use CodemojexWeb, :controller

  def show(conn, %{"file" => file}) do
    case Codemojex.GameBundle.fetch(file) do
      {:ok, bytes, content_type} ->
        conn
        |> put_resp_content_type(content_type)
        |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
        |> send_resp(200, bytes)

      :error ->
        send_resp(conn, 404, "")
    end
  end
end
