#!/usr/bin/env python3
"""
build_page.py — page builder + Apollo quality gates for the
"Functional Programming in Elixir" course (jonnify dark-editorial system).

The manifest below is the single source of truth. Statuses drive whether the
contents directory renders a *link* (live / built) or a *non-linking card*
(planned / soon). The builder injects the generated contents, the chapter
data for the interactive arc, and a freshly minted branded Snowflake build id
into a hand-authored content fragment, then runs Apollo. Any STATUS: FAIL is a
hard stop.

Commands
    extract-head            write the shared <head> partial to _head.html (run once)
    build  --page KEY       assemble a page from content/<file> -> output, then check
    build  --all            build every registered page
    check  FILE [FILE ...]  run the Apollo gates on existing file(s)
    manifest                print the module manifest
    routes                  print route -> status -> file
    id mint   --ns TSK [--node N] [--seq N] [--at ISO8601]
    id decode BRANDED

Stdlib only. No third-party dependencies.
"""

from __future__ import annotations

import argparse
import html as _html
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# --------------------------------------------------------------------------- #
# Branded Snowflake IDs                                                        #
#   layout : timestamp(41) << 22 | node(10) << 12 | seq(12)                    #
#   epoch  : 2024-01-01T00:00:00Z                                             #
#   id     : <NS:3 chars> + base62(snowflake) left-padded to 11               #
#   example: TSK0KHTOWnGLuC <-> 274557032793636864 <-> 2026-01-27 15:11:37 UTC #
# --------------------------------------------------------------------------- #
EPOCH_MS = 1_704_067_200_000
B62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
B62_WIDTH = 11
TS_SHIFT, NODE_SHIFT = 22, 12
NODE_MASK, SEQ_MASK = 0x3FF, 0xFFF


def b62_encode(n: int, width: int = B62_WIDTH) -> str:
    if n < 0:
        raise ValueError("snowflake must be non-negative")
    if n == 0:
        s = "0"
    else:
        out = []
        while n > 0:
            n, r = divmod(n, 62)
            out.append(B62[r])
        s = "".join(reversed(out))
    return s.rjust(width, "0")


def b62_decode(s: str) -> int:
    n = 0
    for ch in s:
        n = n * 62 + B62.index(ch)
    return n


def snowflake(ts_ms: int, node: int = 0, seq: int = 0) -> int:
    rel = ts_ms - EPOCH_MS
    if rel < 0:
        raise ValueError("timestamp predates the snowflake epoch")
    return (rel << TS_SHIFT) | ((node & NODE_MASK) << NODE_SHIFT) | (seq & SEQ_MASK)


def mint(ns: str, node: int = 0, seq: int = 0, at: datetime | None = None) -> str:
    if len(ns) != 3:
        raise ValueError("namespace prefix must be exactly 3 characters")
    at = at or datetime.now(timezone.utc)
    ts_ms = int(at.timestamp() * 1000)
    return ns + b62_encode(snowflake(ts_ms, node, seq))


def decode(branded: str) -> dict:
    ns, rest = branded[:3], branded[3:]
    snow = b62_decode(rest)
    ts = snow >> TS_SHIFT
    node = (snow >> NODE_SHIFT) & NODE_MASK
    seq = snow & SEQ_MASK
    dt = datetime.fromtimestamp((EPOCH_MS + ts) / 1000, tz=timezone.utc)
    return {
        "branded": branded,
        "namespace": ns,
        "snowflake": snow,
        "node": node,
        "seq": seq,
        "timestamp": dt.strftime("%Y-%m-%d %H:%M:%S UTC"),
    }


# --------------------------------------------------------------------------- #
# Manifest — chapters and modules (single source of truth)                     #
# --------------------------------------------------------------------------- #
# status: live | built (linkable)  ·  planned | soon (non-linking card)
ROOT_ROUTE = "/elixir"

CHAPTERS = [
    dict(id="F0", title="History", slug="course", route="/elixir/course",
         status="live",
         one="Where this came from — the languages, the runtimes, and the BEAM.",
         reuses="Context, not a prerequisite. F1 stands on its own.",
         accent="blue"),
    dict(id="F1", title="Algebra", slug="algebra", route="/elixir/algebra",
         status="live",
         one="The functional mindset, straight from the math you already know.",
         reuses="Starts from the algebra you already know.",
         accent="gold"),
    dict(id="F2", title="Functional Programming", slug="functional", route="/elixir/functional",
         status="live",
         one="Pure functions, immutability, and higher-order functions on their own terms.",
         reuses="Builds on F1 · Algebra.",
         accent="elixir"),
    dict(id="F3", title="The Elixir Language", slug="language", route="/elixir/language",
         status="live",
         one="Syntax, pipelines, pattern matching, and structs on the BEAM.",
         reuses="Builds on F2 · Functional Programming.",
         accent="elixir"),
    dict(id="F4", title="Algorithms & Data Structures", slug="algorithms", route="/elixir/algorithms",
         status="live",
         one="Classical and advanced problems, from lists to branded CHAMP tries.",
         reuses="Builds on F3 · The Elixir Language.",
         accent="sage"),
    dict(id="F5", title="Pragmatic Programming", slug="pragmatic", route="/elixir/pragmatic",
         status="live",
         one="Real-world engineering: structure, testing, telemetry, releases.",
         reuses="Builds on F4 · Algorithms & Data Structures.",
         accent="sage"),
    dict(id="F6", title="Phoenix Framework", slug="phoenix", route="/elixir/phoenix",
         status="live",
         one="Web applications on Elixir, and the road into real-time LiveView.",
         reuses="Builds on F5 · Pragmatic Programming.",
         accent="blue"),
]

# modules[chapter_id] -> list of dicts {n,title,one,slug,status,lab,dives?}
MODULES = {
    "F0": [
        dict(n="F0.1", title="The evolution of functional languages & runtimes",
             one="λ-calculus → LISP → ML/Haskell → the immutable turn.",
             slug="fp-evolution", status="built", lab=False,
             dives=[
                 dict(n="F0.1.1", title="From λ-calculus to LISP", slug="lisp-origins", status="soon"),
                 dict(n="F0.1.2", title="Types & laziness — the ML and Haskell branch", slug="ml-haskell", status="soon"),
                 dict(n="F0.1.3", title="The immutable turn — persistent data on the JVM & CLR", slug="immutable-turn", status="soon"),
             ]),
        dict(n="F0.2", title="The evolution of Erlang, the BEAM & OTP",
             one="Telecom roots, soft-real-time scheduling, and supervision.",
             slug="beam-evolution", status="built", lab=False,
             dives=[
                 dict(n="F0.2.1", title="Telecom roots & “let it crash”", slug="telecom-roots", status="soon"),
                 dict(n="F0.2.2", title="Inside the BEAM — scheduling, heaps & soft-real-time GC", slug="inside-beam", status="soon"),
                 dict(n="F0.2.3", title="OTP & the supervision tree — and the polyglot BEAM", slug="otp-supervision", status="soon"),
             ]),
    ],
    "F1": [
        dict(n="F1.01", title="What a function really is",
             one="Mapping, domain & range, exactly one output → first-class functions.",
             slug="functions", status="built", lab=False),
        dict(n="F1.02", title="The substitution model",
             one="Equals for equals → referential transparency and purity.",
             slug="substitution", status="built", lab=False),
        dict(n="F1.03", title="Composition, f∘g",
             one="Chaining mappings, associativity → the pipe.",
             slug="composition", status="built", lab=False),
        dict(n="F1.04", title="Immutability & binding",
             one="A symbol names a fixed value → immutable data.",
             slug="immutability", status="built", lab=False),
        dict(n="F1.05", title="Sets, sequences & mappings",
             one="Applying f across a collection → lists, maps, Enum.map.",
             slug="collections", status="built", lab=False),
        dict(n="F1.06", title="Recursion & induction",
             one="Base case + step, and the proof → recursion, no loops.",
             slug="recursion", status="built", lab=False),
        dict(n="F1.07", title="Higher-order operators (Σ, Π)",
             one="Operators over functions → map / filter / reduce.",
             slug="higher-order", status="built", lab=False),
        dict(n="F1.08", title="Equations & pattern matching",
             one="Identities, solving by structure → pattern matching.",
             slug="pattern-matching", status="built", lab=False),
        dict(n="F1.09", title="Functions on the plane — a plotting lab",
             one="Plot and compose functions; watch f∘g as curves.",
             slug="plotting-lab", status="built", lab=True),
    ],
    "F2": [
        dict(n="F2.01", title="Pure functions & side effects", one="What purity buys; isolating effects.", slug="pure", status="built", lab=False),
        dict(n="F2.02", title="Immutability & persistent data", one="Structural sharing; why copying is cheap.", slug="persistence", status="built", lab=False),
        dict(n="F2.03", title="Higher-order functions", one="Functions as arguments and return values.", slug="higher-order", status="built", lab=False),
        dict(n="F2.04", title="Recursion patterns & tail calls", one="Accumulators and tail-call optimisation.", slug="recursion", status="built", lab=False),
        dict(n="F2.05", title="map / filter / reduce (folds)", one="reduce as the universal fold.", slug="folds", status="built", lab=False),
        dict(n="F2.06", title="Closures & partial application", one="Capturing environment; & and currying by hand.", slug="closures", status="built", lab=False),
        dict(n="F2.07", title="Algebraic data types", one="Sum and product types; tagged tuples.", slug="adt", status="built", lab=False),
        dict(n="F2.08", title="Composition & pipelines", one="Building programs by composing functions.", slug="composition", status="built", lab=False),
        dict(n="F2.09", title="The data-pipeline lab", one="Compose map/filter/reduce over a dataset; watch each stage.", slug="pipeline-lab", status="built", lab=True),
    ],
    "F3": [
        dict(n="F3.01", title="Values, types & IEx", one="The data you build with; the shell as a tool.", slug="values", status="built", lab=False),
        dict(n="F3.02", title="Pattern matching & the match operator", one="= is a match, not assignment.", slug="match", status="built", lab=False),
        dict(n="F3.03", title="Functions, modules & the pipe", one="Defining and composing in modules.", slug="modules", status="built", lab=False),
        dict(n="F3.04", title="Enumerables & streams", one="Eager versus lazy traversal.", slug="enum-streams", status="built", lab=False),
        dict(n="F3.05", title="Structs, maps & keyword lists", one="Shaping data; when to use which.", slug="structs", status="built", lab=False),
        dict(n="F3.06", title="Protocols & behaviours", one="Polymorphism and contracts.", slug="protocols", status="built", lab=False),
        dict(n="F3.07", title="Processes & the actor model", one="spawn, send, receive; isolation.", slug="processes", status="built", lab=False),
        dict(n="F3.08", title="OTP: GenServer & supervisors", one="Stateful servers and fault tolerance.", slug="otp", status="built", lab=False),
        dict(n="F3.09", title="The process playground", one="Spawn processes, send messages, watch the mailbox live.", slug="playground", status="built", lab=True),
    ],
    "F4": [
        dict(n="F4.01", title="Lists, recursion & complexity", one="Cons cells; big-O on the BEAM.", slug="lists", status="built", lab=False),
        dict(n="F4.02", title="Trees & traversals", one="Binary and n-ary trees; DFS/BFS, functionally.", slug="trees", status="built", lab=False),
        dict(n="F4.03", title="Sorting & searching", one="Merge/quick sort and binary search, immutably.", slug="sorting", status="built", lab=False),
        dict(n="F4.04", title="Maps, sets & hashing", one="Hash maps, collisions, the cost model.", slug="maps", status="built", lab=False),
        dict(n="F4.05", title="Hash Array Mapped Tries (HAMT)", one="Persistent maps via prefix trees.", slug="hamt", status="built", lab=False),
        dict(n="F4.06", title="CHAMP maps", one="Compressed Hash-Array Mapped Prefix-trees; layout & iteration.", slug="champ", status="built", lab=False),
        dict(n="F4.07", title="Identifiers, Snowflake & branded ids", one="From naive ids to a Snowflake bigint and a branded, base62 id.", slug="identifiers", status="built", lab=False),
        dict(n="F4.08", title="Branded ids & persistence", one="Branded ids as keys in SQLite, PostgreSQL, and Redis.", slug="persistence", status="built", lab=False),
        dict(n="F4.09", title="Branded CHAMP maps & GenServer", one="A CHAMP keyed by branded ids, partitioned by namespace, behind a GenServer.", slug="branded-champ", status="built", lab=False),
        dict(n="F4.10", title="Practical recipes in Elixir", one="Turning algorithmic problems into idiomatic Elixir.", slug="recipes", status="built", lab=False),
        dict(n="F4.11", title="Dynamic programming & advanced problems", one="Overlapping subproblems, memoized and tabulated.", slug="dynamic-programming", status="built", lab=False),
        dict(n="F4.12", title="Lab: build a branded CHAMP store", one="An interactive lab: insert branded keys and watch the partitioned CHAMP restructure.", slug="lab", status="built", lab=True),
    ],
    "F5": [
        dict(n="F5.01", title="Foundations", one="Start thin: a running Portal from day one.", slug="foundations", status="built", lab=False),
        dict(n="F5.02", title="Modeling the Portal domain", one="Bounded contexts, structs, and the public API.", slug="domain", status="built", lab=False),
        dict(n="F5.03", title="Tracer bullets: a walking skeleton", one="Thin end-to-end first, then iterate.", slug="tracer-bullets", status="built", lab=False),
        dict(n="F5.04", title="Design by contract", one="Preconditions, postconditions, and failing fast.", slug="contracts", status="built", lab=False),
        dict(n="F5.05", title="Commands, queries & events", one="Separate writes from reads; the engine as a reducer over events.", slug="cqrs", status="built", lab=False),
        dict(n="F5.06", title="Where engine state lives", one="One process holds the state; one supervisor keeps it alive.", slug="state", status="built", lab=False),
        dict(n="F5.07", title="Pragmatic testing", one="Testing the pure core, property-based tests, and contracts as tests.", slug="testing", status="built", lab=False),
        dict(n="F5.08", title="Boundaries & integration seams", one="Ports out, a facade in, one error vocabulary for the UI.", slug="boundaries", status="built", lab=False),
        dict(n="F5.09", title="Lab: the Portal engine, LiveView-ready", one="Assemble the engine end to end, then mount it behind a LiveView.", slug="engine-lab", status="built", lab=True),
    ],
    "F6": [
        dict(n="F6.01", title="Architecture & the request lifecycle", one="endpoint → router → controller → view.", slug="lifecycle", status="planned", lab=False),
        dict(n="F6.02", title="Routing, controllers & plugs", one="The plug pipeline.", slug="routing", status="planned", lab=False),
        dict(n="F6.03", title="Ecto: schemas, changesets & queries", one="Data, validation, the repo.", slug="ecto", status="planned", lab=False),
        dict(n="F6.04", title="Contexts & domain design", one="Boundaries that scale.", slug="contexts", status="planned", lab=False),
        dict(n="F6.05", title="Templates, components & HEEx", one="Server-rendered markup.", slug="heex", status="planned", lab=False),
        dict(n="F6.06", title="Phoenix LiveView fundamentals", one="Interactive UIs without hand-written JS.", slug="liveview", status="planned", lab=False),
        dict(n="F6.07", title="PubSub, channels & real-time", one="Live updates over WebSockets.", slug="pubsub", status="planned", lab=False),
        dict(n="F6.08", title="Auth, deployment & going live", one="Sessions, releases, production.", slug="deployment", status="planned", lab=False),
        dict(n="F6.09", title="The live dashboard", one="Real-time LiveView state over a socket; multi-client via PubSub.", slug="live-dashboard", status="planned", lab=True),
    ],
}

LINKABLE = {"live", "built"}


SUBPAGES = {
    # A module can have deep-dive subpages. Their routes become linkable once the
    # parent module itself is linkable. Subpages are NOT counted as modules.
    "F2.04": [
        dict(slug='patterns', title='Recursion patterns', one='sum, length, reverse, map, filter — and why they are folds.'),
        dict(slug='shape', title='The shape of recursion', one='Base case, recursive case, and the growing call stack.'),
        dict(slug='tail-calls', title='Tail calls & accumulators', one='Rewrite with an accumulator to run in constant stack space.'),
    ],
    "F2.05": [
        dict(slug='advanced', title='Advanced folds', one='scan, map_reduce, flat_map, group_by — folds with extra structure.'),
        dict(slug='filter', title='filter', one='Keep the elements that pass a predicate.'),
        dict(slug='map', title='map', one='Transform every element; the structure is preserved.'),
        dict(slug='reduce', title='reduce', one='The general fold; an accumulator of any shape.'),
    ],
    "F2.06": [
        dict(slug='capture', title='The capture operator', one='The & shorthand: positional placeholders and function capture.'),
        dict(slug='currying', title='Partial application & currying', one='Fixing arguments to specialize a function; currying by hand.'),
        dict(slug='environment', title='Capturing the environment', one='What a closure captures, and when — the value at definition time.'),
    ],
    "F2.07": [
        dict(slug='matching', title='Pattern matching on data', one='Destructuring products and dispatching on sum variants.'),
        dict(slug='product', title='Product types', one='Tuples and structs — fields held together; inhabitants multiply.'),
        dict(slug='sum', title='Sum types', one='Tagged tuples and variants — one shape or another; inhabitants add.'),
    ],
    "F2.08": [
        dict(slug="compose",  title="Function composition", one="Combining functions so one's output feeds the next \u2014 f after g."),
        dict(slug="pipe",     title="The pipe operator",    one="|> threads a value left to right, as the first argument."),
        dict(slug="pipeline", title="Building pipelines",   one="map, filter, and reduce stages over a dataset, end to end."),
    ],
    "F3.02": [
        dict(slug='branching', title='Branching with case & guards', one='case, with, and guard clauses that match on structure.'),
        dict(slug='destructuring', title='Destructuring data', one='Pulling values out of tuples, lists, and maps by shape.'),
        dict(slug='operator', title='The match operator', one='= binds by matching structure rather than assigning.'),
    ],
    "F3.04": [
        dict(slug='comprehensions', title='Comprehensions', one='for-comprehensions: filter, map, and into.'),
        dict(slug='enum', title='Enum, the eager workhorse', one='The eager workhorse over any enumerable.'),
        dict(slug='streams', title='Lazy streams', one='Lazy, composable enumerables.'),
    ],
    "F3.05": [
        dict(slug='defaults', title='Enforcing keys & defaults', one='@enforce_keys and default field values.'),
        dict(slug='define', title='Defining a struct', one='defstruct, and how a struct is a tagged map.'),
        dict(slug='matching', title="Matching on a struct's type", one='Pattern matching on %Struct{} by its tag.'),
    ],
    "F3.06": [
        dict(slug='behaviours', title='Behaviours & callbacks', one='@callback declares a typed contract on a module;'),
        dict(slug='defimpl', title='Implementing for a struct', one='defimpl Protocol, for: Struct gives the per-type bodies a call resolves to;'),
        dict(slug='define', title='Defining a protocol', one='defprotocol declares a contract of function signatures;'),
    ],
    "F3.07": [
        dict(slug='messages', title='Sending & receiving messages', one='send/2 appends a term to a mailbox and returns;'),
        dict(slug='spawn', title='Spawning a process', one='spawn/1 starts a function as a new process and returns a PID at once;'),
        dict(slug='state', title='Holding state in a loop', one='A process holds state as the argument to a recursive receive loop, tail-calling itself with the '),
    ],
    "F3.08": [
        dict(slug='call-cast', title='Synchronous call, asynchronous cast', one='GenServer.call sends a request and blocks for the reply, routing to handle_call;'),
        dict(slug='genserver', title='The GenServer behaviour', one='A GenServer abstracts the receive loop into a behaviour: init/1 sets the state, handle_call/3 an'),
        dict(slug='supervisors', title='Supervisors & restart strategies', one='A supervisor starts child processes and restarts them when they crash, by strategy — one_for_one'),
    ],
    "F4.01": [
        dict(slug='big-o', title='Complexity & big-O on the BEAM', one='Big-O for a list is concrete: count the cons cells an operation touches.'),
        dict(slug='cons', title='Cons cells & the shape of a list', one='A cons cell is a head and a tail pointer.'),
        dict(slug='recursion', title='Recursion over lists', one='You walk a list by recursion, not a loop: match [h | t], act on the head, recurse on the tail, a'),
    ],
    "F4.03": [
        dict(slug='sorts', title='Merge & quicksort', one='The two workhorse comparison sorts are both divide-and-conquer.'),
        dict(slug='cost', title='Stability & sort cost', one='Sorts are ranked on average, worst case, space, and stability — whether equal keys keep their or'),
        dict(slug='search', title='Linear & binary search', one='Linear search checks elements one by one over any sequence — O(n).'),
    ],
    "F3.03": [
        dict(slug='functions', title='Defining functions', one='Named functions with def and defp, multiple clauses that dispatch by pattern and guard, arity, a'),
        dict(slug='organising', title='Organising with modules', one='defmodule, module attributes, alias and import, and documentation — how the Portal namespace is '),
        dict(slug='pipe', title='The pipe operator', one='|> threads a value as the first argument to the next call, turning nested calls into a readable '),
    ],
    "F4.02": [
        dict(slug='bfs', title='Breadth-first & balance', one='Breadth-first traversal walks the tree level by level with a FIFO queue.'),
        dict(slug='dfs', title='Depth-first: pre, in, post-order', one='Depth-first traversal makes the same two recursive calls and differs only in when it visits the '),
        dict(slug='shape', title='Binary trees & recursive shape', one='A node is {value, left, right} or nil, so every tree function handles nil as the base case and a'),
    ],
    "F4.04": [
        dict(slug='lookup', title='Maps & key lookup', one='A map associates keys with values and looks one up in effectively constant time.'),
        dict(slug='hashing', title='Hashing & collisions', one='Maps and sets reach O(1) by hashing: phash2 turns a key into an integer, which picks a slot, and'),
        dict(slug='sets', title='MapSet & membership', one='A MapSet stores unique elements and answers membership in O(1).'),
    ],
    "F4.06": [
        dict(slug='equality', title='Canonical equality', one='CHAMP maintains one canonical shape per set of entries, so two equal maps are structurally ident'),
        dict(slug='iteration', title='Cache-friendly iteration', one='Because a CHAMP node keeps its entries contiguous and separate from sub-node pointers, iteration'),
        dict(slug='layout', title='Compressed node layout', one='A CHAMP node carries a datamap and a nodemap — two bitmaps marking which of its 32 slots hold in'),
    ],
    "F4.05": [
        dict(slug='bitmap', title='Bitmapped nodes', one='A HAMT node keeps one 32-bit bitmap marking which of its slots are occupied and one packed array'),
        dict(slug='indexing', title='Hash-prefix indexing', one="A HAMT reads the key's hash in five-bit chunks from the low end: level 0 reads bits 0-4, level 1"),
        dict(slug='sharing', title='Structural sharing', one='An insert builds new nodes only along the path from the root to the changed leaf and shares ever'),
    ],
    "F4.07": [
        dict(slug='snowflake', title='The Snowflake bigint', one='A Snowflake packs three fields into 64 bits: a 42-bit millisecond timestamp from a custom 2024 e'),
        dict(slug='branded', title='Branded ids', one='A branded id encodes the 64-bit Snowflake in base62 over 0-9A-Za-z, left-pads it to eleven chara'),
        dict(slug='choosing', title='Choosing an identifier', one='An auto-increment counter is ordered and tiny but needs one writer, so it cannot scale across ma'),
    ],
    "F4.08": [
        dict(slug='keys', title='Branded ids as keys', one='The database stores the 64-bit integer as a bigint primary key — eight bytes, numerically ordere'),
        dict(slug='redis', title='Redis keys', one='In Redis the id is a namespaced string key, user:USR0NbWMtkosp8.'),
        dict(slug='sql', title='SQLite & PostgreSQL', one='Because the high bits of the id are a timestamp, a window of time is a contiguous window of ids:'),
    ],
    "F4.09": [
        dict(slug='genserver', title='Own it with a GenServer', one="The Portal's session store is a CHAMP behind a GenServer."),
        dict(slug='partition', title='Partition by namespace', one="The Portal's entity registry keeps users, sessions, lessons, and pages in one store: a tiny top-"),
        dict(slug='trie', title='Structural sharing', one="Inside a partition the CHAMP is keyed on the lesson's Snowflake, and Portal.Progress marks a les"),
    ],
    "F4.10": [
        dict(slug='patterns', title='Idiomatic patterns', one='A request to view a lesson clears four gates — validate the id, authenticate the caller, fetch t'),
        dict(slug='pipelines', title='Streams & pipelines', one='The activity feed wants the three most recent completions for a course.'),
        dict(slug='profiling', title='Profiling & complexity', one='Every request finds an active session.'),
    ],
    "F4.11": [
        dict(slug='memoization', title='Memoization & overlapping subproblems', one='The longest prerequisite chain to a lesson is one plus the deepest of its prerequisites — a recu'),
        dict(slug='problems', title='Classic DP problems', one='Edit distance — the fewest single-character inserts, deletes, or substitutions between two strin'),
        dict(slug='tabulation', title='Tabulation & bottom-up', one='The fewest modules (worth 1, 3, or 4 credits) summing to a target is one more than the best answ'),
    ],
    "F4.12": [
        dict(slug='grow', title='Watch a branded CHAMP grow', one="Each put reads a branded id's three-letter namespace and drops the entry into that namespace's p"),
        dict(slug='registry', title='A Snowflake registry', one='Hand the store any branded id and get/1 resolves it in one call: the prefix names the partition,'),
        dict(slug='range', title='Query by time range', one='Because a Snowflake puts the timestamp in its high bits, ids sort by creation time and a time wi'),
    ],
    "F5.01": [
        dict(slug='replaceable', title='A web layer built for replacement', one='The thin server is a detail, by design.'),
        dict(slug='roadmap', title='The development roadmap', one='The whole course is one development roadmap: HTML templating, then a simple web server, then the'),
        dict(slug='thin-server', title='A thin web server in Elixir', one='A minimal HTTP front end for the Portal: a Plug.Router matched and dispatched by Bandit, where e'),
    ],
    "F5.02": [
        dict(slug='api', title="A context's public API", one='Each context exposes a small set of public functions — a smart constructor that validates and re'),
        dict(slug='contexts', title='Bounded contexts', one='A bounded context is a module that owns a few entities and guards their rules — Accounts owns Us'),
        dict(slug='structs', title='Structs & typespecs', one='An entity is a plain struct: @enforce_keys names the fields it cannot exist without, defstruct g'),
    ],
    "F5.03": [
        dict(slug='iterating', title='Iterating the slice', one='Once the skeleton walks, you grow it one thin vertical slice at a time: deliver the first lesson'),
        dict(slug='prototypes', title='Tracer bullets vs prototypes', one='Both are built fast, but their fates are opposite.'),
        dict(slug='skeleton', title='The walking skeleton', one='The enroll-a-learner slice, end to end: a POST /enroll route calls Learning.enroll/2, which buil'),
    ],
    "F5.04": [
        dict(slug='assertions', title='Assertions in Elixir', one='Elixir has no design-by-contract keywords, so contracts are written in its idioms: guards and pa'),
        dict(slug='conditions', title='Preconditions, postconditions & invariants', one='A contract has three parts and three owners.'),
        dict(slug='fail-fast', title='Failing fast', one='Check at the boundary and stop on the first violation, before the struct is built or the store i'),
    ],
    "F5.05": [
        dict(slug='cqs', title='Command/query separation', one='One rule, due to Bertrand Meyer: a function either changes state or returns a value, never both.'),
        dict(slug='events', title='Domain events', one='A record that something happened, written in the past tense and never changed once stored.'),
        dict(slug='reducer', title='The engine as a reducer', one='Once every change is an event, new state is a left fold: the old state plus the next event.'),
    ],
    "F5.06": [
        dict(slug='choosing', title='Choosing where state lives', one='Three places on the BEAM can hold live state, and they are not interchangeable — only one fits the engine.'),
        dict(slug='genserver', title='The engine GenServer', one='Three callbacks carry the whole engine: init folds the log on start, then calls and casts thread state through.'),
        dict(slug='supervision', title='Supervision', one='A stateful process will eventually crash; a supervisor restarts it, and the engine replays its log to recover.'),
    ],
    "F5.07": [
        dict(slug='pure-core', title='Testing the pure core', one="The engine's logic lives in pure functions, so a plain example test — given a state and a command, assert the result — covers the core."),
        dict(slug='property', title='Property-based testing', one='An example test checks the cases you thought of; a property test asserts a rule over the cases a generator invents.'),
        dict(slug='contract-tests', title='Contract tests', one='The F5.04 contract — precondition, postcondition, invariant — becomes three assertions that a command keeps its promises.'),
    ],
    "F5.08": [
        dict(slug='ports', title='Ports & adapters', one='The engine names a port — a behaviour — for each outside dependency; production and tests supply different adapters.'),
        dict(slug='facade', title='The engine facade', one='Ports are how the engine reaches out; the facade is the single door the outside calls in through.'),
        dict(slug='errors', title='Error contracts for the UI', one='A boundary translates every internal failure into one stable error shape the UI can render.'),
    ],
    "F5.09": [
        dict(slug='end-to-end', title='The engine facade end to end', one='Assemble the parts into one supervised system; the F5.04 contracts are what make the wiring hold.'),
        dict(slug='mount', title='A LiveView mount sketch', one='Three LiveView callbacks call the facade and nothing deeper — the UI never reaches past the boundary.'),
        dict(slug='handoff', title='What ships in F6', one='F6 brings Phoenix, but the boundary makes it an addition, not a rewrite: the engine ships unchanged.'),
    ],
}

# Chapter-level context pages (not numbered modules): intro/background pages that
# live directly under a chapter route, e.g. /elixir/language/history. They become
# linkable once the chapter itself is linkable.
CHAPTER_EXTRAS = {
    "F0": [
        dict(slug="csharp", title="Elixir for C# developers", one="An onramp from C# to Elixir."),
    ],
    "F3": [
        dict(slug="history",        title="A short history of Elixir",   one="Where the language came from."),
        dict(slug="timeline",       title="The Elixir release timeline", one="Versions and milestones."),
        dict(slug="under-the-hood", title="Under the hood",              one="How the language runs on the BEAM."),
    ],
    "F5": [
        dict(slug="architecture",  title="The Portal engine blueprint", one="The system this chapter builds, at a glance."),
        dict(slug="domain-model",  title="The domain model",            one="Three bounded contexts and their branded ids."),
        dict(slug="flow",          title="The command & event flow",    one="One use case through the five-stage pipeline."),
    ],
    "F6": [
        dict(slug="journey",   title="The developer journey",              one="Arriving at F6 holding the supervised engine F5 built."),
        dict(slug="blueprint", title="What we're building",                one="The learning platform this chapter builds — a real app, not a framework demo."),
        dict(slug="wiring",    title="Wiring Phoenix onto the F5 engine",  one="The seam the chapter turns on: three small connections, no rewrite."),
    ],
}


def _module_route(mid: str):
    for ch in CHAPTERS:
        for m in MODULES[ch["id"]]:
            if m["n"] == mid:
                return f'{ch["route"]}/{m["slug"]}', m["status"]
    return None, None


def subpages_of(mid: str):
    """(route, title, one) for each subpage of a module."""
    mroute, _ = _module_route(mid)
    if not mroute:
        return []
    return [(f'{mroute}/{s["slug"]}', s["title"], s["one"]) for s in SUBPAGES.get(mid, [])]


def allowed_routes() -> set[str]:
    routes = {ROOT_ROUTE}
    for ch in CHAPTERS:
        if ch["status"] in LINKABLE:
            routes.add(ch["route"])
            for e in CHAPTER_EXTRAS.get(ch["id"], []):
                routes.add(f'{ch["route"]}/{e["slug"]}')
    for cid, mods in MODULES.items():
        chapter = next(c for c in CHAPTERS if c["id"] == cid)
        for m in mods:
            if m["status"] in LINKABLE:
                routes.add(f'{chapter["route"]}/{m["slug"]}')
    # subpages of a module are linkable once the parent module is linkable
    for mid in SUBPAGES:
        mroute, mstatus = _module_route(mid)
        if mroute and mstatus in LINKABLE:
            for s in SUBPAGES[mid]:
                routes.add(f'{mroute}/{s["slug"]}')
    return routes


def module_count() -> int:
    # The six numbered chapters (F1–F6) are the course spine: nine modules each = 54.
    # The optional F0 history chapter and its dives are surfaced separately, so they
    # are not folded into this figure (that is what the landing copy promises).
    return sum(len(MODULES[ch["id"]]) for ch in CHAPTERS if ch["id"] != "F0")


# --------------------------------------------------------------------------- #
# Shared head — jonnify dark-editorial design tokens + base CSS                 #
# --------------------------------------------------------------------------- #
HEAD_CSS = """
:root{
  --ink:#0a0e1a; --ink-2:#10162b; --ink-3:#161d38;
  --cream:#ece4d0; --cream-soft:#d7cfb9; --cream-dim:#a39c89;
  --gold:#d4a85a; --gold-bright:#f0cd7f;
  --blue:#5a87c4; --blue-bright:#9fc0ea;
  --sage:#7ba387; --sage-bright:#a7c9b1;
  --burgundy:#c4504c;
  --elixir:#b39ddb; --elixir-bright:#cdb8f0;
  --line:#2a3252;
  --serif-display:"Cormorant Garamond", Georgia, "Times New Roman", serif;
  --serif:"PT Serif", Georgia, serif;
  --sans:"Manrope", ui-sans-serif, system-ui, sans-serif;
  --mono:"JetBrains Mono", ui-monospace, "SF Mono", Menlo, monospace;
  --measure:68ch;
}
*{box-sizing:border-box}
html{font-size:16px;-webkit-text-size-adjust:100%;scroll-behavior:smooth}
@media (prefers-reduced-motion: reduce){html{scroll-behavior:auto}}
body{
  margin:0; color:var(--cream); background:var(--ink);
  font-family:var(--serif);
  font-size:clamp(1.02rem,0.97rem+0.28vw,1.18rem);
  line-height:1.62; letter-spacing:.005em;
  background-image:
    radial-gradient(1100px 560px at 50% -8%, rgba(179,157,219,.12), transparent 60%),
    radial-gradient(820px 460px at 88% 4%, rgba(212,168,90,.07), transparent 56%),
    radial-gradient(900px 700px at 8% 22%, rgba(90,135,196,.06), transparent 60%);
  background-attachment:fixed;
}
body::after{ /* faint vignette for depth */
  content:""; position:fixed; inset:0; pointer-events:none; z-index:0;
  box-shadow:inset 0 0 240px 40px rgba(4,6,14,.55);
}
.skip{position:absolute;left:-9999px;top:0;background:var(--gold);color:var(--ink);
  padding:.6rem 1rem;border-radius:0 0 10px 0;font-family:var(--sans);font-weight:600;z-index:50}
.skip:focus{left:0}
::selection{background:var(--gold);color:var(--ink)}
img,svg{max-width:100%}
a{color:var(--gold-bright);text-decoration:none}
a:hover{color:var(--cream)}
hr.rule{border:0;height:1px;margin:2.2rem 0;
  background:linear-gradient(90deg,transparent,var(--gold) 18%,var(--gold) 82%,transparent)}

/* ---- layout ---- */
.wrap{max-width:1080px;margin:0 auto;padding:0 clamp(1.1rem,3vw,2.4rem);position:relative;z-index:1}
main{display:block}
section{padding:clamp(2.6rem,6vw,4.6rem) 0}
section + section{border-top:1px solid var(--line)}
.prose{max-width:var(--measure)}
.prose p{margin:0 0 1.05rem}

/* ---- type ---- */
h1,h2,h3,h4{font-family:var(--serif-display);font-weight:600;line-height:1.04;
  letter-spacing:-.01em;color:var(--cream);margin:0 0 .5em}
h1{font-size:clamp(2.7rem,1.9rem+4.2vw,5.1rem);font-weight:600}
h1 .ex{color:var(--elixir-bright);font-style:italic;font-weight:500}
h2{font-size:clamp(1.85rem,1.3rem+1.9vw,2.7rem)}
h3{font-size:clamp(1.3rem,1.1rem+.6vw,1.6rem)}
.eyebrow{font-family:var(--sans);font-weight:600;font-size:.72rem;
  text-transform:uppercase;letter-spacing:.24em;color:var(--gold);
  display:inline-flex;align-items:center;gap:.6rem;margin:0 0 1rem}
.eyebrow::before{content:"";width:26px;height:1px;background:var(--gold);display:inline-block}
.lede{font-family:var(--serif-display);font-weight:500;font-style:italic;
  font-size:clamp(1.25rem,1rem+1vw,1.7rem);line-height:1.32;color:var(--cream-soft);
  max-width:46ch;margin:0 0 1.6rem}
.kicker{font-family:var(--sans);color:var(--cream-dim);font-size:.95rem;max-width:var(--measure)}
.math{font-family:var(--serif);font-style:italic;color:var(--elixir-bright);white-space:nowrap}
strong{color:var(--cream);font-weight:700}

/* ---- site header / footer ---- */
.site{position:sticky;top:0;z-index:30;backdrop-filter:blur(9px);
  background:rgba(10,14,26,.74);border-bottom:1px solid var(--line)}
.site .wrap{display:flex;align-items:center;justify-content:space-between;
  height:58px;font-family:var(--sans)}
.brand{display:inline-flex;align-items:baseline;gap:.5rem;font-family:var(--serif-display);
  font-size:1.32rem;font-weight:600;color:var(--cream);letter-spacing:.01em}
.brand .dot{width:7px;height:7px;border-radius:50%;background:var(--gold);
  display:inline-block;transform:translateY(-2px)}
.brand .sub{font-family:var(--sans);font-size:.66rem;letter-spacing:.22em;
  text-transform:uppercase;color:var(--cream-dim)}
.site nav a{font-size:.82rem;color:var(--cream-soft);letter-spacing:.04em}
.route-tag{font-family:var(--mono);font-size:.78rem;color:var(--gold);
  border:1px solid var(--line);border-radius:999px;padding:.2rem .7rem}
.site-foot{border-top:1px solid var(--line);background:rgba(8,11,22,.6);
  font-family:var(--sans);color:var(--cream-dim);font-size:.86rem}
.site-foot .wrap{padding-top:2.4rem;padding-bottom:3rem;display:flex;
  flex-wrap:wrap;gap:1.4rem 2.4rem;justify-content:space-between;align-items:flex-start}

/* ---- hero ---- */
.hero{padding-top:clamp(3rem,8vw,6rem)}
.hero .cta-row{display:flex;flex-wrap:wrap;gap:.8rem;margin-top:1.7rem}
.btn{font-family:var(--sans);font-weight:600;font-size:.92rem;letter-spacing:.02em;
  display:inline-flex;align-items:center;gap:.55rem;padding:.72rem 1.25rem;border-radius:12px;
  border:1px solid var(--gold);color:var(--ink);background:var(--gold);
  transition:transform .18s ease, box-shadow .18s ease, background .18s ease}
.btn:hover{background:var(--gold-bright);color:var(--ink);transform:translateY(-2px);
  box-shadow:0 10px 30px -12px rgba(212,168,90,.6)}
.btn.ghost{background:transparent;color:var(--gold-bright);border-color:var(--line)}
.btn.ghost:hover{border-color:var(--gold);color:var(--cream);box-shadow:none}
.hero-motif{margin-top:2.4rem;width:100%;height:auto;display:block;opacity:.9}

/* ---- figures / takeaways ---- */
.fig{margin:1.8rem 0 0;border:1px solid var(--line);border-radius:16px;
  background:linear-gradient(180deg,rgba(16,22,43,.6),rgba(10,14,26,.35));
  padding:clamp(1rem,2.4vw,1.6rem)}
.fig svg{display:block;width:100%;height:auto}
.take{margin:1.1rem 0 0;font-family:var(--serif-display);font-style:italic;
  font-size:1.18rem;line-height:1.35;color:var(--cream-soft);
  padding-left:1rem;border-left:2px solid var(--gold)}

/* ---- interactive shells (shared with lesson pages) ---- */
.solid-select{display:flex;flex-wrap:wrap;gap:.5rem}
.solid-select button{font-family:var(--sans);font-weight:600;font-size:.84rem;
  cursor:pointer;padding:.5rem .9rem;border-radius:10px;color:var(--cream-soft);
  background:var(--ink-2);border:1px solid var(--line);transition:.16s ease}
.solid-select button:hover{border-color:var(--cream-dim)}
.solid-select button.active{color:var(--ink);border-color:transparent}
.solid-select button.active[data-c="blue"]{background:var(--blue-bright)}
.solid-select button.active[data-c="sage"]{background:var(--sage-bright)}
.solid-select button.active[data-c="gold"]{background:var(--gold-bright)}
.solid-select button.active[data-c="elixir"]{background:var(--elixir-bright)}
.fold-ctrl{display:flex;align-items:center;gap:1rem;margin:.2rem 0;font-family:var(--sans)}
.fold-ctrl label{min-width:7.5rem;font-size:.86rem;color:var(--cream-soft);letter-spacing:.03em}
.fold-ctrl input[type=range]{flex:1;accent-color:var(--gold);height:2px}
.fold-ctrl .val{font-family:var(--mono);color:var(--gold-bright);min-width:2.5rem;text-align:right}
.geo-readout{font-family:var(--mono);font-size:.95rem;color:var(--gold-bright);
  background:var(--ink);border:1px solid var(--line);border-radius:10px;
  padding:.7rem .9rem;margin-top:1rem;overflow-x:auto;white-space:nowrap}
.geo-readout .dim{color:var(--cream-dim)}
.controls{display:flex;flex-wrap:wrap;gap:1.4rem 2rem;align-items:center;margin-bottom:1rem}

/* ---- code ---- */
pre.code{font-family:var(--mono);font-size:.92rem;line-height:1.6;color:var(--cream);
  background:var(--ink);border:1px solid var(--line);border-radius:12px;
  padding:1rem 1.1rem;margin:1rem 0 0;overflow-x:auto;white-space:pre}
pre.code .op{color:var(--elixir-bright)}
pre.code .fn{color:var(--cream)}
pre.code .fn.blue{color:var(--blue-bright)}
pre.code .fn.sage{color:var(--sage-bright)}
pre.code .fn.gold{color:var(--gold-bright)}
pre.code .res{color:var(--gold-bright)}
pre.code .cmt{color:var(--cream-dim)}
code.inl{font-family:var(--mono);font-size:.9em;color:var(--elixir-bright);
  background:var(--ink-2);border:1px solid var(--line);border-radius:6px;padding:.05em .4em}

/* ---- arc svg ---- */
.arc-node rect{transition:fill .2s ease, stroke .2s ease}
.arc-node{cursor:pointer}
.arc-node .num{font-family:var(--serif-display);font-weight:600;fill:var(--cream)}
.arc-node .nm{font-family:var(--sans);font-weight:600;fill:var(--cream-dim);letter-spacing:.02em}
.arc-node:hover rect{stroke:var(--cream-dim)}
.arc-node.active rect{fill:var(--ink-3);stroke:var(--elixir-bright)}
.arc-node.active .num{fill:var(--gold-bright)}
.arc-node.active .nm{fill:var(--elixir-bright)}
.arc-node:focus{outline:none}
.arc-node:focus-visible rect{stroke:var(--gold-bright)}
.arc-flow{stroke:var(--line);stroke-width:2;fill:none;stroke-dasharray:6 9}
.arc-arrow{fill:var(--cream-dim)}
@media (prefers-reduced-motion: no-preference){
  .arc-flow{animation:flow 1.6s linear infinite}
}
@keyframes flow{to{stroke-dashoffset:-30}}
.arc-readout{margin-top:1.1rem}
.arc-readout .nm{font-family:var(--serif-display);font-size:1.5rem;color:var(--cream);font-weight:600}
.arc-readout .one{font-family:var(--serif);color:var(--cream-soft);margin:.25rem 0 .5rem;max-width:60ch}
.arc-readout .meta{font-family:var(--sans);font-size:.82rem;color:var(--cream-dim);
  display:flex;flex-wrap:wrap;gap:.4rem 1.2rem;align-items:center}
.arc-readout .meta b{color:var(--gold)}
.arc-open{margin-top:.7rem;font-family:var(--sans);font-size:.9rem}
.arc-open .muted{color:var(--cream-dim)}

/* ---- contents directory ---- */
.legend{display:flex;flex-wrap:wrap;gap:.6rem 1.1rem;font-family:var(--sans);
  font-size:.78rem;color:var(--cream-dim);margin:.4rem 0 1.8rem}
.legend span{display:inline-flex;align-items:center;gap:.45rem}
.pill{font-family:var(--sans);font-size:.64rem;font-weight:700;text-transform:uppercase;
  letter-spacing:.12em;padding:.18rem .5rem;border-radius:999px;border:1px solid}
.pill.live{color:var(--sage-bright);border-color:var(--sage)}
.pill.built{color:var(--gold-bright);border-color:var(--gold)}
.pill.planned{color:var(--blue-bright);border-color:var(--blue)}
.pill.soon{color:var(--elixir-bright);border-color:var(--elixir)}
.chap{padding-top:2.2rem}
.chap:first-of-type{padding-top:.4rem}
.chap-head{display:flex;flex-wrap:wrap;align-items:baseline;gap:.5rem 1rem;
  padding-bottom:.6rem;border-bottom:1px solid var(--line);margin-bottom:1.1rem}
.chap-head .cid{font-family:var(--mono);font-size:.95rem;color:var(--gold)}
.chap-head h3{margin:0}
.chap-head .c-one{font-family:var(--sans);font-size:.86rem;color:var(--cream-dim);
  flex-basis:100%;margin-top:.1rem}
.chap-head .chap-link{font-family:var(--sans);font-size:.82rem;margin-left:auto}
.mods{display:grid;grid-template-columns:repeat(3,1fr);gap:.8rem}
.mod{display:block;border:1px solid var(--line);border-radius:13px;padding:.85rem .95rem;
  background:linear-gradient(180deg,rgba(16,22,43,.5),rgba(10,14,26,.3));
  transition:transform .16s ease, border-color .16s ease, box-shadow .16s ease}
a.mod:hover{transform:translateY(-3px);border-color:var(--gold);
  box-shadow:0 14px 34px -18px rgba(212,168,90,.5)}
.mod .top{display:flex;align-items:center;justify-content:space-between;gap:.5rem;margin-bottom:.35rem}
.mod .num{font-family:var(--mono);font-size:.78rem;color:var(--gold)}
.mod .t{font-family:var(--serif-display);font-size:1.14rem;font-weight:600;
  color:var(--cream);line-height:1.12;margin:0 0 .25rem}
.mod .o{font-family:var(--sans);font-size:.8rem;color:var(--cream-dim);line-height:1.4}
.mod.is-quiet{opacity:.66;border-style:dashed}
.mod.is-quiet .t{color:var(--cream-soft)}
.mod.lab{border-left:2px solid var(--elixir)}
.mod.lab .num::after{content:" · lab";color:var(--elixir-bright)}
.dives{list-style:none;margin:.6rem 0 0;padding:.6rem 0 0;border-top:1px dashed var(--line);
  font-family:var(--sans);font-size:.78rem;color:var(--cream-dim);display:grid;gap:.3rem}
.dives li{display:flex;gap:.5rem}
.dives .dn{font-family:var(--mono);color:var(--gold);min-width:3.6rem}

/* ---- pager ---- */
.pager{display:flex;flex-wrap:wrap;gap:1rem;justify-content:space-between;
  align-items:center;font-family:var(--sans)}
.pager .p-left{color:var(--cream-dim);font-size:.9rem}
.pager .spacer{flex:1}

/* ---- branded stamp ---- */
.stamp{font-family:var(--mono);font-size:.8rem;color:var(--cream-dim);
  cursor:pointer;border:1px solid var(--line);border-radius:10px;padding:.45rem .7rem;
  background:var(--ink);user-select:none}
.stamp:hover{border-color:var(--gold)}
.stamp .id{color:var(--gold-bright)}
.stamp .panel{display:none;margin-top:.6rem;color:var(--cream-soft);
  display:none;grid-template-columns:auto 1fr;gap:.25rem .9rem;font-size:.76rem}
.stamp.open .panel{display:grid}
.stamp .panel dt{color:var(--cream-dim)}
.stamp .panel dd{margin:0;color:var(--cream)}
.colophon{max-width:42ch}
.colophon b{color:var(--cream-soft)}

/* ---- reveal (JS-gated; content visible without JS) ---- */
html.js .reveal{opacity:0;transform:translateY(14px)}
html.js .reveal.in{opacity:1;transform:none;transition:opacity .7s ease, transform .7s ease}
@media (prefers-reduced-motion: reduce){
  html.js .reveal,html.js .reveal.in{opacity:1;transform:none;transition:none}
}

/* ---- responsive ---- */
@media (max-width:760px){
  .mods{grid-template-columns:1fr}
  .site nav{display:none}
  .lede{max-width:none}
  .take{font-size:1.08rem}
}

/* ---- module / lesson page additions (additive; shared head) ---- */
.crumbs{font-family:var(--sans);font-size:.8rem;color:var(--cream-dim);
  display:flex;flex-wrap:wrap;gap:.5rem;align-items:center;margin:0 0 1.1rem}
.crumbs a{color:var(--cream-soft)}
.crumbs .sep{opacity:.45}
.crumbs .here{color:var(--gold)}
.toc-mini{display:flex;flex-wrap:wrap;gap:.5rem;font-family:var(--sans);font-size:.82rem;margin:1.4rem 0 0}
.toc-mini a{border:1px solid var(--line);border-radius:999px;padding:.32rem .85rem;color:var(--cream-soft)}
.toc-mini a:hover{border-color:var(--gold);color:var(--cream)}
.bridge{display:grid;grid-template-columns:1fr auto 1fr;gap:1rem;align-items:stretch;margin:1.7rem 0 0}
.bridge .cell{border:1px solid var(--line);border-radius:14px;padding:1rem 1.1rem;
  background:linear-gradient(180deg,rgba(16,22,43,.55),rgba(10,14,26,.3))}
.bridge .cell .lbl{font-family:var(--sans);font-size:.64rem;letter-spacing:.18em;
  text-transform:uppercase;margin:0 0 .55rem;color:var(--cream-dim)}
.bridge .cell.idea .lbl{color:var(--gold)}
.bridge .cell.elix .lbl{color:var(--elixir-bright)}
.bridge .cell p{margin:0;font-family:var(--serif);font-size:.98rem;color:var(--cream-soft)}
.bridge .arrow{align-self:center;font-family:var(--serif-display);font-size:1.7rem;color:var(--cream-dim)}
@media (max-width:760px){
  .bridge{grid-template-columns:1fr;gap:.7rem}
  .bridge .arrow{justify-self:center;transform:rotate(90deg)}
}
.dive{scroll-margin-top:74px}
.dive-head{display:flex;flex-wrap:wrap;align-items:baseline;gap:.5rem .9rem;margin:0 0 .5em}
.dive-tag{font-family:var(--mono);font-size:.72rem;color:var(--elixir-bright);
  border:1px solid var(--elixir);border-radius:999px;padding:.14rem .6rem}
.deflist{display:grid;grid-template-columns:auto 1fr;gap:.35rem 1rem;
  font-family:var(--sans);font-size:.86rem;margin:1.1rem 0 0}
.deflist dt{color:var(--gold);font-family:var(--mono);font-size:.82rem}
.deflist dd{margin:0;color:var(--cream-soft)}
.note{font-family:var(--sans);font-size:.88rem;color:var(--cream-dim);
  border-left:2px solid var(--blue);padding-left:.95rem;margin:1.5rem 0 0}
pre.code .rdx{background:rgba(179,157,219,.18);border-radius:4px;padding:0 .18em;color:var(--elixir-bright)}
pre.code .step{color:var(--cream-dim)}
.lin-arrow{fill:var(--cream-dim)}
"""

HEAD_HTML = (
    "<head>\n"
    '<meta charset="utf-8">\n'
    '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
    "<title>{{TITLE}}</title>\n"
    '<meta name="description" content="{{DESC}}">\n'
    '<link rel="preconnect" href="https://fonts.googleapis.com">\n'
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n'
    '<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;0,700;1,500;1,600&family=PT+Serif:ital,wght@0,400;0,700;1,400&family=Manrope:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;700&display=swap" rel="stylesheet">\n'
    "<style>" + HEAD_CSS + "</style>\n"
    "</head>"
)

BOOTSTRAP = """<script>
/* progressive enhancement: mark JS on, then reveal-on-scroll */
document.documentElement.classList.add('js');
document.addEventListener('DOMContentLoaded', function () {
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var els = document.querySelectorAll('.reveal');
  if (reduce || !('IntersectionObserver' in window)) {
    els.forEach(function (e) { e.classList.add('in'); });
    return;
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (en) {
      if (en.isIntersecting) { en.target.classList.add('in'); io.unobserve(en.target); }
    });
  }, { threshold: 0.12 });
  els.forEach(function (e) { io.observe(e); });
});
</script>"""


# --------------------------------------------------------------------------- #
# Contents directory + arc data (generated from the manifest)                  #
# --------------------------------------------------------------------------- #
def esc(s: str) -> str:
    return _html.escape(s, quote=True)


def _pill(status: str) -> str:
    return f'<span class="pill {status}">{status}</span>'


def _module_card(chapter: dict, m: dict) -> str:
    classes = ["mod"]
    if m.get("lab"):
        classes.append("lab")
    linkable = m["status"] in LINKABLE
    if not linkable:
        classes.append("is-quiet")
    cls = " ".join(classes)
    route = f'{chapter["route"]}/{m["slug"]}'
    inner = (
        f'<div class="top"><span class="num">{esc(m["n"])}</span>{_pill(m["status"])}</div>'
        f'<p class="t">{esc(m["title"])}</p>'
        f'<p class="o">{esc(m["one"])}</p>'
    )
    dives = m.get("dives")
    if dives:
        items = "".join(
            f'<li><span class="dn">{esc(d["n"])}</span><span>{esc(d["title"])}</span></li>'
            for d in dives
        )
        inner += f'<ul class="dives">{items}</ul>'
    if linkable:
        return f'<a class="{cls}" href="{esc(route)}">{inner}</a>'
    return f'<div class="{cls}">{inner}</div>'


def render_contents() -> str:
    out = []
    for ch in CHAPTERS:
        head = [f'<div class="chap-head">',
                f'<span class="cid">{esc(ch["id"])}</span>',
                f'<h3>{esc(ch["title"])}</h3>']
        if ch["status"] in LINKABLE:
            head.append(
                f'<a class="chap-link" href="{esc(ch["route"])}">Open chapter →</a>')
        else:
            head.append(f'{_pill(ch["status"])}')
        head.append(f'<p class="c-one">{esc(ch["one"])}</p>')
        head.append("</div>")
        cards = "".join(_module_card(ch, m) for m in MODULES[ch["id"]])
        out.append(
            f'<section class="chap reveal">{"".join(head)}'
            f'<div class="mods">{cards}</div></section>'
        )
    return "\n".join(out)


def chapters_json() -> str:
    data = []
    for ch in CHAPTERS:
        if ch["id"] == "F0":
            continue  # the arc shows the F1..F6 spine
        data.append({
            "id": ch["id"],
            "name": ch["title"],
            "route": ch["route"],
            "live": ch["status"] in LINKABLE,
            "modules": len(MODULES[ch["id"]]),
            "one": ch["one"],
            "reuses": ch["reuses"],
        })
    return json.dumps(data, ensure_ascii=False)


# --------------------------------------------------------------------------- #
# Apollo — quality gates                                                       #
# --------------------------------------------------------------------------- #
FORBIDDEN = re.compile(
    r"\b(revolutionary|blazing[\s-]?fast|magical|simply|just|obviously|effortless)\b",
    re.I,
)
CONTAINER_TAGS = {"div", "section", "main", "header", "footer", "nav",
                  "article", "figure", "aside"}
TAG_RE = re.compile(r"<(/?)([a-zA-Z][\w-]*)([^>]*?)(/?)>")


def _strip_code(s: str) -> str:
    s = re.sub(r"<script\b[^>]*>.*?</script>", " ", s, flags=re.S | re.I)
    s = re.sub(r"<style\b[^>]*>.*?</style>", " ", s, flags=re.S | re.I)
    return s


def _visible_text(s: str) -> str:
    s = _strip_code(s)
    s = re.sub(r"<svg\b[^>]*>.*?</svg>", " ", s, flags=re.S | re.I)
    s = re.sub(r"<[^>]+>", " ", s)
    return _html.unescape(s)


def gate_containers(doc: str):
    body = _strip_code(doc)
    body = re.sub(r"<svg\b[^>]*>.*?</svg>", " ", body, flags=re.S | re.I)
    stack = []
    for m in TAG_RE.finditer(body):
        closing, name, _attrs, selfclose = m.group(1), m.group(2).lower(), m.group(3), m.group(4)
        if name not in CONTAINER_TAGS:
            continue
        if selfclose:
            continue
        if closing:
            if not stack or stack[-1][0] != name:
                top = stack[-1][0] if stack else "—"
                return False, f"unbalanced </{name}> (open container was <{top}>)"
            stack.pop()
        else:
            stack.append((name, m.start()))
    if stack:
        nm = stack[-1][0]
        return False, f"unclosed <{nm}> — check for a missing </div> in a section"
    return True, "container tags balanced"


def gate_svg_wellformed(doc: str):
    o = len(re.findall(r"<svg\b", doc, re.I))
    c = len(re.findall(r"</svg>", doc, re.I))
    if o == 0:
        return False, "no <svg> present — every page carries a seen argument"
    if o != c:
        return False, f"svg open/close mismatch ({o} open, {c} close)"
    return True, f"{o} svg block(s), well formed"


def gate_no_future(doc: str):
    return ("/future" not in doc), ("no /future links" if "/future" not in doc
                                    else "found a link to /future")


def gate_forbidden(doc: str):
    hits = sorted({h.group(0).lower() for h in FORBIDDEN.finditer(_visible_text(doc))})
    return (not hits), ("no hype / dismissive words" if not hits
                        else "forbidden words: " + ", ".join(hits))


def gate_storage(doc: str):
    bad = re.search(r"\b(localStorage|sessionStorage)\b", doc)
    return (bad is None), ("no web storage APIs" if bad is None
                           else "uses " + bad.group(0))


def gate_reduced_motion(doc: str):
    ok = "prefers-reduced-motion" in doc
    return ok, ("honours prefers-reduced-motion" if ok
                else "missing prefers-reduced-motion handling")


def gate_reveal_degrades(doc: str):
    if ".reveal" not in doc:
        return True, "no reveal animation"
    ok = "html.js .reveal" in doc or ".js .reveal" in doc
    return ok, ("reveal is JS-gated; content visible without JS" if ok
                else "reveal hides content without a JS gate")


def gate_links(doc: str):
    allowed = allowed_routes()
    bad = []
    for m in re.finditer(r'href="([^"]+)"', doc):
        href = m.group(1)
        if href.startswith(("#", "http://", "https://", "mailto:", "tel:", "//")):
            continue
        if href in allowed:
            continue
        bad.append(href)
    bad = sorted(set(bad))
    return (not bad), ("all internal links resolve to live/built routes"
                       if not bad else "dangling internal links: " + ", ".join(bad))


def gate_pager(doc: str):
    if 'class="pager"' not in doc:
        return False, "no .pager navigation block"
    allowed = allowed_routes()
    has = any(m.group(1) in allowed
              for m in re.finditer(r'href="([^"]+)"', doc))
    return has, ("pager links to a real route" if has
                 else "pager has no link to a live/built route")


APOLLO_GATES = [
    ("containers", gate_containers),
    ("svg",        gate_svg_wellformed),
    ("no-future",  gate_no_future),
    ("voice",      gate_forbidden),
    ("storage",    gate_storage),
    ("motion",     gate_reduced_motion),
    ("degrade",    gate_reveal_degrades),
    ("links",      gate_links),
    ("pager",      gate_pager),
]


def apollo(doc: str):
    results = [(name, *fn(doc)) for name, fn in APOLLO_GATES]
    passed = all(ok for _, ok, _ in results)
    return passed, results


def print_apollo(path: str, passed: bool, results) -> None:
    print(f"\nApollo · {path}")
    for name, ok, detail in results:
        mark = "PASS" if ok else "FAIL"
        print(f"  [{mark}] {name:<11} {detail}")
    grade = "A+" if passed else "—"
    print(f"  grade: {grade}")
    print(f"STATUS: {'PASS' if passed else 'FAIL'}")


# --------------------------------------------------------------------------- #
# Build                                                                        #
# --------------------------------------------------------------------------- #
PAGES = {
    # key -> (content fragment, output file, title, description)
    "landing": (
        "content/f0-00-landing.html",
        "index.html",
        "Functional Programming in Elixir — a jonnify course",
        "A bridge from the algebra you already know to real-time apps on the BEAM. "
        "Six chapters, fifty-four modules, interactive and runnable throughout.",
    ),
    "f0-1": (
        "content/f0-01-fp-evolution.html",
        "fp-evolution.html",
        "The evolution of functional languages & runtimes \u2014 F0.1 \u00b7 jonnify",
        "From the lambda calculus to LISP, the ML and Haskell branch, and the "
        "immutable turn \u2014 the lineage Elixir inherited, each idea paired with its Elixir form.",
    ),
    "f0-2": (
        "content/f0-02-beam-evolution.html",
        "beam-evolution.html",
        "The evolution of Erlang, the BEAM & OTP \u2014 F0.2 \u00b7 jonnify",
        "Telecom roots and \u201clet it crash\u201d, the reduction-counting scheduler and per-process heaps, "
        "and the OTP supervision tree \u2014 the runtime Elixir stands on.",
    ),
    "f1-1": (
        "content/f1-01-functions.html",
        "functions.html",
        "What a function really is \u2014 F1.01 \u00b7 jonnify",
        "A function as a mapping: domain, codomain, and range; the single-output rule; and the "
        "first-class function as an ordinary Elixir value.",
    ),
    "f1-2": (
        "content/f1-02-substitution.html",
        "substitution.html",
        "The substitution model \u2014 F1.02 \u00b7 jonnify",
        "Equals for equals: evaluation by substitution, referential transparency, and the purity "
        "that makes a function safe to replace with its result.",
    ),
    "f1-3": (
        "content/f1-03-composition.html",
        "composition.html",
        "Composition, f\u2218g \u2014 F1.03 \u00b7 jonnify",
        "Chaining functions into new ones: the composite g\u2218f, why order matters and grouping is free, "
        "and the pipe as composition written in evaluation order.",
    ),
    "f1-4": (
        "content/f1-04-immutability.html",
        "immutability.html",
        "Immutability & binding \u2014 F1.04 \u00b7 jonnify",
        "A name is a fixed value, not a box: binding versus rebinding, the match operator and the pin, "
        "and immutable data whose updates return new values.",
    ),
    "f1-5": (
        "content/f1-05-collections.html",
        "collections.html",
        "Sets, sequences & mappings \u2014 F1.05 \u00b7 jonnify",
        "Three shapes of collection \u2014 ordered lists, distinct MapSets, key-to-value Maps \u2014 and Enum.map, "
        "the operation that applies a function across any of them.",
    ),
    "f1-6": (
        "content/f1-06-recursion.html",
        "recursion.html",
        "Recursion & induction \u2014 F1.06 \u00b7 jonnify",
        "Base case plus step: the call stack of a recursive sum, why the base case makes it terminate, "
        "and induction \u2014 the proof that shares recursion's shape.",
    ),
    "f1-7": (
        "content/f1-07-higher-order.html",
        "higher-order.html",
        "Higher-order operators (\u03a3, \u03a0) \u2014 F1.07 \u00b7 jonnify",
        "\u03a3 and \u03a0 as operators over a function, the map / filter / reduce trio and how each reshapes a "
        "collection, and reduce as the general fold the others are instances of.",
    ),
    "f1-8": (
        "content/f1-08-pattern-matching.html",
        "pattern-matching.html",
        "Equations & pattern matching \u2014 F1.08 \u00b7 jonnify",
        "Solving by structure: destructuring tuples, lists and maps, dispatching control by shape, "
        "and guards that refine a match by value.",
    ),
    "f1-9": (
        "content/f1-09-plotting-lab.html",
        "plotting-lab.html",
        "Functions on the plane \u2014 F1.09 \u00b7 jonnify",
        "The F1 lab: a coordinate plotter for f, g, and their composites, with an x-trace that follows a "
        "value through f\u2218g \u2014 plotting as Enum.map, composition as a pipeline.",
    ),
    "f2-landing": (
        "content/f2-00-landing.html",
        "functional.html",
        "F2 \u00b7 Functional Programming \u2014 jonnify",
        "The Functional Programming chapter: pure functions, persistent data, higher-order functions, "
        "folds, closures, and composition \u2014 a guided path through nine modules ending in a data-pipeline lab.",
    ),
    "f2-1": (
        "content/f2-01-pure.html",
        "pure.html",
        "Pure functions & side effects \u2014 F2.01 \u00b7 jonnify",
        "What purity buys and how to keep it: same input gives the same output, what counts as a side "
        "effect, and the functional core / imperative shell that isolates effects at the edges.",
    ),
    "f2-2": (
        "content/f2-02-persistence.html",
        "persistence.html",
        "Immutability & persistent data \u2014 F2.02 \u00b7 jonnify",
        "Why copying is cheap: immutable values, structural sharing in lists and maps, and the "
        "memory cost of a full copy versus rebuilding only what changed.",
    ),
    "f2-3": (
        "content/f2-03-higher-order.html",
        "higher-order-functions.html",
        "Higher-order functions \u2014 F2.03 \u00b7 jonnify",
        "Functions as values: passing a function into Enum.map, the differing signatures map / filter / "
        "reduce / sort_by expect, and a factory that returns a function carrying a captured value.",
    ),
    "f2-4": (
        "content/f2-04-recursion.html",
        "recursion-functional.html",
        "Recursion patterns & tail calls \u2014 F2.04 \u00b7 jonnify",
        "Recursion as the functional way to repeat: the call stack, tail calls and accumulators for "
        "constant stack space, and the patterns that recur \u2014 across three deep-dive subpages.",
    ),
    "f2-4-shape": (
        "content/f2-04-1-shape.html",
        "recursion-shape.html",
        "The shape of recursion \u2014 F2.04.1 \u00b7 jonnify",
        "Base case and recursive case, and the call stack growing then unwinding as a body-recursive "
        "function runs to a result.",
    ),
    "f2-4-tail": (
        "content/f2-04-2-tail-calls.html",
        "recursion-tail-calls.html",
        "Tail calls & accumulators \u2014 F2.04.2 \u00b7 jonnify",
        "Body versus tail recursion, the accumulator pattern, and how a tail call reuses the stack frame "
        "to run in constant space.",
    ),
    "f2-4-patterns": (
        "content/f2-04-3-patterns.html",
        "recursion-patterns.html",
        "Recursion patterns \u2014 F2.04.3 \u00b7 jonnify",
        "sum, length, reverse, map, and filter written recursively \u2014 and why each one is a fold over the list.",
    ),
    "f2-5": (
        "content/f2-05-folds.html",
        "folds.html",
        "map / filter / reduce (folds) \u2014 F2.05 \u00b7 jonnify",
        "reduce as the universal fold: how the accumulator threads through a list, how swapping the "
        "combiner changes the result, and how map and filter are reduce with a list accumulator.",
    ),
    "f2-5-map": (
        "content/f2-05-1-map.html",
        "folds-map.html",
        "map \u2014 F2.05.1 \u00b7 jonnify",
        "Transforming every element with a function: one-to-one output, length and order preserved, and "
        "why chained maps fuse into one.",
    ),
    "f2-5-filter": (
        "content/f2-05-2-filter.html",
        "folds-filter.html",
        "filter \u2014 F2.05.2 \u00b7 jonnify",
        "Keeping elements that pass a predicate: filter and its inverse reject, and filtering then mapping "
        "as a pipeline.",
    ),
    "f2-5-reduce": (
        "content/f2-05-3-reduce.html",
        "folds-reduce.html",
        "reduce \u2014 F2.05.3 \u00b7 jonnify",
        "The general fold: accumulators of any shape \u2014 numbers, lists, maps \u2014 and building a frequency "
        "map step by step.",
    ),
    "f2-5-advanced": (
        "content/f2-05-4-advanced.html",
        "folds-advanced.html",
        "Advanced folds \u2014 F2.05.4 \u00b7 jonnify",
        "The Enum toolkit as folds with extra structure: scan as a running fold, plus map_reduce, "
        "flat_map, group_by, and frequencies.",
    ),
}


def cmd_extract_head(_args) -> int:
    (ROOT / "_head.html").write_text(HEAD_HTML, encoding="utf-8")
    print("wrote _head.html")
    return 0


def _assemble(fragment: str, title: str, desc: str) -> str:
    head = (ROOT / "_head.html").read_text(encoding="utf-8")
    head = head.replace("{{TITLE}}", esc(title)).replace("{{DESC}}", esc(desc))
    build_id = mint("TSK")
    info = decode(build_id)
    fragment = (fragment
                .replace("{{CONTENTS}}", render_contents())
                .replace("{{CHAPTERS_JSON}}", chapters_json())
                .replace("{{BUILD_ID}}", build_id)
                .replace("{{BUILD_TS}}", info["timestamp"])
                .replace("{{MODULE_COUNT}}", str(module_count())))
    return ("<!doctype html>\n<html lang=\"en\">\n"
            + head + "\n<body>\n" + fragment + "\n" + BOOTSTRAP + "\n</body>\n</html>\n")


def _build_one(key: str) -> bool:
    frag_path, out_name, title, desc = PAGES[key]
    if not (ROOT / "_head.html").exists():
        print("error: _head.html missing — run `extract-head` first", file=sys.stderr)
        return False
    fragment = (ROOT / frag_path).read_text(encoding="utf-8")
    doc = _assemble(fragment, title, desc)
    out = ROOT / out_name
    out.write_text(doc, encoding="utf-8")
    print(f"built {out_name}  ({len(doc):,} bytes)  from {frag_path}")
    passed, results = apollo(doc)
    print_apollo(out_name, passed, results)
    return passed


def cmd_build(args) -> int:
    keys = list(PAGES) if args.all else [args.page]
    if not args.all and args.page not in PAGES:
        print(f"unknown page '{args.page}'. known: {', '.join(PAGES)}", file=sys.stderr)
        return 2
    ok = True
    for k in keys:
        ok = _build_one(k) and ok
    return 0 if ok else 1


def cmd_check(args) -> int:
    ok = True
    for p in args.files:
        doc = Path(p).read_text(encoding="utf-8")
        passed, results = apollo(doc)
        print_apollo(p, passed, results)
        ok = passed and ok
    return 0 if ok else 1


def cmd_manifest(_args) -> int:
    print(f"{'ID':<8} {'STATUS':<8} TITLE")
    for ch in CHAPTERS:
        print(f"{ch['id']:<8} {ch['status']:<8} {ch['title']}  [{ch['route']}]")
        for m in MODULES[ch["id"]]:
            lab = " (lab)" if m.get("lab") else ""
            print(f"  {m['n']:<6} {m['status']:<8} {m['title']}{lab}")
            for d in m.get("dives", []):
                print(f"    {d['n']:<6} {d['status']:<8} {d['title']}")
    print(f"\ntotal modules (incl. dives): {module_count()}")
    return 0


def cmd_routes(_args) -> int:
    rows = [("ROOT", "live", ROOT_ROUTE, "index.html")]
    for ch in CHAPTERS:
        rows.append((ch["id"], ch["status"], ch["route"], "—"))
        for m in MODULES[ch["id"]]:
            rows.append((m["n"], m["status"], f"{ch['route']}/{m['slug']}", "—"))
    for cid, status, route, f in rows:
        link = "link" if status in LINKABLE else "card"
        print(f"{cid:<8} {status:<8} {link:<5} {route}")
    return 0


def cmd_id(args) -> int:
    if args.id_cmd == "mint":
        at = datetime.fromisoformat(args.at).astimezone(timezone.utc) if args.at else None
        print(mint(args.ns, node=args.node, seq=args.seq, at=at))
    else:
        for k, v in decode(args.branded).items():
            print(f"{k:<11}: {v}")
    return 0


# --------------------------------------------------------------------------- #
# CLI                                                                          #
# --------------------------------------------------------------------------- #
def main(argv=None) -> int:
    p = argparse.ArgumentParser(prog="build_page.py", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("extract-head").set_defaults(func=cmd_extract_head)

    b = sub.add_parser("build")
    b.add_argument("--page", default="landing")
    b.add_argument("--all", action="store_true")
    b.set_defaults(func=cmd_build)

    c = sub.add_parser("check")
    c.add_argument("files", nargs="+")
    c.set_defaults(func=cmd_check)

    sub.add_parser("manifest").set_defaults(func=cmd_manifest)
    sub.add_parser("routes").set_defaults(func=cmd_routes)

    i = sub.add_parser("id")
    isub = i.add_subparsers(dest="id_cmd", required=True)
    im = isub.add_parser("mint")
    im.add_argument("--ns", default="TSK")
    im.add_argument("--node", type=int, default=0)
    im.add_argument("--seq", type=int, default=0)
    im.add_argument("--at", default=None, help="ISO 8601, e.g. 2026-01-27T15:11:37Z")
    id_ = isub.add_parser("decode")
    id_.add_argument("branded")
    i.set_defaults(func=cmd_id)

    args = p.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
