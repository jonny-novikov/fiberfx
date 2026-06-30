// Node-Cluster parallel execution + hot code replacement, over the echo/fx wasm
// kernel. This is the runnable face of the roadmap mechanic:
//
//   * the primary forks one worker per core and gives each a distinct fx node id
//     (0..1023), so minted ids never collide across cores without a shared lock;
//   * work is fanned round-robin (fair by rotation, not by hash);
//   * a rolling reload forks a fresh generation, waits for it to come online,
//     shifts new work onto it, then drains the old generation — no dropped work,
//     no window where zero workers are serving.
//
// Run after building the wasm:  pnpm --filter @echo/fx build
//   node echo/fx/examples/cluster-hcr.mjs
//
// Tunables:  CLUSTER_WORKERS (default = cores, clamped 2..8), BATCH (default 12).

import cluster from "node:cluster";
import os from "node:os";
import { createRequire } from "node:module";
import process from "node:process";

const require = createRequire(import.meta.url);
const NS = "JOB";

function loadFx() {
  // wasm-pack --target nodejs emits a CommonJS module; load it via require.
  return require("../../packages/fx/pkg/echo_fx.js");
}

// ── worker ──────────────────────────────────────────────────────────────────
if (cluster.isWorker) {
  const fx = loadFx();
  const node = Number(process.env.WORKER_NODE ?? "0");
  const gen = Number(process.env.GEN ?? "0");
  const minter = new fx.Minter(node);

  process.on("message", (msg) => {
    if (msg?.type !== "job") return;
    // Mint a branded id and run the per-isolate fused pipeline. Both touch the
    // wasm kernel, proving fx is loaded and live in this worker.
    const id = minter.mint(NS, Date.now());
    const n = msg.n >>> 0;
    const values = Uint32Array.from({ length: 8 }, (_v, i) => (n + i) % 64);
    const sum = fx.fused_sum_of_squares(values, 16);
    process.send?.({
      type: "done",
      corr: msg.corr,
      id,
      node,
      gen,
      sum: sum.toString(),
      pid: process.pid,
    });
  });

  process.send?.({ type: "ready", node, gen, pid: process.pid });
}

// ── primary ─────────────────────────────────────────────────────────────────
if (cluster.isPrimary) {
  const CORES = os.availableParallelism?.() ?? os.cpus().length;
  const WORKERS = Math.max(2, Math.min(Number(process.env.CLUSTER_WORKERS ?? CORES), 8));
  const BATCH = Number(process.env.BATCH ?? 12);
  cluster.setupPrimary({ serialization: "json" });

  const log = (...a) => console.log("[primary]", ...a);
  log(`cores=${CORES} workers=${WORKERS} batch=${BATCH}`);

  /** Fork one generation of workers, each with a disjoint node id. */
  function spawnGeneration(gen) {
    const base = gen * WORKERS; // gen0 -> 0..W-1, gen1 -> W..2W-1 (<= 1023)
    const workers = [];
    const ready = [];
    for (let i = 0; i < WORKERS; i++) {
      const node = base + i;
      const w = cluster.fork({ WORKER_NODE: String(node), GEN: String(gen) });
      const onReady = new Promise((res) => {
        w.on("message", (m) => {
          if (m?.type === "ready") res(m);
        });
      });
      workers.push(w);
      ready.push(onReady);
    }
    return { gen, workers, online: Promise.all(ready) };
  }

  /** Round-robin a batch across a generation; resolve with the replies. */
  function runBatch(generation, count, startCorr) {
    const { workers } = generation;
    const replies = [];
    const pending = new Map();
    const done = new Promise((resolve) => {
      let received = 0;
      for (const w of workers) {
        w.on("message", (m) => {
          if (m?.type !== "done" || !pending.has(m.corr)) return;
          pending.delete(m.corr);
          replies.push(m);
          if (++received === count) resolve();
        });
      }
    });
    for (let i = 0; i < count; i++) {
      const corr = startCorr + i;
      pending.set(corr, true);
      // rotate the ring one step per dispatch — constructed fairness
      const w = workers[i % workers.length];
      w.send({ type: "job", corr, n: corr * 7 });
    }
    return done.then(() => replies);
  }

  function drain(generation) {
    return new Promise((resolve) => {
      let exited = 0;
      for (const w of generation.workers) {
        w.on("exit", () => {
          if (++exited === generation.workers.length) resolve();
        });
        w.disconnect(); // graceful: worker exits when its message channel closes
      }
    });
  }

  const report = { generations: [], idsAll: new Set(), collisions: 0 };

  (async () => {
    // generation 0
    const g0 = spawnGeneration(0);
    await g0.online;
    log("generation 0 online");
    const r0 = await runBatch(g0, BATCH, 0);
    const nodes0 = [...new Set(r0.map((r) => r.node))].sort((a, b) => a - b);
    r0.forEach((r) => (report.idsAll.has(r.id) ? report.collisions++ : report.idsAll.add(r.id)));
    log(`batch 0: ${r0.length} jobs across worker nodes [${nodes0.join(",")}]`);
    report.generations.push({ gen: 0, jobs: r0.length, nodes: nodes0 });

    // hot code replacement: bring gen 1 up BEFORE gen 0 goes down
    log("rolling reload → forking generation 1");
    const g1 = spawnGeneration(1);
    await g1.online;
    log("generation 1 online (gen 0 still serving — zero downtime)");
    const r1 = await runBatch(g1, BATCH, 1000);
    const nodes1 = [...new Set(r1.map((r) => r.node))].sort((a, b) => a - b);
    r1.forEach((r) => (report.idsAll.has(r.id) ? report.collisions++ : report.idsAll.add(r.id)));
    log(`batch 1: ${r1.length} jobs across worker nodes [${nodes1.join(",")}]`);
    report.generations.push({ gen: 1, jobs: r1.length, nodes: nodes1 });

    log("draining generation 0");
    await drain(g0);
    log("generation 0 drained");
    await drain(g1);

    const ok = report.collisions === 0 && report.idsAll.size === BATCH * 2;
    log("──────────────────────────────────────────────");
    log(`ids minted        : ${report.idsAll.size}`);
    log(`id collisions     : ${report.collisions}`);
    log(`gen0 worker nodes : [${report.generations[0].nodes.join(",")}]`);
    log(`gen1 worker nodes : [${report.generations[1].nodes.join(",")}]`);
    log(`HCR result        : ${ok ? "PASS" : "FAIL"}`);
    process.exit(ok ? 0 : 1);
  })().catch((err) => {
    console.error(err);
    process.exit(1);
  });
}
