# ewr-1-2 — AAW scope ledger

## {ewr-1-2-thinking} Thinking

### T-1 — ewr.1.2 fork framing: derivation trace (reconcile + Arms)

LAG-1 RE-PROBE (as-built floor, confirmed + cited):
- EchoWire.Pipe SHIPPED (echo/apps/echo_wire/lib/echo_wire/pipe.ex): %Pipe{conn, via, timeout, cmds:[]}; cmds is a list of command-lists, prepend-newest-first via private add/2 (pipe.ex:538), Enum.reverse'd at flush; curated six-family verbs; command/2 (pipe.ex:490) appends a raw [binary|integer|atom] list; exec/1 (pipe.ex:503) = via.pipeline(conn, Enum.reverse(cmds), timeout); exec_txn/exec_noreply → EchoMQ.Connector directly. MATCH.
- valkey-go Completed = {cs *CommandSlice; cf uint16; ks uint16} (cmds.go:117) — parts + flags + slot. cf consts cmds.go:5-23 (optInTag .. retryableTag/staticTTLTag). Accessors IsReadOnly/IsBlock/IsPipe/NoReply/IsRetryable/IsStaticTTL cmds.go:147-200. Slot() cmds.go:210; slot(key)=crc16(key or {hashtag}) & 16383 (slot.go:5). MATCH.
- CRITICAL MECHANISM FACT: the cf flag is set PER-BUILDER-VERB at construction, not computed at runtime. gen_string.go:231 `Builder.Get()` → `Get{cs:get(), ks:b.ks, cf:int16(readonly)}`; `Set()` leaves cf zero (write). Build() (gen_string.go:37) = `Completed{cs:c.cs, cf:uint16(c.cf), ks:c.ks}`. So a faithful Elixir port derives flags from a STATIC per-verb table (GET→readonly, SET→write), NOT a parse of parts. This is the load-bearing port fact.
- ks (slot) is computed from the key per command (SetSlot(key), slot.go). A pure function of the command's key.

THE FORK (integration of the Completed port with the as-built Pipe). Three arms drafted, all additive above the conformance boundary, no facade growth, no frozen-runtime/Lua touch, conformance {:ok,52} byte-stable:
- Arm 1: new EchoWire.Command value module (%Command{parts, flags, slot}) + a Pipe seam (command/2 accepts %Command{} in addition to a raw list; exec extracts .parts). Minimal, additive, leaves ewr.1.1 verbs untouched. RECOMMENDED.
- Arm 2: enrich the curated Pipe verbs to emit %Command{} internally (per-verb flags). Richer but touches ewr.1.1's shipped verbs — fights the additive-minor stance + the frozen-floor re-pin.
- Arm 3: a standalone EchoWire.Cmd builder surface parallel to Pipe — two construction surfaces, the rejected design-fork Arm B reincarnated.

RECOMMENDATION: Arm 1 (one reason: it is the only arm that adds the rueidis Completed VALUE without re-opening ewr.1.1's shipped verb bodies — the command value is born pure, Pipe gains one accept-a-%Command{} seam, and Arms 2/3 remain layerable on top later, exactly the "A keeps both other arms available" logic the design fork already ruled).

SUB-QUESTION for the Operator (genuine, ewr.design seam 4 deferral): full cf vocabulary now (all ~8 tags ahead of any consumer) vs a minimal command value now (parts + slot + a small advisory flag set: readonly/write + block, grown when a retry/cluster rung consumes them). Recommend MINIMAL-NOW — the flags are advisory this rung (no consumer), and a wrong-frozen-contract risk (is EVAL-of-RO-script readonly?) argues against shipping the full vocabulary ahead of its reader. Surfaced, not decided.

NO-INVENT posture: every public surface forward-tense SPECCED (EchoWire.Command unbuilt); cited pipe.ex + cmds.go/slot.go/gen_string.go anchors.

### T-2 — Operator RULED Arm 3 + full-cf-now (NOT the Arm 1 + minimal-now recommendation). Re-author trace.

RE-PROBE for the ruling (the two facts the re-author depends on, both confirmed against source):
- CONFORMANCE DRIFT CONFIRMED: {:ok, 53}, not 52. conformance_run_test.exs:46 `Conformance.run(conn, q) == {:ok, 53}`; conformance_scenarios_test.exs:19 "(run/2 → {:ok, 53})"; conformance.ex:3 "fifty-three runnable scenarios", :131 "n == 53 today". The 52→53 drift is emq out-of-band (one new scenario). Wire registers NONE; the count is emq-owned, byte-stable from the wire's side. PIN 53 throughout (my draft said 52 — STALE, now corrected).
- FULL cf CONSTANTS CONFIRMED (cmds.go:5-23): optInTag 1<<15 · blockTag 1<<14 · readonly 1<<13|retryableTag · noRetTag 1<<12|readonly|pipeTag · mtGetTag 1<<11|readonly · scrRoTag 1<<10|readonly · unsubTag 1<<9|noRetTag · pipeTag 1<<8 · retryableTag 1<<7 · staticTTLTag 1<<6. CRITICAL: composite bit-inclusion — readonly INCLUDES retryableTag (a read is retryable?); noRetTag includes readonly|pipeTag; unsubTag includes noRetTag. A faithful port mirrors the inclusion (predicate readonly?→implies retryable?). Plus InitSlot 1<<14 / NoSlot 1<<15 (slot sentinels, ks not cf).
- BUILDER CHAIN SHAPE CONFIRMED (gen_string.go): rueidis is a TYPE-STATE chain — Builder.Set() :? → Set.Key(k) :1487 → SetKey.Value(v) :1956 → SetValue.ExSeconds(s) :1998 / SetValue.Build() :2043. Flag stamped at the verb-builder: Set() leaves cf zero (write); Get() stamps cf:int16(readonly) gen_string.go:231. INV3 holds (static per-verb, never parsed from parts). The Elixir port reimagines the type-state chain as `|>` (the design doc already noted dynamic Elixir cannot enforce the compile-time type-state — build/1 is a runtime closing token, a known Arm-3 cost the Operator accepted).

ARM 3 framing decision: design-Arm B REALIZED — EchoWire.Cmd (the fluent builder) + EchoWire.Command (the value it builds) is the additive command-value SIBLING to Pipe, the design fork's "B layers on later" promise made real, NOT a reopening of Arm A. Pipe stays the primary BATCH surface; Cmd is the per-COMMAND value+builder surface. run/2 lives on EchoWire.Cmd (NOT a 12th facade verb — ewr.design §4 correction). The Pipe seam (one additive command/2 head accepting %Command{}) is unchanged from the Arm-1 draft — it is how a built Cmd composes into a Pipe batch.

MODULE SPLIT (design-make to leave to Mars, but recommend): EchoWire.Command = the value (%Command{parts,flags,slot} + predicates + slot/1/parts/1); EchoWire.Cmd = the fluent builder verbs (set/value/ex/build + the six families) + run/2 dispatch. Two modules: the value is the noun, the builder is the verb-chain that mints it + runs it.

Files to update: ewr.1.2.design.md (mark Arm 3 + full-cf RULED, losing arms keep their case) + re-author ewr.1.2.{md,stories,llms,prompt}.

## {ewr-1-2-progress} Progress

### P-1 — ewr.1.2 design doc + triad authored (SPECCED, recommended-arm draft). Fork FRAMED, not decided.

DELIVERED (5 files, docs/echo_mq/wire/specs/ewr.1/):
- ewr.1.2.design.md — four-part Arms (Rationale/5W/Steelman/Steward each), recommendation Arm 1 (advice), the full-cf-now/minimal-now sub-question surfaced for the Operator. Mirrors ewr.design.md surfaced-fork shape.
- ewr.1.2.md — body (Goal · 5W · Scope · D1-D7 · INV1-INV9 · closed error set · DoD), forward-tense SPECCED, Arm 1 + minimal-now.
- ewr.1.2.stories.md — US1-US11 + US-GATE (Connextra + G/W/T), Coverage line; byte-equivalence the load-bearing proof.
- ewr.1.2.llms.md — References/Requirements(R1-R9)/topology/files/two-app gate.
- ewr.1.2.prompt.md — runbook, scope slug ewr-1-2, pre-Stage-1 OPEN fork gate (AskUserQuestion: arm + sub-question), five stages.

RECONCILE (lag-1, all MATCH/confirmed): EchoWire.Pipe command/2 @ pipe.ex:490, add/2 @:538, exec/1 @:503/:501, @type command @:50. valkey-go Completed @ cmds.go:117, cf consts :5-23, accessors :147-210, slot.go:5, gen_string.go:231 per-verb stamp + :37 Build(). LOAD-BEARING port fact captured: cf flag is STATIC per-verb (Builder.Get→readonly), never parsed from parts → INV3. All relative links resolve; all citations verified against source; framing clean.

VERDICT: BUILD-GRADE for the recommended arm, BUT gated on the Operator's fork ruling (arm 1/2/3 + full-cf/minimal). No D-n locked (the fork is the Operator's via Director AskUserQuestion). Triad revised if a different arm/depth is ruled.

Expected Mars touch-set: NEW echo/apps/echo_wire/lib/echo_wire/command.ex + test/echo_wire/command_test.exs; EDIT pipe.ex (ONE additive command/2 head, added-lines-only); NEW echo_mq/test/stories/wire_pipe_command_*_story_test.exs; GEN docs/echo_mq/wire/stories/wire-pipe-command-*.stories.md. No frozen-runtime/facade/mix.lock/echo_mq-lib edit. Gate: two-app ladder + --match wire_pipe idempotent regen + bus-dir-byte-unchanged + multi-seed sweep (no ≥100 loop — no id-mint/process/lease).

### P-2 — ewr.1.2 triad RE-AUTHORED for the ruled arm (Arm 3 + full-cf-now), superseding the P-1 Arm-1 draft.

RULING ADOPTED (Operator, 2026-06-18): Arm 3 (standalone EchoWire.Cmd fluent builder + EchoWire.Command immutable value) + FULL cf vocabulary now. NOT Venus's Arm 1 + minimal recommendation. Framed as design-Arm B realized (the additive command-value sibling to Pipe; Pipe stays the primary batch surface) — extends the chapter ruling, does not reopen Arm A.

FILES UPDATED (docs/echo_mq/wire/specs/ewr.1/):
- ewr.1.2.design.md — header + §3 + §4 now record the RULING (Arm 3 + full-cf), the full cf table with bit-inclusion, the type-state→|> port; losing Arms 1&2 keep their Steelman/Steward as the record of why. Fixed §1 conformance 52→53.
- ewr.1.2.md — full rewrite: TWO modules (EchoWire.Command value + EchoWire.Cmd builder/runner), full cf vocabulary (10 tags, bit-inclusion preserved: readonly⇒retryable), the set|>value|>build chain, run/2 on EchoWire.Cmd (NOT facade), the one additive Pipe.command/2 head. D1-D7, INV1-INV9, closed error set (+build/1 runtime-token errors), DoD. Conformance {:ok,53}.
- ewr.1.2.stories.md — US1-US13 + US-GATE: builder chain, full-cf bit-inclusion truth table, run/2 both-targets, byte-equivalence via run/2 AND Pipe.command/2, Coverage line.
- ewr.1.2.llms.md — References/Requirements R1-R10/topology/touch-set/gate, full cf table, type-state chain citations, {:ok,53}.
- ewr.1.2.prompt.md — Stage-0 = RULED (no open gate now), five stages, two modules, the two care-points (pipe.ex added-lines-only + run/2-not-facade), {:ok,53}.

CORRECTIONS FOLDED + VERIFIED against source:
- CONFORMANCE 52→53 confirmed (conformance_run_test.exs:46 == {:ok,53}; conformance.ex:3,131 "fifty-three"). Pinned 53 throughout; framed as emq-owned, wire registers none.
- FULL cf constants confirmed (cmds.go:5-23) incl. bit-inclusion (readonly=1<<13|retryableTag etc.) — INV3 keeps it.
- TYPE-STATE chain citations confirmed (gen_string.go:1487/1956/1998/2043 Set→SetKey→SetValue→Build, :231 per-verb stamp).
- run/2 on EchoWire.Cmd, EchoWire.run/2 must NOT exist — affirmed all 5 files (INV1).

VERIFY: all relative links resolve; no stray 52 (only "drift from 52" provenance); framing clean (the 2 "sees" hits describe the wire/code, not agents). BUILD-GRADE for the ruled arm.

REVISED Mars touch-set: NEW echo_wire/lib/echo_wire/command.ex + cmd.ex + test/echo_wire/{command,cmd}_test.exs; EDIT pipe.ex (ONE additive command/2 head, added-lines-only); NEW echo_mq/test/stories/wire_pipe_command_*_story_test.exs; GEN docs/echo_mq/wire/stories/wire-pipe-command-*.stories.md. Gate: two-app ladder + full predicate truth table (bit-inclusion) + builder-chain + run/2-vs-bare-verb equivalence + --match wire_pipe idempotent + bus-dir-byte-unchanged + conformance {:ok,53} + facade-11 (run/2 absent) + multi-seed sweep (no ≥100 loop).

### P-3 — Mars-1 self-verify COMPLETE, idle pending Director review. Both ewr.1.2 + ewr.1.3 built in one pass (shared echo_wire app). Gates: echo_wire compile-WAE clean + 109/0 (5/5 multi-seed); echo_mq compile clean + 380 tests/4 doctests/0 fail + CONFORMANCE 54/54; --match wire_pipe regen idempotent (diff -r ×2 clean) + bus dir byte-unchanged + default emits 13 features. Byte-equivalence proven (52B RESP frame identical, flagged %Command{} == bare verb, 3 ways live). Mutation kill-rate 3/3 (static-per-verb INV3, partition INV4, seam-drop byte-equiv), all net-zero reverted. Touch-set = command.ex+cmd.ex+result.ex+3 test files + 2 story files + 1 additive pipe.ex command/2 head (@spec widened 1 line) + 2 gen stories; NO frozen-runtime/facade/mix.lock/echo_mq-lib. FLAG to Director: conformance triad-pin 53 is STALE, as-built 54 (emq.4.1 drift) — gated on 54, doc sync owed. Director review next (independent gate re-run + adversarial probe + net-zero spot-check), then Mars-2 remediate/harden, then Venus reconcile (incl. the 53→54 sync).

### P-4 — ewr.1.2 TRIAD reconciled SPECCED→BUILT (do-no-harm; the 4 triad files only). Director owns Z-1 + floor-doc sync + commit.

AS-BUILT RE-PROBED + FOLDED (verified against source, not taken on faith):
- EchoWire.Command (command.ex): flags = INTEGER BITFIELD with bit-inclusion baked into the constants (@readonly=(1<<<13)|||@retryable :57; @noreply⊇@readonly|@pipe :58; @unsub⊇@noreply :61; @mt_get/@scr_ro⊇@readonly :59-60). Predicates subset-match (f &&& tag == tag, :144-188) → readonly?⇒retryable? holds FOR FREE (INV3 is a property of the constants, no separate check). slot = CRC16-XMODEM (:278-279 the bxor/<<<8 loop, @crc16tab) with {hashtag} rule (:212). Confirmed the body's framing.
- EchoWire.Cmd (cmd.ex:570 run/2). EchoWire.run ABSENT (lib/echo_wire.ex grep 0) — facade stays 11.
- Pipe.command/2 (pipe.ex): ONE additive head + @spec command(t(), command() | EchoWire.Command.t()) widening + extended @doc (added lines); struct/verbs/add/exec byte-identical to HEAD. Confirmed.
- Conformance is now 54 (conformance_run_test.exs:47 {:ok,54}; conformance.ex:3,135 "fifty-four") — the 52→53→54 drift is LIVE.

THE DURABLE FIX (value-free conformance): removed EVERY numeric conformance pin from all 4 triad files. Replaced with "conformance stays byte-stable — the wire registers no scenario and writes no registry.json; the count is emq-owned (drifted 52→53→54 within this program's life — not the wire's to pin)". The only number now is "currently 54" as an explicit gate-floor read (one per file, llms twice). Verified: grep for {:ok,5N}/byte-stable-at-5N across the 4 files = ZERO.

FRAME + DoD:
- SPECCED→BUILT flipped in all 4 (md/stories/llms/prompt headers). The 2 residual "SPECCED" in prompt.md are the Stage-4 runbook NARRATING the reconcile action ("flip the frame SPECCED→BUILT") — correct, kept. Fixed the stale llms framing-clause ("forward-tense SPECCED until shipped" → "now shipped, present-tense, verified at .../command,cmd.ex").
- As-built reconcile NOTE added to the body header (the bitfield/bit-inclusion-in-constants, CRC16-XMODEM + vectors, run/2-not-facade, the one Pipe seam + @spec widening; the gate: echo_wire 109/0 facade-11 EchoWire.run absent, wire :valkey stories 8/0, conformance byte-stable, byte-equivalence proven, INV3+INV4 mutations KILLED). Stories + llms + prompt headers carry the same outcome line.
- DoD: all 9 [ ]→[x], wording tightened to as-built (the realized bitfield, 109/0 + 8/0, mutations killed).

VERIFY: zero numeric conformance pins; all 4 BUILT-framed; DoD 9/9 checked; all relative links resolve; framing clean. Edited ONLY the 4 triad files (no ledger, no floor-doc, no code, no git — yours).

## {ewr-1-2-decisions} Decisions

### D-1 — EWR.1.2-D1 design-make RULED (Mars-1, before any .ex/test artifact). Arm 3 + full-cf adopted (Operator ruling 2026-06-18), not re-litigated.

LAG-1 RE-PROBE (as-built floor, all confirmed at build time):
- pipe.ex: %Pipe{conn,via,timeout,cmds:[]}; command/2 @:489-490 (`command(pipe, parts) when is_list(parts), do: add(pipe, parts)`); add/2 @:537-538 (prepend-newest-first); exec/1 @:500-505 (empty-guard @:501 → {:error,:empty_pipeline}; else via.pipeline(conn, Enum.reverse(cmds), timeout)); @type command @:50 = [binary()|integer()|atom()]. MATCH.
- valkey-go cf consts cmds.go:5-23 with bit-inclusion: optInTag 1<<15 · blockTag 1<<14 · readonly 1<<13|retryableTag · noRetTag 1<<12|readonly|pipeTag · mtGetTag 1<<11|readonly · scrRoTag 1<<10|readonly · unsubTag 1<<9|noRetTag · pipeTag 1<<8 · retryableTag 1<<7 · staticTTLTag 1<<6. Accessors cmds.go:147-212 use SUBSET-match (`c.cf & TAG == TAG`), NOT single-bit. slot.go:5 = crc16(key or {hashtag-inner}) & 16383 (CCITT/XMODEM, "123456789"→0x31C3=12739).
- Per-verb stamp (gen_*.go): reads = readonly; MGET = mtGetTag; blocking (BLPOP/BRPOP/BLMOVE/BLMPOP/BZPOPMIN/BZPOPMAX/BZMPOP) = blockTag; SUBSCRIBE/PSUBSCRIBE/SSUBSCRIBE = noRetTag; UNSUBSCRIBE/PUNSUBSCRIBE/SUNSUBSCRIBE = unsubTag; writes = cf 0. Confirmed gen_string.go:232, gen_set.go, gen_sorted_set.go:10/105/157, gen_pubsub.go:8/323/398, gen_list.go:10/192.

DESIGN-MAKE (the implementor's, ruled):
(D1a flag representation) `flags` = an integer bitfield mirroring cf uint16 EXACTLY (the rueidis constants ported as module attrs with their bit-inclusion: @readonly = 1<<13 ||| @retryable). Chosen over MapSet/keyword because the bit-inclusion semantics (readonly ⊇ retryable; noreply ⊇ readonly|pipe; unsub ⊇ noreply) are PRECISELY the integer subset-match `flags &&& tag == tag` — porting the bitfield is the faithful, least-translation realization, and predicates are one-liners that cannot drift from the inclusion. Predicates read the bitfield via subset-match exactly as cmds.go:147-212.
(D1a flags STATIC per-verb) flags come from a static per-verb table keyed by the builder verb (a `@flags %{get: @readonly, set: @write, ...}` map, looked up by the verb ATOM the opener carries), NEVER parsed from parts. INV3.
(D1a slot) slot/1 = a pure crc16-xmodem(key | {hashtag}) &&& 16383 port of slot.go, a 256-entry table; nil when no key. Ground vector: slot("123456789")==12739; slot("{user}:1")==slot("{user}:2").
(D1d builder chain) verb-opener (e.g. set/1, get/1) returns an un-built builder = a SECOND struct %EchoWire.Cmd{verb, parts, key} (distinct from %Command{} — a forgotten build/1 is thus a FunctionClauseError at run/2/Pipe.command/2, the accepted runtime-token cost). token-setters (value/2, ex/2, nx/1, key/2, ...) append tokens. build/1 freezes → %EchoWire.Command{parts, flags(static per verb), slot(crc16 of key)}.
(D1d run/2 dispatch) EchoWire.Cmd.run(cmd_or_list, conn_or_opts) mirrors Pipe's opaque via: default EchoMQ.Connector, EchoMQ.Pool via opts[:via], extracts .parts → one via.pipeline/3; empty list → {:error,:empty_pipeline}; NEVER inspects the reference (no is_struct/is_atom/module guard). On EchoWire.Cmd, NOT the facade — EchoWire.run/2 must not exist (INV1).
(D1e full-cf membership) all 10 tags + predicates readonly?/write?/block?/pipe?/noreply?/static_ttl?/retryable?/opt_in?/mt_get?/unsub? + slot/1 + parts/1 + raw/1 (+raw/2).
(D1c curated membership) the six families mirroring ewr.1.1's curated set: strings (get/set+setters/getset/getdel/mget/mset/incr/incrby/decr/decrby/append/strlen/setex/setnx), generic (del/unlink/exists/expire/pexpire/ttl/pttl/persist/type/rename/renamenx/scan/touch/copy), hashes (hset/hset_all/hget/hmget/hgetall/hdel/hexists/hincrby/hkeys/hvals/hlen/hsetnx), lists (lpush/rpush/lpop/rpop/lrange/llen/lindex/lset/lrem/ltrim/rpoplpush/lmove + block-flagged blpop/brpop/blmove), sets (sadd/srem/smembers/sismember/scard/spop/srandmember/smismember/sscan), sorted sets (zadd+setters/zrem/zrange/zrevrange/zscore/zcard/zrank/zincrby/zpopmin/zpopmax/zcount/zscan). raw/1 covers the rest (INV6 — never a ceiling).
(D1 seam) ONE additive head: `def command(pipe, %EchoWire.Command{parts: parts}), do: add(pipe, parts)` beside the is_list head @:490 — added-lines-only, rest of pipe.ex byte-identical.
(D1 placement) lib/echo_wire/command.ex + cmd.ex; test/echo_wire/{command,cmd}_test.exs; echo_mq/test/stories/wire_pipe_command_*_story_test.exs → docs/echo_mq/wire/stories/ via --match wire_pipe.

DEVIATION FLAGGED (realization-over-literal, the lag-1 law): the triad pins conformance {:ok, 53}; the AS-BUILT floor is {:ok, 54} (conformance_run_test.exs:47, conformance_scenarios_test.exs:4/20, conformance.ex:3 "fifty-four", moduledoc names the emq.4.1 control plane reassign + lane_drain). emq drifted 53→54 out-of-band since the triad was authored. The wire registers NO scenario; the count is emq-owned and byte-stable from the wire's side. I gate on {:ok, 54} byte-stable and surface the stale-number to the Director (a triad doc sync, not a code issue).

## {ewr-1-2-report} Report

### Y-1 — EWR.1.2 BUILT (Mars-1). The command builder + immutable value (Arm 3 + full cf), all gates green.

DESIGN-MAKE REALIZED (ledgered D-1 before any artifact):
- flags = an INTEGER BITFIELD mirroring the rueidis cf uint16 exactly, ported with the bit-inclusion (@readonly = 1<<13 ||| @retryable; @noreply = 1<<12 ||| @readonly ||| @pipe; @unsub = 1<<9 ||| @noreply; @mt_get/@scr_ro ⊇ @readonly). Predicates subset-match (flags &&& tag == tag), the exact cmds.go:147-212 accessor semantics → readonly? ⇒ retryable? holds for free. Chosen over MapSet because the inclusion IS integer subset-match (least-translation).
- slot/1 = a pure crc16-XMODEM(key | {hashtag-inner}) &&& 16383 port of slot.go (256-entry table). Verified vectors: slot("123456789")==12739 (0x31C3); slot("{user}:1")==slot("{user}:2"); empty/unterminated tag → whole-key fallback; nil→nil.
- builder: verb-opener returns a DISTINCT %EchoWire.Cmd{verb,parts,key} intermediate; token-setters append; build/1 freezes → %EchoWire.Command{parts, flags(STATIC per verb via @verb_flag table, never parsed), slot}. A forgotten build/1 is a FunctionClauseError at the call boundary (the accepted runtime-token cost).
- run/2 on EchoWire.Cmd: opaque via dispatch (default Connector, Pool via :via), extracts .parts → one via.pipeline/3, empty→{:error,:empty_pipeline}, NO reference guard (L-3 carried).

FILES:
- NEW echo/apps/echo_wire/lib/echo_wire/command.ex — the value: struct + 10-tag cf bitfield + 11 predicates + slot/1 + parts/1 + raw/1 + raw/2 + the crc16 port.
- NEW echo/apps/echo_wire/lib/echo_wire/cmd.ex — the fluent builder across the six families + 16 token-setters (value/ex/px/nx/xx/gt/lt/ch/incr_opt/keepttl/get_opt/score/match/count/withscores/arg) + build/1 + run/2.
- EDIT echo/apps/echo_wire/lib/echo_wire/pipe.ex — ONE additive command/2 head accepting %EchoWire.Command{} + a @moduledoc note. The @spec command widened by one type-union member (command() | EchoWire.Command.t()) — the only "removed" line, a required dialyzer-contract realization, NOT a behavioral edit; the is_list head + struct/verbs/add/exec byte-identical.
- NEW test/echo_wire/command_test.exs (33 tests: struct, full predicate truth table + bit-inclusion, slot vectors, raw) + test/echo_wire/cmd_test.exs (the builder chains, the six families, INV1 facade-freeze, INV4 byte-equivalence offline, run/2-vs-bare-verb parts).
- NEW echo/apps/echo_mq/test/stories/wire_pipe_command_value_story_test.exs (4 :valkey scenarios) → GEN docs/echo_mq/wire/stories/wire-cmd-command-value.stories.md.

GATE NUMBERS:
- echo_wire: compile --warnings-as-errors CLEAN; mix test 109/0 (8 pre-existing pipe/facade + 101 new). Facade still 11; EchoWire.run/2 ABSENT (function_exported? false, asserted).
- echo_mq: compile CLEAN; mix test --include valkey 380 tests + 4 doctests, 0 failures; CONFORMANCE 54/54 byte-stable.
- regen: mix echo_mq.stories --match wire_pipe → 10 features/17 scenarios, run twice diff -r CLEAN (idempotent); bus dir docs/echo_mq/stories/ byte-unchanged (4 hashes identical pre/post); default no-match path emits all 13 features (no-harm).
- multi-seed sweep: echo_wire 5/5 (0 1 42 312540 999999); echo_mq new stories 5/5. NO ≥100 loop — no id-mint/process/lease (pure data + thin run/2); the multi-seed sweep + this posture statement is the honest floor.

ADVERSARIAL BATTERY (Lua items N/A — no Lua this rung, grep redis.call on lib diff = 0):
- (1) BYTE-EQUIVALENCE: a flagged %Command{} (flags=0, slot=10778) flushes the byte-identical 52B RESP frame "*5...SET...user:1...alice...EX...60" as Pipe.set/4. Proven offline (cmds equality), at the byte level (RESP.encode identity), and live (3 ways — Cmd.run/2, Pipe.command/2, bare verb — return {:ok,["alice"]}).
- (2) STATIC-PER-VERB MUTATION (INV3): build/1 routed through a parts-parser (`"GET" in parts → readonly`) → 4 KILLS incl. the SET-with-"GET"-value test (got flags=8320 readonly, must be write). Reverted net-zero.
- (4) FROZEN-FLOOR: grep redis.call lib diff = 0; pipe.ex added-lines-only on command/2 (the is_list head + struct/verbs/add/exec byte-identical, only the @spec widened); no lib/echo_mq/ runtime edit; facade unchanged; echo/mix.lock unchanged; facade still 11.
- (5) module mutation kill-rate (shared across 1.2+1.3): 3/3 (static-per-verb, partition-misclassify, seam-drop-token), each net-zero reverted, suite 109/0 after.

DEVIATIONS (realization-over-literal, flagged):
- CONFORMANCE {:ok, 53}→{:ok, 54}: the as-built floor drifted to 54 (emq.4.1 control plane: reassign + lane_drain — conformance_run_test.exs:47, conformance_scenarios_test.exs:4/20, conformance.ex:3 "fifty-four"). The triad pins 53 (a stale snapshot; even Venus's T-2 noted 53). I gate on 54 byte-stable; the wire registers none. Triad doc owes a 53→54 sync (Venus reconcile).
- @spec widening on pipe.ex command/2 (1 line) — required for the additive %Command{} head to type-check; not a behavioral edit.
- raw/1 slots the 2nd token when binary (the conventional key position); a keyless verb gets nil; raw/2 overrides. Benign design-make.
INCOMPLETE: none.

## {ewr-1-2-learnings} Learnings

> Consolidated by the Director for Apollo (the Mentor, out of pipeline — PROPOSE-ONLY).

### L-1 — [Venus] cite a sibling program's MUTABLE count VALUE-FREE (the conformance-volatility lesson)

The triad pinned conformance `{:ok, 53}`; the emq count drifted `53→54` mid-build, and `52→53` between `ewr.1.1`'s ship and this framing — **three values in one session**, all from emq's active out-of-band work (the `emq.4.1` control plane). Pinning a sibling program's count *by value* re-stales within hours. GUARDRAIL (propose to Venus, sharpening the `ewr.1.1` L-1 shared-tool line): *a wire spec cites the emq conformance as the INVARIANT — "byte-stable; the wire registers no scenario; the count is emq-owned" — NEVER a specific number; a number is a current-fact annotation at most.* The general rule: a sibling program's mutable surface (a conformance count, a shared tool's scope) is not the wire's to pin — name the invariant, annotate the current fact.

## {ewr-1-2-complete} Complete

### Z-1 — ewr.1.2 (EchoWire.Cmd + EchoWire.Command) SHIPPED — the rueidis command-value core, build-grade.

WHAT SHIPPED: **`EchoWire.Cmd`** (the fluent `set |> value |> ex |> build` builder across the six data families
+ `run/2`) + **`EchoWire.Command`** (the immutable `%Command{parts, flags, slot}` — the full 10-tag `cf` bitfield
with rueidis bit-inclusion + 11 predicates + the CRC16-XMODEM key-slot) — the faithful `Completed` port as the
additive command-value **sibling** to `Pipe` (design-Arm B realized, per the Operator's ruling: Arm 3 +
full-cf-now). One additive `Pipe.command/2` head (`%Command{} → .parts`). The flags are **advisory** (seam 4);
acceptance is **byte-equivalence** (a flagged command flushes identically to the bare verb). `run/2` is on
`EchoWire.Cmd` — `EchoWire.run/2` is ABSENT (the facade stays 11).

VERIFICATION (Director-independent, valkey 6390): echo_wire **109/0** (facade 11, `EchoWire.run` absent); new
wire `:valkey` stories **8/0** (with ewr.1.3); conformance **byte-stable** (the count is emq-owned — drifted
`52→53→54`, not the wire's to pin); byte-equivalence proven offline + live (3 ways); INV3 (static-per-verb) +
INV4 mutation kills re-confirmed; frozen-floor clean (`pipe.ex` added-lines-only + the one `@spec` widening; no
`lib/echo_mq/` runtime edit; `mix.lock` unchanged; `redis.call`=0).

RULINGS (Operator, via the mandatory `AskUserQuestion` gate): **Arm 3** (standalone `EchoWire.Cmd` builder) +
**full `cf` vocabulary now** (over the recommended Arm 1 / minimal). Recorded `D-1`; arms 1/2 keep their case.

LAW-4: scoped to the rung — NEW `command.ex` / `cmd.ex` + their tests + `wire_pipe_command_value_story_test.exs`
+ the generated `wire-cmd-command-value.stories.md` + the ONE added-lines-only `pipe.ex command/2` head. The
Operator commits out-of-band, scoped by concern (the established pattern); EXCLUDED: any emq-side drift,
`echo/README.md`, `memory/`.
