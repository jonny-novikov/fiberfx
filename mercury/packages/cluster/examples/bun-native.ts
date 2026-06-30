/**
 * A native Bun.serve worker fanned out with SO_REUSEPORT.
 *
 *   bun examples/bun-native.ts
 *
 * The supervisor spawns one Bun process per core; each binds :3000 with
 * `reusePort` and the Linux kernel load-balances connections across them, with
 * no primary proxy on the hot path. Crash respawn, readiness gating, and rolling
 * reload (SIGHUP) are added by the supervisor on top of Bun's bare spawn loop.
 *
 * The warmup here is trivial since there are no pools to open, but it shows the
 * shape: warm first, then bind. Try it:
 *   for i in $(seq 1 8); do curl -s localhost:3000; done   # worker ids vary
 *   kill -HUP <supervisor pid>                              # rolling reload
 */
import { runCluster } from "../src/index.js";

declare const Bun: {
  serve(options: {
    port: number;
    reusePort?: boolean;
    fetch: (request: Request) => Response;
  }): { stop(closeActiveConnections?: boolean): Promise<void> };
};

await runCluster<{ pid: number }>(
  {
    warmup: () => ({ pid: process.pid }),
    serve: ({ pid }, ctx) => {
      const server = Bun.serve({
        port: ctx.port,
        reusePort: ctx.reusePort, // true under the bun backend
        fetch: () =>
          new Response(`served by worker ${ctx.workerId}, gen ${ctx.generation}, pid ${pid}\n`),
      });
      return { stop: () => server.stop(false) };
    },
  },
  { port: 3000, backend: "bun" },
);
