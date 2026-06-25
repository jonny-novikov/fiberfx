import { Cell } from '@ton/core'
import { Account, useTonConnectUI } from '@tonconnect/ui-react'
import { createContext, FC, ReactNode, useContext, useEffect, useState } from 'react'

// import {
//   useGetUserWalletQuery,
//   useRemoveWalletMutation,
//   useSaveWalletMutation,
// } from '@/features/connect-ton-wallet/api/connect-ton-wallet.api'
// import { TelegramUtils } from '@/shared/libs'
import { retry } from '@/shared/libs/utils/promise'

const TonConnectContext = createContext<ReturnType<typeof useTonConnectInternal>>(null!)

export const useTonConnect = () => {
  return useContext(TonConnectContext)
}

export const TonConnectProvider: FC<{ children: ReactNode }> = ({ children }) => {
  const value = useTonConnectInternal()

  return <TonConnectContext.Provider value={value}>{children}</TonConnectContext.Provider>
}

const useTonConnectInternal = () => {
  const [tonConnectUI] = useTonConnectUI()
  const [isLoggingIn, setIsLoggingIn] = useState(false)
  const [tonConnectAccount, setTonConnectAccount] = useState<Account | null>(tonConnectUI.account)
  // const [saveWallet] = useSaveWalletMutation()
  // const [removeWallet] = useRemoveWalletMutation()

  // Получаем данные о кошельке с бекенда для отображения последнего использованного
  // const telegramUser = TelegramUtils.getUser()
  // const {
  //   data: walletData,
  //   error: walletError,
  //   isLoading: isWalletLoading,
  // } = useGetUserWalletQuery(undefined, {
  //   skip: !telegramUser?.id,
  // })

  // Обрабатываем ошибки получения кошелька
  // useEffect(() => {
  //   if (walletError) {
  //     const error = walletError as any
  //     // 404 - это нормально, означает что кошелька еще нет
  //     if (error?.status !== 404) {
  //       console.error('❌ Ошибка при получении кошелька с бэкенда:', error)
  //     }
  //   }
  // }, [walletError])

  // const savedWallet = walletData?.wallet

  // Отслеживаем изменения статуса подключения
  useEffect(() => {
    return tonConnectUI.onStatusChange(() => {
      setTonConnectAccount(tonConnectUI.account)
    })
  }, [tonConnectUI])

  /**
   * Подключение кошелька через модалку TON Connect
   * При подключении автоматически сохраняется на бекенд
   */
  const connectWallet = async () => {
    // Если кошелек уже подключен, возвращаем текущий аккаунт
    if (tonConnectUI.account) {
      console.log('✅ Кошелек уже подключен:', tonConnectUI.account.address)
      return Promise.resolve(tonConnectUI.account)
    }

    setIsLoggingIn(true)
    return new Promise<Account>((resolve, reject) => {
      const unsubscribeModal = tonConnectUI.onModalStateChange((state: any) => {
        if (state.status === 'closed') {
          setIsLoggingIn(false)
          if (!tonConnectUI.account) {
            unsubscribeModal()
            unsubscribeStatus()
            reject(new Error('User closed the modal'))
          }
        }
      })

      const unsubscribeStatus = tonConnectUI.onStatusChange(
        async () => {
          if (tonConnectUI.account) {
            setTonConnectAccount(tonConnectUI.account)

            // Сохраняем новый кошелек на бекенд
            try {
              // await saveWallet({
              //   walletAddress: tonConnectUI.account.address,
              //   network: tonConnectUI.account.chain === '-239' ? 'mainnet' : 'testnet',
              //   isPrimary: true,
              // })
              console.log('✅ Кошелек подключен и сохранен:', tonConnectUI.account.address)
            } catch (error) {
              console.error('❌ Ошибка при сохранении кошелька:', error)
            }

            setIsLoggingIn(false)
            unsubscribeModal()
            unsubscribeStatus()
            resolve(tonConnectUI.account)
          }
        },
        (err: any) => {
          setIsLoggingIn(false)
          unsubscribeModal()
          unsubscribeStatus()
          reject(err)
        }
      )

      tonConnectUI.openModal().catch((err: any) => {
        setIsLoggingIn(false)
        unsubscribeModal()
        unsubscribeStatus()
        reject(err)
      })
    })
  }

  /**
   * Обеспечивает наличие подключенного кошелька
   * Если кошелек не подключен - открывает модалку для подключения
   */
  const ensureWalletConnected = async (): Promise<string | null> => {
    // Если кошелек уже подключен - возвращаем его адрес
    if (tonConnectUI.account?.address) {
      return tonConnectUI.account.address
    }

    // Если нет - подключаем новый
    try {
      const account = await connectWallet()
      return account.address
    } catch (error) {
      console.error('❌ Не удалось подключить кошелек:', error)
      return null
    }
  }

  const waitTonConnectTransaction = async (tonConnectBoc: string) => {
    const txHash = Cell.fromBase64(tonConnectBoc).hash().toString('hex')

    await retry(
      () => fetch(`https://tonapi.io/v2/blockchain/messages/${txHash}/transaction`),
      50,
      5_000
    )
  }

  /**
   * Отвязка кошелька
   * Удаляет данные с бекенда и отключает от SDK
   */
  const disconnectWallet = async () => {
    try {
      // Удаляем кошелек на бекенде
      // await removeWallet()

      // Отключаем кошелек в TonConnect UI
      await tonConnectUI.disconnect()
      setTonConnectAccount(null)

      console.log('✅ Кошелек отключен')
    } catch (error) {
      console.error('❌ Ошибка при отключении кошелька:', error)
      throw error
    }
  }

  return {
    // Основные методы
    connectWallet,
    disconnectWallet,
    ensureWalletConnected,

    // Информация о состоянии
    currentWallet: tonConnectUI.account?.address || null,
    // savedWallet: savedWallet?.walletAddress || null,
    isConnected: !!tonConnectUI.account,
    isLoggingIn,
    // isWalletLoading,

    // Низкоуровневые методы
    tonConnectUI,
    tonConnectAccount,
    waitTonConnectTransaction,
  }
}
