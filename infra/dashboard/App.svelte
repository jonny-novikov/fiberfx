<script>
  import Valkey from './lib/Valkey.svelte'
  let tab = 'valkey'
</script>

<header>
  <h1>Codemojex · Dashboard</h1>
  <nav>
    <button class:active={tab === 'valkey'} on:click={() => (tab = 'valkey')}>Valkey</button>
    <button class:active={tab === 'db'} on:click={() => (tab = 'db')}>Database</button>
  </nav>
</header>

<main>
  {#if tab === 'valkey'}
    <Valkey />
  {:else}
    <!-- pgweb is served under /db behind the same basic auth -->
    <iframe title="pgweb database browser" src="/db/"></iframe>
  {/if}
</main>
