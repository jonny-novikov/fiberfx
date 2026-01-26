<script lang="ts">
  import { auth } from '../lib/auth.svelte';

  let username = $state('');
  let password = $state('');
  let isSubmitting = $state(false);

  async function handleSubmit(e: Event) {
    e.preventDefault();
    if (isSubmitting || !username || !password) return;

    isSubmitting = true;
    await auth.login(username, password);
    isSubmitting = false;
  }
</script>

<div class="min-h-screen flex-center bg-bg-secondary">
  <div class="w-full max-w-md px-4">
    <!-- Logo/Brand -->
    <div class="text-center mb-8">
      <div class="text-5xl mb-4">🎮</div>
      <h1 class="text-2xl font-semibold text-ink-heading mb-2">Codemoji Gateway</h1>
      <p class="text-ink-muted">Database Management Console</p>
    </div>

    <!-- Login Card -->
    <div class="card">
      <h2 class="text-xl font-semibold text-ink-heading mb-6">Sign In</h2>

      <form onsubmit={handleSubmit}>
        <!-- Username -->
        <div class="mb-4">
          <label for="username" class="label">Admin Username</label>
          <input
            type="text"
            id="username"
            bind:value={username}
            class="input"
            class:input-error={auth.error}
            placeholder="Enter your Telegram username"
            autocomplete="username"
            required
            disabled={isSubmitting}
          />
        </div>

        <!-- Password -->
        <div class="mb-6">
          <label for="password" class="label">Gateway Password</label>
          <input
            type="password"
            id="password"
            bind:value={password}
            class="input"
            class:input-error={auth.error}
            placeholder="Enter gateway password"
            autocomplete="current-password"
            required
            disabled={isSubmitting}
          />
        </div>

        <!-- Error Message -->
        {#if auth.error}
          <div class="mb-4 p-3 bg-danger/10 rounded-lg text-danger text-sm flex items-center gap-2">
            <span class="i-carbon-warning"></span>
            {auth.error}
          </div>
        {/if}

        <!-- Submit Button -->
        <button
          type="submit"
          class="btn-primary w-full"
          disabled={isSubmitting || !username || !password}
        >
          {#if isSubmitting}
            <span class="i-carbon-circle-dash animate-spin mr-2"></span>
            Signing in...
          {:else}
            <span class="i-carbon-login mr-2"></span>
            Sign In
          {/if}
        </button>
      </form>
    </div>

    <!-- Footer -->
    <p class="text-center text-sm text-ink-subtle mt-6">
      Admin access only. Powered by Drizzle Studio.
    </p>
  </div>
</div>
