# redis-r602-fairness — AAW scope ledger

## {redis-r602-fairness-thinking} Thinking

### T-1 — Grounding verified on disk (no-invent satisfied)

All `EchoMQ.Lanes` surfaces verified in echo/apps/echo_mq/lib/echo_mq/lanes.ex:
- claim/3 (L321-334): @gclaim (L37-61) — LMOVE ring ring LEFT RIGHT, ZPOPMIN lane, HINCRBY attempts, TIME lease. Returns {id,payload,att,group}.
- wclaim/3 (L352-365): @gwclaim (L87-129) — weighted multi-pop, K = min(w, depth, glimit headroom); one LMOVE rota step then K heads; one shared lease.
- weight/4 (L431-439): @gweight (L208-211) HSET gweight; w>=1; never a pause; no ring bookkeeping.
- enqueue/5 (L293-311), depth/3 (L684-686), limit/4, pause/3, resume/3, reassign/4, reap_group/4 all confirmed.
Keys via Keyspace.queue_key (keyspace.ex L14): emq:{q}:ring, emq:{q}:gactive, emq:{q}:gweight, emq:{q}:glimit; lane_key! -> emq:{q}:g:<group>:pending. slot vector slot("123456789")==12739.

RETIRED-PRIORITY (verbatim, the calibration core):
- weight/4 doc L421-422: "there is no numeric per-job priority (retired by design); 'served more' is a property of the identity, not the work."
- reassign/4 doc L513-515: "Re-aims the RETIRED v1 changePriority-7: there is no numeric per-job priority -- 'matters more now' is a change of lane, mint order is the order theorem."

CONSUMER (verified real surface — CORRECTS the brief's RMM-room assumption):
Codemojex.Guesses.submit/3 (game.ex L21-43) calls Lanes.enqueue(Bus.conn(), "cm", player, job, payload) — the lane is named by the PLAYER's PLR, NOT the room. Moduledoc L5-7 verbatim: "enqueued as a branded JOB on the player's lane -- the lane is named by the player's PLR, so the bus rotates service across players and one keyboard masher cannot starve the field." Codemojex.ScoreWorker (L85-95) drains via Lanes.claim, "the player id arriving as the lane group". Queue "cm" -> lane emq:{cm}:g:<PLR...>:pending. Grounding the consumer in this VERIFIED surface (PLR player lane), satisfying no-invent.

B3.2 figure (bcs.3.md L22, verbatim) confirmed matches prompt-pack.
Models: rate-limiting/index.html (hub) + rate-limiting/fixed-and-sliding-windows.html (dive). cms builds clean at go/jonnify-cms/bin/cms.

## {redis-r602-fairness-progress} Progress

### P-1 — R6.02 Fairness under load: 4 pages + 4 md mirrors authored, ALL A+ / STATUS PASS

Files written (HTML, served):
- html/redis-patterns/flow-control/fairness/index.html (hub, /redis-patterns/flow-control/fairness)
- html/redis-patterns/flow-control/fairness/starvation-under-load.html (R6.02.1)
- html/redis-patterns/flow-control/fairness/the-weighted-share.html (R6.02.2)
- html/redis-patterns/flow-control/fairness/lanes-vs-separate-queues.html (R6.02.3)
md mirrors: docs/redis-patterns/markdown/flow-control/fairness.md + fairness/{starvation-under-load,the-weighted-share,lanes-vs-separate-queues}.md

GATES: all 4 pages PASS all ten gates, grade A+ (containers/svg/no-future/voice/storage/motion/degrade/links/pager/refs). Cross-mounts incl. /echo-persistence.
SCRUBS (all 4, unconditionally clean): bullmq|bull:|dragonfly=0, EchoCache=0, Exchange.=0, bcs/content/bcs=0, .out=0, version-label=0, font-leak=0, first-person=0, banned-words=0.
SURFACES: every cited EchoMQ.Lanes.{claim/3,wclaim/3,weight/4,enqueue/5,reassign/4,reap_group,drain/3,depth/3,pause/3,limit/4} + EchoMQ.Jobs.paused? + Codemojex.{Guesses.submit/3,ScoreWorker} re-verified FOUND on disk.
FROZEN FIGURES (byte-faithful, verified vs source): hub & d1 = @gclaim (lanes.ex L37-61); d2 = @gwclaim K-clamp head (L88-105); d3 = claim/3 host (L321-334). figcaptions name EchoMQ.Lanes / echo/apps/echo_mq, no line numbers.
MANUSCRIPT: B3.2 fair-lanes figure quoted verbatim (bcs.3.md L22) in hub .qfig, source bcs.3.md/B3.
INTERACTIVES: 2 hover-select per page (hover AND click, .focus/.on, live .readout, pure JS over fixed datasets). All 4 inline scripts node --check OK. Degrade: static segbar+svg+readout, JS enhances only.
INVISIBLES: clamps spaced; header.top scoped (no bare .top); segmented clickable route-tag; 3-col footer + verbatim TSK stamp; refs 2-col grid on all 4; pager chain hub->d1->d2->d3->hub correct; no perceptual verb on a tool (rephrased 3 "ring decides" -> "rotation orders service"/"ring sets").

CALIBRATION CORRECTION: brief said codemojex room=lane (RMM); real as-built (Codemojex.Guesses, game.ex L5-7,37) is PLAYER lane (PLR), queue "cm". Grounded the consumer in the VERIFIED PLR-player-lane surface (no-invent honoured).

SIBLING-DEPENDENT: none of my 4 pages link to the unbuilt R6.03 /flow-control/groups — every internal link resolves now. The chapter landing + home are NOT touched (orchestrator relinks R6.02 soon->built).

### P-2 — DONE. Scope verified clean.

Confirmed in-scope only: 4 HTML (html/redis-patterns/flow-control/fairness/{index,starvation-under-load,the-weighted-share,lanes-vs-separate-queues}.html) + 4 md mirrors (docs/redis-patterns/markdown/flow-control/fairness.md + fairness/*.md) + the TOC living-view sync (docs/redis-patterns/redis-patterns.toc.md: R6.02 marked built + chapter status line).
NOT touched: chapter landing html/redis-patterns/flow-control/index.html (its R6.02 card is still a non-anchor <div class="mod"> soon pill — orchestrator flips) and the home html/redis-patterns/index.html (its M-diff is the pre-existing R6.01-built relink, R6.02 still soon — not mine).
FINAL: 4/4 pages STATUS PASS, grade A+. No git run.
