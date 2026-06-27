/*
  catalogue-data.js — Mercury component registry for the catalogue explorer.

  Pure data (no Svelte). Drives the left navigation, the props tables and the
  HTML / Svelte code panels. The *live* variant previews live in Catalogue.svelte
  (real component markup), keyed by the same ids used here.

  Each item: { id, name, blurb, props: [[name, type, default, desc], ...],
               svelte: "<source>", html: "<rendered output>" }
  Foundation items omit props/code and are rendered specially.
*/

const P = (name, type, def, desc) => [name, type, def, desc];

export const SECTIONS = [
  {
    id: "foundations",
    label: "Foundations",
    items: [
      { id: "colors", name: "Color", kind: "foundation",
        blurb: "Radix-style 12-step scales mapped to semantic tokens. Every token is a space-separated RGB triplet — consume with rgb(var(--token)) so alpha and theming compose cleanly." },
      { id: "typography", name: "Typography", kind: "foundation",
        blurb: "DM Sans for UI, DM Mono for numerals and code, DM Serif Display for editorial moments. A five-step body scale and a five-step heading scale." },
      { id: "elevation", name: "Radius & Elevation", kind: "foundation",
        blurb: "A 2→32px radius ramp and a six-level shadow set. Shadows are theme-aware: lighter and tighter in light mode, deeper in dark." },
    ],
  },

  {
    id: "forms",
    label: "Forms & Inputs",
    items: [
      { id: "button", name: "Button",
        blurb: "Primary action trigger. Four variants, three sizes, loading and icon affordances.",
        props: [
          P("variant", "primary | secondary | ghost | danger", "primary", "Visual tone."),
          P("size", "sm | md | lg", "md", "Height and type scale."),
          P("disabled", "boolean", "false", "Blocks interaction and fades."),
          P("loading", "boolean", "false", "Swaps the label for a spinner."),
          P("fullWidth", "boolean", "false", "Stretch to container width."),
          P("icon", "string | null", "null", "Optional leading glyph."),
          P("type", "button | submit | reset", "button", "Native button type."),
          P("onclick", "(e) => void", "—", "Click handler."),
        ],
        svelte: `<Button>Primary</Button>
<Button variant="secondary">Secondary</Button>
<Button variant="ghost">Ghost</Button>
<Button variant="danger">Danger</Button>
<Button loading>Saving…</Button>
<Button size="lg" icon="＋" fullWidth>New connection</Button>`,
        html: `<button class="mx-btn mx-btn--primary mx-btn--md">
  <span class="mx-btn__lbl">Primary</span>
</button>` },

      { id: "input", name: "Input",
        blurb: "Text entry with label, hint and error states. Branches internally to support text, email, password, tel, url and number.",
        props: [
          P("value", "string", '""', "Two-way bound ($bindable)."),
          P("type", "text | email | password | tel | url | number", "text", "Input type."),
          P("label", "string", '""', "Visible label."),
          P("placeholder", "string", '""', "Placeholder text."),
          P("hint", "string", '""', "Helper text below the field."),
          P("error", "string", '""', "Error text; overrides hint."),
          P("disabled", "boolean", "false", "Disable the field."),
          P("required", "boolean", "false", "Mark as required."),
          P("leading / trailing", "Snippet", "—", "Icon slots inside the field."),
        ],
        svelte: `<Input label="Connection name" placeholder="localhost:6379" bind:value={name} />
<Input label="Email" type="email" hint="We never share this." bind:value={email} />
<Input label="Password" type="password" error="Authentication failed." />`,
        html: `<label class="mx-in">
  <span class="mx-in__lbl">Connection name</span>
  <span class="mx-in__field">
    <input class="mx-in__inp" type="text" placeholder="localhost:6379">
  </span>
</label>` },

      { id: "textarea", name: "Textarea",
        blurb: "Multi-line input with optional character counter and resize handle.",
        props: [
          P("value", "string", '""', "Two-way bound ($bindable)."),
          P("label", "string", '""', "Visible label."),
          P("rows", "number", "4", "Visible rows."),
          P("maxlength", "number", "—", "When set, shows a counter."),
          P("resize", "boolean", "false", "Allow user vertical resize."),
          P("hint / error", "string", '""', "Helper / error text."),
        ],
        svelte: `<Textarea
  label="Failure note"
  rows={4}
  maxlength={240}
  bind:value={note}
  hint="Shown to on-call when a job dead-letters." />`,
        html: `<label class="mx-ta">
  <span class="mx-ta__lbl">Failure note</span>
  <div class="mx-ta__field"><textarea class="mx-ta__inp" rows="4"></textarea></div>
  <div class="mx-ta__foot"><span class="mx-ta__count">0/240</span></div>
</label>` },

      { id: "select", name: "Select",
        blurb: "Native-backed select with Mercury styling. Reach for Combobox when options need filtering.",
        props: [
          P("value", "any", '""', "Two-way bound ($bindable)."),
          P("options", "{label, value, disabled?}[]", "[]", "Option list."),
          P("label", "string", '""', "Visible label."),
          P("placeholder", "string", '""', "Empty-state first option."),
          P("hint / error", "string", '""', "Helper / error text."),
          P("disabled / required", "boolean", "false", "Field state."),
        ],
        svelte: `<Select
  label="Mode"
  bind:value={mode}
  options={[
    { label: "Standalone", value: "standalone" },
    { label: "Cluster", value: "cluster" },
    { label: "Sentinel", value: "sentinel" },
  ]} />`,
        html: `<label class="mx-sl">
  <span class="mx-sl__lbl">Mode</span>
  <div class="mx-sl__field">
    <select class="mx-sl__sel">…</select>
    <span class="mx-sl__chev"></span>
  </div>
</label>` },

      { id: "combobox", name: "Combobox",
        blurb: "Searchable single-select. Filters as you type with full keyboard navigation (↑ ↓ Enter Esc).",
        props: [
          P("value", "any", "null", "Selected value ($bindable)."),
          P("open", "boolean", "false", "Dropdown state ($bindable)."),
          P("options", "{label, value, disabled?}[]", "[]", "Option list."),
          P("placeholder", "string", "Select…", "Trigger placeholder."),
          P("emptyText", "string", "No matches", "Empty filter message."),
          P("label / hint / error", "string", '""', "Field text."),
        ],
        svelte: `<Combobox
  label="Queue"
  placeholder="Pick a queue…"
  bind:value={queue}
  options={queues.map((q) => ({ label: q, value: q }))} />`,
        html: `<div class="mx-cb">
  <button class="mx-cb__trigger">
    <span class="mx-cb__val is-placeholder">Pick a queue…</span>
    <span class="mx-cb__chev"></span>
  </button>
</div>` },

      { id: "search", name: "Search",
        blurb: "Search-specialised input with a leading icon, clear button and Enter-to-search.",
        props: [
          P("value", "string", '""', "Two-way bound ($bindable)."),
          P("placeholder", "string", "Search", "Placeholder text."),
          P("disabled", "boolean", "false", "Disable the field."),
          P("onsearch", "(value) => void", "—", "Fired on Enter."),
        ],
        svelte: `<Search bind:value={query} placeholder="Search queues" onsearch={run} />`,
        html: `<label class="mx-sr">
  <span class="mx-sr__icon"><svg>…</svg></span>
  <input class="mx-sr__inp" type="search" placeholder="Search queues">
</label>` },

      { id: "checkbox", name: "Checkbox",
        blurb: "Bindable boolean with an indeterminate visual state.",
        props: [
          P("checked", "boolean", "false", "Two-way bound ($bindable)."),
          P("indeterminate", "boolean", "false", "Mixed state."),
          P("label", "string", '""', "Visible label."),
          P("disabled", "boolean", "false", "Disable the control."),
        ],
        svelte: `<Checkbox bind:checked={groupChildren} label="Group child jobs" />
<Checkbox indeterminate label="Some selected" />`,
        html: `<label class="mx-cb">
  <input type="checkbox">
  <span class="mx-cb__box"><svg class="mx-cb__tick">…</svg></span>
  <span class="mx-cb__lbl">Group child jobs</span>
</label>` },

      { id: "radio", name: "Radio",
        blurb: "Single-select control. Share bind:group across radios in one group.",
        props: [
          P("group", "any", "—", "Selected value ($bindable)."),
          P("value", "any", "—", "This radio's value."),
          P("label", "string", '""', "Visible label."),
          P("disabled", "boolean", "false", "Disable the control."),
        ],
        svelte: `<Radio bind:group={status} value="waiting" label="Waiting" />
<Radio bind:group={status} value="active" label="Active" />
<Radio bind:group={status} value="failed" label="Failed" />`,
        html: `<label class="mx-rd">
  <input type="radio">
  <span class="mx-rd__ring"><span class="mx-rd__dot"></span></span>
  <span class="mx-rd__lbl">Active</span>
</label>` },

      { id: "switch", name: "Switch",
        blurb: "On/off toggle, semantically a checkbox with switch role.",
        props: [
          P("checked", "boolean", "false", "Two-way bound ($bindable)."),
          P("label", "string", '""', "Visible label."),
          P("disabled", "boolean", "false", "Disable the control."),
        ],
        svelte: `<Switch bind:checked={autoRefresh} label="Auto-refresh" />
<Switch bind:checked={paused} label={paused ? "Paused" : "Running"} />`,
        html: `<label class="mx-sw">
  <input type="checkbox" role="switch">
  <span class="mx-sw__track"><span class="mx-sw__thumb"></span></span>
  <span class="mx-sw__lbl">Auto-refresh</span>
</label>` },

      { id: "segmented", name: "Segmented",
        blurb: "Compact single-choice control. Same data shape as Tabs, enclosed group styling.",
        props: [
          P("segments", "{label, value, disabled?}[]", "[]", "Choices."),
          P("value", "any", "—", "Two-way bound ($bindable)."),
          P("size", "sm | md | lg", "md", "Control size."),
          P("fullWidth", "boolean", "false", "Stretch to fill."),
        ],
        svelte: `<Segmented bind:value={range} segments={[
  { label: "1 min", value: "1m" },
  { label: "5 min", value: "5m" },
  { label: "1 hour", value: "1h" },
]} />`,
        html: `<div class="mx-seg mx-seg--md" role="radiogroup">
  <button class="mx-seg__seg is-active">1 min</button>
  <button class="mx-seg__seg">5 min</button>
  <button class="mx-seg__seg">1 hour</button>
</div>` },

      { id: "slider", name: "Slider",
        blurb: "Value-range input with optional label and numeric readout.",
        props: [
          P("value", "number", "0", "Two-way bound ($bindable)."),
          P("min / max / step", "number", "0 / 100 / 1", "Range bounds."),
          P("label", "string", '""', "Visible label."),
          P("unit", "string", '""', "Readout suffix, e.g. ' workers'."),
          P("size", "sm | md", "md", "Track size."),
        ],
        svelte: `<Slider label="Concurrency" max={128} unit=" workers" bind:value={concurrency} />`,
        html: `<div class="mx-sd mx-sd--md">
  <div class="mx-sd__head"><span class="mx-sd__lbl">Concurrency</span><span class="mx-sd__val">64 workers</span></div>
  <div class="mx-sd__track"><input class="mx-sd__inp" type="range"></div>
</div>` },

      { id: "datepicker", name: "DatePicker",
        blurb: "Trigger plus calendar popover for single-date selection, with min/max bounds.",
        props: [
          P("value", "Date | string | null", "null", "Selected date ($bindable)."),
          P("label", "string", '""', "Visible label."),
          P("min / max", "Date", "—", "Selectable range."),
          P("locale", "string", "en-US", "Intl locale for formatting."),
          P("error", "string", '""', "Error text."),
        ],
        svelte: `<DatePicker label="Run after" bind:value={runAfter} min={new Date()} />`,
        html: `<div class="mx-dp">
  <label class="mx-dp__lbl">Run after</label>
  <button class="mx-dp__trigger">
    <span class="mx-dp__val is-placeholder">Select date</span>
    <span class="mx-dp__ico">📅</span>
  </button>
</div>` },

      { id: "authcode", name: "AuthCode",
        blurb: "One-time-password input. Auto-advances, supports paste, backspace and arrow keys.",
        props: [
          P("value", "string", '""', "Full code string ($bindable)."),
          P("length", "number", "6", "Number of slots."),
          P("allow", "numeric | alphanumeric", "numeric", "Input sanitisation."),
          P("error", "string", '""', "Error text."),
          P("oncomplete", "(code) => void", "—", "Fired when all slots fill."),
        ],
        svelte: `<AuthCode bind:value={code} length={6} oncomplete={verify} />`,
        html: `<div class="mx-auth">
  <div class="mx-auth__row">
    <input class="mx-auth__cell" maxlength="1"> …× 6
  </div>
</div>` },

      { id: "form", name: "Form",
        blurb: "Layout wrapper for form groups — consistent title, description and stacked or grid spacing.",
        props: [
          P("title / description", "string", '""', "Header text."),
          P("layout", "stack | grid", "stack", "Field arrangement."),
          P("columns", "number", "2", "Grid columns when layout='grid'."),
          P("gap", "number", "16", "Gap between fields (px)."),
          P("actions", "Snippet", "—", "Footer action row."),
        ],
        svelte: `<Form title="New connection" layout="grid" columns={2} onsubmit={save}>
  <Input label="Host" bind:value={host} />
  <Input label="Port" type="number" bind:value={port} />
  {#snippet actions()}
    <Button variant="secondary">Cancel</Button>
    <Button type="submit">Save</Button>
  {/snippet}
</Form>`,
        html: `<form class="mx-fm">
  <header class="mx-fm__head"><h3 class="mx-fm__h">New connection</h3></header>
  <div class="mx-fm__body mx-fm__body--grid">…</div>
  <footer class="mx-fm__foot">…</footer>
</form>` },
    ],
  },

  {
    id: "display",
    label: "Display",
    items: [
      { id: "avatar", name: "Avatar",
        blurb: "User or entity image with initials fallback and a presence dot.",
        props: [
          P("initials", "string", '""', "Fallback initials."),
          P("src", "string | null", "null", "Image URL; falls back to initials."),
          P("size", "xs | sm | md | lg | xl", "md", "Avatar size."),
          P("status", "online | offline | busy | null", "null", "Presence dot."),
        ],
        svelte: `<Avatar initials="AC" />
<Avatar initials="MQ" status="online" />
<Avatar initials="BU" size="lg" status="busy" />`,
        html: `<span class="mx-av mx-av--md" role="img" aria-label="AC">
  <span class="mx-av__txt">AC</span>
  <span class="mx-av__dot mx-av__dot--online"></span>
</span>` },

      { id: "badge", name: "Badge",
        blurb: "Numeric / notification indicator. Inline chip or attached to another element.",
        props: [
          P("value", "number | string | null", "null", "Count (clamped to max)."),
          P("max", "number", "99", "Overflow threshold → 'max+'."),
          P("dot", "boolean", "false", "Render a dot instead of a number."),
          P("tone", "brand | negative | positive | caution | neutral", "negative", "Color."),
          P("variant", "inline | attached", "inline", "Standalone or anchored."),
        ],
        svelte: `<Badge value={43} tone="brand" />
<Badge value={6628} max={999} tone="negative" />
<Badge value={7} tone="positive" />
<Badge dot tone="caution" />`,
        html: `<span class="mx-bdg mx-bdg--brand mx-bdg--md">43</span>` },

      { id: "card", name: "Card",
        blurb: "Surface with optional media, header, body and footer slots. Flat, outlined or elevated.",
        props: [
          P("title / subtitle", "string", '""', "Header text."),
          P("variant", "flat | outlined | elevated", "outlined", "Surface style."),
          P("hoverable", "boolean", "false", "Lift on hover."),
          P("interactive", "boolean", "false", "Focusable + clickable."),
          P("media / header / footer", "Snippet", "—", "Composable slots."),
        ],
        svelte: `<Card title="Localhost" subtitle="Redis 8.4.0 · standalone" variant="elevated">
  Connected as admin. 16 of 10,000 clients in use.
  {#snippet footer()}
    <Button size="sm" variant="ghost">Details</Button>
    <Button size="sm">Manage</Button>
  {/snippet}
</Card>`,
        html: `<article class="mx-card mx-card--elevated">
  <div class="mx-card__body">
    <div class="mx-card__head"><h3 class="mx-card__h">Localhost</h3><p class="mx-card__sub">Redis 8.4.0 · standalone</p></div>
    <div class="mx-card__content">…</div>
  </div>
  <footer class="mx-card__foot">…</footer>
</article>` },

      { id: "chip", name: "Chip",
        blurb: "Compact, optionally removable tag with a leading-slot affordance.",
        props: [
          P("tone", "neutral | accent | success | warning | danger", "neutral", "Color."),
          P("size", "sm | md", "md", "Chip size."),
          P("closable", "boolean", "false", "Show a remove button."),
          P("onclose", "(e) => void", "—", "Fired on remove."),
        ],
        svelte: `<Chip tone="accent">order-processing</Chip>
<Chip tone="success" closable onclose={remove}>completed</Chip>
<Chip tone="danger" closable>failed</Chip>`,
        html: `<span class="mx-chip mx-chip--accent mx-chip--md">order-processing</span>` },

      { id: "tag", name: "Tag",
        blurb: "Small status label with an optional leading dot. Squarer and tighter than Chip.",
        props: [
          P("tone", "neutral | brand | positive | negative | caution | info | discovery", "neutral", "Color."),
          P("size", "sm | md", "md", "Tag size."),
          P("dot", "boolean", "false", "Prefix with a status dot."),
        ],
        svelte: `<Tag tone="positive" dot>completed</Tag>
<Tag tone="caution" dot>delayed</Tag>
<Tag tone="negative" dot>failed</Tag>
<Tag tone="brand">v8.4.0</Tag>`,
        html: `<span class="mx-tag mx-tag--positive mx-tag--md">
  <span class="mx-tag__dot"></span>completed
</span>` },

      { id: "loader", name: "Loader",
        blurb: "Indeterminate spinner. Five sizes; color inherits or picks a semantic variant.",
        props: [
          P("size", "xs | sm | md | lg | xl", "md", "Spinner size."),
          P("variant", "current | brand | positive | negative | caution | info | inverse", "current", "Color."),
          P("label", "string", "Loading", "Accessible label."),
        ],
        svelte: `<Loader />
<Loader size="sm" variant="brand" />
<Loader size="lg" variant="positive" />`,
        html: `<span class="mx-ld mx-ld--md mx-ld--brand" role="status" aria-label="Loading">
  <span class="mx-ld__ring"></span>
</span>` },
    ],
  },

  {
    id: "feedback",
    label: "Feedback",
    items: [
      { id: "alert", name: "Alert",
        blurb: "Inline contextual feedback. Tones map to status tokens; optionally dismissible.",
        props: [
          P("tone", "info | success | warning | danger", "info", "Status color."),
          P("title", "string", '""', "Optional title above the message."),
          P("dismissible", "boolean", "false", "Show a close button."),
          P("visible", "boolean", "true", "Two-way visibility ($bindable)."),
          P("actions", "Snippet", "—", "Footer action row."),
        ],
        svelte: `<Alert tone="success" title="Queue resumed">order-processing is consuming jobs.</Alert>
<Alert tone="warning" title="High failure rate">6,628 jobs failed in the last hour.</Alert>
<Alert tone="danger" title="Worker disconnected" dismissible>bulk-flows-workers lost connection.</Alert>`,
        html: `<div class="mx-alt mx-alt--success" role="status">
  <span class="mx-alt__icon">✓</span>
  <div class="mx-alt__body"><h4 class="mx-alt__h">Queue resumed</h4><div class="mx-alt__msg">…</div></div>
</div>` },

      { id: "progress", name: "Progress",
        blurb: "Linear progress indicator. Determinate or indeterminate sweep, five status colors.",
        props: [
          P("value", "number", "0", "Current value."),
          P("max", "number", "100", "Maximum value."),
          P("indeterminate", "boolean", "false", "Animated sweep, ignores value."),
          P("variant", "brand | positive | negative | caution | info", "brand", "Bar color."),
          P("size", "sm | md | lg", "md", "Track height."),
        ],
        svelte: `<Progress value={88} variant="positive" />
<Progress value={64} variant="brand" />
<Progress value={32} variant="caution" />
<Progress indeterminate variant="info" />`,
        html: `<div class="mx-pr mx-pr--md mx-pr--positive" role="progressbar" aria-valuenow="88">
  <div class="mx-pr__track"><div class="mx-pr__bar" style="width:88%"></div></div>
</div>` },

      { id: "accordion", name: "Accordion",
        blurb: "Expandable panel list. Open one at a time or many; bordered or plain.",
        props: [
          P("items", "{id, title, content, disabled?}[]", "[]", "Panels."),
          P("open", "string[]", "[]", "Open ids ($bindable)."),
          P("mode", "single | multiple", "single", "Open one or many."),
          P("variant", "bordered | plain", "bordered", "Container style."),
        ],
        svelte: `<Accordion open={["a"]} items={[
  { id: "a", title: "What is a Job Group?", content: "A logical grouping of jobs that share a parent." },
  { id: "b", title: "How are batches retried?", content: "Failed jobs retry with exponential backoff." },
]} />`,
        html: `<div class="mx-ac mx-ac--bordered">
  <div class="mx-ac__item">
    <h3><button class="mx-ac__trigger is-active"><span class="mx-ac__title">What is a Job Group?</span><span class="mx-ac__chev"></span></button></h3>
    <div class="mx-ac__body">…</div>
  </div>
</div>` },

      { id: "toast", name: "Toast / Toaster",
        blurb: "Transient notifications. Mount <Toaster /> once near the root, then call toast(...) from anywhere.",
        props: [
          P("toast(input)", "string | ToastInput", "—", "Add a toast. .success/.info/.warning/.error helpers."),
          P("tone", "info | success | warning | danger", "info", "Status color."),
          P("duration", "number", "4000", "ms; 0 = sticky."),
          P("position (Toaster)", "top/bottom-start/center/end", "bottom-end", "Stack placement."),
          P("action", "{label, onclick}", "—", "Inline action button."),
        ],
        svelte: `import { toast } from "./mercury/toast.svelte.js";

toast.success("Job retried");
toast.error({ title: "Connection lost", description: "Retrying in 5s…" });

<Toaster position="bottom-end" />`,
        html: `<div class="mx-toaster mx-toaster--bottom-end">
  <div class="mx-toast mx-toast--success" role="status">
    <span class="mx-toast__ico">✓</span>
    <div class="mx-toast__body"><div class="mx-toast__title">Job retried</div></div>
  </div>
</div>` },
    ],
  },

  {
    id: "navigation",
    label: "Navigation",
    items: [
      { id: "tabs", name: "Tabs",
        blurb: "Horizontal tab list with underline or pill variants and full arrow-key navigation.",
        props: [
          P("tabs", "{label, value, disabled?}[]", "[]", "Tab list."),
          P("value", "any", "—", "Active value ($bindable)."),
          P("variant", "underline | pills", "underline", "Tab style."),
          P("onchange", "(value) => void", "—", "Fired on change."),
        ],
        svelte: `<Tabs bind:value={tab} tabs={[
  { label: "Metrics", value: "metrics" },
  { label: "Jobs", value: "jobs" },
  { label: "Workers", value: "workers" },
]} />`,
        html: `<div class="mx-tabs mx-tabs--underline" role="tablist">
  <button class="mx-tab is-active" role="tab" aria-selected="true">Metrics</button>
  <button class="mx-tab" role="tab">Jobs</button>
</div>` },

      { id: "breadcrumb", name: "Breadcrumb",
        blurb: "Location trail with smart middle-truncation past maxItems.",
        props: [
          P("items", "{label, href?, onclick?}[]", "[]", "Crumbs."),
          P("separator", "string", "/", "Divider glyph."),
          P("maxItems", "number", "0", "Truncate middle when exceeded."),
        ],
        svelte: `<Breadcrumb items={[
  { label: "Connections", href: "#" },
  { label: "ACME Corp", href: "#" },
  { label: "Localhost", href: "#" },
  { label: "order-processing" },
]} />`,
        html: `<nav class="mx-bc" aria-label="Breadcrumb">
  <ol class="mx-bc__list">
    <li class="mx-bc__item"><a class="mx-bc__lnk">Connections</a><span class="mx-bc__sep">/</span></li>
    <li class="mx-bc__item"><span class="mx-bc__cur" aria-current="page">order-processing</span></li>
  </ol>
</nav>` },

      { id: "pagination", name: "Pagination",
        blurb: "Page selector with smart truncation and optional first/last controls.",
        props: [
          P("page", "number", "1", "Current page ($bindable)."),
          P("pageCount", "number", "1", "Total pages."),
          P("siblings", "number", "1", "Pages shown each side of current."),
          P("showFirstLast", "boolean", "false", "Show « » controls."),
          P("size", "sm | md", "md", "Control size."),
        ],
        svelte: `<Pagination bind:page={page} pageCount={304} siblings={1} showFirstLast />`,
        html: `<nav class="mx-pg mx-pg--md" aria-label="Pagination">
  <button class="mx-pg__b">‹</button>
  <button class="mx-pg__b is-active" aria-current="page">3</button>
  <button class="mx-pg__b">4</button>
  <button class="mx-pg__b">›</button>
</nav>` },

      { id: "menu", name: "Menu",
        blurb: "Click-to-open dropdown with items, dividers, headings, icons and shortcuts. ESC + click-outside to close.",
        props: [
          P("items", "MenuItem[]", "[]", "label, kind, icon, shortcut, onselect, destructive…"),
          P("open", "boolean", "false", "Open state ($bindable)."),
          P("align", "start | end", "start", "Panel horizontal alignment."),
          P("side", "top | bottom", "bottom", "Panel side."),
          P("trigger", "Snippet", "—", "Custom trigger ({ toggle, open })."),
        ],
        svelte: `<Menu items={[
  { kind: "heading", label: "Queue" },
  { label: "Pause", icon: "⏸", onselect: pause },
  { label: "Duplicate", icon: "⧉", shortcut: "⌘D" },
  { kind: "divider" },
  { label: "Delete", icon: "🗑", destructive: true },
]}>
  {#snippet trigger({ toggle })}
    <Button variant="secondary" onclick={toggle}>Actions ▾</Button>
  {/snippet}
</Menu>`,
        html: `<div class="mx-menu">
  <button class="mx-menu__trig">Actions ▾</button>
  <div class="mx-menu__pop" role="menu">
    <button class="mx-menu__item" role="menuitem">…</button>
  </div>
</div>` },
    ],
  },

  {
    id: "overlays",
    label: "Overlays",
    items: [
      { id: "modal", name: "Modal",
        blurb: "Dialog built on the native <dialog> element — backdrop, ESC to close, native focus trap.",
        props: [
          P("open", "boolean", "false", "Two-way bound ($bindable)."),
          P("title", "string", '""', "Header title."),
          P("size", "sm | md | lg", "md", "Panel width."),
          P("closeOnBackdrop", "boolean", "true", "Click-outside closes."),
          P("footer", "Snippet", "—", "Footer action row."),
        ],
        svelte: `<Button onclick={() => (open = true)}>Open modal</Button>
<Modal bind:open={open} title="Delete queue?" size="sm">
  This removes order-processing and its 2,431 jobs.
  {#snippet footer()}
    <Button variant="secondary" onclick={() => (open = false)}>Cancel</Button>
    <Button variant="danger">Delete</Button>
  {/snippet}
</Modal>`,
        html: `<dialog class="mx-md mx-md--sm" open>
  <div class="mx-md__panel">
    <header class="mx-md__head"><h3 class="mx-md__h">Delete queue?</h3><button class="mx-md__x">×</button></header>
    <div class="mx-md__body">…</div>
    <footer class="mx-md__foot">…</footer>
  </div>
</dialog>` },

      { id: "dialog", name: "Dialog",
        blurb: "Thin Modal variant with a lead description paragraph above the body.",
        props: [
          P("open", "boolean", "false", "Two-way bound ($bindable)."),
          P("title", "string", '""', "Header title."),
          P("description", "string | null", "null", "Lead paragraph."),
          P("size", "sm | md | lg", "md", "Panel width."),
        ],
        svelte: `<Dialog bind:open={open} title="Connection added"
  description="Localhost is now reachable and consuming jobs.">
  You can manage processors from the sidebar.
</Dialog>`,
        html: `<dialog class="mx-md mx-md--md" open>
  <div class="mx-md__panel">
    <div class="mx-md__body"><p class="mx-dlg__desc">Localhost is now reachable…</p>…</div>
  </div>
</dialog>` },

      { id: "drawer", name: "Drawer",
        blurb: "Off-canvas panel on any edge, with slide-in animation and native focus trap.",
        props: [
          P("open", "boolean", "false", "Two-way bound ($bindable)."),
          P("side", "start | end | top | bottom", "end", "Edge to dock to."),
          P("size", "sm | md | lg", "md", "Cross-axis size."),
          P("title", "string", '""', "Header title."),
          P("maxWidth", "string | null", "null", "Width cap for start/end."),
        ],
        svelte: `<Button onclick={() => (open = true)}>Inspect job</Button>
<Drawer bind:open={open} side="end" size="md" title="Job #48207">
  Full payload, attempts and logs…
</Drawer>`,
        html: `<dialog class="mx-dr mx-dr--end mx-dr--md" open>
  <section class="mx-dr__panel">
    <header class="mx-dr__head"><h3 class="mx-dr__h">Job #48207</h3><button class="mx-dr__x">×</button></header>
    <div class="mx-dr__body">…</div>
  </section>
</dialog>` },

      { id: "popover", name: "Popover",
        blurb: "Click-to-open rich panel anchored to a trigger. Holds arbitrary content, unlike Tooltip.",
        props: [
          P("open", "boolean", "false", "Open state ($bindable)."),
          P("placement", "top | bottom | start | end", "bottom", "Panel side."),
          P("align", "start | center | end", "start", "Cross-axis alignment."),
          P("width", "number", "280", "Panel width (px)."),
          P("trigger", "Snippet", "—", "Anchor ({ toggle })."),
        ],
        svelte: `<Popover width={260}>
  {#snippet trigger({ toggle })}
    <Button variant="ghost" onclick={toggle}>Filters</Button>
  {/snippet}
  <div>Status, queue, age range…</div>
</Popover>`,
        html: `<span class="mx-pop mx-pop--bottom mx-pop--a-start">
  <button>Filters</button>
  <div class="mx-pop__panel" role="dialog">…</div>
</span>` },

      { id: "tooltip", name: "Tooltip",
        blurb: "Contextual helper text on hover/focus of a wrapped element.",
        props: [
          P("text", "string", "—", "Tooltip content."),
          P("placement", "top | bottom | start | end", "top", "Bubble side."),
          P("delay", "number", "250", "ms before showing."),
          P("disabled", "boolean", "false", "Suppress the tooltip."),
        ],
        svelte: `<Tooltip text="Duplicate queue">
  <Button variant="ghost" icon="⧉" />
</Tooltip>`,
        html: `<span class="mx-tt">
  <button>⧉</button>
  <span class="mx-tt__bubble mx-tt--top" role="tooltip">Duplicate queue</span>
</span>` },

      { id: "alertdialog", name: "AlertDialog",
        blurb: "Confirmation dialog with Cancel / Confirm actions. Any dismissal but Confirm reports oncancel.",
        props: [
          P("open", "boolean", "false", "Two-way bound ($bindable)."),
          P("title / description", "string", '""', "Body text."),
          P("actionLabel / cancelLabel", "string", "Confirm / Cancel", "Button labels."),
          P("actionVariant", "primary | secondary | ghost | danger", "primary", "Confirm button tone."),
          P("onaction / oncancel", "() => void", "—", "Outcome callbacks."),
        ],
        svelte: `<AlertDialog
  bind:open={open}
  title="Flush queue?"
  description="This permanently removes all 2,431 waiting jobs."
  actionLabel="Flush"
  actionVariant="danger"
  onaction={flush} />`,
        html: `<dialog class="mx-md mx-md--sm" open>
  <div class="mx-md__panel">
    <div class="mx-md__body"><p class="mx-adlg__desc">This permanently removes…</p></div>
    <footer class="mx-md__foot"><button class="mx-btn mx-btn--secondary">Cancel</button><button class="mx-btn mx-btn--danger">Flush</button></footer>
  </div>
</dialog>` },
    ],
  },

  {
    id: "data",
    label: "Data",
    items: [
      { id: "table", name: "Table",
        blurb: "Data table with header, optional striping/compact density, and a composable cell snippet.",
        props: [
          P("columns", "{key, label, align?, width?}[]", "[]", "Column defs."),
          P("rows", "Record<string, any>[]", "[]", "Row data."),
          P("striped", "boolean", "false", "Zebra rows."),
          P("compact", "boolean", "false", "Smaller row height."),
          P("cell", "Snippet<[row, col]>", "—", "Custom cell renderer."),
          P("empty", "Snippet", "—", "Empty-state body."),
        ],
        svelte: `<Table columns={cols} rows={rows} striped>
  {#snippet cell(row, col)}
    {#if col.key === "status"}
      <Tag tone={toneFor(row.status)} dot>{row.status}</Tag>
    {:else}
      {row[col.key]}
    {/if}
  {/snippet}
</Table>`,
        html: `<div class="mx-tbl-wrap">
  <table class="mx-tbl mx-tbl--striped">
    <thead><tr><th>Queue</th><th>Active</th><th>Status</th></tr></thead>
    <tbody><tr><td>order-processing</td><td>7</td><td>…</td></tr></tbody>
  </table>
</div>` },
    ],
  },

  {
    id: "patterns",
    label: "Patterns",
    items: [
      { id: "signinform", name: "SignInForm",
        blurb: "Canonical sign-in card composed from Mercury primitives — email, password, remember, SSO and links.",
        props: [
          P("heading", "string", "Sign in to Mercury", "Card title."),
          P("email / password", "string", '""', "Two-way bound ($bindable)."),
          P("remember", "boolean", "true", "Remember-me ($bindable)."),
          P("submitting", "boolean", "false", "Disables submit while true."),
          P("error", "string", '""', "Inline error above the fields."),
          P("onsubmit / onforgot / oncreate / onssoclick", "fn", "—", "Action callbacks."),
        ],
        svelte: `<SignInForm
  heading="Sign in to EchoMQ"
  bind:email={email}
  bind:password={password}
  onsubmit={(creds) => signIn(creds)}
  onforgot={goForgot}
  oncreate={goRegister} />`,
        html: `<form class="mx-sif">
  <div class="mx-card mx-card--elevated">…email, password, remember, SSO…</div>
</form>` },

      { id: "carousel", name: "Carousel",
        blurb: "Horizontal slide deck with arrow + dot controls, optional loop and autoplay.",
        props: [
          P("index", "number", "0", "Active slide ($bindable)."),
          P("loop", "boolean", "true", "Wrap past the ends."),
          P("autoplay", "number", "0", "ms between slides; 0 disables."),
          P("showArrows / showDots", "boolean", "true", "Control visibility."),
        ],
        svelte: `<Carousel autoplay={4000}>
  <div class="mx-car__slide">Slide one</div>
  <div class="mx-car__slide">Slide two</div>
  <div class="mx-car__slide">Slide three</div>
</Carousel>`,
        html: `<div class="mx-car" role="region" aria-roledescription="carousel">
  <div class="mx-car__track">…slides…</div>
  <button class="mx-car__arrow mx-car__arrow--prev">‹</button>
  <div class="mx-car__dots">…</div>
</div>` },
    ],
  },

  {
    id: "screens",
    label: "Screens",
    items: [
      { id: "screen-login", name: "Login", kind: "screen",
        blurb: "Sign in to the EchoMQ console — SSO, email + password, remember-me and a forgot-password link, on the branded split layout.",
        props: [
          P("onsubmit", "({email, password, remember}) => void", "—", "Credentials submitted."),
          P("onforgot / onregister / onsso", "() => void", "—", "Navigation callbacks."),
        ],
        svelte: `<LoginScreen
  onsubmit={signIn}
  onforgot={goForgot}
  onregister={goRegister}
  onsso={ssoStart} />`,
        html: `<div class="ax">
  <aside class="ax__brand">…EchoMQ brand panel…</aside>
  <main class="ax__main"><form class="lg">…SSO · email · password…</form></main>
</div>` },

      { id: "screen-register", name: "Register", kind: "screen",
        blurb: "Create an account — name, work email, organisation and a live password-strength meter with a terms gate.",
        props: [
          P("onsubmit", "(data) => void", "—", "Account details submitted."),
          P("onlogin", "() => void", "—", "Switch to sign-in."),
        ],
        svelte: `<RegisterScreen onsubmit={createAccount} onlogin={goLogin} />`,
        html: `<div class="ax">
  <aside class="ax__brand">…</aside>
  <main class="ax__main"><form class="rg">…name · email · org · password meter…</form></main>
</div>` },

      { id: "screen-forgot", name: "Forgot Password", kind: "screen",
        blurb: "Request a reset link, then a success confirmation state. Includes a back-to-sign-in affordance.",
        props: [
          P("onsubmit", "(email) => void", "—", "Reset requested."),
          P("onback", "() => void", "—", "Return to sign-in."),
        ],
        svelte: `<ForgotPasswordScreen onsubmit={sendReset} onback={goLogin} />`,
        html: `<div class="ax">
  <main class="ax__main"><form class="fp">…email · send reset link…</form></main>
</div>` },

      { id: "screen-reset", name: "Reset Password", kind: "screen",
        blurb: "Set a new password with live match validation and a requirements checklist.",
        props: [
          P("onsubmit", "(password) => void", "—", "New password submitted."),
          P("onback", "() => void", "—", "Return to sign-in."),
        ],
        svelte: `<ResetPasswordScreen onsubmit={updatePassword} onback={goLogin} />`,
        html: `<div class="ax">
  <main class="ax__main"><form class="rp">…new · confirm · rules…</form></main>
</div>` },

      { id: "screen-verify", name: "Verify Email", kind: "screen",
        blurb: "Six-digit OTP step with auto-submit, an error path (try 000000) and a resend cooldown.",
        props: [
          P("email", "string", "you@company.com", "Address the code was sent to."),
          P("onsubmit", "(code) => void", "—", "Verified code."),
          P("onresend / onback", "() => void", "—", "Resend / change account."),
        ],
        svelte: `<VerifyEmailScreen
  email="ada@acme.com"
  onsubmit={confirm}
  onresend={resend} />`,
        html: `<div class="ax">
  <main class="ax__main"><div class="vf"><div class="mx-auth">…6 cells…</div></div></main>
</div>` },
    ],
  },
];

// Flat lookup by id.
export const BY_ID = Object.fromEntries(
  SECTIONS.flatMap((s) => s.items.map((it) => [it.id, { ...it, section: s.label }])),
);
