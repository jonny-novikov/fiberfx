# Seed the two emoji sets from the real sprite sheets (F-CV1 / design §3.3.1).
#
#   mix run priv/repo/seeds.exs
#
# The grid is the measured-true grid of each PNG under docs/codemojex/emoji-sets/:
# at cell_size 72, `01-emoji-set.png` (720x1080) is 10x15 = 150 cells, and
# `02-emoji-set.png` (720x1512) is 10x21 = 210 cells. `codes` is the FULL keyboard
# (every cell, row-major) — the per-game `cell_count` snapshot does the narrowing,
# not a smaller EMS row. `sprite_url` is the asset path the app serves.

alias Codemojex.{EmojiSet, Store}

sets = [
  EmojiSet.new("emoji-set-01", 10, 15,
    cell_size: 72,
    sprite_url: "/emoji-sets/01-emoji-set.png"
  ),
  EmojiSet.new("emoji-set-02", 10, 21,
    cell_size: 72,
    sprite_url: "/emoji-sets/02-emoji-set.png"
  )
]

for %EmojiSet{} = set <- sets do
  :ok = Store.put_set(set)
  IO.puts("seeded EMS #{set.id}  #{set.name}  #{set.cols}x#{set.rows}@#{set.cell_size}  #{length(set.codes)} cells")
end

# The launch config (cm.5 R13): the two launch rooms over the first emoji set.
#
#   1. "Бокс для разминки" — the free warm-up: free guesses (1 clip each), no
#      buy-in, an ordinary live classic room (INV-LAUNCH).
#   2. one Golden Room — a type:"classic", golden:true tournament that forms in
#      :gathering, runs the live top-K split + consolation, and pays a pool seeded
#      by the platform's virtual deposit (the D-7 economy):
#        entry_fee_keys 8 (=80💎), virtual_deposit 833💎 (~$10), start_threshold 10,
#        first_movers 2, entry_fee_revenue_percentage 50, a room_deadline ~48h out.
warmup_set = List.first(sets)

{:ok, warmup} =
  Codemojex.create_room("Бокс для разминки", warmup_set,
    free: true,
    clip_cost: 1,
    duration_ms: 35 * 3_600 * 1000
  )

{:ok, golden} =
  Codemojex.create_golden_room("Golden Room", warmup_set,
    entry_fee_keys: 8,
    virtual_deposit: 833,
    start_threshold: 10,
    first_movers: 2,
    entry_fee_revenue_percentage: 50,
    room_deadline: DateTime.add(DateTime.utc_now(), 48 * 3600, :second) |> DateTime.truncate(:second)
  )

IO.puts("seeded ROOM #{warmup}  Бокс для разминки  (free warm-up)")
IO.puts("seeded ROOM #{golden}  Golden Room  (golden tournament, 8 keys, gather 10)")

IO.puts("CODEMOJEX SEED OK")
