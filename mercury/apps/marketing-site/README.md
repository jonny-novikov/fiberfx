# Mercury — Marketing UI Kit

A landing-page recreation for Mercury, built on the same primitives (colors, type, radii, shadows) as the app kit, tuned for a more editorial/marketing feel via the DM Serif Display family on headlines.

## Files
- `index.html` — full page: nav → hero → logos → features → pricing → quote → CTA → footer, with a working "Get started" modal.
- `components.jsx` — `MkNav`, `MkHero`, `MkLogos`, `MkFeatures`, `MkPricing`, `MkQuote`, `MkCta`, `MkFooter`, `MkSignup`, shared `MkButton` + `MkIcon`.
- `styles.css` — scoped marketing styles prefixed `mk-`.

## Sections
1. **Sticky glass nav** with brand, links, sign-in + dark "Get started" CTA.
2. **Hero** — serif-italic headline, lede, dual CTAs, gradient card mock on the right.
3. **Logos strip** — wordmark placeholders to show social proof rhythm.
4. **Features grid** — 3×2 feature cards with Lucide icons and the iris accent.
5. **Pricing** — Personal / Plus (highlighted, dark) / Teams.
6. **Testimonial** — full-width dark section with serif pull-quote.
7. **CTA banner** — gradient iris→indigo block.
8. **Footer** with four columns + legal strip.

## Interactions
- Clicking any "Get started" / "Create account" / "Start trial" opens the `MkSignup` modal with email input and a fake magic-link success state.

## Notes
- Logo strip uses plain wordmarks as placeholders — swap in partner logos if/when available.
- Hero card-mock currencies and copy are illustrative.
