defmodule Portal.Web.Router do
  @moduledoc """
  The thin, replaceable web layer (F5.1–F5.5; Phoenix replaces it at F6).

  It only parses a request, calls the `Portal.Engine` boundary, and formats a
  response — **no domain logic**, and it names nothing below the boundary. Every
  response goes through `send_json/3`, so F5.3's real bodies and F5.8's
  `%Portal.Error{}` set become added clauses rather than rewrites.
  """
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason
  plug :dispatch

  get "/courses/:user_id" do
    respond(conn, Portal.Engine.query(:courses_of, user_id))
  end

  post "/enroll" do
    command = %{type: :enroll, user_id: conn.params["user"], course_id: conn.params["course"]}

    case Portal.Engine.dispatch(command) do
      {:ok, _} = ok -> send_json(conn, 201, ok)
      {:error, _} = err -> send_json(conn, 422, err)
    end
  end

  match _ do
    send_json(conn, 404, {:error, :not_found})
  end

  # Railway result → HTTP status. {:ok, _} → 2xx; an expected error → 4xx (never 500).
  defp respond(conn, {:ok, _} = ok), do: send_json(conn, 200, ok)
  defp respond(conn, {:error, _} = err), do: send_json(conn, 422, err)

  defp send_json(conn, status, result) do
    body =
      case result do
        {:ok, data} -> %{data: data}
        {:error, reason} -> %{error: reason}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
