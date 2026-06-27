import { Button, Input } from "@mercury/ui";
import { login } from "../store";

export function Login() {
  return (
    <div className="em-body">
      <div className="em-screen em-screen-center">
        <div
          style={{
            width: 56,
            height: 56,
            borderRadius: 14,
            marginBottom: 24,
            background: "linear-gradient(135deg, rgb(var(--iris-10)), rgb(var(--iris-9)))",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            color: "#fff",
            font: "700 26px/1 var(--font-display)",
          }}
          aria-label="Mercury"
        >
          M
        </div>
        <h2 style={{ font: "400 28px/32px var(--font-display)", margin: "0 0 8px", color: "rgb(var(--fg-primary))" }}>Welcome back</h2>
        <p style={{ font: "400 14px/20px var(--font-primary)", color: "rgb(var(--fg-secondary))", margin: "0 0 24px" }}>Sign in to continue.</p>
        <div style={{ width: "100%", display: "flex", flexDirection: "column", gap: 12 }}>
          <Input className="ma-field" label="Email address" type="email" defaultValue="you@example.com" />
          <Input className="ma-field" label="Password" type="password" defaultValue="password" />
          <Button variant="primary" size="lg" fullWidth onClick={() => login()}>
            Sign in
          </Button>
          <Button variant="ghost" size="lg" fullWidth onClick={() => login()}>
            Create account
          </Button>
        </div>
      </div>
    </div>
  );
}
