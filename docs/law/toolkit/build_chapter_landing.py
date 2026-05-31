#!/usr/bin/env python3
"""
build_chapter_landing.py — генератор лендингов глав курса «Право повседневной жизни».
Лендинг: hero → 3 intro-карточки → сетка из 6 тайлов-модулей (последний — капстоун)
→ цепочка глав → футер. Тема главы, крупный десктоп-шрифт.
Выход: <repo>/law/{слаг}/index.html (по умолчанию; переопределяется OUT_BASE)
Тайлы ведут на модули (пути готовы, страницы строятся позже); ссылка «Квиз главы» уже работает.
"""
import os

# Default output target is the repo's served law/ tree, resolved relative to this
# script (docs/law/toolkit/ → repo root → law/) so it works on the local filesystem
# out of the box. OUT_BASE env still overrides it (e.g. a sandbox path).
_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
OUT_BASE = os.environ.get('OUT_BASE', os.path.join(_REPO_ROOT, 'law'))
COURSE_NAME = 'Право повседневной жизни'
COURSE_BASE = '/law'

# короткие подписи глав для цепочки
CHAIN = [(1,'iskazheniya','Искажения'),(2,'veroyatnost','Вероятность'),(3,'bayes','Байес'),
         (4,'igry','Игры'),(5,'dannye','Данные'),(6,'resheniya','Решения')]

CH = [
 dict(n=1, roman='I', slug='dogovor', title='Как читать договор', em='читать',
   accent='#5a8fa4', bright='#7aabc0', deep='#3e6680', rgb='90,143,164',
   lead='Подпись обязывает — даже если вы не читали. Взрослый подписывает <b>около 30</b> юридически значимых документов в год; навык — находить «красные флаги» <em>до</em> подписи, а не после.',
   quote='Договор читают не после проблемы, а до подписи. После — это уже не чтение, а сожаление.',
   qsrc='Принцип чтения до подписи',
   intro=[('Подпись = обязательство','«Не читал» не освобождает от условий. Сила подписи — в том, что вы согласились со всем текстом.'),
          ('Структура повторяется','Стороны, предмет, цена, срок, ответственность — зная анатомию, читать быстрее.'),
          ('Флаги предсказуемы','Автопролонгация, штрафы, подсудность, односторонние изменения — типовые ловушки.')],
   mods=[('1.1','sila','Зачем читать договор','Сила подписи и ~30 документов в год.'),
         ('1.2','anatomiya','Анатомия договора','Стороны, предмет, цена, срок, ответственность.'),
         ('1.3','flagi','Красные флаги','Автопролонгация, штрафы, подсудность, односторонние изменения.'),
         ('1.4','prolongatsiya','Автопролонгация и расторжение','Как не остаться в подписке: сроки отказа.'),
         ('1.5','shtrafy','Штрафы, неустойка, подсудность','Где судиться и сколько стоит нарушение.'),
         ('1.6','sintez','Синтез: чек-лист перед подписью','Свод «красных флагов» в один список.')]),
 dict(n=2, roman='II', slug='potrebitel', title='Права потребителя', em='потребителя',
   accent='#d4a85a', bright='#f0cd7f', deep='#a07f3a', rgb='212,168,90',
   lead='Закон «О защите прав потребителей» даёт вам <b>сильные</b> права: возврат, обмен, гарантии. Большинство споров решает не суд, а грамотная <em>претензия</em> за полчаса.',
   quote='Вежливая письменная претензия со ссылкой на закон решает больше споров, чем громкий скандал у кассы.',
   qsrc='Принцип грамотной претензии',
   intro=[('Закон на вашей стороне','ЗоЗПП — мощный инструмент; знать права уже половина успеха.'),
          ('Сроки и перечни','14 дней на обмен, перечень невозвратного, гарантийные сроки — конкретика решает.'),
          ('Претензия работает','Письменное требование с обоснованием часто закрывает спор без суда.')],
   mods=[('2.1','osnovy','Основы прав потребителя','Что гарантирует ЗоЗПП.'),
         ('2.2','vozvrat','Возврат и обмен','14 дней и перечень невозвратного.'),
         ('2.3','brak','Товар ненадлежащего качества','Недостаток, гарантия, выбор требования.'),
         ('2.4','garantiya','Гарантия и сроки','Гарантийный срок и сроки ответа.'),
         ('2.5','pretenziya','Претензия за 30 минут','Структура претензии (образец).'),
         ('2.6','sintez','Синтез: набор инструментов','Памятка потребителя.')]),
 dict(n=3, roman='III', slug='trud', title='Трудовые отношения', em='отношения',
   accent='#b8804a', bright='#d6a575', deep='#7e5a30', rgb='184,128,74',
   lead='Трудовой договор и ТК РФ дают защиту — но только если знать <b>сроки, оплату и порядок</b>: отпуск, сверхурочные, увольнение, выходное пособие.',
   quote='Трудовые права начинаются не с эмоций, а с трудового договора и точных сроков.',
   qsrc='Принцип трудовых гарантий',
   intro=[('Договор — основа','Существенные условия фиксируют ваши права; устные обещания ненадёжны.'),
          ('Время и оплата','28 дней отпуска, сверхурочные 1,5×/2× — конкретные правила ТК РФ.'),
          ('Порядок увольнения','Основания и сроки предупреждения защищают от произвола.')],
   mods=[('3.1','dogovor','Трудовой договор','Существенные условия договора.'),
         ('3.2','vremya','Рабочее время и отпуск','28 дней и накопление.'),
         ('3.3','oplata','Оплата и сверхурочные','Коэффициенты 1,5× и 2×.'),
         ('3.4','uvolnenie','Увольнение','Основания и предупреждение за 2 недели.'),
         ('3.5','posobie','Выходное пособие и гарантии','Сокращение и средний заработок.'),
         ('3.6','sintez','Синтез: трудовые права','Памятка работника.')]),
 dict(n=4, roman='IV', slug='semya', title='Семейное право', em='право',
   accent='#c4504c', bright='#e07672', deep='#8e3a37', rgb='196,80,76',
   lead='Брак — это и <b>имущественные</b> отношения. Знать про совместное и личное имущество, брачный договор, развод и алименты — значит избежать тяжёлых сюрпризов.',
   quote='Семейное право не про любовь, а про то, что считается общим, а что — личным.',
   qsrc='Принцип имущественной ясности',
   intro=[('Общее и личное','Нажитое в браке обычно общее; дар и наследство — личное.'),
          ('Договор и развод','Брачный договор меняет режим имущества; развод с детьми — через суд.'),
          ('Дети и алименты','Доли алиментов и интересы детей — отдельная, важная тема.')],
   mods=[('4.1','brak','Брак и его последствия','Правовые эффекты брака.'),
         ('4.2','brachnyy-dogovor','Брачный договор','Что можно и чего нельзя.'),
         ('4.3','imushchestvo','Общее и личное имущество','Режим имущества супругов.'),
         ('4.4','razvod','Развод','Через ЗАГС или через суд.'),
         ('4.5','alimenty','Дети и алименты','Доли 1/4, 1/3, 1/2 дохода.'),
         ('4.6','sintez','Синтез: семья и право','Памятка по семейному праву.')]),
 dict(n=5, roman='V', slug='nasledstvo', title='Наследство и завещание', em='завещание',
   accent='#9b6fa0', bright='#bf99c3', deep='#6b4a70', rgb='155,111,160',
   lead='Наследство открывается на <b>6 месяцев</b>. Знать очереди, обязательную долю и как составить завещание правильно с первого раза — чтобы воля исполнилась, а близкие не остались в спорах.',
   quote='Завещание, составленное правильно один раз, дороже десяти устных обещаний.',
   qsrc='Принцип ясной воли',
   intro=[('Срок и нотариус','Принять наследство — 6 месяцев; оформление идёт через нотариуса.'),
          ('Очереди и доля','Закон задаёт очереди наследников и защищает обязательную долю.'),
          ('Долги тоже наследуют','Принимая наследство, принимают и долги — иногда выгоднее отказ.')],
   mods=[('5.1','otkrytie','Как открывается наследство','Срок 6 месяцев, нотариус.'),
         ('5.2','ocheredi','Очереди наследования','Кто и в каком порядке.'),
         ('5.3','zaveshchanie','Завещание','Как сделать действительным.'),
         ('5.4','obyazatelnaya-dolya','Обязательная доля','Не менее 1/2 законной доли.'),
         ('5.5','prinyatie','Принятие и отказ','Долги наследодателя.'),
         ('5.6','sintez','Синтез: наследственное планирование','Памятка по наследству.')]),
 dict(n=6, roman='VI', slug='pretenziya', title='Конфликт и претензия', em='претензия',
   accent='#3d8a8e', bright='#5fb5b9', deep='#2a5e62', rgb='61,138,142',
   lead='Большинство споров решаемо <b>досудебно</b>. Знать путь от претензии к иску, сроки давности и куда обращаться — значит держать конфликт под контролем, а не бояться его.',
   quote='Сильная позиция в споре — это не громкость, а документы, сроки и понятный следующий шаг.',
   qsrc='Принцип спокойного спора',
   intro=[('Сначала претензия','По многим спорам досудебный порядок обязателен — и часто достаточен.'),
          ('Сроки решают','Общий срок исковой давности — 3 года; пропустить его опасно.'),
          ('Есть альтернативы','Кроме суда — надзорные органы и медиация для разных споров.')],
   mods=[('6.1','dosudebnyy','Досудебный порядок','Сначала претензия.'),
         ('6.2','sostavit','Как составить претензию','Структура и доказательства.'),
         ('6.3','davnost','Сроки и исковая давность','Общий срок 3 года.'),
         ('6.4','sud','Обращение в суд','Мировой/районный, госпошлина.'),
         ('6.5','alternativy','Альтернативы суду','Надзор, медиация, омбудсмен.'),
         ('6.6','sintez','Синтез: путь разрешения спора','Капстоун курса: дорожная карта.')]),
]

def intro_html(cards):
    return '\n'.join(
        f'        <div class="intro-card"><h3>{h}</h3><p>{p}</p></div>' for h, p in cards)

def tiles_html(slug, mods):
    out = []
    for i, (num, ms, title, desc) in enumerate(mods):
        cap = ' capstone' if i == len(mods) - 1 else ''
        tag = '<span class="tile-tag">капстоун</span>' if cap else ''
        out.append(
            f'        <a class="tile{cap}" href="{COURSE_BASE}/{slug}/{ms}">\n'
            f'          <div class="tile-top"><span class="tile-num">{num}</span>{tag}</div>\n'
            f'          <h3>{title}</h3><p>{desc}</p>\n'
            f'          <span class="tile-go">Открыть модуль</span>\n'
            f'        </a>')
    return '\n'.join(out)

def chain_html(cur_slug):
    out = []
    for n, slug, label in CHAIN:
        cls = ' cur' if slug == cur_slug else ''
        if slug == cur_slug:
            out.append(f'        <span class="chain-item cur"><span class="ci-n">{n}</span>{label}</span>')
        else:
            out.append(f'        <a class="chain-item" href="{COURSE_BASE}/{slug}"><span class="ci-n">{n}</span>{label}</a>')
    return '\n'.join(out)

TPL = r'''<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Глава @@N@@ · @@TITLE@@ · @@CNAME@@</title>
<meta name="description" content="@@TITLE@@ — глава @@N@@ курса «@@CNAME@@». Шесть модулей с интерактивами и квизом главы.">
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
  --accent:@@ACCENT@@;--accent-bright:@@BRIGHT@@;--accent-deep:@@DEEP@@;
  --serif:'Cormorant Garamond','PT Serif',Georgia,serif;
  --body:'PT Serif','Georgia',serif;
  --sans:'Manrope',system-ui,sans-serif;
  --mono:'JetBrains Mono',ui-monospace,monospace;
}
*{box-sizing:border-box}
html,body{margin:0;padding:0}
html{scroll-behavior:smooth}
body{font-family:var(--body);background:var(--ink);color:var(--cream);font-size:17px;line-height:1.65;-webkit-font-smoothing:antialiased;background-image:radial-gradient(ellipse at 15% 0%,rgba(@@RGB@@,.08) 0%,transparent 55%),linear-gradient(180deg,#0a0e1a 0%,#0e1322 100%);background-attachment:fixed;min-height:100vh;position:relative}
body::before{content:'';position:fixed;inset:0;pointer-events:none;z-index:1;background-image:linear-gradient(rgba(@@RGB@@,.022) 1px,transparent 1px),linear-gradient(90deg,rgba(@@RGB@@,.022) 1px,transparent 1px);background-size:34px 34px;mask-image:radial-gradient(ellipse 85% 60% at center,black 35%,transparent 100%)}
h1,h2,h3,h4{font-family:var(--serif);font-weight:500;line-height:1.16;color:var(--cream)}
h1{font-size:clamp(2.2rem,5vw,3.3rem);letter-spacing:-.02em}
h2{font-size:clamp(1.4rem,2.8vw,1.95rem);letter-spacing:-.01em}
h3{font-size:clamp(1.05rem,1.8vw,1.22rem)}
em,i{color:var(--cream-soft);font-style:italic}
strong,b{color:var(--cream);font-weight:600}
p{margin:.6em 0}
a{color:var(--accent-bright);text-decoration:none;transition:.2s}
.kicker{font-family:var(--sans);font-size:.72rem;font-weight:600;letter-spacing:.22em;text-transform:uppercase;color:var(--accent-bright);display:inline-flex;align-items:center;gap:10px}
.kicker::before{content:'';width:24px;height:1px;background:var(--accent-bright);opacity:.6}
.container{max-width:1080px;margin:0 auto;padding:0 32px;position:relative;z-index:2}
.topbar{position:sticky;top:0;z-index:50;background:rgba(10,14,26,.78);backdrop-filter:blur(14px);border-bottom:1px solid var(--line-soft)}
.topbar-inner{display:flex;align-items:center;justify-content:space-between;padding:14px 32px;max-width:1280px;margin:0 auto;gap:18px}
.brand{display:flex;align-items:center;gap:14px;text-decoration:none;color:inherit}
.brand-mark{width:48px;height:48px;border:1px solid var(--accent);display:grid;place-items:center;font-family:var(--serif);font-style:italic;font-size:1.15rem;color:var(--accent-bright);line-height:1;flex-shrink:0}
.brand-text{display:flex;flex-direction:column;line-height:1.15}
.brand-name{font-family:var(--serif);color:var(--cream);font-size:1.06rem}
.brand-sub{font-family:var(--sans);font-size:.66rem;letter-spacing:.18em;text-transform:uppercase;color:var(--muted)}
.breadcrumb{display:flex;align-items:center;gap:10px;font-family:var(--sans);font-size:.72rem;letter-spacing:.1em;color:var(--cream-soft)}
.breadcrumb a{color:var(--cream-soft)}.breadcrumb a:hover{color:var(--accent-bright)}
.breadcrumb .sep{color:var(--muted);font-family:var(--serif);font-style:italic}
.breadcrumb .current{color:var(--accent-bright);font-weight:600}
.back-link{font-family:var(--sans);font-size:.78rem;font-weight:500;color:var(--cream-soft);display:inline-flex;align-items:center;gap:8px;padding:7px 14px;border:1px solid var(--line);border-radius:2px;transition:.2s}
.back-link:hover{border-color:var(--accent-bright);color:var(--accent-bright)}
.back-link::before{content:'←';font-family:var(--serif);font-size:1rem}
@media (max-width:820px){.topbar-inner{padding:12px 18px}.brand-sub,.breadcrumb{display:none}}
.hero{padding:74px 0 54px;border-bottom:1px solid var(--line-soft);text-align:center}
.hero .hero-id{font-family:var(--serif);font-style:italic;font-size:3.4rem;color:var(--accent-bright);opacity:.6;line-height:1;margin-bottom:6px}
.hero .ch-badge{display:inline-block;font-family:var(--sans);font-size:.7rem;font-weight:700;letter-spacing:.22em;text-transform:uppercase;color:var(--accent-bright);border:1px solid var(--accent-deep);border-radius:2px;padding:6px 16px;margin-bottom:18px}
.hero h1{margin:8px auto 18px;max-width:16ch}
.hero h1 .em{font-style:italic;color:var(--accent-bright);font-weight:400}
.hero-lead{font-size:1.06rem;color:var(--cream-soft);max-width:680px;margin:0 auto;line-height:1.66}
.hero-lead b{color:var(--cream)}.hero-lead em{color:var(--accent-bright)}
.hero-quote{margin:28px auto 0;padding:22px 30px;max-width:660px;border-top:1px solid var(--line-soft);border-bottom:1px solid var(--line-soft);font-family:var(--serif);font-style:italic;font-size:1.1rem;color:var(--cream)}
.hero-quote .hq-src{display:block;margin-top:8px;font-family:var(--sans);font-style:normal;font-size:.72rem;letter-spacing:.14em;text-transform:uppercase;color:var(--accent-bright)}
.law-banner{background:rgba(0,0,0,.22);border-bottom:1px solid var(--line-soft)}
.law-banner p{font-family:var(--sans);font-size:.8rem;color:var(--muted);line-height:1.5;padding:14px 0;margin:0}
.law-banner p b{color:var(--cream-soft)}
.sect{padding:60px 0;border-bottom:1px solid var(--line-soft)}
.sect-head{text-align:center;margin-bottom:30px}
.sect-head .kicker{margin-bottom:12px;justify-content:center}
.sect-head h2 .em{font-style:italic;color:var(--accent-bright);font-weight:400}
.sect-head p{font-size:1rem;color:var(--cream-soft);max-width:660px;margin:10px auto 0;line-height:1.6}
.intro-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}
@media (max-width:760px){.intro-grid{grid-template-columns:1fr}}
.intro-card{padding:22px 24px;background:linear-gradient(165deg,var(--surface) 0%,var(--ink-2) 100%);border:1px solid var(--line);border-top:3px solid var(--accent);border-radius:0 0 3px 3px}
.intro-card h3{margin:0 0 7px;font-size:1.08rem}
.intro-card p{margin:0;font-size:.93rem;color:var(--cream-soft);line-height:1.55}
.tiles-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:14px}
@media (max-width:920px){.tiles-grid{grid-template-columns:repeat(2,1fr)}}
@media (max-width:600px){.tiles-grid{grid-template-columns:1fr}}
.tile{display:flex;flex-direction:column;gap:8px;padding:20px 22px;background:linear-gradient(165deg,var(--surface) 0%,var(--ink-2) 100%);border:1px solid var(--line);border-left:3px solid var(--accent);border-radius:0 3px 3px 0;transition:.22s}
.tile:hover{transform:translateY(-3px);border-color:var(--accent-bright);border-left-color:var(--accent-bright)}
.tile-top{display:flex;align-items:center;justify-content:space-between}
.tile-num{font-family:var(--mono);font-size:.82rem;font-weight:600;color:var(--accent-bright)}
.tile-tag{font-family:var(--sans);font-size:.56rem;font-weight:700;letter-spacing:.1em;text-transform:uppercase;color:var(--accent-bright);border:1px solid var(--accent-deep);border-radius:2px;padding:2px 8px}
.tile h3{margin:0;font-size:1.1rem;color:var(--cream)}
.tile p{margin:0;font-size:.9rem;color:var(--cream-soft);line-height:1.5;flex:1}
.tile-go{font-family:var(--sans);font-size:.74rem;font-weight:600;color:var(--accent-bright);margin-top:4px}
.tile-go::after{content:' →'}
.tile.capstone{background:linear-gradient(165deg,rgba(@@RGB@@,.10) 0%,var(--ink-2) 100%);border-color:var(--accent-deep)}
.quiz-cta{text-align:center;margin-top:28px}
.quiz-cta a{display:inline-flex;align-items:center;gap:10px;font-family:var(--sans);font-size:.84rem;font-weight:600;padding:12px 24px;border:1px solid var(--accent);border-radius:3px;color:var(--accent-bright);transition:.2s}
.quiz-cta a:hover{background:var(--accent);color:var(--ink)}
.quiz-cta a::after{content:'→';font-family:var(--serif)}
.chain{display:flex;flex-wrap:wrap;gap:10px;justify-content:center}
.chain-item{display:inline-flex;align-items:center;gap:8px;font-family:var(--sans);font-size:.8rem;font-weight:500;padding:9px 15px;border:1px solid var(--line);border-radius:2px;color:var(--cream-soft);transition:.2s}
.chain-item:hover{border-color:var(--accent-bright);color:var(--accent-bright)}
.chain-item .ci-n{font-family:var(--serif);font-style:italic;color:var(--accent-bright)}
.chain-item.cur{background:var(--accent);color:var(--ink);border-color:var(--accent);font-weight:700}
.chain-item.cur .ci-n{color:var(--ink)}
.footer{padding:44px 0 54px;border-top:1px solid var(--line-soft);text-align:center;background:var(--ink-2);margin-top:30px}
.footer .foot-mark{font-family:var(--serif);font-style:italic;color:var(--accent-bright);font-size:1.5rem;margin-bottom:10px;line-height:1}
.footer p{font-size:.86rem;color:var(--muted);margin:6px 0}
.footer .foot-links{display:inline-flex;gap:18px;margin-top:14px;flex-wrap:wrap;justify-content:center}
.footer .foot-links a{color:var(--cream-soft);font-family:var(--sans);font-size:.76rem;letter-spacing:.08em}
.footer .foot-links a:hover{color:var(--accent-bright)}
.katex{font-size:1em !important}
/* Крупнее шрифт на desktop (масштабирует все rem-размеры) */
@media (min-width:1024px){ html{font-size:18px} body{font-size:18.5px} }
@media (min-width:1440px){ html{font-size:19px} }
</style>
</head>
<body>
<header class="topbar">
  <div class="topbar-inner">
    <a class="brand" href="@@CBASE@@">
      <div class="brand-mark">@@ROMAN@@</div>
      <div class="brand-text">
        <span class="brand-name">@@TITLE@@</span>
        <span class="brand-sub">Курс · Логика · Глава @@N@@</span>
      </div>
    </a>
    <nav class="breadcrumb">
      <a href="/">Курс</a><span class="sep">/</span>
      <a href="@@CBASE@@">Логика</a><span class="sep">/</span>
      <span class="current">Глава @@N@@</span>
    </nav>
    <a class="back-link" href="@@CBASE@@">К курсу</a>
  </div>
</header>
<section class="hero">
  <div class="container">
    <div class="hero-id">@@ROMAN@@</div>
    <span class="ch-badge">Глава @@N@@</span>
    <h1>@@TITLE_H1@@</h1>
    <p class="hero-lead">@@LEAD@@</p>
    <div class="hero-quote">@@QUOTE@@<span class="hq-src">@@QSRC@@</span></div>
  </div>
</section>
<div class="law-banner"><div class="container"><p><b>Важно:</b> образовательный материал, не юридическая консультация. Право РФ; нормы — по состоянию на момент подготовки, сверяйте действующую редакцию и при необходимости обращайтесь к юристу.</p></div></div>
<section class="sect">
  <div class="container">
    <div class="sect-head">
      <span class="kicker">О чём глава</span>
      <h2>Зачем это <span class="em">нужно</span></h2>
    </div>
    <div class="intro-grid">
@@INTRO@@
    </div>
  </div>
</section>
<section class="sect">
  <div class="container">
    <div class="sect-head">
      <span class="kicker">Модули главы</span>
      <h2>Шесть <span class="em">модулей</span></h2>
      <p>Короткая теория и интерактив в каждом; последний — капстоун с итоговым синтезом.</p>
    </div>
    <div class="tiles-grid">
@@TILES@@
    </div>
    <div class="quiz-cta"><a href="@@CBASE@@/@@SLUG@@/kviz">Пройти квиз главы — 6 вопросов</a></div>
  </div>
</section>
<section class="sect">
  <div class="container">
    <div class="sect-head">
      <span class="kicker">Навигация по курсу</span>
      <h2>Все <span class="em">главы</span></h2>
    </div>
    <div class="chain">
@@CHAIN@@
    </div>
  </div>
</section>
<footer class="footer">
  <div class="container">
    <div class="foot-mark">∴</div>
    <p>Глава @@N@@ · @@TITLE@@</p>
    <p>Курс <a href="@@CBASE@@">«@@CNAME@@»</a></p>
    <p class="foot-links">
      <a href="/">На главную</a>
      <a href="@@CBASE@@">К курсу</a>
      <a href="@@CBASE@@/@@SLUG@@/kviz">Квиз главы</a>
    </p>
  </div>
</footer>
</body>
</html>
'''

def title_h1(title, em):
    # выделить курсивом слово em в заголовке
    if em and em in title:
        return title.replace(em, f'<span class="em">{em}</span>', 1)
    return f'<span class="em">{title}</span>'

def build():
    made = []
    for c in CH:
        html = (TPL
          .replace('@@N@@', str(c['n']))
          .replace('@@ROMAN@@', c['roman'])
          .replace('@@SLUG@@', c['slug'])
          .replace('@@TITLE_H1@@', title_h1(c['title'], c['em']))
          .replace('@@TITLE@@', c['title'])
          .replace('@@ACCENT@@', c['accent']).replace('@@BRIGHT@@', c['bright']).replace('@@DEEP@@', c['deep'])
          .replace('@@RGB@@', c['rgb'])
          .replace('@@LEAD@@', c['lead'])
          .replace('@@QUOTE@@', c['quote']).replace('@@QSRC@@', c['qsrc'])
          .replace('@@INTRO@@', intro_html(c['intro']))
          .replace('@@TILES@@', tiles_html(c['slug'], c['mods']))
          .replace('@@CHAIN@@', chain_html(c['slug']))
          .replace('@@CBASE@@', COURSE_BASE).replace('@@CNAME@@', COURSE_NAME))
        d = os.path.join(OUT_BASE, c['slug']); os.makedirs(d, exist_ok=True)
        out = os.path.join(d, 'index.html')
        open(out, 'w', encoding='utf-8').write(html)
        made.append((c['slug'], os.path.getsize(out)))
    return made

if __name__ == '__main__':
    m = build()
    print(f'Сгенерировано лендингов глав: {len(m)}')
    for s, sz in m:
        print(f'  {COURSE_BASE}/{s}  ({s}/index.html) — {sz} B')
