<script>
  import Button from "./mercury/Button.svelte";
  import Input from "./mercury/Input.svelte";
  import Select from "./mercury/Select.svelte";
  import Search from "./mercury/Search.svelte";
  import Slider from "./mercury/Slider.svelte";
  import Switch from "./mercury/Switch.svelte";
  import Checkbox from "./mercury/Checkbox.svelte";
  import Radio from "./mercury/Radio.svelte";
  import Segmented from "./mercury/Segmented.svelte";
  import Tabs from "./mercury/Tabs.svelte";
  import Avatar from "./mercury/Avatar.svelte";
  import Badge from "./mercury/Badge.svelte";
  import Tag from "./mercury/Tag.svelte";
  import Chip from "./mercury/Chip.svelte";
  import Loader from "./mercury/Loader.svelte";
  import Alert from "./mercury/Alert.svelte";
  import Progress from "./mercury/Progress.svelte";
  import Accordion from "./mercury/Accordion.svelte";
  import Breadcrumb from "./mercury/Breadcrumb.svelte";
  import Pagination from "./mercury/Pagination.svelte";
  import Tooltip from "./mercury/Tooltip.svelte";
  import Card from "./mercury/Card.svelte";
  import Table from "./mercury/Table.svelte";
  import Toaster from "./mercury/Toaster.svelte";
  import { toast } from "./mercury/toast.svelte.js";

  let sw = $state(true);
  let cb = $state(true);
  let radio = $state("b");
  let seg = $state("active");
  let tab = $state("metrics");
  let sliderV = $state(64);
  let page = $state(3);
  let search = $state("");
  let inputV = $state("");

  const tableColumns = [
    { key: "queue", label: "Queue" },
    { key: "active", label: "Active", align: "right" },
    { key: "completed", label: "Completed", align: "right" },
    { key: "status", label: "Status" },
  ];
  const tableRows = [
    { id: 1, queue: "order-processing", active: 7, completed: "51.1K", status: "running" },
    { id: 2, queue: "bulk-flows", active: 31, completed: "12.4K", status: "running" },
    { id: 3, queue: "cdn-upload", active: 1, completed: "8.9K", status: "paused" },
  ];

  const accItems = [
    { id: "a", title: "What is a Job Group?", content: "A logical grouping of jobs that share a parent and complete together." },
    { id: "b", title: "How are batches retried?", content: "Failed jobs in a batch are retried with exponential backoff up to the configured attempts." },
    { id: "c", title: "Processor concurrency", content: "Each processor pulls up to its concurrency limit of jobs from the queue at once." },
  ];
</script>

<div class="sc">
  <header class="sc__intro">
    <p class="sc__eyebrow">Mercury Design System</p>
    <h2 class="sc__title">Component Showcase</h2>
    <p class="sc__lead">Every component below is a real <code>.svelte</code> source file compiled in the browser at runtime and mounted live — no build step.</p>
  </header>

  <!-- BUTTONS -->
  <section class="sc__sec">
    <div class="sc__head"><h5>Buttons</h5><span class="sc__count">Button</span></div>
    <div class="sc__panel">
      <div class="sc__row">
        <Button>Primary</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="ghost">Ghost</Button>
        <Button variant="danger">Danger</Button>
        <Button disabled>Disabled</Button>
        <Button loading>Loading</Button>
      </div>
      <div class="sc__row">
        <Button size="sm">Small</Button>
        <Button size="md">Medium</Button>
        <Button size="lg">Large</Button>
        <Button icon="＋">With icon</Button>
        <Button variant="secondary" icon="↻">Refresh</Button>
      </div>
    </div>
  </section>

  <!-- FORM CONTROLS -->
  <section class="sc__sec">
    <div class="sc__head"><h5>Form controls</h5><span class="sc__count">Input · Select · Search · Slider · Switch · Checkbox · Radio · Segmented</span></div>
    <div class="sc__panel sc__grid2">
      <div class="sc__stack">
        <Input label="Connection name" placeholder="localhost:6379" bind:value={inputV} hint="Host and port of the broker." />
        <Input label="Password" type="password" value="hunter2" error="Authentication failed." />
        <Select label="Mode" value="standalone" options={[{label:"Standalone",value:"standalone"},{label:"Cluster",value:"cluster"},{label:"Sentinel",value:"sentinel"}]} />
        <Search bind:value={search} placeholder="Search queues" />
      </div>
      <div class="sc__stack">
        <Slider label="Concurrency" bind:value={sliderV} unit=" workers" max={128} />
        <div class="sc__row">
          <Switch bind:checked={sw} label="Auto-refresh" />
          <Checkbox bind:checked={cb} label="Group children" />
        </div>
        <div class="sc__row">
          <Radio bind:group={radio} value="a" label="Waiting" />
          <Radio bind:group={radio} value="b" label="Active" />
          <Radio bind:group={radio} value="c" label="Delayed" />
        </div>
        <Segmented bind:value={seg} segments={[{label:"Waiting",value:"waiting"},{label:"Active",value:"active"},{label:"Failed",value:"failed"}]} />
      </div>
    </div>
  </section>

  <!-- DISPLAY -->
  <section class="sc__sec">
    <div class="sc__head"><h5>Display</h5><span class="sc__count">Avatar · Badge · Tag · Chip · Loader</span></div>
    <div class="sc__panel">
      <div class="sc__row">
        <Avatar initials="AC" size="sm" />
        <Avatar initials="MQ" status="online" />
        <Avatar initials="BU" size="lg" status="busy" />
        <Badge value={43} tone="brand" />
        <Badge value={6628} max={999} tone="negative" />
        <Badge value={7} tone="positive" />
      </div>
      <div class="sc__row">
        <Tag tone="positive" dot>running</Tag>
        <Tag tone="caution" dot>paused</Tag>
        <Tag tone="negative" dot>failed</Tag>
        <Tag tone="info">standalone</Tag>
        <Tag tone="brand">v8.4.0</Tag>
      </div>
      <div class="sc__row">
        <Chip tone="accent">order-processing</Chip>
        <Chip tone="success" closable>completed</Chip>
        <Chip tone="warning" closable>delayed</Chip>
        <Chip tone="danger" closable>failed</Chip>
        <Loader size="sm" variant="brand" />
        <Loader variant="brand" />
      </div>
    </div>
  </section>

  <!-- FEEDBACK -->
  <section class="sc__sec">
    <div class="sc__head"><h5>Feedback</h5><span class="sc__count">Alert · Progress · Accordion · Toaster</span></div>
    <div class="sc__panel sc__grid2">
      <div class="sc__stack">
        <Alert tone="success" title="Queue resumed">order-processing is now consuming jobs.</Alert>
        <Alert tone="warning" title="High failure rate">6,628 jobs failed in the last hour.</Alert>
        <Alert tone="danger" title="Worker disconnected" dismissible>bulk-flows-workers lost its connection.</Alert>
        <div class="sc__row">
          <Button size="sm" variant="secondary" onclick={() => toast.success("Job retried")}>Toast success</Button>
          <Button size="sm" variant="secondary" onclick={() => toast.error("Connection lost")}>Toast error</Button>
        </div>
      </div>
      <div class="sc__stack">
        <div class="sc__stack" style="gap:14px;">
          <Progress value={88} variant="positive" />
          <Progress value={64} variant="brand" />
          <Progress value={32} variant="caution" />
          <Progress indeterminate variant="info" />
        </div>
        <Accordion items={accItems} open={["a"]} />
      </div>
    </div>
  </section>

  <!-- NAVIGATION -->
  <section class="sc__sec">
    <div class="sc__head"><h5>Navigation</h5><span class="sc__count">Tabs · Breadcrumb · Pagination</span></div>
    <div class="sc__panel sc__stack">
      <Breadcrumb items={[{label:"Connections",href:"#"},{label:"ACME Corp",href:"#"},{label:"Localhost",href:"#"},{label:"order-processing"}]} />
      <div class="sc__row">
        <Tabs bind:value={tab} tabs={[{label:"Metrics",value:"metrics"},{label:"Jobs",value:"jobs"},{label:"Schedulers",value:"schedulers"},{label:"Workers",value:"workers"}]} />
      </div>
      <div class="sc__row">
        <Tabs variant="pills" value="metrics" tabs={[{label:"1 min",value:"metrics"},{label:"5 min",value:"5"},{label:"15 min",value:"15"},{label:"1 hour",value:"60"}]} />
      </div>
      <Pagination bind:page pageCount={24} siblings={1} showFirstLast />
    </div>
  </section>

  <!-- DATA + OVERLAYS -->
  <section class="sc__sec">
    <div class="sc__head"><h5>Data &amp; overlays</h5><span class="sc__count">Table · Card · Tooltip</span></div>
    <div class="sc__panel sc__grid2">
      <Table columns={tableColumns} rows={tableRows} striped />
      <Card title="Localhost" subtitle="Redis 8.4.0 · standalone" variant="elevated">
        Connected as admin. 16 of 10,000 clients in use, 57.34 MB resident.
        {#snippet footer()}
          <Tooltip text="Opens in a new panel">
            <Button size="sm" variant="ghost">Details</Button>
          </Tooltip>
          <Button size="sm">Manage</Button>
        {/snippet}
      </Card>
    </div>
  </section>

  <Toaster />
</div>

<style>
  .sc {
    max-width: 1080px;
    margin: 0 auto;
    padding: 40px 32px 96px;
    font-family: var(--font-primary);
    color: rgb(var(--fg-primary));
  }
  .sc__intro { margin-bottom: 40px; }
  .sc__eyebrow {
    margin: 0 0 8px;
    font: 500 12px/1 var(--font-secondary);
    letter-spacing: 0.14em;
    text-transform: uppercase;
    color: rgb(var(--fg-brand));
  }
  .sc__title { margin: 0 0 12px; font-size: 36px; line-height: 1.1; }
  .sc__lead { margin: 0; max-width: 60ch; color: rgb(var(--fg-secondary)); font-size: 15px; }
  .sc__lead code { font-size: 13px; }

  .sc__sec { margin-top: 36px; }
  .sc__head {
    display: flex; align-items: baseline; gap: 12px;
    padding-bottom: 12px; margin-bottom: 18px;
    border-bottom: 1px solid rgb(var(--border-secondary));
  }
  .sc__head h5 { font-size: 16px; }
  .sc__count {
    font: 400 12px/1.4 var(--font-secondary);
    color: rgb(var(--fg-tertiary));
  }
  .sc__panel {
    background: rgb(var(--bg-secondary));
    border: 1px solid rgb(var(--border-secondary));
    border-radius: var(--radius-16);
    padding: 24px;
    display: flex;
    flex-direction: column;
    gap: 20px;
  }
  .sc__row { display: flex; flex-wrap: wrap; align-items: center; gap: 14px; }
  .sc__stack { display: flex; flex-direction: column; gap: 18px; }
  .sc__grid2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 28px;
    align-items: start;
  }
  @media (max-width: 820px) { .sc__grid2 { grid-template-columns: 1fr; } }
</style>
