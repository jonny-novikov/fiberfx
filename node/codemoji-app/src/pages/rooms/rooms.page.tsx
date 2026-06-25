import { useRoomsListQuery } from '@/entities/rooms'
import { RoomsList } from '@/entities/rooms/ui/rooms-list'
import { PageLayout } from '@/shared/layout'
import { AdminPanel } from '@/widgets/admin-panel'
import { ArchiveRoomsList } from '@/widgets/archive-rooms'
import { BuyKeysBanner } from '@/widgets/buy-keys-banner'
import { CharacterFooter } from '@/widgets/character-footer'
import { GameRules } from '@/widgets/game-rules'
import { PromoBanner } from '@/widgets/promo-banner'
import { StatusBar } from '@/widgets/status-bar'
import { SubscriptionBanner } from '@/widgets/subscription-banner'

export const RoomsPage = () => {
  const { data } = useRoomsListQuery({ limit: 10, offset: 0, type: 'all' })
  const totalPrizePool = data?.totalPrizePool ?? 0

  return (
    <PageLayout className="bg-black gap-0">
      <div className="flex flex-col items-stretch gap-3">
        <StatusBar className="px-2" />
        <PromoBanner totalEarned={totalPrizePool} />
        <SubscriptionBanner className="px-2" />
        <div className="rounded-tl-4xl rounded-tr-4xl bg-[#D8E4EB] px-2 pt-6">
          <RoomsList className="mb-8" />
          <ArchiveRoomsList className="mb-10" />
          <GameRules className="mb-2" />
          {/* <CharacterKeyBanner /> */}
          <BuyKeysBanner totalEarned={totalPrizePool} className="mb-10" />
        </div>
      </div>
      <CharacterFooter className="bg-[#D8E4EB]" />
      {import.meta.env.DEV && <AdminPanel className="pt-10 pb-safe-bottom bg-red-100" />}
    </PageLayout>
  )
}
