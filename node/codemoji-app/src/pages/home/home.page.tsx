import { useNavigate } from 'react-router-dom';

import { useRoomsListQuery } from '@/entities/rooms';
import { PromoBanner } from '../../widgets/promo-banner';

export const HomePage = () => {
  const navigate = useNavigate();
  const { data } = useRoomsListQuery({ limit: 1, offset: 0, type: 'all' });
  const totalPrizePool = data?.totalPrizePool ?? 0;

  return (
    <div className="max-w-6xl mx-auto px-4 py-8 space-y-12">
      {/* Hero Section */}
      <div className="text-center space-y-6">
        <h1 className="text-5xl md:text-6xl font-bold text-gray-800">
          CodeMoji 🎮
        </h1>
        <p className="text-xl md:text-2xl text-gray-600">
          Играй с эмодзи и побеждай!
        </p>
      </div>

      {/* Статистика */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-8 text-white text-center shadow-lg transform transition-transform hover:scale-105">
          <div className="text-5xl mb-3">👥</div>
          <div className="text-4xl font-bold mb-2">1,250+</div>
          <div className="text-blue-100">Активных игроков</div>
        </div>
        <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-8 text-white text-center shadow-lg transform transition-transform hover:scale-105">
          <div className="text-5xl mb-3">🎯</div>
          <div className="text-4xl font-bold mb-2">50+</div>
          <div className="text-purple-100">Игровых комнат</div>
        </div>
        <div className="bg-gradient-to-br from-pink-500 to-pink-600 rounded-xl p-8 text-white text-center shadow-lg transform transition-transform hover:scale-105">
          <div className="text-5xl mb-3">🏆</div>
          <div className="text-4xl font-bold mb-2">10,000+</div>
          <div className="text-pink-100">Сыгранных игр</div>
        </div>
      </div>

      {/* Особенности */}
      <div className="space-y-8">
        <h2 className="text-3xl font-bold text-center text-gray-800">
          Особенности игры
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-white rounded-xl p-6 shadow-lg border border-gray-100 hover:shadow-xl transition-shadow">
            <div className="flex items-start space-x-4">
              <div className="text-5xl">⚡</div>
              <div className="flex-1">
                <h3 className="text-xl font-semibold text-gray-800 mb-2">
                  Быстрые матчи
                </h3>
                <p className="text-gray-600">
                  Присоединяйтесь к игре моментально и начинайте играть
                </p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-6 shadow-lg border border-gray-100 hover:shadow-xl transition-shadow">
            <div className="flex items-start space-x-4">
              <div className="text-5xl">👫</div>
              <div className="flex-1">
                <h3 className="text-xl font-semibold text-gray-800 mb-2">
                  Мультиплеер
                </h3>
                <p className="text-gray-600">
                  Играйте с друзьями или случайными соперниками
                </p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-6 shadow-lg border border-gray-100 hover:shadow-xl transition-shadow">
            <div className="flex items-start space-x-4">
              <div className="text-5xl">🎨</div>
              <div className="flex-1">
                <h3 className="text-xl font-semibold text-gray-800 mb-2">
                  Уникальный геймплей
                </h3>
                <p className="text-gray-600">
                  Тысячи эмодзи для создания уникальной стратегии
                </p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-6 shadow-lg border border-gray-100 hover:shadow-xl transition-shadow">
            <div className="flex items-start space-x-4">
              <div className="text-5xl">🏅</div>
              <div className="flex-1">
                <h3 className="text-xl font-semibold text-gray-800 mb-2">
                  Рейтинговая система
                </h3>
                <p className="text-gray-600">
                  Соревнуйтесь за место в таблице лидеров
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Промо-баннер */}
      <PromoBanner totalEarned={totalPrizePool} />

      {/* Call to Action */}
      <div className="text-center space-y-6 py-8">
        <h3 className="text-2xl font-semibold text-gray-800">
          Готовы начать играть? 🚀
        </h3>
        <button
          onClick={() => navigate('/rooms')}
          className="px-10 py-4 bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-full text-xl font-semibold shadow-lg hover:shadow-xl transform transition-all hover:scale-105"
        >
          Найти игру
        </button>
      </div>
    </div>
  );
};
