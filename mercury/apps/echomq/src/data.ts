/*
 * EchoMQ dashboard data + chart math — a pure, deterministic layer.
 * Ported from static/echomq.html: the queues, stats, donut arcs, throughput
 * series, jobs, groups, batches and processors. No Date/random — the series
 * use a sin-hash so every render is identical.
 */

export type QueueState = "waiting" | "active" | "delayed" | "prioritized" | "completed" | "failed";

/** Chart/legend colors per job state (app-level viz, not DS tokens-only). */
export const COL: Record<QueueState, string> = {
  waiting: "rgb(var(--slate-9))",
  active: "rgb(var(--indigo-9))",
  delayed: "rgb(var(--orange-9))",
  prioritized: "rgb(167 139 250)",
  completed: "rgb(var(--green-9))",
  failed: "rgb(var(--red-9))",
};

export const LABELS: Record<QueueState, string> = {
  waiting: "Waiting",
  active: "Active",
  delayed: "Delayed",
  prioritized: "Prioritized",
  completed: "Completed",
  failed: "Failed",
};

/** Job/queue state → Mercury Chip/Tag tone. */
export type ChipTone = "neutral" | "brand" | "positive" | "negative" | "caution" | "info" | "discovery";
export const TONE: Record<QueueState, ChipTone> = {
  completed: "positive",
  active: "info",
  failed: "negative",
  delayed: "caution",
  waiting: "neutral",
  prioritized: "discovery",
};

/* ───────── Sidebar queues ───────── */
export interface QueueSeg {
  flex: number;
  color: string;
}
export interface Queue {
  name: string;
  total: number;
  segs: QueueSeg[];
}

const QDATA: { name: string; segs: [QueueState, number][] }[] = [
  { name: "analytics", segs: [["completed", 1]] },
  { name: "build-service", segs: [["completed", 3]] },
  { name: "bulk-flows", segs: [["waiting", 69], ["prioritized", 31]] },
  { name: "bulk-flows-workers", segs: [["delayed", 8], ["completed", 412], ["failed", 24]] },
  { name: "campaign-runner", segs: [] },
  { name: "cdn-upload", segs: [["active", 1]] },
  { name: "collapsed-children", segs: [["prioritized", 6], ["completed", 43], ["failed", 17]] },
  { name: "data-extract", segs: [["completed", 3]] },
  { name: "data-transform", segs: [["completed", 1], ["failed", 1]] },
  { name: "demo-flows", segs: [["prioritized", 5], ["completed", 18], ["failed", 6]] },
  { name: "deploy-pipeline", segs: [["prioritized", 2], ["completed", 2]] },
  { name: "order-processing", segs: [["waiting", 43], ["active", 7], ["completed", 120], ["failed", 18]] },
];

export const QUEUES: Queue[] = QDATA.map((x) => {
  const total = x.segs.reduce((a, [, v]) => a + v, 0);
  const segs: QueueSeg[] =
    total > 0
      ? x.segs.map(([k, v]) => ({ flex: v, color: COL[k] }))
      : [{ flex: 1, color: "rgb(var(--bg-tertiary))" }];
  return { name: x.name, total, segs };
});

/* ───────── Metric strip ───────── */
export const META = [
  { label: "Version", value: "8.4.0" },
  { label: "Mode", value: "standalone" },
  { label: "Used Memory", value: "57.34 MB" },
  { label: "Total Memory", value: "7.65 GB" },
  { label: "Clients", value: "16 / 10000" },
];

/* ───────── Overview stats ───────── */
export const STATS: { label: string; value: string; color: string }[] = (
  [
    ["waiting", "Waiting", "43"],
    ["active", "Active", "7"],
    ["delayed", "Delayed", "35"],
    ["prioritized", "Prioritized", "81"],
    ["completed", "Completed", "51.1K"],
    ["failed", "Failed", "6 628"],
  ] as [QueueState, string, string][]
).map(([k, label, value]) => ({ label, value, color: COL[k] }));

/* ───────── Donuts ───────── */
export interface DonutArc {
  color: string;
  label: string;
  value: number;
  dash: string;
  offset: string;
  pct: string;
}

function donut(segs: [QueueState, number][]): { total: number; arcs: DonutArc[] } {
  const total = segs.reduce((a, [, v]) => a + v, 0);
  const r = 62;
  const C = 2 * Math.PI * r;
  let acc = 0;
  const arcs = segs.map(([k, v]) => {
    const len = (v / total) * C;
    const frac = v / total;
    const arc: DonutArc = {
      color: COL[k],
      label: LABELS[k],
      value: v,
      dash: `${len.toFixed(1)} ${(C - len).toFixed(1)}`,
      offset: (-acc).toFixed(1),
      pct: `${(frac * 100).toFixed(1)}%`,
    };
    acc += len;
    return arc;
  });
  return { total, arcs };
}

const dQ = donut([["waiting", 43], ["active", 7], ["delayed", 35], ["prioritized", 81]]);
const dP = donut([["completed", 51064], ["failed", 6628]]);

export const QUEUED_ARCS = dQ.arcs;
export const QUEUED_TOTAL = dQ.total;
export const PROCESSED_ARCS = dP.arcs;
export const PROCESSED_TOTAL = "57.7K";

/* ───────── Throughput line chart ───────── */
function rnd(i: number): number {
  const x = Math.sin(i * 91.731) * 43758.5453;
  return x - Math.floor(x);
}
function series(n: number, base: number, amp: number, noise: number, phase: number): number[] {
  const out: number[] = [];
  for (let i = 0; i < n; i++) {
    const t = i / n;
    const v =
      base +
      Math.sin(t * Math.PI * 9 + phase) * amp * 0.42 +
      Math.sin(t * Math.PI * 24 + phase * 2) * amp * 0.22 +
      (rnd(i + phase) - 0.5) * noise;
    out.push(Math.max(0, v));
  }
  return out;
}
function linePath(vals: number[], CW: number, CH: number, CMAX: number): string {
  return vals
    .map((v, i) => {
      const x = (i / (vals.length - 1)) * CW;
      const y = CH - (v / CMAX) * CH;
      return `${i ? "L" : "M"}${x.toFixed(1)} ${y.toFixed(1)}`;
    })
    .join(" ");
}

const N = 90;
const CW = 1000;
const CH = 300;
const CMAX = 620;
export const COMPLETED_PATH = linePath(series(N, 400, 150, 70, 0.4), CW, CH, CMAX);
export const FAILED_PATH = linePath(series(N, 48, 22, 26, 2.1), CW, CH, CMAX);
export const COMPLETED_AREA = `${COMPLETED_PATH} L1000 300 L0 300 Z`;
export const GRID_LINES = [0, 100, 200, 300, 400, 500, 600].map((g) => (CH - (g / CMAX) * CH).toFixed(1));
export const Y_TICKS = ["600", "500", "400", "300", "200", "100", "0"];
export const X_TICKS = ["09:40", "10:00", "10:20", "10:40", "11:00", "11:20"];

/* ───────── Jobs ───────── */
export interface JobRow extends Record<string, unknown> {
  id: string;
  name: string;
  status: QueueState;
  attempts: string;
  duration: string;
  age: string;
}
export const JOB_ROWS: JobRow[] = [
  { id: "#48210", name: "charge.capture", status: "completed", attempts: "1/3", duration: "412 ms", age: "2s ago" },
  { id: "#48209", name: "invoice.render", status: "active", attempts: "1/3", duration: "1.2 s", age: "3s ago" },
  { id: "#48208", name: "email.receipt", status: "completed", attempts: "1/3", duration: "318 ms", age: "5s ago" },
  { id: "#48207", name: "charge.capture", status: "failed", attempts: "3/3", duration: "2.1 min", age: "8s ago" },
  { id: "#48206", name: "fulfilment.sync", status: "delayed", attempts: "0/5", duration: "—", age: "11s ago" },
  { id: "#48205", name: "ledger.post", status: "completed", attempts: "1/3", duration: "504 ms", age: "14s ago" },
  { id: "#48204", name: "webhook.dispatch", status: "waiting", attempts: "0/3", duration: "—", age: "16s ago" },
  { id: "#48203", name: "invoice.render", status: "completed", attempts: "2/3", duration: "889 ms", age: "21s ago" },
];

/* ───────── Job Groups & Batches (the row pattern) ───────── */
export type ProgressTone = "brand" | "positive" | "negative" | "caution";
export interface FlowRow {
  name: string;
  meta: string;
  done: number;
  total: number;
  pct: number;
  status: QueueState;
  tone: ProgressTone;
  mono?: boolean;
}

function pct(done: number, total: number): number {
  return Math.round((done / total) * 100);
}
function barTone(status: QueueState): ProgressTone {
  if (status === "completed") return "positive";
  if (status === "delayed") return "caution";
  if (status === "failed") return "negative";
  return "brand";
}

export const GROUPS: FlowRow[] = [
  { name: "checkout-flow", done: 184, total: 200, children: 16, status: "active" },
  { name: "nightly-rollup", done: 512, total: 512, children: 0, status: "completed" },
  { name: "media-transcode", done: 73, total: 140, children: 9, status: "active" },
  { name: "user-export-9931", done: 22, total: 60, children: 4, status: "delayed" },
].map((g) => ({
  name: g.name,
  meta: `${g.children} child queues · parent group`,
  done: g.done,
  total: g.total,
  pct: pct(g.done, g.total),
  status: g.status as QueueState,
  tone: barTone(g.status as QueueState),
}));

export const BATCHES: FlowRow[] = [
  { name: "batch-2f1a", done: 940, total: 1000, failed: 12, status: "active" },
  { name: "batch-7c4d", done: 1000, total: 1000, failed: 0, status: "completed" },
  { name: "batch-b830", done: 410, total: 1200, failed: 88, status: "active" },
  { name: "batch-e07f", done: 300, total: 300, failed: 41, status: "failed" },
].map((b) => ({
  name: b.name,
  meta: `${b.failed} failed · ${b.total} jobs`,
  done: b.done,
  total: b.total,
  pct: pct(b.done, b.total),
  status: b.status as QueueState,
  tone: barTone(b.status as QueueState),
  mono: true,
}));

/* ───────── Processors ───────── */
export interface Processor {
  name: string;
  concurrency: number;
  active: number;
  rate: string;
  util: number;
  tone: ProgressTone;
}
export const PROC_DATA: Processor[] = [
  { name: "order-processing", concurrency: 24, active: 7, rate: "412/min", util: 78 },
  { name: "bulk-flows-workers", concurrency: 64, active: 31, rate: "1.2K/min", util: 91 },
  { name: "cdn-upload", concurrency: 8, active: 1, rate: "44/min", util: 18 },
  { name: "campaign-runner", concurrency: 16, active: 0, rate: "0/min", util: 0 },
].map((p) => ({ ...p, tone: (p.util > 85 ? "caution" : "brand") as ProgressTone }));
