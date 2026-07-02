# msh2-2 — AAW scope ledger

## {msh2-2-thinking} Thinking

### T-1 — msh2.2 rung run opens: frontmatter v2 + the S-4-fenced backfill

Mission (roadmap msh2.2 row, D-8): frontmatter v2 contract keys {project, status, review_after}; scoped memory_scan/memory_stale (project filter, additive params, tool pin stays 8); status: retires the corpus.go:135-138 body sniff to fallback; NEW review-due stale rule (review_after's day-one consumer); the 70-note memory/ backfill as a staged, byte-diffed sub-rung under the manual §3 memory-data ladder. Boundary: go/msh + the one fenced memory/ edit (S-4). Formation per manual §2 + §2.4 (Apollo MANDATORY — mass-backfill rung): Director + Venus (triad; settles Seam S-2 key arity + degrade order) + Mars (build + staged backfill) + Apollo (reconcile + adversarial verify + verdict). Pre-rung baseline: msh memory audit = 71 files, error=0 warn=0 info=1 (clean-before leg green). Dirty-tree fact: memory/MEMORY.md + memory/mercury-design-system.md carry uncommitted Operator edits; memory/mercury-visual-regression-harness.md untracked — backfill commits must pathspec around them.

### T-2 — RESUME: Director re-opens msh2.2 at Stage 2 (Mars build); the D-2 Operator gate is released by "Ship msh2.2.md"

Mode: Flat-L2 · Resume. The Venus triad is build-grade (P-1); scope msh2-2 is live (Director + venus-22 on claude-fable-5; next_ccl 3). Formation per program manual §2 + §2.4: Venus✓ + Mars (build + staged backfill) + Director (independent gate + probe + ship) + Apollo (MANDATORY — §2.4 names the msh2.2 mass backfill high-risk).

Green-before baseline re-run at HEAD (the attribution anchor, per the entangled-tree lesson): `GOWORK=off go build -o $TMP ./cmd` exit 0; `go vet ./...` clean; `go test ./...` all ok including cmd (TestToolCountPin=8 green WITH the untracked cmd/history.go on disk — it is out-of-band, kept on disk so the tree compiles, carved from the rung commit). Venus citations spot-verified accurate against the code: parse.go:10-15/30-36/74-95 (coalesce top>nested); corpus.go:43-64 loadCorpus, :62 sniff call, :85 normalize, :125-142 isSupersededByText; node.go:15-20 Status enum, :22-34 Node; rules.go:22-30 names, :32-42 AllRules, :44 Run, :68-81 sortFindings; audit.go:17 Long promises "any error-severity" vs :44 checks DEAD-TARGET only — D6's target is real.

Build plan (Mars waves, each a bounded write-first dispatch; Director gates between): A go-code D1..D8 + tests G-1..G-8 + gate → B harden (remediate Director findings) → C backfill dry-run (backup + throwaway script + emit note→slug table, STOP before apply for Director review R-2/R-3) → D backfill apply + verify (G-10). Then Apollo §11.2 verdict + spec-sync, then Director ship = TWO pathspec commits per D-1 "commits per concern" (concern 1: go/msh code + triad + progress + roadmap row; concern 2: memory/ backfill, clean notes only).

### T-3 — Director backfill prep (independent, parallel to the Mars-1 go-code build): preconditions verified + the note→slug expectation table for the R-2 dry-run review

Preconditions (read-only grep over memory/): (a) the `metadata:` insertion anchor is present in ALL 71 notes — only MEMORY.md lacks it (correctly skipped, no frontmatter); the §5 "insert project: immediately before metadata:" mechanic is safe corpus-wide. (b) ZERO existing project:/status:/review_after: keys — greenfield insertion, confirms spec §2.

Independent expectation (to diff against Mars's emitted dry-run, anti-rubber-stamp):
- R-1 dir notes (25, verbatim): aaw×5→aaw · courses×3→courses · echo_graft×1→echo_graft · echo_mq×9→echo_mq · elixir×7→elixir.
- R-2 flat MECHANICAL/high-confidence (~31): codemojex-{cm-ship-program,admin-program,livereact-render,program,tauri-track,tma-edge,write-suite,codemoji-design-system}→codemojex · mercury-{compose,design-system,dual-vitest,economy,visual-regression}→mercury · echo-courses-program→echo-courses · exchange-platform→exchange · figma-local-program→figma-local · go-{mcp-go,workspace}→go · mcpd-controller→mcpd · msh-{mcp-server,program}→msh · echo-bot-multibot-engine→echo (explicit guide) · {art,bcs,mesh}-course + bcs-family-tooling→echo (explicit BCS-umbrella guide) · {agile-course,redis-patterns-course,redis-reframe-echomq}→courses · {apollo-mentoring-loop,director-attribution,director-commits,spawn-resilience,workflow-heavy-agent,superpowers-plugin}→aaw.
- AMBIGUOUS — Director rules at dry-run (documented lean): cms-content-store-parity + jonnify-cms-toolchain→elixir (jonnify-cms exists to gate /elixir; vs go) · echo-static-server→echo-courses (Echo-server family; vs go) · echo-persistence-course→courses (it's a course; vs echo-courses) · course-nav-prose-no-redundant-status→elixir (elixir-course craft) · mcp-e2e-figure-validator→courses (validates course figures) · env-secret-inspection-safety + jonnify-gitignore-repo-wide-trap→aaw (cross-cutting operator/Director discipline — the two genuinely home-less notes, surface to Operator if consequential).

Carve-out reminder at apply: the backfill keys all 71 on disk; the rung commit excludes the 5 Operator-dirty memory files (MEMORY.md no-edit, mercury-design-system, mercury-visual-regression-harness, codemojex-program, codemojex-write-suite).

### T-4

T — Mars-1 build derivation (go-code half, D1–D8)

Realization decisions, each inside the brief's contract:
1. HELPER HOME: `command/project.go` already exists (the memory_project anchor tool), so the shared filter helpers landed in NEW `go/msh/memory/command/scope.go`: `normalizeProject` (the corpus.go classifyType lowercase+trim precedent, applied two-sided per spec §3.3), `filterNodesByProject(nodes, p)` (scan), `filterFindingsByProject(findings, g, p)` (stale POST-filter — allowed-path set built from g.Nodes(), rules always run over the FULL graph).
2. REF INJECTION: `utcToday()` homed in ops.go (UTC now → time.Date day-truncate). ALL FOUR production `stale.Run` call sites inject it once per invocation — cobra stale (stale.go), cobra audit (audit.go), ops.Stale, ops.Audit — per spec §3.5 ("ops.go:80,118 + the cobra stale/audit commands"). The rule itself never reads the clock; `AllRules(ref)` closes the review-due entry over ref, the seven existing rule funcs keep their exact signatures.
3. STATUS "PRESENT" SEMANTICS (contract-silent micro-decision): a trimmed-EMPTY `status:` value is treated as ABSENT (sniff fallback), because yaml.v3 cannot distinguish a null-valued key from an absent key on a plain string field; only a NON-EMPTY invalid value records the `invalid status %q: want active|superseded` FrontmatterError. G-5's four spec cases are unaffected.
4. `countByRule` DELETED from audit.go — its sole caller was the old DEAD-TARGET-only exit trigger (grep-verified); the new trigger is `counts[stale.SeverityError] > 0`, aligned to the Long at audit.go:17.
5. `Node.Project` stores the NORMALIZED effective project for BOTH branches (declared key + first path segment), computed once in loadCorpus — one authority (design §4.2); every filter compares normalized-to-normalized.
6. rules.go rewritten whole (not spot-edited): the file was gofmt-RED at HEAD (const-block misalignment); the rewrite adds RuleReviewDue + the ref threading and leaves the file gofmt-clean as the dispatch requires. context.go + extractor_test.go (pre-existing red, out of touch-set) untouched.
7. FIXED REFS in tests: stale-package `testRef` (rule_review_due_test.go) + command-package `fixedRef` (review_audit_test.go), both 2026-07-02 UTC; the four existing Run call sites in stale tests + two in integration_test.go gained the arg with zero import churn.
8. G-6 GOLDEN authored by hand from the deterministic message contract (Finding JSON field order + encoder escaping are struct-determined; note `snippet` has NO omitempty so `"snippet":""` appears) — matched byte-for-byte on first run; two-run byte-stability asserted in-test.

### T-5 — Director-run backfill dry-run complete (peer path abandoned after 2 documented stalls, P-2); apply pending Operator nod

Peer path: Mars-1 (SendMessage-resume) and Mars-2 (fresh spawn) both idled mid-wave without producing the table; Mars-2 completed only the backup (memory-backup/ = 72 md). Per cost-discipline (no more speculative fable spawns) + the read-only nature of the dry-run, the Director generated the table directly (LAW-1a: read-only analysis on memory/ DATA, not go/msh production code; the go-code implementation was genuinely peer-built by Mars-1). The apply will likewise be Director-run — a reviewed, D-1-authorized, scoped-commit-revertible data migration — surfaced to the Operator, not buried.

Dry-run (scratchpad/backfill.py, reusable dry/--apply): 71 notes = 25 R-1 (dir verbatim) + 46 R-2 (closed vocab). Anchors: all 71 carry exactly one top-level `metadata:` line (trailing-space `metadata: ` variant handled by rstrip); none missing/multiple; zero pre-existing project:. Before-leg audit (scratchpad/msh-gate new binary): 72 files, error=0 warn=0 info=1, no findings. Per-slug: aaw15 codemojex8 courses8 echo5 echo-courses2 echo_graft1 echo_mq9 elixir11 exchange1 figma-local1 go2 mcpd1 mercury5 msh2 = 71.

12 Director-ruled ambiguous rows (documented): →elixir {cms-content-store-parity, jonnify-cms-toolchain, course-nav-prose, user-commits-elixir-batches}; →aaw {env-secret-inspection-safety, jonnify-gitignore-repo-wide-trap, operator-runs-deploys, right-size-formation} (operator/agent discipline, no dedicated slug — the softest calls, flagged to Operator); →courses {echo-persistence-course, mcp-e2e-figure-validator}; →echo-courses {echo-static-server}; →codemojex {codemoji-design-system}. Commit carve-out (keyed on disk, excluded from the rung commit): codemojex-program, codemojex-write-suite, mercury-design-system, mercury-visual-regression-harness; MEMORY.md never edited.

## {msh2-2-decisions} Decisions

### D-1 — RULED: the S-4 fence is confirmed; msh2.2 ships now, same aaw topology

Operator ruling 2026-07-02 ("Ship msh.2.2 same aaw topology"): the rung whose definition IS the pre-announced memory/ mass edit is ordered shipped — the S-4 fence (roadmap Seams) is thereby re-confirmed for this run. Discipline unchanged and binding: staged script (throwaway; msh itself stays read-only, design §4.1), tree backup, byte-diff review (frontmatter-only changes on every touched note), msh memory audit = 0 errors before AND after, MEMORY.md untouched by tooling, git diff memory/ presented to the Operator (scoped commit keeps post-hoc review + revert trivial). Formation = the same aaw-ledgered topology as the genesis run: real spawned peers on fable, self-registered on this scope, Director gates independently, LAW-4 pathspec commits per concern.

### D-2 — RULED: an Operator verification gate follows the Venus triad

Operator ruling 2026-07-02 ("Pause after Venus before review, Operator must verify first"): when venus-22 delivers the msh2.2 triad, the run HALTS — the Director presents the triad (S-2 settlement, key placement, review-due determinism mechanism, backfill mapping rules) and waits. The Director's independent review, the Mars dispatch, and any memory/ touch proceed only on the Operator's explicit go. This gate is additive to the S-4 discipline (D-1), not a replacement.

## {msh2-2-progress} Progress

### P-1 — Venus triad landed; run PAUSED at the D-2 Operator gate

venus-22 delivered specs/msh2.2.md (235 ln) + msh2.2.stories.md (124 ln, S-1..S-13) + msh2.2.llms.md (86 ln); msh specs msh clean at error severity. Her settlements pending Operator verification: S-2 = scalar project: + degrade (declared key → first path segment → unscoped) with stale POST-filtering; v2 keys TOP-LEVEL only (metadata: stays the provenance drawer); review-due = injected day-granular ref date through stale.Run (no clock in rules), warn when due, unparseable = ERROR + the audit.go:17-vs-44 exit-contract alignment (D6); backfill = project: on all 70 (R-1 dir-verbatim ×25, R-2 closed-vocabulary table ×45, Director-reviewed dry-run), ZERO status:/review_after: writes (sniff census = 0; tombstone ruled ACTIVE), carve-out pathspecs the 2 dirty + 1 untracked notes out of the commit. Reconcile deltas she caught: 69→70 note count; stale sniff-census assumption; audit doc-vs-code mismatch. Per D-2: no Director review, no Mars dispatch, no memory/ touch until the Operator rules.

### P-2 — Backfill dry-run: Mars-1 idled "available" WITHOUT executing the wave (SendMessage-resume did not activate it)

Recovered from the tree per the spawn-resilience discipline (never trust the message layer): memory/ UNTOUCHED (only the 5 Operator-dirty files present, ZERO project: keys — grep clean); no memory-backup/ dir; no dry-run script or table artifact in the scratchpad; no dry-run T/L/Y on the ledger. The wave did not run — no partial state to clean up (the dry-run is read-only by design).

Action: not gambling on message-resume. Spawning Mars-2 — a FRESH real fable aaw spawn (a distinct memory-data-half implementor; a real Agent spawn, NOT FAKE-N) — with a write-ready dispatch that WRITES the full note→slug table to a KNOWN scratchpad path (scratchpad/backfill-dryrun-table.md) so the mapping is recoverable from disk if the report is lost again. Mars-1 stays idle; the dry-run is read-only, so no race risk on memory/. Next: Mars-2 backup → before-leg audit (new binary) → dry-run table → STOP; Director diffs vs the T-3 expectation, rules ambiguous rows, presents to the Operator before the S-4 apply.

### P-3 — Apollo (3rd fable spawn) idled "available" producing NOTHING: tree-verified no aaw registration, no spec-sync (§2 still "70 notes", §5 still "the three", roadmap still 📋), no ledger entry, no backup. Three fable peer waves have now stalled on multi-step file/script work (Mars-1 backfill-resume, Mars-2, Apollo); only Mars-1's initial go-code build completed + reported.

Decision: no 4th speculative spawn (cost-discipline). The Director ABSORBS the residual §2.4 evaluator duty. Justification: the independent verification is already done and EXCEEDS a standard Apollo pass — Y-2 (fresh `go test -count=1` gate + full spec↔code reconcile + a net-zero boundary mutation killing 2 tests, kill-rate 1→2) + Y-3 (backfill pure-insertion proof, status parity, before/after-leg audit parity). What remains is the mechanical spec-sync — a factual reconcile-to-as-shipped on the spec triad (docs, NOT go/msh production code; the go-code implementation was genuinely peer-built by Mars-1). Documented deviation from the Apollo-mandatory formation, forced by the fable stall pattern; surfaced to the Operator, not buried. Next: spec-sync (§2 census, §5 carve-out, S-13, before-leg count, roadmap row), one final independent gate, a Y-4 consolidated verdict, then the 2 LAW-4 pathspec commits.

## {msh2-2-learnings} Learnings

### L-1 — Two reconcile deltas since the Venus triad (hours), both Director-carried into the Mars dispatch (no re-spawn of Venus; Apollo spec-syncs at close)

(1) gofmt RED at HEAD. `gofmt -l . | grep -v vendor` flags THREE files BEFORE any edit: memory/internal/linkx/extractor_test.go, memory/internal/stale/context.go, memory/internal/stale/rules.go (pure gofmt alignment — e.g. the rules.go const block's `=` columns). rules.go is IN the touch-set (REVIEW-DUE edit → gofmt-clean as a side-effect). context.go + extractor_test.go are OUT of the touch-set → RECORDED pre-existing, NOT repaired in-rung (program §3 do-no-harm; island = go/msh but do-no-harm fences untouched files). Honest gate report: "gofmt silent for every rung-touched file; 2 documented pre-existing HEAD findings in untouched files." This is a latent gate miss from a prior rung (committed un-gofmt'd); flagged to the Operator as an optional separate hygiene cleanup, not this rung.

(2) Corpus + dirty-tree drift. Spec §2 census 70 notes / 71 files → live 71 notes / 72 files (+1: memory/codemojex-write-suite.md, untracked Operator note). Spec §5 carve-out named 3 dirty memory files → live 5: MEMORY.md (no edit — the hand index), mercury-design-system.md (mod), mercury-visual-regression-harness.md (untracked), + codemojex-program.md (mod) + codemojex-write-suite.md (untracked) — the last two joined the Operator [memory] batch AFTER Venus wrote §5. The backfill is count-agnostic (§5 R-2 derives the enumeration at apply time), so it keys the live 71 on disk; the rung commit carves ALL 5 Operator-dirty files out (they ride the Operator's own batch — the §5/S-13 rule extended from 3→5). Also dirty out-of-band and carved by pathspec: cmd/history.go, cmd/history_test.go, and the wider codemojex/mercury/html/docs churn.

### L-2

L — Mars-1 build surprises (msh2.2 go-code)

1. NAME-COLLISION TRAP AVERTED BY A 1s LISTING: the brief said "one shared filterNodesByProject helper in `command`" — the natural file name `project.go` ALREADY EXISTS there as the memory_project anchor tool. A pre-write `ls` of the package dir (not a read) caught it; the helper landed in `scope.go`. Cheap directory listings before creating "obviously free" filenames pay for themselves.
2. GOLDEN-FIRST AUTHORING IS VIABLE for encoding/json NDJSON goldens: field order follows the struct declaration, `%q` quotes JSON-escape to \", and the one non-omitempty string (`snippet`) must appear as `"snippet":""`. The hand-authored golden matched the first real run byte-for-byte — no update-flag scaffolding needed.
3. THE BRIEF'S GOFMT CENSUS HELD EXACTLY: `gofmt -l` at HEAD flagged precisely the predicted three files; rewriting rules.go whole (rather than spot-editing the const block) was the cheapest way to leave the one in-touch-set red file clean without reflowing the two out-of-set ones.
4. yaml.v3 STRING FIELDS CANNOT SEE KEY PRESENCE: `status:` (null value) and an absent key both decode to "" — so "present + invalid" is only detectable for non-empty values. Recorded as the trimmed-empty≡absent realization in T; a future strict mode would need a *string or yaml.Node field.

## {msh2-2-report} Report

### Y-1

Y — Mars-1 final: msh2.2 go-code half BUILT + GATE GREEN (D1–D8)

D1 parser v2: Frontmatter + rawFrontmatter gain Project/Status/ReviewAfter, top-level only, no metadata: coalesce (parse.go); old keys byte-unchanged. D2 node surface: Node.Project + Node.ReviewAfter (omitempty); loadCorpus computes normalized effective_project (declared → first path segment → unscoped), status precedence per §3.4 (valid declared wins + sniff skipped; invalid → FrontmatterError + sniff; absent → sniff byte-unchanged, isSupersededByText untouched). D3 scoped scan: --project flag + scanArgs.Project + Scan(root, format, project) + shared filterNodesByProject in new command/scope.go + PROJECT column after STATUS. D4 scoped stale: --project + staleArgs.Project + Stale(..., project) POST-filtering findings via filterFindingsByProject (full-graph rules, view-only filter); memory_audit unscoped. D5 REVIEW-DUE: new rule_review_due.go (warn on !ref.Before(date), fires ON the day; error on unparseable; superseded skipped; keyless skipped); RuleReviewDue const; AllRules(ref)/Run(...,ref); the rule never reads the clock — utcToday() injected once per invocation at all four production call sites. D6 audit exit: ANY error-severity count > 0 (dead countByRule deleted). D7 docstrings: scan/stale MCP descriptions + CLI Longs name project/status/review_after + REVIEW-DUE. D8: TestToolCountPin untouched, PASS at 8.

Tests: G-1 (2 parser tests), G-2 (scoped scan CLI+ops parity), G-3 (post-filter invents nothing — p linked only from q), G-4 (degrade order), G-5 (4 status-precedence cases), G-6 (testdata/review_due 5-note fixture + hand-authored golden, two-run byte-stable), G-7 (audit non-zero on invalid review_after + clean-corpus pass). All fixtures = temp dirs / testdata; live corpus untouched (memory/ NOT edited — backfill is not this wave).

GATE (verbatim): GOWORK=off go build -o $TMPDIR/msh-gate ./cmd → OK; GOWORK=off go vet ./... → OK; GOWORK=off go test ./... → ok × 11 packages; new tests verified by name (7 command + 3 stale incl. 6 subtests + 2 frontmatter, all PASS); 5× -count=1 loop on command+stale clean; gofmt -l → only the two pre-existing out-of-set files (extractor_test.go, context.go), rules.go now clean. No git run; tree left for Director ratification. make mcp / live smoke deferred to the Director per dispatch.

### Y-2 — Director Stage-3 solo review: the go-code half is BUILD-GRADE (no remediation)

Independent (not a glance at Mars's Y-1): fresh `go test -count=1 ./...` GREEN across 11 packages; build+vet clean; gofmt shows exactly the 2 pre-existing untouched files (rules.go rewrite cleared its own red). Attribution vs the green-before baseline: every tracked change is inside the touch-set; scope.go/rule_review_due.go/testdata new; cmd/history.go+history_test.go stay ?? untouched; memory/ untouched.

Prompted-checks table (each PASS w/ evidence): D1 top-level-only parse — parse.go:90-92 assign raw.Project/Status/ReviewAfter directly, NO coalesce (old keys still coalesce :86-87). D2 effective_project — corpus.go:67-71 declared→SplitN(rel,"/",2)[0]→"" ; two-sided normalize (:56/:69 + scope.go:22). D2 status precedence — corpus.go:76-93: valid declared sets statusDeclared→sniff SKIPPED; invalid → FrontmatterError(:87)+sniff runs; absent/empty → sniff. Sniff DEMOTED not deleted — only the call site gained `!statusDeclared &&` (:91); isSupersededByText body byte-identical to HEAD. D4 post-filter — scope.go:40-58 filters findings by File's project over the FULL-graph run; audit stays unscoped (ops.Audit/cobra audit no project). D5 REVIEW-DUE — rule_review_due.go: skip superseded/empty, parse 2006-01-02, unparseable→error, !ref.Before(date)→warn; NEVER reads clock (grep: sole clock read is ops.go:19 utcToday, injected at 4 sites rules.go:56/AllRules ref-closure). D6 audit exit — audit.go:47 counts[SeverityError]>0. D8 pin — mcp_test.go NOT in diff, cmd pkg green.

Un-prompted findings: (a) graph.Nodes() sorts by Path (graph.go:51) → determinism is structural, not luck (the direct-call determinism test is well-founded). (b) countByRule fully removed, no dangling ref (grep clean) — Mars realization #3 correct dead-code removal. Attack that HELD: mutated `!ref.Before(date)`→`ref.After(date)` (due stops firing on the boundary day) — KILLED TestRuleReviewDueStories/boundary + TestReviewDueGoldenByteStable; restored byte-exact (pre==post sha 073f1f42). Mutation kill-rate: 1 mutant → 2 tests killed (boundary is guarded).

Realizations accepted: empty status→sniff (yaml string can't distinguish null from absent; the only Go-idiomatic behavior; all four §3.4 cases use non-empty `retired`, unaffected); helper home command/scope.go (command/project.go already taken by the memory_project tool); 4 ref-injection sites (matches §3.5's fuller enumeration, body wins over the brief's 2-site note). Open: G-9 live smoke deferred to Director at ship (the exact ops.Scan path is already unit-proven — scope_test.go:93). Next: Mars memory-data half (backfill dry-run, STOP at the table).

### Y-3 — Backfill APPLIED + verified (Director-run under S-4; Operator-authorized "yes, apply")

71 notes keyed (25 R-1 dir-verbatim + 46 R-2 closed-vocab) via scratchpad/backfill.py --apply. Verification, all PASS:
(a) 71 `^project:` keys present (grep).
(b) PURE insertions — the 66 clean notes each add EXACTLY one `+project: <slug>` line vs HEAD (git per-note check, zero offenders); the keyed-dirty notes carry my lone project: line + the Operator's separate edits.
(c) STATUS parity — ZERO status diffs pre(backup)/post(live), 72/72 nodes, same binary scan (no status: written, bodies unchanged → sniff unchanged).
(d) after-leg audit = 72 files error=0 warn=0 info=1 — IDENTICAL to the before-leg (G-10 "counts unchanged" satisfied).

Commit set = the 66 numstat=='1 0' notes. Carve-out (6, ride the Operator [memory] batch): MEMORY.md (never keyed — the hand index), codemojex-program.md + mercury-design-system.md + mercury-dual-vitest-jestdom-trap.md (keyed + Operator-modified), codemojex-write-suite.md + mercury-visual-regression-harness.md (keyed, untracked). The entangled tree MOVED during the rung — the Operator dirtied mercury-dual-vitest-jestdom-trap.md AFTER the backup; the git-computed (not hardcoded) commit set caught it automatically, so no Operator edit can leak into the rung commit. Next: Apollo §2.4 verdict + spec-sync (§2 census 70→71, §5 carve-out 3→6, S-13, G-10 counts, roadmap row → SHIPPED).

### Y-4 — VERDICT: msh2.2 BUILD-GRADE (Director-absorbed §2.4 evaluator pass; Apollo stalled, P-3)

§11.2 charter, consolidated across Y-2/Y-3 + the final post-spec-sync re-run:
- Prompted-checks: D1–D8 all PASS w/ file:line (Y-2). Backfill G-10 PASS (Y-3: 71 keys, pure insertions, status parity, audit 72 files error=0 before==after). Final independent gate: build+vet OK, `go test -count=1 ./...` green ×11 pkgs, gofmt = only the 2 pre-existing untouched files (context.go, extractor_test.go); tool pin stays 8.
- Un-prompted findings: graph.Nodes() sorts by Path → determinism structural not luck; countByRule fully removed (grep clean); the entangled tree MOVED mid-run (mercury-dual-vitest-jestdom-trap joined the Operator batch post-backup) — caught automatically by the git-computed commit set.
- Attack that HELD: boundary mutation `!ref.Before(date)`→`ref.After(date)` killed TestRuleReviewDueStories/boundary + TestReviewDueGoldenByteStable; restored byte-exact (sha 073f1f42). Mutation kill-rate: 1 mutant → 2 tests.
- Spec-sync (Director factual reconcile-to-shipped): msh2.2.md §2 (71/72 census) + §5 (carve-out 3→6) + before-leg (72 files) + R-2 (46 flat); stories S-13 (six files); roadmap row → ✅ SHIPPED.
Verdict: BUILD-GRADE. Ships via 2 pathspec commits (A: backfill 66 notes | B: rung code+triad+ledger+roadmap).

## {msh2-2-complete} Complete

### Z-1 — msh2.2 COMPLETE + shipping

Delivered: frontmatter v2 (project/status/review_after, top-level only) + scoped memory_scan/memory_stale (--project; scan filters nodes, stale POST-filters findings) + status: retires the 1KB sniff to the absent-key fallback (byte-unchanged) + NEW REVIEW-DUE rule (clock-free, injected ref) + audit-exit honesty (D6) + the 71-note memory/ backfill (project: keyed, ZERO status/review_after). All Director-verified BUILD-GRADE (Y-4).

Gates: go build/vet/`test -count=1` green ×11 pkgs; gofmt clean modulo 2 pre-existing untouched files; tool pin stays 8; determinism golden byte-stable; before==after-leg audit 72 files error=0.

Formation deviation (documented, not hidden): 3 fable peer waves stalled (Mars-1 backfill-resume, Mars-2, Apollo — P-2/P-3) → the Director absorbed the backfill apply + the §2.4 evaluator duty + the spec-sync; the go-code (the implementation) was genuinely peer-built + peer-tested by Mars-1.

Decisions locked: D-1 (S-4 fence; ship), D-2 (Operator verify gate — released by "Ship msh2.2.md" + "yes, apply"). Shipping NOW via 2 LAW-4 pathspec commits per D-1 "commits per concern": (A) backfill = the git-computed 66 pure-insertion notes; (B) rung = go/msh touch-set (excl cmd/history.go + history_test.go, out-of-band) + triad + progress ledger + roadmap row. The 6 Operator-dirty memory files ride the Operator's own [memory] batch. NOT pushed (ask first).
