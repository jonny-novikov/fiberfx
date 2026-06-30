/**
 * @echo/cluster — an efficient multicore runtime for echo HTTP surfaces.
 *
 * Define a Bundle once and call runCluster in an entry module:
 *
 *   import { runCluster } from "@echo/cluster";
 *   runCluster(
 *     {
 *       warmup: async (ctx) => buildAndReady(ctx),   // get hot first
 *       serve:  async (app, ctx) => listen(app, ctx) // then bind the port
 *     },
 *     { port: 3000 }                                  // workers default to cores
 *   );
 */
export { runCluster } from "./run.js";
export { detectRuntime, resolveBackend, coreCount, clampWorkers } from "./runtime.js";
export { Supervisor, defaultLog } from "./core.js";
export type { Transport, TransportFactory, SupervisorHooks, SpawnSpec, ExitInfo } from "./core.js";
export type {
  Bundle,
  ServeHandle,
  WorkerContext,
  ClusterOptions,
  ClusterLog,
  Runtime,
  Backend,
  IpcMessage,
} from "./types.js";
export { isReadyMessage, ENV } from "./types.js";
