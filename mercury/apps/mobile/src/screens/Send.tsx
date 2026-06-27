import { Button, Input } from "@mercury/ui";
import { toast } from "@mercury/effector";
import { completeSend, sendForm } from "../store";

export function Send() {
  const recipient = sendForm.useField("recipient");
  const amount = sendForm.useField("amount");
  const note = sendForm.useField("note");
  const form = sendForm.useForm();

  const onSend = () => {
    form.submit(); // mark every field touched so errors surface
    if (!form.isValid) return;
    toast.success(`Sent $${form.values.amount} to ${form.values.recipient}`, { title: "Money sent" });
    completeSend();
    form.reset();
  };

  return (
    <div className="em-screen">
      <h3 style={{ font: "700 22px/28px var(--font-primary)", margin: "0 0 16px" }}>Send money</h3>
      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        <Input
          className="ma-field"
          label="Recipient"
          placeholder="ana@example.com"
          hint="Email, phone or @handle"
          value={recipient.value}
          error={recipient.error}
          onChange={(e) => recipient.onChange(e.target.value)}
          onBlur={recipient.onBlur}
        />
        <div className="em-field">
          <label>Amount</label>
          <div className="em-amt">
            <span className="em-amt-ccy">USD</span>
            <input
              className="em-amt-input"
              value={amount.value}
              onChange={(e) => amount.onChange(e.target.value)}
              onBlur={amount.onBlur}
              inputMode="decimal"
            />
          </div>
          <div className="em-hint" style={amount.error ? { color: "rgb(var(--fg-negative))" } : undefined}>
            {amount.error ?? "Available: $4,218.40 USD"}
          </div>
        </div>
        <Input
          className="ma-field"
          label="Note (optional)"
          placeholder="Dinner"
          value={note.value}
          onChange={(e) => note.onChange(e.target.value)}
        />
        <div style={{ display: "flex", gap: 10, marginTop: 8 }}>
          <Button variant="outline" size="lg" onClick={() => completeSend()}>
            Cancel
          </Button>
          <Button variant="primary" size="lg" style={{ flex: 1 }} onClick={onSend}>
            Send ${form.values.amount}
          </Button>
        </div>
      </div>
    </div>
  );
}
