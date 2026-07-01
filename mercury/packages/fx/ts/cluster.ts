/**
 * A forked-process compute pool for echo/fx, and the typed library behind the
 * `examples/cluster-*.mjs` proof.
 *
 * The scheduler is deliberately in TypeScript, not Rust: a wasm instance is one
 * isolate with private linear memory, so cross-core work cannot share a Rust
 * deque. The cores are separate OS processes, forked with `node:child_process`
 * — process isolation is the property that matters here (one worker crashing or
 * pausing does not take its siblings down), and it is what `node:cluster` was
 * chosen for at the R3 rung. The pool uses `fork` rather than `cluster` because
 * this is a compute pool, not a server: it shares no listening socket, only an
 * IPC job/reply channel, and `fork` is the primitive for that. `child_process`
 * is implemented by both Node and Bun, so the same pool runs on either runtime
 * with no branch. Each worker loads the same wasm kernel and carries a distinct
 * fx node id, which keeps minted ids disjoint without a shared lock; fairness is
 * a property of the round-robin rotation, not of a hash.
 *
 * Hot code replacement is a rolling reload: a fresh generation of workers is
 * brought online before the previous one is drained, so there is never a window
 * with zero workers serving.
 */
import { fork, type ChildProcess } from "node:child_process";
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
  /** Path to the worker module the pool forks (it calls {@link runWorker}). */
  readonly worker: string;
  /** Worker count. Defaults to available parallelism, clamped to 2..1024. */
  readonly workers?: number;
}

interface Generation {
  readonly gen: number;
  readonly workers: ChildProcess[];
  readonly online: Promise<void>;
}

/** Clamp a requested worker count into the fx node-id budget. */
function workerCount(requested: number | undefined): number {
  const cores = os.availableParallelism?.() ?? os.cpus().length;
  const n = requested ?? cores;
  return Math.max(2, Math.min(n, 1024));
}

/**
 * A primary-side pool. Construct it in the primary process; each forked worker
 * runs the worker module and calls {@link runWorker}. Each generation occupies a
 * fresh band of node ids so a reload never reuses a live id.
 */
export class ClusterPool<P, R> {
  private readonly size: number;
  private readonly worker: string;
  private current: Generation;
  private corr = 0;

  private constructor(size: number, worker: string) {
    this.size = size;
    this.worker = worker;
    this.current = this.spawn(0);
  }

  static async start<P, R>(opts: PoolOptions): Promise<ClusterPool<P, R>> {
    const pool = new ClusterPool<P, R>(workerCount(opts.workers), opts.worker);
    await pool.current.online;
    return pool;
  }

  private spawn(gen: number): Generation {
    const base = gen * this.size;
    const workers: ChildProcess[] = [];
    const ready: Array<Promise<void>> = [];
    for (let i = 0; i < this.size; i++) {
      const node = (base + i) % 1024;
      const w = fork(this.worker, [], {
        env: { ...process.env, WORKER_NODE: String(node), GEN: String(gen) },
        serialization: "json",
      });
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
 * transport, correlation, and ready signal are handled here. Runs the same way
 * under a Node or a Bun fork.
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
