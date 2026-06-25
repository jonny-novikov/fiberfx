/**
 * Демо-компонент для тестирования хука useBackButton
 * 
 * Этот файл можно импортировать на любую страницу для тестирования
 * работы кнопки "Назад" в Telegram
 */

import { useState } from 'react';

import { useBackButton } from './use-back-button';

export const BackButtonDemo = () => {
  const [mode, setMode] = useState<'auto' | 'custom' | 'conditional'>('auto');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [showButton, setShowButton] = useState(true);

  // Автоматическая навигация назад
  const autoBackButton = useBackButton({
    show: mode === 'auto' && showButton,
  });

  // Кастомная навигация
  const customBackButton = useBackButton({
    show: mode === 'custom' && showButton,
    navigateTo: '/rooms',
  });

  // Условное отображение (для модалки)
  const conditionalBackButton = useBackButton({
    show: mode === 'conditional' && isModalOpen,
    onClick: () => setIsModalOpen(false),
  });

  return (
    <div className="fixed bottom-4 right-4 bg-white p-4 rounded-lg shadow-lg max-w-xs z-50 border-2 border-blue-500">
      <h3 className="font-bold text-lg mb-3">🔙 BackButton Demo</h3>
      
      <div className="space-y-3">
        {/* Выбор режима */}
        <div>
          <p className="text-sm font-semibold mb-2">Режим:</p>
          <div className="space-y-1">
            <label className="flex items-center text-sm">
              <input
                type="radio"
                checked={mode === 'auto'}
                onChange={() => setMode('auto')}
                className="mr-2"
              />
              Auto (navigate -1)
            </label>
            <label className="flex items-center text-sm">
              <input
                type="radio"
                checked={mode === 'custom'}
                onChange={() => setMode('custom')}
                className="mr-2"
              />
              Custom (/rooms)
            </label>
            <label className="flex items-center text-sm">
              <input
                type="radio"
                checked={mode === 'conditional'}
                onChange={() => setMode('conditional')}
                className="mr-2"
              />
              Conditional (modal)
            </label>
          </div>
        </div>

        {/* Управление видимостью */}
        <div>
          <label className="flex items-center text-sm">
            <input
              type="checkbox"
              checked={showButton}
              onChange={(e) => setShowButton(e.target.checked)}
              className="mr-2"
            />
            Показывать кнопку
          </label>
        </div>

        {/* Модальное окно (для условного режима) */}
        {mode === 'conditional' && (
          <div>
            <button
              onClick={() => setIsModalOpen(!isModalOpen)}
              className="w-full px-3 py-2 bg-blue-500 text-white rounded text-sm"
            >
              {isModalOpen ? '✓ Модалка открыта' : 'Открыть модалку'}
            </button>
          </div>
        )}

        {/* Программное управление */}
        <div className="border-t pt-3">
          <p className="text-sm font-semibold mb-2">Программное управление:</p>
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={() => {
                if (mode === 'auto') autoBackButton.show();
                if (mode === 'custom') customBackButton.show();
                if (mode === 'conditional') conditionalBackButton.show();
              }}
              className="px-2 py-1 bg-green-500 text-white rounded text-xs"
            >
              Show
            </button>
            <button
              onClick={() => {
                if (mode === 'auto') autoBackButton.hide();
                if (mode === 'custom') customBackButton.hide();
                if (mode === 'conditional') conditionalBackButton.hide();
              }}
              className="px-2 py-1 bg-red-500 text-white rounded text-xs"
            >
              Hide
            </button>
          </div>
        </div>

        {/* Информация */}
        <div className="text-xs text-gray-600 border-t pt-2">
          <p>
            Состояние:{' '}
            <span className="font-semibold">
              {mode === 'auto' && autoBackButton.isVisible && '✓ Видна'}
              {mode === 'custom' && customBackButton.isVisible && '✓ Видна'}
              {mode === 'conditional' && conditionalBackButton.isVisible && '✓ Видна'}
              {((mode === 'auto' && !autoBackButton.isVisible) ||
                (mode === 'custom' && !customBackButton.isVisible) ||
                (mode === 'conditional' && !conditionalBackButton.isVisible)) &&
                '✗ Скрыта'}
            </span>
          </p>
          <p className="mt-1">
            💡 Откройте в Telegram для тестирования
          </p>
        </div>
      </div>

      {/* Модальное окно */}
      {isModalOpen && mode === 'conditional' && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-lg shadow-xl max-w-sm">
            <h4 className="font-bold text-lg mb-2">Модальное окно</h4>
            <p className="text-sm mb-4">
              Нажмите кнопку "Назад" в Telegram или кнопку ниже для закрытия
            </p>
            <button
              onClick={() => setIsModalOpen(false)}
              className="w-full px-4 py-2 bg-blue-500 text-white rounded"
            >
              Закрыть
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

// Экспорт для удобного использования
export default BackButtonDemo;

/**
 * Использование:
 * 
 * import { BackButtonDemo } from '@/shared/libs/hooks/BackButtonDemo';
 * 
 * function MyPage() {
 *   return (
 *     <div>
 *       <BackButtonDemo />
 *       {/* Ваш контент *\/}
 *     </div>
 *   );
 * }
 */

