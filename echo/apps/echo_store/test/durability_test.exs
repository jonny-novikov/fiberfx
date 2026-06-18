defmodule EchoStore.DurabilityTest do
  @moduledoc """
  The pluggable-durability surface and the four Graft-hardening values, exercised offline
  (no Valkey, no Snowflake): the facade's adapter selection plus the pure rollup/frontier/
  fencing/divergence logic the EchoMQ 4+ commit-log-as-outbox stands on.
  """
  use ExUnit.Case, async: true

  alias EchoStore.Graft.{Divergence, Epoch, Segment}
  alias EchoData.Graft.SyncPoint

  describe "the durability plug — facade selection" do
    test "defaults to the SQLite adapter (no extra dependency)" do
      assert EchoStore.Durability.adapter() == EchoStore.Durability.SQLite
      assert Keyword.fetch!(EchoStore.Durability.config(), :adapter) == EchoStore.Durability.SQLite
    end
  end

  describe "Graft.SyncPoint — the pushed/pulled frontier" do
    test "advances monotonically and reports the backlog" do
      sp = SyncPoint.new("VOL-test")
      assert sp.local_watermark == 0 and sp.remote == 0

      sp = sp |> SyncPoint.advance_local(5) |> SyncPoint.advance_local(3)
      assert sp.local_watermark == 5
      assert SyncPoint.unsynced(sp, 8) == 3
      refute SyncPoint.synced?(sp, 8)
      assert SyncPoint.synced?(SyncPoint.advance_local(sp, 8), 8)
    end
  end

  describe "Graft.Segment — rollup to one version per page" do
    test "folds newest-LSN-wins and frames the pages" do
      seg = Segment.build("SEG-1", "VOL-1", [{1, 0, "a"}, {2, 0, "b"}, {1, 1, "c"}])
      assert seg.pages == %{0 => "b", 1 => "c"}
      assert seg.lsn_lo == 1 and seg.lsn_hi == 2
      assert Segment.page_count(seg) == 2
      assert Segment.remote_key(seg) == "segments/SEG-1"
      assert [frame] = Segment.frames(seg)
      assert map_size(frame) == 2
    end
  end

  describe "Graft.Epoch — writer fencing" do
    test "claim bumps; fence accepts current, rejects stale" do
      assert Epoch.claim(0) == 1
      assert Epoch.claim(7) == 8
      assert Epoch.fence(3, 3) == :ok
      assert Epoch.fence(2, 3) == {:error, {:fenced, 3}}
    end
  end

  describe "Graft.Divergence — reject, don't merge" do
    test "classifies in-sync, fast-forward, and divergence" do
      sp = SyncPoint.new("VOL-1") |> SyncPoint.advance_local(5) |> SyncPoint.advance_remote(5)
      assert Divergence.check(sp, 5, 5) == :ok
      assert Divergence.check(sp, 5, 9) == {:fast_forward, :remote, 9}
      assert Divergence.check(sp, 9, 9) == {:error, {:diverged, 9, 9}}
    end
  end
end
