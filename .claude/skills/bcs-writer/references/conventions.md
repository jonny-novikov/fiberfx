# BCS series conventions — the full gate set

## Voice (hard gate, swept by scripts/sweep.py)
Forbidden anywhere in prose (code fences and inline code exempt):
revolutionary, blazing, magical*, simply, just, obviously, effortless*,
actually, genuinely, honestly, easy, seamless*, powerful, honest, honesty.
No exclamation marks. Confident, measured, candid about losses; trade-offs
named beside wins (the Oban-style concession pattern).

## Format
Writerside markdown. First line `# BCS · Title` (or the chapter's own h1),
second line `<show-structure depth="2"/>`. Prose-led: headers and short
fenced blocks for measured tables; markdown tables only where a matrix is
the content (choosers, TOC rows). Bullets rare; never in refusals or
analysis that reads as prose. Lede states the article's one sentence.

## NO-INVENT grounding
Cite only modules, files, chapters, and outputs that exist. Surfaces a
chapter will build are written "this chapter builds". Links only to files
that resolve from the article's directory; planned files are plain prose.
Uploaded material and the working tree outrank memory.

## References policy
Numbered References section; every URL search-verified in the current
session (web_search or web_fetch hit). Primary sources over aggregators.
No reference without a claim citing it; no claim number without a listed
reference (sweep enforces the bijection).

## Quotes
Under 15 words, at most one per source, prefer paraphrase. Public-domain
epigraphs exempt.

## Measurement protocol
Derivation before measurement: state what the design predicts, then show
numbers. Probe the environment first; record versions and allocators in
the .out header. Commit every .out the article quotes, before writing.
Whole-run amortized metrics preferred (e.g. used_memory delta / N after a
settle poll). Best-of-5 for nanosecond rows. Every figure in the article
must appear verbatim in a committed .out (sweep --figures enforces).

## Standing decisions
docs/bcs/bcs.toc.md carries a "Standing decisions" section. Read it every
session; it supersedes this skill's examples and any memory (precedent:
the Dragonfly target was superseded by Valkey mid-series). Amendments are
recorded inline in the TOC, naming what they supersede.

## Ship loop tail
After the sweep passes: update bcs.toc.md (status planned→live, link the
file), refresh the production archive, copy deliverables to
/mnt/user-data/outputs/, present_files with the article first.

Archive refresh (adjust paths if the tree moved):
cd /home/claude && rm -f /mnt/user-data/outputs/echo_data-production.zip && \
zip -r /mnt/user-data/outputs/echo_data-production.zip echo_data \
 -x "echo_data/runtimes/elixir/priv/*" -x "*.so" -x "*.o" -x "*.bc" \
 -x "echo_data/runtimes/node/node_modules/*" \
 -x "echo_data/runtimes/node/package-lock.json" \
 -x "echo_data/apps/imagegen/node_modules/*" \
 -x "echo_data/apps/imagegen/package-lock.json" \
 -x "echo_data/contract/branded-id-rs/target/*"
