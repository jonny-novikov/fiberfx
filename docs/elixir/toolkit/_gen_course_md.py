#!/usr/bin/env python3
"""Generate a Writerside-friendly course-content Markdown file from the live manifest."""
import build_page as bp

ROOT = bp.ROOT_ROUTE  # /elixir

# ---- chapter abstracts ----
CH = {
 "F0": "An optional prologue in two essays. Where functional languages came from, and where the BEAM and OTP came from \u2014 the history that explains why Elixir looks and behaves the way it does.",
 "F1": "The mathematical foundation. Nine modules treat functions, composition, recursion, higher-order operators, and pattern matching as pure mathematics, ending in a plotting lab. Every idea introduced here is later carried across to Elixir in F2 \u2014 the recurring *bridge* between an idea and its code.",
 "F2": "The same foundations as working Elixir. Each module pairs a concept with its Elixir form \u2014 purity, persistent data, higher-order functions, recursion, folds, closures, algebraic data types, and composition \u2014 and the later modules expand into hubs, each with several deep-dive subpages. The chapter closes with the data-pipeline lab.",
 "F3": "The Elixir language proper: values and IEx, the match operator, modules and the pipe, enumerables and streams, structs and protocols, processes and the actor model, and OTP \u2014 ending in a live process playground.",
 "F4": "Functional algorithmics. From lists, trees, sorting, and hashing up through the persistent-map family \u2014 HAMT, CHAMP, and the Branded Champ map whose namespaced keys serve as cross-system pivots \u2014 closing with an animated trie-growth lab.",
 "F5": "The engineering craft: Mix, ExUnit and doctests, typespecs and Dialyzer, \u201clet it crash\u201d, Tasks and concurrency, telemetry, releases, and performance \u2014 ending in a self-healing supervision-tree lab.",
 "F6": "Building for the web with Phoenix: the request lifecycle, routing and plugs, Ecto, contexts, HEEx, LiveView, PubSub, and deployment \u2014 ending in a real-time live dashboard.",
}

# ---- module abstracts (by n) ----
A = {
 "F0.1": "Traces the lineage from the \u03bb-calculus through LISP, ML, and Haskell to the immutable turn that shaped today's functional languages \u2014 the intellectual backdrop for everything that follows.",
 "F0.2": "Follows Erlang from its telecom origins to the BEAM's soft-real-time scheduling and OTP's supervision model \u2014 the runtime Elixir is built on.",
 "F1.01": "A function as a mapping with a domain and a range that returns exactly one output for each input, leading to treating functions as first-class values.",
 "F1.02": "Evaluation as replacing equals for equals; the model that gives referential transparency and a precise meaning to purity.",
 "F1.03": "Chaining mappings so the output of one feeds the next, and the associativity that lets a chain regroup freely \u2014 the algebra under the pipe.",
 "F1.04": "A symbol names a fixed value rather than a mutable cell; the foundation of immutable data and equational reasoning.",
 "F1.05": "Applying one function across every element of a collection \u2014 the mathematical seed of lists, maps, and Enum.map.",
 "F1.06": "A base case and a step, paired with the induction that proves it terminates; recursion takes the place of loops.",
 "F1.07": "Operators such as \u03a3 and \u03a0 that take a function as input, generalising into map, filter, and reduce.",
 "F1.08": "Identities and solving by structure \u2014 the mathematical root of pattern matching.",
 "F1.09": "An interactive lab to plot single functions and their compositions, watching f\u2218g take shape as a curve.",
 "F2.01": "What purity buys \u2014 testability, reasoning, and safe concurrency \u2014 and how to keep side effects at the edges of a program.",
 "F2.02": "Persistent data structures and structural sharing, which make an immutable update cheap rather than a full copy.",
 "F2.03": "Treating functions as ordinary values: passing them as arguments and returning them from other functions.",
 "F2.04": "Recursion as the functional loop. A hub with three dives: the shape of a recursive definition, rewriting with an accumulator for tail-call optimisation, and the common patterns that turn out to be folds.",
 "F2.05": "reduce as the universal fold from which map and filter follow. A hub with four dives: map, filter, reduce, and advanced folds such as scan and group_by.",
 "F2.06": "Functions that capture their surrounding environment. A hub with three dives: what a closure captures and when, the & capture operator, and partial application and currying by hand.",
 "F2.07": "Building data from products (this and that) and sums (this or that). A hub with three dives: product types, sum types, and pattern matching on data.",
 "F2.08": "Joining functions into larger ones. A hub with three dives: function composition, the pipe operator, and building pipelines of map, filter, and reduce.",
 "F2.09": "The F2 capstone: compose a full pipeline over a real dataset and watch the value transform at each stage.",
 "F3.01": "The values Elixir programs are built from, and the IEx shell as the primary tool for exploring them.",
 "F3.02": "The match operator: = binds by matching structure rather than assigning, the idea that runs through the whole language.",
 "F3.03": "Defining functions inside modules and composing them with the pipe.",
 "F3.04": "Traversing collections eagerly with Enum and lazily with Stream, and when each is appropriate.",
 "F3.05": "Shaping data with structs, maps, and keyword lists, and choosing between them.",
 "F3.06": "Polymorphism through protocols and contracts through behaviours.",
 "F3.07": "Lightweight isolated processes communicating by messages \u2014 spawn, send, and receive \u2014 the actor model on the BEAM.",
 "F3.08": "OTP's GenServer for stateful servers and supervisors for fault tolerance.",
 "F3.09": "An interactive playground: spawn processes, send messages, and watch the mailbox and process tree live.",
 "F4.01": "Cons-cell lists, recursion over them, and big-O complexity as it actually behaves on the BEAM.",
 "F4.02": "Binary and n-ary trees with depth-first and breadth-first traversals written functionally.",
 "F4.03": "Merge sort, quicksort, and binary search expressed over immutable data.",
 "F4.04": "Hash maps, collisions, and the cost model behind maps and sets.",
 "F4.05": "Hash Array Mapped Tries: persistent maps built on prefix trees.",
 "F4.06": "CHAMP \u2014 Compressed Hash-Array Mapped Prefix-trees \u2014 their node layout and iteration.",
 "F4.07": "Branded Champ maps: namespaced, base62-encoded keys used as cross-system pivots, e.g. TSK0KHTOWnGLuC.",
 "F4.08": "Dynamic programming and memoisation, with harder algorithmic challenges.",
 "F4.09": "An interactive lab that inserts keys and animates a CHAMP / branded trie as it grows.",
 "F5.01": "Project structure with Mix: applications, dependencies, and tasks.",
 "F5.02": "Fast, deterministic testing with ExUnit and doctests.",
 "F5.03": "Documentation with @doc and contracts with @spec, checked by Dialyzer.",
 "F5.04": "Error handling the BEAM way: tagged tuples versus exceptions, and \u201clet it crash\u201d under supervision.",
 "F5.05": "Concurrency patterns with Task, async/await, and back-pressure.",
 "F5.06": "Telemetry, logging, and observability \u2014 seeing inside a running system.",
 "F5.07": "Dependencies, mix release, and configuration for deployment.",
 "F5.08": "Benchmarking, the scheduler, and finding hot paths.",
 "F5.09": "An interactive lab: crash a worker and watch the supervisor restart it.",
 "F6.01": "Phoenix architecture and the request lifecycle: endpoint, router, controller, view.",
 "F6.02": "Routing, controllers, and the plug pipeline.",
 "F6.03": "Ecto schemas, changesets, and queries \u2014 data, validation, and the repo.",
 "F6.04": "Contexts and domain design: boundaries that scale.",
 "F6.05": "Server-rendered markup with templates, components, and HEEx.",
 "F6.06": "Phoenix LiveView fundamentals \u2014 interactive UIs without hand-written JavaScript.",
 "F6.07": "PubSub, channels, and real-time updates over WebSockets.",
 "F6.08": "Sessions and authentication, releases, and going to production.",
 "F6.09": "An interactive lab: real-time LiveView state over a socket, with multiple clients via PubSub.",
}

def marks(m, mid):
    out = ["\u25cf" if m["status"] in ("built", "live") else "\u25cb"]
    if mid in bp.SUBPAGES:
        out.append("\u2b21 hub")
    if m.get("lab"):
        out.append("\u25a3 lab")
    return " ".join(out)

def esc(s):
    # escape pipe so it does not split a GFM table cell
    return s.replace("|", "\\|")

def chapter_table(ch):
    rows = ["| Module | Abstract | Route | Status |", "|---|---|---|---|"]
    croute = ch["route"]
    for m in bp.MODULES[ch["id"]]:
        mid = m["n"]
        route = croute + "/" + m["slug"]
        rows.append(f"| **{esc(mid)} \u00b7 {esc(m['title'])}** | {esc(A.get(mid, m['one']))} | `{route}` | {marks(m, mid)} |")
        for s in bp.SUBPAGES.get(mid, []):
            sroute = route + "/" + s["slug"]
            rows.append(f"| \u21b3 {esc(mid)} &middot; {esc(s['title'])} | {esc(s['one'])} | `{sroute}` | \u25cf |")
    return "\n".join(rows)

parts = []
W = parts.append

W("# Functional Programming in Elixir")
W("")
W("A course that teaches functional programming twice: first as mathematics, then as Elixir. "
  "It runs from the \u03bb-calculus and the BEAM's history, through the algebra of functions, into "
  "idiomatic Elixir, data structures, engineering practice, and the Phoenix web framework. Six chapters "
  "of nine modules each \u2014 fifty-four modules \u2014 plus an optional two-part history chapter. Every lesson "
  "carries an interactive, build-it-yourself component, and every module of mathematics is paired with its "
  "Elixir counterpart \u2014 the recurring *bridge* from an idea to its code.")
W("")
W("> This document is the syllabus and navigation map. Each chapter below lists its modules with a short "
  "abstract and its route; the Mermaid graphs show how the pages link and the order they are read in.")
W("")

# ---- at a glance ----
W("## At a glance")
W("")
W("| | |")
W("|---|---|")
W("| **Chapters** | 7 \u2014 an optional History prologue (F0) and six core chapters (F1\u2013F6) |")
W("| **Modules** | 54 numbered modules (F1\u2013F6), plus 2 History essays |")
W("| **Deep-dive subpages** | 16, across the five F2 hub modules |")
W("| **Live now** | F0, F1, and F2 |")
W("| **Built** | all of F1 (9), F2.01\u2013F2.08 (8), the 16 F2 subpages, and both History essays |")
W("| **Design** | the *jonnify* dark-editorial system; each page has interactive SVG + vanilla-JS components |")
W("| **Quality bar** | every page ships at Apollo **A+** across nine gates |")
W("")
W("**Legend** &mdash; \u25cf built &middot; \u25cb planned &middot; \u2b21 hub (an overview page with deep-dive subpages) "
  "&middot; \u25a3 lab (an interactive capstone) &middot; \u21b3 a subpage of the module above it.")
W("")

# ---- course map graph ----
W("## Course map")
W("")
W("The spine of the course. Solid edges branch from the root to each chapter; the dashed edge is the "
  "intended reading order.")
W("")
W("```mermaid")
W("""graph LR
  ROOT(["/elixir"])
  F0["F0 · History"]
  F1["F1 · Algebra"]
  F2["F2 · Functional"]
  F3["F3 · Language"]
  F4["F4 · Algorithms"]
  F5["F5 · Pragmatic"]
  F6["F6 · Phoenix"]
  ROOT --> F0
  ROOT --> F1
  ROOT --> F2
  ROOT --> F3
  ROOT --> F4
  ROOT --> F5
  ROOT --> F6
  F0 -.-> F1 -.-> F2 -.-> F3 -.-> F4 -.-> F5 -.-> F6
  classDef live fill:#16241a,stroke:#7ba387,color:#ece4d0;
  classDef plan fill:#161d38,stroke:#2a3252,color:#a39c89;
  classDef root fill:#1a1530,stroke:#b39ddb,color:#ece4d0;
  class ROOT root;
  class F0,F1,F2 live;
  class F3,F4,F5,F6 plan;""")
W("```")
W("")
W("Each chapter lives at a route under `/elixir`, every module at `\u2039chapter\u203a/\u2039module\u203a`, and every "
  "deep-dive subpage at `\u2039chapter\u203a/\u2039module\u203a/\u2039subpage\u203a`. Within a chapter the modules read in "
  "order, F.01 through F.09, the last being an interactive lab.")
W("")

# ---- F0 ----
c0 = next(c for c in bp.CHAPTERS if c["id"] == "F0")
W(f"## F0 &middot; History &mdash; `{c0['route']}`")
W("")
W(CH["F0"])
W("")
W(chapter_table(c0))
W("")

# ---- F1 ----
c1 = next(c for c in bp.CHAPTERS if c["id"] == "F1")
W(f"## F1 &middot; Algebra &mdash; `{c1['route']}`")
W("")
W(CH["F1"])
W("")
W(chapter_table(c1))
W("")
W("### F1 navigation")
W("")
W("A single linear sequence ending in the plotting lab. The pager links each module to the next and back.")
W("")
W("```mermaid")
W("""graph LR
  A1["F1.01 · functions"] --> A2["F1.02 · substitution"] --> A3["F1.03 · composition"]
  A3 --> A4["F1.04 · immutability"] --> A5["F1.05 · collections"] --> A6["F1.06 · recursion"]
  A6 --> A7["F1.07 · higher-order"] --> A8["F1.08 · pattern-matching"] --> A9["F1.09 · plotting-lab ▣"]
  classDef live fill:#241f12,stroke:#d4a85a,color:#ece4d0;
  classDef lab fill:#1a1530,stroke:#b39ddb,color:#ece4d0;
  class A1,A2,A3,A4,A5,A6,A7,A8 live;
  class A9 lab;""")
W("```")
W("")

# ---- F2 ----
c2 = next(c for c in bp.CHAPTERS if c["id"] == "F2")
W(f"## F2 &middot; Functional Programming &mdash; `{c2['route']}`")
W("")
W(CH["F2"])
W("")
W(chapter_table(c2))
W("")
W("### F2 navigation")
W("")
W("The reading path threads through the subpages: a hub links forward to its first dive, the dives chain "
  "in order, and the last dive links on to the next module. Each hub also links directly to all of its "
  "dives via on-page cards. The pager is bidirectional, so a hub's back-link reaches the previous module's "
  "last dive.")
W("")
W("```mermaid")
W("""graph TD
  B1["F2.01 · pure"] --> B2["F2.02 · persistence"] --> B3["F2.03 · higher-order"] --> H4

  H4["F2.04 · recursion ⬡"]
  H4 --> C1["F2.04.1 · shape"] --> C2["F2.04.2 · tail-calls"] --> C3["F2.04.3 · patterns"] --> H5

  H5["F2.05 · folds ⬡"]
  H5 --> D1["F2.05.1 · map"] --> D2["F2.05.2 · filter"] --> D3["F2.05.3 · reduce"] --> D4["F2.05.4 · advanced"] --> H6

  H6["F2.06 · closures ⬡"]
  H6 --> E1["F2.06.1 · environment"] --> E2["F2.06.2 · capture"] --> E3["F2.06.3 · currying"] --> H7

  H7["F2.07 · adt ⬡"]
  H7 --> F1n["F2.07.1 · product"] --> F2n["F2.07.2 · sum"] --> F3n["F2.07.3 · matching"] --> H8

  H8["F2.08 · composition ⬡"]
  H8 --> G1["F2.08.1 · compose"] --> G2["F2.08.2 · pipe"] --> G3["F2.08.3 · pipeline"] --> B9

  B9["F2.09 · pipeline-lab ▣"]

  classDef live fill:#1a1530,stroke:#b39ddb,color:#ece4d0;
  classDef hub fill:#16241a,stroke:#7ba387,color:#ece4d0;
  classDef dive fill:#161d38,stroke:#3a4366,color:#d7cfb9;
  classDef plan fill:#161d38,stroke:#2a3252,color:#a39c89;
  class B1,B2,B3 live;
  class H4,H5,H6,H7,H8 hub;
  class C1,C2,C3,D1,D2,D3,D4,E1,E2,E3,F1n,F2n,F3n,G1,G2,G3 dive;
  class B9 plan;""")
W("```")
W("")

# ---- F3-F6 ----
W("## The road ahead &mdash; F3 to F6")
W("")
W("The four remaining chapters are planned. Each follows the same shape as F1 and F2: nine modules read "
  "in order, the ninth an interactive lab. The hub-and-subpages treatment seen in F2 will extend into them "
  "where a topic earns the depth.")
W("")
W("```mermaid")
W("""graph LR
  P1["F·01"] --> P2["F·02"] --> P3["F·03"] --> P4["F·04"] --> P5["F·05"]
  P5 --> P6["F·06"] --> P7["F·07"] --> P8["F·08"] --> P9["F·09 ▣ lab"]
  classDef plan fill:#161d38,stroke:#2a3252,color:#a39c89;
  classDef lab fill:#161d38,stroke:#4a5470,color:#cfc7b3;
  class P1,P2,P3,P4,P5,P6,P7,P8 plan;
  class P9 lab;""")
W("```")
W("")
for cid in ("F3", "F4", "F5", "F6"):
    c = next(c for c in bp.CHAPTERS if c["id"] == cid)
    W(f"### {cid} &middot; {c['title']} &mdash; `{c['route']}`")
    W("")
    W(CH[cid])
    W("")
    W(chapter_table(c))
    W("")

# ---- branded snowflake ----
W("## The branded Snowflake build stamp")
W("")
W("Every page carries a build stamp in its footer: a fourteen-character branded id that decodes, on the "
  "page itself, to a millisecond timestamp. It is a three-character namespace followed by a base62 encoding "
  "of a 64-bit Snowflake, and the same id convention is used as a cross-system pivot key throughout the "
  "course \u2014 and is the subject of module F4.07.")
W("")
W("| Field | Value |")
W("|---|---|")
W("| Branded id | `TSK0KHTOWnGLuC` |")
W("| Namespace | `TSK` |")
W("| Snowflake | `274557032793636864` |")
W("| Timestamp | `2026-01-27 15:11:37 UTC` |")
W("")
W("The 64-bit layout is `timestamp(41) << 22 | node(10) << 12 | sequence(12)`, measured from a custom epoch "
  "of `2024-01-01 00:00:00 UTC` (1704067200000 ms). The base62 alphabet is `0-9 A-Z a-z`, left-padded to "
  "eleven characters, so namespace plus encoding is always fourteen.")
W("")

# ---- how each page is built ----
W("## How each page is built")
W("")
W("Every lesson is a static page in the *jonnify* dark-editorial design system \u2014 Cormorant Garamond and "
  "PT Serif for prose, Manrope for labels, JetBrains Mono for code, over an ink-and-cream palette with gold, "
  "blue, sage, burgundy, and an elixir-purple accent. Beyond the writing, each page is held to a fixed set "
  "of rules:")
W("")
W("- **Interactive components.** Every lesson carries at least one hand-built SVG-and-vanilla-JS component "
  "that computes the real result, shows a live readout and a one-sentence takeaway, works without "
  "JavaScript, and respects reduced-motion. No external libraries, no browser storage.")
W("- **The bridge.** Each mathematical idea is paired with its Elixir counterpart, so the algebra of F1 and "
  "the code of F2 read as two views of one thing.")
W("- **Apollo A+ gates.** A page ships only when it passes all nine checks: required containers, well-formed "
  "SVG, no future-dated claims, an editorial voice gate, no browser storage, reduced-motion support, "
  "graceful degradation without JavaScript, valid internal links, and a working pager.")
W("- **Hubs and subpages.** Deeper modules are an overview hub plus several deep-dive subpages, linked by "
  "the pager and by on-page cards, as the F2 graph above shows.")
W("")
W("---")
W("")
W("*Generated from the course manifest. Routes, titles, and statuses are authoritative; abstracts summarise "
  "each module's scope.*")
W("")

doc = "\n".join(parts)
out = "/home/claude/elixir-course/functional-programming-in-elixir.md"
open(out, "w").write(doc)
print("wrote", out, "—", len(doc), "chars,", doc.count("\n") + 1, "lines")

# voice gate (same discipline as the pages)
import re
FORBIDDEN = ["revolutionary", "blazing-fast", "blazing fast", "magical", "simply", "obviously", "effortless"]
low = doc.lower()
hits = [w for w in FORBIDDEN if w in low]
# 'just' as a whole word
if re.search(r"\bjust\b", low):
    hits.append("just")
print("voice gate:", "CLEAN" if not hits else "HITS -> " + ", ".join(hits))
# mermaid block count
print("mermaid blocks:", doc.count("```mermaid"))
