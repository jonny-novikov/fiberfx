/**
 * Runtime detection and the pure worker-count policy. Kept apart from the
 * supervisor so the clamp can be unit tested without spawning anything.
 */
import os from "node:os";
import type { Runtime, Backend } from "./types.js";

/** Bun exposes a global `Bun`; everything else is treated as Node. */
export function detectRuntime(): Runtime {
  return typeof (globalThis as { Bun?: unknown }).Bun !== "undefined" ? "bun" : "node";
}

/** Resolve `auto` to a concrete backend for the current runtime. */
export function resolveBackend(backend: Backend | undefined, runtime: Runtime): "node" | "bun" {
  const want = backend ?? "auto";
  if (want === "auto") return runtime === "bun" ? "bun" : "node";
  return want;
}

/** Physical cores available to this process. */
export function coreCount(runtime: Runtime): number {
  if (runtime === "bun") {
    const hc = (globalThis.navigator as { hardwareConcurrency?: number } | undefined)
      ?.hardwareConcurrency;
    return typeof hc === "number" && hc > 0 ? hc : 1;
  }
  const par = (os as { availableParallelism?: () => number }).availableParallelism;
  const n = typeof par === "function" ? par() : os.cpus().length;
  return n > 0 ? n : 1;
}

/**
 * Clamp a requested worker count into `[min, max]`, defaulting to the core
 * count. Pure: pass `cores` explicitly in tests.
 */
export function clampWorkers(
  requested: number | undefined,
  cores: number,
  min = 1,
  max = 1024,
): number {
  const base = requested && requested > 0 ? requested : cores;
  return Math.max(min, Math.min(base, max));
}
