/**
 * The supervisor algorithm, written once over an abstract `Transport`. The two
 * runtimes (`node:cluster`, `Bun.spawn`) supply only the primitives —
 * spawn / drain / kill / pid — and report exit and readiness back through the
 * hooks. Everything that defines the runtime's behavior lives here:
 *
 *  - a worker is counted as available only after it reports ready, which it does
 *    after `serve` resolves, which it calls after `warmup` resolves;
 *  - a worker that exits unexpectedly is respawned into the same logical slot
 *    with exponential backoff;
 *  - a rolling reload brings a whole new generation to ready before it drains the
 *    previous one, so there is never a window with reduced capacity;
 *  - shutdown drains every worker and force-kills any that overrun the budget.
 */
import type {
  ClusterLog,
  ClusterOptions,
  IpcMessage,
  Runtime,
} from "./types.js";

/** Instructions to launch one worker. */
export interface SpawnSpec {
  readonly workerId: number;
  readonly generation: number;
  readonly port: number;
  readonly reusePort: boolean;
}

/** How a worker process ended. */
export interface ExitInfo {
  readonly code: number | null;
  readonly signal: string | null;
}

/** The primitives a runtime backend must provide. */
export interface Transport<H> {
  readonly runtime: Runtime;
  spawn(spec: SpawnSpec): H;
  /** Ask the worker to drain in-flight work and exit (graceful). */
  drain(handle: H): void;
  /** Force-terminate the worker now. */
  kill(handle: H): void;
  pid(handle: H): number | undefined;
}

/** Callbacks a backend invokes as workers report in. */
export interface SupervisorHooks<H> {
  onExit(handle: H, info: ExitInfo): void;
  onReady(handle: H, msg: IpcMessage): void;
}

/** Builds a transport once the core can give it the hooks to call. */
export type TransportFactory<H> = (hooks: SupervisorHooks<H>) => Transport<H>;

interface Rec<H> {
  readonly handle: H;
  readonly workerId: number;
  readonly generation: number;
  ready: boolean;
  draining: boolean;
  readonly respawns: number;
}

interface ReadyWaiter {
  readonly generation: number;
  resolve(): void;
  reject(err: Error): void;
  readonly timer: ReturnType<typeof setTimeout>;
}

const DEFAULTS = {
  minWorkers: 1,
  maxWorkers: 1024,
  warmupBudgetMs: 30_000,
  drainTimeoutMs: 10_000,
  respawnDelayMs: 250,
  maxRespawnDelayMs: 5_000,
} as const;

export class Supervisor<H> {
  private readonly recs = new Map<H, Rec<H>>();
  private readonly killTimers = new Map<H, ReturnType<typeof setTimeout>>();
  private readyWaiters: ReadyWaiter[] = [];
  private transport!: Transport<H>;

  private currentGen = 0;
  private shuttingDown = false;
  private reloading = false;
  private resolveRun: (() => void) | undefined;

  private readonly port: number;
  private readonly count: number;
  private readonly reusePort: boolean;
  private readonly warmupBudgetMs: number;
  private readonly drainTimeoutMs: number;
  private readonly respawnDelayMs: number;
  private readonly maxRespawnDelayMs: number;
  private readonly log: (line: ClusterLog) => void;

  constructor(
    opts: ClusterOptions,
    count: number,
    reusePort: boolean,
    private readonly factory: TransportFactory<H>,
  ) {
    this.port = opts.port;
    this.count = count;
    this.reusePort = reusePort;
    this.warmupBudgetMs = opts.warmupBudgetMs ?? DEFAULTS.warmupBudgetMs;
    this.drainTimeoutMs = opts.drainTimeoutMs ?? DEFAULTS.drainTimeoutMs;
    this.respawnDelayMs = opts.respawnDelayMs ?? DEFAULTS.respawnDelayMs;
    this.maxRespawnDelayMs = opts.maxRespawnDelayMs ?? DEFAULTS.maxRespawnDelayMs;
    this.log = opts.onLog ?? defaultLog;
  }

  /** Hooks handed to the transport. */
  get hooks(): SupervisorHooks<H> {
    return {
      onExit: (handle, info) => this.handleExit(handle, info),
      onReady: (handle, msg) => this.handleReady(handle, msg),
    };
  }

  /** Launch the initial generation. Builds the transport on first use. */
  start(): void {
    if (!this.transport) this.transport = this.factory(this.hooks);
    for (let i = 0; i < this.count; i++) this.spawnWorker(i, this.currentGen, 0);
  }

  /** Wire signals, start, and resolve when a later shutdown completes. */
  run(): Promise<void> {
    process.on("SIGTERM", () => void this.shutdown());
    process.on("SIGINT", () => void this.shutdown());
    process.on("SIGHUP", () => void this.reload());
    this.start();
    return new Promise<void>((resolve) => {
      this.resolveRun = resolve;
    });
  }

  /**
   * Roll a fresh generation: spawn `count` new workers, wait for all of them to
   * report ready, then drain the previous generation(s). If the new generation
   * does not warm within the budget, drain it and keep the old one.
   */
  async reload(): Promise<void> {
    if (this.shuttingDown || this.reloading) return;
    this.reloading = true;
    const gen = ++this.currentGen;
    this.log({ level: "info", msg: "rolling reload: warming new generation", generation: gen, workers: this.count });
    for (let i = 0; i < this.count; i++) this.spawnWorker(i, gen, 0);
    try {
      await this.waitGenerationReady(gen);
    } catch {
      this.log({ level: "error", msg: "new generation did not warm in budget; aborting reload", generation: gen });
      this.drainWhere((r) => r.generation === gen);
      this.currentGen = gen - 1;
      this.reloading = false;
      return;
    }
    this.log({ level: "info", msg: "new generation ready; draining previous", generation: gen });
    this.drainWhere((r) => r.generation < gen);
    this.reloading = false;
  }

  /** Drain every worker, then resolve `run`. Force-kills overruns. */
  shutdown(): Promise<void> {
    if (this.shuttingDown) return this.donePromise();
    this.shuttingDown = true;
    this.log({ level: "info", msg: "shutting down; draining all workers", workers: this.recs.size });
    this.drainWhere(() => true);
    if (this.recs.size === 0) this.finish();
    return this.donePromise();
  }

  /** Inspection for tests and diagnostics. */
  snapshot(): Array<{ workerId: number; generation: number; ready: boolean; draining: boolean; pid: number | undefined }> {
    return [...this.recs.values()].map((r) => ({
      workerId: r.workerId,
      generation: r.generation,
      ready: r.ready,
      draining: r.draining,
      pid: this.transport ? this.transport.pid(r.handle) : undefined,
    }));
  }

  // ----- internals -----

  private spawnWorker(workerId: number, generation: number, respawns: number): void {
    const handle = this.transport.spawn({ workerId, generation, port: this.port, reusePort: this.reusePort });
    this.recs.set(handle, { handle, workerId, generation, ready: false, draining: false, respawns });
    this.log({ level: "info", msg: "spawn worker", workerId, generation, pid: this.transport.pid(handle) });
  }

  private handleReady(handle: H, msg: IpcMessage): void {
    const rec = this.recs.get(handle);
    if (!rec) return;
    this.recs.set(handle, { ...rec, ready: true, respawns: 0 });
    this.log({ level: "info", msg: "worker ready", workerId: msg.workerId, generation: msg.generation, pid: msg.pid });
    this.evaluateWaiters();
  }

  private handleExit(handle: H, info: ExitInfo): void {
    const rec = this.recs.get(handle);
    this.recs.delete(handle);
    this.clearKillTimer(handle);
    if (!rec) return;

    if (this.shuttingDown) {
      if (this.recs.size === 0) this.finish();
      return;
    }
    if (rec.draining) {
      this.evaluateWaiters();
      return;
    }
    // Unexpected crash: respawn the same logical slot with backoff, but only
    // while its generation is still current.
    const respawns = rec.respawns + 1;
    const delay = Math.min(this.respawnDelayMs * 2 ** (respawns - 1), this.maxRespawnDelayMs);
    this.log({ level: "warn", msg: "worker exited; respawning", workerId: rec.workerId, generation: rec.generation, code: info.code, signal: info.signal, delayMs: delay });
    setTimeout(() => {
      if (!this.shuttingDown && this.currentGen === rec.generation) {
        this.spawnWorker(rec.workerId, rec.generation, respawns);
      }
    }, delay);
  }

  private drainWhere(pred: (r: Rec<H>) => boolean): void {
    for (const rec of [...this.recs.values()]) {
      if (!pred(rec) || rec.draining) continue;
      this.recs.set(rec.handle, { ...rec, draining: true });
      this.transport.drain(rec.handle);
      const t = setTimeout(() => {
        if (this.recs.has(rec.handle)) {
          this.log({ level: "warn", msg: "drain timeout; killing worker", workerId: rec.workerId, pid: this.transport.pid(rec.handle) });
          this.transport.kill(rec.handle);
        }
      }, this.drainTimeoutMs);
      this.killTimers.set(rec.handle, t);
    }
  }

  private waitGenerationReady(generation: number): Promise<void> {
    if (this.generationReady(generation)) return Promise.resolve();
    return new Promise<void>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.readyWaiters = this.readyWaiters.filter((w) => w.timer !== timer);
        reject(new Error(`generation ${generation} not ready within ${this.warmupBudgetMs}ms`));
      }, this.warmupBudgetMs);
      this.readyWaiters.push({ generation, resolve, reject, timer });
    });
  }

  private evaluateWaiters(): void {
    if (this.readyWaiters.length === 0) return;
    const still: ReadyWaiter[] = [];
    for (const w of this.readyWaiters) {
      if (this.generationReady(w.generation)) {
        clearTimeout(w.timer);
        w.resolve();
      } else {
        still.push(w);
      }
    }
    this.readyWaiters = still;
  }

  private generationReady(generation: number): boolean {
    let seen = 0;
    for (const rec of this.recs.values()) {
      if (rec.generation !== generation) continue;
      seen++;
      if (!rec.ready) return false;
    }
    return seen > 0;
  }

  private clearKillTimer(handle: H): void {
    const t = this.killTimers.get(handle);
    if (t) {
      clearTimeout(t);
      this.killTimers.delete(handle);
    }
  }

  private finish(): void {
    for (const t of this.killTimers.values()) clearTimeout(t);
    this.killTimers.clear();
    this.log({ level: "info", msg: "all workers exited; supervisor done" });
    this.resolveRun?.();
  }

  private donePromise(): Promise<void> {
    if (this.recs.size === 0 && this.shuttingDown) return Promise.resolve();
    return new Promise<void>((resolve) => {
      const prev = this.resolveRun;
      this.resolveRun = () => {
        prev?.();
        resolve();
      };
    });
  }
}

export function defaultLog(line: ClusterLog): void {
  const stream = line.level === "error" ? process.stderr : process.stdout;
  stream.write(JSON.stringify({ src: "echo-cluster", ...line }) + "\n");
}
