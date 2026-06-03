defmodule Portal.Web.Router do
  @moduledoc """
  The thin, replaceable web layer (F5.1–F5.5; Phoenix replaces it at F6).

  It only parses a request, calls the `Portal` facade, and formats the response —
  **no domain logic**, and it names nothing below the boundary (since F5.8 it calls
  only the `Portal` facade, never the engine, the store, or the core — F5.8-INV2).
  Every expected failure maps to a 4xx (never a 500); success maps to a 2xx.
  Responses share one `%{data: ...}` / `%{error: ...}` envelope via `send_json/3`.
  """
  use Plug.Router

  plug(:match)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason)
  plug(:dispatch)

  post "/enroll" do
    case Portal.enroll(conn.params["user"], conn.params["course"]) do
      {:ok, enrollment} ->
        send_json(conn, 201, %{data: %{id: enrollment.id}})

      {:error, %Portal.Error{code: code, message: message}} ->
        send_json(conn, 422, %{error: %{code: code, message: message}})
    end
  end

  get "/lessons/:id" do
    case Portal.lesson(id) do
      {:ok, lesson} -> send_json(conn, 200, %{data: lesson})
      :error -> send_json(conn, 404, %{error: :not_found})
    end
  end

  get "/courses/:user_id" do
    {:ok, enrollments} = Portal.courses_of(user_id)
    send_json(conn, 200, %{data: enrollments})
  end

  match _ do
    send_json(conn, 404, %{error: :not_found})
  end

  defp send_json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
