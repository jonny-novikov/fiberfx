# BCS.0 · agent guide

> How to build (or rebuild) the B0 rung: the exact surface, the requirements traced to the stories, the do-NOTs,
> and the verification commands. Spec of record: [`bcs.0.specs.md`](bcs.0.specs.md) · chapter doc:
> [`bcs.0.md`](bcs.0.md).

## References

- The spec triad: [`bcs.0.md`](bcs.0.md) · [`bcs.0.specs.md`](bcs.0.specs.md) (the gate matrix + design brief).
- The course docs: [`../bcs.md`](../bcs.md) (contract; the MUST-NOT identity list) ·
  [`../bcs.toc.md`](../bcs.toc.md) (the B0–B8 map) · [`../bcs.roadmap.md`](../bcs.roadmap.md) (grounding map +
  seams ledger).
- Grounding sources (quote figures verbatim, never paraphrase a number):
  [`../content/bcs.preface.md`](../content/bcs.preface.md) (the law's lineage) ·
  [`../content/bcs1.md`](../content/bcs1.md) (the three clauses + failure modes) ·
  [`../content/contract.md`](../content/contract.md) (the id form, the gates, `hash32 = 234878118`,
  `MAX_PAYLOAD = "AzL8n0Y58m7"`, epoch `1704067200000`) ·
  [`../content/bcsA.md`](../content/bcsA.md) (the connector: 454,483 pipelined ops/s vs 29,456 sequential,
  Valkey 9.1.0, the `echomq:2.0.0` fence).
- Chrome structure reference (structure only — the styling is BCS's own): `html/echomq/index.html` route-tag,
  footer, stamp + decoder markup.

## Requirements

- **BCS.0-R1** — author the md mirror `docs/echo/bcs/markdown/index.md` before the HTML. [US: BCS.0-US1]
- **BCS.0-R2** — build `html/bcs/index.html` to the design brief and the gate matrix in
  [`bcs.0.specs.md`](bcs.0.specs.md). [US: BCS.0-US1]
- **BCS.0-R3** — mint the build stamp in the course namespace and verify the round-trip before embedding:
  `apps/jonnify-cms/bin/cms stamp mint --ns BCS` → `apps/jonnify-cms/bin/cms stamp decode <id>`. [US: BCS.0-US2]
- **BCS.0-R4** — wire the route per the touchpoint table in [`bcs.0.specs.md`](bcs.0.specs.md); add, never edit,
  existing registrations. [US: BCS.0-US2]
- **BCS.0-R5** — run the verification sequence below to completion; ship only at STATUS: PASS. [US: BCS.0-US2]

## Do NOT

- Do not copy dark-editorial tokens, fonts, or card classes from `/elixir`, `/redis-patterns`, `/echomq`, or the
  AAW course — the MUST-NOT list in [`../bcs.md`](../bcs.md) is binding.
- Do not link unbuilt chapters (B1–B8 are non-anchor `soon` cards) and never link the site root `/`.
- Do not fetch anything external: no CDN fonts, no KaTeX, no third-party scripts.
- Do not write a figure that is not verbatim in a committed output under `../content/`.
- Do not edit the manuscript, its ledger (`../content/bcs.progress.md`), `html/llms.txt`, the root
  `html/index.html`, or `cmd/sitemap/main.go` (the deferred seams).
- Do not run git. The Operator commits out-of-band.
- Mind the gate traps: the voice gate bans the word "just" in visible prose; the no-future gate bans the literal
  substring `/future` anywhere in the file, comments and JS included.

## Agent stories

- **BCS.0-AS1 [implements BCS.0-US1]** — Author the md mirror, then the landing. Acceptance gate: the HTML
  carries every section the md names; the id-anatomy SVG is interactive (hover/focus a segment → its field) and
  degrades statically.
- **BCS.0-AS2 [implements BCS.0-US2]** — Wire and verify. Acceptance gate: the verification sequence below is
  green end to end, including the regression curls.
- **BCS.0-AS3 [implements BCS.0-US3]** — Leave the exemplar copyable: tokens in one `:root` block, the chrome and
  the evidence styling clearly delimited, the stamp + decoder self-contained.

## The verification sequence

```bash
# 1. Gate tool (prebuilt bin exists; rebuild if needed)
cd apps/jonnify-cms && GOWORK=off go build -o bin/cms . && cd ../..

# 2. The ten gates — STATUS: PASS required
apps/jonnify-cms/bin/cms check \
  --routes-from /bcs=html/bcs \
  --routes-from /echomq=html/echomq \
  --routes-from /redis-patterns=html/redis-patterns \
  --routes-from /elixir=elixir \
  --require-refs html/bcs/index.html

# 3. Root server build + hygiene
GOWORK=off gofmt -l main.go && GOWORK=off go vet . && GOWORK=off go build -o bin/jonnify .

# 4. Serve + crawl (port 8765; restart if a stale instance runs)
make status; make start   # or: make restart
curl -s -o /dev/null -w '%{http_code}' localhost:8765/bcs        # 200
curl -s -o /dev/null -w '%{http_code}' localhost:8765/bcs/nope   # 404
for r in /healthz /echomq /redis-patterns /elixir; do
  curl -s -o /dev/null -w "$r %{http_code}\n" localhost:8765$r   # all 200
done

# 5. Adversarial greps (all must return nothing)
grep -n '/future' html/bcs/index.html
grep -nEi '\b(revolutionary|blazing|magical|simply|just|obviously|effortless)\b' html/bcs/index.html
grep -n 'localStorage\|sessionStorage' html/bcs/index.html
grep -nE 'clamp\([^)]*[0-9](\+|-)' html/bcs/index.html
grep -n 'href="/"' html/bcs/index.html
```

## Comprehensive prompt

Build the B0 rung of the BCS course. Read [`bcs.0.specs.md`](bcs.0.specs.md) (deliverables, invariants, gate
matrix, design brief) and the grounding sources above. Author `docs/echo/bcs/markdown/index.md`, then
`html/bcs/index.html` as one self-contained page in the course's own visual identity: monospace-forward system
typography, the 3/11 id-anatomy rhythm, the law as a triptych, verbatim transcript evidence, the B1–B8 map with
non-anchor `soon` cards, doors to `/echomq` and `/redis-patterns`, two-column References, the clickable route-tag,
the 3-column footer with a freshly minted `BCS…` stamp and its decoder. Wire `/bcs` per the touchpoint table.
Run the verification sequence; ship only when every step is green. Never run git.

---

Index: ../bcs.md · TOC: ../bcs.toc.md · Roadmap: ../bcs.roadmap.md · Chapter: ./bcs.0.md · Spec: ./bcs.0.specs.md
