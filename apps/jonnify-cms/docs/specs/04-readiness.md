# 04 — Readiness: manifest ↔ filesystem ↔ gates reconciliation

This document specifies `cms readiness [--root DIR] [--json]`. The command reports, per
module, whether the module is **ready**, by reconciling the three sources of truth
(`docs/specs/00-overview.md` §2): the manifest's declared status, the presence of the backing
file under `/elixir`, and the nine Apollo gates run against that file. It also surfaces
**drift** — modules that are ready while the manifest still declares them planned — and
specifies the promote-on-ready flow that turns a "soon" placeholder into a live link.

Readiness is read-only. It does not edit the manifest or the content tree; promotion is a
manifest edit a person makes after reviewing the report.

## 1. Definitions

For a module `M` with declared status `S`, backing route `R`, and resolved file `F`:

- **Exists** — the resolver (`docs/specs/00-overview.md` §3) finds a file at `R` under the
  content root.
- **Passes** — the file at `R` passes **all nine** Apollo gates
  (`docs/specs/05-build-validate.md`). Evaluated only when Exists is true; otherwise Passes is
  false by definition.
- **Ready** — `Exists AND Passes`. Readiness is the filesystem-and-quality view of a module.
  It does not consider `S`.
- **DeclaredLinkable** — `S ∈ {live, built}` (`manifest.Status.Linkable()`).
- **Drift** — `Ready AND NOT DeclaredLinkable`. The page is finished and passes, but the
  manifest still calls it `planned`/`soon`. The page is therefore rendered as a non-linking
  card even though it could be a link.

The unit of readiness is the **module** (and, when `--root` is given, also its subpages,
reported nested under the module). Chapters are summarized but readiness is defined per page.

## 2. The reconciliation matrix

Every module falls into one cell of (DeclaredLinkable, Exists, Passes). The matrix defines the
reported state and the action a person should take.

| DeclaredLinkable | Exists | Passes | State | Meaning | Action |
|:---:|:---:|:---:|---|---|---|
| no | no | – | `planned` | Declared planned, not built. The expected state for future work. | none (build when scheduled) |
| no | yes | no | `drift-failing` | A file exists for a planned module but does not pass the gates. | finish the page to A+, then promote |
| no | yes | yes | **`drift-ready`** | Built and passing, but the manifest still says planned. | **promote** status → `built` (§4) |
| yes | no | – | `missing` | Declared linkable, but no backing file. The contents directory links to a 404. | build the page (or demote in the manifest) |
| yes | yes | no | `regressed` | Declared linkable and present, but a gate fails. The live page is below the A+ bar. | repair the page to passing |
| yes | yes | yes | **`ready`** | Declared linkable, present, passing. The healthy steady state. | none |

`ready` and `drift-ready` are the two states in which the module is **ready** (`Ready` is
true). `drift-ready` is the actionable drift: the only thing missing is the manifest catching
up. `missing` and `regressed` are the inverse problems — the manifest is ahead of, or
out of step with, a healthy file.

## 3. The current drift case

Today the canonical drift is **F2.06 (closures), F2.07 (adt), F2.08 (composition)**. The
manifest declares all three `planned` (`docs/specs/01-manifest.md` §2), yet each is on disk
and passes the gates:

| Module | Declared | Backing file (resolved) | Exists | Expected state |
|---|---|---|---|---|
| F2.06 closures | `planned` | `functional/closures/index.html` | yes | `drift-ready` |
| F2.07 adt | `planned` | `functional/adt/index.html` | yes | `drift-ready` |
| F2.08 composition | `planned` | `functional/composition/index.html` (after audit `--fix`) | yes (after `--fix`) | `drift-ready` |

Note the interaction with the link audit: F2.08's hub file is currently named
`functional/composition/functional.html`, an orphan, so before `cms audit --fix` the route
`/elixir/functional/composition` resolves to no file and F2.08 reports `missing` /
`drift-failing` rather than `drift-ready`. After `cms audit --fix` renames the orphan to
`functional/composition/index.html` (`docs/specs/03-link-audit.md` §4–§5), the route resolves,
the gates run on the present file, and F2.08 joins F2.06 and F2.07 as `drift-ready`. The
recommended order is therefore **audit `--fix` first, then readiness, then promote**.

The brief (`fp-elixir-brief.md`) already describes these three as `built` hubs with subpages;
the manifest port has not caught up. `readiness` makes that gap explicit and actionable.

## 4. Promote-on-ready: soon → link

Promotion is the resolution of `drift-ready`. It is a **manifest edit**, performed by a person
after reviewing the readiness report; `cms` does not mutate the manifest. The effect chain:

1. In `internal/manifest`, change the module's `Status` from `planned` to `built` (and, for a
   chapter or subpage that becomes reachable, its status likewise).
2. `manifest.AllowedRoutes()` now includes the module's route (and its subpages' routes, since
   a subpage becomes linkable once its parent is — `docs/specs/01-manifest.md` §4).
3. The contents directory (`build`) now renders the module as `<a class="mod" href="…">`
   instead of `<div class="mod is-quiet">` — the "soon"/quiet placeholder card becomes a live
   **link** (`docs/specs/05-build-validate.md`). The `links`/`pager` Apollo gates on other
   pages now accept hrefs to the promoted route.
4. `cms routes` shows the route as `link` rather than `card`; `cms graph` marks the node
   linkable; `cms audit` accepts links to it.
5. Re-running `cms readiness` reports the module as `ready` (the steady state) rather than
   `drift-ready`.

Promotion turns a placeholder into a link precisely because linkability is derived from
status: the page already exists and passes; changing the declared status is the only thing
that flips its rendering and admits inbound links.

The inverse, **demotion**, applies to a persistent `missing` row whose page is not going to be
built soon: change `built`→`planned` so the contents directory stops linking to a 404. The
matrix's `missing` row recommends build-or-demote; readiness reports the state, the person
chooses.

## 5. Algorithm

`cms readiness`:

1. Resolve the content root (`--root`, default `./elixir`).
2. For each chapter in `manifest.Chapters`, for each module in `manifest.Modules[chapter.ID]`,
   in order:
   a. Compute the module route and declared status.
   b. `Exists, File := Resolve(root, route)` (§3 of `02`).
   c. If Exists, read `File` and run `apollo.Run(bytes)` → `(passed, perGateResults)`; else
      `passed = false`.
   d. Classify into one of the six states per the §2 matrix from
      `(DeclaredLinkable, Exists, passed)`.
   e. If the module has subpages, repeat (a)–(d) per subpage and attach the results nested
      under the module.
3. Aggregate counts per state and overall `ready / total`.
4. Emit the table (§6) or JSON (`--json`).

The Apollo run is the same engine `cms check` uses; readiness is "the manifest's module list,
each row resolved to a file and run through `check`, cross-tabulated against the declared
status." Modules without a backing file are not run through the gates (nothing to read);
their Passes is false and they land in `planned` or `missing`.

## 6. Output

### 6.1 Table (default)

```
Readiness · root=../../elixir
ID        DECLARED  EXISTS  GATES  STATE          FILE
F1.01     built     yes     9/9    ready          algebra/functions.html
F1.02     built     yes     9/9    ready          algebra/substitution.html
...
F2.01     built     yes     9/9    ready          functional/pure.html
F2.05     built     yes     9/9    ready          functional/folds/index.html
F2.06     planned   yes     9/9    drift-ready    functional/closures/index.html
F2.07     planned   yes     9/9    drift-ready    functional/adt/index.html
F2.08     planned   yes     9/9    drift-ready    functional/composition/index.html
F2.09     planned   no      –      planned        functional/pipeline-lab.html (absent)
F3.01     planned   no      –      planned        language/values.html (absent)
...

summary: ready 28 · drift-ready 3 · planned 31 · missing 0 · regressed 0 · drift-failing 0
promote candidates (drift-ready): F2.06, F2.07, F2.08
```

Columns: `ID` (8), `DECLARED` (status, 9), `EXISTS` (yes/no, 6), `GATES` (`n/9` or `–`),
`STATE` (the §2 state), `FILE` (resolved path, with `(absent)` when the file does not exist —
the path shown is the leaf candidate from the resolver). The `GATES` column shows how many of
the nine passed; `9/9` is required for `ready`/`drift-ready`. A footer summary line counts
each state, and a `promote candidates` line lists the `drift-ready` modules (the actionable
set for §4). Output is deterministic (manifest order).

When a gate fails on an existing file (`regressed`/`drift-failing`), the row is followed by an
indented list of the failing gate names so the repair is directed:

```
F2.08     planned   yes     7/9    drift-failing  functional/composition/index.html
            failing: svg, pager
```

### 6.2 JSON (`--json`)

```json
{
  "root": "../../elixir",
  "summary": {
    "ready": 28, "driftReady": 3, "planned": 31,
    "missing": 0, "regressed": 0, "driftFailing": 0, "total": 62
  },
  "promoteCandidates": ["F2.06", "F2.07", "F2.08"],
  "modules": [
    {
      "id": "F2.06",
      "title": "Closures & partial application",
      "route": "/elixir/functional/closures",
      "declared": "planned",
      "declaredLinkable": false,
      "exists": true,
      "file": "functional/closures/index.html",
      "gatesPassed": 9,
      "gatesTotal": 9,
      "failingGates": [],
      "ready": true,
      "state": "drift-ready",
      "subpages": []
    }
  ]
}
```

- `state` is one of `ready|drift-ready|planned|missing|regressed|drift-failing`.
- `failingGates` lists the names of any of the nine gates that failed (empty when all pass or
  the file is absent).
- `total` in `summary` counts modules across all six F1–F6 chapters plus F0 modules that the
  report includes; `promoteCandidates` is the `drift-ready` subset, ordered by manifest order.
- `subpages`, when present, carries the same per-page shape nested under the module.
- Arrays are in manifest order; the JSON is two-space-indented with a trailing newline.

## 7. Exit codes

| Invocation | Outcome | Exit |
|---|---|---|
| `cms readiness` | report printed; no `regressed` and no `missing` modules | `0` |
| `cms readiness` | ≥1 `regressed` or `missing` module (a declared-linkable page is broken or absent) | `1` |
| `cms readiness --json` | same rule; JSON always emitted regardless | per above |
| any | unreadable root / bad flag | `2` |

`drift-ready` and `drift-failing` are **not** failures for the exit code: drift is expected
ahead of a promote and does not block. The exit-1 condition is reserved for a manifest that
promises something the filesystem does not honor (`missing`) or a live page that fell below
A+ (`regressed`). This makes `cms readiness` usable as a CI gate that fails when published
content breaks, while tolerating in-progress drift.
