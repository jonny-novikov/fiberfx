/**
 * The worker side. A re-executed entry lands here when its role is `worker`. It
 * warms the bundle, then serves, then tells the supervisor it is ready — in that
 * order, so the port is bound only once the worker is hot. On a termination
 * signal it drains in-flight work through the serve handle before exiting.
 */
import { ENV } from "./types.js";
import type { Bundle, IpcMessage, Runtime, WorkerContext } from "./types.js";

/** Reconstruct this worker's context from the environment the supervisor set. */
export function workerContextFromEnv(runtime: Runtime, fallbackPort: number): WorkerContext {
  const num = (key: string, dflt: number): number => {
    const raw = process.env[key];
    const n = raw === undefined ? NaN : Number(raw);
    return Number.isFinite(n) ? n : dflt;
  };
  return {
    workerId: num(ENV.worker, 0),
    generation: num(ENV.generation, 0),
    port: num(ENV.port, fallbackPort),
    runtime,
    reusePort: process.env[ENV.reuse] === "1",
  };
}

function sendReady(ctx: WorkerContext): void {
  if (typeof process.send !== "function") return;
  const msg: IpcMessage = {
    t: "echo-cluster",
    ev: "ready",
    workerId: ctx.workerId,
    generation: ctx.generation,
    pid: process.pid,
  };
  process.send(msg);
}

export async function runWorker<W>(bundle: Bundle<W>, ctx: WorkerContext): Promise<void> {
  const warm = await bundle.warmup(ctx);
  const handle = await bundle.serve(warm, ctx);
  sendReady(ctx);

  let draining = false;
  const drain = async (): Promise<void> => {
    if (draining) return;
    draining = true;
    try {
      await handle.stop();
    } catch (err) {
      process.stderr.write(`echo-cluster worker drain error: ${String(err)}\n`);
    } finally {
      process.exit(0);
    }
  };
  process.on("SIGTERM", () => void drain());
  process.on("SIGINT", () => void drain());
}
