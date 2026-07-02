# Testing — the machine gates and the Operator-observed pixel proof

> Two kinds of proof, deliberately separated: what a machine can gate (types, the artifact's
> content, the suites) and what only eyes on the live loop can confirm (classes resolving to
> pixels, the host page un-clobbered). Never let the first impersonate the second.

## The machine gate ladder

Run **from `mercury/codemojex/`** (pnpm resolves the mercury workspace root upward). Never a
blind `pnpm -r` — the workspace carries other packages with their own build states.

```bash
pnpm install
pnpm --filter @codemojex/game typecheck   # tsc --noEmit
pnpm --filter @codemojex/game build       # vite build → the artifact gates below
pnpm --filter @codemojex/game test        # vitest (5 files / 35 tests as of cmt.4.1)
```

## The artifact gates (grep the bundle — never read it into context)

The build must emit **exactly one** `game-[hash].js` + `.vite/manifest.json` into
`echo/apps/codemojex/priv/static/game/` (a gitignored dir), with **zero** `.css` assets. Then,
with `ART=echo/apps/codemojex/priv/static/game/game-*.js`:

| Grep | Expect | Proves |
|---|---|---|
| `grep -c -F '.text-2xs{' $ART` | ≥ 1 | Tailwind compiled the `@theme` + a smoke-used utility rides |
| `grep -c -F '.bg-card{' $ART` | ≥ 1 | same, second utility |
| `grep -c -F -- '--color-bg-app-from' $ART` | ≥ 1 | the ported token rides (tracked via the `var()` reference in scanned source) |
| `grep -c -F '@codemoji/design' $ART` | 0 | no design-package dependency (F1) |
| `grep -c -F 'box-sizing:border-box' $ART` | 0 | no preflight leaked (the host is safe) |
| `grep -c -F 'VITE_GAME_SMOKE' $ART` | 0 | the smoke branch was statically folded out of the shipped bundle |

**Do not false-positive on the `*,:before,:after,::backdrop` block** the artifact does contain:
it is Tailwind v4's `@property` fallback (inside a `@supports` guard) initializing only internal
`--tw-*` custom properties. It styles no host element. The preflight check is the
`box-sizing`/reset **signature**, not the selector shape.

## The node-import gate (F-1 — source greps cannot see this)

App-mode Rollup can apply the facade optimization and emit a bundle **without** the entry's named
exports — every source grep still passes while the island is dead. `preserveEntrySignatures:
"strict"` in `vite.config.ts` prevents it; the gate that actually catches a regression is
importing the artifact:

```bash
node -e 'import("./echo/apps/codemojex/priv/static/game/"+process.argv[1]).then(m => {
  const ok = typeof m.mount === "function" && "GameEdge" in m;
  console.log(ok ? "OK: mount + GameEdge exported" : "FAIL: exports dropped");
  process.exit(ok ? 0 : 1);
})' "$(ls echo/apps/codemojex/priv/static/game/ | grep '^game-.*\.js$')"
```

## The vitest suites (as of cmt.4.1)

5 files / 35 tests: `GameSmoke.test.tsx` (the foundation smoke — render, `t() ≠ key`,
`cn('p-2', false && 'x', 'p-4') === 'p-4'`, the Classic className set), `GameEdge.test.tsx` +
`channel/model.test.ts` (the cmt.3 layer), `channel/bridge.test.ts` + `mount.test.tsx` (the
hotswap entry). jsdom computes no Tailwind pixels — the suites assert wiring and strings, never
`getComputedStyle`. jest-dom matchers ride the package's **own** expect
(`import "@testing-library/jest-dom/vitest"` in the test file — see
[troubleshooting.md](./troubleshooting.md) for the dual-vitest trap this avoids).

## The pixel proof (Operator-observed — OWED for cmt.4.1)

The one thing no gate above can see: that the tokens resolve to actual pixels in the real host
page, without clobbering it. Procedure, in the running dev loop
([dev-loop.md](./dev-loop.md)):

1. **Restart Vite in smoke mode** (the flag is baked per server run):
   ```bash
   # in the Vite terminal: Ctrl+C, then
   cd mercury/codemojex/apps/game
   VITE_GAME_SMOKE=1 pnpm exec vite --host 127.0.0.1 --port 5173 --strictPort
   ```
2. **Reload the game view in the shell** (navigate to a game page — `/` → `/lobby` →
   `/game/:gam`).
3. **Observe — all four, in the island's area only:**
   - the vertical gradient, pale blue `#E8F3F7` at the top → deeper `#AFC7D6` below (the Classic
     screen fill on the ported bg-app pair);
   - a white rounded card floating on it (`bg-card`, `rounded-2xl`);
   - the label **«пинг»** — tiny (10px, `text-2xs`), bold, black (`text-primary`), in
     Noto Sans Mono (i18n resolved the bundled `ru` string synchronously);
   - **the host page unchanged** — the welcome/lobby chrome and every non-island element look
     exactly as before the island mounted (no preflight, no reset). This is the non-clobber half
     of the proof.
4. **Flip back:** restart Vite **without** the flag → reload → the real game returns (the
   model-driven `BridgeGame` path). This also re-proves off-by-default.
5. Optional: open the dev panel (**Ctrl+`**) and watch the Channel frames while playing — the
   cmt.3 state layer feeding the same island the smoke just probed.

Doubt the mode mid-way? `curl -s http://127.0.0.1:5173/src/index.tsx | head -1` — smoke mode
shows `"VITE_GAME_SMOKE": "1"` inside the inlined `import.meta.env`.
