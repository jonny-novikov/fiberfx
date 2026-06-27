<script>
  /**
   * AuthLayout — branded split-screen shell for authentication pages.
   * Left: EchoMQ brand panel (hidden on narrow widths). Right: form column.
   * Fills its parent container (height: 100%), so it works framed or full-page.
   *
   * @typedef {Object} AuthLayoutProps
   * @property {string}  [eyebrow]   Small label above the heading.
   * @property {string}  [heading]   Form heading.
   * @property {string}  [subheading] Supporting line under the heading.
   * @property {import('svelte').Snippet} [children]  Form body.
   * @property {import('svelte').Snippet} [footer]    Footer row under the card.
   * @property {import('svelte').Snippet} [aside]     Overrides the brand-panel body.
   */
  let { eyebrow = "", heading = "", subheading = "", children, footer, aside } = $props();

  const features = [
    "Real-time queue & job telemetry",
    "Batches, groups and processor controls",
    "Role-based access for your whole team",
  ];
</script>

<div class="ax">
  <!-- Brand panel -->
  <aside class="ax__brand">
    <div class="ax__brandtop">
      <span class="ax__logo">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="currentColor"><path d="M13 2L4 14h6l-1 8 9-12h-6z"></path></svg>
      </span>
      <span class="ax__wordmark">EchoMQ</span>
      <span class="ax__chip">Bus</span>
    </div>

    {#if aside}
      {@render aside()}
    {:else}
      <div class="ax__brandmid">
        <h2 class="ax__brandh">The control plane for your message bus.</h2>
        <ul class="ax__feat">
          {#each features as f (f)}
            <li><span class="ax__check" aria-hidden="true">✓</span>{f}</li>
          {/each}
        </ul>
      </div>
    {/if}

    <div class="ax__brandfoot">
      <div class="ax__statline">
        <span class="ax__dot"></span> All systems operational
      </div>
      <span class="ax__ver">v8.4.0</span>
    </div>

    <span class="ax__glow ax__glow--1" aria-hidden="true"></span>
    <span class="ax__glow ax__glow--2" aria-hidden="true"></span>
  </aside>

  <!-- Form column -->
  <main class="ax__main">
    <div class="ax__form">
      {#if eyebrow}<p class="ax__eyebrow">{eyebrow}</p>{/if}
      {#if heading}<h1 class="ax__h">{heading}</h1>{/if}
      {#if subheading}<p class="ax__sub">{subheading}</p>{/if}
      <div class="ax__body">{@render children?.()}</div>
      {#if footer}<div class="ax__foot">{@render footer()}</div>{/if}
    </div>
  </main>
</div>

<style>
  .ax {
    display: grid;
    grid-template-columns: 1.05fr 1fr;
    height: 100%;
    min-height: 600px;
    background: rgb(var(--bg-primary));
    color: rgb(var(--fg-primary));
    font-family: var(--font-primary);
  }

  /* ---- brand panel ---- */
  .ax__brand {
    position: relative;
    overflow: hidden;
    display: flex;
    flex-direction: column;
    padding: 40px;
    background:
      radial-gradient(120% 80% at 0% 0%, rgb(var(--iris-9) / 0.22), transparent 60%),
      linear-gradient(160deg, rgb(var(--bg-secondary)), rgb(var(--bg-tertiary)));
    border-inline-end: 1px solid rgb(var(--border-secondary));
  }
  .ax__brandtop { display: flex; align-items: center; gap: 10px; position: relative; z-index: 2; }
  .ax__logo { display: inline-flex; color: rgb(var(--iris-9)); }
  .ax__wordmark { font: 700 18px/1 var(--font-primary); letter-spacing: -0.01em; }
  .ax__chip {
    font: 600 10px/1 var(--font-secondary); letter-spacing: 0.1em; text-transform: uppercase;
    color: rgb(var(--fg-on-brand)); background: rgb(var(--iris-9)); padding: 4px 6px; border-radius: 5px;
  }

  .ax__brandmid { margin-top: auto; margin-bottom: auto; position: relative; z-index: 2; }
  .ax__brandh {
    margin: 0 0 28px; max-width: 14ch;
    font: 400 40px/1.08 var(--font-display); letter-spacing: -0.01em;
    color: rgb(var(--fg-primary));
  }
  .ax__feat { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 14px; }
  .ax__feat li { display: flex; align-items: center; gap: 12px; font: 500 14px/1.4 var(--font-primary); color: rgb(var(--fg-secondary)); }
  .ax__check {
    width: 22px; height: 22px; flex-shrink: 0; border-radius: 50%;
    display: inline-flex; align-items: center; justify-content: center;
    background: rgb(var(--bg-brand-subtle)); color: rgb(var(--fg-brand));
    font: 700 11px/1 var(--font-secondary);
  }

  .ax__brandfoot {
    position: relative; z-index: 2;
    display: flex; align-items: center; justify-content: space-between;
    padding-top: 24px; border-top: 1px solid rgb(var(--border-secondary));
  }
  .ax__statline { display: inline-flex; align-items: center; gap: 8px; font: 500 12px/1 var(--font-primary); color: rgb(var(--fg-secondary)); }
  .ax__dot { width: 8px; height: 8px; border-radius: 50%; background: rgb(var(--green-9)); box-shadow: 0 0 0 3px rgb(var(--green-9) / 0.2); }
  .ax__ver { font: 500 12px/1 var(--font-secondary); color: rgb(var(--fg-tertiary)); }

  .ax__glow { position: absolute; border-radius: 50%; filter: blur(60px); opacity: 0.5; pointer-events: none; z-index: 1; }
  .ax__glow--1 { width: 320px; height: 320px; background: rgb(var(--iris-9) / 0.4); top: -80px; right: -60px; }
  .ax__glow--2 { width: 260px; height: 260px; background: rgb(var(--indigo-9) / 0.3); bottom: -60px; left: 30px; }

  /* ---- form column ---- */
  .ax__main { display: flex; align-items: center; justify-content: center; padding: 40px; overflow-y: auto; }
  .ax__form { width: 100%; max-width: 400px; }
  .ax__eyebrow {
    margin: 0 0 10px; font: 600 12px/1 var(--font-secondary);
    letter-spacing: 0.14em; text-transform: uppercase; color: rgb(var(--fg-brand));
  }
  .ax__h { margin: 0 0 8px; font: 700 28px/1.1 var(--font-primary); letter-spacing: -0.02em; }
  .ax__sub { margin: 0 0 28px; font: 400 15px/1.5 var(--font-primary); color: rgb(var(--fg-secondary)); }
  .ax__body { display: flex; flex-direction: column; gap: 16px; }
  .ax__body :global(.mx-in),
  .ax__body :global(.mx-sl),
  .ax__body :global(.mx-ta),
  .ax__body :global(.mx-sr) { max-width: none; width: 100%; }
  .ax__body :global(.mx-auth__row) { justify-content: space-between; width: 100%; }
  .ax__body :global(.mx-auth__cell) { flex: 1; }
  .ax__foot { margin-top: 28px; }

  @media (max-width: 880px) {
    .ax { grid-template-columns: 1fr; }
    .ax__brand { display: none; }
  }
</style>
