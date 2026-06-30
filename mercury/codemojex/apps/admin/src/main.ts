/** Standalone single-process entry (`node dist/main.js` / `tsx src/main.ts`). */
import { start } from "./server.js";

start().catch((e: unknown) => {
  console.error(e);
  process.exit(1);
});
