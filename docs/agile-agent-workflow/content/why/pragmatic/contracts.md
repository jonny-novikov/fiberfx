# A1.02.2 — Design by contract (the contract is the spec)

- **Route:** `/course/agile-agent-workflow/why/pragmatic/contracts`
- **File:** `html/agile-agent-workflow/why/pragmatic/contracts.html`
- **Place in the module:** the second dive of A1.02 — the *specification* principle. How do you hand an agent a
  unit precisely enough to implement and to accept?
- **Accent word (`.ex`):** "contract".

## Lead

Design by Contract states a routine's obligations as three clauses: a precondition the caller must meet, a
postcondition the routine guarantees, and an invariant always true. For an agent that is not a nicety — it is
the specification itself. A contract is the smallest precise statement of a unit an agent can implement against
and you can accept against, without reading every line of the diff.

## Definition

- **precondition** — the caller's obligation; what must hold for the routine to run. Unmet → the routine refuses;
  the agent need not handle the impossible.
- **postcondition** — the routine's guarantee; what is true of the result when the precondition held. This is
  what you accept against.
- **invariant** — a property true before and after every call, on every path.
- **Design by Contract (DbC)** — specifying a unit by those three clauses (Meyer, Eiffel). The agent-era reading:
  the contract is the acceptance criterion. A diff that satisfies the contract is acceptable; one that does not
  is rejected by the named clause it broke — a verdict you reach without re-reading the implementation.

## Worked Portal example

The branded id has a contract. **Precondition:** the namespace is a known type (`:user`, `:event`, `:lesson`).
**Postcondition:** the result is a 14-character `TSK…`-prefixed id that `decode/1` maps back to that type.
**Invariant:** ids are unique and monotonic within a node-millisecond — never two the same. This is exactly the
contract that made "generate one id" an acceptable thin slice back in A1.01.3: the slice carried its own
acceptance. Use only the established API (`Portal.ID.generate/1`, `Portal.ID.decode/1`, and `decode(id).type` /
`decode(id).timestamp` as in the thin-slices lesson). Do not invent new functions, arities, or fields.

## The two interactives (different teaching moves)

- **Hero figure — the contract, evaluated live (the IDEA).** One `.solid-select` button group `#ctInput` picks
  the namespace passed in, from {`:user`, `:event`, `:lesson`, `:banana`}. The SVG shows three lamps stacked —
  precondition, postcondition, invariant (`#lamp-pre`, `#lamp-post`, `#lamp-inv`) — each lit green (holds) or
  red (violated) for the chosen input. Pure logic: `KNOWN = {user, event, lesson}`; `preHolds(ns) =
  KNOWN.has(ns)`. If `preHolds`: pre green, post green ("TSK… · 14 chars · decodes to :ns"), invariant green.
  If not: pre red ("unknown namespace → refuse"), post and invariant greyed (never reached — the routine does
  not run). Readout `#ctOut` states the verdict. element ids: `#ctInput`, `#lamp-pre/-post/-inv`, `#ctOut`.
- **Content figure — the acceptance gate (the CONSEQUENCE).** Model an agent's submitted output and let the
  contract accept or reject it. Controls: one `.fold-ctrl` slider `idLength` (10…18; the contract requires
  exactly 14) and two `.solid-select` toggles `decodes` (yes/no) and `unique` (yes/no). Pure boolean:
  `lenOk = (idLength === 14)`; `accept = lenOk && decodes && unique`. A verdict panel `#ctVerdict` reads ACCEPT
  (gold) when all three hold, else REJECT (burgundy) naming the first failing clause:
  `!lenOk` → "postcondition: length is L, not 14"; `!decodes` → "postcondition: does not decode to the type";
  `!unique` → "invariant: collides within a node-millisecond". Three clause lamps mirror the booleans. Readout
  `#ctGate`: "The contract is the gate. You accept the agent's diff because it satisfies the contract — not
  because you re-read every line." element ids: `#ctLen`/`#ctLenVal`, `#ctDecodes`, `#ctUnique`, `#ctVerdict`,
  `#ctGate`, `#gate-len/-dec/-uniq`.

## Bridge / recap / references

- **bridge:** principle — a routine's obligations are stated as pre/post/invariant → Portal — the id contract
  (known namespace in; 14-char decoding id out; unique within a node-ms) is the slice's acceptance.
- **take:** the contract is the unit of specification *and* the unit of acceptance; it is what lets a human
  accept an agent's work at the boundary instead of line by line.
- **sources (real):** Meyer, B. — *Object-Oriented Software Construction* (Design by Contract, Eiffel);
  Hunt & Thomas, *The Pragmatic Programmer* ("Design by Contract").
- **related:** A1.02.1 dry, A1.02.3 orthogonality, the A1.02 hub, A1.01.3 thin-slices (the slice carried its
  acceptance), A1.

## Wiring

- route-tag `/course/agile-agent-workflow/why/pragmatic/contracts`; crumbs jonnify / AAW / A1 (`/why`) /
  A1.02 (`/why/pragmatic`) / here. Pager: prev → A1.02.1 dry (`/why/pragmatic/dry`); next → A1.02.3 orthogonality
  (`/why/pragmatic/orthogonality`).
- `.hero-split`: hero text beside the live-contract hero interactive. Copy head/header/footer/scripts from
  `html/agile-agent-workflow/why/pragmatic/dry.html` (same module — exact design-system parity).
