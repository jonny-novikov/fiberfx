<script>
  /**
   * ResetPasswordScreen — set a new password (post reset-link). Validates that
   * both fields match before enabling submit.
   *
   * @typedef {Object} ResetPasswordScreenProps
   * @property {(password: string) => void} [onsubmit]
   * @property {() => void} [onback]
   */
  import AuthLayout from "./AuthLayout.svelte";
  import Input from "../mercury/Input.svelte";
  import Button from "../mercury/Button.svelte";

  let { onsubmit, onback } = $props();

  let password = $state("");
  let confirm = $state("");
  let submitting = $state(false);

  const mismatch = $derived(confirm.length > 0 && confirm !== password);
  const tooShort = $derived(password.length > 0 && password.length < 8);
  const valid = $derived(password.length >= 8 && password === confirm);

  // Rule checks computed here so the template never starts an expression with
  // a regex literal — Svelte reads a leading `{/` as a block-closing tag.
  const hasLen = $derived(password.length >= 8);
  const hasUpper = $derived((/[A-Z]/).test(password));
  const hasNum = $derived((/[0-9]/).test(password));

  function submit(e) {
    e.preventDefault();
    if (!valid) return;
    submitting = true;
    setTimeout(() => { submitting = false; onsubmit?.(password); }, 700);
  }
</script>

<AuthLayout eyebrow="Almost there" heading="Set a new password" subheading="Choose a strong password you don't use anywhere else.">
  <form class="rp" onsubmit={submit} novalidate>
    <Input
      label="New password"
      type="password"
      placeholder="At least 8 characters"
      bind:value={password}
      error={tooShort ? "Must be at least 8 characters." : ""}
      required
    />
    <Input
      label="Confirm password"
      type="password"
      placeholder="Re-enter password"
      bind:value={confirm}
      error={mismatch ? "Passwords don't match." : ""}
      required
    />

    <ul class="rp__rules">
      <li class:ok={hasLen}><span aria-hidden="true">{hasLen ? "✓" : "○"}</span> 8+ characters</li>
      <li class:ok={hasUpper}><span aria-hidden="true">{hasUpper ? "✓" : "○"}</span> One uppercase letter</li>
      <li class:ok={hasNum}><span aria-hidden="true">{hasNum ? "✓" : "○"}</span> One number</li>
    </ul>

    <Button type="submit" size="lg" fullWidth loading={submitting} disabled={!valid}>Update password</Button>
  </form>

  {#snippet footer()}
    <p class="rp__foot"><button type="button" class="rp__link" onclick={() => onback?.()}><span aria-hidden="true">←</span> Back to sign in</button></p>
  {/snippet}
</AuthLayout>

<style>
  .rp { display: flex; flex-direction: column; gap: 16px; font-family: var(--font-primary); }
  .rp__rules { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 8px; }
  .rp__rules li { display: flex; align-items: center; gap: 8px; font: 500 13px/1 var(--font-primary); color: rgb(var(--fg-tertiary)); }
  .rp__rules li span { width: 14px; display: inline-flex; justify-content: center; }
  .rp__rules li.ok { color: rgb(var(--fg-positive)); }
  .rp__foot { margin: 0; text-align: center; }
  .rp__link {
    display: inline-flex; align-items: center; gap: 6px;
    border: 0; background: transparent; padding: 0; cursor: pointer;
    color: rgb(var(--fg-brand)); font: 600 13px/1.4 var(--font-primary);
  }
  .rp__link:hover { text-decoration: underline; }
</style>
