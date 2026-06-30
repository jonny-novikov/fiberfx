/**
 * Node-Cluster orchestration for echo/fx — the typed library behind the
 * `examples/cluster-hcr.mjs` demo.
 *
 * The scheduler is deliberately in TypeScript, not Rust: a wasm instance is one
 * V8 isolate with private linear memory, so cross-core work cannot share a Rust
 * deque. The cores are OS processes (`node:cluster`); each loads the same wasm
 * kernel and carries a distinct fx node id, which is what keeps minted ids
 * disjoint without a shared lock. Fairness is a property of the round-robin
 * rotation, not of a hash.
 *
 * Hot code replacement is a rolling reload: a fresh generation of workers is
 * brought online before the previous one is drained, so there is never a window
 * with zero workers serving.
 *
 * This module typechecks and documents the surface; the runnable proof is the
 * `.mjs` example (no build step required there).
 */
import cluster, { type Worker } from "node:cluster";
import os from "node:os";
import process from "node:process";

export interface Job<P> {
  readonly corr: number;
  readonly payload: P;
}

export interface Reply<R> {
  readonly corr: number;
  readonly result: R;
  readonly node: number;
  readonly gen: number;
  readonly pid: number;
}

export interface PoolOptions {
  /** Worker count. Defaults to available parallelism, clamped to 2..1024. */
  readonly workers?: number;
}

interface Generation {
  readonly gen: number;
  readonly workers: Worker[];
  readonly online: Promise<void>;
}

/** Clamp a requested worker count into the fx node-id budget. */
function workerCount(requested: number | undefined): number {
  const cores = os.availableParallelism?.() ?? os.cpus().length;
  const n = requested ?? cores;
  return Math.max(2, Math.min(n, 1024));
}

/**
 * A primary-side pool. Construct it in `cluster.isPrimary`; the worker side is
 * `runWorker`. Each generation occupies a fresh band of node ids so a reload
 * never reuses a live id.
 */
export class ClusterPool<P, R> {
  private readonly size: number;
  private current: Generation;
  private corr = 0;

  private constructor(size: number) {
    this.size = size;
    cluster.setupPrimary({ serialization: "json" });
    this.current = this.spawn(0);
  }

  static async start<P, R>(opts: PoolOptions = {}): Promise<ClusterPool<P, R>> {
    const pool = new ClusterPool<P, R>(workerCount(opts.workers));
    await pool.current.online;
    return pool;
  }

  private spawn(gen: number): Generation {
    const base = gen * this.size;
    const workers: Worker[] = [];
    const ready: Array<Promise<void>> = [];
    for (let i = 0; i < this.size; i++) {
      const node = (base + i) % 1024;
      const w = cluster.fork({ WORKER_NODE: String(node), GEN: String(gen) });
      ready.push(
        new Promise<void>((res) => {
          w.on("message", (m: { type?: string }) => {
            if (m?.type === "ready") res();
          });
        }),
      );
      workers.push(w);
    }
    return { gen, workers, online: Promise.all(ready).then(() => undefined) };
  }

  /** Dispatch one payload to the next worker in rotation. */
  submit(payload: P): Promise<Reply<R>> {
    const corr = this.corr++;
    const w = this.current.workers[corr % this.current.workers.length]!;
    return new Promise<Reply<R>>((resolve) => {
      const onMessage = (m: Reply<R> & { type?: string; corr: number }): void => {
        if (m?.type === "done" && m.corr === corr) {
          w.off("message", onMessage);
          resolve(m);
        }
      };
      w.on("message", onMessage);
      w.send({ type: "job", corr, payload } satisfies {
        type: "job";
        corr: number;
        payload: P;
      });
    });
  }

  /** Rolling reload: new generation online first, then drain the old. */
  async reload(): Promise<void> {
    const previous = this.current;
    const next = this.spawn(previous.gen + 1);
    await next.online;
    this.current = next;
    await this.drain(previous);
  }

  private drain(generation: Generation): Promise<void> {
    return new Promise<void>((resolve) => {
      let exited = 0;
      for (const w of generation.workers) {
        w.on("exit", () => {
          if (++exited === generation.workers.length) resolve();
        });
        w.disconnect();
      }
    });
  }

  async shutdown(): Promise<void> {
    await this.drain(this.current);
  }
}

/**
 * Worker entry point. Register a handler that maps a payload to a result; the
 * transport, correlation, and ready signal are handled here.
 */
export function runWorker<P, R>(handler: (payload: P, node: number) => R): void {
  const node = Number(process.env["WORKER_NODE"] ?? "0");
  const gen = Number(process.env["GEN"] ?? "0");
  process.on("message", (msg: { type?: string; corr: number; payload: P }) => {
    if (msg?.type !== "job") return;
    const result = handler(msg.payload, node);
    process.send?.({ type: "done", corr: msg.corr, result, node, gen, pid: process.pid });
  });
  process.send?.({ type: "ready", node, gen, pid: process.pid });
}
