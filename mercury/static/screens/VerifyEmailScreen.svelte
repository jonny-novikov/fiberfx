<script>
  /**
   * VerifyEmailScreen — one-time-code verification step (2FA / email confirm).
   * Uses the AuthCode primitive; auto-submits when all digits are filled.
   *
   * @typedef {Object} VerifyEmailScreenProps
   * @property {string} [email]
   * @property {(code: string) => void} [onsubmit]
   * @property {() => void} [onresend]
   * @property {() => void} [onback]
   */
  import AuthLayout from "./AuthLayout.svelte";
  import AuthCode from "../mercury/AuthCode.svelte";
  import Button from "../mercury/Button.svelte";

  let { email = "you@company.com", onsubmit, onresend, onback } = $props();

  let code = $state("");
  let error = $state("");
  let submitting = $state(false);
  let cooldown = $state(0);

  function complete(value) {
    error = "";
    submitting = true;
    setTimeout(() => {
      submitting = false;
      if (value === "000000") { error = "That code is invalid or expired."; code = ""; }
      else onsubmit?.(value);
    }, 700);
  }

  function resend() {
    if (cooldown > 0) return;
    onresend?.();
    cooldown = 30;
    const t = setInterval(() => { cooldown -= 1; if (cooldown <= 0) clearInterval(t); }, 1000);
  }
</script>

<AuthLayout eyebrow="Verify it's you" heading="Enter your code" subheading={`We sent a 6-digit code to ${email}. It expires in 10 minutes.`}>
  <div class="vf">
    <AuthCode bind:value={code} length={6} {error} oncomplete={complete} />

    <Button size="lg" fullWidth loading={submitting} disabled={code.length < 6} onclick={() => complete(code)}>Verify</Button>

    <p class="vf__resend">
      Didn't get it?
      <button type="button" class="vf__link" class:is-dis={cooldown > 0} disabled={cooldown > 0} onclick={resend}>
        {cooldown > 0 ? `Resend in ${cooldown}s` : "Resend code"}
      </button>
    </p>
  </div>

  {#snippet footer()}
    <p class="vf__foot"><button type="button" class="vf__link" onclick={() => onback?.()}><span aria-hidden="true">←</span> Use a different account</button></p>
  {/snippet}
</AuthLayout>

<style>
  .vf { display: flex; flex-direction: column; gap: 20px; font-family: var(--font-primary); align-items: stretch; }
  .vf__resend { margin: 0; text-align: center; font: 400 14px/1.4 var(--font-primary); color: rgb(var(--fg-secondary)); }
  .vf__foot { margin: 0; text-align: center; }
  .vf__link {
    display: inline-flex; align-items: center; gap: 6px;
    border: 0; background: transparent; padding: 0; cursor: pointer;
    color: rgb(var(--fg-brand)); font: 600 13px/1.4 var(--font-primary);
  }
  .vf__link:hover:not(.is-dis) { text-decoration: underline; }
  .vf__link.is-dis { color: rgb(var(--fg-tertiary)); cursor: not-allowed; }
</style>
