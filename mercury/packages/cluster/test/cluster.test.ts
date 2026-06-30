import { test } from "node:test";
import assert from "node:assert/strict";
import { Supervisor, clampWorkers } from "../src/index.js";

const tick = (ms = 5) => new Promise((r) => setTimeout(r, ms));

// A transport with no real processes: it records calls and lets the test drive
// readiness and exit through the supervisor's hooks.
function fakeTransport() {
  const spawned = [];
  const drained = new Set();
  const killed = new Set();
  let hooks;
  const t = {
    runtime: "node",
    autoExitOnDrain: true,
    spawn(spec) {
      const handle = { id: spawned.length, spec };
      spawned.push(handle);
      return handle;
    },
    drain(h) {
      drained.add(h);
      if (t.autoExitOnDrain) queueMicrotask(() => hooks.onExit(h, { code: 0, signal: null }));
    },
    kill(h) {
      killed.add(h);
      hooks.onExit(h, { code: null, signal: "SIGKILL" });
    },
    pid(h) {
      return 10_000 + h.id;
    },
    // test drivers
    ready(h) {
      hooks.onReady(h, { t: "echo-cluster", ev: "ready", workerId: h.spec.workerId, generation: h.spec.generation, pid: t.pid(h) });
    },
    crash(h) {
      hooks.onExit(h, { code: 1, signal: null });
    },
  };
  const factory = (h) => {
    hooks = h;
    return t;
  };
  return { t, spawned, drained, killed, factory };
}

const silent = () => {};
const opts = (over = {}) => ({ port: 3000, workers: 2, onLog: silent, ...over });

test("clampWorkers defaults to cores and respects bounds", () => {
  assert.equal(clampWorkers(undefined, 4), 4);
  assert.equal(clampWorkers(8, 4), 8);
  assert.equal(clampWorkers(0, 4), 4);
  assert.equal(clampWorkers(100, 4, 1, 16), 16);
  assert.equal(clampWorkers(1, 4, 2, 16), 2);
});

test("start fans out the requested worker count", () => {
  const f = fakeTransport();
  const sup = new Supervisor(opts({ workers: 3 }), 3, false, f.factory);
  sup.start();
  assert.equal(f.spawned.length, 3);
  assert.deepEqual(sup.snapshot().map((w) => w.workerId).sort(), [0, 1, 2]);
});

test("an unexpected exit respawns the same logical slot", async () => {
  const f = fakeTransport();
  const sup = new Supervisor(opts({ workers: 1, respawnDelayMs: 0 }), 1, false, f.factory);
  sup.start();
  assert.equal(f.spawned.length, 1);
  f.t.crash(f.spawned[0]); // worker 0 dies unexpectedly
  await tick();
  assert.equal(f.spawned.length, 2, "a replacement was spawned");
  const live = sup.snapshot();
  assert.equal(live.length, 1);
  assert.equal(live[0].workerId, 0, "same logical id reused");
});

test("rolling reload warms the new generation before draining the old", async () => {
  const f = fakeTransport();
  const sup = new Supervisor(opts({ workers: 2 }), 2, false, f.factory);
  sup.start();
  for (const h of [...f.spawned]) f.t.ready(h); // gen 0 healthy

  const reload = sup.reload();
  // gen 1 spawned (2 more), but the old gen must still be present until gen 1 is ready
  assert.equal(f.spawned.length, 4, "new generation spawned");
  assert.equal(f.drained.size, 0, "old generation not drained before new is ready");

  for (const h of f.spawned.filter((s) => s.spec.generation === 1)) f.t.ready(h);
  await reload;
  await tick();

  const live = sup.snapshot();
  assert.equal(live.length, 2, "only the new generation remains");
  assert.ok(live.every((w) => w.generation === 1), "all survivors are gen 1");
  assert.equal(f.drained.size, 2, "exactly the old generation was drained");
});

test("shutdown drains every worker and resolves", async () => {
  const f = fakeTransport();
  const sup = new Supervisor(opts({ workers: 2 }), 2, false, f.factory);
  sup.start();
  for (const h of [...f.spawned]) f.t.ready(h);
  await sup.shutdown();
  assert.equal(sup.snapshot().length, 0, "no workers remain after shutdown");
  assert.equal(f.drained.size, 2, "both workers were drained");
});
