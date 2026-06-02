defmodule Portal.Web.Router do
  @moduledoc """
  The thin, replaceable web layer (F5.1–F5.5; Phoenix replaces it at F6).

  It only parses a request, calls the `Portal.Engine` boundary, and formats the
  response — **no domain logic**, and it names nothing below the boundary. Every
  expected failure maps to a 4xx (never a 500); success maps to a 2xx. Responses
  share one `%{data: ...}` / `%{error: ...}` envelope via `send_json/3`.
  """
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded, :json], pass: ["*/*"], json_decoder: Jason
  plug :dispatch

  post "/enroll" do
    command = %{type: :enroll, user_id: conn.params["user"], course_id: conn.params["course"]}

    case Portal.Engine.dispatch(command) do
      {:ok, enrollment} -> send_json(conn, 201, %{data: %{id: enrollment.id}})
      {:error, reason} -> send_json(conn, 422, %{error: reason})
    end
  end

  get "/lessons/:id" do
    case Portal.Engine.query(:lesson, id) do
      {:ok, lesson} -> send_json(conn, 200, %{data: lesson})
      :error -> send_json(conn, 404, %{error: :not_found})
    end
  end

  get "/courses/:user_id" do
    enrollments = Portal.Engine.query(:courses_of, user_id)
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
