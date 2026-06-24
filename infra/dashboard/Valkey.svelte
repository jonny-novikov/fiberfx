<script>
  import { onMount, onDestroy } from 'svelte'

  let overview = null
  let clients = null
  let err = null
  let timer

  async function getJSON(path) {
    const r = await fetch(path)
    if (!r.ok) throw new Error(path + ' → HTTP ' + r.status)
    return r.json()
  }

  async function load() {
    try {
      ;[overview, clients] = await Promise.all([
        getJSON('/api/valkey/overview'),
        getJSON('/api/valkey/clients'),
      ])
      err = null
    } catch (e) {
      err = e.message
    }
  }

  onMount(() => {
    load()
    timer = setInterval(load, 5000)
  })
  onDestroy(() => clearInterval(timer))

  const cards = (o) => [
    ['Server', o.server],
    ['Clients', o.clients],
    ['Memory', o.memory],
    ['Stats', o.stats],
    ['Persistence', o.persistence],
  ]
</script>

{#if err}
  <div class="err">{err}</div>
{/if}

{#if overview}
  <div class="grid">
    {#each cards(overview) as [title, obj]}
      <div class="card">
        <h3>{title}</h3>
        {#each Object.entries(obj || {}) as [k, v]}
          <div class="kv"><span>{k}</span><span>{v}</span></div>
        {/each}
      </div>
    {/each}
    <div class="card">
      <h3>Keyspace</h3>
      {#each Object.entries(overview.keyspace || {}) as [db, v]}
        <div class="kv"><span>{db}</span><span>{v}</span></div>
      {/each}
      <div class="kv"><span>dbsize</span><span>{overview.dbsize}</span></div>
    </div>
  </div>

  {#if clients && clients.clients}
    <div class="card" style="margin-top:16px">
      <h3>Connected clients ({clients.count})</h3>
      <table>
        <thead><tr><th>addr</th><th>name</th><th>age</th><th>cmd</th><th>db</th></tr></thead>
        <tbody>
          {#each clients.clients as c}
            <tr><td>{c.addr}</td><td>{c.name}</td><td>{c.age}</td><td>{c.cmd}</td><td>{c.db}</td></tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
{:else if !err}
  <p style="color:var(--muted)">Loading…</p>
{/if}
