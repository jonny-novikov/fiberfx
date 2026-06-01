// Package manifest is the in-code course manifest: the declared structure of
// the "Functional Programming in Elixir" course (chapters, modules, deep-dive
// subpages, statuses, routes). It is a faithful port of the manifest in
// docs/elixir/kb/build_page.py. Statuses are kept exactly as the Python declares
// them so that downstream reconciliation against the filesystem can detect drift
// (a module declared "planned" whose page already exists and passes the gates).
package manifest

import "fmt"

// RootRoute is the section mount point.
const RootRoute = "/elixir"

// Linkable reports whether a status renders as a link (versus a non-linking card).
func Linkable(status string) bool { return status == "live" || status == "built" }

// Dive is an inline F0 sub-lesson (rendered as a static list item, never a link).
type Dive struct {
	N      string `json:"n"`
	Title  string `json:"title"`
	Slug   string `json:"slug"`
	Status string `json:"status"`
}

// Module is one numbered lesson within a chapter.
type Module struct {
	N      string `json:"n"`
	Title  string `json:"title"`
	One    string `json:"one"`
	Slug   string `json:"slug"`
	Status string `json:"status"`
	Lab    bool   `json:"lab"`
	Dives  []Dive `json:"dives,omitempty"`
}

// Chapter is a top-level division of the course.
type Chapter struct {
	ID     string `json:"id"`
	Title  string `json:"title"`
	Slug   string `json:"slug"`
	Route  string `json:"route"`
	Status string `json:"status"`
	One    string `json:"one"`
	Reuses string `json:"reuses"`
	Accent string `json:"accent"`
}

// Subpage is a deep-dive page beneath a hub module.
type Subpage struct {
	Slug  string `json:"slug"`
	Title string `json:"title"`
	One   string `json:"one"`
}

// Chapters is the ordered chapter spine (F0 prologue, then the F1-F6 spine).
var Chapters = []Chapter{
	{"F0", "History", "course", "/elixir/course", "live", "Where this came from — the languages, the runtimes, and the BEAM.", "Context, not a prerequisite. F1 stands on its own.", "blue"},
	{"F1", "Algebra", "algebra", "/elixir/algebra", "live", "The functional mindset, straight from the math you already know.", "Starts from the algebra you already know.", "gold"},
	{"F2", "Functional Programming", "functional", "/elixir/functional", "live", "Pure functions, immutability, and higher-order functions on their own terms.", "Builds on F1 · Algebra.", "elixir"},
	{"F3", "The Elixir Language", "language", "/elixir/language", "live", "Syntax, pipelines, pattern matching, and structs on the BEAM.", "Builds on F2 · Functional Programming.", "elixir"},
	{"F4", "Algorithms & Data Structures", "algorithms", "/elixir/algorithms", "live", "Classical and advanced problems, from lists to branded CHAMP tries.", "Builds on F3 · The Elixir Language.", "sage"},
	{"F5", "Pragmatic Programming", "pragmatic", "/elixir/pragmatic", "live", "Real-world engineering: structure, testing, telemetry, releases.", "Builds on F4 · Algorithms & Data Structures.", "sage"},
	{"F6", "Phoenix Framework", "phoenix", "/elixir/phoenix", "planned", "Web applications on Elixir, and the road into real-time LiveView.", "Builds on F5 · Pragmatic Programming.", "blue"},
}

// Modules maps a chapter id to its ordered modules. Statuses are verbatim from
// build_page.py: F2.06-F2.09 remain "planned" even though their pages now exist
// on disk — that gap is the canonical drift the readiness command surfaces.
var Modules = map[string][]Module{
	"F0": {
		{N: "F0.1", Title: "The evolution of functional languages & runtimes", One: "λ-calculus → LISP → ML/Haskell → the immutable turn.", Slug: "fp-evolution", Status: "built", Dives: []Dive{
			{"F0.1.1", "From λ-calculus to LISP", "lisp-origins", "soon"},
			{"F0.1.2", "Types & laziness — the ML and Haskell branch", "ml-haskell", "soon"},
			{"F0.1.3", "The immutable turn — persistent data on the JVM & CLR", "immutable-turn", "soon"},
		}},
		{N: "F0.2", Title: "The evolution of Erlang, the BEAM & OTP", One: "Telecom roots, soft-real-time scheduling, and supervision.", Slug: "beam-evolution", Status: "built", Dives: []Dive{
			{"F0.2.1", "Telecom roots & \"let it crash\"", "telecom-roots", "soon"},
			{"F0.2.2", "Inside the BEAM — scheduling, heaps & soft-real-time GC", "inside-beam", "soon"},
			{"F0.2.3", "OTP & the supervision tree — and the polyglot BEAM", "otp-supervision", "soon"},
		}},
	},
	"F1": {
		{N: "F1.01", Title: "What a function really is", One: "Mapping, domain & range → first-class functions.", Slug: "functions", Status: "built"},
		{N: "F1.02", Title: "The substitution model", One: "Equals for equals → referential transparency.", Slug: "substitution", Status: "built"},
		{N: "F1.03", Title: "Composition, f∘g", One: "Chaining mappings → the pipe.", Slug: "composition", Status: "built"},
		{N: "F1.04", Title: "Immutability & binding", One: "A symbol names a fixed value → immutable data.", Slug: "immutability", Status: "built"},
		{N: "F1.05", Title: "Sets, sequences & mappings", One: "Applying f across a collection → Enum.map.", Slug: "collections", Status: "built"},
		{N: "F1.06", Title: "Recursion & induction", One: "Base case + step → recursion, no loops.", Slug: "recursion", Status: "built"},
		{N: "F1.07", Title: "Higher-order operators (Σ, Π)", One: "Operators over functions → map/filter/reduce.", Slug: "higher-order", Status: "built"},
		{N: "F1.08", Title: "Equations & pattern matching", One: "Solving by structure → pattern matching.", Slug: "pattern-matching", Status: "built"},
		{N: "F1.09", Title: "Functions on the plane — a plotting lab", One: "Plot and compose functions; watch f∘g as curves.", Slug: "plotting-lab", Status: "built", Lab: true},
	},
	"F2": {
		{N: "F2.01", Title: "Pure functions & side effects", One: "What purity buys; isolating effects.", Slug: "pure", Status: "built"},
		{N: "F2.02", Title: "Immutability & persistent data", One: "Structural sharing; cheap updates.", Slug: "persistence", Status: "built"},
		{N: "F2.03", Title: "Higher-order functions", One: "Functions as arguments and return values.", Slug: "higher-order", Status: "built"},
		{N: "F2.04", Title: "Recursion patterns & tail calls", One: "Accumulators and tail-call optimisation.", Slug: "recursion", Status: "built"},
		{N: "F2.05", Title: "map / filter / reduce (folds)", One: "reduce as the universal fold.", Slug: "folds", Status: "built"},
		{N: "F2.06", Title: "Closures & partial application", One: "Capturing environment; & and currying.", Slug: "closures", Status: "built"},
		{N: "F2.07", Title: "Algebraic data types", One: "Sum and product types; tagged tuples.", Slug: "adt", Status: "built"},
		{N: "F2.08", Title: "Composition & pipelines", One: "Building programs by composing functions.", Slug: "composition", Status: "built"},
		{N: "F2.09", Title: "The data-pipeline lab", One: "Compose map/filter/reduce over a dataset.", Slug: "pipeline-lab", Status: "built", Lab: true},
	},
	"F3": {
		{N: "F3.01", Title: "Values, types & IEx", One: "The data you build with; the shell.", Slug: "values", Status: "built"},
		{N: "F3.02", Title: "Pattern matching & the match operator", One: "= is a match, not assignment.", Slug: "match", Status: "built"},
		{N: "F3.03", Title: "Functions, modules & the pipe", One: "Defining and composing in modules.", Slug: "modules", Status: "built"},
		{N: "F3.04", Title: "Enumerables & streams", One: "Eager versus lazy traversal.", Slug: "enum-streams", Status: "built"},
		{N: "F3.05", Title: "Structs, maps & keyword lists", One: "Shaping data; when to use which.", Slug: "structs", Status: "built"},
		{N: "F3.06", Title: "Protocols & behaviours", One: "Polymorphism and contracts.", Slug: "protocols", Status: "built"},
		{N: "F3.07", Title: "Processes & the actor model", One: "spawn, send, receive; isolation.", Slug: "processes", Status: "built"},
		{N: "F3.08", Title: "OTP: GenServer & supervisors", One: "Stateful servers and fault tolerance.", Slug: "otp", Status: "built"},
		{N: "F3.09", Title: "The process playground", One: "Spawn processes; watch the mailbox live.", Slug: "playground", Status: "built", Lab: true},
	},
	"F4": {
		{N: "F4.01", Title: "Lists, recursion & complexity", One: "Cons cells; big-O on the BEAM.", Slug: "lists", Status: "built"},
		{N: "F4.02", Title: "Trees & traversals", One: "Binary/n-ary trees; DFS/BFS functionally.", Slug: "trees", Status: "built"},
		{N: "F4.03", Title: "Sorting & searching", One: "Merge/quick sort, binary search, immutably.", Slug: "sorting", Status: "built"},
		{N: "F4.04", Title: "Maps, sets & hashing", One: "Hash maps, collisions, the cost model.", Slug: "maps", Status: "built"},
		{N: "F4.05", Title: "Hash Array Mapped Tries (HAMT)", One: "Persistent maps via prefix trees.", Slug: "hamt", Status: "built"},
		{N: "F4.06", Title: "CHAMP maps", One: "Compressed HAMT trees; layout & iteration.", Slug: "champ", Status: "built"},
		{N: "F4.07", Title: "Identifiers, Snowflake & branded ids", One: "From naive ids to a Snowflake bigint and a branded, base62 id.", Slug: "identifiers", Status: "built"},
		{N: "F4.08", Title: "Branded ids & persistence", One: "Branded ids as keys in SQLite, PostgreSQL, and Redis.", Slug: "persistence", Status: "built"},
		{N: "F4.09", Title: "Branded CHAMP maps & GenServer", One: "A CHAMP keyed by branded ids, partitioned by namespace, behind a GenServer.", Slug: "branded-champ", Status: "built"},
		{N: "F4.10", Title: "Practical recipes in Elixir", One: "Turning algorithmic problems into idiomatic Elixir.", Slug: "recipes", Status: "built"},
		{N: "F4.11", Title: "Dynamic programming & advanced problems", One: "Overlapping subproblems, memoized and tabulated.", Slug: "dynamic-programming", Status: "built"},
		{N: "F4.12", Title: "Lab: build a branded CHAMP store", One: "An interactive lab: insert branded keys and watch the partitioned CHAMP restructure.", Slug: "lab", Status: "built", Lab: true},
	},
	"F5": {
		{N: "F5.01", Title: "Foundations", One: "Start thin: a running Portal from day one.", Slug: "foundations", Status: "built"},
		{N: "F5.02", Title: "Modeling the Portal domain", One: "Bounded contexts, structs, and the public API.", Slug: "domain", Status: "built"},
		{N: "F5.03", Title: "Tracer bullets: a walking skeleton", One: "Thin end-to-end first, then iterate.", Slug: "tracer-bullets", Status: "built"},
		{N: "F5.04", Title: "Design by contract", One: "Preconditions, postconditions, and failing fast.", Slug: "contracts", Status: "built"},
		{N: "F5.05", Title: "Commands, queries & events", One: "Separate writes from reads; the engine as a reducer over events.", Slug: "cqrs", Status: "built"},
		{N: "F5.06", Title: "Where engine state lives", One: "One process holds the state; one supervisor keeps it alive.", Slug: "state", Status: "built"},
		{N: "F5.07", Title: "Pragmatic testing", One: "Testing the pure core, property-based tests, and contracts as tests.", Slug: "testing", Status: "built"},
		{N: "F5.08", Title: "Performance & profiling", One: "Benchmarks, the scheduler, hot paths.", Slug: "performance", Status: "planned"},
		{N: "F5.09", Title: "Let it crash — a supervision tree that heals", One: "Crash a worker; watch the restart.", Slug: "supervision-lab", Status: "planned", Lab: true},
	},
	"F6": {
		{N: "F6.01", Title: "Architecture & the request lifecycle", One: "endpoint → router → controller → view.", Slug: "lifecycle", Status: "planned"},
		{N: "F6.02", Title: "Routing, controllers & plugs", One: "The plug pipeline.", Slug: "routing", Status: "planned"},
		{N: "F6.03", Title: "Ecto: schemas, changesets & queries", One: "Data, validation, the repo.", Slug: "ecto", Status: "planned"},
		{N: "F6.04", Title: "Contexts & domain design", One: "Boundaries that scale.", Slug: "contexts", Status: "planned"},
		{N: "F6.05", Title: "Templates, components & HEEx", One: "Server-rendered markup.", Slug: "heex", Status: "planned"},
		{N: "F6.06", Title: "Phoenix LiveView fundamentals", One: "Interactive UIs without hand-written JS.", Slug: "liveview", Status: "planned"},
		{N: "F6.07", Title: "PubSub, channels & real-time", One: "Live updates over WebSockets.", Slug: "pubsub", Status: "planned"},
		{N: "F6.08", Title: "Auth, deployment & going live", One: "Sessions, releases, production.", Slug: "deployment", Status: "planned"},
		{N: "F6.09", Title: "The live dashboard", One: "Real-time LiveView state over a socket.", Slug: "live-dashboard", Status: "planned", Lab: true},
	},
}

// Subpages maps a hub module's F-id to its deep-dive pages. A subpage becomes
// linkable once its parent module is linkable.
var Subpages = map[string][]Subpage{
	"F2.04": {
		{"patterns", "Recursion patterns", "sum, length, reverse, map, filter — and why they are folds."},
		{"shape", "The shape of recursion", "Base case, recursive case, and the growing call stack."},
		{"tail-calls", "Tail calls & accumulators", "Rewrite with an accumulator to run in constant stack space."},
	},
	"F2.05": {
		{"advanced", "Advanced folds", "scan, map_reduce, flat_map, group_by — folds with extra structure."},
		{"filter", "filter", "Keep the elements that pass a predicate."},
		{"map", "map", "Transform every element; the structure is preserved."},
		{"reduce", "reduce", "The general fold; an accumulator of any shape."},
	},
	"F2.06": {
		{"capture", "The capture operator", "The & shorthand: positional placeholders and function capture."},
		{"currying", "Partial application & currying", "Fixing arguments to specialize a function; currying by hand."},
		{"environment", "Capturing the environment", "What a closure captures, and when — the value at definition time."},
	},
	"F2.07": {
		{"matching", "Pattern matching on data", "Destructuring products and dispatching on sum variants."},
		{"product", "Product types", "Tuples and structs — fields held together; inhabitants multiply."},
		{"sum", "Sum types", "Tagged tuples and variants — one shape or another; inhabitants add."},
	},
	"F2.08": {
		{"compose", "Function composition", "Combining functions so one's output feeds the next — f after g."},
		{"pipe", "The pipe operator", "|> threads a value left to right, as the first argument."},
		{"pipeline", "Building pipelines", "map, filter, and reduce stages over a dataset, end to end."},
	},
	"F3.02": {
		{"branching", "Branching with case & guards", "case, with, and guard clauses that match on structure."},
		{"destructuring", "Destructuring data", "Pulling values out of tuples, lists, and maps by shape."},
		{"operator", "The match operator", "= binds by matching structure rather than assigning."},
	},
	"F3.04": {
		{"comprehensions", "Comprehensions", "for-comprehensions: filter, map, and into."},
		{"enum", "Enum, the eager workhorse", "The eager workhorse over any enumerable."},
		{"streams", "Lazy streams", "Lazy, composable enumerables."},
	},
	"F3.05": {
		{"defaults", "Enforcing keys & defaults", "@enforce_keys and default field values."},
		{"define", "Defining a struct", "defstruct, and how a struct is a tagged map."},
		{"matching", "Matching on a struct's type", "Pattern matching on %Struct{} by its tag."},
	},
	"F3.06": {
		{"behaviours", "Behaviours & callbacks", "@callback declares a typed contract on a module;"},
		{"defimpl", "Implementing for a struct", "defimpl Protocol, for: Struct gives the per-type bodies a call resolves to;"},
		{"define", "Defining a protocol", "defprotocol declares a contract of function signatures;"},
	},
	"F3.07": {
		{"messages", "Sending & receiving messages", "send/2 appends a term to a mailbox and returns;"},
		{"spawn", "Spawning a process", "spawn/1 starts a function as a new process and returns a PID at once;"},
		{"state", "Holding state in a loop", "A process holds state as the argument to a recursive receive loop, tail-calling itself with the "},
	},
	"F3.08": {
		{"call-cast", "Synchronous call, asynchronous cast", "GenServer.call sends a request and blocks for the reply, routing to handle_call;"},
		{"genserver", "The GenServer behaviour", "A GenServer abstracts the receive loop into a behaviour: init/1 sets the state, handle_call/3 an"},
		{"supervisors", "Supervisors & restart strategies", "A supervisor starts child processes and restarts them when they crash, by strategy — one_for_one"},
	},
	"F4.01": {
		{"big-o", "Complexity & big-O on the BEAM", "Big-O for a list is concrete: count the cons cells an operation touches."},
		{"cons", "Cons cells & the shape of a list", "A cons cell is a head and a tail pointer."},
		{"recursion", "Recursion over lists", "You walk a list by recursion, not a loop: match [h | t], act on the head, recurse on the tail, a"},
	},
	"F4.03": {
		{"sorts", "Merge & quicksort", "The two workhorse comparison sorts are both divide-and-conquer."},
		{"cost", "Stability & sort cost", "Sorts are ranked on average, worst case, space, and stability — whether equal keys keep their or"},
		{"search", "Linear & binary search", "Linear search checks elements one by one over any sequence — O(n)."},
	},
	"F3.03": {
		{"functions", "Defining functions", "Named functions with def and defp, multiple clauses that dispatch by pattern and guard, arity, a"},
		{"organising", "Organising with modules", "defmodule, module attributes, alias and import, and documentation — how the Portal namespace is "},
		{"pipe", "The pipe operator", "|> threads a value as the first argument to the next call, turning nested calls into a readable "},
	},
	"F4.02": {
		{"bfs", "Breadth-first & balance", "Breadth-first traversal walks the tree level by level with a FIFO queue."},
		{"dfs", "Depth-first: pre, in, post-order", "Depth-first traversal makes the same two recursive calls and differs only in when it visits the "},
		{"shape", "Binary trees & recursive shape", "A node is {value, left, right} or nil, so every tree function handles nil as the base case and a"},
	},
	"F4.04": {
		{"lookup", "Maps & key lookup", "A map associates keys with values and looks one up in effectively constant time."},
		{"hashing", "Hashing & collisions", "Maps and sets reach O(1) by hashing: phash2 turns a key into an integer, which picks a slot, and"},
		{"sets", "MapSet & membership", "A MapSet stores unique elements and answers membership in O(1)."},
	},
	"F4.06": {
		{"equality", "Canonical equality", "CHAMP maintains one canonical shape per set of entries, so two equal maps are structurally ident"},
		{"iteration", "Cache-friendly iteration", "Because a CHAMP node keeps its entries contiguous and separate from sub-node pointers, iteration"},
		{"layout", "Compressed node layout", "A CHAMP node carries a datamap and a nodemap — two bitmaps marking which of its 32 slots hold in"},
	},
	"F4.05": {
		{"bitmap", "Bitmapped nodes", "A HAMT node keeps one 32-bit bitmap marking which of its slots are occupied and one packed array"},
		{"indexing", "Hash-prefix indexing", "A HAMT reads the key's hash in five-bit chunks from the low end: level 0 reads bits 0-4, level 1"},
		{"sharing", "Structural sharing", "An insert builds new nodes only along the path from the root to the changed leaf and shares ever"},
	},
	"F4.07": {
		{"snowflake", "The Snowflake bigint", "A Snowflake packs three fields into 64 bits: a 42-bit millisecond timestamp from a custom 2024 e"},
		{"branded", "Branded ids", "A branded id encodes the 64-bit Snowflake in base62 over 0-9A-Za-z, left-pads it to eleven chara"},
		{"choosing", "Choosing an identifier", "An auto-increment counter is ordered and tiny but needs one writer, so it cannot scale across ma"},
	},
	"F4.08": {
		{"keys", "Branded ids as keys", "The database stores the 64-bit integer as a bigint primary key — eight bytes, numerically ordere"},
		{"redis", "Redis keys", "In Redis the id is a namespaced string key, user:USR0NbWMtkosp8."},
		{"sql", "SQLite & PostgreSQL", "Because the high bits of the id are a timestamp, a window of time is a contiguous window of ids:"},
	},
	"F4.09": {
		{"genserver", "Own it with a GenServer", "The Portal's session store is a CHAMP behind a GenServer."},
		{"partition", "Partition by namespace", "The Portal's entity registry keeps users, sessions, lessons, and pages in one store: a tiny top-"},
		{"trie", "Structural sharing", "Inside a partition the CHAMP is keyed on the lesson's Snowflake, and Portal.Progress marks a les"},
	},
	"F4.10": {
		{"patterns", "Idiomatic patterns", "A request to view a lesson clears four gates — validate the id, authenticate the caller, fetch t"},
		{"pipelines", "Streams & pipelines", "The activity feed wants the three most recent completions for a course."},
		{"profiling", "Profiling & complexity", "Every request finds an active session."},
	},
	"F4.11": {
		{"memoization", "Memoization & overlapping subproblems", "The longest prerequisite chain to a lesson is one plus the deepest of its prerequisites — a recu"},
		{"problems", "Classic DP problems", "Edit distance — the fewest single-character inserts, deletes, or substitutions between two strin"},
		{"tabulation", "Tabulation & bottom-up", "The fewest modules (worth 1, 3, or 4 credits) summing to a target is one more than the best answ"},
	},
	"F4.12": {
		{"grow", "Watch a branded CHAMP grow", "Each put reads a branded id's three-letter namespace and drops the entry into that namespace's p"},
		{"registry", "A Snowflake registry", "Hand the store any branded id and get/1 resolves it in one call: the prefix names the partition,"},
		{"range", "Query by time range", "Because a Snowflake puts the timestamp in its high bits, ids sort by creation time and a time wi"},
	},
	"F5.01": {
		{"replaceable", "A web layer built for replacement", "The thin server is a detail, by design."},
		{"roadmap", "The development roadmap", "The whole course is one development roadmap: HTML templating, then a simple web server, then the"},
		{"thin-server", "A thin web server in Elixir", "A minimal HTTP front end for the Portal: a Plug.Router matched and dispatched by Bandit, where e"},
	},
	"F5.02": {
		{"api", "A context's public API", "Each context exposes a small set of public functions — a smart constructor that validates and re"},
		{"contexts", "Bounded contexts", "A bounded context is a module that owns a few entities and guards their rules — Accounts owns Us"},
		{"structs", "Structs & typespecs", "An entity is a plain struct: @enforce_keys names the fields it cannot exist without, defstruct g"},
	},
	"F5.03": {
		{"iterating", "Iterating the slice", "Once the skeleton walks, you grow it one thin vertical slice at a time: deliver the first lesson"},
		{"prototypes", "Tracer bullets vs prototypes", "Both are built fast, but their fates are opposite."},
		{"skeleton", "The walking skeleton", "The enroll-a-learner slice, end to end: a POST /enroll route calls Learning.enroll/2, which buil"},
	},
	"F5.04": {
		{"assertions", "Assertions in Elixir", "Elixir has no design-by-contract keywords, so contracts are written in its idioms: guards and pa"},
		{"conditions", "Preconditions, postconditions & invariants", "A contract has three parts and three owners."},
		{"fail-fast", "Failing fast", "Check at the boundary and stop on the first violation, before the struct is built or the store i"},
	},
	"F5.05": {
		{"cqs", "Command/query separation", "One rule, due to Bertrand Meyer: a function either changes state or returns a value, never both."},
		{"events", "Domain events", "A record that something happened, written in the past tense and never changed once stored."},
		{"reducer", "The engine as a reducer", "Once every change is an event, new state is a left fold: the old state plus the next event."},
	},
	"F5.06": {
		{"choosing", "Choosing where state lives", "Three places on the BEAM can hold live state, and they are not interchangeable — only one fits the engine."},
		{"genserver", "The engine GenServer", "Three callbacks carry the whole engine: init folds the log on start, then calls and casts thread state through."},
		{"supervision", "Supervision", "A stateful process will eventually crash; a supervisor restarts it, and the engine replays its log to recover."},
	},
	"F5.07": {
		{"pure-core", "Testing the pure core", "The engine's logic lives in pure functions, so a plain example test — given a state and a command, assert the result — covers the core."},
		{"property", "Property-based testing", "An example test checks the cases you thought of; a property test asserts a rule over the cases a generator invents."},
		{"contract-tests", "Contract tests", "The F5.04 contract — precondition, postcondition, invariant — becomes three assertions that a command keeps its promises."},
	},
}

// ChapterExtras are chapter-level context pages (not numbered modules) that live
// directly under a chapter route, e.g. /elixir/language/history. They become
// linkable once the chapter itself is linkable.
var ChapterExtras = map[string][]Subpage{
	"F0": {
		{"csharp", "Elixir for C# developers", "An onramp from C# to Elixir."},
	},
	"F3": {
		{"history", "A short history of Elixir", "Where the language came from."},
		{"timeline", "The Elixir release timeline", "Versions and milestones."},
		{"under-the-hood", "Under the hood", "How the language runs on the BEAM."},
	},
	"F5": {
		{"architecture", "The Portal engine blueprint", "The system this chapter builds, at a glance."},
		{"domain-model", "The domain model", "Three bounded contexts and their branded ids."},
		{"flow", "The command & event flow", "One use case through the five-stage pipeline."},
	},
}

// ChapterByID returns the chapter with the given id.
func ChapterByID(id string) (Chapter, bool) {
	for _, c := range Chapters {
		if c.ID == id {
			return c, true
		}
	}
	return Chapter{}, false
}

// ChapterOf returns the chapter that owns the given module F-id.
func ChapterOf(n string) (Chapter, Module, bool) {
	for _, c := range Chapters {
		for _, m := range Modules[c.ID] {
			if m.N == n {
				return c, m, true
			}
		}
	}
	return Chapter{}, Module{}, false
}

// ModuleRoute returns the clean route and status for a module F-id.
func ModuleRoute(n string) (route, status string, ok bool) {
	c, m, found := ChapterOf(n)
	if !found {
		return "", "", false
	}
	return fmt.Sprintf("%s/%s", c.Route, m.Slug), m.Status, true
}

// SubpageRef is a resolved deep-dive page.
type SubpageRef struct {
	Route string
	Title string
	One   string
}

// SubpagesOf returns the resolved deep-dive pages for a module F-id.
func SubpagesOf(n string) []SubpageRef {
	route, _, ok := ModuleRoute(n)
	if !ok {
		return nil
	}
	var out []SubpageRef
	for _, s := range Subpages[n] {
		out = append(out, SubpageRef{Route: route + "/" + s.Slug, Title: s.Title, One: s.One})
	}
	return out
}

// AllowedRoutes returns the set of routes that render as links (live/built
// chapters, their linkable modules, and the subpages of linkable hubs).
func AllowedRoutes() map[string]bool {
	allowed := map[string]bool{RootRoute: true}
	for _, c := range Chapters {
		if Linkable(c.Status) {
			allowed[c.Route] = true
			for _, e := range ChapterExtras[c.ID] {
				allowed[c.Route+"/"+e.Slug] = true
			}
		}
		for _, m := range Modules[c.ID] {
			if !Linkable(m.Status) {
				continue
			}
			route := fmt.Sprintf("%s/%s", c.Route, m.Slug)
			allowed[route] = true
			for _, s := range Subpages[m.N] {
				allowed[route+"/"+s.Slug] = true
			}
		}
	}
	return allowed
}

// ModuleCount counts the numbered modules in the F1-F6 spine (F0 excluded).
func ModuleCount() int {
	n := 0
	for _, c := range Chapters {
		if c.ID == "F0" {
			continue
		}
		n += len(Modules[c.ID])
	}
	return n
}
