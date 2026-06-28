# AuthLayout — the branded split-screen auth shell

The split-screen shell for authentication flows: a prop-driven brand panel on the left (hidden on narrow
widths) and a centred form column on the right with an eyebrow / heading / subheading, a `children` body,
and a `footer` slot. Fills its parent (`height: 100%`), so it works framed in a demo or as a full page.
Reach for it to host any sign-in / register / reset / verify screen. Import:
`import { AuthLayout } from "@mercury/ui"`.

## Props

| Prop | Type | Default | Notes |
|---|---|---|---|
| `eyebrow` | `string` | — | Small label above the heading (e.g. "Welcome back"). |
| `heading` | `ReactNode` | — | The form `<h1>`. |
| `subheading` | `ReactNode` | — | Supporting line under the heading. |
| `children` | `ReactNode` | — | The form body (inputs, buttons, dividers). |
| `footer` | `ReactNode` | — | Footer row under the form (e.g. "New here? Create an account"). |
| `brand` | `ReactNode` | — | Replaces the brand-panel body wholesale (overrides `brandTagline` / `brandFeatures`). |
| `brandName` | `string` | `"Mercury"` | Wordmark in the brand panel top. |
| `brandBadge` | `string` | `"UI"` | Small badge beside the wordmark; hidden when empty. |
| `brandLogo` | `ReactNode` | `DEFAULT_LOGO` | The logo glyph (defaults to the Mercury bolt SVG). |
| `brandTagline` | `ReactNode` | `"The design system for your whole product."` | Brand-panel headline (shown unless `brand` is set). |
| `brandFeatures` | `string[]` | `DEFAULT_FEATURES` | Checked feature bullets (shown unless `brand` is set). |
| `brandStatus` | `string` | `"All systems operational"` | Status line in the brand-panel foot. |
| `brandVersion` | `string` | `"v2.4.0"` | Version chip in the foot; hidden when empty. |
| `className` | `string` | — | Extra classes merged onto the root. |

Not a `forwardRef` / `…rest` component — the prop set above is the whole surface (no native-attr
pass-through). The brand-panel defaults make a complete screen from `eyebrow` / `heading` / `subheading`
/ `children` / `footer` alone.

## Composition

AuthLayout is the rich composer at the top of the layout group — its body (`children`) and `footer` hold
the form primitives. Verified against the five `AuthFlowPage` screens:

- **Composes:** [Button](../../actions/Button/Button.prompt.md) (the submit / SSO action),
  [Input](../../inputs/Input/Input.prompt.md) (the fields),
  [AuthCode](../../inputs/AuthCode/AuthCode.prompt.md) (the verify screen's 6-digit code),
  [Checkbox](../../selection/Checkbox/Checkbox.prompt.md) ("Keep me signed in" / "I agree"),
  [Checklist](../../data-display/Checklist/Checklist.prompt.md) (the reset-screen password rules),
  [PasswordStrength](../../feedback/PasswordStrength/PasswordStrength.prompt.md) (the register meter),
  [Alert](../../feedback/Alert/Alert.prompt.md) (the forgot-screen "reset link sent" state),
  [Divider](../../foundations/Divider/Divider.prompt.md) (the "or sign in with email" separator), and
  [Link](../../actions/Link/Link.prompt.md) (the `footer` affordance, in the body's form rows).
- **Composed by:** nothing in `@mercury/ui` — it is the top-level layout shell; the auth *pages* / app
  shells mount it (e.g. `AuthFlowPage`).

## Examples

```tsx
// Sign in — eyebrow / heading / subheading / footer + a body of primitives
<AuthLayout
  eyebrow="Welcome back"
  heading="Sign in to your console"
  subheading="Manage queues, jobs and processors across your connections."
  footer={<p style={footStyle}>New here? <Link size="sm">Create an account</Link></p>}
>
  <Button variant="secondary" size="lg" fullWidth>Continue with Google</Button>
  <Divider label="or sign in with email" />
  <Input label="Email" type="email" value={email.value} onChange={…} />
  <Input label="Password" type="password" value={password.value} onChange={…} />
  <Button size="lg" fullWidth loading={form.submitting} onClick={() => signInForm.submit()}>Sign in</Button>
</AuthLayout>
// showcase/src/pages/patterns/AuthFlowPage.tsx

// Verify — a code screen with a centred back-link footer
<AuthLayout
  eyebrow="Verify it's you"
  heading="Enter your code"
  subheading="We sent a 6-digit code to you@company.com. It expires in 10 minutes."
  footer={<p style={{ ...footStyle, textAlign: "center" }}><Link size="sm" leading={<span aria-hidden="true">←</span>}>Use a different account</Link></p>}
>
  <AuthCode value={code} onChange={setCode} onComplete={complete} length={6} error={error} />
  <Button size="lg" fullWidth loading={submitting} disabled={code.length < 6} onClick={() => complete(code)}>Verify</Button>
</AuthLayout>
// showcase/src/pages/patterns/AuthFlowPage.tsx
```

The five screens — Sign in, Register, Forgot, Reset, Verify — all reuse the one shell, varying only
`eyebrow` / `heading` / `subheading` / `children` / `footer`.

## Notes

- **The brand panel is prop-driven** — pass nothing and you get the Mercury defaults (wordmark, tagline,
  three feature bullets, status + version). Pass `brand` to replace the whole brand body; the top
  (`brandName` / `brandBadge` / `brandLogo`) and foot (`brandStatus` / `brandVersion`) still render
  around it.
- **`brandBadge` / `brandVersion` hide when empty** (`""`), so an unbranded shell drops them cleanly.
- **Semantics** — the heading renders as `<h1>`, so AuthLayout owns the page's top heading; don't nest a
  second `<h1>` in `children`.
- **Sizing** — it fills its parent at `height: 100%`; the call site frames it in a fixed-height,
  rounded, overflow-hidden box for the demo. The left brand panel is hidden at narrow widths.
