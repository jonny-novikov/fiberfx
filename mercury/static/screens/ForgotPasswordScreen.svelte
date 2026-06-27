<script>
  /**
   * ForgotPasswordScreen — request a password-reset link. Shows a success
   * state once the request is "sent".
   *
   * @typedef {Object} ForgotPasswordScreenProps
   * @property {(email: string) => void} [onsubmit]
   * @property {() => void} [onback]
   */
  import AuthLayout from "./AuthLayout.svelte";
  import Input from "../mercury/Input.svelte";
  import Button from "../mercury/Button.svelte";

  let { onsubmit, onback } = $props();

  let email = $state("");
  let sent = $state(false);
  let submitting = $state(false);

  function submit(e) {
    e.preventDefault();
    if (!email) return;
    submitting = true;
    setTimeout(() => { submitting = false; sent = true; onsubmit?.(email); }, 700);
  }
</script>

<AuthLayout
  eyebrow="Account recovery"
  heading={sent ? "Check your inbox" : "Reset your password"}
  subheading={sent ? "" : "Enter the email tied to your account and we'll send a reset link."}
>
  {#if sent}
    <div class="fp__sent">
      <span class="fp__icon" aria-hidden="true">✓</span>
      <p class="fp__msg">We sent a reset link to <b>{email}</b>. The link expires in 30 minutes.</p>
      <Button variant="secondary" size="lg" fullWidth onclick={() => (sent = false)}>Use a different email</Button>
    </div>
  {:else}
    <form class="fp" onsubmit={submit} novalidate>
      <Input label="Email" type="email" placeholder="you@company.com" bind:value={email} required />
      <Button type="submit" size="lg" fullWidth loading={submitting}>Send reset link</Button>
    </form>
  {/if}

  {#snippet footer()}
    <p class="fp__foot">
      <button type="button" class="fp__link" onclick={() => onback?.()}>
        <span aria-hidden="true">←</span> Back to sign in
      </button>
    </p>
  {/snippet}
</AuthLayout>

<style>
  .fp { display: flex; flex-direction: column; gap: 16px; font-family: var(--font-primary); }
  .fp__sent { display: flex; flex-direction: column; gap: 18px; align-items: flex-start; }
  .fp__icon {
    width: 44px; height: 44px; border-radius: 50%;
    display: inline-flex; align-items: center; justify-content: center;
    background: rgb(var(--bg-positive-subtle)); color: rgb(var(--fg-positive));
    font: 700 18px/1 var(--font-secondary);
  }
  .fp__msg { margin: 0; font: 400 15px/1.6 var(--font-primary); color: rgb(var(--fg-secondary)); }
  .fp__msg b { color: rgb(var(--fg-primary)); font-weight: 600; }
  .fp__foot { margin: 0; text-align: center; }
  .fp__link {
    display: inline-flex; align-items: center; gap: 6px;
    border: 0; background: transparent; padding: 0; cursor: pointer;
    color: rgb(var(--fg-brand)); font: 600 13px/1.4 var(--font-primary);
  }
  .fp__link:hover { text-decoration: underline; }
</style>
