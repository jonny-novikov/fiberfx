/**
 * The one call an application makes. The same entry module is executed by the
 * supervisor and by every worker; `runCluster` reads the role the supervisor set
 * and either fans out workers or runs the bundle. Define the bundle once at the
 * top of an entry file and call this.
 */
import type { Worker } from "node:cluster";
import { detectRuntime, resolveBackend, coreCount, clampWorkers } from "./runtime.js";
import { Supervisor } from "./core.js";
import type { TransportFactory } from "./core.js";
import { createNodeTransport } from "./node-backend.js";
import { createBunTransport } from "./bun-backend.js";
import type { BunSubprocess } from "./bun-backend.js";
import { runWorker, workerContextFromEnv } from "./worker.js";
import { ENV } from "./types.js";
import type { Bundle, ClusterOptions } from "./types.js";

export async function runCluster<W>(bundle: Bundle<W>, opts: ClusterOptions): Promise<void> {
  const runtime = detectRuntime();

  // Worker role: run the bundle and return; never fan out.
  if (process.env[ENV.role] === "worker") {
    const ctx = workerContextFromEnv(runtime, opts.port);
    await runWorker(bundle, ctx);
    return;
  }

  // Supervisor role: pick a backend and fan out.
  const backend = resolveBackend(opts.backend, runtime);
  const count = clampWorkers(
    opts.workers,
    coreCount(runtime),
    opts.minWorkers ?? 1,
    opts.maxWorkers ?? 1024,
  );

  if (backend === "bun") {
    const entry = process.argv[1];
    if (entry === undefined) throw new Error("cannot determine entry path for the bun backend");
    const factory: TransportFactory<BunSubprocess> = (hooks) => createBunTransport(hooks, entry);
    await new Supervisor<BunSubprocess>(opts, count, true, factory).run();
    return;
  }

  const factory: TransportFactory<Worker> = (hooks) => createNodeTransport(hooks);
  await new Supervisor<Worker>(opts, count, false, factory).run();
}
