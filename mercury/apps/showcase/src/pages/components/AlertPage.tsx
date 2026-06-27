import { Alert } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";

export function AlertPage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Alert"
        lede="Communicate non-blocking status. For blocking decisions, use a Modal."
      />

      <Section title="Variants" />
      <Demo
        layout="col"
        code={`<Alert tone="info" title="Scheduled maintenance">
  Mercury will be read-only on Sunday, April 27 from 02:00 – 04:00 UTC.
</Alert>
<Alert tone="success" title="Payment received">
  Your invoice for April has been paid. A receipt was sent to billing@jonnify.com.
</Alert>
<Alert tone="warning" title="API key rotating soon">
  Your production key expires in 7 days. Generate a replacement in Settings → API.
</Alert>
<Alert tone="danger" title="Deploy failed">
  Build #4821 failed on step "test:e2e". Check logs for the stack trace.
</Alert>`}
      >
        <div style={{ width: "100%" }}>
          <Alert tone="info" title="Scheduled maintenance">
            Mercury will be read-only on Sunday, April 27 from 02:00 – 04:00 UTC.
          </Alert>
        </div>
        <div style={{ width: "100%" }}>
          <Alert tone="success" title="Payment received">
            Your invoice for April has been paid. A receipt was sent to billing@jonnify.com.
          </Alert>
        </div>
        <div style={{ width: "100%" }}>
          <Alert tone="warning" title="API key rotating soon">
            Your production key expires in 7 days. Generate a replacement in Settings → API.
          </Alert>
        </div>
        <div style={{ width: "100%" }}>
          <Alert tone="danger" title="Deploy failed">
            Build #4821 failed on step "test:e2e". Check logs for the stack trace.
          </Alert>
        </div>
      </Demo>
    </Page>
  );
}
