import { cn } from '@/shared/libs'

interface WalletAddressProps {
  address: string | null
  className?: string
}

/**
 * Форматирует адрес кошелька, сокращая его до вида UQd4D..61p
 */
const formatAddress = (address: string): string => {
  if (address.length <= 12) return address
  return `${address.slice(0, 5)}..${address.slice(-3)}`
}

export const WalletAddress = ({ address, className }: WalletAddressProps) => {
  if (!address) return null

  return (
    <span className={cn('text-sm font-medium text-muted-foreground', className)}>
      {formatAddress(address)}
    </span>
  )
}
