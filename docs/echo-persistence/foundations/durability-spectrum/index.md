---
title: "Module 1 — The durability spectrum"
id: ep-m1-hub
status: established
route: "/echo-persistence/foundations/durability-spectrum"
kind: "module 1 hub — Chapter I, 3 dives"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive frontier SVG; figures are indicative single-core asides."
renders-to: "foundations/durability-spectrum/index.html"
---

# The durability spectrum { id="ep-m1-hub" }

> _Durability is a position on a spectrum, set deliberately per queue. This module builds the spectrum as a tradeoff frontier, extracts the one knob that moves a system along it, and separates the two axes a queue is placed on — taught by moving the picture, not by reading a machine's numbers._

**Interactive figure (hub).** A tradeoff-frontier scatter: vertical axis durability (none → strict), horizontal axis throughput (durable records per fsync). Engines sit on a frontier curve — Oban top-left (strict, slow), Memory bottom-right (none, fast) — with Champ's K=1k and K=10k showing the *same knob* sliding the point down-right as K grows. BullMQ sits below the curve (dominated). A goal marker, **Champ + Graft**, sits top-right (strict and fast) with an arrow showing the two tiers pushing the strict corner rightward. Tapping a point explains its position; the only figures appear in the readout, labelled indicative single-core.

## §1 What this module is { id="about" }

A single number teaches little because it is one machine's answer to one question. What transfers is the **shape** and the **knob** behind it: throughput tracks how many durable records ride each fsync, so the whole spectrum is one tradeoff moved by one lever. Memory rides infinitely many records per fsync and loses everything; Oban rides one and loses nothing; Champ rides K, and sliding K walks the Champ point along the frontier.

The far corner the figure marks — strict durability **and** high throughput — is unreachable for a single engine, which is why Echo Persistence splits the job into two tiers. The goal marker is where the course is headed, measured per-workload when the engines are benchmarked together (eg.6 — deferred behind a fly.io deploy floor; the live frontier is the bus's Stream Tier).

**On the numbers.** Where a figure appears in this course, it is an indicative single-core sandbox measurement against MinIO, shown to make a *relationship* concrete — never as a portable benchmark. Read the slope, not the digit.

## §2 The three dives { id="dives" }

- **Dive 1.1 — Inherited Valkey durability** — what AOF's once-a-second flush actually promises; an interactive timeline where you trigger a crash and watch the lost window appear. → `/echo-persistence/foundations/durability-spectrum/inherited-valkey-durability`
- **Dive 1.2 — The shootout and the one knob** — the mechanism, with a slider for records-per-fsync; the four engines fall out as positions, not a table. → `/echo-persistence/foundations/durability-spectrum/the-shootout-and-the-knob`
- **Dive 1.3 — Two axes, one decision** — loss window and replication are independent; drop a workload into the durability–replication plane. → `/echo-persistence/foundations/durability-spectrum/two-axes`

## §3 Build & check { id="build" }

**What you build.** A one-page placement worksheet: take three queues — a telemetry firehose, an ordinary work queue, a payments queue — and place each on both axes (loss window and replication), justifying every placement in a sentence. Reused in Dive 1.3's plane.

**Check.** Using the frontier figure and Dive 1.2's slider — not the table — state the one knob in a sentence, and predict, before moving the slider, which direction Champ's point travels as K grows. Then confirm it.

## §4 References & sources { id="refs" }

Echo records:
- graft.design.md — the spectrum and the two-tier design — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- graft.roadmap.md — the per-workload shootout (eg.6), the goal corner — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.roadmap.md

External:
- Valkey persistence (AOF) — the inherited window — https://valkey.io/topics/persistence/
- oban-bg/oban — the strict per-commit anchor — https://github.com/oban-bg/oban
- Designing Data-Intensive Applications, Kleppmann 2017 — WAL, group commit (Ch. 3, 5) — https://dataintensive.net

---

_Pager: ← Course overview · Dive 1.1 — Inherited Valkey durability →_
