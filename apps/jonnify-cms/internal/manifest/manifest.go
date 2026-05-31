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
	{"F4", "Algorithms & Data Structures", "algorithms", "/elixir/algorithms", "planned", "Classical and advanced problems, from lists to branded CHAMP tries.", "Builds on F3 · The Elixir Language.", "sage"},
	{"F5", "Pragmatic Programming", "pragmatic", "/elixir/pragmatic", "planned", "Real-world engineering: structure, testing, telemetry, releases.", "Builds on F4 · Algorithms & Data Structures.", "sage"},
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
		{N: "F3.03", Title: "Functions, modules & the pipe", One: "Defining and composing in modules.", Slug: "modules", Status: "planned"},
		{N: "F3.04", Title: "Enumerables & streams", One: "Eager versus lazy traversal.", Slug: "enum-streams", Status: "built"},
		{N: "F3.05", Title: "Structs, maps & keyword lists", One: "Shaping data; when to use which.", Slug: "structs", Status: "built"},
		{N: "F3.06", Title: "Protocols & behaviours", One: "Polymorphism and contracts.", Slug: "protocols", Status: "planned"},
		{N: "F3.07", Title: "Processes & the actor model", One: "spawn, send, receive; isolation.", Slug: "processes", Status: "planned"},
		{N: "F3.08", Title: "OTP: GenServer & supervisors", One: "Stateful servers and fault tolerance.", Slug: "otp", Status: "planned"},
		{N: "F3.09", Title: "The process playground", One: "Spawn processes; watch the mailbox live.", Slug: "playground", Status: "planned", Lab: true},
	},
	"F4": {
		{N: "F4.01", Title: "Lists, recursion & complexity", One: "Cons cells; big-O on the BEAM.", Slug: "lists", Status: "planned"},
		{N: "F4.02", Title: "Trees & traversals", One: "Binary/n-ary trees; DFS/BFS functionally.", Slug: "trees", Status: "planned"},
		{N: "F4.03", Title: "Sorting & searching", One: "Merge/quick sort, binary search, immutably.", Slug: "sorting", Status: "planned"},
		{N: "F4.04", Title: "Maps, sets & hashing", One: "Hash maps, collisions, the cost model.", Slug: "maps", Status: "planned"},
		{N: "F4.05", Title: "Hash Array Mapped Tries (HAMT)", One: "Persistent maps via prefix trees.", Slug: "hamt", Status: "planned"},
		{N: "F4.06", Title: "CHAMP maps", One: "Compressed HAMT trees; layout & iteration.", Slug: "champ", Status: "planned"},
		{N: "F4.07", Title: "Branded Champ maps", One: "Namespaced keys as cross-system pivots.", Slug: "branded-champ", Status: "planned"},
		{N: "F4.08", Title: "Dynamic programming & advanced problems", One: "Memoisation and harder challenges.", Slug: "dynamic-programming", Status: "planned"},
		{N: "F4.09", Title: "Watch a Branded Champ map grow", One: "Insert keys; animate the trie building.", Slug: "champ-lab", Status: "planned", Lab: true},
	},
	"F5": {
		{N: "F5.01", Title: "Project structure & Mix", One: "Apps, deps, tasks.", Slug: "mix", Status: "planned"},
		{N: "F5.02", Title: "Testing with ExUnit & doctests", One: "Fast, deterministic tests.", Slug: "testing", Status: "planned"},
		{N: "F5.03", Title: "Documentation & typespecs", One: "@doc, @spec, Dialyzer.", Slug: "typespecs", Status: "planned"},
		{N: "F5.04", Title: "Error handling & \"let it crash\"", One: "Tagged tuples vs exceptions; supervision.", Slug: "let-it-crash", Status: "planned"},
		{N: "F5.05", Title: "Concurrency patterns & Tasks", One: "Task, async/await, back-pressure.", Slug: "tasks", Status: "planned"},
		{N: "F5.06", Title: "Telemetry, logging & observability", One: "Seeing inside a running system.", Slug: "telemetry", Status: "planned"},
		{N: "F5.07", Title: "Dependencies, releases & deployment", One: "mix release, config, runtime.", Slug: "releases", Status: "planned"},
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
		{"shape", "The shape of recursion", "Base case, recursive case, and the growing call stack."},
		{"tail-calls", "Tail calls & accumulators", "Rewrite with an accumulator for constant stack space."},
		{"patterns", "Recursion patterns", "sum, length, reverse, map, filter — and why they are folds."},
	},
	"F2.05": {
		{"map", "map", "Transform every element; the structure is preserved."},
		{"filter", "filter", "Keep the elements that pass a predicate."},
		{"reduce", "reduce", "The general fold; an accumulator of any shape."},
		{"advanced", "Advanced folds", "scan, map_reduce, flat_map, group_by."},
	},
	"F2.06": {
		{"environment", "Capturing the environment", "What a closure captures, and when — the value at definition time."},
		{"capture", "The capture operator", "The & shorthand: positional placeholders and function capture."},
		{"currying", "Partial application & currying", "Fixing arguments to specialize a function; currying by hand."},
	},
	"F2.07": {
		{"product", "Product types", "Tuples and structs — fields held together; inhabitants multiply."},
		{"sum", "Sum types", "Tagged tuples and variants — one shape or another; inhabitants add."},
		{"matching", "Pattern matching on data", "Destructuring products and dispatching on sum variants."},
	},
	"F2.08": {
		{"compose", "Function composition", "Combining functions so one's output feeds the next — f after g."},
		{"pipe", "The pipe operator", "|> threads a value left to right, as the first argument."},
		{"pipeline", "Building pipelines", "map, filter, and reduce stages over a dataset, end to end."},
	},
	"F3.02": {
		{"operator", "The match operator", "= binds by matching structure rather than assigning."},
		{"destructuring", "Destructuring data", "Pulling values out of tuples, lists, and maps by shape."},
		{"branching", "Branching with case & guards", "case, with, and guard clauses that match on structure."},
	},
	"F3.04": {
		{"enum", "Enum, the eager workhorse", "The eager workhorse over any enumerable."},
		{"streams", "Lazy streams", "Lazy, composable enumerables."},
		{"comprehensions", "Comprehensions", "for-comprehensions: filter, map, and into."},
	},
	"F3.05": {
		{"define", "Defining a struct", "defstruct, and how a struct is a tagged map."},
		{"defaults", "Enforcing keys & defaults", "@enforce_keys and default field values."},
		{"matching", "Matching on a struct's type", "Pattern matching on %Struct{} by its tag."},
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
