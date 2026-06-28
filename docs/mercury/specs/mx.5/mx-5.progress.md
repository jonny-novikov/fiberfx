# mx-5 — AAW scope ledger

## {mx-5-progress} Progress

### P-1 — mx.5 triad authored + reconciled (BUILD-GRADE). Wrote docs/mercury/specs/mx.5/{mx.5.md,mx.5.stories.md,mx.5.llms.md}. Rung = six effector-powered Storybook stories (one per adapter) under apps/storybook/stories/effector/; barrel FROZEN byte-identical; host already wired (zero host-config edit). Key reconciles: (1) source has 6 adapters, roadmap row lags at 4 (design §1 correct); (2) formatter→Stat NOT MoneyInput (formatter is Intl date/locale, MoneyInput takes no formatter — task hint corrected §6.6); (3) strength is a PURE fn, story supplies effector state. 3 residual Arms (theme decorator augment[rec]/replace; host-home[rec]; one-file-per-adapter[rec]). All triad links resolve.

### P-2 — mx.5 BUILT + post-build verified BUILD-GRADE (Apollo, 2026-06-29). Six story files shipped (Theme/Toast/Form/Strength/Cooldown/Formatter, each NEW under apps/storybook/stories/effector/). Independent gate all EXIT 0: sb:typecheck · packages typecheck+build · 5 product apps build (catalogue/docs/echomq/mobile/showcase) · sb:build = 42 homes (prior 36 + the six Effector/*). INV-1 barrel byte-identical (empty diff); INV-2 only the six untracked stories + triad under mercury/; INV-6/7 greps empty; Arm A holds (no initTheme import); Formatter wires Stat not MoneyInput; SAMPLE fixed. Every promise (K-1..K-6, INV-1..INV-7, S-1..S-9) = MATCH; 0 STALE/INVENTED/MISSING. §9 as-built filled; body status flipped to BUILT; llms.md gotcha added (the new Date() substring-literal gate). Residual flag for the Director: mercury/vitest.config.ts is modified (adds packages/*/src tests) — outside mx.5; keep it OUT of the mx.5 pathspec commit.


