# Monetization Playbook

How to turn the course system into revenue without compromising what makes it good. The thesis: you have built a *production system*, not just a course, and its economics — high fixed cost already paid, near-zero marginal cost per course and per visitor — point squarely at a high-margin digital catalog.

## 1. The asset and its economics

What the toolkit actually is, in business terms:

- **A repeatable factory.** A new subject becomes a polished, interactive, mobile-friendly course at low marginal cost, because every page is config-as-data on a shared system.
- **Near-zero serving cost.** Pages are self-contained static HTML with no images and no backend, so hosting is effectively free and infinitely scalable on a CDN.
- **Durable inventory.** For stable subjects (school physics, core math) the content is evergreen; it earns for years with little maintenance.

| Cost line | Where it sits | Implication |
|-----------|---------------|-------------|
| Toolkit & design system | Fixed, already paid | Sunk; every future course rides it for free |
| Per-course authoring | Low, repeatable | A catalog is cheap to grow |
| Hosting / serving | Near zero (static, no images) | Margin barely moves with traffic |
| Maintenance | Low for evergreen, higher for spec-bound (e.g. exam) | Choose subjects with this in mind |

> **The moat is speed, consistency, interactivity, and verified-math trust** — a catalog that all feels like one trustworthy product, shipped faster than hand-built competitors and cheaper to run.

## 2. Packaging — what to sell

Several products come out of the same pages; you can run more than one.

| Package | What the buyer gets | Best for |
|---------|---------------------|----------|
| **Single course** (one-time) | Lifetime access to one course | Low-commitment first purchase |
| **Track / bundle** (one-time) | A themed set (e.g. all applied-math courses) | Higher AOV, natural cross-sell |
| **Subscription** | The whole catalog, plus new courses as they ship | The flywheel: more courses → more value |
| **Freemium** | Free opening chapters; pay to unlock the rest | Top-of-funnel reach; the static structure makes gating trivial |
| **Certificate / exam pass** | The scored final test, certified | A cheap, high-perceived-value add-on |
| **Tutor / school edition** | Answer keys, lesson plans, assignable quizzes | B2B / B2I margins |
| **White-label / licensing** | The course (or toolkit output) under someone else's brand | Schools, tutoring chains, edtech platforms |

> **Lead with freemium + a certified finale.** Free chapters get people in and let the interactives sell themselves; the paywalled remainder plus a certifiable final test is the natural conversion point.

## 3. Pricing

- **One-time vs subscription.** One-time suits a single exam-prep course bought in a hurry; subscription suits a growing catalog a learner returns to. Many catalogs run both: buy a course outright, or subscribe for everything.
- **Tiered anchors.** A three-tier ladder reads clearly: *Basic* (content only) → *Plus* (+ certificate, printable workbook) → *Pro* (+ support / tutor edition). The middle tier is the target; the top tier makes it look reasonable.
- **Regional / purchasing-power pricing.** For the Russian-language market, price to local willingness-to-pay rather than to a Western anchor; the near-zero marginal cost gives full freedom here.
- **Seasonality.** Exam-prep demand spikes before the exam window — time launches, bundles, and discounts to that calendar.
- **Discount levers.** Launch pricing, referral credit, group/family and classroom bulk rates. Keep the list price stable and discount transparently rather than discounting the anchor.

## 4. Distribution and channels

| Channel | Reach | Margin | Notes |
|---------|-------|--------|-------|
| **Direct (own site)** | You build it | Highest | The course *is* the funnel — the home page is the landing page |
| **Marketplaces** (Stepik-style and similar) | High, built-in | Lower (rev-share) | Reach vs take-rate trade-off; good for discovery |
| **B2B / B2I** | Schools, tutors, libraries | High (site licences) | Recurring, low-churn, few-but-large deals |
| **Affiliate / ambassadors** | Tutor and teacher networks | Pay-per-result | Aligns cost with revenue |

> **Each module is an SEO asset.** A module page answers a concrete, searched question — "как считать счёт за электричество", "что делает стабилизатор напряжения" — and then converts the reader into the course. The whole catalog is organic top-of-funnel.

> **The calculators are shareable on their own.** The bill calculator, the appliance-load table, the UPS-runtime tool — packaged as standalone embeddable widgets — are link-bait and backlinks that funnel toward the paid course. They are the cheapest marketing you already own.

## 5. Conversion mechanics the toolkit already enables

The product is also the sales engine. Several mechanics are already in the pages or one small step away.

- **Try-before-buy is built in.** The interactives are the hook; a reader who has *used* the calculator is far closer to buying than one who read a description.
- **Freemium gating is nearly free.** Because pages are static and independent, shipping chapters 1–2 free and gating the rest is a matter of not linking (or lightly gating) the later pages — no re-architecture.
- **The scored final test becomes a certifiable exam.** It already tallies a score and grade; wrap a certificate around a passing score and you have a paid outcome, not just content.
- **Habit drives retention.** Progress and per-question state already persist locally; promote that into streaks and cross-device progress (with accounts) and you have the retention loop a subscription needs.

## 6. Value-added revenue layers

Layers that add margin on top of the core content, each cheap to produce because the toolkit already exists.

- **Certificates of completion.** Tie a certificate to the final-test score. Give each certificate a **branded, verifiable ID** — a namespaced base62 Snowflake (e.g. `CRT…`) — so it can be looked up and trusted; this slots directly into a Snowflake-ID backend.
- **Printable workbooks / PDFs.** A print stylesheet (`@media print`) turns the existing content into a formula cheat-sheet, an appliance-power table, and a safety checklist — a paid download with near-zero production cost.
- **Tutor / teacher edition.** Answer keys, lesson plans, and assignable quizzes sold to the people who teach with the material.
- **Localization.** The same toolkit re-skinned into another language is a new market for the cost of translation, not the cost of a new course.
- **Sponsorship — carefully.** A relevant brand (say, a stabiliser or UPS maker for that chapter) could sponsor content, but only with full disclosure and zero editorial influence; the trust signal is worth more than the cheque.

## 7. The backend that unlocks the upper tiers

The course core should stay static, cheap, and durable. Monetization that needs state is added as a **thin dynamic layer around** that core, not baked into it.

| Capability | Why | Note |
|------------|-----|------|
| Accounts + cross-device progress | Subscriptions need identity and continuity | The natural step beyond localStorage |
| Payments / subscriptions | The actual revenue | Stripe or a regional processor (e.g. YooKassa for RU) |
| Attempt & score tracking | Certificates, analytics, leaderboards | Learner, attempt, and certificate IDs as **branded Snowflakes** (namespace prefix + base62), matching the existing stack |
| Light auth / gating | Premium-page access | Keep it light — the value is the content, not the wall |
| Analytics | Know which modules convert and where readers drop off | Drives both pricing and catalog sequencing |

> **Architectural rule: protect the static core.** Auth, payments, and progress are a small service that *wraps* the pages. The pages stay framework-free, image-free, and instantly cacheable — that is the cost and durability advantage, and it should survive monetization intact.

## 8. Catalog and portfolio strategy

The single course is the unit of sale; the **catalog** is the asset.

- **Compounding subscription value.** Each new course is cheap to add and makes the subscription worth more, which is the whole point of owning a factory rather than a single product.
- **Sequence by demand.** Build the courses with the highest search demand and exam relevance first; let analytics and SEO data order the backlog.
- **Cross-sell within the catalog.** Finish the physics course → recommend the personal-finance course; the linear-chain navigation already trains readers to "continue".
- **A unifying brand.** Frame the whole line as *school physics and mathematics as a practical tool*. The applied lineup — logic and decision-making, everyday law, personal finance, entrepreneurship, learning science — reads as one coherent product family, which is itself a marketing and pricing advantage.

## 9. Trust as a marketing asset

The quality gates are not just engineering hygiene; they are claims you can put on the box, and every one is literally true of the product:

- **"Every number is verified."** (The math verifier and the figure-equals-figure rule.)
- **"Works on your phone, loads instantly."** (Static, image-free, self-contained.)
- **"No ads, no tracking."** (Nothing phones home.)
- **"Consistent A+ quality across the catalog."** (The same gates pass on every page of every course.)

In a market full of thin, ad-stuffed exam-prep sites, *verified, fast, ad-free, consistent* is a genuine differentiator — and it is free, because it is already true.

## 10. Risks and guardrails

- **Do not trade pedagogy for conversion.** No dark patterns, no manufactured urgency, no shaming the low scorer. The wellbeing-by-design stance is also good business — trust compounds, tricks don't.
- **Balance the free tier.** Too little free content starves the funnel; too much removes the reason to pay. The opening chapters plus the live calculators is usually the right free surface.
- **Marketplace dependence.** Discovery on a third-party platform is rented reach; keep the direct channel strong so a policy or rev-share change is not existential.
- **Freshness for spec-bound subjects.** Evergreen subjects barely age; exam-aligned ones (EGE) must track the current specification, which is a real, ongoing maintenance commitment to budget for.

## 11. A phased starter plan

A pragmatic sequence that earns before it invests.

> **Phase 1 — Sell what exists, directly.** Ship one or two flagship courses with chapters 1–2 free and the rest paid, a certifiable final test, and a printable workbook upsell. Sell on your own site; lean on per-module SEO and shareable calculator widgets for traffic. Minimal backend: a light gate and a payment link.

> **Phase 2 — Add the engine.** Introduce accounts, payments, and cross-device progress as a thin layer around the static pages. Launch the subscription and the track bundles; start measuring module-level conversion.

> **Phase 3 — Scale the catalog and the channels.** Expand the course lineup in demand order, open B2B/B2I licensing to schools and tutoring centres, and localize the strongest courses into new languages. Add certificates with branded, verifiable IDs.

The throughline of all three phases: the static, verified, fast course core never changes — everything monetizable is layered around it.
