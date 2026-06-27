<script>
  /**
   * Catalogue — Mercury design-system explorer.
   * Left: searchable navigation. Right: live variants, a props table and an
   * HTML / Svelte code panel for the selected component or screen.
   *
   * All previews are real compiled Mercury components (runtime-compiled Svelte).
   */
  import { SECTIONS, BY_ID } from "./catalogue-data.js";

  // Forms & inputs
  import Button from "./mercury/Button.svelte";
  import Input from "./mercury/Input.svelte";
  import Textarea from "./mercury/Textarea.svelte";
  import Select from "./mercury/Select.svelte";
  import Combobox from "./mercury/Combobox.svelte";
  import Search from "./mercury/Search.svelte";
  import Checkbox from "./mercury/Checkbox.svelte";
  import Radio from "./mercury/Radio.svelte";
  import Switch from "./mercury/Switch.svelte";
  import Segmented from "./mercury/Segmented.svelte";
  import Slider from "./mercury/Slider.svelte";
  import DatePicker from "./mercury/DatePicker.svelte";
  import AuthCode from "./mercury/AuthCode.svelte";
  import Form from "./mercury/Form.svelte";
  // Display
  import Avatar from "./mercury/Avatar.svelte";
  import Badge from "./mercury/Badge.svelte";
  import Card from "./mercury/Card.svelte";
  import Chip from "./mercury/Chip.svelte";
  import Tag from "./mercury/Tag.svelte";
  import Loader from "./mercury/Loader.svelte";
  // Feedback
  import Alert from "./mercury/Alert.svelte";
  import Progress from "./mercury/Progress.svelte";
  import Accordion from "./mercury/Accordion.svelte";
  import Toaster from "./mercury/Toaster.svelte";
  import { toast } from "./mercury/toast.svelte.js";
  // Navigation
  import Tabs from "./mercury/Tabs.svelte";
  import Breadcrumb from "./mercury/Breadcrumb.svelte";
  import Pagination from "./mercury/Pagination.svelte";
  import Menu from "./mercury/Menu.svelte";
  // Overlays
  import Modal from "./mercury/Modal.svelte";
  import Dialog from "./mercury/Dialog.svelte";
  import Drawer from "./mercury/Drawer.svelte";
  import Popover from "./mercury/Popover.svelte";
  import Tooltip from "./mercury/Tooltip.svelte";
  import AlertDialog from "./mercury/AlertDialog.svelte";
  // Data
  import Table from "./mercury/Table.svelte";
  // Patterns
  import SignInForm from "./mercury/SignInForm.svelte";
  import Carousel from "./mercury/Carousel.svelte";
  // Screens
  import LoginScreen from "./screens/LoginScreen.svelte";
  import RegisterScreen from "./screens/RegisterScreen.svelte";
  import ForgotPasswordScreen from "./screens/ForgotPasswordScreen.svelte";
  import ResetPasswordScreen from "./screens/ResetPasswordScreen.svelte";
  import VerifyEmailScreen from "./screens/VerifyEmailScreen.svelte";

  let { theme = "dark" } = $props();

  /* ---------- navigation ---------- */
  let selected = $state("button");
  let query = $state("");

  const filteredSections = $derived.by(() => {
    const q = query.trim().toLowerCase();
    if (!q) return SECTIONS;
    return SECTIONS
      .map((s) => ({ ...s, items: s.items.filter((it) => it.name.toLowerCase().includes(q) || it.id.includes(q)) }))
      .filter((s) => s.items.length);
  });

  const doc = $derived(BY_ID[selected]);

  /* ---------- code panel ---------- */
  let codeLang = $state("svelte");
  let copied = $state(false);

  function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  }
  // Single-pass highlighter over escaped source — never re-scans inserted markup.
  function highlight(src) {
    const esc = escapeHtml(src ?? "");
    return esc.replace(
      /(&lt;\/?)([A-Za-z][\w-]*)|("[^"]*"|'[^']*')|(\{[^{}]*\})|\b([A-Za-z_][\w-]*)(?==)/g,
      (m, tOpen, tName, str, expr, attr) => {
        if (tName) return tOpen + '<span class="tk-tag">' + tName + "</span>";
        if (str) return '<span class="tk-str">' + str + "</span>";
        if (expr) return '<span class="tk-expr">' + expr + "</span>";
        if (attr) return '<span class="tk-attr">' + attr + "</span>";
        return m;
      },
    );
  }
  const highlighted = $derived(highlight(codeLang === "html" ? doc?.html : doc?.svelte));

  async function copyCode() {
    try {
      await navigator.clipboard.writeText((codeLang === "html" ? doc?.html : doc?.svelte) ?? "");
      copied = true;
      setTimeout(() => (copied = false), 1400);
    } catch (_) {}
  }

  function pick(id) { selected = id; codeLang = "svelte"; }

  /* ---------- live preview state ---------- */
  let swA = $state(true), swB = $state(false);
  let cbA = $state(true), cbB = $state(false);
  let radioVal = $state("active");
  let segVal = $state("5m");
  let sliderVal = $state(64);
  let tabVal = $state("metrics");
  let pillVal = $state("1m");
  let pageVal = $state(3);
  let inputVal = $state(""), pwVal = $state(""), taVal = $state("");
  let selVal = $state("standalone");
  let comboVal = $state("order-processing");
  let dateVal = $state(null);
  let codeVal = $state("");
  let searchVal = $state("");

  let modalOpen = $state(false), dialogOpen = $state(false), drawerOpen = $state(false), adlgOpen = $state(false);

  let chips = $state(["order-processing", "bulk-flows", "cdn-upload"]);
  let alertShown = $state(true);

  const queueOpts = [
    { label: "order-processing", value: "order-processing" },
    { label: "bulk-flows", value: "bulk-flows" },
    { label: "cdn-upload", value: "cdn-upload" },
    { label: "campaign-runner", value: "campaign-runner" },
  ];
  const tableCols = [
    { key: "queue", label: "Queue" },
    { key: "active", label: "Active", align: "right" },
    { key: "status", label: "Status" },
  ];
  const tableRows = [
    { id: 1, queue: "order-processing", active: 7, status: "running" },
    { id: 2, queue: "bulk-flows", active: 31, status: "running" },
    { id: 3, queue: "cdn-upload", active: 1, status: "paused" },
  ];
  const accItems = [
    { id: "a", title: "What is a Job Group?", content: "A logical grouping of jobs that share a parent and complete together." },
    { id: "b", title: "How are batches retried?", content: "Failed jobs retry with exponential backoff up to the configured attempts." },
  ];
  const menuItems = [
    { kind: "heading", label: "Queue" },
    { label: "Pause", icon: "⏸", onselect: () => toast("Queue paused") },
    { label: "Duplicate", icon: "⧉", shortcut: "⌘D" },
    { kind: "divider" },
    { label: "Delete", icon: "🗑", destructive: true, onselect: () => toast.error("Queue deleted") },
  ];

  /* ---------- foundations data ---------- */
  const steps = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  const scales = [
    { name: "Iris · brand", v: "--iris-" },
    { name: "Slate · neutral", v: "--slate-" },
    { name: "Indigo · active", v: "--indigo-" },
  ];
  const statusSwatches = [
    { name: "Brand", v: "--iris-9" },
    { name: "Active", v: "--indigo-9" },
    { name: "Positive", v: "--green-9" },
    { name: "Negative", v: "--red-9" },
    { name: "Caution", v: "--orange-9" },
    { name: "Discovery", v: "--plum-9" },
  ];
  const surfaces = [
    { name: "bg-primary", v: "--bg-primary" },
    { name: "bg-secondary", v: "--bg-secondary" },
    { name: "bg-tertiary", v: "--bg-tertiary" },
    { name: "bg-elevated", v: "--bg-elevated" },
    { name: "bg-inverse", v: "--bg-inverse" },
  ];
  const typeScale = [
    { label: "Display", cls: "ty-display", note: "DM Serif Display · 48px" },
    { label: "Heading 300", cls: "ty-h3", note: "DM Mono · 36px / 700" },
    { label: "Heading 100", cls: "ty-h5", note: "DM Sans · 18px / 700" },
    { label: "Body 400", cls: "ty-b4", note: "DM Sans · 16px / 400" },
    { label: "Body 300", cls: "ty-b3", note: "DM Sans · 14px / 400" },
    { label: "Mono 200", cls: "ty-mono", note: "DM Mono · 12px" },
  ];
  const radii = [
    { name: "4", v: "4px" }, { name: "8", v: "8px" }, { name: "12", v: "12px" },
    { name: "16", v: "16px" }, { name: "24", v: "24px" }, { name: "full", v: "9999px" },
  ];
  const shadows = ["--shadow-100", "--shadow-200", "--shadow-300", "--shadow-400", "--shadow-500"];

  const noop = () => {};
</script>

<div class="cat">
  <!-- ============ NAV ============ -->
  <aside class="cat__nav">
    <div class="cat__navhead">
      <div class="cat__brand">
        <span class="cat__logo"><svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M13 2L4 14h6l-1 8 9-12h-6z"/></svg></span>
        <div>
          <div class="cat__brandname">Mercury</div>
          <div class="cat__brandsub">Design System</div>
        </div>
      </div>
      <Search bind:value={query} placeholder="Search components" />
    </div>

    <nav class="cat__sections">
      {#each filteredSections as section (section.id)}
        <div class="cat__group">
          <div class="cat__grouplabel">{section.label}</div>
          {#each section.items as item (item.id)}
            <button class="cat__link" class:is-active={selected === item.id} onclick={() => pick(item.id)}>
              {item.name}
              {#if item.kind === "screen"}<span class="cat__pill">screen</span>{/if}
            </button>
          {/each}
        </div>
      {:else}
        <div class="cat__empty">No matches for "{query}".</div>
      {/each}
    </nav>
  </aside>

  <!-- ============ MAIN ============ -->
  <main class="cat__main">
    {#if doc}
      <header class="cat__doc">
        <div class="cat__eyebrow">{doc.section}</div>
        <h1 class="cat__title">{doc.name}</h1>
        <p class="cat__blurb">{doc.blurb}</p>
      </header>

      <!-- ---------- PREVIEW ---------- -->
      <section class="cat__block">
        <div class="cat__blockhead"><h2>Preview</h2></div>
        <div class="cat__stage" class:is-screen={doc.kind === "screen"} class:is-foundation={doc.kind === "foundation"}>

          {#if selected === "colors"}
            <div class="fnd">
              {#each scales as sc (sc.name)}
                <div class="fnd__scalerow">
                  <span class="fnd__scalename">{sc.name}</span>
                  <div class="fnd__scale">
                    {#each steps as n (n)}
                      <div class="fnd__step" style="background:rgb(var({sc.v}{n}));" title="{sc.v}{n}"><span>{n}</span></div>
                    {/each}
                  </div>
                </div>
              {/each}
              <div class="fnd__sub">Solid status</div>
              <div class="fnd__swatches">
                {#each statusSwatches as s (s.name)}
                  <div class="fnd__sw"><span class="fnd__chip" style="background:rgb(var({s.v}));"></span><b>{s.name}</b><code>{s.v}</code></div>
                {/each}
              </div>
              <div class="fnd__sub">Semantic surfaces</div>
              <div class="fnd__swatches">
                {#each surfaces as s (s.name)}
                  <div class="fnd__sw"><span class="fnd__chip fnd__chip--bordered" style="background:rgb(var({s.v}));"></span><b>{s.name}</b></div>
                {/each}
              </div>
            </div>

          {:else if selected === "typography"}
            <div class="fnd fnd--type">
              {#each typeScale as t (t.label)}
                <div class="fnd__typerow">
                  <span class={"fnd__sample " + t.cls}>Queues, jobs &amp; batches</span>
                  <span class="fnd__typenote">{t.note}</span>
                </div>
              {/each}
            </div>

          {:else if selected === "elevation"}
            <div class="fnd">
              <div class="fnd__sub">Radius</div>
              <div class="fnd__radii">
                {#each radii as r (r.name)}
                  <div class="fnd__radcol"><div class="fnd__rad" style="border-radius:{r.v};"></div><code>{r.name}</code></div>
                {/each}
              </div>
              <div class="fnd__sub">Elevation</div>
              <div class="fnd__shadows">
                {#each shadows as sh (sh)}
                  <div class="fnd__shadow" style="box-shadow:var({sh});"><code>{sh.replace('--shadow-','')}</code></div>
                {/each}
              </div>
            </div>

          {:else if selected === "button"}
            <div class="pv">
              <div class="pv__row">
                <Button>Primary</Button>
                <Button variant="secondary">Secondary</Button>
                <Button variant="ghost">Ghost</Button>
                <Button variant="danger">Danger</Button>
              </div>
              <div class="pv__row">
                <Button size="sm">Small</Button>
                <Button size="md">Medium</Button>
                <Button size="lg">Large</Button>
              </div>
              <div class="pv__row">
                <Button icon="＋">With icon</Button>
                <Button loading>Saving…</Button>
                <Button disabled>Disabled</Button>
              </div>
            </div>

          {:else if selected === "input"}
            <div class="pv pv--narrow">
              <Input label="Connection name" placeholder="localhost:6379" bind:value={inputVal} hint="Host and port of the broker." />
              <Input label="Email" type="email" placeholder="you@company.com" />
              <Input label="Password" type="password" error="Authentication failed." />
            </div>

          {:else if selected === "textarea"}
            <div class="pv pv--narrow">
              <Textarea label="Failure note" rows={4} maxlength={240} bind:value={taVal} hint="Shown to on-call." />
            </div>

          {:else if selected === "select"}
            <div class="pv pv--narrow">
              <Select label="Mode" bind:value={selVal} options={[{label:"Standalone",value:"standalone"},{label:"Cluster",value:"cluster"},{label:"Sentinel",value:"sentinel"}]} />
            </div>

          {:else if selected === "combobox"}
            <div class="pv pv--narrow">
              <Combobox label="Queue" bind:value={comboVal} options={queueOpts} />
            </div>

          {:else if selected === "search"}
            <div class="pv pv--narrow">
              <Search bind:value={searchVal} placeholder="Search queues" onsearch={(v) => toast("Searching " + v)} />
            </div>

          {:else if selected === "checkbox"}
            <div class="pv">
              <div class="pv__row">
                <Checkbox bind:checked={cbA} label="Group child jobs" />
                <Checkbox bind:checked={cbB} label="Include retries" />
                <Checkbox indeterminate label="Some selected" />
                <Checkbox disabled label="Disabled" />
              </div>
            </div>

          {:else if selected === "radio"}
            <div class="pv">
              <div class="pv__row">
                <Radio bind:group={radioVal} value="waiting" label="Waiting" />
                <Radio bind:group={radioVal} value="active" label="Active" />
                <Radio bind:group={radioVal} value="failed" label="Failed" />
                <Radio bind:group={radioVal} value="x" disabled label="Disabled" />
              </div>
            </div>

          {:else if selected === "switch"}
            <div class="pv">
              <div class="pv__row">
                <Switch bind:checked={swA} label="Auto-refresh" />
                <Switch bind:checked={swB} label={swB ? "Running" : "Paused"} />
                <Switch disabled label="Disabled" />
              </div>
            </div>

          {:else if selected === "segmented"}
            <div class="pv">
              <Segmented bind:value={segVal} segments={[{label:"1 min",value:"1m"},{label:"5 min",value:"5m"},{label:"15 min",value:"15m"},{label:"1 hour",value:"1h"}]} />
              <Segmented size="sm" value="active" segments={[{label:"Waiting",value:"waiting"},{label:"Active",value:"active"},{label:"Failed",value:"failed"}]} />
            </div>

          {:else if selected === "slider"}
            <div class="pv pv--narrow">
              <Slider label="Concurrency" max={128} unit=" workers" bind:value={sliderVal} />
              <Slider label="Sample rate" size="sm" value={40} unit="%" />
            </div>

          {:else if selected === "datepicker"}
            <div class="pv"><DatePicker label="Run after" bind:value={dateVal} /></div>

          {:else if selected === "authcode"}
            <div class="pv"><AuthCode bind:value={codeVal} length={6} oncomplete={() => toast.success("Code complete")} /></div>

          {:else if selected === "form"}
            <div class="pv pv--wide">
              <Form title="New connection" description="Connect a broker to start consuming jobs." layout="grid" columns={2} onsubmit={() => toast.success("Saved")}>
                <Input label="Host" placeholder="localhost" />
                <Input label="Port" type="number" placeholder="6379" />
                {#snippet actions()}
                  <Button variant="secondary">Cancel</Button>
                  <Button type="submit">Save</Button>
                {/snippet}
              </Form>
            </div>

          {:else if selected === "avatar"}
            <div class="pv">
              <div class="pv__row">
                <Avatar initials="AC" size="xs" />
                <Avatar initials="MQ" size="sm" status="online" />
                <Avatar initials="BU" status="busy" />
                <Avatar initials="OP" size="lg" status="online" />
                <Avatar initials="CR" size="xl" status="offline" />
              </div>
            </div>

          {:else if selected === "badge"}
            <div class="pv">
              <div class="pv__row">
                <Badge value={43} tone="brand" />
                <Badge value={7} tone="positive" />
                <Badge value={6628} max={999} tone="negative" />
                <Badge value={12} tone="caution" />
                <Badge dot tone="negative" />
              </div>
            </div>

          {:else if selected === "card"}
            <div class="pv pv--wide">
              <div class="pv__cards">
                <Card title="Outlined" subtitle="Default surface">Connected as admin.</Card>
                <Card title="Elevated" subtitle="Raised surface" variant="elevated">16 of 10,000 clients.</Card>
                <Card title="Interactive" subtitle="Hover me" hoverable interactive onclick={() => toast("Card clicked")}>Click or focus.</Card>
              </div>
            </div>

          {:else if selected === "chip"}
            <div class="pv">
              <div class="pv__row">
                {#each chips as c (c)}
                  <Chip tone="accent" closable onclose={() => (chips = chips.filter((x) => x !== c))}>{c}</Chip>
                {/each}
                {#if !chips.length}<Button size="sm" variant="ghost" onclick={() => (chips = ["order-processing","bulk-flows","cdn-upload"])}>Reset chips</Button>{/if}
              </div>
              <div class="pv__row">
                <Chip tone="neutral">neutral</Chip>
                <Chip tone="success">completed</Chip>
                <Chip tone="warning">delayed</Chip>
                <Chip tone="danger">failed</Chip>
              </div>
            </div>

          {:else if selected === "tag"}
            <div class="pv">
              <div class="pv__row">
                <Tag tone="positive" dot>completed</Tag>
                <Tag tone="info" dot>active</Tag>
                <Tag tone="caution" dot>delayed</Tag>
                <Tag tone="negative" dot>failed</Tag>
                <Tag tone="neutral" dot>waiting</Tag>
                <Tag tone="brand">v8.4.0</Tag>
                <Tag tone="discovery">prioritized</Tag>
              </div>
            </div>

          {:else if selected === "loader"}
            <div class="pv">
              <div class="pv__row" style="align-items:center;">
                <Loader size="xs" /><Loader size="sm" variant="brand" /><Loader variant="brand" /><Loader size="lg" variant="positive" /><Loader size="xl" variant="info" />
              </div>
            </div>

          {:else if selected === "alert"}
            <div class="pv pv--wide">
              <Alert tone="info" title="Heads up">A new EchoMQ version is available.</Alert>
              <Alert tone="success" title="Queue resumed">order-processing is consuming jobs.</Alert>
              <Alert tone="warning" title="High failure rate">6,628 jobs failed in the last hour.</Alert>
              {#if alertShown}
                <Alert tone="danger" title="Worker disconnected" dismissible bind:visible={alertShown}>bulk-flows-workers lost its connection.</Alert>
              {:else}
                <Button size="sm" variant="ghost" onclick={() => (alertShown = true)}>Restore dismissed alert</Button>
              {/if}
            </div>

          {:else if selected === "progress"}
            <div class="pv pv--wide" style="gap:18px;">
              <Progress value={88} variant="positive" />
              <Progress value={64} variant="brand" />
              <Progress value={32} variant="caution" />
              <Progress indeterminate variant="info" />
            </div>

          {:else if selected === "accordion"}
            <div class="pv pv--wide"><Accordion open={["a"]} items={accItems} /></div>

          {:else if selected === "toast"}
            <div class="pv">
              <div class="pv__row">
                <Button variant="secondary" onclick={() => toast.success("Job retried")}>Success</Button>
                <Button variant="secondary" onclick={() => toast.info("Sync started")}>Info</Button>
                <Button variant="secondary" onclick={() => toast.warning("Approaching limit")}>Warning</Button>
                <Button variant="secondary" onclick={() => toast.error({ title: "Connection lost", description: "Retrying in 5s…" })}>Error</Button>
              </div>
            </div>

          {:else if selected === "tabs"}
            <div class="pv pv--wide">
              <Tabs bind:value={tabVal} tabs={[{label:"Metrics",value:"metrics"},{label:"Jobs",value:"jobs"},{label:"Workers",value:"workers"},{label:"Schedulers",value:"sched",disabled:true}]} />
              <Tabs variant="pills" bind:value={pillVal} tabs={[{label:"1 min",value:"1m"},{label:"5 min",value:"5m"},{label:"1 hour",value:"1h"}]} />
            </div>

          {:else if selected === "breadcrumb"}
            <div class="pv">
              <Breadcrumb items={[{label:"Connections",href:"#"},{label:"ACME Corp",href:"#"},{label:"Localhost",href:"#"},{label:"order-processing"}]} />
            </div>

          {:else if selected === "pagination"}
            <div class="pv"><Pagination bind:page={pageVal} pageCount={304} siblings={1} showFirstLast /></div>

          {:else if selected === "menu"}
            <div class="pv">
              <Menu items={menuItems}>
                {#snippet trigger({ toggle })}
                  <Button variant="secondary" onclick={toggle}>Queue actions ▾</Button>
                {/snippet}
              </Menu>
            </div>

          {:else if selected === "modal"}
            <div class="pv">
              <Button onclick={() => (modalOpen = true)}>Open modal</Button>
              <Modal bind:open={modalOpen} title="Delete queue?" size="sm">
                This permanently removes order-processing and its 2,431 jobs.
                {#snippet footer()}
                  <Button variant="secondary" onclick={() => (modalOpen = false)}>Cancel</Button>
                  <Button variant="danger" onclick={() => { modalOpen = false; toast.error("Queue deleted"); }}>Delete</Button>
                {/snippet}
              </Modal>
            </div>

          {:else if selected === "dialog"}
            <div class="pv">
              <Button onclick={() => (dialogOpen = true)}>Open dialog</Button>
              <Dialog bind:open={dialogOpen} title="Connection added" description="Localhost is now reachable and consuming jobs.">
                You can manage processors from the sidebar at any time.
                {#snippet footer()}<Button onclick={() => (dialogOpen = false)}>Got it</Button>{/snippet}
              </Dialog>
            </div>

          {:else if selected === "drawer"}
            <div class="pv">
              <Button onclick={() => (drawerOpen = true)}>Inspect job</Button>
              <Drawer bind:open={drawerOpen} side="end" size="md" title="Job #48207">
                <p>charge.capture · failed after 3 attempts.</p>
                <p>Full payload, attempts and logs would render here.</p>
                {#snippet footer()}<Button variant="secondary" onclick={() => (drawerOpen = false)}>Close</Button><Button>Retry job</Button>{/snippet}
              </Drawer>
            </div>

          {:else if selected === "popover"}
            <div class="pv">
              <Popover width={260}>
                {#snippet trigger({ toggle })}<Button variant="secondary" onclick={toggle}>Filters</Button>{/snippet}
                <div class="pop-demo">
                  <strong>Filter jobs</strong>
                  <Checkbox label="Waiting" checked /><Checkbox label="Active" checked /><Checkbox label="Failed" />
                </div>
              </Popover>
            </div>

          {:else if selected === "tooltip"}
            <div class="pv">
              <div class="pv__row">
                <Tooltip text="Duplicate queue"><Button variant="secondary">Hover me</Button></Tooltip>
                <Tooltip text="Delete — cannot be undone" placement="bottom"><Button variant="ghost">Bottom</Button></Tooltip>
                <Tooltip text="Refresh stats" placement="end"><Button variant="ghost">End</Button></Tooltip>
              </div>
            </div>

          {:else if selected === "alertdialog"}
            <div class="pv">
              <Button variant="danger" onclick={() => (adlgOpen = true)}>Flush queue</Button>
              <AlertDialog bind:open={adlgOpen} title="Flush queue?" description="This permanently removes all 2,431 waiting jobs. This cannot be undone."
                actionLabel="Flush" actionVariant="danger"
                onaction={() => toast.error("Queue flushed")} oncancel={noop} />
            </div>

          {:else if selected === "table"}
            <div class="pv pv--wide">
              <Table columns={tableCols} rows={tableRows} striped>
                {#snippet cell(row, col)}
                  {#if col.key === "status"}
                    <Tag tone={row.status === "running" ? "positive" : "caution"} dot>{row.status}</Tag>
                  {:else}
                    {row[col.key]}
                  {/if}
                {/snippet}
              </Table>
            </div>

          {:else if selected === "signinform"}
            <div class="pv pv--center"><SignInForm heading="Sign in to EchoMQ" onsubmit={() => toast.success("Signed in")} onforgot={noop} oncreate={noop} onssoclick={noop} /></div>

          {:else if selected === "carousel"}
            <div class="pv pv--wide">
              <Carousel>
                <div class="car-demo car-demo--1">Queues at a glance</div>
                <div class="car-demo car-demo--2">Job throughput</div>
                <div class="car-demo car-demo--3">Processor health</div>
              </Carousel>
            </div>

          {:else if selected === "screen-login"}
            <div class="screen"><LoginScreen onsubmit={() => toast.success("Signed in")} onforgot={() => pick("screen-forgot")} onregister={() => pick("screen-register")} onsso={() => toast("Starting SSO…")} /></div>
          {:else if selected === "screen-register"}
            <div class="screen"><RegisterScreen onsubmit={() => toast.success("Account created")} onlogin={() => pick("screen-login")} /></div>
          {:else if selected === "screen-forgot"}
            <div class="screen"><ForgotPasswordScreen onsubmit={() => toast("Reset link sent")} onback={() => pick("screen-login")} /></div>
          {:else if selected === "screen-reset"}
            <div class="screen"><ResetPasswordScreen onsubmit={() => toast.success("Password updated")} onback={() => pick("screen-login")} /></div>
          {:else if selected === "screen-verify"}
            <div class="screen"><VerifyEmailScreen email="ada@acme.com" onsubmit={() => toast.success("Verified")} onresend={() => toast("Code resent")} onback={() => pick("screen-login")} /></div>
          {/if}
        </div>
      </section>

      <!-- ---------- PROPS ---------- -->
      {#if doc.props && doc.props.length}
        <section class="cat__block">
          <div class="cat__blockhead"><h2>Props</h2></div>
          <div class="pt-wrap">
            <table class="pt">
              <thead><tr><th>Prop</th><th>Type</th><th>Default</th><th>Description</th></tr></thead>
              <tbody>
                {#each doc.props as [n, t, d, desc] (n)}
                  <tr>
                    <td><code class="pt__name">{n}</code></td>
                    <td><code class="pt__type">{t}</code></td>
                    <td><code class="pt__def">{d}</code></td>
                    <td class="pt__desc">{desc}</td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        </section>
      {/if}

      <!-- ---------- CODE ---------- -->
      {#if doc.svelte}
        <section class="cat__block">
          <div class="cat__blockhead">
            <h2>Example</h2>
            <div class="cat__codectl">
              <Segmented size="sm" bind:value={codeLang} segments={[{label:"Svelte",value:"svelte"},{label:"HTML",value:"html"}]} />
              <button class="cat__copy" onclick={copyCode}>{copied ? "Copied ✓" : "Copy"}</button>
            </div>
          </div>
          <div class="code">
            <div class="code__lang">{codeLang === "html" ? "rendered html" : "App.svelte"}</div>
            <pre class="code__pre"><code>{@html highlighted}</code></pre>
          </div>
        </section>
      {/if}
    {/if}
  </main>

  <Toaster position="bottom-end" />
</div>

<style>
  .cat {
    display: grid;
    grid-template-columns: 264px 1fr;
    height: 100%;
    background: rgb(var(--bg-primary));
    color: rgb(var(--fg-primary));
    font-family: var(--font-primary);
    overflow: hidden;
  }
  .cat :global(*) { box-sizing: border-box; }

  /* ---- nav ---- */
  .cat__nav {
    display: flex; flex-direction: column;
    background: rgb(var(--bg-secondary));
    border-inline-end: 1px solid rgb(var(--border-secondary));
    overflow: hidden;
  }
  .cat__navhead { padding: 18px 16px 14px; border-bottom: 1px solid rgb(var(--border-secondary)); display: flex; flex-direction: column; gap: 14px; }
  .cat__brand { display: flex; align-items: center; gap: 10px; }
  .cat__logo {
    width: 34px; height: 34px; flex-shrink: 0; border-radius: var(--radius-8);
    display: inline-flex; align-items: center; justify-content: center;
    background: rgb(var(--bg-brand-subtle)); color: rgb(var(--fg-brand));
  }
  .cat__brandname { font: 700 15px/1.1 var(--font-primary); letter-spacing: -0.01em; }
  .cat__brandsub { font: 500 11px/1 var(--font-secondary); letter-spacing: 0.1em; text-transform: uppercase; color: rgb(var(--fg-tertiary)); margin-top: 3px; }

  .cat__sections { flex: 1; overflow-y: auto; padding: 12px 10px 32px; }
  .cat__group { margin-bottom: 14px; }
  .cat__grouplabel {
    padding: 6px 10px; font: 700 10px/1 var(--font-primary);
    letter-spacing: 0.12em; text-transform: uppercase; color: rgb(var(--fg-tertiary));
  }
  .cat__link {
    display: flex; align-items: center; gap: 8px; width: 100%;
    padding: 8px 10px; border: 0; border-radius: var(--radius-8);
    background: transparent; color: rgb(var(--fg-secondary));
    font: 500 13.5px/1.2 var(--font-primary); text-align: start; cursor: pointer;
    transition: background 120ms ease, color 120ms ease;
  }
  .cat__link:hover { background: rgb(var(--bg-hover)); color: rgb(var(--fg-primary)); }
  .cat__link.is-active { background: rgb(var(--bg-selected)); color: rgb(var(--fg-primary)); font-weight: 600; }
  .cat__pill {
    margin-inline-start: auto; font: 600 9px/1 var(--font-secondary);
    letter-spacing: 0.08em; text-transform: uppercase;
    color: rgb(var(--fg-brand)); background: rgb(var(--bg-brand-subtle));
    padding: 3px 5px; border-radius: 4px;
  }
  .cat__empty { padding: 16px 12px; font: 400 13px/1.5 var(--font-primary); color: rgb(var(--fg-tertiary)); }

  /* ---- main ---- */
  .cat__main { overflow-y: auto; padding: 36px 40px 80px; }
  .cat__doc { max-width: 900px; margin-bottom: 28px; }
  .cat__eyebrow { font: 600 12px/1 var(--font-secondary); letter-spacing: 0.12em; text-transform: uppercase; color: rgb(var(--fg-brand)); }
  .cat__title { margin: 12px 0 10px; font: 700 34px/1.05 var(--font-primary); letter-spacing: -0.02em; }
  .cat__blurb { margin: 0; max-width: 70ch; font: 400 16px/1.6 var(--font-primary); color: rgb(var(--fg-secondary)); }

  .cat__block { margin-top: 30px; max-width: 1000px; }
  .cat__blockhead { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-bottom: 14px; }
  .cat__blockhead h2 { margin: 0; font: 700 12px/1 var(--font-primary); letter-spacing: 0.1em; text-transform: uppercase; color: rgb(var(--fg-tertiary)); }
  .cat__codectl { display: flex; align-items: center; gap: 10px; }
  .cat__copy {
    height: 30px; padding: 0 12px; border-radius: var(--radius-6);
    border: 1px solid rgb(var(--border-primary)); background: rgb(var(--bg-primary));
    color: rgb(var(--fg-secondary)); font: 600 12px/1 var(--font-primary); cursor: pointer;
    transition: background 120ms ease, color 120ms ease;
  }
  .cat__copy:hover { background: rgb(var(--bg-hover)); color: rgb(var(--fg-primary)); }

  /* ---- stage ---- */
  .cat__stage {
    border: 1px solid rgb(var(--border-secondary)); border-radius: var(--radius-16);
    background:
      linear-gradient(rgb(var(--bg-secondary)), rgb(var(--bg-secondary))) padding-box,
      repeating-conic-gradient(rgb(var(--bg-tertiary) / 0) 0% 25%, rgb(var(--bg-tertiary) / 0.4) 0% 50%) 0 / 22px 22px;
    padding: 32px;
    overflow: visible;
  }
  .cat__stage.is-foundation { padding: 28px; }
  .cat__stage.is-screen { padding: 0; overflow: hidden; }

  .pv { display: flex; flex-direction: column; gap: 18px; align-items: flex-start; }
  .pv--narrow { max-width: 340px; width: 100%; }
  .pv--wide { width: 100%; }
  .pv--center { width: 100%; align-items: center; }
  .pv__row { display: flex; flex-wrap: wrap; align-items: center; gap: 14px; }
  .pv__cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; width: 100%; }
  .pv--wide :global(.mx-in), .pv--wide :global(.mx-ta) { max-width: none; }

  .screen { height: 640px; width: 100%; border-radius: var(--radius-16); overflow: hidden; }

  .pop-demo { display: flex; flex-direction: column; gap: 10px; }
  .pop-demo strong { font: 600 13px/1 var(--font-primary); }
  .car-demo {
    height: 200px; display: flex; align-items: center; justify-content: center;
    font: 700 26px/1 var(--font-display); color: rgb(var(--fg-on-brand));
  }
  .car-demo--1 { background: linear-gradient(135deg, rgb(var(--iris-9)), rgb(var(--indigo-9))); }
  .car-demo--2 { background: linear-gradient(135deg, rgb(var(--indigo-9)), rgb(var(--plum-9))); }
  .car-demo--3 { background: linear-gradient(135deg, rgb(var(--green-9)), rgb(var(--indigo-9))); }

  /* ---- foundations ---- */
  .fnd { display: flex; flex-direction: column; gap: 18px; width: 100%; }
  .fnd__scalerow { display: flex; flex-direction: column; gap: 8px; }
  .fnd__scalename { font: 600 12px/1 var(--font-primary); color: rgb(var(--fg-secondary)); }
  .fnd__scale { display: grid; grid-template-columns: repeat(12, 1fr); gap: 4px; }
  .fnd__step {
    height: 46px; border-radius: var(--radius-6); display: flex; align-items: flex-end; justify-content: center;
    padding-bottom: 4px; box-shadow: inset 0 0 0 1px rgb(var(--border-secondary) / 0.5);
  }
  .fnd__step span { font: 600 9px/1 var(--font-secondary); color: rgb(var(--slate-1)); mix-blend-mode: difference; opacity: 0.9; }
  .fnd__sub { font: 700 10px/1 var(--font-primary); letter-spacing: 0.1em; text-transform: uppercase; color: rgb(var(--fg-tertiary)); margin-top: 6px; }
  .fnd__swatches { display: grid; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); gap: 12px; }
  .fnd__sw { display: flex; align-items: center; gap: 10px; font: 500 13px/1.2 var(--font-primary); }
  .fnd__sw code { font: 500 11px/1 var(--font-secondary); color: rgb(var(--fg-tertiary)); }
  .fnd__chip { width: 30px; height: 30px; border-radius: var(--radius-8); flex-shrink: 0; }
  .fnd__chip--bordered { box-shadow: inset 0 0 0 1px rgb(var(--border-primary)); }

  .fnd--type { gap: 4px; }
  .fnd__typerow { display: flex; align-items: baseline; justify-content: space-between; gap: 24px; padding: 14px 0; border-bottom: 1px solid rgb(var(--border-secondary)); }
  .fnd__sample { color: rgb(var(--fg-primary)); }
  .ty-display { font: 400 44px/1 var(--font-display); letter-spacing: -0.01em; }
  .ty-h3 { font: 700 32px/1 var(--font-secondary); letter-spacing: -0.01em; }
  .ty-h5 { font: 700 18px/1 var(--font-primary); }
  .ty-b4 { font: 400 16px/1 var(--font-primary); }
  .ty-b3 { font: 400 14px/1 var(--font-primary); }
  .ty-mono { font: 500 13px/1 var(--font-secondary); }
  .fnd__typenote { font: 500 11px/1 var(--font-secondary); color: rgb(var(--fg-tertiary)); white-space: nowrap; }

  .fnd__radii { display: flex; flex-wrap: wrap; gap: 18px; }
  .fnd__radcol { display: flex; flex-direction: column; align-items: center; gap: 8px; }
  .fnd__rad { width: 72px; height: 72px; background: rgb(var(--bg-brand-subtle)); box-shadow: inset 0 0 0 1.5px rgb(var(--border-brand)); }
  .fnd__radcol code, .fnd__shadow code { font: 600 11px/1 var(--font-secondary); color: rgb(var(--fg-tertiary)); }
  .fnd__shadows { display: flex; flex-wrap: wrap; gap: 24px; padding: 6px 0 10px; }
  .fnd__shadow {
    width: 110px; height: 80px; border-radius: var(--radius-12);
    background: rgb(var(--bg-elevated)); display: flex; align-items: flex-end; justify-content: center; padding-bottom: 8px;
  }

  /* ---- props table ---- */
  .pt-wrap { border: 1px solid rgb(var(--border-primary)); border-radius: var(--radius-12); overflow: hidden; }
  .pt { width: 100%; border-collapse: collapse; font-family: var(--font-primary); }
  .pt thead th {
    text-align: start; padding: 11px 14px; background: rgb(var(--bg-tertiary));
    font: 600 11px/1 var(--font-primary); letter-spacing: 0.06em; text-transform: uppercase;
    color: rgb(var(--fg-secondary)); border-bottom: 1px solid rgb(var(--border-primary));
  }
  .pt td { padding: 11px 14px; border-bottom: 1px solid rgb(var(--border-secondary)); vertical-align: top; }
  .pt tbody tr:last-child td { border-bottom: 0; }
  .pt__name { font: 600 12.5px/1.4 var(--font-secondary); color: rgb(var(--fg-primary)); background: rgb(var(--bg-brand-subtle)); padding: 2px 6px; border-radius: 4px; }
  .pt__type { font: 500 12px/1.5 var(--font-secondary); color: rgb(var(--fg-brand)); }
  .pt__def { font: 500 12px/1.4 var(--font-secondary); color: rgb(var(--fg-tertiary)); }
  .pt__desc { font: 400 13px/1.5 var(--font-primary); color: rgb(var(--fg-secondary)); }
  .pt td:nth-child(1) { white-space: nowrap; }

  /* ---- code ---- */
  .code { position: relative; border-radius: var(--radius-12); overflow: hidden; border: 1px solid rgb(var(--border-primary)); background: rgb(var(--bg-tertiary)); }
  .code__lang {
    position: absolute; top: 10px; inset-inline-end: 14px;
    font: 600 10px/1 var(--font-secondary); letter-spacing: 0.08em; text-transform: uppercase;
    color: rgb(var(--fg-tertiary)); pointer-events: none;
  }
  .code__pre { margin: 0; padding: 18px 20px; overflow-x: auto; }
  .code__pre code { font: 500 13px/1.7 var(--font-secondary); color: rgb(var(--fg-primary)); white-space: pre; }
  .code :global(.tk-tag) { color: rgb(var(--fg-brand)); }
  .code :global(.tk-attr) { color: rgb(var(--fg-info)); }
  .code :global(.tk-str) { color: rgb(var(--fg-positive)); }
  .code :global(.tk-expr) { color: rgb(var(--fg-caution)); }

  @media (max-width: 1080px) {
    .cat { grid-template-columns: 220px 1fr; }
    .pv__cards { grid-template-columns: 1fr; }
  }
</style>
