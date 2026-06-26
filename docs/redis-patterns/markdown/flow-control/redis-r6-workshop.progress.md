# redis-r6-workshop — AAW scope ledger

## {redis-r6-workshop-progress} Progress

### P-1 — md source-of-record authored at docs/redis-patterns/markdown/flow-control/workshop.md. All consumer + bus surfaces verified on disk: Codemojex.{RateLimiter.take/2, Guesses.submit/3+pause/resume/depth/1, ScoreWorker.handle/1, NotificationWorker.handle/1, CommandWorker.handle/1, Notifier.notify/3} + EchoMQ.{Lanes.enqueue/5+claim/3+bclaim/3+pause/3+resume/3+depth/3, Jobs.enqueue_in/5+enqueue_many/4, Consumer, Metrics.get_rate_limit_ttl/3}. Brands minted confirmed: PLR/ROM/GAM/GES/JOB/NOT present, USR/RMM/RND absent. Doors built: /echomq/queue, /bcs/bus, /bcs/codemojex. Next: build the HTML to match the md.

### P-2 — R6.06 workshop COMPLETE at STATUS: PASS. Files: html/redis-patterns/flow-control/workshop/index.html + docs/redis-patterns/markdown/flow-control/workshop.md. cms gate A+ all 10 (2 svg well-formed, links/pager/refs PASS). All scrubs clean: bullmq/dragonfly, EchoCache, Exchange., .out, version-labels, voice, font-leak, USR/RMM/RND, bcs/content/bcs — all empty. node --check OK. Every echo-layer surface re-found on disk with real arity (Codemojex.{Guesses.submit/3,pause/1,ScoreWorker.handle/1,NotificationWorker.handle/1,CommandWorker.handle/1,RateLimiter.take/2,Notifier} + EchoMQ.{Lanes.enqueue/5+claim/3+bclaim/3+pause/3+limit/4,Jobs.enqueue_in/5+enqueue_many/4,Consumer,Pool,Metrics.get_rate_limit_ttl/3} + EchoWire.Pipe). Lanes.claim/3 returns {:ok,{id,payload,att,group}} — backs the lane-group claim. Clamp spaced, route-tag segmented, header.top scoped, perceptual-verb scan clean, degrade=static gates+layers. Doors /echomq/queue + /bcs/bus + /bcs/codemojex all built. NOT editing the home/landing manifests (orchestrator relinks).


