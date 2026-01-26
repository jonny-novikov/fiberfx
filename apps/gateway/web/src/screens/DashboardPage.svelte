<script lang="ts">
  import { auth } from '../lib/auth.svelte';

  function handleLogout() {
    auth.logout();
  }

  function openStudio() {
    window.location.href = '/local/';
  }
</script>

<div class="min-h-screen bg-bg-secondary">
  <!-- Header -->
  <header class="bg-white border-b border-border">
    <div class="max-w-6xl mx-auto px-4 py-4 flex-between">
      <div class="flex items-center gap-3">
        <span class="text-2xl"></span>
        <h1 class="text-xl font-semibold text-ink-heading">Codemoji</h1>
      </div>
      <div class="flex items-center gap-4">
        <span class="text-sm text-ink-muted">
          Logged in as <span class="font-medium text-ink-body">{auth.user?.username}</span>
        </span>
        <button onclick={handleLogout} class="btn-secondary text-sm">
          <span class="i-carbon-logout mr-1"></span>
          Logout
        </button>
      </div>
    </div>
  </header>

  <!-- Main Content -->
  <main class="max-w-6xl mx-auto px-4 py-8">
    <div class="grid gap-6 md:grid-cols-2">
      <!-- Drizzle Studio Card -->
      <button onclick={openStudio} class="card hover:shadow-elevated transition-shadow text-left group">
        <div class="flex items-start gap-4">
          <div class="w-12 h-12 rounded-lg bg-primary/10 flex-center group-hover:bg-primary/20 transition-colors">
            <span class="i-carbon-data-base text-2xl text-primary"></span>
          </div>
          <div class="flex-1">
            <h2 class="text-lg font-semibold text-ink-heading mb-1">Database Studio</h2>
            <p class="text-sm text-ink-muted">
              Visual database explorer. Browse tables, run queries, and manage your PostgreSQL data.
            </p>
          </div>
          <span class="i-carbon-arrow-right text-xl text-ink-subtle group-hover:text-primary transition-colors"></span>
        </div>
      </button>

      <!-- Info Card -->
      <div class="card">
        <div class="flex items-start gap-4">
          <div class="w-12 h-12 rounded-lg bg-success/10 flex-center">
            <span class="i-carbon-checkmark-filled text-2xl text-success"></span>
          </div>
          <div class="flex-1">
            <h2 class="text-lg font-semibold text-ink-heading mb-1">Connection Status</h2>
            <p class="text-sm text-ink-muted mb-3">
              Gateway is connected and ready.
            </p>
            <div class="text-xs text-ink-subtle">
              <p>Database: codemoji-db.internal</p>
              <p>Role: {auth.user?.role || 'admin'}</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Quick Stats -->
    <div class="mt-8">
      <h2 class="text-lg font-semibold text-ink-heading mb-4">Quick Actions</h2>
      <div class="grid gap-4 sm:grid-cols-3">
        <a href="/db/" class="card hover:shadow-elevated transition-shadow flex items-center gap-3">
          <span class="i-carbon-table-split text-xl text-primary"></span>
          <span class="text-sm font-medium text-ink-body">Browse Tables</span>
        </a>
        <a href="/db/" class="card hover:shadow-elevated transition-shadow flex items-center gap-3">
          <span class="i-carbon-sql text-xl text-primary"></span>
          <span class="text-sm font-medium text-ink-body">Run Query</span>
        </a>
        <a href="/db/" class="card hover:shadow-elevated transition-shadow flex items-center gap-3">
          <span class="i-carbon-diagram text-xl text-primary"></span>
          <span class="text-sm font-medium text-ink-body">View Schema</span>
        </a>
      </div>
    </div>
  </main>
</div>
