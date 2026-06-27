import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { cn } from '../lib/cn';
import { BoardCard } from './lib/BoardCard';
import { Button } from '../components/Button';

// The "get keys free" referral block (Figma 94:2974 / 121:2056). Re-expresses the
// ShareForClips + InviteFriendButton pair: a centered pitch over two stacked CTAs,
// then the Mr. Freeman tip. Text is verbatim from the Figma master (Russian). Colors
// match Figma: "Поделиться в сторис" is the black share button; "Пригласить друга" is
// the blue button (#0050FF = the `enter` token). Presentational only — the real
// Telegram story-share / invite-link plumbing is omitted. Shared by board + lobby.
export interface ShareKeysProps {
  onShare?: () => void;
  onInvite?: () => void;
  className?: string;
}

export function ShareKeys({ onShare, onInvite, className }: ShareKeysProps) {
  const { t } = useTranslation();
  return (
    <BoardCard className={cn('font-sans', className)}>
      <h2 className="text-h1 font-bold mb-2 text-center text-dark-muted">
        {t('board.shareKeys.title')}
      </h2>
      <p className="text-h5 text-card-foreground-secondary mb-4 text-center">
        {t('board.shareKeys.description')}
      </p>
      <Button variant="default" className="w-full mb-2" onClick={onShare}>
        {t('share.toStories')}
      </Button>
      <Button variant="enter" className="w-full" onClick={onInvite}>
        👥 {t('gameRules.inviteFriend')}
      </Button>
      <p className="mt-4 text-h5 text-muted">{t('board.shareKeys.tip')}</p>
    </BoardCard>
  );
}
