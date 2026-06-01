# Course Creation System

A repeatable method for turning a subject into a polished, interactive, mobile-friendly online course — built as self-contained static HTML on one shared design system, with every number verified and every page held to a fixed quality bar.

This documentation captures the **principles** behind that method, the **toolkit** that enforces them, and the **business** thinking for turning the output into a product. It is written to be subject-agnostic: the running examples come from the «Электричество и устройства» physics course, but the same system already powers a lineup of applied-math courses (logic, law, personal finance, entrepreneurship, learning science) and ports cleanly to any new subject.

## What the system produces

A course is a tree of static pages, all cut from the same design system and graded against the same gates:

```text
Course
├─ Home (hub: hero + chapter grid + finale block)
├─ Chapter 1 … Chapter N
│   ├─ Landing (hero formula, module tiles, quiz CTA)
│   ├─ Module 1 … Module M  (4 sections + 1 interactive + 5-question quiz)
│   └─ Chapter quiz (8 questions)
└─ Finale (un-numbered: recap landing + final test with score tally)
```

Every page is plain HTML with no external assets, no images, no tracking, and no build-time framework — it loads instantly, works on a phone, and can be hosted anywhere.

## Reading order

| # | Document | What it covers | Read it when |
|---|----------|----------------|--------------|
| 1 | [Course Creation Principles](course-creation-principles.md) | Pedagogy, the anatomy of a chapter / module / quiz, the interactive component taxonomy, and the authoring workflow | You are designing course content |
| 2 | [Toolkit & Quality Gates](toolkit-and-quality-gates.md) | The generators, the strict build cycle, KaTeX strict-mode rules, the validator harness, and the regression discipline | You are building or extending the machinery |
| 3 | [Monetization Playbook](monetization-playbook.md) | Packaging, pricing, distribution, the conversion mechanics the toolkit already enables, and a phased starter plan | You are turning the catalog into revenue |

## The one-paragraph philosophy

Teach the concrete before the abstract; let one formula do a lot of work; replace prose with a calculator wherever a reader would rather *try* than read; prove every displayed number in code before it ships; and hold every page to the same non-negotiable bar so the whole catalog feels like one trustworthy product. The toolkit exists so that none of this depends on memory or discipline alone — the gates fail loudly when a rule is broken.
