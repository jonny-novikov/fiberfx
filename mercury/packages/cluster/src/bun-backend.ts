/**
 * The `Bun.spawn` transport. Each worker is an independent Bun process that
 * binds the shared port with `SO_REUSEPORT`, and the Linux kernel load-balances
 * connections across them — no primary proxy on the hot path. Bun's bare spawn
 * loop has no per-worker restart and no readiness signal; this transport adds an
 * IPC `ready` channel and exit reporting so the supervisor can respawn crashes
 * and roll generations. Constructed only under the Bun runtime.
 */
import { isReadyMessage, ENV } from "./types.js";
import type { SupervisorHooks, Transport } from "./core.js";

export interface BunSubprocess {
  readonly pid: number;
  kill(signal?: number | string): void;
}

interface BunSpawnOptions {
  readonly cmd: readonly string[];
  readonly env?: Record<string, string | undefined>;
  readonly stdout?: "inherit" | "pipe" | "ignore";
  readonly stderr?: "inherit" | "pipe" | "ignore";
  readonly stdin?: "inherit" | "pipe" | "ignore";
  readonly ipc?: (message: unknown, subprocess: BunSubprocess) => void;
  readonly onExit?: (
    subprocess: BunSubprocess,
    exitCode: number | null,
    signalCode: number | null,
    error?: unknown,
  ) => void;
}

interface BunGlobal {
  spawn(options: BunSpawnOptions): BunSubprocess;
}

function bun(): BunGlobal {
  const g = (globalThis as { Bun?: BunGlobal }).Bun;
  if (!g) throw new Error("the bun backend requires the Bun runtime");
  return g;
}

export function createBunTransport(
  hooks: SupervisorHooks<BunSubprocess>,
  entry: string,
): Transport<BunSubprocess> {
  return {
    runtime: "bun",
    spawn(spec) {
      return bun().spawn({
        cmd: [process.execPath, entry],
        env: {
          ...process.env,
          [ENV.role]: "worker",
          [ENV.worker]: String(spec.workerId),
          [ENV.generation]: String(spec.generation),
          [ENV.port]: String(spec.port),
          [ENV.reuse]: spec.reusePort ? "1" : "0",
        },
        stdout: "inherit",
        stderr: "inherit",
        stdin: "inherit",
        ipc(message, subprocess) {
          if (isReadyMessage(message)) hooks.onReady(subprocess, message);
        },
        onExit(subprocess, exitCode, signalCode) {
          hooks.onExit(subprocess, {
            code: exitCode,
            signal: signalCode == null ? null : String(signalCode),
          });
        },
      });
    },
    drain(proc) {
      proc.kill("SIGTERM");
    },
    kill(proc) {
      proc.kill("SIGKILL");
    },
    pid(proc) {
      return proc.pid;
    },
  };
}
