import { Progress } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";
import { useProgress } from "../../store";

export function ProgressPage() {
  const progress = useProgress();

  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Progress"
        lede="Thin bars for determinate loading and upload states."
      />

      <Section title="Sizes" />
      <Demo
        layout="col"
        code={`<Progress value={60} size="sm" />
<Progress value={60} size="md" />
<Progress value={60} size="lg" />`}
      >
        <div style={{ width: "100%" }}>
          <Progress value={60} size="sm" />
        </div>
        <div style={{ width: "100%" }}>
          <Progress value={60} size="md" />
        </div>
        <div style={{ width: "100%" }}>
          <Progress value={60} size="lg" />
        </div>
      </Demo>

      <Section title="Variants (live)" hint="auto-advances every ~1s" />
      <Demo layout="col">
        <div style={{ width: "100%" }}>
          <Progress value={progress} variant="brand" />
        </div>
        <div style={{ width: "100%" }}>
          <Progress value={progress} variant="positive" />
        </div>
        <div style={{ width: "100%" }}>
          <Progress value={progress} variant="caution" />
        </div>
        <div style={{ width: "100%" }}>
          <Progress value={progress} variant="negative" />
        </div>
      </Demo>
    </Page>
  );
}
