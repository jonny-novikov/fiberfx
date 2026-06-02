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
    dict(id='F0', title='History', slug='course', route='/elixir/course',
         status='live',
         one='Where this came from — the languages, the runtimes, and the BEAM.',
         reuses='Context, not a prerequisite. F1 stands on its own.',
         accent='blue'),
    dict(id='F1', title='Algebra', slug='algebra', route='/elixir/algebra',
         status='built',
         one='The functional mindset, straight from the math you already know.',
         reuses='Starts from the algebra you already know.',
         accent='gold'),
    dict(id='F2', title='Functional Programming', slug='functional', route='/elixir/functional',
         status='built',
         one='Pure functions, immutability, and higher-order functions on their own terms.',
         reuses='Builds on F1 · Algebra.',
         accent='elixir'),
    dict(id='F3', title='The Elixir Language', slug='language', route='/elixir/language',
         status='built',
         one='Syntax, pipelines, pattern matching, and structs on the BEAM.',
         reuses='Builds on F2 · Functional Programming.',
         accent='elixir'),
    dict(id='F4', title='Algorithms & Data Structures', slug='algorithms', route='/elixir/algorithms',
         status='built',
         one='Classical and advanced problems, from lists to branded CHAMP tries.',
         reuses='Builds on F3 · The Elixir Language.',
         accent='sage'),
    dict(id='F5', title='Pragmatic Programming', slug='pragmatic', route='/elixir/pragmatic',
         status='built',
         one='Real-world engineering: structure, contracts, CQRS, testing, boundaries.',
         reuses='Builds on F4 · Algorithms & Data Structures.',
         accent='sage'),
    dict(id='F6', title='Phoenix Framework', slug='phoenix', route='/elixir/phoenix',
         status='built',
         one='Web applications on Elixir, and the road into real-time LiveView.',
         reuses='Builds on F5 · Pragmatic Programming.',
         accent='blue'),
]

# modules[chapter_id] -> list of dicts {n,title,one,slug,status,lab,dives?}
MODULES = {
    'F0': [
        dict(n='F0.1', title='The evolution of functional languages & runtimes',
             one='From the lambda calculus to LISP, the ML and Haskell branch, and the immutable turn',
             slug='fp-evolution', status="built", lab=False),
        dict(n='F0.2', title='The evolution of Erlang, the BEAM & OTP',
             one='Telecom roots and “let it crash”, the reduction-counting scheduler and per-process heaps, and the OTP',
             slug='beam-evolution', status="built", lab=False),
    ],
    'F1': [
        dict(n='F1.01', title='What a function really is',
             one='A function as a mapping',
             slug='functions', status="built", lab=False),
        dict(n='F1.02', title='The substitution model',
             one='Equals for equals',
             slug='substitution', status="built", lab=False),
        dict(n='F1.03', title='Composition, f∘g',
             one='Chaining functions into new ones',
             slug='composition', status="built", lab=False),
        dict(n='F1.04', title='Immutability & binding',
             one='A name is a fixed value, not a box',
             slug='immutability', status="built", lab=False),
        dict(n='F1.05', title='Sets, sequences & mappings',
             one='Three shapes of collection',
             slug='collections', status="built", lab=False),
        dict(n='F1.06', title='Recursion & induction',
             one='Base case plus step: the call stack of a recursive sum, why the base case makes it terminate, and induction',
             slug='recursion', status="built", lab=False),
        dict(n='F1.07', title='Higher-order operators (Σ, Π)',
             one='Σ and Π as operators over a function, the map / filter / reduce trio and how each reshapes a collection, and',
             slug='higher-order', status="built", lab=False),
        dict(n='F1.08', title='Equations & pattern matching',
             one='Solving by structure',
             slug='pattern-matching', status="built", lab=False),
        dict(n='F1.09', title='Functions on the plane',
             one='The F1 lab',
             slug='plotting-lab', status="built", lab=True),
    ],
    'F2': [
        dict(n='F2.01', title='Pure functions & side effects',
             one='What purity buys and how to keep it',
             slug='pure', status="built", lab=False),
        dict(n='F2.02', title='Immutability & persistent data',
             one='Why copying is cheap',
             slug='persistence', status="built", lab=False),
        dict(n='F2.03', title='Higher-order functions',
             one='Functions as values',
             slug='higher-order', status="built", lab=False),
        dict(n='F2.04', title='Recursion patterns & tail calls',
             one='Recursion as the functional way to repeat',
             slug='recursion', status="built", lab=False),
        dict(n='F2.05', title='map / filter / reduce (folds)',
             one='reduce as the universal fold',
             slug='folds', status="built", lab=False),
        dict(n='F2.06', title='Closures & partial application',
             one='A closure is a function plus the environment it captured.',
             slug='closures', status="built", lab=False),
        dict(n='F2.07', title='Algebraic data types',
             one='The algebra of types',
             slug='adt', status="built", lab=False),
        dict(n='F2.08', title='Composition & pipelines',
             one='Building programs by combining functions',
             slug='composition', status="built", lab=False),
        dict(n='F2.09', title='The data-pipeline lab',
             one='The F2 capstone',
             slug='pipeline-lab', status="built", lab=True),
    ],
    'F3': [
        dict(n='F3.01', title='Values, types & IEx',
             one='The data Elixir is built from',
             slug='values', status="built", lab=False),
        dict(n='F3.02', title='Pattern matching & the match operator',
             one='Pattern matching is how Elixir reads the shape of data and pulls it apart.',
             slug='match', status="built", lab=False),
        dict(n='F3.03', title='Functions, modules & the pipe',
             one='Functions are the unit of work, modules group them, and the pipe composes them.',
             slug='modules', status="built", lab=False),
        dict(n='F3.04', title='Enumerables & streams',
             one='A collection is anything that implements the Enumerable protocol; Enum walks it eagerly, and Stream walks it lazily.',
             slug='enum-streams', status="built", lab=False),
        dict(n='F3.05', title='Structs, maps & keyword lists',
             one='Three containers for key-and-value data',
             slug='structs', status="built", lab=False),
        dict(n='F3.06', title='Protocols & behaviours',
             one='Two kinds of polymorphism in Elixir',
             slug='protocols', status="built", lab=False),
        dict(n='F3.07', title='Processes & the actor model',
             one="A process is the BEAM's isolated unit of concurrency, coordinating only by messages",
             slug='processes', status="built", lab=False),
        dict(n='F3.08', title='OTP: GenServer & supervisors',
             one='OTP wraps the actor model in tested patterns',
             slug='otp', status="built", lab=False),
        dict(n='F3.09', title='The process playground',
             one='The F3 capstone lab: a live supervised tree you drive',
             slug='playground', status="built", lab=True),
    ],
    'F4': [
        dict(n='F4.01', title='Lists, recursion & complexity',
             one='The BEAM list is a linked list of cons cells, not an array',
             slug='lists', status="built", lab=False),
        dict(n='F4.02', title='Trees & traversals',
             one='A binary tree is a cons cell with two pointers: a node is {value, left, right} or nil.',
             slug='trees', status="built", lab=False),
        dict(n='F4.03', title='Sorting & searching',
             one='Sorting and searching are two halves of one bargain',
             slug='sorting', status="built", lab=False),
        dict(n='F4.04', title='Maps, sets & hashing',
             one='The course you are reading runs on Phoenix LiveView, and its data layer is built from these structures',
             slug='maps', status="built", lab=False),
        dict(n='F4.05', title='Hash array mapped tries',
             one='A HAMT spreads a hash table over a tree',
             slug='hamt', status="built", lab=False),
        dict(n='F4.06', title='CHAMP maps',
             one='A CHAMP is the compressed successor to the HAMT',
             slug='champ', status="built", lab=False),
        dict(n='F4.07', title='Identifiers, Snowflake & branded ids',
             one='Every record in the portal needs a name.',
             slug='identifiers', status="built", lab=False),
        dict(n='F4.08', title='Branded ids & persistence',
             one='A branded Snowflake is the key everywhere the portal stores data',
             slug='persistence', status="built", lab=False),
        dict(n='F4.09', title='Branded CHAMP maps & GenServer',
             one='The chapter folds together',
             slug='branded-champ', status="built", lab=False),
        dict(n='F4.10', title='Practical recipes in Elixir',
             one="The chapter's structures turned into the Portal's everyday code through three recurring recipes",
             slug='recipes', status="built", lab=False),
        dict(n='F4.11', title='Dynamic programming & advanced problems',
             one='Dynamic programming solves a problem with overlapping subproblems by solving each once and reusing it, in two',
             slug='dynamic-programming', status="built", lab=False),
        dict(n='F4.12', title='Lab: build a branded CHAMP store',
             one='The capstone lab assembles the chapter into one Portal.Store',
             slug='lab', status="built", lab=True),
    ],
    'F5': [
        dict(n='F5.01', title='Start thin: a running Portal from day one',
             one='Pragmatic programming starts with a system that runs.',
             slug='foundations', status="built", lab=False),
        dict(n='F5.02', title='Modeling the Portal domain',
             one='The engine needs a shape before it needs behavior.',
             slug='domain', status="built", lab=False),
        dict(n='F5.03', title='Tracer bullets: a walking skeleton',
             one='With a running server and a domain model in hand, F5.03 wires them together by driving one use case',
             slug='tracer-bullets', status="built", lab=False),
        dict(n='F5.04', title='Design by contract',
             one='Every command on the engine carries a contract',
             slug='contracts', status="built", lab=False),
        dict(n='F5.05', title='Commands, queries & events',
             one='With the enroll command now contract-checked, F5.05 formalizes how the engine handles change',
             slug='cqrs', status="built", lab=False),
        dict(n='F5.06', title='Where engine state lives',
             one='The F5.05 fold is pure: it computes the current state from the event log and forgets it.',
             slug='state', status="built", lab=False),
        dict(n='F5.07', title='Pragmatic testing',
             one='The engine was built to be tested',
             slug='testing', status="built", lab=False),
        dict(n='F5.08', title='Boundaries & integration seams',
             one='The engine works, but its callers still have to know it is a process with message shapes and a chosen store.',
             slug='boundaries', status="built", lab=False),
        dict(n='F5.09', title='Lab: the Portal engine, LiveView-ready',
             one='The finale assembles eight modules into one running Portal',
             slug='engine-lab', status="built", lab=True),
    ],
    'F6': [
        dict(n='F6.01', title='Architecture & the request lifecycle',
             one='How a request travels through Phoenix and where it meets the F5 engine',
             slug='lifecycle', status="built", lab=False),
        dict(n='F6.02', title='Routing, controllers & plugs',
             one='The plug pipeline that carries a request to a controller',
             slug='routing', status="built", lab=False),
        dict(n='F6.03', title='Ecto: schemas, changesets & queries',
             one='Ecto in three pieces',
             slug='ecto', status="built", lab=False),
        dict(n='F6.04', title='Contexts & domain design',
             one='A context is a dedicated module that groups related functionality behind a public API and hides its schemas',
             slug='contexts', status="built", lab=False),
        dict(n='F6.05', title='Templates, components & HEEx',
             one='HEEx is the view half of the request a controller returns',
             slug='heex', status="built", lab=False),
        dict(n='F6.06', title='Phoenix LiveView fundamentals',
             one='LiveView makes the F6.05 templates live',
             slug='liveview', status="built", lab=False),
        dict(n='F6.07', title='PubSub, channels & real-time',
             one='PubSub turns one LiveView into many that update together',
             slug='pubsub', status="built", lab=False),
        dict(n='F6.08', title='Auth, deployment & going live',
             one='Taking the whole application to production',
             slug='deployment', status="built", lab=False),
        dict(n='F6.09', title='The live dashboard',
             one='The capstone lab: a real-time operations dashboard that converges the whole course.',
             slug='live-dashboard', status="built", lab=True),
    ],
}

LINKABLE = {"live", "built"}


SUBPAGES = {
    # A module can have deep-dive subpages. Their routes become linkable once the
    # parent module itself is linkable. Subpages are NOT counted as modules.
    'F4.01': [
        dict(slug='big-o', title='Complexity & big-O on the BEAM', one='Big-O for a list is concrete: count the cons cells an operation touches.'),
        dict(slug='cons', title='Cons cells & the shape of a list', one='A cons cell is a head and a tail pointer.'),
        dict(slug='recursion', title='Recursion over lists', one='You walk a list by recursion, not a loop: match [h | t], act on the head, recurse on the tail, and stop at [].'),
    ],
    'F6.01': [
        dict(slug='controllers', title='Controllers, views & the facade seam', one='Where your code lives in the lifecycle'),
        dict(slug='endpoint', title='The endpoint, supervised', one='PortalWeb.Endpoint has two roles: the outermost plug'),
        dict(slug='request-path', title='The request lifecycle', one='A request from the browser to the response, step by step'),
    ],
    'F5.01': [
        dict(slug='replaceable', title='A web layer built for replacement', one='The thin server is a detail, by design.'),
        dict(slug='roadmap', title='The development roadmap', one='The whole course is one development roadmap'),
        dict(slug='thin-server', title='A thin web server in Elixir', one='A minimal HTTP front end for the Portal'),
    ],
    'F4.02': [
        dict(slug='bfs', title='Breadth-first & balance', one='Breadth-first traversal walks the tree level by level with a FIFO queue.'),
        dict(slug='dfs', title='Depth-first: pre, in, post-order', one='Depth-first traversal makes the same two recursive calls and differs only in when it visits the node'),
        dict(slug='shape', title='Binary trees & recursive shape', one='A node is {value, left, right} or nil, so every tree function handles nil as the base case and a node by'),
    ],
    'F3.02': [
        dict(slug='branching', title='Branching with case, with & guards', one='Dispatching on shape: function-head matching, case, guards, and the with pipeline'),
        dict(slug='destructuring', title='Destructuring portal data', one='Pulling fields out of tuples, lists, maps, and structs in a single match'),
        dict(slug='operator', title='The match operator', one='= asserts that a value matches a pattern and binds the rest'),
    ],
    'F6.02': [
        dict(slug='pipelines', title='Pipelines & scopes', one='A named pipeline is a reusable, ordered stack of plugs; a scope runs a group of routes through one with pipe_through.'),
        dict(slug='plugs', title='Writing a plug', one='The contract every stage of the pipeline shares'),
        dict(slug='routes', title='Routes & verbs', one='How a verb and a path map to one controller action'),
    ],
    'F5.02': [
        dict(slug='api', title="A context's public API", one='Each context exposes a small set of public functions'),
        dict(slug='contexts', title='Bounded contexts', one='A bounded context is a module that owns a few entities and guards their rules'),
        dict(slug='structs', title='Structs & typespecs', one='An entity is a plain struct'),
    ],
    'F4.03': [
        dict(slug='cost', title='Stability & sort cost', one='Sorts are ranked on average, worst case, space, and stability — whether equal keys keep their order.'),
        dict(slug='search', title='Linear & binary search', one='Linear search checks elements one by one over any sequence — O(n).'),
        dict(slug='sorts', title='Merge & quicksort', one='The two workhorse comparison sorts are both divide-and-conquer.'),
    ],
    'F3.03': [
        dict(slug='functions', title='Defining functions', one='Named functions with def and defp, multiple clauses that dispatch by pattern and guard, arity, anonymous'),
        dict(slug='organising', title='Organising with modules', one='defmodule, module attributes, alias and import, and documentation'),
        dict(slug='pipe', title='The pipe operator', one='|> threads a value as the first argument to the next call, turning nested calls into a readable pipeline'),
    ],
    'F6.03': [
        dict(slug='changesets', title='Changesets & validation', one='A changeset is a pure pipeline'),
        dict(slug='repo', title='Queries & the repo', one='The Repo executes composable Ecto queries and persists changesets'),
        dict(slug='schemas', title='Schemas & migrations', one='A migration creates and evolves a database table'),
    ],
    'F5.03': [
        dict(slug='iterating', title='Iterating the slice', one='Once the skeleton walks, you grow it one thin vertical slice at a time'),
        dict(slug='prototypes', title='Tracer bullets vs prototypes', one='Both are built fast, but their fates are opposite.'),
        dict(slug='skeleton', title='The walking skeleton', one='The enroll-a-learner slice, end to end'),
    ],
    'F4.04': [
        dict(slug='hashing', title='Hashing & collisions', one='Maps and sets reach O(1) by hashing'),
        dict(slug='lookup', title='Maps & key lookup', one='A map associates keys with values and looks one up in effectively constant time.'),
        dict(slug='sets', title='MapSet & membership', one='A MapSet stores unique elements and answers membership in O(1).'),
    ],
    'F2.04': [
        dict(slug='patterns', title='Recursion patterns', one='sum, length, reverse, map, and filter written recursively — and why each one is a fold over the list.'),
        dict(slug='shape', title='The shape of recursion', one='Base case and recursive case, and the call stack growing then unwinding as a body-recursive function runs to a result.'),
        dict(slug='tail-calls', title='Tail calls & accumulators', one='Body versus tail recursion, the accumulator pattern, and how a tail call reuses the stack frame to run in'),
    ],
    'F3.04': [
        dict(slug='comprehensions', title='Comprehensions', one='The for comprehension'),
        dict(slug='enum', title='Enum, the eager workhorse', one='The Enumerable protocol unifies lists, ranges, maps, and streams, and the Enum module is the toolkit that'),
        dict(slug='streams', title='Lazy streams', one='Stream builds a lazy recipe that computes nothing until an Enum function pulls values through'),
    ],
    'F6.04': [
        dict(slug='boundaries', title='Context boundaries', one='A context groups related functionality behind a public API and keeps its schemas and the Repo private.'),
        dict(slug='composition', title='Composing contexts', one='How one context depends on another without breaking boundaries'),
        dict(slug='vs-facade', title='Contexts vs the F5 facade', one='A Phoenix context and the F5 Portal facade are the same idea — a public API over a slice of the domain.'),
    ],
    'F5.04': [
        dict(slug='assertions', title='Assertions in Elixir', one='Elixir has no design-by-contract keywords, so contracts are written in its idioms'),
        dict(slug='conditions', title='Preconditions, postconditions & invariants', one='A contract has three parts and three owners.'),
        dict(slug='fail-fast', title='Failing fast', one='Check at the boundary and stop on the first violation, before the struct is built or the store is touched.'),
    ],
    'F4.05': [
        dict(slug='bitmap', title='Bitmapped nodes', one='A HAMT node keeps one 32-bit bitmap marking which of its slots are occupied and one packed array holding only'),
        dict(slug='indexing', title='Hash-prefix indexing', one="A HAMT reads the key's hash in five-bit chunks from the low end"),
        dict(slug='sharing', title='Structural sharing', one='An insert builds new nodes only along the path from the root to the changed leaf and shares every other'),
    ],
    'F2.05': [
        dict(slug='advanced', title='Advanced folds', one='The Enum toolkit as folds with extra structure'),
        dict(slug='filter', title='filter', one='Keeping elements that pass a predicate: filter and its inverse reject, and filtering then mapping as a pipeline.'),
        dict(slug='map', title='map', one='Transforming every element with a function'),
        dict(slug='reduce', title='reduce', one='The general fold: accumulators of any shape — numbers, lists, maps — and building a frequency map step by step.'),
    ],
    'F3.05': [
        dict(slug='defaults', title='Enforcing keys & defaults', one='@enforce_keys for required fields and keyword defaults in defstruct'),
        dict(slug='define', title='Defining a struct', one='defstruct over Portal.Accounts.User'),
        dict(slug='matching', title="Matching on a struct's type", one='The %Struct{} pattern dispatches on the __struct__ tag across function clauses'),
    ],
    'F6.05': [
        dict(slug='components', title='Function components & slots', one='A function component is a pure function from assigns to markup, declared with attr and slot so its inputs are'),
        dict(slug='forms', title='Forms & inputs', one='A form is a changeset turned into a form with to_form/1.'),
        dict(slug='templates', title='Templates & assigns', one='A HEEx template renders the assigns a controller set'),
    ],
    'F5.05': [
        dict(slug='cqs', title='Command/query separation', one='Command/query separation is one rule'),
        dict(slug='events', title='Domain events', one='Model every change as a past-tense fact: %LearnerEnrolled{}, %LessonDelivered{}, %ProgressRecorded{}.'),
        dict(slug='reducer', title='The engine as a reducer', one='State is not stored so much as derived'),
    ],
    'F4.06': [
        dict(slug='equality', title='Canonical equality', one='CHAMP maintains one canonical shape per set of entries, so two equal maps are structurally identical trees'),
        dict(slug='iteration', title='Cache-friendly iteration', one='Because a CHAMP node keeps its entries contiguous and separate from sub-node pointers, iteration walks the'),
        dict(slug='layout', title='Compressed node layout', one='A CHAMP node carries a datamap and a nodemap'),
    ],
    'F2.06': [
        dict(slug='capture', title='The capture operator', one='The & shorthand for anonymous functions'),
        dict(slug='currying', title='Partial application & currying', one='Fixing arguments to specialise a function, and building curried functions by hand — applying arguments one at a time.'),
        dict(slug='environment', title='Capturing the environment', one='What a closure captures and when'),
    ],
    'F3.06': [
        dict(slug='behaviours', title='Behaviours & callbacks', one='@callback declares a typed contract on a module'),
        dict(slug='defimpl', title='Implementing for a struct', one='defimpl Protocol, for'),
        dict(slug='define', title='Defining a protocol', one='defprotocol declares a contract of function signatures'),
    ],
    'F6.06': [
        dict(slug='events', title='handle_event & state', one='Bindings like phx-click, phx-change, and phx-submit send events to handle_event/3, which transforms the'),
        dict(slug='mount', title='mount & assigns', one='A LiveView is a stateful process connected to the browser over a socket.'),
        dict(slug='render', title='render & diffs', one='render/1 returns HEEx from the assigns, and LiveView tracks which assigns changed to send only those values'),
    ],
    'F5.06': [
        dict(slug='choosing', title='Choosing where state lives', one='Three holders for live state on the BEAM are not interchangeable'),
        dict(slug='genserver', title='The engine GenServer', one='Three callbacks carry the engine.'),
        dict(slug='supervision', title='Supervision', one='Let it crash: a process holding state will eventually fail, so a supervisor sits above the engine and restarts it.'),
    ],
    'F4.07': [
        dict(slug='branded', title='Branded ids', one='A branded id encodes the 64-bit Snowflake in base62 over 0-9A-Za-z, left-pads it to eleven characters, and'),
        dict(slug='choosing', title='Choosing an identifier', one='An auto-increment counter is ordered and tiny but needs one writer, so it cannot scale across machines'),
        dict(slug='snowflake', title='The Snowflake bigint', one='A Snowflake packs three fields into 64 bits'),
    ],
    'F2.07': [
        dict(slug='matching', title='Pattern matching on data', one='Taking algebraic data apart'),
        dict(slug='product', title='Product types', one='Tuples and structs'),
        dict(slug='sum', title='Sum types', one='Tagged tuples and variants'),
    ],
    'F3.07': [
        dict(slug='messages', title='Sending & receiving messages', one='send/2 appends a term to a mailbox and returns'),
        dict(slug='spawn', title='Spawning a process', one='spawn/1 starts a function as a new process and returns a PID at once'),
        dict(slug='state', title='Holding state in a loop', one='A process holds state as the argument to a recursive receive loop, tail-calling itself with the updated value'),
    ],
    'F6.07': [
        dict(slug='broadcast', title='Broadcasting engine events', one='Phoenix.PubSub is process-to-process publish/subscribe over a string topic.'),
        dict(slug='presence', title='Channels & presence', one='Channels are the lower-level real-time primitive LiveView is built on, with explicit join and handle_in for'),
        dict(slug='subscribe', title='Subscribing a LiveView', one='A LiveView subscribes to a topic on its connected mount and receives broadcasts in handle_info/2'),
    ],
    'F5.07': [
        dict(slug='contract-tests', title='Contract tests', one='The F5.04 contract written as tests'),
        dict(slug='property', title='Property-based testing', one='State a property true for every valid input and let StreamData generate hundreds of cases, shrinking any'),
        dict(slug='pure-core', title='Testing the pure core', one='decide, evolve, and replay are pure functions, so a test is three lines'),
    ],
    'F4.08': [
        dict(slug='keys', title='Branded ids as keys', one='The database stores the 64-bit integer as a bigint primary key'),
        dict(slug='redis', title='Redis keys', one='In Redis the id is a namespaced string key, user:USR0NbWMtkosp8.'),
        dict(slug='sql', title='SQLite & PostgreSQL', one='Because the high bits of the id are a timestamp, a window of time is a contiguous window of ids'),
    ],
    'F2.08': [
        dict(slug='compose', title='Function composition', one='Composing functions by hand — f after g — why the order matters, and chaining three together.'),
        dict(slug='pipe', title='The pipe operator', one='The |> operator'),
        dict(slug='pipeline', title='Building pipelines', one='Composing map, filter, and reduce into a pipeline over a dataset, watching the value transform at each stage.'),
    ],
    'F3.08': [
        dict(slug='call-cast', title='Synchronous call, asynchronous cast', one='GenServer.call sends a request and blocks for the reply, routing to handle_call'),
        dict(slug='genserver', title='The GenServer behaviour', one='A GenServer abstracts the receive loop into a behaviour'),
        dict(slug='supervisors', title='Supervisors & restart strategies', one='A supervisor starts child processes and restarts them when they crash, by strategy'),
    ],
    'F6.08': [
        dict(slug='auth', title='Sessions & authentication', one='mix phx.gen.auth generates an Accounts context, a User schema, and the session plumbing.'),
        dict(slug='deploy', title='Deploying to production', one='The deploy is build, migrate, boot'),
        dict(slug='releases', title='Releases & config', one='mix release packages the app, its dependencies, and the BEAM into one self-contained artifact.'),
    ],
    'F5.08': [
        dict(slug='errors', title='Error contracts for the UI', one='Failure is part of the contract'),
        dict(slug='facade', title='The engine facade', one='The driving port: a small context module'),
        dict(slug='ports', title='Ports & adapters', one='A port is an Elixir behaviour the core depends on'),
    ],
    'F4.09': [
        dict(slug='genserver', title='Own it with a GenServer', one="The Portal's session store is a CHAMP behind a GenServer."),
        dict(slug='partition', title='Partition by namespace', one="The Portal's entity registry keeps users, sessions, lessons, and pages in one store"),
        dict(slug='trie', title='Structural sharing', one="Inside a partition the CHAMP is keyed on the lesson's Snowflake, and Portal.Progress marks a lesson complete"),
    ],
    'F6.09': [
        dict(slug='build', title='Build the dashboard', one='The dashboard is a LiveView that holds a read model on its socket'),
        dict(slug='multi-client', title='Many clients, live', one='One broadcast reaches every connected dashboard at once, so all viewers update together, and Presence reports'),
        dict(slug='stream', title='Broadcast engine events', one='The domain emits events after a write (F6.07) and the dashboard subscribes to the topic on its connected mount.'),
    ],
    'F5.09': [
        dict(slug='end-to-end', title='The engine facade end to end', one='The full supervision tree'),
        dict(slug='handoff', title='What ships in F6', one='The handoff'),
        dict(slug='mount', title='A LiveView mount sketch', one='A LiveView that touches only the facade'),
    ],
    'F4.10': [
        dict(slug='patterns', title='Idiomatic patterns', one='A request to view a lesson clears four gates'),
        dict(slug='pipelines', title='Streams & pipelines', one='The activity feed wants the three most recent completions for a course.'),
        dict(slug='profiling', title='Profiling & complexity', one='Every request finds an active session.'),
    ],
    'F4.11': [
        dict(slug='memoization', title='Memoization & overlapping subproblems', one='The longest prerequisite chain to a lesson is one plus the deepest of its prerequisites — a recursion.'),
        dict(slug='problems', title='Classic DP problems', one='Edit distance'),
        dict(slug='tabulation', title='Tabulation & bottom-up', one='The fewest modules (worth 1, 3, or 4 credits) summing to a target is one more than the best answer for the'),
    ],
    'F4.12': [
        dict(slug='grow', title='Watch a branded CHAMP grow', one="Each put reads a branded id's three-letter namespace and drops the entry into that namespace's partition,"),
        dict(slug='range', title='Query by time range', one='Because a Snowflake puts the timestamp in its high bits, ids sort by creation time and a time window becomes'),
        dict(slug='registry', title='A Snowflake registry', one='Hand the store any branded id and get/1 resolves it in one call'),
    ],
}


CHAPTER_SUBPAGES = {
    # A chapter can have front-matter subpages (intro material at the chapter route,
    # not under any module). Linkable once the chapter is linkable; not counted as
    # modules.
    'F0': [
        dict(slug='csharp', title='Elixir for C# developers', one='A bridge from .NET to the BEAM'),
    ],
    'F3': [
        dict(slug='history', title='A short history of Elixir', one='Why José Valim built Elixir on the Erlang VM in 2011, what it inherited from Erlang, Ruby, and Clojure, and'),
        dict(slug='timeline', title='The Elixir release timeline', one="An interactive timeline of Elixir's milestones, from the first commit in 2011 to the current stable release,"),
        dict(slug='under-the-hood', title='Under the hood', one='How Elixir source becomes BEAM bytecode'),
    ],
    'F5': [
        dict(slug='architecture', title='The Portal engine blueprint', one='The system this chapter builds, at a glance'),
        dict(slug='domain-model', title='The domain model', one='The data the Portal engine owns: three bounded contexts'),
        dict(slug='flow', title='The command & event flow', one='How one use case moves through the engine'),
    ],
    'F6': [
        dict(slug='blueprint', title="What we're building", one='The Portal as a real learning platform: browse, enroll, lessons, live progress, and a dashboard.'),
        dict(slug='journey', title='The developer journey', one='The path F6 walks, from the F5 facade to a deployed, real-time learning platform, in four arcs'),
        dict(slug='wiring', title='Wiring Phoenix onto the F5 engine', one='The seam the chapter turns on, in code'),
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
    # The six numbered chapters (F1–F6) are the course spine. Five carry nine
    # modules; F4 (Algorithms) carries twelve — 57 in all. The optional F0 history
    # chapter is surfaced separately, so it is not folded into this figure (that is
    # what the landing copy promises).
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
    'landing': (
        'content/f0-00-landing.html',
        'index.html',
        'Functional Programming in Elixir — a jonnify course',
        'A bridge from the algebra you already know to real-time apps on the BEAM. Six chapters, fifty-four modules, interactive and runnable throughout.',
    ),
    'f1-landing': (
        'content/f1-00-landing.html',
        'algebra.html',
        'F1 · Algebra — jonnify',
        'The Algebra chapter: the opening chapter of Functional Programming in Elixir. Nine lessons showing that the algebra you already know — functions, substitution, composition, recursion — is functional programming, with an algebra-to-Elixir dictionary and an interactive function visualizer.',
    ),
    'f1-05': (
        'content/f1-05-collections.html',
        'algebra-collections.html',
        'Sets, sequences & mappings — F1.05 · jonnify',
        'Three shapes of collection — ordered lists, distinct MapSets, key-to-value Maps — and Enum.map, the operation that applies a function across any of them.',
    ),
    'f1-03': (
        'content/f1-03-composition.html',
        'algebra-composition.html',
        'Composition, f∘g — F1.03 · jonnify',
        'Chaining functions into new ones: the composite g∘f, why order matters and grouping is free, and the pipe as composition written in evaluation order.',
    ),
    'f1-01': (
        'content/f1-01-functions.html',
        'algebra-functions.html',
        'What a function really is — F1.01 · jonnify',
        'A function as a mapping: domain, codomain, and range; the single-output rule; and the first-class function as an ordinary Elixir value.',
    ),
    'f1-07': (
        'content/f1-07-higher-order.html',
        'algebra-higher-order.html',
        'Higher-order operators (Σ, Π) — F1.07 · jonnify',
        'Σ and Π as operators over a function, the map / filter / reduce trio and how each reshapes a collection, and reduce as the general fold the others are instances of.',
    ),
    'f1-04': (
        'content/f1-04-immutability.html',
        'algebra-immutability.html',
        'Immutability & binding — F1.04 · jonnify',
        'A name is a fixed value, not a box: binding versus rebinding, the match operator and the pin, and immutable data whose updates return new values.',
    ),
    'f1-08': (
        'content/f1-08-pattern-matching.html',
        'algebra-pattern-matching.html',
        'Equations & pattern matching — F1.08 · jonnify',
        'Solving by structure: destructuring tuples, lists and maps, dispatching control by shape, and guards that refine a match by value.',
    ),
    'f1-09': (
        'content/f1-09-plotting-lab.html',
        'algebra-plotting-lab.html',
        'Functions on the plane — F1.09 · jonnify',
        'The F1 lab: a coordinate plotter for f, g, and their composites, with an x-trace that follows a value through f∘g — plotting as Enum.map, composition as a pipeline.',
    ),
    'f1-06': (
        'content/f1-06-recursion.html',
        'algebra-recursion.html',
        'Recursion & induction — F1.06 · jonnify',
        "Base case plus step: the call stack of a recursive sum, why the base case makes it terminate, and induction — the proof that shares recursion's shape.",
    ),
    'f1-02': (
        'content/f1-02-substitution.html',
        'algebra-substitution.html',
        'The substitution model — F1.02 · jonnify',
        'Equals for equals: evaluation by substitution, referential transparency, and the purity that makes a function safe to replace with its result.',
    ),
    'f4-landing': (
        'content/f4-00-landing.html',
        'algorithms.html',
        'Algorithms & Data Structures — F4 · jonnify',
        'The F4 chapter overview: nine modules from lists through trees, sorting, and hash-based maps to the persistent trie family — HAMT, CHAMP, and the branded CHAMP map keyed by a Snowflake pivot — plus dynamic programming and a lab. F4.01 is built; the rest show their planned dives.',
    ),
    'f4-09': (
        'content/f4-09-branded-champ.html',
        'algorithms-branded-champ.html',
        'Branded CHAMP maps & GenServer — F4.09 · jonnify',
        'The chapter folds together: the compressed CHAMP of F4.06, the branded Snowflake key of F4.07, and the persistence of F4.08 become one in-memory store — a CHAMP keyed by branded ids, partitioned by the three-letter namespace, owned by a GenServer. It is immutable (lock-free reads), structurally shared (cheap snapshots), and partitioned (a shallow sub-trie per kind). The Portal runs three: a session store, an entity registry, and a progress tracker.',
    ),
    'f4-09-3': (
        'content/f4-09-3-genserver.html',
        'algorithms-branded-champ-genserver.html',
        'Own it with a GenServer — F4.09.3 · jonnify',
        "The Portal's session store is a CHAMP behind a GenServer. The GenServer serializes writes through its mailbox and publishes each new snapshot; because the map is immutable, Portal.Auth.current_user/1 reads the published root lock-free on every request. Writes never race and reads never queue — the split the immutable, partitioned CHAMP makes possible.",
    ),
    'f4-09-1': (
        'content/f4-09-1-partition.html',
        'algorithms-branded-champ-partition.html',
        'Partition by namespace — F4.09.1 · jonnify',
        "The Portal's entity registry keeps users, sessions, lessons, and pages in one store: a tiny top-level map from a three-letter namespace to a CHAMP per kind. A lookup reads the prefix it already has, picks the partition, and descends only that sub-trie — so a USR key never shares a node with an LSN key, each partition stays shallow, and a kind can be snapshotted or evicted on its own.",
    ),
    'f4-09-2': (
        'content/f4-09-2-trie.html',
        'algorithms-branded-champ-trie.html',
        'Structural sharing — F4.09.2 · jonnify',
        "Inside a partition the CHAMP is keyed on the lesson's Snowflake, and Portal.Progress marks a lesson complete by returning a new map that shares every sub-tree except the path to the changed leaf. The previous snapshot stays valid, so a history of progress and a cheap diff between any two points come for free — the cost of an update is the trie's depth, not its size.",
    ),
    'f4-06': (
        'content/f4-06-champ.html',
        'algorithms-champ.html',
        'CHAMP maps — F4.06 · jonnify',
        "A CHAMP is the compressed successor to the HAMT: same O(log32 n) lookup, but each node splits its slots into two bitmaps and two densely packed arrays — entries and sub-nodes. That compression buys cache-friendly iteration and a canonical shape per map, which makes equality and snapshot diffs cheap. It is the structure under the course's persistent registry and the branded-CHAMP trie in the stack.",
    ),
    'f4-06-3': (
        'content/f4-06-3-equality.html',
        'algorithms-champ-equality.html',
        'Canonical equality — F4.06.3 · jonnify',
        'CHAMP maintains one canonical shape per set of entries, so two equal maps are structurally identical trees and equality short-circuits on shared sub-trees. The same sharing makes a one-entry change cheap — only the path to it differs — which is what lets the course diff two registry snapshots.',
    ),
    'f4-06-2': (
        'content/f4-06-2-iteration.html',
        'algorithms-champ-iteration.html',
        'Cache-friendly iteration — F4.06.2 · jonnify',
        'Because a CHAMP node keeps its entries contiguous and separate from sub-node pointers, iteration walks the entry array linearly in a canonical order and recurses into sub-nodes after — far fewer cache misses than a HAMT, where entries and pointers are interleaved across a 32-slot array.',
    ),
    'f4-06-1': (
        'content/f4-06-1-layout.html',
        'algorithms-champ-layout.html',
        'Compressed node layout — F4.06.1 · jonnify',
        "A CHAMP node carries a datamap and a nodemap — two bitmaps marking which of its 32 slots hold inline entries and which hold sub-nodes — and stores each kind in its own packed array with no empty cells. A slot's position in an array is the popcount of the lower bits of the matching bitmap.",
    ),
    'f4-11': (
        'content/f4-11-dynamic-programming.html',
        'algorithms-dynamic-programming.html',
        'Dynamic programming & advanced problems — F4.11 · jonnify',
        'Dynamic programming solves a problem with overlapping subproblems by solving each once and reusing it, in two styles: memoisation caches a recursion top-down, tabulation fills a table bottom-up. The hub counts how a learner can pace a track one or two lessons at a time — the Fibonacci recurrence — contrasting the exponential naive call count against one subproblem per lesson, and points to three Portal cases: prerequisite depth, a credit target, and typo-tolerant search.',
    ),
    'f4-11-1': (
        'content/f4-11-1-memoization.html',
        'algorithms-dynamic-programming-memoization.html',
        'Memoization & overlapping subproblems — F4.11.1 · jonnify',
        'The longest prerequisite chain to a lesson is one plus the deepest of its prerequisites — a recursion. Because prerequisites are shared, the plain recursion re-derives a popular one along every path that reaches it: over six lessons each built on the two before it, depth(L6) evaluates the lessons 8, 5, 3, 2, 1, 1 times — the Fibonacci numbers, 20 in all — while a cache evaluates each once, 6 in all, for the same answer.',
    ),
    'f4-11-3': (
        'content/f4-11-3-problems.html',
        'algorithms-dynamic-programming-problems.html',
        'Classic DP problems — F4.11.3 · jonnify',
        "Edit distance — the fewest single-character inserts, deletes, or substitutions between two strings — is the textbook two-dimensional DP: a cell per pair of prefixes, each built from the three above and to its left. Against the catalog title elixir, elixr is one edit, exilir two, exlir three; below a two-edit threshold the Portal offers a 'did you mean' suggestion. The grid is O(m x n) and collapses to one row when only the number is wanted.",
    ),
    'f4-11-2': (
        'content/f4-11-2-tabulation.html',
        'algorithms-dynamic-programming-tabulation.html',
        'Tabulation & bottom-up — F4.11.2 · jonnify',
        "The fewest modules (worth 1, 3, or 4 credits) summing to a target is one more than the best answer for the target minus a module's worth — optimal substructure. Tabulation fills a table of the fewest modules for every total from zero up, so the target reads off smaller cells. For six credits the table finds two (3 + 3) where greedy takes three (4 + 1 + 1), because greedy commits to a locally largest step and the table weighs all worths.",
    ),
    'f4-05': (
        'content/f4-05-hamt.html',
        'algorithms-hamt.html',
        'Hash array mapped tries — F4.05 · jonnify',
        "A HAMT spreads a hash table over a tree: it consumes the key's hash five bits at a time, branching up to 32 ways per level, so a node is a bitmap plus one packed array and depth is about log32 n. It is the structure the BEAM uses for a large immutable map, and the first of the chapter's three persistent-map modules — the page registry is a map, and that map is a trie like this one.",
    ),
    'f4-05-1': (
        'content/f4-05-1-bitmap.html',
        'algorithms-hamt-bitmap.html',
        'Bitmapped nodes — F4.05.1 · jonnify',
        "A HAMT node keeps one 32-bit bitmap marking which of its slots are occupied and one packed array holding only the occupants, in slot order; a slot's position in the array is the popcount of the lower bits. The single array mixes inline entries and child nodes — the one compromise that F4.06 removes with two bitmaps and two arrays.",
    ),
    'f4-05-2': (
        'content/f4-05-2-indexing.html',
        'algorithms-hamt-indexing.html',
        'Hash-prefix indexing — F4.05.2 · jonnify',
        "A HAMT reads the key's hash in five-bit chunks from the low end: level 0 reads bits 0-4, level 1 reads bits 5-9, each chunk naming one of 32 slots, so a key's path is its hash read five bits at a time and depth grows as log32 n. Any term keys the same way, so branded Snowflake ids index like a route string.",
    ),
    'f4-05-3': (
        'content/f4-05-3-sharing.html',
        'algorithms-hamt-sharing.html',
        'Structural sharing — F4.05.3 · jonnify',
        'An insert builds new nodes only along the path from the root to the changed leaf and shares every other sub-tree by reference, so the old map stays intact and a new version costs about log32 n nodes. That persistence makes a snapshot history nearly free — the basis for cheap LiveView diffs and the spine that leads to CHAMP.',
    ),
    'f4-07': (
        'content/f4-07-identifiers.html',
        'algorithms-identifiers.html',
        'Identifiers, Snowflake & branded ids — F4.07 · jonnify',
        "Every record in the portal needs a name. A database counter breaks across machines; a random UUID is large and unsortable. A Snowflake is a 64-bit integer carrying its own millisecond timestamp, a worker id, and a sequence — sortable by time, unique without coordination — and a branded id wraps it as a namespaced, base62 string like TSK0KHTOWnGLuC. It is the id behind every other module's keys.",
    ),
    'f4-07-3': (
        'content/f4-07-3-branded.html',
        'algorithms-identifiers-branded.html',
        'Branded ids — F4.07.3 · jonnify',
        'A branded id encodes the 64-bit Snowflake in base62 over 0-9A-Za-z, left-pads it to eleven characters, and prepends a three-letter namespace, e.g. PGE0NbWMtkosp8. It is url-safe, self-describing, lossless to decode, and order-preserving — the fixed width keeps lexical order equal to numeric order, which is time order.',
    ),
    'f4-07-1': (
        'content/f4-07-1-choosing.html',
        'algorithms-identifiers-choosing.html',
        'Choosing an identifier — F4.07.1 · jonnify',
        'An auto-increment counter is ordered and tiny but needs one writer, so it cannot scale across machines; a random UUID needs no coordination but is 128-bit and not time-sortable. A Snowflake keeps order without coordination, because the timestamp sits in the high bits — sorting a set of them recovers creation order.',
    ),
    'f4-07-2': (
        'content/f4-07-2-snowflake.html',
        'algorithms-identifiers-snowflake.html',
        'The Snowflake bigint — F4.07.2 · jonnify',
        "A Snowflake packs three fields into 64 bits: a 42-bit millisecond timestamp from a custom 2024 epoch, a 10-bit worker id, and a 12-bit per-millisecond sequence. Each field is read with one shift and one mask, and because time is in the high bits the integer's natural order is time order.",
    ),
    'f4-12': (
        'content/f4-12-lab.html',
        'algorithms-lab.html',
        'Lab: build a branded CHAMP store — F4.12 · jonnify',
        "The capstone lab assembles the chapter into one Portal.Store: a GenServer over a map from namespace to that namespace's CHAMP. A put is validated, routed to a partition by its three-letter prefix, stored in that partition's CHAMP, and dated for free from the Snowflake embedded in its id. The hub traces one write through those four layers — each an earlier lesson — and three dives build the store: insert and watch it grow, resolve ids as a registry, and query by time range.",
    ),
    'f4-12-1': (
        'content/f4-12-1-grow.html',
        'algorithms-lab-grow.html',
        'Watch a branded CHAMP grow — F4.12.1 · jonnify',
        "Each put reads a branded id's three-letter namespace and drops the entry into that namespace's partition, creating the partition on first use. Stepping through ten real keys, the store grows by partition — users, sessions, lessons, pages appear and fill as each key routes itself by prefix. Inside a partition the CHAMP root holds 32 entries before the 33rd forces a second level, keeping depth at ceil(log32 n); the write rebuilds only one partition and shares the rest.",
    ),
    'f4-12-3': (
        'content/f4-12-3-range.html',
        'algorithms-lab-range.html',
        'Query by time range — F4.12.3 · jonnify',
        "Because a Snowflake puts the timestamp in its high bits, ids sort by creation time and a time window becomes an id range: the smallest id at time t is (t - epoch) << 22, so computing the bounds for a window's start and end selects the entries created inside it with no timestamp column. The honest catch in memory is that a CHAMP is hash-ordered, so a true range scan needs a sorted index alongside it (gb_sets) or a filter over a small partition.",
    ),
    'f4-12-2': (
        'content/f4-12-2-registry.html',
        'algorithms-lab-registry.html',
        'A Snowflake registry — F4.12.2 · jonnify',
        'Hand the store any branded id and get/1 resolves it in one call: the prefix names the partition, the lookup is an O(log32 n) descent, and the creation time is decoded from the Snowflake with no stored column. An id of a known namespace that is absent returns not-found after a real search; an id of an unknown namespace (here TSK) is rejected before any search, the same edge check as the persistence lesson, even though it still decodes to a timestamp.',
    ),
    'f4-01': (
        'content/f4-01-lists.html',
        'algorithms-lists.html',
        'Lists, recursion & complexity — F4.01 · jonnify',
        'The BEAM list is a linked list of cons cells, not an array: prepend is O(1) and the tail is shared, every list function is written by recursion, and the cost of an operation is the number of cells it touches. Three dives on the shape, the recursion, and the big-O.',
    ),
    'f4-01-3': (
        'content/f4-01-3-big-o.html',
        'algorithms-lists-big-o.html',
        'Complexity & big-O on the BEAM — F4.01.3 · jonnify',
        'Big-O for a list is concrete: count the cons cells an operation touches. Working at the head is O(1); reaching the end — length, ++, last — is O(n). The cost cheat-sheet that motivates the rest of F4.',
    ),
    'f4-01-1': (
        'content/f4-01-1-cons.html',
        'algorithms-lists-cons.html',
        'Cons cells & the shape of a list — F4.01.1 · jonnify',
        'A cons cell is a head and a tail pointer. [head | tail] builds one new cell over an existing list, so prepend is O(1) and the old list is shared; hd/1 and tl/1 are O(1) reads; ++ appends by copying the left list, so it is O(n).',
    ),
    'f4-01-2': (
        'content/f4-01-2-recursion.html',
        'algorithms-lists-recursion.html',
        'Recursion over lists — F4.01.2 · jonnify',
        'You walk a list by recursion, not a loop: match [h | t], act on the head, recurse on the tail, and stop at []. sum, map, and length are the same shape with a different body; a tail-recursive accumulator turns the walk into a constant-space loop.',
    ),
    'f4-04': (
        'content/f4-04-maps.html',
        'algorithms-maps.html',
        'Maps, sets & hashing — F4.04 · jonnify',
        'The course you are reading runs on Phoenix LiveView, and its data layer is built from these structures: a map from route to page, a set of built routes, and branded Snowflake ids hashed as keys. Map lookup and set membership are O(1) on average; this module shows why, ending at the 32-way HAMT behind Elixir maps.',
    ),
    'f4-04-3': (
        'content/f4-04-3-hashing.html',
        'algorithms-maps-hashing.html',
        'Hashing & collisions — F4.04.3 · jonnify',
        'Maps and sets reach O(1) by hashing: phash2 turns a key into an integer, which picks a slot, and collisions resolve in place. Elixir stores entries in a 32-way HAMT, so depth is about log32 n — the door into F4.05. Branded Snowflake ids hash like any other key.',
    ),
    'f4-04-1': (
        'content/f4-04-1-lookup.html',
        'algorithms-maps-lookup.html',
        'Maps & key lookup — F4.04.1 · jonnify',
        "A map associates keys with values and looks one up in effectively constant time. Over the course's page registry — a map from route to a page struct — Map.get, Map.fetch, and Map.put read and write by key, and a LiveView's socket.assigns is itself just such a map.",
    ),
    'f4-04-2': (
        'content/f4-04-2-sets.html',
        'algorithms-maps-sets.html',
        'MapSet & membership — F4.04.2 · jonnify',
        "A MapSet stores unique elements and answers membership in O(1). Over the course's route sets — built versus planned — MapSet.member? is exactly the links gate, and union, intersection, and difference compose the sets. A MapSet is a map under the hood.",
    ),
    'f4-08': (
        'content/f4-08-persistence.html',
        'algorithms-persistence.html',
        'Branded ids & persistence — F4.08 · jonnify',
        'A branded Snowflake is the key everywhere the portal stores data: a 64-bit bigint primary key in SQLite and PostgreSQL, a namespaced string key in Redis. Its decisive property arrives before any store is touched — the id validates itself, so a request for a malformed or time-impossible id (GET /user/profile/USR0NbWMtkosp8) is answered 404 in constant time with zero I/O, shedding the enumeration and flooding traffic that targets a database.',
    ),
    'f4-08-1': (
        'content/f4-08-1-keys.html',
        'algorithms-persistence-keys.html',
        'Branded ids as keys — F4.08.1 · jonnify',
        "The database stores the 64-bit integer as a bigint primary key — eight bytes, numerically ordered — and the application brands it into a fourteen-character string only at the edge. An index on the integer answers a point lookup in O(log n), and because time is in the high bits the same index is clustered by creation time, which the next dive's range query rides on.",
    ),
    'f4-08-3': (
        'content/f4-08-3-redis.html',
        'algorithms-persistence-redis.html',
        'Redis keys — F4.08.3 · jonnify',
        "In Redis the id is a namespaced string key, user:USR0NbWMtkosp8. The self-validating id pays off hardest at a cache: an edge validator rejects malformed, out-of-range, wrong-namespace, and future ids with a 404 before a GET or a database fallback, so a scanner's flood becomes constant-time rejects. The honest limit is that a well-formed but absent id still costs one lookup.",
    ),
    'f4-08-2': (
        'content/f4-08-2-sql.html',
        'algorithms-persistence-sql.html',
        'SQLite & PostgreSQL — F4.08.2 · jonnify',
        "Because the high bits of the id are a timestamp, a window of time is a contiguous window of ids: compute the Snowflake at the window's open and close and query id >= min AND id < max. The primary-key index serves it as a contiguous read, so a point lookup and a time range share one structure — no created_at column, no second index, identical in SQLite and PostgreSQL.",
    ),
    'f4-10': (
        'content/f4-10-recipes.html',
        'algorithms-recipes.html',
        'Practical recipes in Elixir — F4.10 · jonnify',
        "The chapter's structures turned into the Portal's everyday code through three recurring recipes: a with chain to thread a request through validate-load-authorize without nested cases; a lazy Stream pipeline to build reports over large collections without materialising every step; and reading complexity to choose the structure a lookup deserves. The hub computes a learner's course progress as a count over the F4.09 store, and the recipes compose into one request flow.",
    ),
    'f4-10-1': (
        'content/f4-10-1-patterns.html',
        'algorithms-recipes-patterns.html',
        'Idiomatic patterns — F4.10.1 · jonnify',
        'A request to view a lesson clears four gates — validate the id, authenticate the caller, fetch the lesson, authorize access — then renders. Written as a with chain it is four lines that bind the happy path while every failure falls through to one else that maps a tagged error ({:error, :bad_id}, :unauthenticated, :not_found, :forbidden) to a status, and the steps after a failure never run.',
    ),
    'f4-10-2': (
        'content/f4-10-2-pipelines.html',
        'algorithms-recipes-pipelines.html',
        'Streams & pipelines — F4.10.2 · jonnify',
        'The activity feed wants the three most recent completions for a course. Eager Enum runs each stage to a full list — walking all twelve completions and mapping all seven matches before three are taken. Lazy Stream fuses filter and map into one pull that stops at the third match, examining five completions and allocating no intermediate lists for the same result. Eager still wins on small collections read to the end.',
    ),
    'f4-10-3': (
        'content/f4-10-3-profiling.html',
        'algorithms-recipes-profiling.html',
        'Profiling & complexity — F4.10.3 · jonnify',
        "Every request finds an active session. A list scan is O(n) and grows with the user base; a branded-CHAMP lookup is O(log32 n) and stays a few node hops — 2 at a thousand sessions, 4 at a hundred thousand, 5 at ten million. Reason about which scales before measuring with :timer.tc; log32 n is flat in practice but not literally O(1), and a small list still beats a trie. The Portal's store is a CHAMP for this reason.",
    ),
    'f4-03': (
        'content/f4-03-sorting.html',
        'algorithms-sorting.html',
        'Sorting & searching — F4.03 · jonnify',
        'Sorting and searching are two halves of one bargain: sort once at O(n log n), and every later lookup drops to an O(log n) binary search. Merge sort and quicksort are the divide-and-conquer recursion of F4.02; binary search is its halving descent. Three dives plus the comparison-sort lower bound.',
    ),
    'f4-03-3': (
        'content/f4-03-3-cost.html',
        'algorithms-sorting-cost.html',
        'Stability & sort cost — F4.03.3 · jonnify',
        'Sorts are ranked on average, worst case, space, and stability — whether equal keys keep their order. Over all of them sits a hard floor: a comparison sort is a decision tree with n! leaves, so it needs at least log2(n!) ~ n log n comparisons. Merge sort meets the floor and is stable.',
    ),
    'f4-03-2': (
        'content/f4-03-2-search.html',
        'algorithms-sorting-search.html',
        'Linear & binary search — F4.03.2 · jonnify',
        'Linear search checks elements one by one over any sequence — O(n). Binary search halves a sorted, randomly-accessible sequence — O(log n) — but a linked list has no O(1) middle, so binary search wants a tuple or a balanced tree, not a list.',
    ),
    'f4-03-1': (
        'content/f4-03-1-sorts.html',
        'algorithms-sorting-sorts.html',
        'Merge & quicksort — F4.03.1 · jonnify',
        'The two workhorse comparison sorts are both divide-and-conquer. Merge sort halves the list, sorts each half, and merges; quicksort picks a pivot, partitions the rest into smaller and larger, and recurses. Both average O(n log n); merge sort is stable and O(n log n) worst case, quicksort can hit O(n^2).',
    ),
    'f4-02': (
        'content/f4-02-trees.html',
        'algorithms-trees.html',
        'Trees & traversals — F4.02 · jonnify',
        'A binary tree is a cons cell with two pointers: a node is {value, left, right} or nil. The linear list walk becomes a traversal, and a balanced tree turns an O(n) walk into an O(log n) descent — the idea the trie family builds on. Three dives plus an advanced look at balance and tries.',
    ),
    'f4-02-3': (
        'content/f4-02-3-bfs.html',
        'algorithms-trees-bfs.html',
        'Breadth-first & balance — F4.02.3 · jonnify',
        'Breadth-first traversal walks the tree level by level with a FIFO queue. The level count is the search cost: a balanced tree of n nodes has about log2 n levels, while sorted insertion degenerates into an O(n) chain — which is why self-balancing trees and, later, tries exist.',
    ),
    'f4-02-2': (
        'content/f4-02-2-dfs.html',
        'algorithms-trees-dfs.html',
        'Depth-first: pre, in, post-order — F4.02.2 · jonnify',
        'Depth-first traversal makes the same two recursive calls and differs only in when it visits the node: before the calls (pre), between them (in), or after them (post). In-order on a binary search tree comes out sorted, and all three are one parameterised fold.',
    ),
    'f4-02-1': (
        'content/f4-02-1-shape.html',
        'algorithms-trees-shape.html',
        'Binary trees & recursive shape — F4.02.1 · jonnify',
        'A node is {value, left, right} or nil, so every tree function handles nil as the base case and a node by combining its two subtrees. size, height, and sum are one recursion with a different combine — and insert rebuilds only the path it changes, sharing the rest.',
    ),
    'f0-course': (
        'content/f0-00-course.html',
        'course.html',
        'Course contents — History · jonnify',
        'The full map of the course — six chapters and an optional history — plus an onramp for engineers arriving from C# and .NET, comparing the CLR and the BEAM and the functional ideas they share.',
    ),
    'f0-02': (
        'content/f0-02-beam-evolution.html',
        'course-beam-evolution.html',
        'The evolution of Erlang, the BEAM & OTP — F0.2 · jonnify',
        'Telecom roots and “let it crash”, the reduction-counting scheduler and per-process heaps, and the OTP supervision tree — the runtime Elixir stands on.',
    ),
    'f0-fm-csharp': (
        'content/f0-csharp.html',
        'course-csharp.html',
        'Elixir for C# developers — History · jonnify',
        "A bridge from .NET to the BEAM: how the two runtimes differ, the functional ideas C# has already adopted, and how the language-ext library maps Option, Either, immutability, and the actor model onto Elixir's own.",
    ),
    'f0-01': (
        'content/f0-01-fp-evolution.html',
        'course-fp-evolution.html',
        'The evolution of functional languages & runtimes — F0.1 · jonnify',
        'From the lambda calculus to LISP, the ML and Haskell branch, and the immutable turn — the lineage Elixir inherited, each idea paired with its Elixir form.',
    ),
    'f2-landing': (
        'content/f2-00-landing.html',
        'functional.html',
        'F2 · Functional Programming — jonnify',
        'The Functional Programming chapter: pure functions, persistent data, higher-order functions, folds, closures, and composition — a guided path through nine modules ending in a data-pipeline lab.',
    ),
    'f2-07': (
        'content/f2-07-adt.html',
        'functional-adt.html',
        'Algebraic data types — F2.07 · jonnify',
        'The algebra of types: product types hold several values at once and their counts multiply; sum types are one shape or another and their counts add; pattern matching takes them apart.',
    ),
    'f2-07-3': (
        'content/f2-07-3-matching.html',
        'functional-adt-matching.html',
        'Pattern matching on data — F2.07.3 · jonnify',
        'Taking algebraic data apart: destructuring products to bind fields, and dispatching on sum variants with case and function heads.',
    ),
    'f2-07-1': (
        'content/f2-07-1-product.html',
        'functional-adt-product.html',
        'Product types — F2.07.1 · jonnify',
        "Tuples and structs: bundling fields by position or by name, immutable struct update, and why a product type's inhabitants multiply.",
    ),
    'f2-07-2': (
        'content/f2-07-2-sum.html',
        'functional-adt-sum.html',
        'Sum types — F2.07.2 · jonnify',
        'Tagged tuples and variants: a value is one shape or another, the atom tag discriminates, and the inhabitants add — including the {:ok, _} | {:error, _} idiom.',
    ),
    'f2-06': (
        'content/f2-06-closures.html',
        'functional-closures.html',
        'Closures & partial application — F2.06 · jonnify',
        'A closure is a function plus the environment it captured. Building specialised functions by capturing a value, partial application, and the & capture operator.',
    ),
    'f2-06-2': (
        'content/f2-06-2-capture.html',
        'functional-closures-capture.html',
        'The capture operator — F2.06.2 · jonnify',
        'The & shorthand for anonymous functions: positional placeholders &1 and &2, and capturing named functions with &Module.fun/arity.',
    ),
    'f2-06-3': (
        'content/f2-06-3-currying.html',
        'functional-closures-currying.html',
        'Partial application & currying — F2.06.3 · jonnify',
        'Fixing arguments to specialise a function, and building curried functions by hand — applying arguments one at a time.',
    ),
    'f2-06-1': (
        'content/f2-06-1-environment.html',
        'functional-closures-environment.html',
        'Capturing the environment — F2.06.1 · jonnify',
        'What a closure captures and when: the value at definition time, immutability, lexical scope, and capturing several variables at once.',
    ),
    'f2-08': (
        'content/f2-08-composition.html',
        'functional-composition.html',
        'Composition & pipelines — F2.08 · jonnify',
        'Building programs by combining functions: composing two so one feeds the next, the pipe operator that threads a value left to right, and pipelines of map, filter, and reduce.',
    ),
    'f2-08-1': (
        'content/f2-08-1-compose.html',
        'functional-composition-compose.html',
        'Function composition — F2.08.1 · jonnify',
        'Composing functions by hand — f after g — why the order matters, and chaining three together.',
    ),
    'f2-08-2': (
        'content/f2-08-2-pipe.html',
        'functional-composition-pipe.html',
        'The pipe operator — F2.08.2 · jonnify',
        'The |> operator: threading a value as the first argument, reading left to right instead of inside out, and passing extra arguments.',
    ),
    'f2-08-3': (
        'content/f2-08-3-pipeline.html',
        'functional-composition-pipeline.html',
        'Building pipelines — F2.08.3 · jonnify',
        'Composing map, filter, and reduce into a pipeline over a dataset, watching the value transform at each stage.',
    ),
    'f2-05': (
        'content/f2-05-folds.html',
        'functional-folds.html',
        'map / filter / reduce (folds) — F2.05 · jonnify',
        'reduce as the universal fold: how the accumulator threads through a list, how swapping the combiner changes the result, and how map and filter are reduce with a list accumulator.',
    ),
    'f2-05-4': (
        'content/f2-05-4-advanced.html',
        'functional-folds-advanced.html',
        'Advanced folds — F2.05.4 · jonnify',
        'The Enum toolkit as folds with extra structure: scan as a running fold, plus map_reduce, flat_map, group_by, and frequencies.',
    ),
    'f2-05-2': (
        'content/f2-05-2-filter.html',
        'functional-folds-filter.html',
        'filter — F2.05.2 · jonnify',
        'Keeping elements that pass a predicate: filter and its inverse reject, and filtering then mapping as a pipeline.',
    ),
    'f2-05-1': (
        'content/f2-05-1-map.html',
        'functional-folds-map.html',
        'map — F2.05.1 · jonnify',
        'Transforming every element with a function: one-to-one output, length and order preserved, and why chained maps fuse into one.',
    ),
    'f2-05-3': (
        'content/f2-05-3-reduce.html',
        'functional-folds-reduce.html',
        'reduce — F2.05.3 · jonnify',
        'The general fold: accumulators of any shape — numbers, lists, maps — and building a frequency map step by step.',
    ),
    'f2-03': (
        'content/f2-03-higher-order.html',
        'functional-higher-order.html',
        'Higher-order functions — F2.03 · jonnify',
        'Functions as values: passing a function into Enum.map, the differing signatures map / filter / reduce / sort_by expect, and a factory that returns a function carrying a captured value.',
    ),
    'f2-02': (
        'content/f2-02-persistence.html',
        'functional-persistence.html',
        'Immutability & persistent data — F2.02 · jonnify',
        'Why copying is cheap: immutable values, structural sharing in lists and maps, and the memory cost of a full copy versus rebuilding only what changed.',
    ),
    'f2-09': (
        'content/f2-09-pipeline-lab.html',
        'functional-pipeline-lab.html',
        'The data-pipeline lab — F2.09 · jonnify',
        'The F2 capstone: compose filter, map, sort, and reduce stages over a dataset, watch the rows transform at each stage, and read the idiomatic Elixir pipeline the configuration generates.',
    ),
    'f2-01': (
        'content/f2-01-pure.html',
        'functional-pure.html',
        'Pure functions & side effects — F2.01 · jonnify',
        'What purity buys and how to keep it: same input gives the same output, what counts as a side effect, and the functional core / imperative shell that isolates effects at the edges.',
    ),
    'f2-04': (
        'content/f2-04-recursion.html',
        'functional-recursion.html',
        'Recursion patterns & tail calls — F2.04 · jonnify',
        'Recursion as the functional way to repeat: the call stack, tail calls and accumulators for constant stack space, and the patterns that recur — across three deep-dive subpages.',
    ),
    'f2-04-3': (
        'content/f2-04-3-patterns.html',
        'functional-recursion-patterns.html',
        'Recursion patterns — F2.04.3 · jonnify',
        'sum, length, reverse, map, and filter written recursively — and why each one is a fold over the list.',
    ),
    'f2-04-1': (
        'content/f2-04-1-shape.html',
        'functional-recursion-shape.html',
        'The shape of recursion — F2.04.1 · jonnify',
        'Base case and recursive case, and the call stack growing then unwinding as a body-recursive function runs to a result.',
    ),
    'f2-04-2': (
        'content/f2-04-2-tail-calls.html',
        'functional-recursion-tail-calls.html',
        'Tail calls & accumulators — F2.04.2 · jonnify',
        'Body versus tail recursion, the accumulator pattern, and how a tail call reuses the stack frame to run in constant space.',
    ),
    'f3-landing': (
        'content/f3-00-landing.html',
        'language.html',
        'The Elixir Language — F3 · jonnify',
        "The chapter that grounds the functional ideas of F2 in real Elixir: values and IEx, pattern matching, modules, enumerables and streams, structs, protocols, processes, and OTP. Start with the language's history, a release timeline, and a look under the hood.",
    ),
    'f3-04': (
        'content/f3-04-enum-streams.html',
        'language-enum-streams.html',
        'Enumerables & streams — F3.04 · jonnify',
        "A collection is anything that implements the Enumerable protocol; Enum walks it eagerly, and Stream walks it lazily. This module deepens the Enum steps from the pipe and adds lazy processing over a learner's full history. Three deep dives follow.",
    ),
    'f3-04-2': (
        'content/f3-04-2-comprehensions.html',
        'language-enum-streams-comprehensions.html',
        'Comprehensions — F3.04 · jonnify',
        'The for comprehension: generators draw from any enumerable, filters drop items, :into chooses the result collection, and multiple generators nest — set-builder notation as Elixir syntax.',
    ),
    'f3-04-1': (
        'content/f3-04-1-enum.html',
        'language-enum-streams-enum.html',
        'Enum, the eager workhorse — F3.04 · jonnify',
        'The Enumerable protocol unifies lists, ranges, maps, and streams, and the Enum module is the toolkit that walks them — map, filter, reduce, group_by, frequencies — each returning a new collection.',
    ),
    'f3-04-3': (
        'content/f3-04-3-streams.html',
        'language-enum-streams-streams.html',
        'Lazy streams — F3.04 · jonnify',
        'Stream builds a lazy recipe that computes nothing until an Enum function pulls values through — the same pipeline eager and lazy, early exit, infinite sequences, and when laziness is worth it.',
    ),
    'f3-fm-history': (
        'content/f3-00-history.html',
        'language-history.html',
        'A short history of Elixir — F3 · jonnify',
        'Why José Valim built Elixir on the Erlang VM in 2011, what it inherited from Erlang, Ruby, and Clojure, and how it reached a stable 1.0 in 2014.',
    ),
    'f3-02': (
        'content/f3-02-match.html',
        'language-match.html',
        'Pattern matching & the match operator — F3.02 · jonnify',
        'Pattern matching is how Elixir reads the shape of data and pulls it apart. This module introduces it through the project the whole course builds: a learning portal with magic-link sign-in and progress tracking. Three deep dives follow.',
    ),
    'f3-02-3': (
        'content/f3-02-3-branching.html',
        'language-match-branching.html',
        'Branching with case, with & guards — F3.02 · jonnify',
        "Dispatching on shape: function-head matching, case, guards, and the with pipeline — built around the portal's magic-link sign-in flow and its progress events.",
    ),
    'f3-02-2': (
        'content/f3-02-2-destructuring.html',
        'language-match-destructuring.html',
        'Destructuring portal data — F3.02 · jonnify',
        'Pulling fields out of tuples, lists, maps, and structs in a single match — the auth claims, request params, and progress records the learning portal passes around.',
    ),
    'f3-02-1': (
        'content/f3-02-1-operator.html',
        'language-match-operator.html',
        'The match operator — F3.02 · jonnify',
        '= asserts that a value matches a pattern and binds the rest; the pin operator ^ matches against a value you already have. Seen through verifying a magic-link sign-in.',
    ),
    'f3-03': (
        'content/f3-03-modules.html',
        'language-modules.html',
        'Functions, modules & the pipe — F3.03 · jonnify',
        "Functions are the unit of work, modules group them, and the pipe composes them. This module builds the learning portal's first real modules — Accounts, Auth, Catalog, Progress — and the functions they expose. Three deep dives follow.",
    ),
    'f3-03-1': (
        'content/f3-03-1-functions.html',
        'language-modules-functions.html',
        'Defining functions — F3.03 · jonnify',
        "Named functions with def and defp, multiple clauses that dispatch by pattern and guard, arity, anonymous functions, and the capture operator — seen through the portal's progress and auth helpers.",
    ),
    'f3-03-2': (
        'content/f3-03-2-organising.html',
        'language-modules-organising.html',
        'Organising with modules — F3.03 · jonnify',
        'defmodule, module attributes, alias and import, and documentation — how the Portal namespace is structured and how its modules refer to one another.',
    ),
    'f3-03-3': (
        'content/f3-03-3-pipe.html',
        'language-modules-pipe.html',
        'The pipe operator — F3.03 · jonnify',
        "|> threads a value as the first argument to the next call, turning nested calls into a readable pipeline — composing Portal and Enum functions over a learner's progress.",
    ),
    'f3-08': (
        'content/f3-08-otp.html',
        'language-otp.html',
        'OTP: GenServer & supervisors — F3.08 · jonnify',
        'OTP wraps the actor model in tested patterns: a GenServer holds state behind callbacks, a Supervisor restarts crashed children — an OTP system as a small tree of server, client, and supervisor.',
    ),
    'f3-08-2': (
        'content/f3-08-2-call-cast.html',
        'language-otp-call-cast.html',
        'Synchronous call, asynchronous cast — F3.08.2 · jonnify',
        'GenServer.call sends a request and blocks for the reply, routing to handle_call; GenServer.cast returns :ok at once, routing to handle_cast; a clean client API wraps both so callers never touch the raw message tags.',
    ),
    'f3-08-1': (
        'content/f3-08-1-genserver.html',
        'language-otp-genserver.html',
        'The GenServer behaviour — F3.08.1 · jonnify',
        'A GenServer abstracts the receive loop into a behaviour: init/1 sets the state, handle_call/3 answers synchronous requests, handle_cast/2 handles asynchronous ones, and each return tuple threads the next state.',
    ),
    'f3-08-3': (
        'content/f3-08-3-supervisors.html',
        'language-otp-supervisors.html',
        'Supervisors & restart strategies — F3.08.3 · jonnify',
        'A supervisor starts child processes and restarts them when they crash, by strategy — one_for_one, one_for_all, or rest_for_one — turning process isolation into recovery: the let-it-crash model.',
    ),
    'f3-09': (
        'content/f3-09-playground.html',
        'language-playground.html',
        'The process playground — F3.09 · jonnify',
        "The F3 capstone lab: a live supervised tree you drive — send messages into a worker's mailbox, drain them through its receive loop to move state, issue a synchronous call, and crash workers to watch the supervisor restart them per strategy. Each worker carries a branded PRC Snowflake PID.",
    ),
    'f3-07': (
        'content/f3-07-processes.html',
        'language-processes.html',
        'Processes & the actor model — F3.07 · jonnify',
        "A process is the BEAM's isolated unit of concurrency, coordinating only by messages — the actor model built from three primitives: spawn a process, send and receive messages, and loop to hold state.",
    ),
    'f3-07-2': (
        'content/f3-07-2-messages.html',
        'language-processes-messages.html',
        'Sending & receiving messages — F3.07.2 · jonnify',
        'send/2 appends a term to a mailbox and returns; receive pattern-matches messages out, leaving unmatched ones queued; a message carries self() so the server can reply — the whole actor protocol.',
    ),
    'f3-07-1': (
        'content/f3-07-1-spawn.html',
        'language-processes-spawn.html',
        'Spawning a process — F3.07.1 · jonnify',
        'spawn/1 starts a function as a new process and returns a PID at once; the child runs concurrently on its own heap, and a crash stays inside its boundary — the isolation a supervisor later builds on.',
    ),
    'f3-07-3': (
        'content/f3-07-3-state.html',
        'language-processes-state.html',
        'Holding state in a loop — F3.07.3 · jonnify',
        'A process holds state as the argument to a recursive receive loop, tail-calling itself with the updated value after each message — a hand-written GenServer, and the bridge into OTP.',
    ),
    'f3-06': (
        'content/f3-06-protocols.html',
        'language-protocols.html',
        'Protocols & behaviours — F3.06 · jonnify',
        "Two kinds of polymorphism in Elixir: a protocol dispatches a function on a value's type at runtime, a behaviour is a compile-time contract a module fulfils — with the portal's Summary and Notifier as examples.",
    ),
    'f3-06-3': (
        'content/f3-06-3-behaviours.html',
        'language-protocols-behaviours.html',
        'Behaviours & callbacks — F3.06.3 · jonnify',
        '@callback declares a typed contract on a module; @behaviour and @impl true fulfil it and let the compiler flag a missing callback — the compile-time counterpart to a protocol, and the basis for OTP behaviours.',
    ),
    'f3-06-2': (
        'content/f3-06-2-defimpl.html',
        'language-protocols-defimpl.html',
        'Implementing for a struct — F3.06.2 · jonnify',
        'defimpl Protocol, for: Struct gives the per-type bodies a call resolves to; three implementations form a dispatch table that grows by addition — open for extension, closed for modification.',
    ),
    'f3-06-1': (
        'content/f3-06-1-define.html',
        'language-protocols-define.html',
        'Defining a protocol — F3.06.1 · jonnify',
        "defprotocol declares a contract of function signatures; a call resolves to the implementation registered for the value's type, dispatching by tag, or raises Protocol.UndefinedError when no implementation exists.",
    ),
    'f3-05': (
        'content/f3-05-structs.html',
        'language-structs.html',
        'Structs, maps & keyword lists — F3.05 · jonnify',
        "Three containers for key-and-value data — the map, the keyword list, and the struct — and when each fits, with the portal's User as the running example.",
    ),
    'f3-05-2': (
        'content/f3-05-2-defaults.html',
        'language-structs-defaults.html',
        'Enforcing keys & defaults — F3.05.2 · jonnify',
        '@enforce_keys for required fields and keyword defaults in defstruct: what fills in for the common case, and the ArgumentError raised at construction when an essential field is missing.',
    ),
    'f3-05-1': (
        'content/f3-05-1-define.html',
        'language-structs-define.html',
        'Defining a struct — F3.05.1 · jonnify',
        'defstruct over Portal.Accounts.User: the %User{} literal as sugar over a map, and the hidden __struct__ key that names the module and makes a struct an ordinary map at runtime.',
    ),
    'f3-05-3': (
        'content/f3-05-3-matching.html',
        'language-structs-matching.html',
        "Matching on a struct's type — F3.05.3 · jonnify",
        'The %Struct{} pattern dispatches on the __struct__ tag across function clauses; why clause order matters when a struct is a map, and the is_struct/2 guard that keeps plain maps in their own clause.',
    ),
    'f3-fm-timeline': (
        'content/f3-00-timeline.html',
        'language-timeline.html',
        'The Elixir release timeline — F3 · jonnify',
        "An interactive timeline of Elixir's milestones, from the first commit in 2011 to the current stable release, with one headline feature per version.",
    ),
    'f3-fm-under-the-hood': (
        'content/f3-00-under-the-hood.html',
        'language-under-the-hood.html',
        'Under the hood — F3 · jonnify',
        'How Elixir source becomes BEAM bytecode: tokenizing, parsing to the quoted AST, macro expansion, and the Erlang VM that runs the result.',
    ),
    'f3-01': (
        'content/f3-01-values.html',
        'language-values.html',
        'Values, types & IEx — F3.01 · jonnify',
        'The data Elixir is built from — integers, floats, atoms, booleans, strings, lists, tuples, and maps — explored through IEx, the interactive shell, and the i/1 helper.',
    ),
    'f6-landing': (
        'content/f6-00-landing.html',
        'phoenix.html',
        'Phoenix Framework — F6 · jonnify',
        'The F6 chapter overview: building a real, real-time learning platform on top of the F5 Portal engine. Nine modules add a Phoenix web layer over the same facade — the request lifecycle, routing and plugs, Ecto, contexts, HEEx, LiveView, PubSub, and deployment — ending in a live dashboard. The chapter front matter is live; the modules are planned, with their build path shown.',
    ),
    'f6-fm-blueprint': (
        'content/f6-00-blueprint.html',
        'phoenix-blueprint.html',
        "What we're building — F6.0.2 · jonnify",
        'The Portal as a real learning platform: browse, enroll, lessons, live progress, and a dashboard. Underneath is the F5 stack with one band added on top — a Phoenix web layer (endpoint, router, controllers, LiveView) that calls the F5 facade — and an Ecto adapter beneath. The two middle layers, the engine and the domain core, are exactly as F5 left them.',
    ),
    'f6-04': (
        'content/f6-04-contexts.html',
        'phoenix-contexts.html',
        'Contexts & domain design — F6.04 · jonnify',
        "A context is a dedicated module that groups related functionality behind a public API and hides its schemas and the Repo — the same idea as the hexagonal Portal facade from F5, under Phoenix's name for it. Three dives: drawing context boundaries, reconciling a context with the F5 facade and its port, and composing across contexts without breaking their boundaries.",
    ),
    'f6-04-1': (
        'content/f6-04-1-boundaries.html',
        'phoenix-contexts-boundaries.html',
        'Context boundaries — F6.04.1 · jonnify',
        'A context groups related functionality behind a public API and keeps its schemas and the Repo private. How to draw the line by cohesion rather than by table, why exposing a schema across a boundary couples two contexts, and the difference between a controller that calls Catalog.get_course!/1 and one that reaches the Repo.',
    ),
    'f6-04-3': (
        'content/f6-04-3-composition.html',
        'phoenix-contexts-composition.html',
        'Composing contexts — F6.04.3 · jonnify',
        'How one context depends on another without breaking boundaries: call the public API, pass ids or public structs, never touch a foreign schema or Repo. A one-way dependency graph with no cycles, Enrollment calling Catalog, and a with pipeline across contexts that returns the closed %Portal.Error{}.',
    ),
    'f6-04-2': (
        'content/f6-04-2-vs-facade.html',
        'phoenix-contexts-vs-facade.html',
        'Contexts vs the F5 facade — F6.04.2 · jonnify',
        "A Phoenix context and the F5 Portal facade are the same idea — a public API over a slice of the domain. How they layer (web → facade → contexts → adapters), where Phoenix's default puts Ecto in the context, and how this course keeps Ecto behind the F6.03 port so a context calls the port, not the Repo.",
    ),
    'f6-08': (
        'content/f6-08-deployment.html',
        'phoenix-deployment.html',
        'Auth, deployment & going live — F6.08 · jonnify',
        'Taking the whole application to production: sessions and authentication so the app knows who the user is, releases and runtime config that package it to run, and the deploy itself — build, migrate, boot — with clustering so the F6.07 PubSub and Presence span every node. Three dives over the same supervised system from F5, now live in production.',
    ),
    'f6-08-1': (
        'content/f6-08-1-auth.html',
        'phoenix-deployment-auth.html',
        'Sessions & authentication — F6.08.1 · jonnify',
        'mix phx.gen.auth generates an Accounts context, a User schema, and the session plumbing. The session is a signed cookie carrying a token; a plug loads the current user into conn.assigns, and a LiveView enforces auth with on_mount before the socket connects — authentication is just another context plus standard plugs.',
    ),
    'f6-08-3': (
        'content/f6-08-3-deploy.html',
        'phoenix-deployment-deploy.html',
        'Deploying to production — F6.08.3 · jonnify',
        'The deploy is build, migrate, boot: compile the release, run pending migrations with a release command, then start the supervision tree so the endpoint serves over HTTPS. Clustering connects the nodes so the F6.07 PubSub and Presence span the whole cluster, and the F5 supervision tree keeps it alive.',
    ),
    'f6-08-2': (
        'content/f6-08-2-releases.html',
        'phoenix-deployment-releases.html',
        'Releases & config — F6.08.2 · jonnify',
        'mix release packages the app, its dependencies, and the BEAM into one self-contained artifact. config/runtime.exs is evaluated at boot and reads env vars for secrets and the database URL, distinct from compile-time config, and a release has no mix, so migrations run through a small release command module.',
    ),
    'f6-03': (
        'content/f6-03-ecto.html',
        'phoenix-ecto.html',
        'Ecto: schemas, changesets & queries — F6.03 · jonnify',
        "Ecto in three pieces: a schema maps a table to a struct, a changeset validates before a write, and the repo runs queries and persists. The whole library lives behind the engine's port — the F5.09 Postgres adapter — so the domain core still names no database. Three dives: schemas and migrations, changesets and validation, and queries and the repo.",
    ),
    'f6-03-2': (
        'content/f6-03-2-changesets.html',
        'phoenix-ecto-changesets.html',
        'Changesets & validation — F6.03.2 · jonnify',
        'A changeset is a pure pipeline — cast permits and coerces fields, validate checks the rules, and a constraint defers to the database — producing a struct that carries valid? and errors before any write. The engine wraps a failed changeset in the closed %Portal.Error{} contract from F5.08.',
    ),
    'f6-03-3': (
        'content/f6-03-3-repo.html',
        'phoenix-ecto-repo.html',
        'Queries & the repo — F6.03.3 · jonnify',
        "The Repo executes composable Ecto queries and persists changesets — get one row by Snowflake id, run a query, insert a changeset. Crucially the Repo lives behind the engine's port, the F5.09 Postgres adapter, so the domain core calls the facade and never the database directly.",
    ),
    'f6-03-1': (
        'content/f6-03-1-schemas.html',
        'phoenix-ecto-schemas.html',
        'Schemas & migrations — F6.03.1 · jonnify',
        'A migration creates and evolves a database table; a schema maps that table to an Elixir struct you work with as %Course{}. The primary key is a Snowflake bigint minted by Portal.ID rather than a database serial, so the same time-ordered id convention from F4 and F5 carries into the database row.',
    ),
    'f6-05': (
        'content/f6-05-heex.html',
        'phoenix-heex.html',
        'Templates, components & HEEx — F6.05 · jonnify',
        'HEEx is the view half of the request a controller returns: a template renders the assigns the controller set, function components make markup reusable and compile-checked, and forms are backed by changesets. Three dives: templates and assigns, function components and slots, and forms and inputs — all rendering data the contexts expose, never the database directly.',
    ),
    'f6-05-2': (
        'content/f6-05-2-components.html',
        'phoenix-heex-components.html',
        'Function components & slots — F6.05.2 · jonnify',
        'A function component is a pure function from assigns to markup, declared with attr and slot so its inputs are validated at compile time. One <.course_card> replaces copied markup across templates, and render_slot/1 lets a component wrap caller-supplied content.',
    ),
    'f6-05-3': (
        'content/f6-05-3-forms.html',
        'phoenix-heex-forms.html',
        'Forms & inputs — F6.05.3 · jonnify',
        "A form is a changeset turned into a form with to_form/1. <.form for={@form}> and <.input field={@form[:title]}> render fields and surface the F6.03 changeset errors inline, and the submitted params flow back to the context's create or update function, closing the loop from view to domain.",
    ),
    'f6-05-1': (
        'content/f6-05-1-templates.html',
        'phoenix-heex-templates.html',
        'Templates & assigns — F6.05.1 · jonnify',
        'A HEEx template renders the assigns a controller set — @courses, @course — using :for and :if as attributes, curly interpolation for values, and verified ~p routes for links. The template holds no business logic and never queries the database; it is a pure function of its assigns.',
    ),
    'f6-fm-journey': (
        'content/f6-00-journey.html',
        'phoenix-journey.html',
        'The developer journey — F6.0.1 · jonnify',
        'The path F6 walks, from the F5 facade to a deployed, real-time learning platform, in four arcs: stand Phoenix up (F6.01–F6.02), add data and domain with Ecto and contexts (F6.03–F6.04), render and go live with HEEx and LiveView (F6.05–F6.06), then make it real-time, secure, and shipped (F6.07–F6.09). The rule never changes: Phoenix calls only the Portal facade.',
    ),
    'f6-01': (
        'content/f6-01-lifecycle.html',
        'phoenix-lifecycle.html',
        'Architecture & the request lifecycle — F6.01 · jonnify',
        "How a request travels through Phoenix and where it meets the F5 engine: the endpoint plug stack, the router match and pipeline, the controller action that calls the Portal facade, and the view that renders the result. Three dives — the lifecycle end to end, the endpoint as a supervised process in F5's tree, and the controller/view seam where the web calls only the facade.",
    ),
    'f6-01-3': (
        'content/f6-01-3-controllers.html',
        'phoenix-lifecycle-controllers.html',
        'Controllers, views & the facade seam — F6.01.3 · jonnify',
        'Where your code lives in the lifecycle: a thin controller calls only the Portal facade, branches on the closed error contract, and picks a view; the view renders assigns to markup. The controller is the seam between HTTP and the engine, and the rule is that it names only Portal and %Portal.Error{}.',
    ),
    'f6-01-2': (
        'content/f6-01-2-endpoint.html',
        'phoenix-lifecycle-endpoint.html',
        'The endpoint, supervised — F6.01.2 · jonnify',
        'PortalWeb.Endpoint has two roles: the outermost plug — static files, parsers, session, the router — and a supervised process, one more child of the OTP tree the F5.09 lab assembled. The endpoint is where HTTP and OTP meet, and adding it to the tree is the whole structural change F6 makes.',
    ),
    'f6-01-1': (
        'content/f6-01-1-request-path.html',
        'phoenix-lifecycle-request-path.html',
        'The request lifecycle — F6.01.1 · jonnify',
        "A request from the browser to the response, step by step: Bandit hands the connection to PortalWeb.Endpoint, the endpoint runs its plug stack, the router matches a route through a pipeline, the controller action calls the Portal facade, and the view renders the result. Only the facade call is domain work; the rest is the framework's pipeline.",
    ),
    'f6-09': (
        'content/f6-09-live-dashboard.html',
        'phoenix-live-dashboard.html',
        'The live dashboard — F6.09 · jonnify',
        'The capstone lab: a real-time operations dashboard that converges the whole course. The F5 engine emits events, the domain broadcasts them on a topic (F6.07), and a LiveView (F6.06) folds each event into a read model — live counts and an activity feed — that every connected client sees at once, with a Presence viewer count and auth and clustering from F6.08. Three dives: build the dashboard, broadcast engine events, and many clients live.',
    ),
    'f6-09-1': (
        'content/f6-09-1-build.html',
        'phoenix-live-dashboard-build.html',
        'Build the dashboard — F6.09.1 · jonnify',
        'The dashboard is a LiveView that holds a read model on its socket: metric counts seeded from the F6.04 contexts at mount, plus a capped stream for a live activity feed. render/1 draws metric cards and the feed, and the socket holds derived state rather than anything stored.',
    ),
    'f6-09-3': (
        'content/f6-09-3-multi-client.html',
        'phoenix-live-dashboard-multi-client.html',
        'Many clients, live — F6.09.3 · jonnify',
        'One broadcast reaches every connected dashboard at once, so all viewers update together, and Presence reports a live count of who is watching. The dashboard only reads and folds — a projection over the event stream — and clustering from F6.08 spans nodes in production.',
    ),
    'f6-09-2': (
        'content/f6-09-2-stream.html',
        'phoenix-live-dashboard-stream.html',
        'Broadcast engine events — F6.09.2 · jonnify',
        'The domain emits events after a write (F6.07) and the dashboard subscribes to the topic on its connected mount. handle_info/2 folds each event into the read model — bumping a count and prepending to the feed stream — so the numbers and the activity feed stay live without a reload.',
    ),
    'f6-06': (
        'content/f6-06-liveview.html',
        'phoenix-liveview.html',
        'Phoenix LiveView fundamentals — F6.06 · jonnify',
        'LiveView makes the F6.05 templates live: instead of a stateless request, a stateful server process holds the socket assigns, renders HEEx from them, and pushes only the diff over a WebSocket on every change. Three dives: mount and assigns, handle_event and state, and render and diffs — the same HEEx and the same contexts, now interactive without hand-written JavaScript.',
    ),
    'f6-06-2': (
        'content/f6-06-2-events.html',
        'phoenix-liveview-events.html',
        'handle_event & state — F6.06.2 · jonnify',
        'Bindings like phx-click, phx-change, and phx-submit send events to handle_event/3, which transforms the socket assigns and returns {:noreply, socket}. A live search box filtering the course list and a live create form reuse the same Portal contexts and changesets from F6.04 and F6.05, each event re-rendering the process with no page reload.',
    ),
    'f6-06-1': (
        'content/f6-06-1-mount.html',
        'phoenix-liveview-mount.html',
        'mount & assigns — F6.06.1 · jonnify',
        'A LiveView is a stateful process connected to the browser over a socket. mount/3 returns its initial state, and it runs twice — once for the disconnected HTTP first paint, once for the connected socket — so connected?(socket) guards the one-time side effects, exactly as a GenServer init/1 sets up a process once.',
    ),
    'f6-06-3': (
        'content/f6-06-3-render.html',
        'phoenix-liveview-render.html',
        'render & diffs — F6.06.3 · jonnify',
        'render/1 returns HEEx from the assigns, and LiveView tracks which assigns changed to send only those values over the socket. A HEEx template compiles into static segments and dynamic holes, so the diff is the minimal delta of the rendered state since the last render; streams keep large, append-only collections out of socket memory.',
    ),
    'f6-07': (
        'content/f6-07-pubsub.html',
        'phoenix-pubsub.html',
        'PubSub, channels & real-time — F6.07 · jonnify',
        "PubSub turns one LiveView into many that update together: the domain broadcasts an event on a topic after a write, every subscribed LiveView receives it in handle_info and re-renders, and one user's change becomes everyone's live update. Three dives: broadcasting engine events, subscribing a LiveView, and channels and presence — real-time built on the same OTP message passing as the F5 engine.",
    ),
    'f6-07-1': (
        'content/f6-07-1-broadcast.html',
        'phoenix-pubsub-broadcast.html',
        'Broadcasting engine events — F6.07.1 · jonnify',
        'Phoenix.PubSub is process-to-process publish/subscribe over a string topic. The domain broadcasts an event after a successful write — the context emits it, not the web layer — and a thin facade wrapper keeps the PubSub server name and the topics in one place, started in the application supervision tree.',
    ),
    'f6-07-3': (
        'content/f6-07-3-presence.html',
        'phoenix-pubsub-presence.html',
        'Channels & presence — F6.07.3 · jonnify',
        'Channels are the lower-level real-time primitive LiveView is built on, with explicit join and handle_in for custom client protocols. Presence tracks who is subscribed to a topic, synced across nodes by a CRDT, which is how a live viewer count stays correct across a cluster.',
    ),
    'f6-07-2': (
        'content/f6-07-2-subscribe.html',
        'phoenix-pubsub-subscribe.html',
        'Subscribing a LiveView — F6.07.2 · jonnify',
        'A LiveView subscribes to a topic on its connected mount and receives broadcasts in handle_info/2 — the process-message callback, distinct from handle_event/3 for browser events. It updates assigns or a stream and re-renders, so a write by one client appears live for every connected client.',
    ),
    'f6-02': (
        'content/f6-02-routing.html',
        'phoenix-routing.html',
        'Routing, controllers & plugs — F6.02 · jonnify',
        'The plug pipeline that carries a request to a controller: routes map a verb and path to an action, named pipelines are reusable stacks of plugs, and scopes run a group of routes through one. Three dives — routes and verbs, pipelines and scopes, and writing a plug — building out the match in the middle of the F6.01 lifecycle.',
    ),
    'f6-02-2': (
        'content/f6-02-2-pipelines.html',
        'phoenix-routing-pipelines.html',
        'Pipelines & scopes — F6.02.2 · jonnify',
        'A named pipeline is a reusable, ordered stack of plugs; a scope runs a group of routes through one with pipe_through. The :browser pipeline fetches the session and protects from forgery; :api accepts JSON; auth becomes one more pipeline that requires a logged-in user before a route is reached.',
    ),
    'f6-02-3': (
        'content/f6-02-3-plugs.html',
        'phoenix-routing-plugs.html',
        'Writing a plug — F6.02.3 · jonnify',
        'The contract every stage of the pipeline shares: a plug is init/1 plus call(conn, opts), taking a conn and returning a conn. A module plug that loads the current user and halt/1 to stop the pipeline early; a function plug for small steps. Everything in the request path — endpoint, pipeline, router — is a plug.',
    ),
    'f6-02-1': (
        'content/f6-02-1-routes.html',
        'phoenix-routing-routes.html',
        'Routes & verbs — F6.02.1 · jonnify',
        "How a verb and a path map to one controller action: get and post, resources for the seven RESTful routes, and live for a LiveView. Route params arrive in the action's params map, and verified ~p paths are checked against the router at compile time so a typo is a warning, not a broken link.",
    ),
    'f6-fm-wiring': (
        'content/f6-00-wiring.html',
        'phoenix-wiring.html',
        'Wiring Phoenix onto the F5 engine — F6.0.3 · jonnify',
        "The seam the chapter turns on, in code: PortalWeb.Endpoint joins the supervision tree the F5.09 lab assembled, a live route maps a URL to a LiveView, and the LiveView's mount and handle_event call only the Portal facade. Three additions on top of the engine — a child, a route, and a caller — never edits inside it.",
    ),
    'f5-landing': (
        'content/f5-00-landing.html',
        'pragmatic.html',
        'Pragmatic Programming — F5 · jonnify',
        'The F5 chapter overview: a pragmatic build of the Portal engine in Elixir. Nine modules carry one product from a decoupled core through domain modeling, a tracer-bullet walking skeleton, design by contract, commands/queries/events, where state lives, testing, and integration seams — ending in a lab where the engine facade is mounted behind a LiveView sketch, ready to integrate with Phoenix LiveView in F6.',
    ),
    'f5-fm-architecture': (
        'content/f5-00-architecture.html',
        'pragmatic-architecture.html',
        'The Portal engine blueprint — F5.0.1 · jonnify',
        'The system this chapter builds, at a glance: the Portal engine is a framework-free domain core that sits between the branded CHAMP store from F4 below and the Phoenix LiveView UI from F6 above. Four layers — UI, the engine facade, the domain core (contexts, commands, queries, events), and persistence — each built by a specific F5 module, so the chapter has one destination: a UI-ready engine boundary.',
    ),
    'f5-08': (
        'content/f5-08-boundaries.html',
        'pragmatic-boundaries.html',
        'Boundaries & integration seams — F5.08 · jonnify',
        'The engine works, but its callers still have to know it is a process with message shapes and a chosen store. F5.08 draws the boundary with hexagonal architecture: the core declares its needs as ports (behaviours), adapters implement them, a facade is the one door the UI calls, and failures cross the line as a closed set of typed errors. Three dives on ports and adapters, the engine facade, and error contracts for the UI.',
    ),
    'f5-08-3': (
        'content/f5-08-3-errors.html',
        'pragmatic-boundaries-errors.html',
        'Error contracts for the UI — F5.08.3 · jonnify',
        'Failure is part of the contract: a closed set of %Portal.Error{} codes, mapped from internal reasons at the boundary, so the UI renders a finite list of outcomes exhaustively. Expected failures become typed errors; impossible states stay crashes for the supervisor, and an unmodelled reason raises rather than leaking.',
    ),
    'f5-08-2': (
        'content/f5-08-2-facade.html',
        'pragmatic-boundaries-facade.html',
        'The engine facade — F5.08.2 · jonnify',
        'The driving port: a small context module — enroll/2, deliver_lesson/2, progress_of/1 — that names intentions and hides the GenServer, the event log, and the reducer. It keeps the command/query split in its specs and is the only place GenServer.call appears, so the runtime can change without touching callers.',
    ),
    'f5-08-1': (
        'content/f5-08-1-ports.html',
        'pragmatic-boundaries-ports.html',
        'Ports & adapters — F5.08.1 · jonnify',
        'A port is an Elixir behaviour the core depends on; an adapter is a module that implements it; configuration decides which adapter is loaded. One EventStore contract, an in-memory adapter for dev and tests and an Ecto adapter for production, and a dependency arrow that points inward at the behaviour, never at an adapter.',
    ),
    'f5-04': (
        'content/f5-04-contracts.html',
        'pragmatic-contracts.html',
        'Design by contract — F5.04 · jonnify',
        'Every command on the engine carries a contract: a precondition the caller must meet, a postcondition the function guarantees, and an invariant always true of the state. F5.04 makes the enroll command honest — expressing those conditions in idiomatic Elixir with guards, with chains, tagged tuples, and raises, and failing fast at the boundary so a violation stops the command before it can corrupt anything. Three dives on the conditions, the Elixir assertions, and failing fast.',
    ),
    'f5-04-2': (
        'content/f5-04-2-assertions.html',
        'pragmatic-contracts-assertions.html',
        'Assertions in Elixir — F5.04.2 · jonnify',
        'Elixir has no design-by-contract keywords, so contracts are written in its idioms: guards and pattern matching express preconditions on shape, a with chain composes them and short-circuits on the first failure, tagged tuples carry expected errors back to the caller, and raise crashes loudly on a broken invariant — a bug, not a bad request.',
    ),
    'f5-04-1': (
        'content/f5-04-1-conditions.html',
        'pragmatic-contracts-conditions.html',
        'Preconditions, postconditions & invariants — F5.04.1 · jonnify',
        "A contract has three parts and three owners. The precondition is the caller's obligation — valid ids, not already enrolled. The postcondition is the function's guarantee — a fresh enrollment with progress 0. The invariant is what every operation must preserve — progress stays within 0..100. Each says who is at fault when it breaks.",
    ),
    'f5-04-3': (
        'content/f5-04-3-fail-fast.html',
        'pragmatic-contracts-fail-fast.html',
        'Failing fast — F5.04.3 · jonnify',
        'Check at the boundary and stop on the first violation, before the struct is built or the store is touched. An expected failure returns a tagged error the caller handles; an impossible state raises and crashes. Either way the error lands close to its cause and nothing downstream is corrupted — the opposite of failing late and silently.',
    ),
    'f5-05': (
        'content/f5-05-cqrs.html',
        'pragmatic-cqrs.html',
        'Commands, queries & events — F5.05 · jonnify',
        'With the enroll command now contract-checked, F5.05 formalizes how the engine handles change: writes are commands that return only success or failure, reads are queries that return data and change nothing, and every change is recorded as a past-tense domain event. State is then derived by folding those events, which makes the engine a reducer. Three dives on command/query separation, domain events, and the engine as a reducer.',
    ),
    'f5-05-1': (
        'content/f5-05-1-cqs.html',
        'pragmatic-cqrs-cqs.html',
        'Command/query separation — F5.05.1 · jonnify',
        'Command/query separation is one rule: a function either changes state and returns only whether it worked, or returns data and changes nothing — never both. enroll is a command, courses_of is a query. Keeping them apart makes queries safe to repeat and commands honest about what they do.',
    ),
    'f5-05-2': (
        'content/f5-05-2-events.html',
        'pragmatic-cqrs-events.html',
        'Domain events — F5.05.2 · jonnify',
        'Model every change as a past-tense fact: %LearnerEnrolled{}, %LessonDelivered{}, %ProgressRecorded{}. An event is immutable, named for what happened, and carries the data of the change plus the time it occurred. Events are the record the engine is built from.',
    ),
    'f5-05-3': (
        'content/f5-05-3-reducer.html',
        'pragmatic-cqrs-reducer.html',
        'The engine as a reducer — F5.05.3 · jonnify',
        'State is not stored so much as derived: a command emits events, each event evolves the state, and one reduce over the event log replays the engine to its current state. Two pure functions — decide and evolve — are the whole engine, and a fold is how they run.',
    ),
    'f5-02': (
        'content/f5-02-domain.html',
        'pragmatic-domain.html',
        'Modeling the Portal domain — F5.02 · jonnify',
        "The engine needs a shape before it needs behavior. F5.02 models the Portal's domain in three layers: each entity is a plain struct with a typespec; entities are grouped into bounded contexts — Accounts, Catalog, Learning — that reference one another only by branded id; and each context exposes a small public API that validates input and hides its internals. Three dives on structs, contexts, and the public API.",
    ),
    'f5-fm-domain-model': (
        'content/f5-00-domain-model.html',
        'pragmatic-domain-model.html',
        'The domain model — F5.0.2 · jonnify',
        "The data the Portal engine owns: three bounded contexts — Accounts (User, Session), Catalog (Course, Lesson, Page), and Learning (Enrollment, Progress) — modeled as plain structs and keyed by the branded Snowflake ids from F4. The contexts are the engine's seams; each owns its entities and exposes a small public API, the shape F5.02 builds.",
    ),
    'f5-02-3': (
        'content/f5-02-3-api.html',
        'pragmatic-domain-api.html',
        "A context's public API — F5.02.3 · jonnify",
        'Each context exposes a small set of public functions — a smart constructor that validates and returns {:ok, struct} or {:error, reason}, a command, a query — and keeps its structs and helpers private. The API is the contract every caller depends on, from the thin server today to Phoenix in F6.',
    ),
    'f5-02-2': (
        'content/f5-02-2-contexts.html',
        'pragmatic-domain-contexts.html',
        'Bounded contexts — F5.02.2 · jonnify',
        "A bounded context is a module that owns a few entities and guards their rules — Accounts owns User and Session, Catalog owns Course and Lesson, Learning owns Enrollment and Progress. Contexts reference one another only by branded id, never by reaching into each other's structs, so each context can change on its own.",
    ),
    'f5-02-1': (
        'content/f5-02-1-structs.html',
        'pragmatic-domain-structs.html',
        'Structs & typespecs — F5.02.1 · jonnify',
        'An entity is a plain struct: @enforce_keys names the fields it cannot exist without, defstruct gives the optional ones their defaults, and a @type t documents the shape and lets Dialyzer check it. Branded-id fields carry their namespace, so a malformed reference is visible at a glance — no database row, just data.',
    ),
    'f5-09': (
        'content/f5-09-engine-lab.html',
        'pragmatic-engine-lab.html',
        'Lab: the Portal engine, LiveView-ready — F5.09 · jonnify',
        'The finale assembles eight modules into one running Portal: a supervision tree with the engine behind its facade, fed by an event-store port, mounted behind a LiveView sketch, with the handoff to F6 stated. It ships with a spec and copy-paste build prompts that generate the Portal logic end to end. Three dives: the engine facade end to end, a LiveView mount sketch, and what ships in F6.',
    ),
    'f5-09-1': (
        'content/f5-09-1-end-to-end.html',
        'pragmatic-engine-lab-end-to-end.html',
        'The engine facade end to end — F5.09.1 · jonnify',
        "The full supervision tree: Portal.Application starts the configured store adapter and the engine; the engine's init reads the whole stream through the port and replays it into state; a command decides, appends events through the port, and evolves, so a crash and restart replays the log back to the same state.",
    ),
    'f5-09-3': (
        'content/f5-09-3-handoff.html',
        'pragmatic-engine-lab-handoff.html',
        'What ships in F6 — F5.09.3 · jonnify',
        "The handoff: F6 replaces the thin web layer with Phoenix and adds its endpoint to the same supervision tree, but the Portal facade is called unchanged, the closed %Portal.Error{} contract is the render surface, the engine and store are untouched, and the F5.07 tests carry over. The chapter's definition of done, closed.",
    ),
    'f5-09-2': (
        'content/f5-09-2-mount.html',
        'pragmatic-engine-lab-mount.html',
        'A LiveView mount sketch — F5.09.2 · jonnify',
        'A LiveView that touches only the facade: mount/3 loads state with a query, handle_event/3 issues a command and branches on the closed error contract, and render/1 draws from assigns. The event loop — click, command, re-assign, re-render — never reaches past Portal and %Portal.Error{}.',
    ),
    'f5-fm-flow': (
        'content/f5-00-flow.html',
        'pragmatic-flow.html',
        'The command & event flow — F5.0.3 · jonnify',
        'How one use case moves through the engine: a command is checked against a contract, emits a domain event, the event transitions state, and a query reads a projection. The write path and the read path are kept separate, so the engine the UI calls has a predictable surface — the flow F5.04, F5.05, and F5.06 build.',
    ),
    'f5-01': (
        'content/f5-01-foundations.html',
        'pragmatic-foundations.html',
        'Start thin: a running Portal from day one — F5.01 · jonnify',
        'Pragmatic programming starts with a system that runs. F5.01 stands the Portal up behind a minimal Elixir web server from the first day, places that move on a course-wide roadmap — HTML templating, a simple web server, Portal logic, Phoenix, then Fly production — and keeps the web layer thin enough that Phoenix replaces it in F6 without touching the engine. Three dives on the roadmap, the thin server, and the replaceable seam.',
    ),
    'f5-01-3': (
        'content/f5-01-3-replaceable.html',
        'pragmatic-foundations-replaceable.html',
        'A web layer built for replacement — F5.01.3 · jonnify',
        'The thin server is a detail, by design. Because every route only calls Portal.Engine.dispatch/1 and query/2, the same calls move unchanged into a Phoenix controller or a LiveView handle_event in F6 — the web layer is swapped, the engine is not. Orthogonality and ETC, made concrete.',
    ),
    'f5-01-1': (
        'content/f5-01-1-roadmap.html',
        'pragmatic-foundations-roadmap.html',
        'The development roadmap — F5.01.1 · jonnify',
        'The whole course is one development roadmap: HTML templating, then a simple web server, then the Portal logic behind it, then Phoenix in F6, then Fly in production. You start thin and grow it so the system runs from day one — a tracer bullet — instead of disappearing into months of build with nothing to show.',
    ),
    'f5-01-2': (
        'content/f5-01-2-thin-server.html',
        'pragmatic-foundations-thin-server.html',
        'A thin web server in Elixir — F5.01.2 · jonnify',
        'A minimal HTTP front end for the Portal: a Plug.Router matched and dispatched by Bandit, where each route does one thing — turn the request into a command or a query, call Portal.Engine, and send the result. No framework, a handful of lines, and a running server you can curl today.',
    ),
    'f5-06': (
        'content/f5-06-state.html',
        'pragmatic-state.html',
        'Where engine state lives — F5.06 · jonnify',
        'The F5.05 fold is pure: it computes the current state from the event log and forgets it. At runtime the Portal must keep that state alive between requests, and on the BEAM live state lives in a process. F5.06 picks the process that owns the folded state — a GenServer, an Agent, or ETS — builds it around decide and evolve, and puts a supervisor around it. Three dives on choosing the holder, the engine GenServer, and supervision.',
    ),
    'f5-06-1': (
        'content/f5-06-1-choosing.html',
        'pragmatic-state-choosing.html',
        'Choosing where state lives — F5.06.1 · jonnify',
        'Three holders for live state on the BEAM are not interchangeable: a GenServer is a process that holds state and runs logic, an Agent holds a value with get and update, and ETS is a shared table with concurrent reads. The engine runs a contract and a fold on every command, so it needs the GenServer.',
    ),
    'f5-06-2': (
        'content/f5-06-2-genserver.html',
        'pragmatic-state-genserver.html',
        'The engine GenServer — F5.06.2 · jonnify',
        'Three callbacks carry the engine. init folds the event log into the starting state; a command handle_call runs decide and evolve and keeps the new state; a query handle_call reads and replies, unchanged. The command/query split becomes two clauses, and one mailbox serializes writes for free.',
    ),
    'f5-06-3': (
        'content/f5-06-3-supervision.html',
        'pragmatic-state-supervision.html',
        'Supervision — F5.06.3 · jonnify',
        'Let it crash: a process holding state will eventually fail, so a supervisor sits above the engine and restarts it. On restart init folds the event log again and the state returns — deterministic replay is why a crash loses nothing. One_for_one restarts only the failed child.',
    ),
    'f5-07': (
        'content/f5-07-testing.html',
        'pragmatic-testing.html',
        'Pragmatic testing — F5.07 · jonnify',
        'The engine was built to be tested: decide and evolve are pure and state is a fold, so most of it is checked with plain example tests — no processes, no mocks. Above those sit property-based tests that state an invariant and let StreamData generate the cases, and contract tests that run the F5.04 contract with doctests keeping the docs honest. Three dives on the pure core, property-based testing, and contract tests.',
    ),
    'f5-07-3': (
        'content/f5-07-3-contract-tests.html',
        'pragmatic-testing-contract-tests.html',
        'Contract tests — F5.07.3 · jonnify',
        'The F5.04 contract written as tests: a precondition test feeds a bad command and asserts {:error, reason} with no state change, a postcondition test asserts the guarantee, an invariant test checks the rule on the result, and doctest runs the @doc examples so the documentation cannot drift from the code.',
    ),
    'f5-07-2': (
        'content/f5-07-2-property.html',
        'pragmatic-testing-property.html',
        'Property-based testing — F5.07.2 · jonnify',
        "State a property true for every valid input and let StreamData generate hundreds of cases, shrinking any failure to the smallest counterexample. The engine's properties: replay is deterministic, the progress invariant survives any command sequence, and decide is total — it returns a tagged result, never raises.",
    ),
    'f5-07-1': (
        'content/f5-07-1-pure-core.html',
        'pragmatic-testing-pure-core.html',
        'Testing the pure core — F5.07.1 · jonnify',
        'decide, evolve, and replay are pure functions, so a test is three lines: arrange a state, call the function, assert the output — no process to start, no database to seed, no mocks. This is the payoff of pushing the logic out of the GenServer and into functions: the bulk of the engine is tested without the machinery.',
    ),
    'f5-03': (
        'content/f5-03-tracer-bullets.html',
        'pragmatic-tracer-bullets.html',
        'Tracer bullets: a walking skeleton — F5.03 · jonnify',
        'With a running server and a domain model in hand, F5.03 wires them together by driving one use case — enroll a learner — through every layer at once: route, context API, struct, store, and back. That thin end-to-end slice is the walking skeleton, real production code rather than a throwaway prototype, and once it runs the system grows by iterating the slice. Three dives on tracer bullets, the skeleton, and iteration.',
    ),
    'f5-03-3': (
        'content/f5-03-3-iterating.html',
        'pragmatic-tracer-bullets-iterating.html',
        'Iterating the slice — F5.03.3 · jonnify',
        'Once the skeleton walks, you grow it one thin vertical slice at a time: deliver the first lesson, then record progress, each slice touching route, context, struct, and store, each leaving the system running and demoable. Vertical slices keep the whole thing alive where horizontal layers would not.',
    ),
    'f5-03-1': (
        'content/f5-03-1-prototypes.html',
        'pragmatic-tracer-bullets-prototypes.html',
        'Tracer bullets vs prototypes — F5.03.1 · jonnify',
        'Both are built fast, but their fates are opposite. A tracer bullet is thin but real code that round-trips the whole system and is kept and built upon; a prototype is throwaway code written to answer one question, then discarded. Knowing which you are writing keeps you from shipping a prototype or polishing a tracer bullet.',
    ),
    'f5-03-2': (
        'content/f5-03-2-skeleton.html',
        'pragmatic-tracer-bullets-skeleton.html',
        'The walking skeleton — F5.03.2 · jonnify',
        'The enroll-a-learner slice, end to end: a POST /enroll route calls Learning.enroll/2, which builds an %Enrollment{} and puts it in the store, and the handler answers 201. Every layer is present and every layer is minimal — a skeleton that walks, the frame every later feature drops into.',
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
    # Every linkable route the manifest knows: ROOT, chapters, modules, module
    # deep-dives, and chapter front-matter — one bare route per line. With every
    # chapter/module/subpage live this is exactly the on-disk elixir/ route tree.
    for route in sorted(allowed_routes()):
        print(route)
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
