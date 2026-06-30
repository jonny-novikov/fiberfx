import { createRequire } from "node:module";
import { db, players, rooms, games, guesses, emojiSets } from "./db/dist/index.js";
const require = createRequire(import.meta.url);
const fx = require("./echo/fx/pkg/echo_fx.js");
const Valkey = (await import("./codemojex-node/admin/node_modules/iovalkey/built/index.js")).default;

const m = new fx.Minter(1);
const now = Date.now();
const ems = m.mint("EMS", now);
const plr = m.mint("PLR", now);
const rom = m.mint("ROM", now);
const gam = m.mint("GAM", now);
const ges = m.mint("GES", now);

const codes = Array.from({ length: 150 }, (_, i) => String(i).padStart(4, "0"));

await db.insert(emojiSets).values({
  id: ems, name: "emoji-set-01", rows: 10, cols: 15, cellSize: 72,
  spriteUrl: "/emoji-sets/01-emoji-set.png", codes,
}).onConflictDoNothing();

await db.insert(players).values({
  id: plr, name: "e2e-player", clips: 99,
}).onConflictDoNothing();

await db.insert(rooms).values({
  id: rom, name: "E2E Warmup", emojiSetId: ems, free: true, clipCost: 1,
  durationMs: 3_600_000, status: "open",
}).onConflictDoNothing();

await db.insert(games).values({
  id: gam, roomId: rom, emojiSetId: ems, free: true, guessFee: 1,
  prizePool: 0, endsMs: now + 3_600_000, status: "active",
  totals: { guesses: 1 }, secret: codes.slice(0, 6), keyboard: codes,
}).onConflictDoNothing();

await db.insert(guesses).values({
  id: ges, gameId: gam, playerId: plr,
  codes: ["0000","0100","0200","0300","0400","0500"],
  score: 0, percentage: 0, effort: 0, breakdown: [],
}).onConflictDoNothing();

// live board ZSET, mirroring Codemojex.Board (key board:<gameId>)
const vk = new Valkey({ host: "localhost", port: 6390 });
await vk.zadd(`board:${gam}`, 0, plr);
await vk.quit();

console.log("seeded:");
console.log("  EMS", ems);
console.log("  PLR", plr);
console.log("  ROM", rom);
console.log("  GAM", gam, "(board ZSET written)");
console.log("  GES", ges);
process.exit(0);
