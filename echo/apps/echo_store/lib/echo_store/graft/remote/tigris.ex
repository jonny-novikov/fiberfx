defmodule EchoStore.Graft.Remote.Tigris do
  @moduledoc """
  Graft's remote on Tigris S3, via the native `EchoStore.Tigris` client.

  Object layout (path-style, under the configured bucket):

    * `segments/{SEG}`            — a Segment blob
    * `logs/{VOL}/commits/{LSN}`  — a commit blob, LSN zero-padded to 20 digits

  Commits are written create-only (`If-None-Match: "*"`) with
  `X-Tigris-Consistent: true`, so the per-LSN slot is a compare-and-set against
  the leader.
  """
  @behaviour EchoStore.Graft.Remote
  alias EchoStore.Tigris

  @impl true
  def put_segment(cfg, vol, seg_id, blob) do
    case Tigris.put_object(cfg, seg_key(vol, seg_id), blob) do
      {:ok, s, _, _} when s in 200..299 -> :ok
      {:ok, s, _, b} -> {:error, {:http, s, b}}
      err -> err
    end
  end

  @impl true
  def get_segment(cfg, vol, seg_id) do
    case Tigris.get_object(cfg, seg_key(vol, seg_id), consistent: true) do
      {:ok, 200, _, body} -> {:ok, body}
      {:ok, 404, _, _} -> :absent
      {:ok, s, _, b} -> {:error, {:http, s, b}}
      err -> err
    end
  end

  @impl true
  def put_commit(cfg, vol, lsn, blob) do
    case Tigris.put_object(cfg, commit_key(vol, lsn), blob, create_only: true, consistent: true) do
      {:ok, s, _, _} when s in 200..299 -> :ok
      {:ok, 412, _, _} -> :conflict
      {:ok, s, _, b} -> {:error, {:http, s, b}}
      err -> err
    end
  end

  @impl true
  def list_commits(cfg, vol, from_lsn) do
    case Tigris.list_objects_v2(cfg, commits_prefix(vol)) do
      {:ok, 200, _, xml} ->
        lsns =
          xml
          |> keys_from_xml()
          |> Enum.map(&lsn_from_key/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.filter(&(&1 >= from_lsn))
          |> Enum.sort()

        {:ok, lsns}

      {:ok, s, _, b} ->
        {:error, {:http, s, b}}

      err ->
        err
    end
  end

  # --- key layout ---------------------------------------------------------
  defp seg_key(_vol, seg_id), do: "segments/" <> seg_id
  defp commit_key(vol, lsn), do: commits_prefix(vol) <> pad(lsn)
  defp commits_prefix(vol), do: "logs/" <> vol <> "/commits/"
  defp pad(lsn), do: lsn |> Integer.to_string() |> String.pad_leading(20, "0")

  # Minimal S3 ListBucketResult parsing: pull <Key>…</Key> values. The format is
  # fixed and simple enough that a regex avoids an XML dependency.
  defp keys_from_xml(xml), do: Regex.scan(~r|<Key>([^<]+)</Key>|, xml) |> Enum.map(fn [_, k] -> k end)

  defp lsn_from_key(key) do
    case key |> String.split("/") |> List.last() do
      <<digits::binary-20>> -> String.to_integer(digits)
      _ -> nil
    end
  end
end
