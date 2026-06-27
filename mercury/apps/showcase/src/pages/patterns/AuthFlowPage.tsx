import { useState } from "react";
import type { ComponentType } from "react";
import {
  Alert,
  AuthCode,
  AuthLayout,
  Button,
  Checkbox,
  Checklist,
  Divider,
  Input,
  Link,
  PasswordStrength,
  Segmented,
} from "@mercury/ui";
import { createCooldown, createForm, passwordStrength, toast } from "@mercury/effector";
import { Page, PageHead, Section } from "../../chrome/Page";

/* The whole auth flow, mercurized: one AuthLayout shell, the new Link /
 * Divider / PasswordStrength / Checklist primitives, and the @mercury/effector
 * plug doing the work — createForm with an async onSubmit drives every
 * loading + validation state; passwordStrength scores the meter and the rules;
 * createCooldown runs the resend timer. Stores live at module scope, the way a
 * real consumer would wire them. */

const wait = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

type Screen = "signin" | "register" | "forgot" | "reset" | "verify";

const SCREENS: { value: Screen; label: string }[] = [
  { value: "signin", label: "Sign in" },
  { value: "register", label: "Register" },
  { value: "forgot", label: "Forgot" },
  { value: "reset", label: "Reset" },
  { value: "verify", label: "Verify" },
];

const isEmail = (s: string) => /.+@.+\..+/.test(s);

/* ───────── models ───────── */

const signInForm = createForm({
  initialValues: { email: "", password: "" },
  validate: (v) => {
    const e: { email?: string; password?: string } = {};
    if (!v.email) e.email = "Email is required";
    else if (!isEmail(v.email)) e.email = "Enter a valid email";
    if (v.password.length < 8) e.password = "Use at least 8 characters";
    return e;
  },
  onSubmit: async (v) => {
    await wait(700);
    toast.success(`Signed in as ${v.email}`, { title: "Welcome back" });
  },
});

const registerForm = createForm({
  initialValues: { name: "", email: "", org: "", password: "" },
  validate: (v) => {
    const e: Record<string, string> = {};
    if (!v.name) e.name = "Your name is required";
    if (!v.email) e.email = "Work email is required";
    else if (!isEmail(v.email)) e.email = "Enter a valid email";
    if (v.password.length < 8) e.password = "Use at least 8 characters";
    return e;
  },
  onSubmit: async (v) => {
    await wait(800);
    toast.success("Workspace is ready to go.", { title: `Welcome, ${v.name}` });
  },
});

const forgotForm = createForm({
  initialValues: { email: "" },
  validate: (v) => (!v.email ? { email: "Email is required" } : !isEmail(v.email) ? { email: "Enter a valid email" } : {}),
  onSubmit: async () => {
    await wait(700);
  },
});

const resetForm = createForm({
  initialValues: { password: "", confirm: "" },
  validate: (v) => {
    const e: { password?: string; confirm?: string } = {};
    if (v.password.length < 8) e.password = "Must be at least 8 characters";
    if (v.confirm.length > 0 && v.confirm !== v.password) e.confirm = "Passwords don't match";
    return e;
  },
  onSubmit: async () => {
    await wait(700);
    toast.success("You can now sign in with it.", { title: "Password updated" });
  },
});

const resendCooldown = createCooldown();

/* ───────── screens ───────── */

function SignIn() {
  const email = signInForm.useField("email");
  const password = signInForm.useField("password");
  const form = signInForm.useForm();
  const [remember, setRemember] = useState(true);

  return (
    <AuthLayout
      eyebrow="Welcome back"
      heading="Sign in to your console"
      subheading="Manage queues, jobs and processors across your connections."
      footer={
        <p style={footStyle}>
          New here? <Link size="sm">Create an account</Link>
        </p>
      }
    >
      <Button variant="secondary" size="lg" fullWidth>
        Continue with Google
      </Button>
      <Divider label="or sign in with email" />
      <Input
        label="Email"
        type="email"
        placeholder="you@company.com"
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
      <div style={rowStyle}>
        <Checkbox checked={remember} onChange={setRemember} label="Keep me signed in" />
        <Link size="sm">Forgot password?</Link>
      </div>
      <Button size="lg" fullWidth loading={form.submitting} onClick={() => signInForm.submit()}>
        Sign in
      </Button>
    </AuthLayout>
  );
}

function Register() {
  const name = registerForm.useField("name");
  const email = registerForm.useField("email");
  const org = registerForm.useField("org");
  const password = registerForm.useField("password");
  const form = registerForm.useForm();
  const [agree, setAgree] = useState(false);
  const strength = passwordStrength(password.value);

  return (
    <AuthLayout
      eyebrow="Get started"
      heading="Create your account"
      subheading="Spin up a workspace and connect your first broker in minutes."
      footer={
        <p style={footStyle}>
          Already have an account? <Link size="sm">Sign in</Link>
        </p>
      }
    >
      <Input
        label="Full name"
        placeholder="Ada Lovelace"
        value={name.value}
        error={name.error}
        onChange={(e) => name.onChange(e.target.value)}
        onBlur={name.onBlur}
      />
      <Input
        label="Work email"
        type="email"
        placeholder="you@company.com"
        value={email.value}
        error={email.error}
        onChange={(e) => email.onChange(e.target.value)}
        onBlur={email.onBlur}
      />
      <Input
        label="Organisation"
        placeholder="ACME Corp"
        hint="This becomes your workspace name."
        value={org.value}
        onChange={(e) => org.onChange(e.target.value)}
      />
      <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
        <Input
          label="Password"
          type="password"
          placeholder="At least 8 characters"
          value={password.value}
          error={password.error}
          onChange={(e) => password.onChange(e.target.value)}
          onBlur={password.onBlur}
        />
        {password.value && <PasswordStrength score={strength.score} label={strength.label} variant={strength.variant} />}
      </div>
      <Checkbox checked={agree} onChange={setAgree} label="I agree to the Terms and Privacy Policy." />
      <Button size="lg" fullWidth loading={form.submitting} disabled={!agree} onClick={() => registerForm.submit()}>
        Create account
      </Button>
    </AuthLayout>
  );
}

function Forgot() {
  const email = forgotForm.useField("email");
  const form = forgotForm.useForm();
  const [sent, setSent] = useState(false);

  async function send() {
    if (await forgotForm.submit()) setSent(true);
  }

  return (
    <AuthLayout
      eyebrow="Account recovery"
      heading={sent ? "Check your inbox" : "Reset your password"}
      subheading={sent ? undefined : "Enter the email tied to your account and we'll send a reset link."}
      footer={
        <p style={{ ...footStyle, textAlign: "center" }}>
          <Link size="sm" leading={<span aria-hidden="true">←</span>}>
            Back to sign in
          </Link>
        </p>
      }
    >
      {sent ? (
        <>
          <Alert tone="success" title="Reset link sent">
            We sent a reset link to <b>{email.value}</b>. The link expires in 30 minutes.
          </Alert>
          <Button variant="secondary" size="lg" fullWidth onClick={() => setSent(false)}>
            Use a different email
          </Button>
        </>
      ) : (
        <>
          <Input
            label="Email"
            type="email"
            placeholder="you@company.com"
            value={email.value}
            error={email.error}
            onChange={(e) => email.onChange(e.target.value)}
            onBlur={email.onBlur}
          />
          <Button size="lg" fullWidth loading={form.submitting} onClick={send}>
            Send reset link
          </Button>
        </>
      )}
    </AuthLayout>
  );
}

function Reset() {
  const password = resetForm.useField("password");
  const confirm = resetForm.useField("confirm");
  const form = resetForm.useForm();
  const { rules } = passwordStrength(password.value);

  return (
    <AuthLayout
      eyebrow="Almost there"
      heading="Set a new password"
      subheading="Choose a strong password you don't use anywhere else."
      footer={
        <p style={{ ...footStyle, textAlign: "center" }}>
          <Link size="sm" leading={<span aria-hidden="true">←</span>}>
            Back to sign in
          </Link>
        </p>
      }
    >
      <Input
        label="New password"
        type="password"
        placeholder="At least 8 characters"
        value={password.value}
        error={password.error}
        onChange={(e) => password.onChange(e.target.value)}
        onBlur={password.onBlur}
      />
      <Input
        label="Confirm password"
        type="password"
        placeholder="Re-enter password"
        value={confirm.value}
        error={confirm.error}
        onChange={(e) => confirm.onChange(e.target.value)}
        onBlur={confirm.onBlur}
      />
      <Checklist
        items={[
          { label: "8+ characters", met: rules.length },
          { label: "Upper & lower case", met: rules.mixedCase },
          { label: "A number", met: rules.number },
        ]}
      />
      <Button size="lg" fullWidth loading={form.submitting} onClick={() => resetForm.submit()}>
        Update password
      </Button>
    </AuthLayout>
  );
}

function Verify() {
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const remaining = resendCooldown.useCooldown();

  function complete(value: string) {
    setError("");
    setSubmitting(true);
    setTimeout(() => {
      setSubmitting(false);
      if (value === "000000") {
        setError("That code is invalid or expired.");
        setCode("");
      } else {
        toast.success("Your email is verified.", { title: "Verified" });
      }
    }, 700);
  }

  return (
    <AuthLayout
      eyebrow="Verify it's you"
      heading="Enter your code"
      subheading="We sent a 6-digit code to you@company.com. It expires in 10 minutes."
      footer={
        <p style={{ ...footStyle, textAlign: "center" }}>
          <Link size="sm" leading={<span aria-hidden="true">←</span>}>
            Use a different account
          </Link>
        </p>
      }
    >
      <AuthCode value={code} onChange={setCode} onComplete={complete} length={6} error={error} />
      <Button size="lg" fullWidth loading={submitting} disabled={code.length < 6} onClick={() => complete(code)}>
        Verify
      </Button>
      <p style={{ ...footStyle, textAlign: "center" }}>
        Didn't get it?{" "}
        <Link size="sm" disabled={remaining > 0} onClick={() => resendCooldown.start(30)}>
          {remaining > 0 ? `Resend in ${remaining}s` : "Resend code"}
        </Link>
      </p>
    </AuthLayout>
  );
}

const SCREEN_VIEWS: Record<Screen, ComponentType> = {
  signin: SignIn,
  register: Register,
  forgot: Forgot,
  reset: Reset,
  verify: Verify,
};

const footStyle = { margin: 0, font: "400 14px/1.4 var(--font-primary)", color: "rgb(var(--fg-secondary))" } as const;
const rowStyle = { display: "flex", alignItems: "center", justifyContent: "space-between" } as const;

export function AuthFlowPage() {
  const [screen, setScreen] = useState<Screen>("signin");
  const View = SCREEN_VIEWS[screen];

  return (
    <Page>
      <PageHead
        eyebrow="Patterns"
        title="Auth flow"
        lede="Five screens, one AuthLayout shell. Composed from Mercury primitives and driven entirely by the @mercury/effector plug — async forms, password scoring and a resend cooldown."
      />

      <Section title="Screens" hint="Switch between the flow's steps." />
      <div style={{ marginBottom: 16 }}>
        <Segmented segments={SCREENS} value={screen} onChange={setScreen} />
      </div>

      <div
        style={{
          height: 620,
          border: "1px solid rgb(var(--border-secondary))",
          borderRadius: 16,
          overflow: "hidden",
          boxShadow: "var(--shadow-200)",
        }}
      >
        <View />
      </div>
    </Page>
  );
}
