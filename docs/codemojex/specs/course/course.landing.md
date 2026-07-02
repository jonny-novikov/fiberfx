# Codemojex — the course · Landing manuscript

The manuscript for `/codemojex` (`html/codemojex/index.html`). The landing is the course's front door:
the game in one paragraph, one interactive figure that teaches the scoring law in thirty seconds, the
nine-chapter map, the doors, and the references. Identity: the CMX calibration — the contract-sheet
basis with a Telegram-blue house lead (`--c-lead`), gold reserved for the Golden Room's money elements,
teal for diamonds/settlement. Stamp: a unique 14-char `CMX…` id + the standard Base62 decoder
(epoch `1704067200000`).

## Hero

- **Kicker:** `Codemojex · a course` — **h1:** the game as branded systems (lead-hued span on the
  house phrase).
- **Lede** (from design §The game in one paragraph, tightened): a room is a template; a game is one
  play in it. A secret of six emoji codes, guesses that cost a currency, a per-position score of
  `100 − 20·d` summing to 600, a leaderboard ranked by the best linear total — and three currencies
  moving through Postgres atomically. Classic pays the top scorer live; the blind golden mode reveals
  a committed secret and pays the top K in one sealed pass.
- **Status line, stated plainly:** the landing is built; the nine chapters ship as gated stubs; the
  dives follow per chapter.

## The hero figure (interactive, /bcs anatomy-style)

**The six-cell guess row, scored `100 − 20·d`.** Provenance: design §The scoring authority (the
linear law, the 600 total) + §The provably-fair secret (the commitment chip). No emoji assets — cells
carry `XXYY` codes (column-then-row, the `EMS` convention). Elements:

- the **secret row** (sealed, shown as `▓▓` cells with the commitment chip beside it — gold, labeled
  `SHA-256(secret ‖ nonce)`),
- the **guess row** — six cells with codes,
- the **distance row** — per-position `d` labels,
- the **points row** — `100 80 60 40 20 0` per `d`, and the running **sum toward 600** (readout).
- Segbar (hover/click, `aria-pressed`): **the secret · the guess · the distance · the score** — each
  segment dims the rest and swaps the readout line, exactly the /bcs anatomy interaction.

## §1 · The course map

Nine `.pcard`s (C0–C8) from [`course.toc.md`](course.toc.md): `.bid` chapter number, the canon title,
the one-line gist, the three dive names, `3 dives · planned` chip. Every card links its live stub
route.

## §2 · How to read

The grounding ethic in three sentences: the course teaches the shipped engine as-built (cm.1–cm.7);
every claim traces to `echo/apps/codemojex`, the binding design, or the generated stories; the one
forward surface is cm.8+ (cash-out, the rake, membership), marked wherever named. State the stub
status plainly.

## §3 · The doors

- **/bcs** — the architecture law this game is built to; its B7 chapter is this game inside the BCS
  course, and it doors back here.
- **/echomq** — the bus: the fair lanes, the consumers, the leases under the guesses.
- **/redis-patterns** — the Valkey patterns applied across the same stack.
- **/mesh** — the CAP weave the whole stack composes.

## §4 · References (design §References, curated for the landing)

Mastermind (the board game) · the feedback-function pair (arXiv 1607.04597 / 1207.0773) · commitment
schemes · all-pay auction + Networks ch. 9 · King, Announcing Snowflake (2010) · Helland, Life Beyond
Distributed Transactions (CIDR 2007) · Kreps, The Log · Ecto.Multi · Phoenix Channels · the OTP
supervisor behaviour · Valkey benchmarking/latency/persistence · Fly Machines + private networking ·
Telegram Mini Apps (validating WebApp data). Related: `/bcs/codemojex`, `/echomq`.

## Pager + footer

- Pager: next → `/codemojex/overview` (C0).
- Footer: 3-col — brand + tag · **Chapters** (start + C0–C8, all live links) · **The courses**
  (/codemojex /bcs /echomq /redis-patterns /mesh) — then the foot-bar: © jonnify + the CMX stamp with
  the standard decoder IIFE.
