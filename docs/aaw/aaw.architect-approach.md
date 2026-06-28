# AAW — the architect's approach

> The method of record for how a **spec-steward** (the architect, Venus) frames and argues a **design fork**
> before the Operator rules it. Companion to [aaw.framework.md](aaw.framework.md) (the roles),
> [aaw.rules.md](aaw.rules.md) (the Decisions fence and the formations), and
> [specs.approach.md](../elixir/specs/specs.approach.md) (the triad templates). This document owns two facts —
> the *structure of a surfaced fork* and the *discipline of an authored contract set* — and quotes and links
> the rest; it does not re-own a contract defined elsewhere.

## Purpose of this document

The framework fixes the boundary — "an agent surfaces forks; it never decides them"
([aaw.framework.md](aaw.framework.md), the Operator-Agent model) — and the rules fix where a deferred choice
is recorded: the roadmap's "Seams & open decisions", under the Operator's absolute decision rights over
architecture, public API contracts, and new dependencies ([aaw.rules.md](aaw.rules.md), Decisions). What
neither fixes is the *shape of the argument* an architect puts in front of the Operator. A fork surfaced as a
bare list of options forces the Operator to reconstruct the case for each one by hand; a fork surfaced in this
structure arrives ready to rule. The structure was earned on the emq design forks — the "surfaced forks —
Venus surfaces, the Operator rules" sections of the `emq.N.design.md` carve docs — and is generalized here so
every program references one model instead of restating it.

## When it applies

The architect's approach governs the **design step** of a rung, not every rung. It applies when:

- a rung opens with more than one credible approach and the choice belongs to the Operator — architecture, a
  public API contract, a new dependency, a routing-identity question ([aaw.rules.md](aaw.rules.md), Decisions);
- the work runs in the **fan-out formation**, where the orchestrator senior-authors the design before any
  triad is written ([aaw.rules.md](aaw.rules.md), the two formations);
- a design doc precedes the triad — the `emq.N.design.md` precedent, sitting beside the chapter spec, carrying
  the ADRs and the surfaced forks.

A rung whose approach is already settled skips the fork and goes straight to the triad. A fork is a deliberate
instrument, not a default; surfacing one where none exists manufactures a decision the Operator did not need.

## The unit — an arm, argued in four parts

A fork is a set of **arms** (the candidate approaches). Each arm is argued in four parts, in this order. The
order is load-bearing: the Rationale earns the arm a place on the table, the 5W frames it, the Steelman is the
case for, and the Steward is the case for living with it for years.

### Rationale

The problem the arm solves and why it is a credible answer — never a strawman. An arm carried only to be
knocked down wastes the Operator's attention and corrupts the comparison, because a fork is only as honest as
its weakest seriously-argued arm. The Rationale states the need in one or two sentences and names what about
this arm answers it.

### 5W

Five bolded bullets — **Why · What · Who · When · Where** — the frame the roadmap epic uses
([aaw.roadmap.md](aaw.roadmap.md)). *Why* the arm exists, *What* it delivers, *Who* operates or consumes it,
*When* it is reached on the ladder, *Where* it lives in the tree. The 5W turns a sketch into something
locatable and schedulable, and exposes an arm whose cost lands on someone the Rationale did not mention.

### Steelman

The strongest possible case *for* the arm, argued at its best by an advocate who wants it to win — concrete
evidence, real call sites, named trade-offs honored rather than waved away. This is the part that most often
decides a fork and the part most often shortchanged. The Steelman is the `STEELMAN:` field of an
alternatives-channel entry in the progress ledger (`{<slug>-alternatives}`, `V-n`); its companion
`CHOSEN-AGAINST:` is written later, once the Operator rules, so the path not taken keeps its best case on the
record.

### Steward

The long-game counterweight: what the arm costs to keep. A public surface is a multi-year liability, and the
steward owns that view — maintenance burden, the cost to freeze and test it, how many invariants it adds and
how they age, how it composes with what is already frozen, and whether it honors the values it touches: One
authority, Do no harm, Thin but robust, Grounded ([aaw.framework.md](aaw.framework.md), Values). The Steward is
honest even about the arm the architect favors; an arm with a weak Steward is a debt the Operator should price
before ruling, not discover after.

## The fork surface

After the arms, the fork is **surfaced**, not resolved:

- the arms are set side by side — a table is the usual form — so the trade is legible at a glance;
- the architect *may* note a recommendation, with the one reason that carries it; the recommendation is
  advice, never a decision;
- the choice is the Operator's. "An agent surfaces forks; it never decides them" holds without exception — an
  architect that picks the winner has stopped being a steward and become an unaccountable author.

A surfaced fork the Operator defers becomes a **named decision** in the roadmap's "Seams & open decisions"
([aaw.rules.md](aaw.rules.md)). Once ruled, the ruling is recorded in the ledger's decisions channel
(`{<slug>-decisions}`, `D-n`, `RULED:`) and the chosen arm flows into the triad; the losing arms keep their
`CHOSEN-AGAINST:` rationale so the decision stays inspectable a year later.

## The multi-architect debate (optional)

For a high-stakes fork — a foundational contract, a surface that will be frozen — one architect's framing is a
single point of view. The approach then fans out **two or more architects**, each arguing the *same* arms from
a divergent lens (for example: developer-experience against spec-steward/invariants; performance against
simplicity; the consumer's view against the maintainer's). The Director stages the disagreement in the design
doc rather than averaging it away — a genuine divergence on which arm wins is itself the most useful signal the
Operator receives.

Two cadence rules apply. Heavy authoring runs at most two agents concurrently
([aaw.rules.md](aaw.rules.md), Concurrency asymmetry), so a debate is sized in waves. And the three judgments
stay separate: the architects argue, the Director synthesizes, the Operator rules. Each architect ranks the
arms and pre-empts the strongest objection from the opposing lens, so the synthesis inherits a rebuttal already
on the page instead of a second round.

## The contract set — surfaces authored as hypotheses that feed each other

A fork chooses an approach; many rungs then require the architect to **author a set of contracts** — the
per-unit documents that define a surface for the people and agents who build on it: a component library's
co-located `<Name>.prompt.md`, a command catalogue's per-command slices, an API's per-endpoint briefs. A
contract set is not a fork — there is no choice to rule, only a surface to get right — so it is argued in no
arms. It is the **second instrument** of the architect's design step, and it has its own discipline.

- **A contract is a hypothesis.** Each one states how a unit is used — its inputs, its variants, its
  composition — as a claim the implementation and the real call sites can falsify. It is authored against the
  source, never from memory. An unverified contract is the most expensive kind of wrong, because a consumer —
  a developer, or an agent generating UI from it — acts on it as fact (the Grounded value,
  [aaw.framework.md](aaw.framework.md)).
- **A generated stub is not a contract.** An extractor — a design-sync converter, a `.d.ts` emitter — reflects
  the *runtime shape* ("use via `window.X.Button`"), not the architect's intent. It carries no rationale, no
  cross-reference, and no grounding in how the surface is actually composed. A generated stub is a seed at
  most; the authoritative contract is hand-authored and verified.
- **The set feeds itself.** A contract references its siblings and its foundation — it composes
  (`leading={<Icon/>}`, "wrap a `Button`", "place under `AuthLayout`") and it draws on a shared vocabulary (the
  token families, the common prop kit). A cross-reference is a **link, never a restatement** — One Authority
  applied to the contract layer: a concept is defined in one contract and pointed to from the rest, so the set
  stays consistent as it grows and a reader can traverse it. The cross-references also surface gaps for free —
  a composition that names a sibling with no contract yet is a missing rung made visible.
- **Feedback closes against three truths.** A contract is reconciled against (1) the **implementation** — do
  the documented inputs and arities match the source; (2) the **real call sites** — is every example a usage
  that exists, not one invented to read well; (3) the **sibling contracts** — do the cross-references resolve
  and the vocabulary agree. A mismatch edits the contract; when the mismatch is in the implementation, it
  surfaces as a delta to the Operator — never silently smoothed. This is the reconcile pass
  ([aaw.framework.md](aaw.framework.md), the artifact-truth event) applied to an authored surface rather than
  to code.
- **Author the exemplar first, then fan out.** Efficiency takes the shape of the fan-out formation
  ([aaw.rules.md](aaw.rules.md)): the architect senior-authors **one** contract to the bar the rest imitate —
  fixing the section order, the depth, and the grounding standard — then the siblings are authored in waves,
  each applying the exemplar, each grounded and verified, the concurrency cadence (at most two heavy authors at
  once) unchanged. The exemplar is what makes a set of thirty contracts read as one surface rather than thirty
  voices.

The contract set is part of the spec layer's deliverable: the brief instructs the implementor or an author
wave to produce each contract grounded and cross-linked, and the stories accept the set by sampling its
reconciliation. The fork rules the approach; the contract set documents the surface that approach exposes.

## Voice and grounding

The design doc obeys the corpus voice and grounding ([aaw.rules.md](aaw.rules.md), Voice): plain specific
prose, no first person, no forbidden words, no perceptual or interior-state verbs applied to software. NO-INVENT
holds with full force — every surface an arm names is verified at its source or written in the forward tense
for surface not yet built, and the design doc links the contracts it cites rather than restating them. An arm
that rests on an invented module or an unverified arity is disqualified before it is argued; a Steelman built on
a surface that does not exist is the most expensive kind of wrong, because it is the most persuasive.

## How it composes

The approach is the first half of a rung's design layer; the triad is the second. The arc: the architect
surfaces the fork in four-part arms → the Operator rules → the architect authors the chosen arm's **contract
set** (above) → [specs.approach.md](../elixir/specs/specs.approach.md) governs the triad → the lead-team builds
it → the reconcile pass checks the build against the spec ([aaw.rules.md](aaw.rules.md), the lag-1 reconcile).
This document defines the architect's two design-step instruments — the fork and the contract set; once the arm
is chosen and its surface documented, authority passes to the triad contract, and the fork's record survives in
the roadmap and the ledger.

## References

- The roles and the surface-forks boundary: [aaw.framework.md](aaw.framework.md).
- The Decisions fence, the two formations, the concurrency rules, and the voice: [aaw.rules.md](aaw.rules.md).
- The triad templates, the traceability chain, the completion rule:
  [specs.approach.md](../elixir/specs/specs.approach.md).
- The 5W epic frame: [aaw.roadmap.md](aaw.roadmap.md).
- The surfaced-fork precedent in a shipped program: the "surfaced forks — Venus surfaces, the Operator rules"
  sections of [emq.design.md](../echo_mq/emq.design.md) and the `emq.N.design.md` carve docs.
- The ledger channels the four parts map to: the alternatives channel (`{<slug>-alternatives}`,
  `STEELMAN:` / `CHOSEN-AGAINST:`) and the decisions channel (`{<slug>-decisions}`, `RULED:`).

---

Index: [aaw.md](aaw.md) · Definition: [aaw.framework.md](aaw.framework.md) · Rules: [aaw.rules.md](aaw.rules.md) ·
Reverse: [aaw.reverse.md](aaw.reverse.md) · Roadmap: [aaw.roadmap.md](aaw.roadmap.md)
