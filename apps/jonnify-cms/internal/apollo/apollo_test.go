package apollo

func passDetail(res []Result, name string) (bool, string) {
	for _, r := range res {
		if r.Name == name {
			return r.OK, r.Detail
		}
	}
	return false, "missing gate"
}

// A minimal document that clears all nine gates.
const goodDoc = `<!doctype html><html><head>
<style>@media (prefers-reduced-motion:reduce){*{animation:none}}</style></head>
<body><main id="main"><section>
<svg viewBox="0 0 10 10"><rect/></svg>
<p>A precise sentence with no hype.</p>
<nav class="pager"><a href="/elixir">Home</a></nav>
</section></main></body></html>`

// A document that trips voice, storage, no-future and links.
const badDoc = `<!doctype html><html><head>
<style>@media (prefers-reduced-motion:reduce){}</style></head>
<body><main><section>
<svg></svg>
<p>This is just obviously a great page.</p>
<script>localStorage.setItem('x',1)</script>
<a href="/future/llms">future</a>
<a href="/elixir/nope">dangling</a>
<nav class="pager"><a href="/elixir">Home</a></nav>
</section></main></body></html>`
