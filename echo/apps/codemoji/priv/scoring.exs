ise = fn s -> IO.puts(s) end

ise.("# Codemoji Linear scoring engine -- derivation (pure, no bus)")
ise.("# points(d) = 100 - 20*d for d in 0..5; a miss is 0")
ise.("")
ise.("distance points status")
Enum.each(Codemoji.Scoring.scale(), fn {d, p, st} ->
  ise.("D#{d}       #{String.pad_trailing(to_string(p), 6)}#{st}")
end)
ise.("miss     0     MISS")
ise.("")

secret = ["DOG", "GUIDE", "SERVICE", "POODLE", "CAT", "BLACKCAT"]
guess = ["DOG", "SERVICE", "GUIDE", "POODLE", "BLACKCAT", "CAT"]
ise.("# worked example (the rules' dogs round; emoji shown as names here)")
ise.("# secret: " <> Enum.join(secret, " "))
ise.("# guess:  " <> Enum.join(guess, " "))
ise.("")
r = Codemoji.Scoring.score(secret, guess)
ise.("pos guess     dist points status")
Enum.each(r.breakdown, fn {i, g, d, p, st} ->
  dd = if d == :miss, do: "miss", else: "D#{d}"
  ise.("#{i}   #{String.pad_trailing(g, 10)}#{String.pad_trailing(dd, 5)}#{String.pad_trailing(to_string(p), 7)}#{st}")
end)
ise.("")
ise.("total #{r.total} of #{r.max}   percentage #{r.percentage}%   tier #{r.tier}")
ise.("")

ise.("# the 30-tier ladder (exact-match anchors)")
ise.("tier points pct anchor")
Enum.each(0..30, fn t ->
  pts = t * 20
  pct = round(pts / 600 * 100)
  anchor = if rem(t, 5) == 0, do: "#{div(t, 5)} exact", else: ""
  ise.("#{String.pad_trailing(to_string(t), 5)}#{String.pad_trailing(to_string(pts), 7)}#{String.pad_trailing(to_string(pct) <> "%", 4)}#{anchor}")
end)
