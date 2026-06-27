<script>
  /**
   * LoginScreen — sign in to the EchoMQ console. Composed from Mercury primitives.
   *
   * @typedef {Object} LoginScreenProps
   * @property {(creds: {email:string,password:string,remember:boolean}) => void} [onsubmit]
   * @property {() => void} [onforgot]
   * @property {() => void} [onregister]
   * @property {() => void} [onsso]
   */
  import AuthLayout from "./AuthLayout.svelte";
  import Input from "../mercury/Input.svelte";
  import Button from "../mercury/Button.svelte";
  import Checkbox from "../mercury/Checkbox.svelte";
  import Alert from "../mercury/Alert.svelte";

  let { onsubmit, onforgot, onregister, onsso } = $props();

  let email = $state("");
  let password = $state("");
  let remember = $state(true);
  let error = $state("");
  let submitting = $state(false);

  function submit(e) {
    e.preventDefault();
    error = "";
    if (!email || !password) { error = "Enter your email and password to continue."; return; }
    submitting = true;
    setTimeout(() => { submitting = false; onsubmit?.({ email, password, remember }); }, 700);
  }
</script>

<AuthLayout eyebrow="Welcome back" heading="Sign in to your console" subheading="Manage queues, jobs and processors across your connections.">
  <form class="lg" onsubmit={submit} novalidate>
    {#if error}<Alert tone="danger" title="Could not sign in">{error}</Alert>{/if}

    <Button variant="secondary" size="lg" fullWidth onclick={() => onsso?.()}>
      {#snippet leading()}<span class="lg__g">G</span>{/snippet}
      Continue with Google
    </Button>

    <div class="lg__or"><span></span><em>or sign in with email</em><span></span></div>

    <Input label="Email" type="email" placeholder="you@company.com" bind:value={email} required />
    <Input label="Password" type="password" placeholder="••••••••" bind:value={password} required />

    <div class="lg__row">
      <Checkbox bind:checked={remember} label="Keep me signed in" />
      <button type="button" class="lg__link" onclick={() => onforgot?.()}>Forgot password?</button>
    </div>

    <Button type="submit" size="lg" fullWidth loading={submitting}>Sign in</Button>
  </form>

  {#snippet footer()}
    <p class="lg__foot">New to EchoMQ? <button type="button" class="lg__link" onclick={() => onregister?.()}>Create an account</button></p>
  {/snippet}
</AuthLayout>

<style>
  .lg { display: flex; flex-direction: column; gap: 16px; font-family: var(--font-primary); }
  .lg__g {
    width: 18px; height: 18px; border-radius: 4px;
    display: inline-flex; align-items: center; justify-content: center;
    background: rgb(var(--bg-tertiary)); color: rgb(var(--fg-primary));
    font: 700 11px/1 var(--font-secondary);
  }
  .lg__or { display: flex; align-items: center; gap: 12px; margin: 2px 0; }
  .lg__or span { flex: 1; height: 1px; background: rgb(var(--border-secondary)); }
  .lg__or em { font: 500 11px/1 var(--font-primary); letter-spacing: 0.06em; text-transform: uppercase; color: rgb(var(--fg-tertiary)); font-style: normal; }
  .lg__row { display: flex; align-items: center; justify-content: space-between; }
  .lg__link {
    border: 0; background: transparent; padding: 0; cursor: pointer;
    color: rgb(var(--fg-brand)); font: 600 13px/1.4 var(--font-primary);
  }
  .lg__link:hover { text-decoration: underline; }
  .lg__foot { margin: 0; text-align: center; font: 400 14px/1.4 var(--font-primary); color: rgb(var(--fg-secondary)); }
</style>
