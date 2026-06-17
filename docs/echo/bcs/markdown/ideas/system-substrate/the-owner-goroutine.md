# B1.1 · The Owner Goroutine — same law, different clothing

> Route: `/bcs/ideas/system-substrate/the-owner-goroutine` (dive 3 of 3, module B1.1). The route-mirror
> source-of-record. Teaches the Go design of `content/bcs1.1.md` · How (Go, as designed); the snippet is
> quoted verbatim and labelled as design. Build stamp: `BCS0NtMiKa22DY`.

## Hero

Kicker: `B1.1 · DIVE — THE OWNER GOROUTINE`. Title: **Same law, different clothing.** Lede — Go states the
substrate's first clause as doctrine: do not communicate by sharing memory; share memory by communicating. A
goroutine that owns a data structure guarantees sequential access by construction. The substrate translates
directly. Heronote — designed counterpart; the manuscript marks it as landing as its own rung. The pure-Go
contract package (`brandedid`) already supplies parse and hash conformance under `runtimes/go/`.

### Interactive 1 — one op through the boundary (hero)

An SVG of the shape — caller → channel → owner goroutine (map + sorted key slice) → reply. A four-step
walk-through, each step a pure lookup:

1. **send** — the caller writes an `op` (kind · 14-byte branded id · value · reply channel) into the channel.
   No reference to the map exists outside the goroutine.
2. **gate** — the namespace gate runs at the channel's receiving edge, via the existing pure-Go contract
   package (`brandedid`); a wrong-namespace id is refused before the table is touched.
3. **mutate** — the goroutine alone reads or writes `props`, and keeps `keys` sorted so byte order keeps
   supplying mint order — Go maps are unordered.
4. **reply** — the result returns on the op's own reply channel. Sequential access, by construction.

Degrades to the static diagram plus this list.

## §1 · The design, verbatim (#design)

The chapter's snippet (`content/bcs1.1.md` · How — Go, as designed), labelled as the manuscript labels it:

```go
// Designed counterpart — lands as its own rung. The gate package exists.
type op struct {
	kind  byte      // put | get | page
	id    string    // 14-byte branded id; gated before the table
	value any
	reply chan any
}

func propertyStore(ns string, ops <-chan op) {
	props := map[string]any{} // owned by this goroutine alone
	var keys []string         // kept sorted: byte order == mint order
	for o := range ops {
		// gate via the existing pure-Go contract package (brandedid),
		// refuse wrong namespace, then mutate props/keys and reply.
		_ = ns
		o.reply <- nil
	}
}
```

## §2 · Enforcement differs; the law does not (#enforcement)

The shapes differ in enforcement, not in law: the BEAM refuses the reach-through at the VM; Go removes the
shared reference so there is nothing to reach through. Both put the gate at the one place identities enter.

### Interactive 2 — the refusal matrix

Three crimes × two runtimes, a pure lookup over six cells:

- **reach-through** — BEAM: outside `lookup`/`insert` → `ArgumentError`; the VM refuses at the call. Go: no
  shared reference exists — the map lives in one goroutine's stack frame; there is nothing to reach through.
- **traveling object** — BEAM: map/tuple/integer ids → `FunctionClauseError` 3/3; binaries only. Go: the `op`
  carries `id string` — a 14-byte branded id, not an object; the channel is the only crossing.
- **wrong namespace** — BEAM: `{:error, :namespace}` from `gate/2`, `NamespaceError` from the raising twin.
  Go: the gate at the channel's receiving edge, via `brandedid`, refuses before the table is touched.

Degrades to this static table.

## §3 · Where it lands (#lands)

In the tree, the Go counterpart targets `runtimes/go/`, where the pure-Go contract package (`brandedid`)
already supplies parse and hash conformance; the store itself is designed in the written chapter and lands as
its own rung. The course returns to it when that rung freezes its own transcript.

## References (#refs)

Sources: The Go Project — Share Memory By Communicating (`https://go.dev/doc/codewalk/sharemem/`) · Erlang/OTP
— the ets module (`https://www.erlang.org/doc/apps/stdlib/ets.html`) · Chassaing — Functional Event Sourcing
Decider (`https://thinkbeforecoding.com/post/2021/12/17/functional-event-sourcing-decider`).
Related: `/bcs/ideas/system-substrate` (the B1.1 hub) · `/bcs/ideas` (B1 · Ideas Behind) · `/bcs` (course
home).

## Pager

Previous: `/bcs/ideas/system-substrate/ownership-on-the-beam` — Ownership on the BEAM. Next:
`/bcs/ideas/system-substrate` — back to the B1.1 hub.
