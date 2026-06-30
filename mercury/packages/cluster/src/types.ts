/**
 * The contract between the runtime and the application it runs.
 *
 * A `Bundle` is the unit the cluster fans out across cores. The runtime calls
 * `warmup` first and only calls `serve` once it resolves, so a worker binds its
 * port while it is already hot — the kernel never routes a request at a cold
 * worker. `serve` returns a handle whose `stop` drains in-flight work, which is
 * what makes both crash-respawn and rolling reload graceful.
 */

/** Which JavaScript runtime the supervisor is running under. */
export type Runtime = "bun" | "node";

/**
 * How workers share the listening port.
 *  - `node`: the `node:cluster` primary owns the socket and distributes accepted
 *    connections to workers. Runs on Node and on Bun (Bun implements
 *    `node:cluster`). Workers do not set `SO_REUSEPORT`.
 *  - `bun`: each worker binds the same port with `SO_REUSEPORT` via `Bun.spawn`,
 *    and the Linux kernel load-balances connections. Bun runtime only.
 *  - `auto`: `bun` under Bun, `node` otherwise.
 */
export type Backend = "auto" | "node" | "bun";

/** Everything a worker needs to know about its place in the cluster. */
export interface WorkerContext {
  /** Stable logical id within a generation (0-based), reused across respawns. */
  readonly workerId: number;
  /** Generation number; a rolling reload increments it. */
  readonly generation: number;
  /** The port every worker shares. */
  readonly port: number;
  /** The runtime the worker is executing under. */
  readonly runtime: Runtime;
  /**
   * When true the worker must bind with `SO_REUSEPORT` (the `bun` backend);
   * when false the `node:cluster` primary distributes and the worker binds
   * normally.
   */
  readonly reusePort: boolean;
}

/** A running server. `stop` must finish in-flight work before resolving. */
export interface ServeHandle {
  stop(): Promise<void> | void;
}

/**
 * The application the cluster runs. Defined once in an entry module; the same
 * module is executed by the supervisor and by every worker, and the runtime
 * decides which role each process plays.
 */
export interface Bundle<Warm = unknown> {
  /**
   * Bring the worker hot before it serves: open database and cache pools, build
   * the HTTP app, optionally exercise the hot path so the JIT has compiled it.
   * The resolved value is handed to `serve`.
   */
  warmup(ctx: WorkerContext): Promise<Warm> | Warm;
  /**
   * Bind the port and start accepting requests using the warm state. Must honor
   * `ctx.reusePort`. Returns a handle whose `stop` drains gracefully.
   */
  serve(warm: Warm, ctx: WorkerContext): Promise<ServeHandle> | ServeHandle;
}

/** A single structured log line; wire `onLog` to your logger of choice. */
export interface ClusterLog {
  readonly level: "info" | "warn" | "error";
  readonly msg: string;
  readonly [field: string]: unknown;
}

/** Tuning for the supervisor. Only `port` is required. */
export interface ClusterOptions {
  /** The port every worker shares. */
  readonly port: number;
  /** Desired worker count. Defaults to the core count. */
  readonly workers?: number;
  /** Lower clamp on worker count. Default 1. */
  readonly minWorkers?: number;
  /** Upper clamp on worker count. Default 1024. */
  readonly maxWorkers?: number;
  /** Spawn strategy. Default `auto`. */
  readonly backend?: Backend;
  /** Milliseconds to wait for a worker to report ready before it counts as failed. Default 30000. */
  readonly warmupBudgetMs?: number;
  /** Milliseconds to let a draining worker finish before a force kill. Default 10000. */
  readonly drainTimeoutMs?: number;
  /** Initial respawn backoff after a crash. Default 250. */
  readonly respawnDelayMs?: number;
  /** Ceiling on respawn backoff. Default 5000. */
  readonly maxRespawnDelayMs?: number;
  /** Structured log sink. Defaults to a JSON line on stderr. */
  readonly onLog?: (line: ClusterLog) => void;
}

/** Messages a worker sends back to its supervisor over IPC. */
export type IpcMessage = {
  readonly t: "echo-cluster";
  readonly ev: "ready";
  readonly workerId: number;
  readonly generation: number;
  readonly pid: number;
};

/** Narrows an unknown IPC payload to the cluster's ready message. */
export function isReadyMessage(value: unknown): value is IpcMessage {
  if (typeof value !== "object" || value === null) return false;
  const m = value as Record<string, unknown>;
  return m["t"] === "echo-cluster" && m["ev"] === "ready" && typeof m["pid"] === "number";
}

/** Environment keys the supervisor sets so a re-executed entry knows its role. */
export const ENV = {
  role: "ECHO_CLUSTER_ROLE",
  worker: "ECHO_CLUSTER_WORKER",
  generation: "ECHO_CLUSTER_GEN",
  port: "ECHO_CLUSTER_PORT",
  reuse: "ECHO_CLUSTER_REUSE",
} as const;
