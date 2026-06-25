import { useAtom } from 'jotai'
import { useTranslation } from 'react-i18next'

import { usePurchaseKeys, useKeyPackages } from '../model/hooks'
import { keysPurchaseDrawerAtom, type KeyPackage } from '../model/store'

import { KeyPurchaseItem } from './key-purchase-item'

import { useMyResources } from '@/entities/player'
import { useBackButton } from '@/shared/libs'
import {
  Drawer,
  DrawerContent,
  DrawerHandle,
  DrawerTitle,
  DrawerDescription,
  DrawerBody,
  Skeleton,
} from '@/shared/ui'

export const KeysPurchaseDrawer = () => {
  const { t } = useTranslation()
  const [isOpen, setIsOpen] = useAtom(keysPurchaseDrawerAtom)

  const { data: resources, isLoading: isResourcesLoading } = useMyResources()
  const keysBalance = resources?.keys.balance

  const { data: packages = [], isLoading: isPackagesLoading } = useKeyPackages({
    enabled: isOpen,
  })
  const purchaseMutation = usePurchaseKeys({ onClose: () => setIsOpen(false) })

  // Кнопка "Назад" закрывает drawer
  useBackButton({
    show: isOpen,
    onClick: () => setIsOpen(false),
  })

  const handlePurchase = (pkg: KeyPackage) => {
    purchaseMutation.mutate(pkg.id)
  }

  if (!isOpen) {
    return null
  }

  return (
    <Drawer open={isOpen} onOpenChange={setIsOpen}>
      <DrawerContent className="max-h-[90dvh]">
        <DrawerHandle />

        <DrawerBody className="px-2 pb-4 pt-5">
          <div className="absolute top-2 right-6 text-xs">
            <p className="text-primary">{t('common.balance')}</p>
            <div className="flex items-center gap-1">
              <img src="/images/keys/dark-key.png" alt="Key" className="size-4" />
              <span>
                {isResourcesLoading ? (
                  <Skeleton className="w-6 h-4 rounded-sm bg-black/40" />
                ) : (
                  keysBalance
                )}
              </span>
            </div>
          </div>
          <div className="flex flex-col items-center mb-6">
            <img src="/images/keys/dark-keys.png" alt="Keys" className="w-50" draggable="false" />
            <DrawerTitle className="font-bold text-xl mb-3 text-drawer-foreground">
              {t('keys.purchase.title')}
            </DrawerTitle>
            <DrawerDescription className="text-xs text-drawer-foreground-secondary font-medium">
              {t('keys.purchase.description')}
            </DrawerDescription>
          </div>

          <div className="flex flex-col gap-3">
            {isPackagesLoading
              ? // Show skeleton loaders while fetching packages
                Array.from({ length: 4 }).map((_, i) => (
                  <Skeleton key={i} className="h-16 w-full rounded-xl bg-black/20" />
                ))
              : packages.map((pkg) => (
                  <KeyPurchaseItem
                    key={pkg.id}
                    pkg={pkg}
                    onClick={() => handlePurchase(pkg)}
                    isLoading={purchaseMutation.isPending && purchaseMutation.variables === pkg.id}
                    disabled={purchaseMutation.isPending}
                  />
                ))}
          </div>
        </DrawerBody>
      </DrawerContent>
    </Drawer>
  )
}
