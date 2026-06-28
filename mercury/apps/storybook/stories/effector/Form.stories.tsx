import type { Meta, StoryObj } from "@storybook/react-vite";
import { createForm } from "@mercury/effector";
import { Input, Button } from "@mercury/ui";

// "Effector/Form" — createForm driving presentational Inputs + a submit Button.
// NO-INVENT: symbols traced from packages/mercury-effector/src/form.ts
// (createForm → { useField, useForm, submit, ... }; useField → { value, error,
// onChange (VALUE-based), onBlur }; useForm → { isValid, submitting, ... }).
// Input props traced from Input.tsx (label/value/onChange (DOM event)/onBlur/
// error); Button props from Button.tsx (type/loading/disabled). Mirrors the
// proven wiring in apps/showcase/src/pages/patterns/AuthFlowPage.tsx. Models
// live at module scope; hooks read inside the render component. Cross-component
// story — no `component:`.

const wait = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));
const isEmail = (v: string) => /.+@.+\..+/.test(v);

const signInForm = createForm({
  initialValues: { email: "", password: "" },
  validate: (v) => {
    const e: { email?: string; password?: string } = {};
    if (!v.email) e.email = "Email is required";
    else if (!isEmail(v.email)) e.email = "Enter a valid email";
    if (v.password.length < 8) e.password = "Use at least 8 characters";
    return e;
  },
  onSubmit: async () => {
    await wait(800);
  },
});

const newsletterForm = createForm({
  initialValues: { email: "" },
  validate: (v) => (!v.email ? { email: "Email is required" } : !isEmail(v.email) ? { email: "Enter a valid email" } : {}),
  onSubmit: async () => {
    await wait(600);
  },
});

const meta: Meta = {
  title: "Effector/Form",
};
export default meta;

type Story = StoryObj;

function SignInDemo() {
  const email = signInForm.useField("email");
  const password = signInForm.useField("password");
  const form = signInForm.useForm();
  return (
    <form
      style={{ display: "flex", flexDirection: "column", gap: "12px", maxWidth: "320px" }}
      onSubmit={(e) => {
        e.preventDefault();
        void signInForm.submit();
      }}
    >
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
        value={password.value}
        error={password.error}
        onChange={(e) => password.onChange(e.target.value)}
        onBlur={password.onBlur}
      />
      <Button type="submit" loading={form.submitting} disabled={!form.isValid}>
        Sign in
      </Button>
    </form>
  );
}

function NewsletterDemo() {
  const email = newsletterForm.useField("email");
  const form = newsletterForm.useForm();
  return (
    <form
      style={{ display: "flex", gap: "8px", alignItems: "flex-end", maxWidth: "420px" }}
      onSubmit={(e) => {
        e.preventDefault();
        void newsletterForm.submit();
      }}
    >
      <div style={{ flex: 1 }}>
        <Input
          label="Email"
          type="email"
          placeholder="you@company.com"
          value={email.value}
          error={email.error}
          onChange={(e) => email.onChange(e.target.value)}
          onBlur={email.onBlur}
        />
      </div>
      <Button type="submit" loading={form.submitting} disabled={!form.isValid}>
        Subscribe
      </Button>
    </form>
  );
}

export const Playground: Story = {
  render: () => <SignInDemo />,
};

export const SingleField: Story = {
  render: () => <NewsletterDemo />,
};
