# EchoMesh course conventions — the full gate set

## Voice (hard gate, swept by scripts/sweep.py)
Forbidden anywhere in prose (code fences and inline code exempt):
revolutionary, blazing, magical*, simply, just, obviously, effortless*,
actually, genuinely, honestly, easy, seamless*, powerful, honest, honesty.
No exclamation marks. Use "candid" for the honest/honesty sense. Confident,
measured, candid about losses; trade-offs named beside wins. (Note the
asterisked entries match suffixes — `seamless\w*` catches "seamlessly" but
not the bare noun "seam", which is the course's term for the identity
join and is allowed.)

## Format
Writerside markdown. First line `# EchoMesh, In Depth · {title}`, second
line `<show-structure depth="2"/>`. Prose-led: headers carry the argument;
bullets only for the navigational map and the doors. A dive opens with a
one-paragraph blockquote lede stating its one sentence, then a
`## Scope and method` naming what is cited versus stated as design and what
is out of frame, and closes with `## Boundaries`, `## Map`, and
`## References`. No numbered lists in the body — a line beginning `N. `
collides with the reference bijection.

## NO-INVENT grounding
Cite only chapters, dives, files, modules, and outputs that exist in the
corpus, an upload, or a committed output. Surfaces a later chapter will
build are written as plain prose in inline code (`mesh.5.md`), never as
markdown links. Links resolve only to files that exist on disk from the
page's directory. Uploaded material and the working tree outrank memory.

## PROPOSED-EchoMesh discipline
EchoMesh is a forward composition this course introduces. Its pieces are
real and shipped — the BEAM, Postgres with `Ecto.Multi`, Tigris, Fly
Machines, the FLAME pattern, and the EchoMQ and EchoCache components — and
their composition into the segmented mesh is proposed. Every chapter
landing and every mesh dive carries a candid line separating the shipped
substrate from the proposed whole, and defers the full separation to the
synthesis (M8.2). Teach shipped technologies in the present tense; teach
the mesh as the design the course builds toward.

## Identity seam
The 14-byte branded identity that lets one entity stay addressable across
surfaces that chose different trades is the `/bcs` course's contract. It is
described and pointed at the `/bcs` door and the M5.3 build — never
restated from memory as if this course specified it, and not cited to an
outside reference.

## References policy
Numbered References section per file; every URL search-verified in the
current session (web_search or web_fetch hit). Primary sources over
aggregators. No reference without a claim citing it; no claim number
without a listed reference — the sweep enforces the bijection per file, so
dives renumber their references locally `1..k` rather than carrying the
landing's global scheme.

## CAP reference canon (reuse the entries; re-verify each session)
The course's external claims draw from a fixed primary-source set. Reuse
these citations, but confirm each URL this session before writing.

1. Gilbert, S. & Lynch, N. (2012) — Perspectives on the CAP Theorem
   (IEEE Computer 45(2):30–36): CAP as a case of the safety-versus-liveness
   impossibility; the four coping strategies and the five segmentation
   dimensions; the phrase that practitioners must "do the impossible".
   https://groups.csail.mit.edu/tds/papers/Gilbert/Brewer2.pdf
2. Gilbert, S. & Lynch, N. (2002) — Brewer's Conjecture and the
   Feasibility of Consistent, Available, Partition-Tolerant Web Services
   (ACM SIGACT News 33(2):51–59): the formal proof in the asynchronous
   model. https://dl.acm.org/doi/10.1145/564585.564601
3. Fischer, M., Lynch, N. & Paterson, M. (1985) — Impossibility of
   Distributed Consensus with One Faulty Process (J. ACM 32(2):374–382):
   consensus is unsolvable with one crash failure.
   https://dl.acm.org/doi/10.1145/3149.214121
4. Abadi, D. — The PACELC design principle: the else-clause; consistency
   trades against latency on a healthy network.
   https://en.wikipedia.org/wiki/PACELC_theorem
5. McCord, C. — Rethinking Serverless with FLAME (Fly.io): the Fleeting
   Lambda Application for Modular Execution pattern.
   https://fly.io/blog/rethinking-serverless-with-flame/
6. Fly.io — Machines: subsecond-launch VMs with a REST lifecycle API.
   https://fly.io/docs/machines/
7. Fly.io — Tigris Global Object Storage: globally distributed,
   S3-compatible, writes near the region and replicates near requesters.
   https://fly.io/docs/tigris/
8. Elixir — Ecto.Multi: composes operations into one atomic transaction
   with automatic rollback. https://hexdocs.pm/ecto/Ecto.Multi.html
9. Erlang Solutions — BEAM and JVM Virtual Machines: the BEAM's built-in,
   location-transparent distribution model.
   https://www.erlang-solutions.com/blog/beam-jvm-virtual-machines-comparing-and-contrasting/

## Quotes
Under 15 words, at most one per source, prefer paraphrase. Public-domain
epigraphs exempt.

## Measurement (when a chapter quotes numbers)
Most orientation dives carry no measurement and say so in Scope and method.
A chapter that makes performance or size claims commits its `.out` files
first, records versions and allocators in the `.out` header, derives what
the design predicts before showing numbers, and ensures every figure
appears verbatim in a committed `.out` (sweep `--figures` enforces).

## Structure rules
Landing + three dives per standard chapter. M0 is the overview chapter and
opens into three dives (the impossible, the menu, the mesh). The four
strategies are M2–M5; M5 (segmentation) is the heart. M8 is the synthesis.
Each landing presents the four doors (`/art`, `/bcs`, `/echomq`,
`/elixir`) and carries the `MSH…` Snowflake stamp.

## Ship loop tail
After the sweep passes: update mesh.toc.md (status, link the file, dive
tally), record any supersession as an inline TOC amendment naming what it
replaces, refresh the production archive, copy deliverables to
/mnt/user-data/outputs/, present_files with the new page first. When the
user asks for the article, also include its markdown in the response.

Archive refresh (adjust paths if the corpus moved):
cd /home/claude && rm -f /mnt/user-data/outputs/mesh.zip && \
zip -r /mnt/user-data/outputs/mesh.zip mesh -x "*/.DS_Store" -x "__MACOSX/*"
