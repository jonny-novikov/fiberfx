#!/usr/bin/env python3
"""
build_chapter_quiz.py — генератор страниц «Квиз главы» для курса
«Право повседневной жизни». На страницу: 6 вопросов — по одному на каждый
модуль главы, тема главы, бейдж модуля, цепочечная навигация, прогресс в localStorage.
Движок — тот же, что в курсе I (валидирован). Запуск:  python3 build_chapter_quiz.py
Выход (по умолчанию): <repo>/docs/law/toolkit/.gen/{глава}/kviz.html — СТЕЙДЖИНГ-папка,
а НЕ живое дерево law/. Лендинги/квизы в law/ местами вручную допилены (интерактив Гл.2/3,
сквозная линия «Несовершеннолетние»), поэтому генератор не пишет туда по умолчанию —
сгенерируй в .gen, сравни (diff) и перенеси нужное. Чтобы писать прямо в живое дерево:
  OUT_BASE=<repo>/law python3 build_chapter_quiz.py
"""
import json, os

# Локальная адаптация: путь резолвится от расположения скрипта (CWD-независимо).
# docs/law/toolkit/law/<this> -> вверх 4 уровня = корень репозитория.
_HERE = os.path.dirname(os.path.abspath(__file__))
_REPO_ROOT = os.path.abspath(os.path.join(_HERE, '..', '..', '..', '..'))
OUT_BASE = os.environ.get('OUT_BASE', os.path.join(_REPO_ROOT, 'docs', 'law', 'toolkit', '.gen'))
COURSE_NAME = 'Право повседневной жизни'
COURSE_BASE = '/law'

CH = [
 dict(n=1, slug='dogovor', title='Как читать договор',
   accent='#5a8fa4', bright='#7aabc0', deep='#3e6680', rgb='90,143,164',
   nxt=(f'{COURSE_BASE}/potrebitel/kviz','Квиз главы 2','Права потребителя'),
   Q=[
    dict(mod='1.1 · Сила подписи', q='Подписанный вами договор:',
       options=['обязывает, даже если вы его не прочитали','не действует без печати','можно не исполнять, если не читал','действует только сутки'], correct=0,
       explain='<b>Подпись обязывает.</b> «Не читал» — не освобождает от условий. Поэтому читать нужно ДО подписи.'),
    dict(mod='1.2 · Анатомия', q='Существенное условие почти любого договора — это:',
       options=['предмет договора','цвет бумаги','подпись свидетеля','дата печати'], correct=0,
       explain='<b>Предмет договора.</b> Без согласованного предмета договор обычно считается незаключённым.'),
    dict(mod='1.3 · Красные флаги', q='«Красный флаг» в договоре — это, например:',
       options=['автопролонгация и право одностороннего изменения условий','указание сторон','наличие даты','реквизиты счёта'], correct=0,
       explain='<b>Автопролонгация и односторонние изменения.</b> Такие пункты стоит замечать и оценивать до подписи.'),
    dict(mod='1.4 · Автопролонгация', q='Чтобы подписка не продлилась автоматически, обычно нужно:',
       options=['уведомить об отказе в срок до конца периода','ничего не делать','перестать платить молча','позвонить в любой день'], correct=0,
       explain='<b>Уведомить в срок.</b> Условие о пролонгации задаёт срок отказа — пропустите его, и договор продлится. Сверяйте условия договора.'),
    dict(mod='1.5 · Подсудность', q='Условие о подсудности в договоре определяет:',
       options=['в каком суде будут рассматриваться споры','размер налога','срок гарантии','валюту платежа'], correct=0,
       explain='<b>Где судиться.</b> Иногда спор «уводят» в неудобный для вас суд — это стоит замечать.'),
    dict(mod='1.6 · Перед подписью', q='Перед подписанием договора разумнее всего:',
       options=['прочитать целиком и пройтись по чек-листу «красных флагов»','подписать и разобраться потом','довериться менеджеру','смотреть только на цену'], correct=0,
       explain='<b>Прочитать и проверить.</b> Чек-лист «красных флагов» экономит деньги и нервы.'),
   ]),
 dict(n=2, slug='potrebitel', title='Права потребителя',
   accent='#d4a85a', bright='#f0cd7f', deep='#a07f3a', rgb='212,168,90',
   nxt=(f'{COURSE_BASE}/trud/kviz','Квиз главы 3','Трудовые отношения'),
   Q=[
    dict(mod='2.1 · Основы', q='Права потребителя в РФ регулирует прежде всего:',
       options=['Закон «О защите прав потребителей»','Уголовный кодекс','Налоговый кодекс','Устав магазина'], correct=0,
       explain='<b>ЗоЗПП № 2300-1.</b> Базовый закон о возврате, гарантиях и претензиях. Сверяйте действующую редакцию.'),
    dict(mod='2.2 · Возврат и обмен', q='Непродовольственный товар надлежащего качества обычно можно обменять в течение:',
       options=['14 дней (не считая дня покупки)','1 года','3 дней','любого срока'], correct=0,
       explain='<b>14 дней.</b> Есть перечень невозвратных товаров. Сверяйте действующую редакцию ЗоЗПП.'),
    dict(mod='2.3 · Брак товара', q='Если товар оказался с недостатком, потребитель вправе:',
       options=['требовать ремонт, замену, снижение цены или возврат денег','только ждать','только обменять на тот же','ничего'], correct=0,
       explain='<b>Несколько требований на выбор.</b> Конкретный набор и условия — по ЗоЗПП; зависит от ситуации.'),
    dict(mod='2.4 · Гарантия', q='Гарантийный срок — это период, в течение которого:',
       options=['можно предъявить требования по недостаткам товара','товар нельзя возвращать','цена фиксирована','магазин закрыт'], correct=0,
       explain='<b>Окно для требований по недостаткам.</b> Сроки и порядок — по закону и договору.'),
    dict(mod='2.5 · Претензия', q='Грамотная письменная претензия продавцу:',
       options=['фиксирует требование и часто решает спор до суда','бесполезна','заменяет суд всегда','нужна только юристу'], correct=0,
       explain='<b>Часто решает спор досудебно.</b> Письменная форма и срок ответа — ключевые элементы.'),
    dict(mod='2.6 · Если отказали', q='Если продавец отказал, разумный следующий шаг:',
       options=['письменная претензия, затем Роспотребнадзор или суд','забыть','скандал в магазине','отзыв в соцсетях вместо претензии'], correct=0,
       explain='<b>Претензия → надзор/суд.</b> Документируйте обращения; это пригодится.'),
   ]),
 dict(n=3, slug='trud', title='Трудовые отношения',
   accent='#b8804a', bright='#d6a575', deep='#7e5a30', rgb='184,128,74',
   nxt=(f'{COURSE_BASE}/semya/kviz','Квиз главы 4','Семейное право'),
   Q=[
    dict(mod='3.1 · Договор', q='Трудовой договор обязательно содержит:',
       options=['трудовую функцию, место работы и условия оплаты','только зарплату','только должность','устные обещания'], correct=0,
       explain='<b>Существенные условия.</b> Перечень — в ТК РФ; сверяйте действующую редакцию.'),
    dict(mod='3.2 · Отпуск', q='Минимальный ежегодный оплачиваемый отпуск в общем случае:',
       options=['28 календарных дней','14 дней','7 дней','45 дней'], correct=0,
       explain='<b>28 календарных дней.</b> Для отдельных категорий — больше. Сверяйте ТК РФ.'),
    dict(mod='3.3 · Сверхурочные', q='Сверхурочная работа оплачивается:',
       options=['первые 2 часа — не менее 1,5×, далее — не менее 2×','всегда 1×','всегда 3×','не оплачивается'], correct=0,
       explain='<b>1,5× и 2×.</b> Минимальные коэффициенты по ТК РФ; договор/локальные акты могут больше.'),
    dict(mod='3.4 · Увольнение', q='При увольнении по собственному желанию работник обычно предупреждает работодателя:',
       options=['за 2 недели','за 1 день','за полгода','не обязан'], correct=0,
       explain='<b>2 недели.</b> Есть исключения и случаи по соглашению. Сверяйте ТК РФ.'),
    dict(mod='3.5 · Сокращение', q='При сокращении работнику, как правило, положено:',
       options=['выходное пособие (средний заработок)','ничего','только премия','штраф'], correct=0,
       explain='<b>Выходное пособие и гарантии.</b> Размер и условия — по ТК РФ; зависит от ситуации.'),
    dict(mod='3.6 · Защита', q='Если права на работе нарушены, можно обратиться:',
       options=['в трудовую инспекцию (Роструд) или суд','только к коллегам','в полицию по любому поводу','никуда'], correct=0,
       explain='<b>Роструд или суд.</b> Сохраняйте документы и переписку.'),
   ]),
 dict(n=4, slug='semya', title='Семейное право',
   accent='#c4504c', bright='#e07672', deep='#8e3a37', rgb='196,80,76',
   nxt=(f'{COURSE_BASE}/nasledstvo/kviz','Квиз главы 5','Наследство'),
   Q=[
    dict(mod='4.1 · Брак', q='Имущество, нажитое супругами в браке, по общему правилу:',
       options=['является их совместной собственностью','принадлежит только мужу','принадлежит государству','делится поровну только через суд'], correct=0,
       explain='<b>Совместная собственность.</b> Если иное не установлено брачным договором. Сверяйте СК РФ.'),
    dict(mod='4.2 · Брачный договор', q='Брачный договор может:',
       options=['изменить режим имущества супругов','определить, с кем останутся дети','лишить родителя прав','отменить алименты детям'], correct=0,
       explain='<b>Меняет имущественный режим.</b> Личные неимущественные отношения и права детей им не регулируются.'),
    dict(mod='4.3 · Личное имущество', q='Личным имуществом супруга обычно считается:',
       options=['полученное в дар или по наследству','зарплата за время брака','совместно купленная квартира','общие накопления'], correct=0,
       explain='<b>Дар и наследство — личное.</b> Нюансы (улучшения и т. п.) зависят от ситуации.'),
    dict(mod='4.4 · Развод', q='Развод при наличии общих несовершеннолетних детей оформляется:',
       options=['через суд','только в ЗАГС','устно','у нотариуса'], correct=0,
       explain='<b>Через суд.</b> Без детей и при согласии — обычно через ЗАГС. Сверяйте СК РФ.'),
    dict(mod='4.5 · Алименты', q='Алименты на одного ребёнка по общему правилу (доля от дохода):',
       options=['одна четверть (1/4)','половина','весь доход','одна десятая'], correct=0,
       explain='<b>1/4 на одного.</b> На двоих — 1/3, на троих и более — 1/2 (ст. 81 СК РФ). Сверяйте редакцию; возможна твёрдая сумма.'),
    dict(mod='4.6 · Споры', q='Споры о детях и разделе имущества при разводе (без соглашения) разрешает:',
       options=['суд','банк','работодатель','участковый'], correct=0,
       explain='<b>Суд.</b> Лучше — соглашение сторон; суд — когда договориться не вышло.'),
   ]),
 dict(n=5, slug='nasledstvo', title='Наследство и завещание',
   accent='#9b6fa0', bright='#bf99c3', deep='#6b4a70', rgb='155,111,160',
   nxt=(f'{COURSE_BASE}/pretenziya/kviz','Квиз главы 6','Конфликт и претензия'),
   Q=[
    dict(mod='5.1 · Сроки', q='Принять наследство нужно в течение:',
       options=['6 месяцев со дня открытия','1 месяца','3 лет','10 лет'], correct=0,
       explain='<b>6 месяцев.</b> Пропуск срока восстанавливается лишь по уважительным причинам. Сверяйте ГК РФ.'),
    dict(mod='5.2 · Очереди', q='Наследники первой очереди по закону — это:',
       options=['дети, супруг и родители','только дети','двоюродные братья','соседи'], correct=0,
       explain='<b>Первая очередь.</b> Следующие очереди наследуют, если нет предыдущей. Сверяйте ГК РФ.'),
    dict(mod='5.3 · Завещание', q='Чтобы завещание было действительным, оно обычно:',
       options=['удостоверяется нотариусом','пишется карандашом','объявляется устно при свидетелях','не требует формы'], correct=0,
       explain='<b>Нотариальная форма.</b> Есть особые случаи; общее правило — удостоверение у нотариуса.'),
    dict(mod='5.4 · Обязательная доля', q='Обязательная доля в наследстве составляет:',
       options=['не менее половины законной доли','весь объём наследства','одну десятую','ничего'], correct=0,
       explain='<b>Не менее 1/2 законной доли.</b> Защищает нетрудоспособных/несовершеннолетних. Сверяйте ст. 1149 ГК РФ.'),
    dict(mod='5.5 · Долги', q='Приняв наследство, наследник принимает:',
       options=['и имущество, и долги наследодателя','только имущество','только долги','ничего лишнего'], correct=0,
       explain='<b>И долги тоже.</b> Поэтому иногда выгоднее отказаться. Ответственность — в пределах наследства.'),
    dict(mod='5.6 · По закону', q='Если завещания нет, имущество наследуется:',
       options=['по закону, по очередям','государством всегда','случайным образом','по решению банка'], correct=0,
       explain='<b>По закону, по очередям.</b> Завещание меняет этот порядок (с учётом обязательной доли).'),
   ]),
 dict(n=6, slug='pretenziya', title='Конфликт и претензия',
   accent='#3d8a8e', bright='#5fb5b9', deep='#2a5e62', rgb='61,138,142',
   nxt=(COURSE_BASE,'На главную курса', COURSE_NAME),
   Q=[
    dict(mod='6.1 · Досудебный', q='Во многих спорах перед обращением в суд сначала нужно:',
       options=['направить досудебную претензию','сразу подавать иск','ждать год','ничего'], correct=0,
       explain='<b>Сначала претензия.</b> По ряду споров досудебный порядок обязателен. Сверяйте требования закона.'),
    dict(mod='6.2 · Претензия', q='Хорошая претензия содержит:',
       options=['суть требования, обоснование и срок для ответа','только эмоции','угрозы','чужие реквизиты'], correct=0,
       explain='<b>Требование, обоснование, срок.</b> Приложите доказательства и сохраните подтверждение отправки.'),
    dict(mod='6.3 · Давность', q='Общий срок исковой давности составляет:',
       options=['3 года','1 месяц','10 лет','бессрочно'], correct=0,
       explain='<b>3 года.</b> Есть специальные сроки и правила их исчисления. Сверяйте ГК РФ.'),
    dict(mod='6.4 · Какой суд', q='Имущественные споры небольшой суммы рассматривает обычно:',
       options=['мировой судья','Верховный суд','арбитраж','прокуратура'], correct=0,
       explain='<b>Мировой судья</b> — в пределах установленной суммы; крупнее — районный суд. Сверяйте подсудность и госпошлину (актуальный калькулятор).'),
    dict(mod='6.5 · Альтернативы', q='Кроме суда, потребитель может обратиться:',
       options=['в Роспотребнадзор (по потребительским спорам)','только к друзьям','в любое министерство','никуда'], correct=0,
       explain='<b>Надзорные органы и медиация.</b> Для разных споров — разные адресаты (Роспотребнадзор, Роструд и т. д.).'),
    dict(mod='6.6 · Путь спора', q='Разумный путь разрешения спора:',
       options=['сначала переговоры и претензия, затем — суд','сразу суд по любому поводу','молчать','только жалобы в соцсети'], correct=0,
       explain='<b>Претензия → суд.</b> Большинство споров решается до суда при грамотных действиях.'),
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
/* Крупнее шрифт на desktop (масштабирует все rem-размеры) */
@media (min-width:1024px){ html{font-size:18px} body{font-size:18.5px} }
@media (min-width:1440px){ html{font-size:19px} }
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
      <a href="@@CBASE@@">Право</a><span class="sep">/</span>
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
      <p class="law-note"><b>Важно:</b> образовательный материал, не юридическая консультация. Нормы РФ — сверяйте действующую редакцию.</p>
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
          .replace('@@STORAGE@@', f"law-c{c['n']}-kviz")
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
