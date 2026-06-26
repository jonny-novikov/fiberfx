import * as React from 'react';
import { cn } from '../lib/cn';
import { BoardCard } from './lib/BoardCard';
import { Button } from '../components/Button';

// The "Get keys free" referral block at the foot of the board (94:2974).
// Re-expresses the ShareForClips + InviteFriendButton pair from
// widgets/game-rules: a centered pitch over two stacked, full-width CTAs.
// Share-to-story rides the `buy` variant (bg-accent) so it recolors with the
// theme toolbar; invite is the quieter `outline`. Presentational only — the
// real Telegram story-share / invite-link plumbing is omitted.
export interface ShareKeysProps {
  onShare?: () => void;
  onInvite?: () => void;
  className?: string;
}

export function ShareKeys({ onShare, onInvite, className }: ShareKeysProps) {
  return (
    <BoardCard className={cn('font-sans text-center', className)}>
      <h2 className="text-h1 font-bold mb-2">📣 Get keys free</h2>
      <p className="text-xs text-card-foreground-secondary mb-4">
        Share to your story or invite a friend to earn more keys 🔑
      </p>
      <Button variant="buy" className="w-full mb-2" onClick={onShare}>
        Share to story
      </Button>
      <Button variant="outline" className="w-full" onClick={onInvite}>
        👥 Invite a friend
      </Button>
    </BoardCard>
  );
}
