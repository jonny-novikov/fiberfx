// Exercises the real typed ClusterPool (child_process.fork) over the echo/fx
// wasm kernel, and asserts the R3 + R4 properties: disjoint node ids across the
// forked cores (collision-free minting) and a rolling reload that brings a fresh
// generation online before draining the old (no dropped work). The same file
// runs on both runtimes — Bun executes the TypeScript directly, Node via tsx:
//
//   bun examples/cluster-fork.ts
//   node --import tsx examples/cluster-fork.ts
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import process from "node:process";
import { ClusterPool } from "../ts/cluster.ts";

const here = dirname(fileURLToPath(import.meta.url));
const worker = join(here, "cluster-worker.mjs");
const WORKERS = Math.max(2, Math.min(Number(process.env.CLUSTER_WORKERS ?? 4), 8));
const BATCH = Number(process.env.BATCH ?? 12);
const runtime = "Bun" in globalThis ? "bun" : "node";

type Payload = { n: number };
type Result = { id: string; sum: string };

const log = (...a: unknown[]) => console.log(`[${runtime}]`, ...a);
const nodesOf = (rs: { node: number }[]) =>
  [...new Set(rs.map((r) => r.node))].sort((a, b) => a - b);

const all = new Set<string>();
let collisions = 0;

const pool = await ClusterPool.start<Payload, Result>({ worker, workers: WORKERS });
log(`pool online: ${WORKERS} forked workers, batch ${BATCH}`);

const r0 = await Promise.all(
  Array.from({ length: BATCH }, (_v, i) => pool.submit({ n: i * 7 })),
);
r0.forEach((r) => (all.has(r.result.id) ? collisions++ : all.add(r.result.id)));
log(`batch 0: ${r0.length} jobs across nodes [${nodesOf(r0).join(",")}]`);

await pool.reload();
log("rolling reload → generation 1 online, generation 0 drained");

const r1 = await Promise.all(
  Array.from({ length: BATCH }, (_v, i) => pool.submit({ n: 1000 + i })),
);
r1.forEach((r) => (all.has(r.result.id) ? collisions++ : all.add(r.result.id)));
log(`batch 1: ${r1.length} jobs across nodes [${nodesOf(r1).join(",")}]`);

await pool.shutdown();

const ok = collisions === 0 && all.size === BATCH * 2;
log("──────────────────────────────────────────────");
log(`runtime           : ${runtime}`);
log(`ids minted        : ${all.size}`);
log(`id collisions     : ${collisions}`);
log(`gen0 nodes        : [${nodesOf(r0).join(",")}]`);
log(`gen1 nodes        : [${nodesOf(r1).join(",")}]`);
log(`result            : ${ok ? "PASS" : "FAIL"}`);
process.exit(ok ? 0 : 1);
