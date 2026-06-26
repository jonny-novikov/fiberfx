import type { Meta, StoryObj } from '@storybook/react-vite';
import * as React from 'react';
// .mjs data module — typed via allowJs (inferred from the manifest); cast to Screen below.
import { goldenInProgress, goldenFinished, goldenScreens } from './screens.data.mjs';
import { DriftView, PhoneFrame, type Screen } from './ScreenView';
import { GoldenInProgressScreen, GoldenFinishedScreen } from '../golden-game/GoldenScreen';

// Golden Game — the boost-class room: a gold_multiplier on an otherwise classic
// game (NOT the app's separate blind commit-reveal "golden" type — see
// Golden/Treatment for that overload note). Two states from the export: an active
// boosted game (in progress) and the post-settlement winner-take-all (finished).
// Each is rebuilt LIVE from the design system beside the Figma reference — the gild
// is the --gradient-gold token (the bezel + the CTAs), not the app's raster gold.png.

function BoostNote() {
  return (
    <div
      style={{
        borderLeft: '3px solid var(--color-gold-border)',
        paddingLeft: 12,
        fontSize: 12,
        opacity: 0.85,
      }}
    >
      <strong>Boost class.</strong> <code>gold_multiplier</code> on a <code>classic</code> game — the
      gild is the tokenized <code>--gradient-gold</code> (see <strong>Golden/Treatment</strong>), not
      the raster <code>gold.png</code>.
    </div>
  );
}

function InProgressView() {
  return (
    <DriftView screen={goldenInProgress as Screen} golden note={<BoostNote />}>
      <GoldenInProgressScreen />
    </DriftView>
  );
}

function FinishedView() {
  return (
    <DriftView
      screen={goldenFinished as Screen}
      golden
      note={
        <>
          <p style={{ fontSize: 13, opacity: 0.85, margin: '0 0 10px' }}>
            Post-settlement: winner-take-all of the boosted pool (the <code>golden_win</code> moment;
            entities <code>TXN</code> · <code>NOT</code>).
          </p>
          <BoostNote />
        </>
      }
    >
      <GoldenFinishedScreen />
    </DriftView>
  );
}

function ProgressionView() {
  const set = goldenScreens as Screen[];
  return (
    <div className="font-sans" style={{ color: 'var(--color-dark-muted)' }}>
      <h2 style={{ marginBottom: 4, fontSize: 20 }}>Golden Room — open → settled</h2>
      <p style={{ marginBottom: 20, opacity: 0.7, fontSize: 13 }}>
        The boost-class arc: an active boosted game, then winner-take-all at close.
      </p>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 28 }}>
        {set.map((s) => (
          <div key={s.figma_id}>
            <PhoneFrame screen={s} width={230} golden />
            <div style={{ fontSize: 11, marginTop: 8, opacity: 0.7 }}>
              <code>{s.figma_id}</code> · {s.game_state}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

const meta: Meta = { title: 'Screens/Golden Game' };
export default meta;

type Story = StoryObj;
export const InProgress: Story = { render: () => <InProgressView /> };
export const Finished: Story = { render: () => <FinishedView /> };
export const Progression: Story = { render: () => <ProgressionView /> };
