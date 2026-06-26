import * as React from 'react';
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

const TIP =
  '💡 Совет от Mr. Freeman: Вы когда-нибудь совершали что-нибудь по-настоящему из ряда вон? Никогда! И не сможете, знаете почему? Потому что всё это находится за пределами вашей зоны комфорта, вы упакованы в неё, словно полипропиленновый мешок.';

export function ShareKeys({ onShare, onInvite, className }: ShareKeysProps) {
  return (
    <BoardCard className={cn('font-sans', className)}>
      <h2 className="text-h1 font-bold mb-2 text-center text-dark-muted">Получи ключ бесплатно</h2>
      <p className="text-h5 text-card-foreground-secondary mb-4 text-center">
        Опубликуй сторис, чтобы получить доступ к специальной комнате
      </p>
      <Button variant="default" className="w-full mb-2" onClick={onShare}>
        Поделиться в сторис
      </Button>
      <Button variant="enter" className="w-full" onClick={onInvite}>
        👥 Пригласить друга
      </Button>
      <p className="mt-4 text-h5 text-muted">{TIP}</p>
    </BoardCard>
  );
}
