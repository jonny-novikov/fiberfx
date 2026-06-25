import { useState, useEffect, useCallback } from 'react';

interface LeaderboardNotificationsState {
  isEnabled: boolean;
  toggle: () => void;
  enable: () => void;
  disable: () => void;
}

const STORAGE_KEY = 'leaderboard-notifications';

/**
 * Хук для управления уведомлениями о смене лидеров
 * @param defaultEnabled - значение по умолчанию (false)
 * @returns объект с состоянием и методами управления уведомлениями
 */
export const useLeaderboardNotifications = (
  defaultEnabled = false
): LeaderboardNotificationsState => {
  const [isEnabled, setIsEnabled] = useState(defaultEnabled);

  // Инициализация из localStorage
  useEffect(() => {
    const savedValue = localStorage.getItem(STORAGE_KEY);
    if (savedValue !== null) {
      setIsEnabled(savedValue === 'true');
    }
  }, []);

  // Сохранение в localStorage при изменении
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, String(isEnabled));
  }, [isEnabled]);

  const toggle = useCallback(() => {
    setIsEnabled((prev) => {
      const newValue = !prev;
      if (newValue) {
        console.log('✅ Уведомления о смене лидеров включены');
        // Здесь можно добавить логику отправки на сервер
      } else {
        console.log('🔕 Уведомления о смене лидеров выключены');
      }
      return newValue;
    });
  }, []);

  const enable = useCallback(() => {
    setIsEnabled(true);
    console.log('✅ Уведомления о смене лидеров включены');
  }, []);

  const disable = useCallback(() => {
    setIsEnabled(false);
    console.log('🔕 Уведомления о смене лидеров выключены');
  }, []);

  return {
    isEnabled,
    toggle,
    enable,
    disable,
  };
};

