import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
import { BoardCard } from './BoardCard';
import { EmojiTile } from './EmojiTile';

// The shared atom. One story shows every state side by side so drift in any
// board surface that uses it is visible in one place.
const meta: Meta<typeof EmojiTile> = {
  title: 'Board/lib/Emoji Tile',
  component: EmojiTile,
};
export default meta;

type Story = StoryObj<typeof EmojiTile>;

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
      <span style={{ width: 88, fontSize: 12, opacity: 0.6 }}>{label}</span>
      {children}
    </div>
  );
}

export const States: Story = {
  render: () => (
    <BoardCard className="font-sans" style={{ maxWidth: 320 }}>
      <Row label="empty">
        <EmojiTile state="empty" />
      </Row>
      <Row label="active">
        <EmojiTile state="active" />
      </Row>
      <Row label="filled">
        <EmojiTile state="filled" emoji="🔥" />
      </Row>
      <Row label="locked">
        <EmojiTile state="locked" emoji="💎" locked />
      </Row>
      <Row label="key">
        <EmojiTile state="key" emoji="😀" />
      </Row>
    </BoardCard>
  ),
};
