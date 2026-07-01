// Forked compute worker for the echo/fx pool proof. Plain JS so it runs under a
// Node or a Bun fork with no TypeScript loader. It speaks the ClusterPool IPC
// protocol: {type:"job", corr, payload} in, {type:"done", corr, result, ...} out,
// and one {type:"ready"} at start. Each fork loads the wasm kernel and carries a
// distinct fx node id, so minted ids stay disjoint without a shared lock.
import { createRequire } from "node:module";
import process from "node:process";

const require = createRequire(import.meta.url);
const fx = require("../pkg/echo_fx.js");
const NS = "JOB";

const node = Number(process.env.WORKER_NODE ?? "0");
const gen = Number(process.env.GEN ?? "0");
const minter = new fx.Minter(node);

process.on("message", (msg) => {
  if (msg?.type !== "job") return;
  const n = (msg.payload?.n ?? 0) >>> 0;
  const id = minter.mint(NS, Date.now());
  const values = Uint32Array.from({ length: 8 }, (_v, i) => (n + i) % 64);
  const sum = fx.fused_sum_of_squares(values, 16);
  process.send?.({
    type: "done",
    corr: msg.corr,
    result: { id, sum: sum.toString() },
    node,
    gen,
    pid: process.pid,
  });
});

process.send?.({ type: "ready", node, gen, pid: process.pid });
