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

IO.puts("CODEMOJEX SEED OK")
