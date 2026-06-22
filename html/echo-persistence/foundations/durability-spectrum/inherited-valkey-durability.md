---
title: "Inherited Valkey durability"
id: ep-m1-d1
status: established
route: "/echo-persistence/foundations/durability-spectrum/inherited-valkey-durability"
kind: "module 1 · dive 1.1"
design: "html/redis-patterns sheet, re-themed amber/bronze."
pedagogy: "Taught through a unique interactive AOF crash-window SVG; no machine throughput numbers."
renders-to: "foundations/durability-spectrum/inherited-valkey-durability.html"
---

# Inherited Valkey durability { id="ep-m1-d1" }

> _EchoMQ enqueues on Valkey, so it inherits Valkey's durability. With the append-only file flushed once a second, a write is safe within a second — on one box. The exposure is exactly the writes accepted since the last flush. Move the crash and watch it._

**Interactive figure.** An AOF timeline (`appendfsync everysec`): writes arrive left to right; dashed vertical lines are once-a-second flushes to disk. A draggable crash marker splits the writes — those before the last flush are safe (green), those after it are the **lost window** (red), those after the crash haven't happened. The readout counts safe vs lost. Dragging the crash makes the point viscerally: the window is at most one flush interval, and on a single box it does not come back.

## §1 The one-second window { id="window" }

The shape is the lesson: durability here is a **window**, not a guarantee. Tightening the flush to every write closes the window but turns each write into its own flush — the strict, low-throughput corner of the spectrum. Loosening it widens the window for throughput. Same knob as everywhere else; Valkey simply ships it set to one second.

## §2 When it is, and isn't, enough { id="why" }

For most work a one-second window is fine: a dropped metric or a retried side-effect costs nothing. For the jobs Echo Persistence exists for — a payment, the recorded product of a completed job — two things are missing, and the timeline shows both. First, the lost window is real work that was acknowledged and then vanished. Second, and invisible on a single timeline, **nothing has left the machine**: lose the box and you lose the file. Closing the window is one axis; getting the state off the box is the other — Dive 1.3 separates them, and the rest of the course reaches the corner where both are answered.

## §3 References & sources { id="refs" }

External:
- Valkey persistence — AOF & appendfsync — https://valkey.io/topics/persistence/
- Redis persistence — the same AOF model in depth — https://redis.io/docs/management/persistence/

Echo records:
- graft.design.md — why the inherited window is a floor, not a guarantee — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/graft/graft.design.md
- emq.roadmap.md — EchoMQ on Valkey, the bus the window belongs to — https://github.com/jonny-novikov/fiberfx/blob/echo_mq/docs/echo_mq/emq.roadmap.md

---

_Pager: ← The durability spectrum · Dive 1.2 — The shootout and the one knob →_
