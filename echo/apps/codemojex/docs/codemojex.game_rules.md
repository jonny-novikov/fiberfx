# Codemojex: The Art of Mastermind

## Prelude

*The Game, The Code, The Competition*

---

## What is Codemojex?

Codemojex is a competitive puzzle game where players race to decode a secret sequence of 6 emojis. 
Think Wordle meets Mastermind — but with emojis, real money prizes, and a ticking clock.

> *"Guess the code of 6 emojis"* 

Each round, a secret code is generated — six emojis in a specific order, drawn from a themed category (animals, food, sports, etc.). Players have limited attempts to crack the code before time runs out. Every guess reveals how close you are, creating a feedback loop of deduction, intuition, and strategic risk-taking.

---

## The Core Game Loop

1. **A Round Begins** — Timer starts (e.g., 35 hours), prize pool opens
2. **Select 6 Emojis** — Choose from the category keyboard
3. **Submit Your Guess** — Costs 🔑 Keys (limited resource, can be topped up)
4. **Receive Feedback** — Your score 0-600
5. **Iterate or Wait** — Use feedback to improve, or save keys
6. **Round Ends** — Prize pool distributed by leaderboard position

---

## Game Mechanics

### 🔑 Keys — The Currency of Attempts

Every guess costs Keys. Keys are earned through gameplay, purchased with Stars, or won as rewards. The cost creates meaningful decisions: is this guess worth the investment?

| Resource | Purpose | Acquisition |
|:--------:|---------|-------------|
| 🔑 Keys | Submit guesses | Purchase with ⭐ Stars |
| ⭐ Stars | Buy keys, entry fees | In-app purchase, rewards |
| 💰 Prize Pool | Round rewards | Entry fees (30% platform fee) |

### ⏱️ Round Timer — The Pressure Cooker

Each round has a countdown (typically 24-48 hours). 
The timer creates urgency: submit early to claim first-mover bonuses, or wait to analyze others' progress? 
Time is a strategic dimension.

### 🏆 Prize Pool — Real Stakes

Players contribute to the prize pool through entry fees. 
After a 30% game fee, the remaining 70% is distributed to top performers. 
Higher scores = larger share. This transforms casual play into genuine competition.

### 📌 Position Locking — Strategic Anchoring

Found an emoji in the right position? 
Lock it! Locked positions persist across guesses, letting you build on confirmed knowledge. 
This mechanic rewards incremental progress and reduces frustration.

---

## The Secret Code

At the heart of every round is a 6-emoji secret code. Understanding its structure is essential to understanding scoring.

### Code Structure

```
Position:  [ 0 ]  [ 1 ]  [ 2 ]  [ 3 ]  [ 4 ]  [ 5 ]
Secret:    [ 🐕 ] [ 🦮 ] [ 🐕‍🦺 ] [ 🐩 ] [ 🐈 ] [ 🐈‍⬛ ]
```

The code has exactly 6 positions (indexed 0-5). 
Each position contains exactly one emoji from the round's category. 
Emojis are **unique** — no duplicates in the secret code.

**IMPORTANT!** Emojis ARE NOT the Unicode Characters - they are respresented as any custom set of "codes":

- Represented by png sprite;
- Has position on the sprite grid;
- "The Secret Code" of N is the set of the positions in particular EmojiSet.

### What Your Guess Reveals

When you submit a guess, the system compares each position:

| Result | Distance | Meaning |
|:------:|:--------:|---------|
| **Exact Match** | D0 | Right emoji, right position |
| **Adjacent** | D1 | Right emoji, 1 position off |
| **Near** | D2-D3 | Right emoji, 2-3 positions off |
| **Far** | D4-D5 | Right emoji, 4-5 positions off |
| **Miss** | — | Emoji not in secret code |

### Distance Calculation

Distance is the absolute difference between guess position and secret position:

```
distance = | guess_position − secret_position |
```

**Example:** If 🐈 is at position 4 in the secret, and you guess 🐈 at position 2:

```
distance = |2 - 4| = 2  →  "Near" (D2)
```

---

## The Linear Scoring Engine

Codemojex uses a Linear scoring system that rewards both precision and progress. 
Every correct emoji earns points, even if misplaced.

### Point Values by Distance

| Distance | Points | % of Max | Status | Meaning |
|:--------:|:------:|:--------:|:------:|---------|
| **D0** | **100** | 100% | EXACT | Perfect placement |
| **D1** | **80** | 80% | ADJACENT | So close! |
| **D2** | **60** | 60% | NEAR | Right track |
| **D3** | **40** | 40% | NEAR | Found it |
| **D4** | **20** | 20% | FAR | In the code |
| **D5** | **0** | 0% | MAX | Wrong end |
| **Miss** | **0** | 0% | NOT FOUND | Not in code |

*Linear Point Scale: 100-80-60-40-20-0*

### The 20-Point Gap Design

Notice the uniform 20-point gaps between each distance level. 
This isn't accidental — these gaps create exactly **30 natural scoring tiers** and reserve space for future mechanics.

```
D0: 100 ─┐
         │ 20-point gaps throughout
D1:  80 ─┤
         │ 
D2:  60 ─┤
         │ 
D3:  40 ─┤
         │
D4:  20 ─┤
         │
D5:   0 ─┘
```

### Total Score Calculation

Your total score is the sum of points across all 6 positions:

```
total_points = Σ points(distance[i])  for i = 0..5

percentage = (total_points ÷ 600) × 100
```

### Worked Example

```
Secret:  [ 🐕 ] [ 🦮 ] [ 🐕‍🦺 ] [ 🐩 ] [ 🐈 ] [ 🐈‍⬛ ]
Guess:   [ 🐕 ] [ 🐕‍🦺 ] [ 🦮 ] [ 🐩 ] [ 🐈‍⬛ ] [ 🐈 ]
```

| Pos | Secret | Guess | Analysis | Distance | Points | Status |
|:---:|:------:|:-----:|----------|:--------:|:------:|:------:|
| 0 | 🐕 | 🐕 | Match! | D0 | **100** | EXACT |
| 1 | 🦮 | 🐕‍🦺 | 🐕‍🦺 is at pos 2 | D1 | **80** | ADJACENT |
| 2 | 🐕‍🦺 | 🦮 | 🦮 is at pos 1 | D1 | **80** | ADJACENT |
| 3 | 🐩 | 🐩 | Match! | D0 | **100** | EXACT |
| 4 | 🐈 | 🐈‍⬛ | 🐈‍⬛ is at pos 5 | D1 | **80** | ADJACENT |
| 5 | 🐈‍⬛ | 🐈 | 🐈 is at pos 4 | D1 | **80** | ADJACENT |

**Result:**

```
Total = 100 + 80 + 80 + 100 + 80 + 80 = 520 points
Percentage = 520 ÷ 600 = 87%
```

---

## The 30-Tier System

The Linear scoring system creates exactly 30 natural tiers, forming a ladder from 0 to 600 points. 
Each tier represents 20 points and a meaningful milestone.

### Complete Tier Table

| Tier | Points | % | Anchor |
|:----:|:------:|:---:|:------:|
| **0** | **0** | **0%** | Zero ⭐ |
| 1 | 20 | 3% | |
| 2 | 40 | 7% | |
| 3 | 60 | 10% | |
| 4 | 80 | 13% | |
| **5** | **100** | **17%** | 1 Exact ⭐ |
| 6 | 120 | 20% | |
| 7 | 140 | 23% | |
| 8 | 160 | 27% | |
| 9 | 180 | 30% | |
| **10** | **200** | **33%** | 2 Exact ⭐ |
| 11 | 220 | 37% | |
| 12 | 240 | 40% | |
| 13 | 260 | 43% | |
| 14 | 280 | 47% | |
| **15** | **300** | **50%** | 3 Exact ⭐ |
| 16 | 320 | 53% | |
| 17 | 340 | 57% | |
| 18 | 360 | 60% | |
| 19 | 380 | 63% | |
| **20** | **400** | **67%** | 4 Exact ⭐ |
| 21 | 420 | 70% | |
| 22 | 440 | 73% | |
| 23 | 460 | 77% | |
| 24 | 480 | 80% | |
| **25** | **500** | **83%** | 5 Exact ⭐ |
| 26 | 520 | 87% | |
| 27 | 540 | 90% | |
| 28 | 560 | 93% | |
| 29 | 580 | 97% | |
| **30** | **600** | **100%** | Perfect ⭐ |

*Complete 30-Tier Structure (⭐ = Exact Match Anchor)*

---

## Future Game Extension: Tiers

The 30-tier structure enables our most innovative competitive mechanic.

### Strategic Implications

- **Speed vs Accuracy:** Submit early to claim tier badges, or wait to perfect your guess?
- **Comeback Potential:** Behind on tiers 1-10? Race to be first on tiers 20-30!
- **Spectator Drama:** Live leaderboard shows "+1 First to Tier 25!" moments

---

## Key Concepts Summary

| Concept | Definition |
|:-------:|------------|
| **Secret Code** | 6 unique emojis in positions 0-5, hidden from players |
| **Distance** | Absolute difference: `\|guess_position - secret_position\|` |
| **Linear Scoring** | 100-80-60-40-20-0 point scale with uniform 20-point gaps |
| **Maximum Score** | 600 points (6 × 100) = 100% = Perfect |
| **Tier** | 20-point milestone (30 total: 0, 20, 40... 580, 600) |
| **Key** | Resource consumed per guess attempt |
| **Prize Pool** | Accumulated entry fees minus 30% platform fee |
| **Position Lock** | Confirmed emoji position that persists across guesses |

---

> *"In Codemojex, every point tells a story. Every tier is a milestone. Every second matters."*

You now understand the foundations: what Codemojex is, how the secret code works, and how the Linear scoring engine translates your guesses into points and percentages.

In the chapters ahead, we'll dive deeper — exploring the psychology behind point values, the economics of tier bonuses, the technical implementation, and the edge cases that make competitive play fascinating.

**Welcome to The Art of Mastermind.**
