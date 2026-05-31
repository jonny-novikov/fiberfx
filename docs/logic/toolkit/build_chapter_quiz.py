#!/usr/bin/env python3
"""
build_chapter_quiz.py — генератор страниц «Квиз главы» для курса
«Логика и принятие решений». На страницу: 6 вопросов — по одному на каждый
модуль главы, тема главы, бейдж модуля, цепочечная навигация, прогресс в localStorage.
Движок — тот же, что в курсе I (валидирован). Запуск:  python3 build_chapter_quiz.py
Выход: <repo>/logic/{глава}/kviz.html  (по умолчанию; переопределяется OUT_BASE)
"""
import json, os

# Default output target is the repo's served logic/ tree, resolved relative to this
# script (docs/logic/toolkit/ → repo root → logic/) so it works on the local
# filesystem out of the box. OUT_BASE env still overrides it (e.g. a sandbox path).
_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
OUT_BASE = os.environ.get('OUT_BASE', os.path.join(_REPO_ROOT, 'logic'))
COURSE_NAME = 'Логика и принятие решений'
COURSE_BASE = '/logic'

CH = [
 dict(n=1, slug='iskazheniya', title='Когнитивные искажения',
   accent='#c4504c', bright='#e07672', deep='#8e3a37', rgb='196,80,76',
   nxt=(f'{COURSE_BASE}/veroyatnost/kviz','Квиз главы 2','Вероятность и ценность'),
   Q=[
    dict(mod='1.1 · Две системы', q='Система 1 и Система 2 мышления — это:',
       options=['быстрое интуитивное и медленное аналитическое мышление','левое и правое полушарие','сознание и сон','память и внимание'], correct=0,
       explain='<b>Быстрое и медленное.</b> Система 1 — мгновенные интуиции, Система 2 — усилие и расчёт.'),
    dict(mod='1.2 · Якорение', q='Эффект якорения — это когда:',
       options=['первое названное число искажает последующую оценку','забываешь начало списка','повторение делает мысль правдой','решение зависит от настроения'], correct=0,
       explain='<b>Якорь смещает оценку.</b> Случайное число «до» влияет на ваш ответ «после».'),
    dict(mod='1.3 · Доступность', q='Эвристика доступности заставляет:',
       options=['переоценивать вероятность ярких, легко вспоминаемых событий','недооценивать редкое','считать точнее','избегать риска'], correct=0,
       explain='<b>Яркое кажется частым.</b> Авиакатастрофы пугают сильнее статистически опаснее дороги.'),
    dict(mod='1.4 · Ошибка выжившего', q='Ошибка выжившего — это:',
       options=['выводы только по «дошедшим», без учёта невидимых неудач','страх перед смертью','вера в удачу','переоценка экспертов'], correct=0,
       explain='<b>Невидимые проигравшие.</b> Самолёты Вальда: укреплять надо там, куда НЕ попадали вернувшиеся.'),
    dict(mod='1.5 · Неприятие потери', q='Неприятие потери означает, что:',
       options=['потеря ощущается сильнее равного по размеру выигрыша','люди любят рисковать','выигрыш важнее всего','эмоции не влияют на выбор'], correct=0,
       explain='<b>Потеря болезненнее.</b> Поэтому держатся за убыточные активы и «невозвратные» вложения.'),
    dict(mod='1.6 · Дебиасинг', q='Лучшая защита от искажений:',
       options=['знать их и применять процедуры/чек-листы','просто «стараться быть объективным»','доверять первой мысли','избегать любых решений'], correct=0,
       explain='<b>Процедуры, а не воля.</b> Чек-листы и правила работают лучше, чем намерение «не ошибаться».'),
   ]),
 dict(n=2, slug='veroyatnost', title='Вероятность и ожидаемая стоимость',
   accent='#d4a85a', bright='#f0cd7f', deep='#a07f3a', rgb='212,168,90',
   nxt=(f'{COURSE_BASE}/bayes/kviz','Квиз главы 3','Байес'),
   Q=[
    dict(mod='2.1 · Вероятность', q='Закон больших чисел говорит, что:',
       options=['при многих испытаниях частота приближается к вероятности','удача чередуется','после череды неудач «должно повезти»','вероятность зависит от настроения'], correct=0,
       explain='<b>Частота → вероятность.</b> На длинной дистанции доля исходов стремится к их вероятности.'),
    dict(mod='2.2 · Ожидаемая стоимость', q='Ожидаемая стоимость $E[X]$ считается как:',
       options=['сумма (вероятность × исход) по всем исходам','среднее всех исходов без весов','максимальный возможный выигрыш','самый вероятный исход'], correct=0,
       explain='<b>$E[X] = \\sum p_i v_i$.</b> Каждый исход взвешивается своей вероятностью.'),
    dict(mod='2.3 · Классы решений', q='Любое решение полезно рассматривать как:',
       options=['ставку с вероятностями и ценностями исходов','бинарный выбор «да/нет»','волю случая','вопрос интуиции'], correct=0,
       explain='<b>Решение — это ставка.</b> Разные классы решений отличаются профилем вероятностей и ценностей.'),
    dict(mod='2.4 · Дисперсия и риск', q='Почему ожидаемая стоимость — не всё?',
       options=['она не учитывает дисперсию и риск разорения','она всегда ошибочна','она слишком сложна','она запрещает рисковать'], correct=0,
       explain='<b>Риск разорения.</b> Ставка с плюсовым $E[X]$ губительна, если проигрыш банкротит.'),
    dict(mod='2.5 · Комбинаторика', q='Шанс угадать 6 чисел из 49 примерно:',
       options=['1 к ~14 миллионам','1 к тысяче','1 к миллиону','1 к ста'], correct=0,
       explain='<b>$C(49,6) \\approx 14$ млн.</b> Поэтому лотерея почти всегда имеет отрицательную ожидаемую стоимость.'),
    dict(mod='2.6 · Синтез', q='Рациональнее принимать решения:',
       options=['считая ожидаемую ценность, а не по интуиции «повезёт»','полагаясь на предчувствие','избегая любого риска','копируя других'], correct=0,
       explain='<b>Считать, а не чувствовать.</b> Числа дисциплинируют интуицию, особенно при редких исходах.'),
   ]),
 dict(n=3, slug='bayes', title='Байесовское обновление',
   accent='#5a87c4', bright='#7aa8e0', deep='#3d6494', rgb='90,135,196',
   nxt=(f'{COURSE_BASE}/igry/kviz','Квиз главы 4','Теория игр'),
   Q=[
    dict(mod='3.1 · Байес-мышление', q='Байесовское мышление — это:',
       options=['обновлять априорную веру под новые улики','верить только фактам','никогда не менять мнение','доверять интуиции'], correct=0,
       explain='<b>Prior → улика → posterior.</b> Рациональность — менять степень уверенности под данные.'),
    dict(mod='3.2 · Формула', q='По формуле Байеса итоговая вероятность зависит от:',
       options=['априорной веры, правдоподобия улики и базовой частоты','только от теста','только от желания','от числа попыток'], correct=0,
       explain='<b>Prior, правдоподобие, база.</b> Posterior $= \\frac{P(E|H)P(H)}{P(E)}$.'),
    dict(mod='3.3 · Базовая ставка', q='Пренебрежение базовой ставкой — это когда:',
       options=['игнорируют исходную распространённость и переоценивают тест','считают слишком осторожно','учитывают всё','доверяют статистике'], correct=0,
       explain='<b>Забыли про базу.</b> При редкой болезни даже точный тест даёт много ложных «плюсов».'),
    dict(mod='3.4 · Последовательное', q='Несколько независимых улик:',
       options=['последовательно обновляют веру (posterior становится новым prior)','отменяют друг друга','считаются только последней','не влияют'], correct=0,
       explain='<b>Цепочка обновлений.</b> Каждая улика двигает веру, начиная с обновлённой.'),
    dict(mod='3.5 · Сила улик', q='Сильная улика — это та, что:',
       options=['во много раз вероятнее при гипотезе, чем без неё','просто громкая','совпадает с мнением','появилась первой'], correct=0,
       explain='<b>Высокое отношение правдоподобия.</b> Сильно сдвигает posterior; слабая — почти нет.'),
    dict(mod='3.6 · Синтез', q='Рациональный ум при новых фактах:',
       options=['меняет мнение пропорционально силе улик','держится за исходную позицию','меняет мнение от любой мелочи','игнорирует факты'], correct=0,
       explain='<b>Пропорционально уликам.</b> Не упрямство и не флюгер — взвешенное обновление.'),
   ]),
 dict(n=4, slug='igry', title='Теория игр для жизни',
   accent='#9b6fa0', bright='#bf99c3', deep='#6b4a70', rgb='155,111,160',
   nxt=(f'{COURSE_BASE}/dannye/kviz','Квиз главы 5','Чтение данных'),
   Q=[
    dict(mod='4.1 · Что такое игра', q='Игра в теории игр — это ситуация, где:',
       options=['исход зависит от решений нескольких сторон','есть только случай','решает один человек','нет правил'], correct=0,
       explain='<b>Взаимозависимость.</b> Ваш лучший ход зависит от того, что сделают другие.'),
    dict(mod='4.2 · Дилемма заключённого', q='В дилемме заключённого взаимное предательство:',
       options=['хуже для обоих, чем взаимная кооперация','всегда выгодно','невозможно','не изучается'], correct=0,
       explain='<b>Оба проигрывают.</b> Индивидуально «выгодное» предательство ведёт к худшему общему исходу.'),
    dict(mod='4.3 · Повторяющиеся игры', q='В повторяющихся играх хорошо работает стратегия:',
       options=['начни с кооперации, отвечай тем же (tit-for-tat)','всегда предавай','всегда уступай','действуй случайно'], correct=0,
       explain='<b>Tit-for-tat.</b> Доброжелательность, ответность и прощение выигрывают вдолгую (Аксельрод).'),
    dict(mod='4.4 · Координация', q='Равновесие Нэша — это набор стратегий, где:',
       options=['никому не выгодно отклоняться в одиночку','все проигрывают','выигрывает только один','нет стабильности'], correct=0,
       explain='<b>Никто не хочет менять ход.</b> При фиксированных стратегиях других отклонение не улучшает результат.'),
    dict(mod='4.5 · Семья vs работа', q='Дилемму «семья vs работа» полезно видеть как:',
       options=['повторяющуюся игру, где репутация и доверие важнее разового выигрыша','разовую сделку','случайность','игру с нулевой суммой'], correct=0,
       explain='<b>Повторяющаяся игра.</b> С близкими вы играете много раундов — доверие ценнее сиюминутной выгоды.'),
    dict(mod='4.6 · Синтез', q='Вдолгую с теми же людьми обычно выгоднее:',
       options=['кооперация и надёжность','разовое предательство','избегать всех','скрывать намерения'], correct=0,
       explain='<b>Кооперация выигрывает.</b> «Тень будущего» делает надёжность рациональной стратегией.'),
   ]),
 dict(n=5, slug='dannye', title='Чтение данных и статей',
   accent='#5a8fa4', bright='#7aabc0', deep='#3e6680', rgb='90,143,164',
   nxt=(f'{COURSE_BASE}/resheniya/kviz','Квиз главы 6','Фреймворки'),
   Q=[
    dict(mod='5.1 · Корреляция', q='Корреляция между двумя величинами:',
       options=['не доказывает причинность','всегда означает причину','бессмысленна','доказывает обратное'], correct=0,
       explain='<b>Корреляция ≠ причинность.</b> Связь может объясняться третьим фактором или совпадением.'),
    dict(mod='5.2 · p-value', q='$p$-value — это:',
       options=['вероятность увидеть такие данные (или экстремальнее), если эффекта нет','вероятность, что гипотеза верна','размер эффекта','шанс на успех'], correct=0,
       explain='<b>При отсутствии эффекта.</b> Маленькое $p$ не равно «гипотеза верна» и не говорит о величине эффекта.'),
    dict(mod='5.3 · Доверительный интервал', q='Более узкий доверительный интервал означает:',
       options=['более точную оценку (обычно при большей выборке)','более слабый результат','ошибку','отсутствие эффекта'], correct=0,
       explain='<b>Точнее оценка.</b> Чем больше выборка, тем уже интервал неопределённости.'),
    dict(mod='5.4 · Отн. ≠ абс.', q='«Риск снизился на 50 процентов» без абсолютных чисел:',
       options=['может быть малозначимым (относительное ≠ абсолютное)','всегда огромная польза','означает удвоение жизни','бессмысленно'], correct=0,
       explain='<b>Относительное ≠ абсолютное.</b> 50 процентов от 2 процентов — это всего 1 процентный пункт.'),
    dict(mod='5.5 · Ловушки статей', q='Красный флаг исследования:',
       options=['выбор удобных результатов, p-hacking, крошечная выборка','крупная выборка','предрегистрация','повторяемость'], correct=0,
       explain='<b>Cherry-picking и p-hacking.</b> Подгонка под «значимость» делает результат ненадёжным.'),
    dict(mod='5.6 · Синтез', q='Читая медицинскую новость, в первую очередь:',
       options=['ищите абсолютные числа и размер эффекта','верьте заголовку','смотрите на громкость','доверяйте одному исследованию'], correct=0,
       explain='<b>Абсолютные числа.</b> Они показывают реальную величину пользы или вреда.'),
   ]),
 dict(n=6, slug='resheniya', title='Фреймворки решений',
   accent='#3d8a8e', bright='#5fb5b9', deep='#2a5e62', rgb='61,138,142',
   nxt=(COURSE_BASE,'На главную курса', COURSE_NAME),
   Q=[
    dict(mod='6.1 · Зачем фреймворки', q='Фреймворк решения особенно полезен, когда решение:',
       options=['крупное, неочевидное и с неопределённостью','мелкое и привычное','уже принято','чужое'], correct=0,
       explain='<b>Большие неопределённые решения.</b> Для рутины интуиция ок; для важного — структура.'),
    dict(mod='6.2 · Дерево решений', q='Дерево решений помогает:',
       options=['разложить выбор на ветви и сравнить их ожидаемую ценность','угадать будущее','избежать выбора','усложнить всё'], correct=0,
       explain='<b>Ветви × $E[X]$.</b> Раскладываешь исходы, веса и ценности — и сравниваешь.'),
    dict(mod='6.3 · 10/10/10', q='Правило 10/10/10 предлагает спросить:',
       options=['как я отнесусь к решению через 10 минут, 10 месяцев и 10 лет','сколько это стоит','что скажут другие','какова вероятность'], correct=0,
       explain='<b>Три горизонта.</b> Снимает власть сиюминутной эмоции над важным выбором.'),
    dict(mod='6.4 · Инверсия Мангера', q='Инверсия Мангера советует:',
       options=['думать от обратного: как всё испортить — и избегать этого','копировать успешных','идти ва-банк','ждать знака'], correct=0,
       explain='<b>Избегай глупости.</b> Часто полезнее устранить пути к провалу, чем искать путь к успеху.'),
    dict(mod='6.5 · Predict & verify', q='Predict & verify — это практика:',
       options=['записывать прогнозы и потом сверять с реальностью','верить интуиции','избегать прогнозов','менять прогноз задним числом'], correct=0,
       explain='<b>Калибровка.</b> Запись прогнозов и проверка — единственный способ улучшать суждение.'),
    dict(mod='6.6 · Личная система', q='Личная система решений нужна, чтобы:',
       options=['принимать важные решения структурно, а не на искажениях','решать быстрее всех','никогда не ошибаться','избегать ответственности'], correct=0,
       explain='<b>Структура против искажений.</b> Система превращает уроки курса в привычку рационального выбора.'),
   ]),
]

TPL = r'''<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Квиз главы @@N@@ · @@TITLE@@ · @@CNAME@@</title>
<meta name="description" content="Квиз главы «@@TITLE@@»: шесть вопросов — по одному на каждый модуль главы. Мгновенная обратная связь, прогресс сохраняется.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,500;0,600;0,700;1,400;1,500;1,600&family=PT+Serif:ital,wght@0,400;0,700;1,400;1,700&family=Manrope:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
<script defer src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/contrib/auto-render.min.js"
  onload="renderMathInElement(document.body,{delimiters:[{left:'$$',right:'$$',display:true},{left:'$',right:'$',display:false}],throwOnError:false,strict:false});"></script>
<style>
:root{
  --ink:#0a0e1a;--ink-2:#0e1322;--surface:#131826;--surface-2:#1a2138;
  --line:#2a3252;--line-soft:#1f2740;
  --cream:#ece4d0;--cream-soft:#d9cfb4;--muted:#a89a7a;--muted-2:#7d745f;
  --burgundy:#c4504c;--burgundy-2:#e07672;
  --accent:@@ACCENT@@;--accent-bright:@@BRIGHT@@;--accent-deep:@@DEEP@@;
  --serif:'Cormorant Garamond','PT Serif',Georgia,serif;
  --body:'PT Serif','Georgia',serif;
  --sans:'Manrope',system-ui,sans-serif;
  --mono:'JetBrains Mono',ui-monospace,monospace;
}
*{box-sizing:border-box}
html,body{margin:0;padding:0}
html{scroll-behavior:smooth}
body{font-family:var(--body);background:var(--ink);color:var(--cream);font-size:17px;line-height:1.65;-webkit-font-smoothing:antialiased;background-image:radial-gradient(ellipse at 15% 5%,rgba(@@RGB@@,.07) 0%,transparent 50%),linear-gradient(180deg,#0a0e1a 0%,#0e1322 100%);background-attachment:fixed;min-height:100vh;position:relative}
body::before{content:'';position:fixed;inset:0;pointer-events:none;z-index:1;background-image:linear-gradient(rgba(@@RGB@@,.025) 1px,transparent 1px),linear-gradient(90deg,rgba(@@RGB@@,.025) 1px,transparent 1px);background-size:32px 32px;mask-image:radial-gradient(ellipse 80% 60% at center,black 40%,transparent 100%)}
h1,h2,h3,h4{font-family:var(--serif);font-weight:500;line-height:1.18;color:var(--cream)}
h1{font-size:clamp(2rem,4.5vw,2.9rem);letter-spacing:-.015em}
em,i{color:var(--cream-soft);font-style:italic}
strong,b{color:var(--cream);font-weight:600}
p{margin:.6em 0}
a{color:var(--accent-bright);text-decoration:none;transition:.2s}
.kicker{font-family:var(--sans);font-size:.72rem;font-weight:600;letter-spacing:.22em;text-transform:uppercase;color:var(--accent-bright);display:inline-flex;align-items:center;gap:10px}
.kicker::before{content:'';width:24px;height:1px;background:var(--accent-bright);opacity:.6}
.container{max-width:820px;margin:0 auto;padding:0 28px;position:relative;z-index:2}
.topbar{position:sticky;top:0;z-index:50;background:rgba(10,14,26,.78);backdrop-filter:blur(14px);border-bottom:1px solid var(--line-soft)}
.topbar-inner{display:flex;align-items:center;justify-content:space-between;padding:14px 28px;max-width:1100px;margin:0 auto;gap:18px}
.brand{display:flex;align-items:center;gap:14px;text-decoration:none;color:inherit}
.brand-mark{width:46px;height:46px;border:1px solid var(--accent);display:grid;place-items:center;font-family:var(--serif);font-style:italic;font-size:1.05rem;color:var(--accent-bright);line-height:1;flex-shrink:0}
.brand-text{display:flex;flex-direction:column;line-height:1.15}
.brand-name{font-family:var(--serif);color:var(--cream);font-size:1.04rem}
.brand-sub{font-family:var(--sans);font-size:.66rem;letter-spacing:.18em;text-transform:uppercase;color:var(--muted)}
.breadcrumb{display:flex;align-items:center;gap:10px;font-family:var(--sans);font-size:.72rem;letter-spacing:.1em;color:var(--cream-soft)}
.breadcrumb a{color:var(--cream-soft)}.breadcrumb a:hover{color:var(--accent-bright)}
.breadcrumb .sep{color:var(--muted);font-family:var(--serif);font-style:italic}
.breadcrumb .current{color:var(--accent-bright);font-weight:600}
.back-link{font-family:var(--sans);font-size:.78rem;font-weight:500;color:var(--cream-soft);display:inline-flex;align-items:center;gap:8px;padding:7px 14px;border:1px solid var(--line);border-radius:2px;transition:.2s}
.back-link:hover{border-color:var(--accent-bright);color:var(--accent-bright)}
.back-link::before{content:'←';font-family:var(--serif);font-size:1rem}
@media (max-width:880px){.topbar-inner{padding:12px 18px}.brand-sub,.breadcrumb{display:none}}
.hero{padding:64px 0 40px;border-bottom:1px solid var(--line-soft);text-align:center}
.hero .h-mark{font-family:var(--serif);font-style:italic;font-size:2.6rem;color:var(--accent-bright);opacity:.7;line-height:1;margin-bottom:10px}
.hero h1{margin:8px 0 16px}
.hero h1 .em{font-style:italic;color:var(--accent-bright);font-weight:400}
.hero-lead{font-size:1.02rem;color:var(--cream-soft);max-width:640px;margin:0 auto;line-height:1.6}
.hero-lead b{color:var(--cream)}.hero-lead em{color:var(--accent-bright)}
.quiz-wrap{padding:46px 0 10px}
.quiz{max-width:780px;margin:0 auto;background:linear-gradient(170deg,var(--surface) 0%,var(--ink-2) 100%);border:1px solid var(--accent-deep);border-left:3px solid var(--accent);border-radius:3px;padding:28px 32px}
@media (max-width:580px){.quiz{padding:22px 18px}}
.quiz-head{display:flex;align-items:center;justify-content:space-between;gap:14px;margin-bottom:8px;padding-bottom:14px;border-bottom:1px dashed var(--line);flex-wrap:wrap}
.quiz-tag{font-family:var(--sans);font-size:.66rem;font-weight:700;letter-spacing:.18em;text-transform:uppercase;color:var(--accent-bright);padding:4px 10px;background:rgba(@@RGB@@,.16);border-radius:2px}
.quiz-score{font-family:var(--mono);font-size:.9rem;color:var(--cream-soft)}
.quiz-intro{font-size:.9rem;color:var(--muted);line-height:1.5;margin:12px 0 8px}
.quiz-q{padding:18px 0;border-bottom:1px solid var(--line-soft)}
.quiz-q:last-of-type{border-bottom:none}
.q-mod{display:inline-block;font-family:var(--sans);font-size:.6rem;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--accent-bright);background:rgba(@@RGB@@,.12);border:1px solid var(--accent-deep);border-radius:2px;padding:3px 9px;margin-bottom:10px}
.q-text{font-size:.99rem;color:var(--cream);line-height:1.5;margin-bottom:12px;display:flex;gap:10px}
.q-text .q-num{font-family:var(--serif);font-style:italic;font-size:1.25rem;color:var(--accent-bright);flex-shrink:0;line-height:1.2}
.q-options{display:flex;flex-direction:column;gap:8px}
.q-opt{font-family:var(--body);font-size:.93rem;text-align:left;padding:11px 14px;background:var(--ink-2);border:1px solid var(--line);border-radius:3px;color:var(--cream-soft);cursor:pointer;transition:.18s}
.q-opt:hover:not(.disabled){border-color:var(--accent-bright);color:var(--cream)}
.q-opt.disabled{cursor:default}
.q-opt.correct{background:rgba(@@RGB@@,.20);border-color:var(--accent);color:var(--cream)}
.q-opt.correct::after{content:' ✓';color:var(--accent-bright);font-weight:700}
.q-opt.incorrect{background:rgba(196,80,76,.16);border-color:var(--burgundy);color:var(--cream)}
.q-opt.incorrect::after{content:' ✗';color:var(--burgundy-2);font-weight:700}
.q-explain{display:none;margin-top:10px;padding:11px 14px;background:rgba(0,0,0,.22);border-left:2px solid var(--accent-deep);border-radius:0 2px 2px 0;font-size:.88rem;color:var(--cream-soft);line-height:1.5}
.q-explain.show{display:block}
.q-explain b{color:var(--cream)}.q-explain em{color:var(--accent-bright)}
.quiz-foot{margin-top:18px;padding-top:14px;border-top:1px dashed var(--line);display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap}
.quiz-result{font-family:var(--sans);font-size:.84rem;color:var(--cream-soft)}
.quiz-result b{color:var(--accent-bright)}
.quiz-reset{font-family:var(--sans);font-size:.74rem;font-weight:600;padding:8px 16px;border-radius:2px;border:1px solid var(--line);background:transparent;color:var(--cream-soft);cursor:pointer;transition:.2s}
.quiz-reset:hover{border-color:var(--accent-bright);color:var(--accent-bright)}
.nav-prev-next{display:grid;grid-template-columns:1fr 1fr;gap:14px;max-width:780px;margin:30px auto 0;padding:0 28px}
@media (max-width:580px){.nav-prev-next{grid-template-columns:1fr}}
.nav-card{padding:18px 22px;background:linear-gradient(170deg,var(--surface) 0%,var(--ink-2) 100%);border:1px solid var(--line);border-radius:3px;text-decoration:none;color:inherit;transition:.25s;display:flex;flex-direction:column;gap:6px}
.nav-card:hover{border-color:var(--accent-bright);transform:translateY(-2px)}
.nav-card.prev{text-align:left}.nav-card.next{text-align:right}
.nav-card .nv-label{font-family:var(--sans);font-size:.66rem;font-weight:600;letter-spacing:.16em;text-transform:uppercase;color:var(--muted)}
.nav-card .nv-title{font-family:var(--serif);font-size:1.04rem;color:var(--cream)}
.nav-card .nv-title .em{font-style:italic;color:var(--accent-bright)}
.nav-card.prev .nv-label::before{content:'← '}
.nav-card.next .nv-label::after{content:' →'}
.footer{padding:40px 0 50px;border-top:1px solid var(--line-soft);text-align:center;background:var(--ink-2);margin-top:40px}
.footer .foot-mark{font-family:var(--serif);font-style:italic;color:var(--accent-bright);font-size:1.4rem;margin-bottom:10px;line-height:1}
.footer p{font-size:.84rem;color:var(--muted);margin:6px 0}
.footer .foot-links{display:inline-flex;gap:18px;margin-top:14px;flex-wrap:wrap;justify-content:center}
.footer .foot-links a{color:var(--cream-soft);font-family:var(--sans);font-size:.74rem;letter-spacing:.1em}
.footer .foot-links a:hover{color:var(--accent-bright)}
.katex{font-size:1em !important}
.katex-display{margin:.4em 0 !important;overflow-x:auto;overflow-y:hidden}
</style>
</head>
<body>
<header class="topbar">
  <div class="topbar-inner">
    <a class="brand" href="@@CBASE@@/@@SLUG@@">
      <div class="brand-mark">@@N@@</div>
      <div class="brand-text">
        <span class="brand-name">Квиз главы @@N@@</span>
        <span class="brand-sub">@@TITLE@@</span>
      </div>
    </a>
    <nav class="breadcrumb">
      <a href="/">Курс</a><span class="sep">/</span>
      <a href="@@CBASE@@">Логика</a><span class="sep">/</span>
      <a href="@@CBASE@@/@@SLUG@@">Гл. @@N@@</a><span class="sep">/</span>
      <span class="current">Квиз</span>
    </nav>
    <a class="back-link" href="@@CBASE@@/@@SLUG@@">К Главе @@N@@</a>
  </div>
</header>
<section class="hero">
  <div class="container">
    <div class="h-mark">?</div>
    <span class="kicker">Глава @@N@@ · Проверь себя</span>
    <h1>Квиз главы: <span class="em">@@TITLE@@</span></h1>
    <p class="hero-lead">Шесть вопросов — <b>по одному на каждый модуль</b> главы. Выберите ответ и сразу увидите верный вариант с пояснением. <em>Прогресс сохраняется.</em></p>
  </div>
</section>
<div class="quiz-wrap">
  <div class="container">
    <section class="quiz" id="quiz">
      <div class="quiz-head">
        <span class="quiz-tag">Квиз главы @@N@@</span>
        <span class="quiz-score" id="quiz-score">0 / 6</span>
      </div>
      <p class="quiz-intro">Шесть модулей главы — шесть вопросов.</p>
      <div id="quiz-root"></div>
      <div class="quiz-foot">
        <span class="quiz-result" id="quiz-result">Отвечено: 0 из 6</span>
        <button class="quiz-reset" id="quiz-reset">Сбросить квиз</button>
      </div>
    </section>
  </div>
</div>
<nav class="nav-prev-next">
  <a class="nav-card prev" href="@@CBASE@@/@@SLUG@@">
    <span class="nv-label">К главе @@N@@</span>
    <span class="nv-title">@@TITLE@@</span>
  </a>
  <a class="nav-card next" href="@@NXT_HREF@@">
    <span class="nv-label">@@NXT_LABEL@@</span>
    <span class="nv-title"><span class="em">@@NXT_TITLE@@</span></span>
  </a>
</nav>
<footer class="footer">
  <div class="container">
    <div class="foot-mark">✱</div>
    <p>Квиз главы @@N@@ · @@TITLE@@</p>
    <p>Курс <a href="@@CBASE@@">«@@CNAME@@»</a></p>
    <p class="foot-links">
      <a href="/">На главную</a>
      <a href="@@CBASE@@">К курсу</a>
      <a href="@@CBASE@@/@@SLUG@@">← К Главе @@N@@</a>
    </p>
  </div>
</footer>
<script>
const QUIZ_KEY = '@@STORAGE@@';
const QUIZ = @@QUIZJS@@;
let quizState = {};
function rerenderMath(el){ if(window.renderMathInElement){ renderMathInElement(el, {delimiters:[{left:'$$',right:'$$',display:true},{left:'$',right:'$',display:false}],throwOnError:false,strict:false}); } }
function saveQuiz(){ try{ localStorage.setItem(QUIZ_KEY, JSON.stringify(quizState)); }catch(e){} }
function loadQuiz(){ try{ const r=localStorage.getItem(QUIZ_KEY); if(r) quizState=JSON.parse(r); }catch(e){ quizState={}; } }
function buildQuiz(){
  const root = document.getElementById('quiz-root'); let html = '';
  QUIZ.forEach((item, qi) => {
    html += `<div class="quiz-q" data-q="${qi}"><span class="q-mod">${item.mod}</span><div class="q-text"><span class="q-num">${qi+1}</span><span>${item.q}</span></div>`;
    html += `<div class="q-options">`;
    item.options.forEach((o, oi) => { html += `<button class="q-opt" data-q="${qi}" data-o="${oi}">${o}</button>`; });
    html += `</div><div class="q-explain" id="qe-${qi}">${item.explain}</div></div>`;
  });
  root.innerHTML = html;
  root.querySelectorAll('.q-opt').forEach(b => b.addEventListener('click', onOpt));
  Object.keys(quizState).forEach(qi => applyQ(Number(qi)));
}
function applyQ(qi){
  const item = QUIZ[qi], st = quizState[qi]; if (!st) return;
  const qEl = document.querySelector(`.quiz-q[data-q="${qi}"]`); if (!qEl) return;
  qEl.querySelectorAll('.q-opt').forEach((b, oi) => { b.classList.add('disabled'); if (oi === item.correct) b.classList.add('correct'); else if (oi === st.choice) b.classList.add('incorrect'); });
  document.getElementById('qe-'+qi).classList.add('show');
}
function onOpt(e){ const qi=Number(e.currentTarget.dataset.q), oi=Number(e.currentTarget.dataset.o); if (quizState[qi]) return; quizState[qi]={answered:true,correct:oi===QUIZ[qi].correct,choice:oi}; applyQ(qi); saveQuiz(); updateScore(); }
function updateScore(){
  const ans=Object.keys(quizState).length, ok=Object.values(quizState).filter(s=>s.correct).length;
  document.getElementById('quiz-score').textContent = `${ok} / ${QUIZ.length}`;
  const res=document.getElementById('quiz-result');
  if (ans===0){ res.textContent='Отвечено: 0 из '+QUIZ.length; return; }
  if (ans<QUIZ.length){ res.innerHTML=`Отвечено: <b>${ans}</b> из ${QUIZ.length} · верно ${ok}`; return; }
  let verdict = ok===QUIZ.length ? 'отлично — глава усвоена!' : (ok>=Math.ceil(QUIZ.length*0.6) ? 'хорошо!' : 'стоит перечитать главу');
  res.innerHTML = `Результат: <b>${ok} / ${QUIZ.length}</b> — ${verdict}`;
}
function init(){
  loadQuiz(); buildQuiz(); updateScore();
  document.getElementById('quiz-reset').addEventListener('click', () => {
    quizState = {}; try{ localStorage.removeItem(QUIZ_KEY); }catch(e){}
    buildQuiz(); updateScore(); rerenderMath(document.getElementById('quiz-root'));
  });
}
init();
</script>
</body>
</html>
'''

def build():
    made = []
    for c in CH:
        qjs = json.dumps([{'mod':q['mod'],'q':q['q'],'options':q['options'],'correct':q['correct'],'explain':q['explain']} for q in c['Q']], ensure_ascii=False, indent=2)
        html = (TPL
          .replace('@@N@@', str(c['n']))
          .replace('@@SLUG@@', c['slug'])
          .replace('@@TITLE@@', c['title'])
          .replace('@@ACCENT@@', c['accent']).replace('@@BRIGHT@@', c['bright']).replace('@@DEEP@@', c['deep'])
          .replace('@@RGB@@', c['rgb'])
          .replace('@@STORAGE@@', f"lg-c{c['n']}-kviz")
          .replace('@@NXT_HREF@@', c['nxt'][0]).replace('@@NXT_LABEL@@', c['nxt'][1]).replace('@@NXT_TITLE@@', c['nxt'][2])
          .replace('@@CBASE@@', COURSE_BASE).replace('@@CNAME@@', COURSE_NAME)
          .replace('@@QUIZJS@@', qjs))
        d = os.path.join(OUT_BASE, c['slug']); os.makedirs(d, exist_ok=True)
        out = os.path.join(d, 'kviz.html')
        open(out, 'w', encoding='utf-8').write(html)
        made.append((c['slug'], len(c['Q']), os.path.getsize(out)))
    return made

if __name__ == '__main__':
    m = build()
    print(f'Сгенерировано квиз-страниц: {len(m)}')
    for s, n, sz in m:
        print(f'  {COURSE_BASE}/{s}/kviz.html — {n} вопросов, {sz} B')
