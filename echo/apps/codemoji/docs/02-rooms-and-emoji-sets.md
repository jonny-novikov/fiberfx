# Rooms and Emoji Sets

IMPORTANT!

Rooms acts as a template for a round. Round = game in a room.

At the same moment of time either:
- none game is started in the room - waiting for the first player joins and timer starting (roomDuration)
- only one game - round in a room is being played.

When round is created to be played as a game in a room. Snapshot of current room Emoji Set and other props are assigned:

- Duration (if no player hits 600 max score, room closed and prizePool goes to player with max_score)
- Emoji Set
- Initial prize pool (platform promote to play)
- Guess fee = how many keys deducted from a single guess

IMPORTANT: Player never sees what was guessed. Not his own, not others. Only own attempt history with scores, max score and leaderboard (by max_score).

## Emoji Set Frontend Rendering Approach - CSS Sprites

Sprite sheets render emojis using CSS `background-image` and `background-position`. 
This is more efficient than loading individual images.

### The Math

Given an XXYY coordinate code:

```typescript
// Code: "0305" → Column 3, Row 5
const x = parseInt(code.slice(0, 2), 10);  // 3
const y = parseInt(code.slice(2, 4), 10);  // 5

// For a 144px cell size:
const bgPositionX = -x * cellSize;  // -3 * 144 = -432
const bgPositionY = -y * cellSize;  // -5 * 144 = -720

// CSS: background-position: -432px -720px;
```

### Visual Example

```
Sprite Sheet (1440×2160px, 10×15 grid, 144px cells)
┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
│0000│0100│0200│0300│0400│0500│0600│0700│0800│0900│ Row 0
├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
│0001│0101│0201│0301│0401│0501│0601│0701│0801│0901│ Row 1
├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
│... │    │    │    │    │    │    │    │    │    │
├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
│0005│0105│0205│0305│0405│0505│0605│0705│0805│0905│ Row 5
│    │    │    │ 🎯 │    │    │    │    │    │    │
└────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
                  ↑
            code "0305"
            x=3, y=5
            position: -432px -720px
```