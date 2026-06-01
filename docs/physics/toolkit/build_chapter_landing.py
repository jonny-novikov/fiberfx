#!/usr/bin/env python3
"""Генератор лендинга главы для курса /physics (дизайн-система style.py).
Лендинг: герой главы (свой акцент), сетка модулей, карточка квиза главы, навигация.
В CFG — образец Главы 1; для остальных глав заполнить по аналогии (см. build-playbook.md)."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style

BASE = os.path.dirname(os.path.abspath(__file__))

# образец: Глава 1
CFG = dict(
    slug='tok', num='1', pal='tok',
    title='Глава 1 · Ток, напряжение, сопротивление · Электричество дома',
    desc='Глава 1 курса: ток, напряжение и сопротивление — что течёт в проводах, закон Ома U=IR, последовательные и параллельные цепи. Пять модулей с калькуляторами и квизом.',
    kicker='Глава 1 · Основы',
    h1='Ток, напряжение, <span class="em">сопротивление</span>',
    formula='U = I · R',
    lead='С чего всё начинается: что именно течёт в проводах, что «толкает» ток и что ему мешает. Главная формула главы — закон Ома, связывающий напряжение, ток и сопротивление.',
    intro='Эта глава даёт интуицию и аппарат: ток как поток, напряжение как «давление», сопротивление как «узость трубы». Освоив закон Ома, вы поймёте всё остальное в курсе.',
    points=[
        '<b>Ток</b> — поток заряда; измеряется в амперах (А).',
        '<b>Напряжение</b> — то, что «толкает» ток; вольты (В).',
        '<b>Сопротивление</b> — то, что мешает току; омы (Ом).',
        '<b>Закон Ома</b> связывает их: $U = IR$ — фундамент всего курса.',
    ],
    modules=[
        ('1.1', 'tok-chto', 'Что течёт в проводах', 'Ток, заряд и направление: что именно движется в розетке.'),
        ('1.2', 'napryazhenie', 'Напряжение', 'Что «толкает» ток. Вольты и аналогия давления воды.'),
        ('1.3', 'soprotivlenie', 'Сопротивление', 'Что мешает току и от чего оно зависит. Омы.'),
        ('1.4', 'zakon-oma', 'Закон Ома', 'U = IR на практике: интерактивный калькулятор и график.'),
        ('1.5', 'cepi', 'Цепи: последовательно и параллельно', 'Как складываются сопротивления и токи в цепях.'),
    ],
    prev=('/physics', 'Курс', 'К <span class="em">обзору</span> курса'),
    nxt=('/physics/moshchnost', 'Глава 2', 'Мощность и <span class="em">энергия</span>'),
)

def build(c):
    a, b, d, rgb = style.PALETTE[c['pal']]
    pts = '\n      '.join(f'<li>{p}</li>' for p in c['points'])
    tiles = []
    for i,(mn, ms, mt, mtopic) in enumerate(c['modules']):
        delay = f'{0.04*i:.2f}s'
        tiles.append(f'<a class="ch-tile" href="/physics/{c["slug"]}/{ms}" '
                     f'style="--t:{a};--tb:{b};--trgb:{rgb};animation-delay:{delay}">'
                     f'<div class="ct-top"><span class="ct-n">{mn}</span>'
                     f'<span class="ct-tag">Модуль {mn}</span></div>'
                     f'<h3>{mt}</h3><p class="ct-topic">{mtopic}</p>'
                     f'<div class="ct-foot"><span class="ct-go">Открыть</span></div></a>')
    tiles = '\n      '.join(tiles)
    ph, pl, pt = c['prev']; nh, nl, nt = c['nxt']
    html = style.head(c['title'], c['desc'], slug=c['pal'])
    body = f"""<body id="top">
<div class="progress-bar"></div>

<header class="topbar">
  <div class="topbar-inner">
    <a class="brand" href="/physics">
      <div class="brand-mark">&#9889;</div>
      <div class="brand-text"><span class="brand-name">Электричество и устройства</span><span class="brand-sub">Школьная физика дома</span></div>
    </a>
    <nav class="breadcrumb"><a href="/physics">Физика</a><span class="sep">/</span><span class="current">Глава {c['num']}</span></nav>
    <a class="back-link" href="/physics">К курсу</a>
  </div>
</header>

<nav class="section-nav" aria-label="Навигация по разделам">
  <div class="section-nav-inner">
    <a href="#intro"><span class="sn-n">01</span>Обзор</a>
    <a href="#modules"><span class="sn-n">02</span>Модули</a>
    <a href="#quiz-cta"><span class="sn-n">03</span>Квиз главы</a>
  </div>
</nav>

<section class="hero">
  <div class="container">
    <div class="hero-mark">&#9889;</div>
    <span class="kicker">{c['kicker']}</span>
    <h1>{c['h1']}</h1>
    <div class="formula-row"><span class="formula-chip"><span class="fc-l">формула главы</span> $U = IR$</span></div>
    <p class="hero-lead">{c['lead']}</p>
  </div>
</section>

<div class="safety-banner"><div><p><b>Важно:</b> образовательный материал по школьной физике. Электричество опасно — соблюдайте правила безопасности и не работайте под напряжением.</p></div></div>

<section class="sect" id="intro">
  <div class="sect-head"><span class="kicker">О главе</span><h2>Что внутри <span class="em">главы</span></h2><p class="lead">{c['intro']}</p></div>
  <div class="sect-block"><ul>
      {pts}
  </ul></div>
</section>

<section class="sect" id="modules">
  <div class="sect-head"><span class="kicker">Модули</span><h2>Пять <span class="em">модулей</span></h2><p class="lead">Каждый модуль — наглядное объяснение, интерактив и квиз в конце.</p></div>
  <div class="ch-grid">
      {tiles}
  </div>
</section>

<section class="sect" id="quiz-cta" style="border-bottom:none">
  <div class="sect-head"><span class="kicker">Проверка</span><h2>Квиз <span class="em">главы</span></h2><p class="lead">Когда пройдёте модули — проверьте себя сквозным квизом по всей главе.</p></div>
  <div class="project-cta"><div>
    <h3>Квиз <span class="em">главы 1</span></h3>
    <p>Несколько вопросов по току, напряжению, сопротивлению и закону Ома. С разбором каждого ответа; прогресс сохраняется в браузере.</p>
    <a href="/physics/{c['slug']}/kviz">Пройти квиз главы</a>
  </div></div>
</section>

<nav class="nav-prev-next">
  <a class="nav-card prev" href="{ph}"><span class="nv-label">{pl}</span><span class="nv-title">{pt}</span></a>
  <a class="nav-card next" href="{nh}"><span class="nv-label">{nl}</span><span class="nv-title">{nt}</span></a>
</nav>
<div class="to-top"><a href="#top">↑ Наверх</a></div>

<footer class="footer"><div class="container">
  <div class="foot-mark">&#9889;</div>
  <p>Глава {c['num']} · {c['h1'].replace('<span class="em">','').replace('</span>','')}</p>
  <p>Курс <a href="/physics">«Электричество и устройства»</a></p>
  <p class="foot-links"><a href="/physics">К курсу</a><a href="/physics/{c['slug']}/kviz">Квиз главы</a></p>
</div></footer>

<script>
{style.NAV_JS}
</script>
</body>
</html>
"""
    out_dir = os.path.join(BASE, 'site', 'physics', c['slug'])
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, 'index.html')
    open(out, 'w', encoding='utf-8').write(html + body)
    print('written:', out, '|', len(html + body), 'bytes')

if __name__ == '__main__':
    build(CFG)
