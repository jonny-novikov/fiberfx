<script>
  /**
   * RegisterScreen — create a new EchoMQ account.
   *
   * @typedef {Object} RegisterScreenProps
   * @property {(data: object) => void} [onsubmit]
   * @property {() => void} [onlogin]
   */
  import AuthLayout from "./AuthLayout.svelte";
  import Input from "../mercury/Input.svelte";
  import Button from "../mercury/Button.svelte";
  import Checkbox from "../mercury/Checkbox.svelte";
  import Progress from "../mercury/Progress.svelte";

  let { onsubmit, onlogin } = $props();

  let name = $state("");
  let email = $state("");
  let org = $state("");
  let password = $state("");
  let agree = $state(false);
  let submitting = $state(false);

  const strength = $derived.by(() => {
    let s = 0;
    if (password.length >= 8) s += 34;
    if (/[A-Z]/.test(password) && /[a-z]/.test(password)) s += 33;
    if (/[0-9]/.test(password) || /[^a-zA-Z0-9]/.test(password)) s += 33;
    return Math.min(100, s);
  });
  const strengthLabel = $derived(
    password.length === 0 ? "" : strength < 40 ? "Weak" : strength < 75 ? "Fair" : "Strong",
  );
  const strengthVariant = $derived(strength < 40 ? "negative" : strength < 75 ? "caution" : "positive");

  function submit(e) {
    e.preventDefault();
    submitting = true;
    setTimeout(() => { submitting = false; onsubmit?.({ name, email, org, password }); }, 800);
  }
</script>

<AuthLayout eyebrow="Get started" heading="Create your account" subheading="Spin up a workspace and connect your first broker in minutes.">
  <form class="rg" onsubmit={submit} novalidate>
    <Input label="Full name" placeholder="Ada Lovelace" bind:value={name} required />
    <Input label="Work email" type="email" placeholder="you@company.com" bind:value={email} required />
    <Input label="Organisation" placeholder="ACME Corp" bind:value={org} hint="This becomes your workspace name." />

    <div class="rg__pw">
      <Input label="Password" type="password" placeholder="At least 8 characters" bind:value={password} required />
      {#if password}
        <div class="rg__meter">
          <Progress value={strength} variant={strengthVariant} size="sm" />
          <span class="rg__meterlbl rg__meterlbl--{strengthVariant}">{strengthLabel}</span>
        </div>
      {/if}
    </div>

    <Checkbox bind:checked={agree}>
      I agree to the <a href="#terms" class="rg__inline">Terms</a> and <a href="#privacy" class="rg__inline">Privacy Policy</a>.
    </Checkbox>

    <Button type="submit" size="lg" fullWidth loading={submitting} disabled={!agree}>Create account</Button>
  </form>

  {#snippet footer()}
    <p class="rg__foot">Already have an account? <button type="button" class="rg__link" onclick={() => onlogin?.()}>Sign in</button></p>
  {/snippet}
</AuthLayout>

<style>
  .rg { display: flex; flex-direction: column; gap: 16px; font-family: var(--font-primary); }
  .rg__pw { display: flex; flex-direction: column; gap: 10px; }
  .rg__meter { display: flex; align-items: center; gap: 12px; }
  .rg__meterlbl { font: 600 12px/1 var(--font-primary); flex-shrink: 0; min-width: 48px; }
  .rg__meterlbl--negative { color: rgb(var(--fg-negative)); }
  .rg__meterlbl--caution  { color: rgb(var(--fg-caution)); }
  .rg__meterlbl--positive { color: rgb(var(--fg-positive)); }
  .rg__inline { color: rgb(var(--fg-brand)); }
  .rg__link { border: 0; background: transparent; padding: 0; cursor: pointer; color: rgb(var(--fg-brand)); font: 600 13px/1.4 var(--font-primary); }
  .rg__link:hover { text-decoration: underline; }
  .rg__foot { margin: 0; text-align: center; font: 400 14px/1.4 var(--font-primary); color: rgb(var(--fg-secondary)); }
</style>
