<script>
  import Tag from "./mercury/Tag.svelte";
  import Progress from "./mercury/Progress.svelte";
  import Switch from "./mercury/Switch.svelte";
  import Search from "./mercury/Search.svelte";
  import Table from "./mercury/Table.svelte";
  import Pagination from "./mercury/Pagination.svelte";
  import Segmented from "./mercury/Segmented.svelte";
  import Avatar from "./mercury/Avatar.svelte";
  import Tooltip from "./mercury/Tooltip.svelte";
  import Toaster from "./mercury/Toaster.svelte";
  import { toast } from "./mercury/toast.svelte.js";

  /* ---- theme toggle is owned by the host (wrapper class) ---- */
  let { onToggleTheme, theme = "dark" } = $props();

  /* ---- inline icons (simple stroke glyphs) ---- */
  const ic = (b) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${b}</svg>`;
  const plusSvg = ic('<path d="M12 5v14M5 12h14"/>');
  const refreshSvg = ic('<path d="M21 12a9 9 0 1 1-2.6-6.4M21 4v4h-4"/>');
  const trashSvg = ic('<path d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14"/>');
  const copySvg = ic('<rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h8"/>');
  const pauseSvg = ic('<path d="M8 5v14M16 5v14"/>');
  const playSvg = `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M8 5.5v13l11-6.5z"/></svg>`;
  const teamSvg = ic('<circle cx="9" cy="8" r="3"/><path d="M3 20a6 6 0 0 1 12 0M16 6a3 3 0 0 1 0 6M21 20a5 5 0 0 0-4-5"/>');
  const bankSvg = ic('<path d="M3 10h18M5 10v8m4-8v8m6-8v8m4-8v8M3 21h18M12 3l9 5H3z"/>');
  const boltSvg = `<svg viewBox="0 0 24 24" fill="currentColor"><path d="M13 2L4 14h6l-1 8 9-12h-6z"/></svg>`;
  const sunSvg = ic('<circle cx="12" cy="12" r="4"/><path d="M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5M17.5 17.5L19 19M19 5l-1.5 1.5M6.5 17.5L5 19"/>');
  const moonSvg = ic('<path d="M21 12.8A8 8 0 1 1 11.2 3a6 6 0 0 0 9.8 9.8z"/>');
  const flowSvg = ic('<circle cx="6" cy="6" r="2.5"/><circle cx="18" cy="6" r="2.5"/><circle cx="12" cy="18" r="2.5"/><path d="M7.5 7.8 11 15m6-7.2L13 15"/>');
  const batchSvg = ic('<rect x="3" y="4" width="18" height="5" rx="1"/><rect x="3" y="11" width="18" height="5" rx="1"/><path d="M6 20h12"/>');

  /* ---- categorical colour map (token-driven, theme-aware) ---- */
  const COL = {
    waiting:     "rgb(var(--slate-9))",
    active:      "rgb(var(--indigo-9))",
    delayed:     "rgb(var(--orange-9))",
    prioritized: "rgb(167 139 250)",
    completed:   "rgb(var(--green-9))",
    failed:      "rgb(var(--red-9))",
  };
  const LABELS = {
    waiting: "Waiting", active: "Active", delayed: "Delayed",
    prioritized: "Prioritized", completed: "Completed", failed: "Failed",
  };

  /* ---- main views ---- */
  const views = ["Message Queue", "Jobs", "Job Groups", "Batches", "Processors", "Statistics"];
  let view = $state("Message Queue");
  let running = $state(true);
  let range = $state("1m");
  let page = $state(1);
  let search = $state("");

  /* ---- sidebar queues ---- */
  const queues = [
    { name: "analytics", segs: [{ k: "completed", v: 1 }] },
    { name: "build-service", segs: [{ k: "completed", v: 3 }] },
    { name: "bulk-flows", segs: [{ k: "waiting", v: 69 }, { k: "prioritized", v: 31 }] },
    { name: "bulk-flows-workers", segs: [{ k: "delayed", v: 8 }, { k: "completed", v: 412 }, { k: "failed", v: 24 }] },
    { name: "campaign-runner", segs: [] },
    { name: "cdn-upload", segs: [{ k: "active", v: 1 }] },
    { name: "collapsed-children", segs: [{ k: "prioritized", v: 6 }, { k: "completed", v: 43 }, { k: "failed", v: 17 }] },
    { name: "collapsed-grandchildren", segs: [{ k: "completed", v: 75 }, { k: "failed", v: 12 }] },
    { name: "collapsed-node-test", segs: [{ k: "waiting", v: 4 }, { k: "prioritized", v: 4 }] },
    { name: "data-extract", segs: [{ k: "completed", v: 3 }] },
    { name: "data-transform", segs: [{ k: "completed", v: 1 }, { k: "failed", v: 1 }] },
    { name: "demo-flows", segs: [{ k: "prioritized", v: 5 }, { k: "completed", v: 18 }, { k: "failed", v: 6 }] },
    { name: "deploy-pipeline", segs: [{ k: "prioritized", v: 2 }, { k: "completed", v: 2 }] },
    { name: "order-processing", segs: [{ k: "waiting", v: 43 }, { k: "active", v: 7 }, { k: "completed", v: 120 }, { k: "failed", v: 18 }] },
  ];
  let selected = $state("order-processing");
  const filtered = $derived(
    queues.filter((q) => q.name.toLowerCase().includes(search.toLowerCase())),
  );

  function segTotal(segs) { return segs.reduce((a, s) => a + s.v, 0); }

  /* ---- top metric strip ---- */
  const meta = [
    { label: "Version", value: "8.4.0" },
    { label: "Mode", value: "standalone" },
    { label: "Used Memory", value: "57.34 MB" },
    { label: "Total Memory", value: "7.65 GB" },
    { label: "Clients", value: "16 / 10000" },
  ];

  /* ---- stat cards ---- */
  const stats = [
    { k: "waiting", label: "Waiting", value: "43" },
    { k: "active", label: "Active", value: "7" },
    { k: "delayed", label: "Delayed", value: "35" },
    { k: "prioritized", label: "Prioritized", value: "81" },
    { k: "completed", label: "Completed", value: "51.1K" },
    { k: "failed", label: "Failed", value: "6 628" },
  ];

  /* ---- donuts ---- */
  const queuedSegs = [
    { k: "waiting", v: 43 }, { k: "active", v: 7 },
    { k: "delayed", v: 35 }, { k: "prioritized", v: 81 },
  ];
  const processedSegs = [
    { k: "completed", v: 51064 }, { k: "failed", v: 6628 },
  ];

  function donut(segs) {
    const total = segs.reduce((a, s) => a + s.v, 0);
    const r = 62, C = 2 * Math.PI * r;
    let acc = 0;
    const arcs = segs.map((s) => {
      const frac = s.v / total;
      const len = frac * C;
      const arc = { k: s.k, v: s.v, frac, dash: `${len} ${C - len}`, offset: -acc };
      acc += len;
      return arc;
    });
    return { total, r, C, arcs };
  }
  const dQueued = donut(queuedSegs);
  const dProcessed = donut(processedSegs);

  /* ---- throughput series (deterministic) ---- */
  function rnd(i) { const x = Math.sin(i * 91.731) * 43758.5453; return x - Math.floor(x); }
  function series(n, base, amp, noise, phase) {
    const out = [];
    for (let i = 0; i < n; i++) {
      const t = i / n;
      const v = base
        + Math.sin(t * Math.PI * 9 + phase) * amp * 0.42
        + Math.sin(t * Math.PI * 24 + phase * 2) * amp * 0.22
        + (rnd(i + phase) - 0.5) * noise;
      out.push(Math.max(0, v));
    }
    return out;
  }
  const N = 90, CW = 1000, CH = 300, CMAX = 620;
  const completedSeries = series(N, 400, 150, 70, 0.4);
  const failedSeries = series(N, 48, 22, 26, 2.1);

  function linePath(vals) {
    return vals.map((v, i) => {
      const x = (i / (vals.length - 1)) * CW;
      const y = CH - (v / CMAX) * CH;
      return `${i ? "L" : "M"}${x.toFixed(1)} ${y.toFixed(1)}`;
    }).join(" ");
  }
  const areaPath = (vals) => `${linePath(vals)} L${CW} ${CH} L0 ${CH} Z`;

  const respTime = { min: "322 ms", median: "2.4 sec", max: "2.1 min" };
  const procTime = { min: "137 ms", median: "626 ms", max: "3.6 sec" };

  /* ---- Jobs ---- */
  const jobCols = [
    { key: "id", label: "Job ID", width: "92px" },
    { key: "name", label: "Name" },
    { key: "status", label: "Status" },
    { key: "attempts", label: "Attempts", align: "center" },
    { key: "duration", label: "Duration", align: "right" },
    { key: "age", label: "Added", align: "right" },
  ];
  const jobRows = [
    { id: "#48210", name: "charge.capture", status: "completed", attempts: "1/3", duration: "412 ms", age: "2s ago" },
    { id: "#48209", name: "invoice.render", status: "active", attempts: "1/3", duration: "1.2 s", age: "3s ago" },
    { id: "#48208", name: "email.receipt", status: "completed", attempts: "1/3", duration: "318 ms", age: "5s ago" },
    { id: "#48207", name: "charge.capture", status: "failed", attempts: "3/3", duration: "2.1 min", age: "8s ago" },
    { id: "#48206", name: "fulfilment.sync", status: "delayed", attempts: "0/5", duration: "—", age: "11s ago" },
    { id: "#48205", name: "ledger.post", status: "completed", attempts: "1/3", duration: "504 ms", age: "14s ago" },
    { id: "#48204", name: "webhook.dispatch", status: "waiting", attempts: "0/3", duration: "—", age: "16s ago" },
    { id: "#48203", name: "invoice.render", status: "completed", attempts: "2/3", duration: "889 ms", age: "21s ago" },
  ];
  const statusTone = { completed: "positive", active: "info", failed: "negative", delayed: "caution", waiting: "neutral", prioritized: "discovery" };

  /* ---- Job Groups & Batches ---- */
  const groups = [
    { name: "checkout-flow", done: 184, total: 200, children: 16, status: "active" },
    { name: "nightly-rollup", done: 512, total: 512, children: 0, status: "completed" },
    { name: "media-transcode", done: 73, total: 140, children: 9, status: "active" },
    { name: "user-export-9931", done: 22, total: 60, children: 4, status: "delayed" },
  ];
  const batches = [
    { name: "batch-2f1a", done: 940, total: 1000, failed: 12, status: "active" },
    { name: "batch-7c4d", done: 1000, total: 1000, failed: 0, status: "completed" },
    { name: "batch-b830", done: 410, total: 1200, failed: 88, status: "active" },
    { name: "batch-e07f", done: 300, total: 300, failed: 41, status: "failed" },
  ];

  /* ---- Processors ---- */
  const processors = $state([
    { name: "order-processing", concurrency: 24, active: 7, rate: "412/min", util: 78, paused: false },
    { name: "bulk-flows-workers", concurrency: 64, active: 31, rate: "1.2K/min", util: 91, paused: false },
    { name: "cdn-upload", concurrency: 8, active: 1, rate: "44/min", util: 18, paused: false },
    { name: "campaign-runner", concurrency: 16, active: 0, rate: "0/min", util: 0, paused: true },
  ]);

  function toggleRun() {
    running = !running;
    running ? toast.success("Queue resumed") : toast.warning("Queue paused");
  }
</script>

<div class="eq">
  <!-- ============ SIDEBAR ============ -->
  <aside class="eq-side">
    <div class="eq-side__top">
      <div class="eq-side__title">
        <span>CONNECTIONS</span>
        <button class="eq-iconbtn" aria-label="Add connection">{@html plusSvg}</button>
      </div>
      <p class="eq-side__sub">Used 1 of 15 connections.</p>
      <div class="eq-side__search"><Search bind:value={search} placeholder="Search" /></div>
    </div>

    <div class="eq-org">
      <span class="eq-org__icon">{@html bankSvg}</span>
      <span class="eq-org__name">ACME CORP</span>
      <button class="eq-iconbtn" aria-label="Refresh">{@html refreshSvg}</button>
    </div>
    <div class="eq-team">
      <span class="eq-team__dot">{@html teamSvg}</span>
      <span class="eq-team__name">Core Team</span>
    </div>

    <div class="eq-conn">
      <span class="eq-conn__status"></span>
      <span class="eq-conn__name">Localhost</span>
      <div class="eq-conn__actions">
        <button class="eq-iconbtn" aria-label="Refresh">{@html refreshSvg}</button>
        <button class="eq-iconbtn" aria-label="Delete">{@html trashSvg}</button>
      </div>
    </div>

    <div class="eq-queues">
      {#each filtered as q (q.name)}
        {@const total = segTotal(q.segs)}
        <button
          class="eq-q"
          class:is-selected={selected === q.name}
          onclick={() => (selected = q.name)}
        >
          <span class="eq-q__name">{q.name}</span>
          {#if total > 0}
            <span class="eq-q__bar">
              {#each q.segs as s (s.k)}
                <span class="eq-q__seg" style="flex:{s.v};background:{COL[s.k]};">
                  {#if s.v / total > 0.16}<span class="eq-q__val">{s.v}</span>{/if}
                </span>
              {/each}
            </span>
          {:else}
            <span class="eq-q__bar eq-q__bar--empty"></span>
          {/if}
        </button>
      {/each}
    </div>
  </aside>

  <!-- ============ MAIN ============ -->
  <main class="eq-main">
    <!-- metric strip -->
    <div class="eq-strip">
      <span class="eq-brand">{@html boltSvg}</span>
      <div class="eq-strip__divider"></div>
      {#each meta as m (m.label)}
        <div class="eq-meta">
          <span class="eq-meta__label">{m.label}</span>
          <span class="eq-meta__value">{m.value}</span>
        </div>
      {/each}
    </div>

    <!-- queue header -->
    <div class="eq-qhead">
      <button class="eq-iconbtn eq-iconbtn--lg" aria-label="Refresh">{@html refreshSvg}</button>
      <div class="eq-qhead__title">
        <h3>{selected}</h3>
        <p>Using: EchoMQ Bus v8.4.0 as <span>admin</span></p>
      </div>
      <nav class="eq-tabs">
        {#each views as v (v)}
          <button class="eq-tab" class:is-active={view === v} onclick={() => (view = v)}>{v}</button>
        {/each}
      </nav>
      <div class="eq-runctl">
        <button class="eq-runbtn" class:is-on={!running} aria-label="Pause" onclick={toggleRun}>{@html pauseSvg}</button>
        <button class="eq-runbtn eq-runbtn--play" class:is-on={running} aria-label="Resume" onclick={toggleRun}>{@html playSvg}</button>
      </div>
      <Tooltip text="Duplicate queue">
        <button class="eq-iconbtn eq-iconbtn--lg" aria-label="Duplicate">{@html copySvg}</button>
      </Tooltip>
      <Tooltip text="Delete queue">
        <button class="eq-iconbtn eq-iconbtn--lg" aria-label="Delete">{@html trashSvg}</button>
      </Tooltip>
    </div>

    <!-- ===== view body ===== -->
    <div class="eq-body">
      {#if view === "Message Queue" || view === "Statistics"}
        <!-- stat cards -->
        <div class="eq-cards">
          {#each stats as s (s.label)}
            <div class="eq-card">
              <span class="eq-card__label">{s.label}</span>
              <span class="eq-card__value" style="color:{COL[s.k]};">{s.value}</span>
            </div>
          {/each}
        </div>

        <!-- donuts -->
        <div class="eq-grid2">
          <div class="eq-panel">
            <h6 class="eq-panel__h">Currently Queued</h6>
            <div class="eq-donutwrap">
              <svg class="eq-donut" viewBox="0 0 160 160">
                <g transform="rotate(-90 80 80)">
                  {#each dQueued.arcs as a (a.k)}
                    <circle cx="80" cy="80" r={dQueued.r} fill="none" stroke={COL[a.k]}
                      stroke-width="20" stroke-dasharray={a.dash} stroke-dashoffset={a.offset} />
                  {/each}
                </g>
                <text x="80" y="74" class="eq-donut__num">{dQueued.total}</text>
                <text x="80" y="92" class="eq-donut__cap">queued</text>
              </svg>
              <ul class="eq-legend">
                {#each dQueued.arcs as a (a.k)}
                  <li><span class="eq-legend__dot" style="background:{COL[a.k]};"></span>{LABELS[a.k]}<b>{a.v}</b></li>
                {/each}
              </ul>
            </div>
          </div>

          <div class="eq-panel">
            <h6 class="eq-panel__h">Processed</h6>
            <div class="eq-donutwrap">
              <svg class="eq-donut" viewBox="0 0 160 160">
                <g transform="rotate(-90 80 80)">
                  {#each dProcessed.arcs as a (a.k)}
                    <circle cx="80" cy="80" r={dProcessed.r} fill="none" stroke={COL[a.k]}
                      stroke-width="20" stroke-dasharray={a.dash} stroke-dashoffset={a.offset} />
                  {/each}
                </g>
                <text x="80" y="74" class="eq-donut__num">57.7K</text>
                <text x="80" y="92" class="eq-donut__cap">total</text>
              </svg>
              <ul class="eq-legend">
                {#each dProcessed.arcs as a (a.k)}
                  <li><span class="eq-legend__dot" style="background:{COL[a.k]};"></span>{LABELS[a.k]}<b>{(a.frac * 100).toFixed(1)}%</b></li>
                {/each}
              </ul>
            </div>
          </div>
        </div>

        <!-- throughput -->
        <div class="eq-panel">
          <div class="eq-panel__bar">
            <h6 class="eq-panel__h">Job Throughput</h6>
            <div class="eq-range">
              <Segmented bind:value={range} size="sm" segments={[
                {label:"1 min",value:"1m"},{label:"5 min",value:"5m"},
                {label:"15 min",value:"15m"},{label:"30 min",value:"30m"},{label:"1 hour",value:"1h"}]} />
            </div>
          </div>
          <div class="eq-legend eq-legend--inline">
            <span><span class="eq-legend__dot" style="background:{COL.completed};"></span>Completed</span>
            <span><span class="eq-legend__dot" style="background:{COL.failed};"></span>Failed</span>
          </div>
          <div class="eq-chart">
            <svg viewBox="0 0 1000 300" preserveAspectRatio="none" class="eq-chart__svg">
              {#each [0,100,200,300,400,500,600] as g (g)}
                <line x1="0" x2="1000" y1={CH - (g/CMAX)*CH} y2={CH - (g/CMAX)*CH} class="eq-chart__grid" />
              {/each}
              <path d={areaPath(completedSeries)} fill="url(#cgrad)" stroke="none" />
              <path d={linePath(completedSeries)} fill="none" stroke={COL.completed} stroke-width="2.5" />
              <path d={linePath(failedSeries)} fill="none" stroke={COL.failed} stroke-width="2.5" />
              <defs>
                <linearGradient id="cgrad" x1="0" x2="0" y1="0" y2="1">
                  <stop offset="0%" stop-color={COL.completed} stop-opacity="0.28" />
                  <stop offset="100%" stop-color={COL.completed} stop-opacity="0" />
                </linearGradient>
              </defs>
            </svg>
            <div class="eq-chart__yaxis">
              {#each [600,500,400,300,200,100,0] as g (g)}<span>{g}</span>{/each}
            </div>
            <div class="eq-chart__xaxis">
              {#each ["09:40","10:00","10:20","10:40","11:00","11:20"] as t (t)}<span>{t}</span>{/each}
            </div>
          </div>
        </div>

        <!-- timing -->
        <div class="eq-grid2">
          <div class="eq-panel">
            <h6 class="eq-panel__h">Response Time — Time in Queue</h6>
            <div class="eq-timing">
              <div><span>Min</span><b style="color:{COL.completed};">{respTime.min}</b></div>
              <div><span>Median</span><b style="color:{COL.active};">{respTime.median}</b></div>
              <div><span>Max</span><b style="color:{COL.delayed};">{respTime.max}</b></div>
            </div>
          </div>
          <div class="eq-panel">
            <h6 class="eq-panel__h">Process Time — Time in Workers</h6>
            <div class="eq-timing">
              <div><span>Min</span><b style="color:{COL.completed};">{procTime.min}</b></div>
              <div><span>Median</span><b style="color:{COL.active};">{procTime.median}</b></div>
              <div><span>Max</span><b style="color:{COL.delayed};">{procTime.max}</b></div>
            </div>
          </div>
        </div>

      {:else if view === "Jobs"}
        <div class="eq-panel">
          <div class="eq-panel__bar">
            <h6 class="eq-panel__h">Recent Jobs · {selected}</h6>
            <span class="eq-muted">8 of 2,431 jobs</span>
          </div>
          <Table columns={jobCols} rows={jobRows}>
            {#snippet cell(row, col)}
              {#if col.key === "status"}
                <Tag tone={statusTone[row.status]} dot>{row.status}</Tag>
              {:else if col.key === "id"}
                <span class="eq-mono">{row.id}</span>
              {:else if col.key === "name"}
                <span class="eq-mono eq-strong">{row.name}</span>
              {:else}
                {row[col.key]}
              {/if}
            {/snippet}
          </Table>
          <div class="eq-pag"><Pagination bind:page pageCount={304} siblings={1} showFirstLast /></div>
        </div>

      {:else if view === "Job Groups"}
        <div class="eq-list">
          {#each groups as g (g.name)}
            {@const pct = Math.round((g.done / g.total) * 100)}
            <div class="eq-panel eq-row">
              <div class="eq-row__lead">
                <span class="eq-flowicon">{@html flowSvg}</span>
                <div>
                  <div class="eq-row__name">{g.name}</div>
                  <div class="eq-row__meta">{g.children} child queues · parent group</div>
                </div>
              </div>
              <div class="eq-row__prog">
                <div class="eq-row__progtop"><span>{g.done} / {g.total}</span><span>{pct}%</span></div>
                <Progress value={pct} variant={g.status === "completed" ? "positive" : g.status === "delayed" ? "caution" : "brand"} />
              </div>
              <Tag tone={statusTone[g.status]} dot>{g.status}</Tag>
            </div>
          {/each}
        </div>

      {:else if view === "Batches"}
        <div class="eq-list">
          {#each batches as b (b.name)}
            {@const pct = Math.round((b.done / b.total) * 100)}
            <div class="eq-panel eq-row">
              <div class="eq-row__lead">
                <span class="eq-flowicon">{@html batchSvg}</span>
                <div>
                  <div class="eq-row__name eq-mono">{b.name}</div>
                  <div class="eq-row__meta">{b.failed} failed · {b.total} jobs</div>
                </div>
              </div>
              <div class="eq-row__prog">
                <div class="eq-row__progtop"><span>{b.done} / {b.total}</span><span>{pct}%</span></div>
                <Progress value={pct} variant={b.status === "completed" ? "positive" : b.status === "failed" ? "negative" : "brand"} />
              </div>
              <Tag tone={statusTone[b.status]} dot>{b.status}</Tag>
            </div>
          {/each}
        </div>

      {:else if view === "Processors"}
        <div class="eq-procgrid">
          {#each processors as p (p.name)}
            <div class="eq-panel eq-proc">
              <div class="eq-proc__top">
                <div class="eq-row__name">{p.name}</div>
                <Switch bind:checked={p.paused} label={p.paused ? "Paused" : "Running"} />
              </div>
              <div class="eq-proc__stats">
                <div><span>Concurrency</span><b>{p.concurrency}</b></div>
                <div><span>Active</span><b style="color:{COL.active};">{p.active}</b></div>
                <div><span>Rate</span><b>{p.rate}</b></div>
              </div>
              <div class="eq-row__progtop"><span>Utilisation</span><span>{p.util}%</span></div>
              <Progress value={p.util} variant={p.util > 85 ? "caution" : "brand"} />
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </main>
  <Toaster />
</div>

<style>
  /* ---------- shell ---------- */
  .eq {
    display: flex;
    height: 100%;
    width: 100%;
    background: rgb(var(--bg-primary));
    color: rgb(var(--fg-primary));
    font-family: var(--font-primary);
    overflow: hidden;
  }
  .eq :global(*) { box-sizing: border-box; }

  /* ---------- sidebar ---------- */
  .eq-side {
    width: 300px;
    flex-shrink: 0;
    background: rgb(var(--bg-secondary));
    border-right: 1px solid rgb(var(--border-secondary));
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }
  .eq-side__top { padding: 20px 18px 14px; border-bottom: 1px solid rgb(var(--border-secondary)); }
  .eq-side__title {
    display: flex; align-items: center; justify-content: center; gap: 8px;
    font: 700 13px/1 var(--font-primary); letter-spacing: 0.12em;
    color: rgb(var(--fg-primary));
  }
  .eq-side__sub {
    margin: 8px 0 14px; text-align: center;
    font: 500 11px/1 var(--font-primary); letter-spacing: 0.04em;
    color: rgb(var(--fg-tertiary));
  }
  .eq-org, .eq-conn {
    display: flex; align-items: center; gap: 10px;
    padding: 14px 18px;
  }
  .eq-org { border-bottom: 1px solid rgb(var(--border-secondary)); }
  .eq-org__icon, .eq-conn__status { display: inline-flex; }
  .eq-org__name {
    flex: 1; font: 700 14px/1 var(--font-primary); letter-spacing: 0.06em;
  }
  .eq-team { display: flex; align-items: center; gap: 8px; padding: 10px 18px 4px; }
  .eq-team__name { font: 600 13px/1 var(--font-primary); color: rgb(var(--iris-11)); }
  .eq-team__dot { color: rgb(var(--iris-11)); display: inline-flex; }
  .eq-conn__status {
    width: 8px; height: 8px; border-radius: 50%;
    background: rgb(var(--green-9)); box-shadow: 0 0 0 3px rgb(var(--green-9) / 0.2);
  }
  .eq-conn__name { flex: 1; font: 600 14px/1 var(--font-primary); }
  .eq-conn__actions { display: flex; gap: 2px; }

  .eq-queues { flex: 1; overflow-y: auto; padding: 6px 12px 24px; }
  .eq-q {
    display: block; width: 100%; text-align: left;
    background: transparent; border: 0; cursor: pointer;
    padding: 9px 8px; border-radius: var(--radius-8);
    transition: background 120ms ease;
  }
  .eq-q:hover { background: rgb(var(--bg-hover)); }
  .eq-q.is-selected { background: rgb(var(--bg-selected)); }
  .eq-q__name {
    display: block; font: 500 13px/1.2 var(--font-primary);
    color: rgb(var(--fg-secondary)); margin-bottom: 7px;
  }
  .eq-q.is-selected .eq-q__name { color: rgb(var(--fg-primary)); font-weight: 600; }
  .eq-q__bar {
    display: flex; height: 18px; border-radius: var(--radius-4);
    overflow: hidden; gap: 2px;
  }
  .eq-q__bar--empty { background: rgb(var(--bg-tertiary)); height: 6px; margin-top: 6px; }
  .eq-q__seg {
    display: flex; align-items: center; justify-content: center;
    min-width: 0; border-radius: 3px;
  }
  .eq-q__val {
    font: 700 10px/1 var(--font-primary); color: #fff;
    text-shadow: 0 1px 1px rgb(0 0 0 / 0.25); padding: 0 2px;
  }

  .eq-iconbtn {
    display: inline-flex; align-items: center; justify-content: center;
    width: 28px; height: 28px; border-radius: var(--radius-6);
    background: transparent; border: 0; cursor: pointer;
    color: rgb(var(--fg-tertiary)); transition: background 120ms, color 120ms;
  }
  .eq-iconbtn:hover { background: rgb(var(--bg-hover)); color: rgb(var(--fg-primary)); }
  .eq-iconbtn--lg { width: 40px; height: 40px; border-radius: var(--radius-8); }
  .eq-iconbtn svg { width: 16px; height: 16px; }
  .eq-iconbtn--lg svg { width: 18px; height: 18px; }

  /* ---------- main ---------- */
  .eq-main { flex: 1; display: flex; flex-direction: column; overflow: hidden; }

  .eq-strip {
    display: flex; align-items: center; gap: 22px;
    padding: 14px 24px;
    border-bottom: 1px solid rgb(var(--border-secondary));
    background: rgb(var(--bg-secondary));
    flex-shrink: 0; overflow-x: auto;
  }
  .eq-brand { color: rgb(var(--red-9)); display: inline-flex; }
  .eq-brand svg { width: 30px; height: 30px; }
  .eq-strip__divider { width: 1px; height: 34px; background: rgb(var(--border-primary)); }
  .eq-meta { display: flex; flex-direction: column; gap: 4px; white-space: nowrap; }
  .eq-meta__label {
    font: 700 10px/1 var(--font-primary); letter-spacing: 0.1em;
    text-transform: uppercase; color: rgb(var(--fg-tertiary));
  }
  .eq-meta__value { font: 600 15px/1 var(--font-secondary); color: rgb(var(--fg-primary)); }

  .eq-qhead {
    display: flex; align-items: center; gap: 14px;
    padding: 16px 24px;
    border-bottom: 1px solid rgb(var(--border-secondary));
    flex-shrink: 0;
  }
  .eq-qhead__title { margin-right: auto; }
  .eq-qhead__title h3 { font: 700 22px/1.1 var(--font-primary); letter-spacing: -0.01em; }
  .eq-qhead__title p { margin: 4px 0 0; font: 400 12px/1 var(--font-primary); color: rgb(var(--fg-tertiary)); }
  .eq-qhead__title p span { color: rgb(var(--fg-secondary)); }

  .eq-tabs { display: flex; gap: 4px; flex-wrap: wrap; }
  .eq-tab {
    background: transparent; border: 0; cursor: pointer;
    padding: 8px 12px; border-radius: var(--radius-8);
    font: 500 14px/1 var(--font-primary); color: rgb(var(--fg-tertiary));
    transition: color 120ms, background 120ms;
  }
  .eq-tab:hover { color: rgb(var(--fg-primary)); background: rgb(var(--bg-hover)); }
  .eq-tab.is-active { color: rgb(var(--fg-primary)); font-weight: 600; background: rgb(var(--bg-selected)); }

  .eq-runctl {
    display: flex; gap: 2px; padding: 3px;
    background: rgb(var(--bg-tertiary)); border-radius: var(--radius-8);
  }
  .eq-runbtn {
    display: inline-flex; align-items: center; justify-content: center;
    width: 36px; height: 32px; border: 0; border-radius: var(--radius-6);
    background: transparent; cursor: pointer; color: rgb(var(--fg-tertiary));
    transition: background 120ms, color 120ms;
  }
  .eq-runbtn svg { width: 16px; height: 16px; }
  .eq-runbtn.is-on { color: rgb(var(--fg-primary)); }
  .eq-runbtn--play.is-on { background: rgb(var(--green-9)); color: #fff; }

  .eq-body { flex: 1; overflow-y: auto; padding: 22px 24px 60px; }

  /* stat cards */
  .eq-cards {
    display: grid; grid-template-columns: repeat(6, 1fr); gap: 14px; margin-bottom: 18px;
  }
  .eq-card {
    background: rgb(var(--bg-secondary)); border: 1px solid rgb(var(--border-secondary));
    border-radius: var(--radius-12); padding: 16px 18px;
    display: flex; flex-direction: column; gap: 10px;
  }
  .eq-card__label {
    font: 700 11px/1 var(--font-primary); letter-spacing: 0.08em;
    text-transform: uppercase; color: rgb(var(--fg-tertiary));
  }
  .eq-card__value { font: 700 30px/1 var(--font-secondary); letter-spacing: -0.02em; }

  /* panels */
  .eq-panel {
    background: rgb(var(--bg-secondary)); border: 1px solid rgb(var(--border-secondary));
    border-radius: var(--radius-16); padding: 20px 22px; margin-bottom: 18px;
  }
  .eq-panel__h {
    margin: 0; font: 700 12px/1 var(--font-primary); letter-spacing: 0.08em;
    text-transform: uppercase; color: rgb(var(--fg-secondary));
  }
  .eq-panel__bar { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-bottom: 14px; }
  .eq-grid2 { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; }
  .eq-muted { font: 400 12px/1 var(--font-primary); color: rgb(var(--fg-tertiary)); }

  /* donuts */
  .eq-donutwrap { display: flex; align-items: center; gap: 28px; margin-top: 18px; }
  .eq-donut { width: 168px; height: 168px; flex-shrink: 0; }
  .eq-donut__num { text-anchor: middle; font: 700 28px/1 var(--font-secondary); fill: rgb(var(--fg-primary)); }
  .eq-donut__cap { text-anchor: middle; font: 500 11px/1 var(--font-primary); letter-spacing: 0.08em; text-transform: uppercase; fill: rgb(var(--fg-tertiary)); }
  .eq-legend { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 12px; }
  .eq-legend li { display: flex; align-items: center; gap: 9px; font: 500 13px/1 var(--font-primary); color: rgb(var(--fg-secondary)); }
  .eq-legend li b { margin-left: auto; font: 600 13px/1 var(--font-secondary); color: rgb(var(--fg-primary)); padding-left: 18px; }
  .eq-legend__dot { width: 10px; height: 10px; border-radius: 3px; flex-shrink: 0; }
  .eq-legend--inline { flex-direction: row; gap: 20px; margin-bottom: 10px; }
  .eq-legend--inline span { display: inline-flex; align-items: center; gap: 8px; font: 500 12px/1 var(--font-primary); color: rgb(var(--fg-secondary)); }

  /* chart */
  .eq-chart { position: relative; padding-left: 38px; padding-bottom: 24px; }
  .eq-chart__svg { width: 100%; height: 300px; display: block; overflow: visible; }
  .eq-chart__grid { stroke: rgb(var(--border-secondary)); stroke-width: 1; }
  .eq-chart__yaxis {
    position: absolute; left: 0; top: 0; height: 300px; width: 34px;
    display: flex; flex-direction: column; justify-content: space-between;
    text-align: right; font: 400 10px/1 var(--font-secondary); color: rgb(var(--fg-tertiary));
  }
  .eq-chart__xaxis {
    display: flex; justify-content: space-between; margin: 8px 0 0 0;
    font: 400 10px/1 var(--font-secondary); color: rgb(var(--fg-tertiary));
  }

  /* timing */
  .eq-timing { display: flex; gap: 40px; margin-top: 18px; }
  .eq-timing div { display: flex; flex-direction: column; gap: 8px; }
  .eq-timing span { font: 700 11px/1 var(--font-primary); letter-spacing: 0.08em; text-transform: uppercase; color: rgb(var(--fg-tertiary)); }
  .eq-timing b { font: 700 26px/1 var(--font-secondary); }

  /* tables / misc */
  .eq-pag { display: flex; justify-content: flex-end; margin-top: 16px; }
  .eq-mono { font-family: var(--font-secondary); font-size: 13px; }
  .eq-strong { color: rgb(var(--fg-primary)); font-weight: 500; }

  /* lists (groups / batches) */
  .eq-list { display: flex; flex-direction: column; gap: 14px; }
  .eq-row { display: flex; align-items: center; gap: 24px; margin-bottom: 0; }
  .eq-row__lead { display: flex; align-items: center; gap: 14px; width: 280px; flex-shrink: 0; }
  .eq-flowicon {
    width: 40px; height: 40px; border-radius: var(--radius-10, 10px);
    display: inline-flex; align-items: center; justify-content: center;
    background: rgb(var(--bg-brand-subtle)); color: rgb(var(--fg-brand)); flex-shrink: 0;
  }
  .eq-flowicon svg { width: 20px; height: 20px; }
  .eq-row__name { font: 600 15px/1.2 var(--font-primary); }
  .eq-row__meta { margin-top: 4px; font: 400 12px/1 var(--font-primary); color: rgb(var(--fg-tertiary)); }
  .eq-row__prog { flex: 1; }
  .eq-row__progtop { display: flex; justify-content: space-between; margin-bottom: 8px; font: 500 12px/1 var(--font-secondary); color: rgb(var(--fg-secondary)); }

  /* processors */
  .eq-procgrid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
  .eq-proc { margin-bottom: 0; }
  .eq-proc__top { display: flex; align-items: center; justify-content: space-between; margin-bottom: 18px; }
  .eq-proc__stats { display: flex; gap: 32px; margin-bottom: 18px; }
  .eq-proc__stats div { display: flex; flex-direction: column; gap: 6px; }
  .eq-proc__stats span { font: 700 10px/1 var(--font-primary); letter-spacing: 0.08em; text-transform: uppercase; color: rgb(var(--fg-tertiary)); }
  .eq-proc__stats b { font: 700 20px/1 var(--font-secondary); }

  @media (max-width: 1100px) {
    .eq-cards { grid-template-columns: repeat(3, 1fr); }
    .eq-grid2, .eq-procgrid { grid-template-columns: 1fr; }
  }
</style>
