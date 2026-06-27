import { Button, Card, Checkbox, Divider, Icon, Input, Link } from "@mercury/ui";
import { createForm, toast } from "@mercury/effector";
import { useState } from "react";
import { Page, PageHead } from "../../chrome/Page";

/* The sign-in model lives at module scope — the Effector store outlives any
 * single render, the same way a real consumer would wire a form. */
const signIn = createForm({
  initialValues: { email: "", password: "" },
  validate: (v) => {
    const e: { email?: string; password?: string } = {};
    if (!v.email) e.email = "Email is required";
    else if (!/.+@.+\..+/.test(v.email)) e.email = "Enter a valid email";
    if (v.password.length < 8) e.password = "Use at least 8 characters";
    return e;
  },
});

export function SignInPage() {
  const email = signIn.useField("email");
  const password = signIn.useField("password");
  const form = signIn.useForm();
  const [remember, setRemember] = useState(false);

  function submit() {
    form.submit();
    if (form.isValid) toast.success("Signed in");
    else toast.error("Check the highlighted fields");
  }

  return (
    <Page>
      <PageHead
        eyebrow="Patterns"
        title="Sign-in form"
        lede="A realistic form composed entirely from Mercury primitives."
      />

      <div style={{ maxWidth: 420 }}>
        <Card variant="raised" padding={32}>
          <div style={{ marginBottom: 20 }}>
            <h2 style={{ font: "700 22px/1.2 var(--font-primary)", margin: "0 0 6px", letterSpacing: "-0.01em" }}>
              Sign in to Mercury
            </h2>
            <p style={{ font: "400 14px/20px var(--font-primary)", color: "rgb(var(--fg-secondary))", margin: 0 }}>
              New here? <Link size="sm">Create an account</Link>
            </p>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: 14, marginBottom: 20 }}>
            <Input
              label="Email"
              type="email"
              placeholder="you@company.com"
              leading={<Icon name="mail" size={14} />}
              value={email.value}
              error={email.error}
              onChange={(e) => email.onChange(e.target.value)}
              onBlur={email.onBlur}
            />
            <Input
              label="Password"
              type="password"
              placeholder="••••••••"
              value={password.value}
              error={password.error}
              onChange={(e) => password.onChange(e.target.value)}
              onBlur={password.onBlur}
            />
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <Checkbox checked={remember} onChange={setRemember} label="Remember me" />
              <Link size="sm">Forgot password?</Link>
            </div>
          </div>

          <Button fullWidth size="lg" onClick={submit}>
            Sign in
          </Button>

          <div style={{ margin: "20px 0" }}>
            <Divider label="or" />
          </div>

          <Button variant="secondary" fullWidth size="lg">
            Continue with SSO
          </Button>
        </Card>
      </div>
    </Page>
  );
}
