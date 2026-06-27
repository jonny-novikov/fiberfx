import { Button, Tooltip } from "@mercury/ui";
import { Page, PageHead, Section } from "../../chrome/Page";
import { Demo } from "../../chrome/Demo";
import { openInvite, openDanger } from "../../store";

export function ModalPage() {
  return (
    <Page>
      <PageHead
        eyebrow="Components"
        title="Modal"
        lede="Focused, blocking dialogs for confirmation and composition. The dialogs themselves are owned by the app shell — these buttons open them through the Effector store."
      />

      <Section title="Basic" />
      <Demo
        code={`<Button onClick={() => openInvite()}>Open modal</Button>
<Button variant="destructive" onClick={() => openDanger()}>Delete project</Button>`}
      >
        <Button onClick={() => openInvite()}>Open modal</Button>
        <Button variant="destructive" onClick={() => openDanger()}>
          Delete project
        </Button>
      </Demo>

      <Section title="Tooltip (bonus)" />
      <Demo
        code={`<Tooltip content="Copy link to clipboard">
  <Button variant="secondary">Share</Button>
</Tooltip>
<Tooltip content="You’ve got mail">
  <Button variant="ghost">Inbox</Button>
</Tooltip>`}
      >
        <Tooltip content="Copy link to clipboard">
          <Button variant="secondary">Share</Button>
        </Tooltip>
        <Tooltip content="You’ve got mail">
          <Button variant="ghost">Inbox</Button>
        </Tooltip>
      </Demo>
    </Page>
  );
}
