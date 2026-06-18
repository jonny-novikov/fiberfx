defmodule CodemojexWeb.FallbackController do
  @moduledoc "Turns the facade's `{:error, reason}` tuples into JSON responses with the right status."
  use CodemojexWeb, :controller

  def call(conn, {:error, reason}) do
    {status, message} = render_error(reason)

    conn
    |> put_status(status)
    |> json(%{error: message})
  end

  def call(conn, nil) do
    conn
    |> put_status(:not_found)
    |> json(%{error: "not found"})
  end

  defp render_error(:no_player), do: {:unauthorized, "player required"}
  defp render_error(:no_round), do: {:not_found, "round not found"}
  defp render_error(:no_room), do: {:not_found, "room not found"}
  defp render_error(:insufficient), do: {:payment_required, "insufficient balance"}
  defp render_error(:no_keys), do: {:payment_required, "not enough keys"}
  defp render_error(:closed), do: {:conflict, "round is closed"}
  defp render_error(:expired), do: {:conflict, "round has expired"}
  defp render_error(:bad_guess), do: {:unprocessable_entity, "invalid guess"}
  defp render_error(:bad_amount), do: {:unprocessable_entity, "invalid amount"}
  defp render_error(other), do: {:bad_request, to_string(other)}
end
