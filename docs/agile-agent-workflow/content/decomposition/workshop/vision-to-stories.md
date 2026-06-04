# A2.07.1 · Vision to stories

- **Route:** `/course/agile-agent-workflow/decomposition/workshop/vision-to-stories`
- **File:** `html/agile-agent-workflow/decomposition/workshop/vision-to-stories.html`
- **Role:** dive 1 of the workshop. Vision → a first story set, applying A2.01–A2.04 in sequence.
- **Accent:** elixir-purple.

## Lead

The vision is one sentence: learners enrol in a course and study it. This dive runs the first four A2 moves
on it — value not tasks, the Connextra form, INVEST, and Given/When/Then — and the output is a first story
set. Not the final backlog: some stories will still be too big. That is the input to the next dive.

## Worked Portal example (the sequence)

1. **Value, not tasks (A2.01).** The vision implies chores — "add a courses table", "build a Phoenix route".
   Those are not stories. Restate each as a change in what a role can do: a learner *browses the catalogue*,
   a learner *enrols in a course*, a learner *opens a lesson*, a learner *tracks progress*. Four candidates,
   each demonstrable.
2. **The Connextra form (A2.02).** Write each as role, want, reason — for example: "As a learner, I want to
   enrol in a course, so that it is added to my courses and I can study it." The value sits on the card.
3. **INVEST (A2.03).** Score each candidate against the six tests. "Browse the catalogue", "enrol", and
   "open a lesson" pass all six. "Track progress through a course" passes value and testable but fails Small
   — it spans every lesson and every surface. It is kept as a story but flagged too-big.
4. **Given/When/Then (A2.04).** Pin each ready story with one concrete scenario, the executable definition of
   done — for enrol: "Given a learner viewing a course, when they enrol, then the course appears in their
   courses." An agent and a test read the same line.

Output: four stories in role-want-reason form, three ready, one flagged too-big — the first story set.

## Hero interactive — the four moves on one candidate

**Run the pipeline on one Portal item.** A control switches between four candidates (browse, enrol, open a
lesson, track progress). The figure shows the item at four stages — raw chore, value story, INVEST score,
acceptance scenario — and the readout reports what each move produced and whether the result is ready or
still too-big.

- control ids: `#v2sItem` (segmented, `data-k` = browse|enrol|lesson|track)
- pure function: `pipelineFor(itemKey) -> { story, invest:{pass,fail}, ready:bool, scenario }`
- sample readout: "enrol in a course — value story written, INVEST 6/6, acceptance: Given a learner viewing a course, when they enrol, then the course appears in their courses. Ready to hand to the Author."

## Main interactive — INVEST gate over the first story set

**Score the whole first set.** A row of four stories; each is scored against INVEST and marked ready or
too-big. A live count reports how many of the set are rung-ready and which one is the input to splitting.
Pure function `scoreSet()` over the fixed dataset.

- control ids: `#v2sStory` (segmented, pick which story to read in detail)
- pure function: `investScore(itemKey) -> { pass:int, fail:[letters], ready:bool }`
- sample readout: "track progress through a course — passes 4/6. Fails S (Small) and the Estimable that follows: it spans every lesson and surface. Kept as a story, flagged for splitting in A2.07.2. First set: 3 of 4 ready."

## Principle ↔ practice bridge

- principle: a vision is decomposed by applying the story disciplines in order — value, form, readiness,
  acceptance — not by guessing at tasks.
- practice: the Portal vision yields four candidate stories; three pass INVEST with a Given/When/Then; one
  ("track progress") fails Small and is carried into splitting.
- take: the first story set is the vision run through four moves — most of it ready, the rest named for repair.

## References (Sources — real, vetted)

- Cohn, M. — *User Stories Applied* — https://www.mountaingoatsoftware.com/books/user-stories-applied
- Adzic, G. — *Specification by Example* — https://gojko.net/books/specification-by-example/
- Humble & Farley — *Continuous Delivery* — https://continuousdelivery.com/

## Related (internal — must resolve)

- A2.01 value, A2.02 connextra, A2.03 invest; workshop hub; A2 landing; `/elixir/course`
- A2.07.2 split-and-test (next dive)
- (A2.04 named in prose only — not linked.)

## Pager

- prev: workshop hub `/course/agile-agent-workflow/decomposition/workshop`
- next: `/course/agile-agent-workflow/decomposition/workshop/split-and-test`
