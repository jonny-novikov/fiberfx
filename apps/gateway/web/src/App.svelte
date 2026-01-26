<script lang="ts">
  import { auth } from './lib/auth.svelte';
  import LoginPage from './screens/LoginPage.svelte';
  import DashboardPage from './screens/DashboardPage.svelte';

  let initialized = $state(false);

  $effect(() => {
    auth.init();
    initialized = true;
  });
</script>

{#if !initialized}
  <div class="min-h-screen flex-center bg-bg-secondary">
    <div class="i-carbon-circle-dash text-4xl text-primary animate-spin"></div>
  </div>
{:else if auth.isAuthenticated}
  <DashboardPage />
{:else}
  <LoginPage />
{/if}
