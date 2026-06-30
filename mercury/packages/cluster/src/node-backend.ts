/**
 * The `node:cluster` transport. The primary owns the listening socket and the
 * cluster module distributes accepted connections to workers, so a worker binds
 * the port normally (no `SO_REUSEPORT`) and a worker that has not yet called
 * `listen` — because it is still warming — is not in the rotation. This
 * backend runs on Node and on Bun, since Bun implements `node:cluster`.
 */
import cluster from "node:cluster";
import type { Worker } from "node:cluster";
import { isReadyMessage, ENV } from "./types.js";
import type { SupervisorHooks, Transport } from "./core.js";

export function createNodeTransport(hooks: SupervisorHooks<Worker>): Transport<Worker> {
  cluster.on("message", (worker: Worker, message: unknown) => {
    if (isReadyMessage(message)) hooks.onReady(worker, message);
  });
  cluster.on("exit", (worker: Worker, code: number, signal: string) => {
    hooks.onExit(worker, { code: signal ? null : code, signal: signal || null });
  });

  return {
    runtime: "node",
    spawn(spec) {
      return cluster.fork({
        [ENV.role]: "worker",
        [ENV.worker]: String(spec.workerId),
        [ENV.generation]: String(spec.generation),
        [ENV.port]: String(spec.port),
        [ENV.reuse]: spec.reusePort ? "1" : "0",
      });
    },
    drain(worker) {
      // SIGTERM lets the worker's drain handler close the server and exit.
      worker.process.kill("SIGTERM");
    },
    kill(worker) {
      worker.process.kill("SIGKILL");
    },
    pid(worker) {
      return worker.process.pid;
    },
  };
}
