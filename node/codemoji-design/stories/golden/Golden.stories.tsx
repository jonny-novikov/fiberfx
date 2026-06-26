import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// @ts-expect-error — .mjs token source has no .d.ts; shape is known here.
import { gold } from '../../tokens/tokens.mjs';
import { Button } from '../components/Button';

// The formalized GOLD treatment. Today the app gilds ad-hoc: a Button variant on
// a raster (bg-[url("/images/rooms/gold.png")]) and ONE inline gold gradient
// (the golden-room banner in widgets/lobby-info). This story shows the tokenized
// form: the --gradient-gold swatch, the `golden` Button variant, and a golden
// room-card demo (the boost-class gild, re-expressed as tokens not a PNG).

function GradientSwatch() {
  return (
    <div>
      <div
        style={{
          height: 72,
          borderRadius: 12,
          background: 'var(--gradient-gold)',
          border: '1px solid rgba(0,0,0,0.15)',
        }}
      />
      <code style={{ fontSize: 11 }}>--gradient-gold</code>
    </div>
  );
}

function GoldenRoomCard() {
  // Re-expresses the golden-room banner: the gradient surface + a boost label +
  // the effective-pool figure (mirrors the 03-rooms.md golden-room mock numbers).
  return (
    <div
      style={{
        borderRadius: 16,
        overflow: 'hidden',
        width: 320,
        border: '1px solid var(--color-gold-border)',
        background: 'var(--color-card)',
      }}
    >
      <div
        style={{
          background: 'var(--gradient-gold)',
          color: 'var(--color-gold-foreground)',
          padding: '14px 16px',
          fontWeight: 700,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <span>Golden Room</span>
        <span style={{ fontSize: 13 }}>3× BOOST</span>
      </div>
      <div style={{ padding: 16, color: 'var(--color-dark-muted)' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
          <span>effective pool</span>
          <strong>2352 💎</strong>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
          <span>closes in</span>
          <strong>48:00:00</strong>
        </div>
        <Button variant="golden" size="default" style={{ width: '100%' }}>
          Enter Golden Room
        </Button>
      </div>
    </div>
  );
}

function Golden() {
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)', maxWidth: 760 }}>
      <h2 style={{ marginBottom: 8 }}>Gold treatment</h2>
      <p style={{ marginBottom: 16 }}>
        The gild is now a token. <code>--gradient-gold</code> is the app&apos;s one inline gold
        gradient (the <code>lobby-info</code> golden-room banner), lifted verbatim; the surface,
        foreground and border tokens (<code>{gold.goldSurface}</code> /{' '}
        <code>{gold.goldForeground}</code> / <code>{gold.goldBorder}</code>) give a flat fill where a
        gradient is not wanted. These supersede the raster{' '}
        <code>bg-[url(&quot;/images/rooms/gold.png&quot;)]</code>.
      </p>

      <section style={{ marginBottom: 24 }}>
        <h3 style={{ marginBottom: 8 }}>Token swatch</h3>
        <GradientSwatch />
      </section>

      <section style={{ marginBottom: 24 }}>
        <h3 style={{ marginBottom: 8 }}>The golden Button variant</h3>
        <Button variant="golden">Enter Golden Room</Button>
      </section>

      <section style={{ marginBottom: 24 }}>
        <h3 style={{ marginBottom: 8 }}>Golden room card</h3>
        <GoldenRoomCard />
      </section>

      <section
        style={{
          borderLeft: '3px solid var(--color-gold-border)',
          paddingLeft: 12,
          fontSize: 13,
          opacity: 0.85,
        }}
      >
        <strong>&quot;Golden&quot; is overloaded.</strong> A <em>boost class</em> (
        <code>gold_multiplier</code> on an otherwise <code>classic</code> game — the Golden Room
        screens; the export&apos;s golden screens) is a different thing from the{' '}
        <em>blind commit-reveal game type</em> (the app&apos;s <code>golden</code> code). This
        treatment formalizes the golden <strong>visuals</strong> (the boost-class gild) only.
      </section>
    </div>
  );
}

const meta: Meta<typeof Golden> = {
  title: 'Golden/Treatment',
  component: Golden,
};
export default meta;

type Story = StoryObj<typeof Golden>;
export const GoldTreatment: Story = {};
