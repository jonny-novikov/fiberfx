Stars aren't real money on their own — they're Telegram's in-app currency (XTR), and their USD value is derived from TON. The standard planning rate is about $0.013 per earned Star ($13 per 1,000), which is the desktop/web developer payout. The catch on the revenue side: you lose roughly 32% of every mobile Stars payment — Apple's and Google's 30% platform fee reduces the effective developer payout to around $0.009 per Star. On desktop/web purchases those store fees don't apply, so you keep ~97%.

Here's the full ladder, discount columns carried forward with the 100-key Display bumped to **27%**, plus the USD math:

| Package | Stars ⭐ | Real discount | Display | USD face (@ $0.013) | Net — mobile (~32% fee) | Net — desktop (~3% fee) |
|---|---|---|---|---|---|---|
| 5 keys | 99 | 0.0000% | 0% | $1.29 | $0.88 | $1.25 |
| 15 keys | 249 | 16.1616% | 16% | $3.24 | $2.20 | $3.14 |
| 50 keys | 799 | 19.2929% | 20% | $10.39 | $7.06 | $10.08 |
| 100 keys | 1,449 | 26.8182% | **27%** | $18.84 | $12.81 | $18.27 |
| 200 keys | 2,599 | 34.3687% | 35% | $33.79 | $22.98 | $32.78 |
| 500 keys | 5,499 | 44.4545% | 45% | $71.49 | $48.61 | $69.34 |
| 1000 keys | 9,999 | 49.5000% | 50% | $129.99 | $88.39 | $126.09 |

The **USD face** column is the nominal $13/1,000 rate. 
It's a planning figure, not a fixed price — the USD value fluctuates daily with TON's market price, since Telegram fixes Stars at 200 per TON and TON floats on the market. If TON runs hot, every cell scales up proportionally; if it dips, down.

The **two net columns** bracket your real take-home, and the spread between them is large. 
Mobile is the realistic baseline — roughly 80% of Star purchases come from mobile, so on a blended audience you should budget closer to the mobile column. 
That means a 1000-key whale paying ~$130 of face value nets you ~$88 after the store cut, vs ~$126 if they'd bought their Stars on desktop. The ~$38 gap per top-bundle sale is pure Apple/Google tax, and you can nudge but not force buyers to desktop.

Stars-to-TON conversion is a taxable event in most jurisdictions, and TON-to-fiat is another — and there's a 1,000-Star minimum and a 21-day hold before withdrawal, so revenue recognized ≠ cash in hand for about three weeks.

If you want, I can turn this into a small pure-Elixir pricing module — a `Codemoji.KeyShop` with the bundle table, a `net_revenue/2` taking `:mobile | :desktop` and a configurable TON rate, so the USD figures recompute from a live `stars_usd_rate` rather than the baked-in $0.013.