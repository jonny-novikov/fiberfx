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
         status="planned",
         one="Real-world engineering: structure, testing, telemetry, releases.",
         reuses="Builds on F4 · Algorithms & Data Structures.",
         accent="sage"),
    dict(id="F6", title="Phoenix Framework", slug="phoenix", route="/elixir/phoenix",
         status="planned",
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
        dict(n="F4.01", title="Lists, recursion & complexity", one="Cons cells; big-O on the BEAM.", slug="lists", status="built", lab=False,
             dives=[
                 dict(n="F4.01.1", title="Cons cells & the shape of a list", slug="cons", status="built"),
                 dict(n="F4.01.2", title="Recursion over lists", slug="recursion", status="built"),
                 dict(n="F4.01.3", title="Complexity & big-O on the BEAM", slug="big-o", status="built"),
             ]),
        dict(n="F4.02", title="Trees & traversals", one="Binary and n-ary trees; DFS/BFS, functionally.", slug="trees", status="built", lab=False,
             dives=[
                 dict(n="F4.02.1", title="Binary trees & recursive shape", slug="shape", status="soon"),
                 dict(n="F4.02.2", title="Depth-first: pre, in, post-order", slug="dfs", status="soon"),
                 dict(n="F4.02.3", title="Breadth-first & balance", slug="bfs", status="soon"),
             ]),
        dict(n="F4.03", title="Sorting & searching", one="Merge/quick sort and binary search, immutably.", slug="sorting", status="built", lab=False,
             dives=[
                 dict(n="F4.03.1", title="Merge & quicksort", slug="sorts", status="soon"),
                 dict(n="F4.03.2", title="Linear & binary search", slug="search", status="soon"),
                 dict(n="F4.03.3", title="Stability & sort cost", slug="cost", status="soon"),
             ]),
        dict(n="F4.04", title="Maps, sets & hashing", one="Hash maps, collisions, the cost model.", slug="maps", status="built", lab=False,
             dives=[
                 dict(n="F4.04.1", title="Maps & key lookup", slug="lookup", status="built"),
                 dict(n="F4.04.2", title="MapSet & membership", slug="sets", status="built"),
                 dict(n="F4.04.3", title="Hashing & collisions", slug="hashing", status="built"),
             ]),
        dict(n="F4.05", title="Hash Array Mapped Tries (HAMT)", one="Persistent maps via prefix trees.", slug="hamt", status="planned", lab=False,
             dives=[
                 dict(n="F4.05.1", title="Bitmapped nodes", slug="bitmap", status="soon"),
                 dict(n="F4.05.2", title="Hash-prefix indexing", slug="index", status="soon"),
                 dict(n="F4.05.3", title="Structural sharing", slug="sharing", status="soon"),
             ]),
        dict(n="F4.06", title="CHAMP maps", one="Compressed Hash-Array Mapped Prefix-trees; layout & iteration.", slug="champ", status="built", lab=False,
             dives=[
                 dict(n="F4.06.1", title="Compressed node layout", slug="layout", status="built"),
                 dict(n="F4.06.2", title="Cache-friendly iteration", slug="iteration", status="built"),
                 dict(n="F4.06.3", title="Canonical equality", slug="equality", status="built"),
             ]),
        dict(n="F4.07", title="Branded Champ maps", one="Namespaced keys as cross-system pivots, e.g. TSK0KHTOWnGLuC.", slug="branded-champ", status="planned", lab=False,
             dives=[
                 dict(n="F4.07.1", title="Branded Snowflake keys", slug="keys", status="soon"),
                 dict(n="F4.07.2", title="A cross-system pivot key", slug="pivot", status="soon"),
                 dict(n="F4.07.3", title="Base62 encode & decode", slug="encode", status="soon"),
             ]),
        dict(n="F4.08", title="Dynamic programming & advanced problems", one="Memoisation and harder challenges.", slug="dynamic-programming", status="planned", lab=False,
             dives=[
                 dict(n="F4.08.1", title="Memoization & overlapping subproblems", slug="memoization", status="soon"),
                 dict(n="F4.08.2", title="Tabulation & bottom-up", slug="tabulation", status="soon"),
                 dict(n="F4.08.3", title="Classic DP problems", slug="problems", status="soon"),
             ]),
        dict(n="F4.09", title="Watch a Branded Champ map grow", one="Insert keys; animate the CHAMP / branded trie building.", slug="champ-lab", status="planned", lab=True),
    ],
    "F5": [
        dict(n="F5.01", title="Project structure & Mix", one="Apps, deps, tasks.", slug="mix", status="planned", lab=False),
        dict(n="F5.02", title="Testing with ExUnit & doctests", one="Fast, deterministic tests.", slug="testing", status="planned", lab=False),
        dict(n="F5.03", title="Documentation & typespecs", one="@doc, @spec, Dialyzer.", slug="typespecs", status="planned", lab=False),
        dict(n="F5.04", title="Error handling & “let it crash”", one="Tagged tuples versus exceptions; supervision.", slug="let-it-crash", status="planned", lab=False),
        dict(n="F5.05", title="Concurrency patterns & Tasks", one="Task, async/await, back-pressure.", slug="tasks", status="planned", lab=False),
        dict(n="F5.06", title="Telemetry, logging & observability", one="Seeing inside a running system.", slug="telemetry", status="planned", lab=False),
        dict(n="F5.07", title="Dependencies, releases & deployment", one="mix release, config, runtime.", slug="releases", status="planned", lab=False),
        dict(n="F5.08", title="Performance & profiling", one="Benchmarks, the scheduler, hot paths.", slug="performance", status="planned", lab=False),
        dict(n="F5.09", title="Let it crash — a supervision tree that heals", one="Crash a worker; watch the supervisor restart it.", slug="supervision-lab", status="planned", lab=True),
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
        dict(slug="shape",      title="The shape of recursion",    one="Base case, recursive case, and the growing call stack."),
        dict(slug="tail-calls", title="Tail calls & accumulators",  one="Rewrite with an accumulator to run in constant stack space."),
        dict(slug="patterns",   title="Recursion patterns",         one="sum, length, reverse, map, filter \u2014 and why they are folds."),
    ],
    "F2.05": [
        dict(slug="map",      title="map",            one="Transform every element; the structure is preserved."),
        dict(slug="filter",   title="filter",         one="Keep the elements that pass a predicate."),
        dict(slug="reduce",   title="reduce",         one="The general fold; an accumulator of any shape."),
        dict(slug="advanced", title="Advanced folds", one="scan, map_reduce, flat_map, group_by \u2014 folds with extra structure."),
    ],
    "F2.06": [
        dict(slug="environment", title="Capturing the environment", one="What a closure captures, and when \u2014 the value at definition time."),
        dict(slug="capture",     title="The capture operator",      one="The & shorthand: positional placeholders and function capture."),
        dict(slug="currying",    title="Partial application & currying", one="Fixing arguments to specialize a function; currying by hand."),
    ],
    "F2.07": [
        dict(slug="product",  title="Product types",            one="Tuples and structs \u2014 fields held together; inhabitants multiply."),
        dict(slug="sum",      title="Sum types",                one="Tagged tuples and variants \u2014 one shape or another; inhabitants add."),
        dict(slug="matching", title="Pattern matching on data", one="Destructuring products and dispatching on sum variants."),
    ],
    "F2.08": [
        dict(slug="compose",  title="Function composition", one="Combining functions so one's output feeds the next \u2014 f after g."),
        dict(slug="pipe",     title="The pipe operator",    one="|> threads a value left to right, as the first argument."),
        dict(slug="pipeline", title="Building pipelines",   one="map, filter, and reduce stages over a dataset, end to end."),
    ],
    "F3.02": [
        dict(slug="operator",      title="The match operator",                one="= asserts a shape and binds the rest \u2014 not assignment; the pin ^ matches a known value."),
        dict(slug="destructuring", title="Destructuring portal data",         one="Pull fields out of the maps, structs, and tuples the portal passes around."),
        dict(slug="branching",     title="Branching with case, with & guards", one="Dispatch on shape: function heads, case, the with pipeline, and guards."),
    ],
    "F3.03": [
        dict(slug="functions",  title="Defining functions",     one="def and defp, multiple clauses, arity, anonymous functions, and the capture operator."),
        dict(slug="organising", title="Organising with modules", one="defmodule, attributes, alias and import, and documentation \u2014 the Portal namespace."),
        dict(slug="pipe",       title="The pipe operator",       one="|> threads a value as the first argument, composing module functions into a pipeline."),
    ],
    "F3.04": [
        dict(slug="enum",           title="Enum, the eager workhorse", one="The Enumerable protocol and the Enum functions that walk any collection \u2014 map, filter, reduce, group_by."),
        dict(slug="comprehensions", title="Comprehensions",            one="for over generators, with filters and :into \u2014 set-builder notation as Elixir syntax."),
        dict(slug="streams",        title="Lazy streams",              one="Stream builds a recipe that runs only when pulled \u2014 eager versus lazy, and why laziness wins."),
    ],
    "F3.05": [
        dict(slug="define",   title="Defining a struct",            one="defstruct over a Portal entity, the %User{} literal, and the __struct__ key that makes a struct a tagged map."),
        dict(slug="defaults", title="Enforcing keys & defaults",    one="@enforce_keys for required fields and default values in defstruct \u2014 what fills in, and what fails at build time."),
        dict(slug="matching", title="Matching on a struct's type",  one="The %User{} pattern, dispatch by struct tag across function clauses, clause order, and the is_struct/2 guard."),
    ],
    "F3.06": [
        dict(slug="define",     title="Defining a protocol",         one="defprotocol declares the contract; a call resolves to an implementation by the value's type, or raises Protocol.UndefinedError."),
        dict(slug="defimpl",    title="Implementing for a struct",   one="One defimpl per type builds a dispatch table; new types are added without touching the protocol or the other implementations."),
        dict(slug="behaviours", title="Behaviours & callbacks",      one="@callback declares the contract, @behaviour and @impl fulfil it \u2014 the compile-time counterpart that OTP is built on."),
    ],
    "F3.07": [
        dict(slug="spawn",    title="Spawning a process",          one="spawn/1 starts a function as a new process and returns its PID at once; the child runs concurrently, with its own heap and crash boundary."),
        dict(slug="messages", title="Sending & receiving messages", one="send/2 drops a term in a mailbox; receive matches it out. A message can carry a PID, so the receiver can reply."),
        dict(slug="state",    title="Holding state in a loop",      one="State is the argument to a recursive receive loop; the process tail-calls itself with updated state \u2014 the pattern GenServer abstracts."),
    ],
    "F3.08": [
        dict(slug="genserver",   title="The GenServer behaviour",     one="use GenServer hides the loop; you fill in init/1, handle_call/3, and handle_cast/2, and the state threads between them."),
        dict(slug="call-cast",   title="Synchronous call, asynchronous cast", one="call blocks until the server replies; cast returns :ok at once. One routes to handle_call, the other to handle_cast."),
        dict(slug="supervisors", title="Supervisors & restart strategies", one="A supervisor restarts crashed children by strategy \u2014 one_for_one, one_for_all, rest_for_one. This is let it crash."),
    ],
    "F4.01": [
        dict(slug="cons",      title="Cons cells & the shape of a list", one="A list is [head | tail]; prepend is O(1) and shares the old list, hd/1 and tl/1 read a cell, and append must copy."),
        dict(slug="recursion", title="Recursion over lists",             one="Match [h | t], act on the head, recurse on the tail, stop at []; an accumulator makes it tail-recursive, a loop in constant space."),
        dict(slug="big-o",     title="Complexity & big-O on the BEAM",   one="Cost is how many cons cells an operation touches: O(1) at the head, O(n) for length, ++, and last."),
    ],
    "F4.02": [
        dict(slug="shape", title="Binary trees & recursive shape", one="A node is {value, left, right} or nil; size, height, and sum fold the two subtrees, and insert shares all but the path it rebuilds."),
        dict(slug="dfs",   title="Depth-first: pre, in, post-order", one="The three orders differ only in when the node is visited relative to its subtrees; in-order on a BST comes out sorted."),
        dict(slug="bfs",   title="Breadth-first & balance",         one="Level order with a FIFO queue, why a balanced tree keeps the descent at log n, and how sorted insertion degenerates into a list."),
    ],
    "F4.03": [
        dict(slug="sorts",  title="Merge & quicksort",        one="Two divide-and-conquer sorts: merge splits then merges, quicksort pivots then partitions; both average O(n log n)."),
        dict(slug="search", title="Linear & binary search",   one="Linear is O(n) over anything; binary is O(log n) over a sorted, randomly-accessible sequence, which a linked list is not."),
        dict(slug="cost",   title="Stability & sort cost",    one="Average, worst, space, and stability per sort, and the decision-tree argument for the Omega(n log n) comparison floor."),
    ],
    "F4.04": [
        dict(slug="lookup",  title="Maps & key lookup",     one="Map.get/fetch/put over the course's page registry; O(1)-average lookup by route, and the LiveView assigns map."),
        dict(slug="sets",    title="MapSet & membership",   one="MapSet membership and set algebra over the course's route sets; the links gate is a MapSet.member? check."),
        dict(slug="hashing", title="Hashing & collisions",  one="How maps and sets reach O(1): phash2 hashes a key to a slot, collisions resolve, and Elixir stores entries in a 32-way HAMT."),
    ],
    "F4.06": [
        dict(slug="layout",    title="Compressed node layout",   one="A CHAMP node splits its slots into two bitmaps and two packed arrays — entries and sub-nodes — with no empty cells."),
        dict(slug="iteration", title="Cache-friendly iteration", one="Because entries sit contiguously, a CHAMP walks them linearly in a canonical order, with far better cache locality than a HAMT."),
        dict(slug="equality",  title="Canonical equality",       one="CHAMP keeps one canonical shape per map, so structural equality and cheap snapshot diffs fall out of shared sub-trees."),
    ],
}


CHAPTER_SUBPAGES = {
    # A chapter can have front-matter subpages (intro material that sits at the
    # chapter route, not under any module). Their routes become linkable once the
    # chapter itself is linkable. Like module subpages, these are NOT counted as modules.
    "F0": [
        dict(slug="csharp", title="Elixir for C# developers", one="The runtime gap from the CLR to the BEAM, the functional ideas C# already shares, and language-ext as the bridge."),
    ],
    "F3": [
        dict(slug="history",         title="A short history of Elixir", one="Why Jos\u00e9 Valim built a new language on a thirty-year-old VM."),
        dict(slug="timeline",        title="The release timeline",      one="From the first commit to today, one headline per milestone."),
        dict(slug="under-the-hood",  title="Under the hood",            one="Source to bytecode: tokens, the AST, macros, and the BEAM."),
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


def chapter_subpages_of(cid: str):
    """(route, title, one) for each front-matter subpage of a chapter."""
    chapter = next((c for c in CHAPTERS if c["id"] == cid), None)
    if not chapter:
        return []
    return [(f'{chapter["route"]}/{s["slug"]}', s["title"], s["one"]) for s in CHAPTER_SUBPAGES.get(cid, [])]


def allowed_routes() -> set[str]:
    routes = {ROOT_ROUTE}
    for ch in CHAPTERS:
        if ch["status"] in LINKABLE:
            routes.add(ch["route"])
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
    # front-matter subpages of a chapter are linkable once the chapter is linkable
    for cid in CHAPTER_SUBPAGES:
        chapter = next((c for c in CHAPTERS if c["id"] == cid), None)
        if chapter and chapter["status"] in LINKABLE:
            for s in CHAPTER_SUBPAGES[cid]:
                routes.add(f'{chapter["route"]}/{s["slug"]}')
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
  font-size:clamp(1.02rem,0.97rem + 0.28vw,1.18rem);
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
h1{font-size:clamp(2.7rem,1.9rem + 4.2vw,5.1rem);font-weight:600}
h1 .ex{color:var(--elixir-bright);font-style:italic;font-weight:500}
h2{font-size:clamp(1.85rem,1.3rem + 1.9vw,2.7rem)}
h3{font-size:clamp(1.3rem,1.1rem + .6vw,1.6rem)}
.eyebrow{font-family:var(--sans);font-weight:600;font-size:.72rem;
  text-transform:uppercase;letter-spacing:.24em;color:var(--gold);
  display:inline-flex;align-items:center;gap:.6rem;margin:0 0 1rem}
.eyebrow::before{content:"";width:26px;height:1px;background:var(--gold);display:inline-block}
.lede{font-family:var(--serif-display);font-weight:500;font-style:italic;
  font-size:clamp(1.25rem,1rem + 1vw,1.7rem);line-height:1.32;color:var(--cream-soft);
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
pre.code .fn.elixir{color:var(--elixir-bright)}
pre.code .fn.burg{color:#e08f8b}
pre.code .res{color:var(--gold-bright)}
pre.code .str{color:var(--sage-bright)}
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
    "f0-course": (
        "content/f0-00-course.html",
        "course.html",
        "Course contents \u2014 History \u00b7 jonnify",
        "The full map of the course \u2014 six chapters and an optional history \u2014 plus an onramp for engineers "
        "arriving from C# and .NET, comparing the CLR and the BEAM and the functional ideas they share.",
    ),
    "f0-csharp": (
        "content/f0-csharp.html",
        "course-csharp.html",
        "Elixir for C# developers \u2014 History \u00b7 jonnify",
        "A bridge from .NET to the BEAM: how the two runtimes differ, the functional ideas C# has already "
        "adopted, and how the language-ext library maps Option, Either, immutability, and the actor model "
        "onto Elixir's own.",
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
    "f2-6": (
        "content/f2-06-closures.html",
        "closures.html",
        "Closures & partial application \u2014 F2.06 \u00b7 jonnify",
        "A closure is a function plus the environment it captured. Building specialised functions by capturing "
        "a value, partial application, and the & capture operator.",
    ),
    "f2-6-environment": (
        "content/f2-06-1-environment.html",
        "closures-environment.html",
        "Capturing the environment \u2014 F2.06.1 \u00b7 jonnify",
        "What a closure captures and when: the value at definition time, immutability, lexical scope, and "
        "capturing several variables at once.",
    ),
    "f2-6-capture": (
        "content/f2-06-2-capture.html",
        "closures-capture.html",
        "The capture operator \u2014 F2.06.2 \u00b7 jonnify",
        "The & shorthand for anonymous functions: positional placeholders &1 and &2, and capturing named "
        "functions with &Module.fun/arity.",
    ),
    "f2-6-currying": (
        "content/f2-06-3-currying.html",
        "closures-currying.html",
        "Partial application & currying \u2014 F2.06.3 \u00b7 jonnify",
        "Fixing arguments to specialise a function, and building curried functions by hand \u2014 applying "
        "arguments one at a time.",
    ),
    "f2-7": (
        "content/f2-07-adt.html",
        "adt.html",
        "Algebraic data types \u2014 F2.07 \u00b7 jonnify",
        "The algebra of types: product types hold several values at once and their counts multiply; sum types "
        "are one shape or another and their counts add; pattern matching takes them apart.",
    ),
    "f2-7-product": (
        "content/f2-07-1-product.html",
        "adt-product.html",
        "Product types \u2014 F2.07.1 \u00b7 jonnify",
        "Tuples and structs: bundling fields by position or by name, immutable struct update, and why a product "
        "type's inhabitants multiply.",
    ),
    "f2-7-sum": (
        "content/f2-07-2-sum.html",
        "adt-sum.html",
        "Sum types \u2014 F2.07.2 \u00b7 jonnify",
        "Tagged tuples and variants: a value is one shape or another, the atom tag discriminates, and the "
        "inhabitants add \u2014 including the {:ok, _} | {:error, _} idiom.",
    ),
    "f2-7-matching": (
        "content/f2-07-3-matching.html",
        "adt-matching.html",
        "Pattern matching on data \u2014 F2.07.3 \u00b7 jonnify",
        "Taking algebraic data apart: destructuring products to bind fields, and dispatching on sum variants "
        "with case and function heads.",
    ),
    "f2-8": (
        "content/f2-08-composition.html",
        "composition-functional.html",
        "Composition & pipelines \u2014 F2.08 \u00b7 jonnify",
        "Building programs by combining functions: composing two so one feeds the next, the pipe operator that "
        "threads a value left to right, and pipelines of map, filter, and reduce.",
    ),
    "f2-8-compose": (
        "content/f2-08-1-compose.html",
        "composition-compose.html",
        "Function composition \u2014 F2.08.1 \u00b7 jonnify",
        "Composing functions by hand \u2014 f after g \u2014 why the order matters, and chaining three together.",
    ),
    "f2-8-pipe": (
        "content/f2-08-2-pipe.html",
        "composition-pipe.html",
        "The pipe operator \u2014 F2.08.2 \u00b7 jonnify",
        "The |> operator: threading a value as the first argument, reading left to right instead of inside out, "
        "and passing extra arguments.",
    ),
    "f2-8-pipeline": (
        "content/f2-08-3-pipeline.html",
        "composition-pipeline.html",
        "Building pipelines \u2014 F2.08.3 \u00b7 jonnify",
        "Composing map, filter, and reduce into a pipeline over a dataset, watching the value transform at each "
        "stage.",
    ),
    "f2-9": (
        "content/f2-09-pipeline-lab.html",
        "pipeline-lab.html",
        "The data-pipeline lab \u2014 F2.09 \u00b7 jonnify",
        "The F2 capstone: compose filter, map, sort, and reduce stages over a dataset, watch the rows transform "
        "at each stage, and read the idiomatic Elixir pipeline the configuration generates.",
    ),
    "f3-landing": (
        "content/f3-00-landing.html",
        "language.html",
        "The Elixir Language \u2014 F3 \u00b7 jonnify",
        "The chapter that grounds the functional ideas of F2 in real Elixir: values and IEx, pattern matching, "
        "modules, enumerables and streams, structs, protocols, processes, and OTP. Start with the language's "
        "history, a release timeline, and a look under the hood.",
    ),
    "f3-history": (
        "content/f3-intro-history.html",
        "language-history.html",
        "A short history of Elixir \u2014 F3 \u00b7 jonnify",
        "Why Jos\u00e9 Valim built Elixir on the Erlang VM in 2011, what it inherited from Erlang, Ruby, and Clojure, "
        "and how it reached a stable 1.0 in 2014.",
    ),
    "f3-timeline": (
        "content/f3-intro-timeline.html",
        "language-timeline.html",
        "The Elixir release timeline \u2014 F3 \u00b7 jonnify",
        "An interactive timeline of Elixir's milestones, from the first commit in 2011 to the current stable "
        "release, with one headline feature per version.",
    ),
    "f3-hood": (
        "content/f3-intro-hood.html",
        "language-under-the-hood.html",
        "Under the hood \u2014 F3 \u00b7 jonnify",
        "How Elixir source becomes BEAM bytecode: tokenizing, parsing to the quoted AST, macro expansion, and the "
        "Erlang VM that runs the result.",
    ),
    "f3-1": (
        "content/f3-01-values.html",
        "values.html",
        "Values, types & IEx \u2014 F3.01 \u00b7 jonnify",
        "The data Elixir is built from \u2014 integers, floats, atoms, booleans, strings, lists, tuples, and maps \u2014 "
        "explored through IEx, the interactive shell, and the i/1 helper.",
    ),
    "f3-2": (
        "content/f3-02-match.html",
        "match.html",
        "Pattern matching & the match operator \u2014 F3.02 \u00b7 jonnify",
        "Pattern matching is how Elixir reads the shape of data and pulls it apart. This module introduces it "
        "through the project the whole course builds: a learning portal with magic-link sign-in and progress "
        "tracking. Three deep dives follow.",
    ),
    "f3-2-op": (
        "content/f3-02-1-operator.html",
        "match-operator.html",
        "The match operator \u2014 F3.02 \u00b7 jonnify",
        "= asserts that a value matches a pattern and binds the rest; the pin operator ^ matches against a value "
        "you already have. Seen through verifying a magic-link sign-in.",
    ),
    "f3-2-de": (
        "content/f3-02-2-destructuring.html",
        "match-destructuring.html",
        "Destructuring portal data \u2014 F3.02 \u00b7 jonnify",
        "Pulling fields out of tuples, lists, maps, and structs in a single match \u2014 the auth claims, request "
        "params, and progress records the learning portal passes around.",
    ),
    "f3-2-br": (
        "content/f3-02-3-branching.html",
        "match-branching.html",
        "Branching with case, with & guards \u2014 F3.02 \u00b7 jonnify",
        "Dispatching on shape: function-head matching, case, guards, and the with pipeline \u2014 built around the "
        "portal's magic-link sign-in flow and its progress events.",
    ),
    "f3-3": (
        "content/f3-03-modules.html",
        "modules.html",
        "Functions, modules & the pipe \u2014 F3.03 \u00b7 jonnify",
        "Functions are the unit of work, modules group them, and the pipe composes them. This module builds the "
        "learning portal's first real modules \u2014 Accounts, Auth, Catalog, Progress \u2014 and the functions they expose. "
        "Three deep dives follow.",
    ),
    "f3-3-fn": (
        "content/f3-03-1-functions.html",
        "modules-functions.html",
        "Defining functions \u2014 F3.03 \u00b7 jonnify",
        "Named functions with def and defp, multiple clauses that dispatch by pattern and guard, arity, anonymous "
        "functions, and the capture operator \u2014 seen through the portal's progress and auth helpers.",
    ),
    "f3-3-org": (
        "content/f3-03-2-organising.html",
        "modules-organising.html",
        "Organising with modules \u2014 F3.03 \u00b7 jonnify",
        "defmodule, module attributes, alias and import, and documentation \u2014 how the Portal namespace is "
        "structured and how its modules refer to one another.",
    ),
    "f3-3-pipe": (
        "content/f3-03-3-pipe.html",
        "modules-pipe.html",
        "The pipe operator \u2014 F3.03 \u00b7 jonnify",
        "|> threads a value as the first argument to the next call, turning nested calls into a readable pipeline "
        "\u2014 composing Portal and Enum functions over a learner's progress.",
    ),
    "f3-4": (
        "content/f3-04-enum-streams.html",
        "enum-streams.html",
        "Enumerables & streams \u2014 F3.04 \u00b7 jonnify",
        "A collection is anything that implements the Enumerable protocol; Enum walks it eagerly, and Stream walks "
        "it lazily. This module deepens the Enum steps from the pipe and adds lazy processing over a learner's full "
        "history. Three deep dives follow.",
    ),
    "f3-4-en": (
        "content/f3-04-1-enum.html",
        "enumerables.html",
        "Enum, the eager workhorse \u2014 F3.04 \u00b7 jonnify",
        "The Enumerable protocol unifies lists, ranges, maps, and streams, and the Enum module is the toolkit that "
        "walks them \u2014 map, filter, reduce, group_by, frequencies \u2014 each returning a new collection.",
    ),
    "f3-4-co": (
        "content/f3-04-2-comprehensions.html",
        "comprehensions.html",
        "Comprehensions \u2014 F3.04 \u00b7 jonnify",
        "The for comprehension: generators draw from any enumerable, filters drop items, :into chooses the result "
        "collection, and multiple generators nest \u2014 set-builder notation as Elixir syntax.",
    ),
    "f3-4-st": (
        "content/f3-04-3-streams.html",
        "streams.html",
        "Lazy streams \u2014 F3.04 \u00b7 jonnify",
        "Stream builds a lazy recipe that computes nothing until an Enum function pulls values through \u2014 the same "
        "pipeline eager and lazy, early exit, infinite sequences, and when laziness is worth it.",
    ),
    "f3-5": (
        "content/f3-05-structs.html",
        "structs.html",
        "Structs, maps & keyword lists \u2014 F3.05 \u00b7 jonnify",
        "Three containers for key-and-value data \u2014 the map, the keyword list, and the struct \u2014 and when each "
        "fits, with the portal's User as the running example.",
    ),
    "f3-5-def": (
        "content/f3-05-1-define.html",
        "structs-define.html",
        "Defining a struct \u2014 F3.05.1 \u00b7 jonnify",
        "defstruct over Portal.Accounts.User: the %User{} literal as sugar over a map, and the hidden __struct__ key "
        "that names the module and makes a struct an ordinary map at runtime.",
    ),
    "f3-5-enf": (
        "content/f3-05-2-defaults.html",
        "structs-defaults.html",
        "Enforcing keys & defaults \u2014 F3.05.2 \u00b7 jonnify",
        "@enforce_keys for required fields and keyword defaults in defstruct: what fills in for the common case, and "
        "the ArgumentError raised at construction when an essential field is missing.",
    ),
    "f3-5-mat": (
        "content/f3-05-3-matching.html",
        "structs-matching.html",
        "Matching on a struct's type \u2014 F3.05.3 \u00b7 jonnify",
        "The %Struct{} pattern dispatches on the __struct__ tag across function clauses; why clause order matters when "
        "a struct is a map, and the is_struct/2 guard that keeps plain maps in their own clause.",
    ),
    "f3-6": (
        "content/f3-06-protocols.html",
        "protocols.html",
        "Protocols & behaviours \u2014 F3.06 \u00b7 jonnify",
        "Two kinds of polymorphism in Elixir: a protocol dispatches a function on a value's type at runtime, a "
        "behaviour is a compile-time contract a module fulfils \u2014 with the portal's Summary and Notifier as examples.",
    ),
    "f3-6-def": (
        "content/f3-06-1-define.html",
        "protocols-define.html",
        "Defining a protocol \u2014 F3.06.1 \u00b7 jonnify",
        "defprotocol declares a contract of function signatures; a call resolves to the implementation registered for "
        "the value's type, dispatching by tag, or raises Protocol.UndefinedError when no implementation exists.",
    ),
    "f3-6-imp": (
        "content/f3-06-2-defimpl.html",
        "protocols-defimpl.html",
        "Implementing for a struct \u2014 F3.06.2 \u00b7 jonnify",
        "defimpl Protocol, for: Struct gives the per-type bodies a call resolves to; three implementations form a "
        "dispatch table that grows by addition \u2014 open for extension, closed for modification.",
    ),
    "f3-6-beh": (
        "content/f3-06-3-behaviours.html",
        "protocols-behaviours.html",
        "Behaviours & callbacks \u2014 F3.06.3 \u00b7 jonnify",
        "@callback declares a typed contract on a module; @behaviour and @impl true fulfil it and let the compiler "
        "flag a missing callback \u2014 the compile-time counterpart to a protocol, and the basis for OTP behaviours.",
    ),
    "f3-7": (
        "content/f3-07-processes.html",
        "processes.html",
        "Processes & the actor model \u2014 F3.07 \u00b7 jonnify",
        "A process is the BEAM's isolated unit of concurrency, coordinating only by messages \u2014 the actor model "
        "built from three primitives: spawn a process, send and receive messages, and loop to hold state.",
    ),
    "f3-7-spw": (
        "content/f3-07-1-spawn.html",
        "processes-spawn.html",
        "Spawning a process \u2014 F3.07.1 \u00b7 jonnify",
        "spawn/1 starts a function as a new process and returns a PID at once; the child runs concurrently on its own "
        "heap, and a crash stays inside its boundary \u2014 the isolation a supervisor later builds on.",
    ),
    "f3-7-msg": (
        "content/f3-07-2-messages.html",
        "processes-messages.html",
        "Sending & receiving messages \u2014 F3.07.2 \u00b7 jonnify",
        "send/2 appends a term to a mailbox and returns; receive pattern-matches messages out, leaving unmatched ones "
        "queued; a message carries self() so the server can reply \u2014 the whole actor protocol.",
    ),
    "f3-7-loop": (
        "content/f3-07-3-state.html",
        "processes-state.html",
        "Holding state in a loop \u2014 F3.07.3 \u00b7 jonnify",
        "A process holds state as the argument to a recursive receive loop, tail-calling itself with the updated value "
        "after each message \u2014 a hand-written GenServer, and the bridge into OTP.",
    ),
    "f3-8": (
        "content/f3-08-otp.html",
        "otp.html",
        "OTP: GenServer & supervisors \u2014 F3.08 \u00b7 jonnify",
        "OTP wraps the actor model in tested patterns: a GenServer holds state behind callbacks, a Supervisor restarts "
        "crashed children \u2014 an OTP system as a small tree of server, client, and supervisor.",
    ),
    "f3-8-gs": (
        "content/f3-08-1-genserver.html",
        "otp-genserver.html",
        "The GenServer behaviour \u2014 F3.08.1 \u00b7 jonnify",
        "A GenServer abstracts the receive loop into a behaviour: init/1 sets the state, handle_call/3 answers "
        "synchronous requests, handle_cast/2 handles asynchronous ones, and each return tuple threads the next state.",
    ),
    "f3-8-cc": (
        "content/f3-08-2-call-cast.html",
        "otp-call-cast.html",
        "Synchronous call, asynchronous cast \u2014 F3.08.2 \u00b7 jonnify",
        "GenServer.call sends a request and blocks for the reply, routing to handle_call; GenServer.cast returns :ok at "
        "once, routing to handle_cast; a clean client API wraps both so callers never touch the raw message tags.",
    ),
    "f3-8-sup": (
        "content/f3-08-3-supervisors.html",
        "otp-supervisors.html",
        "Supervisors & restart strategies \u2014 F3.08.3 \u00b7 jonnify",
        "A supervisor starts child processes and restarts them when they crash, by strategy \u2014 one_for_one, "
        "one_for_all, or rest_for_one \u2014 turning process isolation into recovery: the let-it-crash model.",
    ),
    "f3-9": (
        "content/f3-09-playground.html",
        "playground.html",
        "The process playground \u2014 F3.09 \u00b7 jonnify",
        "The F3 capstone lab: a live supervised tree you drive \u2014 send messages into a worker's mailbox, drain them "
        "through its receive loop to move state, issue a synchronous call, and crash workers to watch the supervisor "
        "restart them per strategy. Each worker carries a branded PRC Snowflake PID.",
    ),
    "f4-landing": (
        "content/f4-00-landing.html",
        "algorithms.html",
        "Algorithms & Data Structures \u2014 F4 \u00b7 jonnify",
        "The F4 chapter overview: nine modules from lists through trees, sorting, and hash-based maps to the "
        "persistent trie family \u2014 HAMT, CHAMP, and the branded CHAMP map keyed by a Snowflake pivot \u2014 plus "
        "dynamic programming and a lab. F4.01 is built; the rest show their planned dives.",
    ),
    "f4-1": (
        "content/f4-01-lists.html",
        "lists.html",
        "Lists, recursion & complexity \u2014 F4.01 \u00b7 jonnify",
        "The BEAM list is a linked list of cons cells, not an array: prepend is O(1) and the tail is shared, every "
        "list function is written by recursion, and the cost of an operation is the number of cells it touches. "
        "Three dives on the shape, the recursion, and the big-O.",
    ),
    "f4-1-cons": (
        "content/f4-01-1-cons.html",
        "lists-cons.html",
        "Cons cells & the shape of a list \u2014 F4.01.1 \u00b7 jonnify",
        "A cons cell is a head and a tail pointer. [head | tail] builds one new cell over an existing list, so "
        "prepend is O(1) and the old list is shared; hd/1 and tl/1 are O(1) reads; ++ appends by copying the left "
        "list, so it is O(n).",
    ),
    "f4-1-rec": (
        "content/f4-01-2-recursion.html",
        "lists-recursion.html",
        "Recursion over lists \u2014 F4.01.2 \u00b7 jonnify",
        "You walk a list by recursion, not a loop: match [h | t], act on the head, recurse on the tail, and stop at "
        "[]. sum, map, and length are the same shape with a different body; a tail-recursive accumulator turns the "
        "walk into a constant-space loop.",
    ),
    "f4-1-bigo": (
        "content/f4-01-3-big-o.html",
        "lists-big-o.html",
        "Complexity & big-O on the BEAM \u2014 F4.01.3 \u00b7 jonnify",
        "Big-O for a list is concrete: count the cons cells an operation touches. Working at the head is O(1); "
        "reaching the end \u2014 length, ++, last \u2014 is O(n). The cost cheat-sheet that motivates the rest of F4.",
    ),
    "f4-2": (
        "content/f4-02-trees.html",
        "trees.html",
        "Trees & traversals \u2014 F4.02 \u00b7 jonnify",
        "A binary tree is a cons cell with two pointers: a node is {value, left, right} or nil. The linear list walk "
        "becomes a traversal, and a balanced tree turns an O(n) walk into an O(log n) descent \u2014 the idea the "
        "trie family builds on. Three dives plus an advanced look at balance and tries.",
    ),
    "f4-2-shape": (
        "content/f4-02-1-shape.html",
        "trees-shape.html",
        "Binary trees & recursive shape \u2014 F4.02.1 \u00b7 jonnify",
        "A node is {value, left, right} or nil, so every tree function handles nil as the base case and a node by "
        "combining its two subtrees. size, height, and sum are one recursion with a different combine \u2014 and "
        "insert rebuilds only the path it changes, sharing the rest.",
    ),
    "f4-2-dfs": (
        "content/f4-02-2-dfs.html",
        "trees-dfs.html",
        "Depth-first: pre, in, post-order \u2014 F4.02.2 \u00b7 jonnify",
        "Depth-first traversal makes the same two recursive calls and differs only in when it visits the node: "
        "before the calls (pre), between them (in), or after them (post). In-order on a binary search tree comes "
        "out sorted, and all three are one parameterised fold.",
    ),
    "f4-2-bfs": (
        "content/f4-02-3-bfs.html",
        "trees-bfs.html",
        "Breadth-first & balance \u2014 F4.02.3 \u00b7 jonnify",
        "Breadth-first traversal walks the tree level by level with a FIFO queue. The level count is the search "
        "cost: a balanced tree of n nodes has about log2 n levels, while sorted insertion degenerates into an "
        "O(n) chain \u2014 which is why self-balancing trees and, later, tries exist.",
    ),
    "f4-3": (
        "content/f4-03-sorting.html",
        "sorting.html",
        "Sorting & searching \u2014 F4.03 \u00b7 jonnify",
        "Sorting and searching are two halves of one bargain: sort once at O(n log n), and every later lookup drops "
        "to an O(log n) binary search. Merge sort and quicksort are the divide-and-conquer recursion of F4.02; "
        "binary search is its halving descent. Three dives plus the comparison-sort lower bound.",
    ),
    "f4-3-sorts": (
        "content/f4-03-1-sorts.html",
        "sorting-sorts.html",
        "Merge & quicksort \u2014 F4.03.1 \u00b7 jonnify",
        "The two workhorse comparison sorts are both divide-and-conquer. Merge sort halves the list, sorts each "
        "half, and merges; quicksort picks a pivot, partitions the rest into smaller and larger, and recurses. Both "
        "average O(n log n); merge sort is stable and O(n log n) worst case, quicksort can hit O(n^2).",
    ),
    "f4-3-search": (
        "content/f4-03-2-search.html",
        "sorting-search.html",
        "Linear & binary search \u2014 F4.03.2 \u00b7 jonnify",
        "Linear search checks elements one by one over any sequence \u2014 O(n). Binary search halves a sorted, "
        "randomly-accessible sequence \u2014 O(log n) \u2014 but a linked list has no O(1) middle, so binary search "
        "wants a tuple or a balanced tree, not a list.",
    ),
    "f4-3-cost": (
        "content/f4-03-3-cost.html",
        "sorting-cost.html",
        "Stability & sort cost \u2014 F4.03.3 \u00b7 jonnify",
        "Sorts are ranked on average, worst case, space, and stability \u2014 whether equal keys keep their order. "
        "Over all of them sits a hard floor: a comparison sort is a decision tree with n! leaves, so it needs at "
        "least log2(n!) ~ n log n comparisons. Merge sort meets the floor and is stable.",
    ),
    "f4-4": (
        "content/f4-04-maps.html",
        "maps.html",
        "Maps, sets & hashing \u2014 F4.04 \u00b7 jonnify",
        "The course you are reading runs on Phoenix LiveView, and its data layer is built from these structures: a "
        "map from route to page, a set of built routes, and branded Snowflake ids hashed as keys. Map lookup and "
        "set membership are O(1) on average; this module shows why, ending at the 32-way HAMT behind Elixir maps.",
    ),
    "f4-4-lookup": (
        "content/f4-04-1-lookup.html",
        "maps-lookup.html",
        "Maps & key lookup \u2014 F4.04.1 \u00b7 jonnify",
        "A map associates keys with values and looks one up in effectively constant time. Over the course's page "
        "registry \u2014 a map from route to a page struct \u2014 Map.get, Map.fetch, and Map.put read and write by "
        "key, and a LiveView's socket.assigns is itself just such a map.",
    ),
    "f4-4-sets": (
        "content/f4-04-2-sets.html",
        "maps-sets.html",
        "MapSet & membership \u2014 F4.04.2 \u00b7 jonnify",
        "A MapSet stores unique elements and answers membership in O(1). Over the course's route sets \u2014 built "
        "versus planned \u2014 MapSet.member? is exactly the links gate, and union, intersection, and difference "
        "compose the sets. A MapSet is a map under the hood.",
    ),
    "f4-4-hashing": (
        "content/f4-04-3-hashing.html",
        "maps-hashing.html",
        "Hashing & collisions \u2014 F4.04.3 \u00b7 jonnify",
        "Maps and sets reach O(1) by hashing: phash2 turns a key into an integer, which picks a slot, and "
        "collisions resolve in place. Elixir stores entries in a 32-way HAMT, so depth is about log32 n \u2014 the "
        "door into F4.05. Branded Snowflake ids hash like any other key.",
    ),
    "f4-6": (
        "content/f4-06-champ.html",
        "champ.html",
        "CHAMP maps \u2014 F4.06 \u00b7 jonnify",
        "A CHAMP is the compressed successor to the HAMT: same O(log32 n) lookup, but each node splits its slots "
        "into two bitmaps and two densely packed arrays \u2014 entries and sub-nodes. That compression buys "
        "cache-friendly iteration and a canonical shape per map, which makes equality and snapshot diffs cheap. It "
        "is the structure under the course's persistent registry and the branded-CHAMP trie in the stack.",
    ),
    "f4-6-layout": (
        "content/f4-06-1-layout.html",
        "champ-layout.html",
        "Compressed node layout \u2014 F4.06.1 \u00b7 jonnify",
        "A CHAMP node carries a datamap and a nodemap \u2014 two bitmaps marking which of its 32 slots hold inline "
        "entries and which hold sub-nodes \u2014 and stores each kind in its own packed array with no empty cells. "
        "A slot's position in an array is the popcount of the lower bits of the matching bitmap.",
    ),
    "f4-6-iteration": (
        "content/f4-06-2-iteration.html",
        "champ-iteration.html",
        "Cache-friendly iteration \u2014 F4.06.2 \u00b7 jonnify",
        "Because a CHAMP node keeps its entries contiguous and separate from sub-node pointers, iteration walks the "
        "entry array linearly in a canonical order and recurses into sub-nodes after \u2014 far fewer cache misses "
        "than a HAMT, where entries and pointers are interleaved across a 32-slot array.",
    ),
    "f4-6-equality": (
        "content/f4-06-3-equality.html",
        "champ-equality.html",
        "Canonical equality \u2014 F4.06.3 \u00b7 jonnify",
        "CHAMP maintains one canonical shape per set of entries, so two equal maps are structurally identical "
        "trees and equality short-circuits on shared sub-trees. The same sharing makes a one-entry change cheap "
        "\u2014 only the path to it differs \u2014 which is what lets the course diff two registry snapshots.",
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
