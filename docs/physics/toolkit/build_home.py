#!/usr/bin/env python3
"""Главная страница курса «Электричество и устройства: школьная физика дома» (/physics).
Собирается на дизайн-системе style.py. Хаб: герой с формулами, сетка из 5 глав,
блок подхода и карточка финального проекта."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style

BASE = os.path.dirname(os.path.abspath(__file__))

# главы: (slug, номер, заголовок, тема, формула-чип, палитра-слаг)
CH = [
    ('tok', '1', 'Ток, напряжение, сопротивление', 'Что течёт в проводах и почему. Интуиция «воды в трубе» и закон Ома.', 'U = I · R', 'tok'),
    ('moshchnost', '2', 'Мощность и энергия', 'Почему чайник «ест» больше лампочки. Ватты, киловатт-часы, единицы.', 'P = U · I', 'moshchnost'),
    ('schet', '3', 'Счёт за электричество', 'кВт·ч, умноженные на тариф: что реально тратит деньги. Калькулятор.', 'кВт·ч × тариф', 'schet'),
    ('bezopasnost', '4', 'Безопасность', 'Почему бьёт током; заземление, УЗО, перегрузка и риск пожара.', 'I = U / R', 'bezopasnost'),
    ('ustroystva', '5', 'Устройства и батареи', 'Зарядка, ёмкость в мА·ч, КПД и почему техника греется.', 'Вт·ч = А·ч × В', 'ustroystva'),
]

def tile(i, slug, num, title, topic, form, pal):
    a, b, d, rgb = style.PALETTE[pal]
    delay = f'{0.04*i:.2f}s'
    return (f'<a class="ch-tile" href="/physics/{slug}" '
            f'style="--t:{a};--tb:{b};--trgb:{rgb};animation-delay:{delay}">'
            f'<div class="ct-top"><span class="ct-n">{num}</span>'
            f'<span class="ct-tag">Глава {num}</span></div>'
            f'<h3>{title}</h3>'
            f'<p class="ct-topic">{topic}</p>'
            f'<div class="ct-foot"><span class="ct-form">{form}</span>'
            f'<span class="ct-go">Открыть</span></div></a>')

tiles = '\n      '.join(tile(i, *c) for i, c in enumerate(CH))

PILLARS = [
    ('&#128161;', 'Наглядно', 'Каждая идея — через простую аналогию, диаграмму и пример из розетки, а не через сухую формулу.'),
    ('&#129518;', 'Калькуляторы', 'Интерактив на каждой теме: посчитать ток, мощность, счёт за свет, нагрузку удлинителя и время работы батареи.'),
    ('&#9889;', 'Безопасность', 'Отдельная глава о том, как электричество бьёт и горит — и как не навредить себе и дому.'),
    ('&#128424;', 'Оффлайн', 'Печатные памятки: таблица мощностей, чек-лист безопасности и шпаргалка по формулам.'),
]
pillars = '\n      '.join(
    f'<div class="pillar"><div class="pi-ic">{ic}</div><h4>{h}</h4><p>{p}</p></div>'
    for ic, h, p in PILLARS)

html = style.head(
    'Электричество и устройства: школьная физика дома · Курс',
    'Курс «Электричество и устройства: школьная физика дома»: закон Ома, мощность и энергия, счёт за свет, безопасность и батареи — школьная физика как аппарат для жизни. Пять глав, калькуляторы, квизы и финальный проект.',
    slug='global')

body = f"""<body id="top">
<div class="progress-bar"></div>

<header class="topbar">
  <div class="topbar-inner">
    <a class="brand" href="/physics">
      <div class="brand-mark">&#9889;</div>
      <div class="brand-text">
        <span class="brand-name">Электричество и устройства</span>
        <span class="brand-sub">Школьная физика дома</span>
      </div>
    </a>
    <nav class="breadcrumb">
      <a href="/">Курсы</a><span class="sep">/</span>
      <span class="current">Физика</span>
    </nav>
    <a class="back-link" href="/">Все курсы</a>
  </div>
</header>

<nav class="section-nav" aria-label="Навигация по разделам">
  <div class="section-nav-inner">
    <a href="#about"><span class="sn-n">01</span>Обзор</a>
    <a href="#chapters"><span class="sn-n">02</span>Главы</a>
    <a href="#approach"><span class="sn-n">03</span>Подход</a>
    <a href="#project"><span class="sn-n">04</span>Проект</a>
  </div>
</nav>

<section class="hero">
  <div class="container">
    <div class="hero-mark">&#9889;</div>
    <span class="kicker">Курс · Физика для жизни</span>
    <h1>Электричество и устройства: <span class="em">школьная физика дома</span></h1>
    <div class="formula-row">
      <span class="formula-chip"><span class="fc-l">закон Ома</span> $U = IR$</span>
      <span class="formula-chip"><span class="fc-l">мощность</span> $P = UI$</span>
      <span class="formula-chip"><span class="fc-l">энергия</span> $E = Pt$</span>
    </div>
    <p class="hero-lead">Розетка не прощает незнания: ток, напряжение и мощность связаны одной школьной формулой — и от неё зависят и счёт за свет, и ваша безопасность. Этот курс превращает <b>закон Ома</b> и <b>мощность</b> в practical-аппарат для дома.</p>
    <div class="hero-quote">Физика в розетке — это не абстракция из учебника, а то, что определяет ваш счёт и вашу безопасность каждый день.<span class="hq-source">Идея курса</span></div>
  </div>
</section>

<div class="safety-banner">
  <div><p><b>Важно:</b> материал образовательный и опирается на школьную физику. Электричество опасно: не выполняйте работы под напряжением, доверяйте монтаж и ремонт квалифицированным специалистам и соблюдайте правила (ПУЭ) и инструкции к приборам.</p></div>
</div>

<section class="sect" id="about">
  <div class="sect-head">
    <span class="kicker">Зачем этот курс</span>
    <h2>Двух формул <span class="em">достаточно</span></h2>
    <p class="lead">$U = IR$ и $P = UI$ — это почти всё, что нужно, чтобы понять и счёт за свет, и почему нельзя включать обогреватель с чайником в один удлинитель. Курс показывает, как школьная физика работает в быту.</p>
  </div>
  <div class="sect-block">
    <p>После курса вы сможете:</p>
    <ul>
      <li><b>Читать розетку и прибор:</b> что означают вольты, амперы и ватты на наклейке.</li>
      <li><b>Считать счёт за свет:</b> переводить мощность и время в киловатт-часы и рубли — и видеть, что реально дорого.</li>
      <li><b>Не перегружать сеть:</b> понимать пределы удлинителя и проводки, избегать перегрева и пожара.</li>
      <li><b>Обращаться с техникой и батареями:</b> понимать ёмкость, зарядку, КПД и почему устройства греются.</li>
    </ul>
  </div>
</section>

<section class="sect" id="chapters">
  <div class="sect-head">
    <span class="kicker">Программа</span>
    <h2>Пять <span class="em">глав</span></h2>
    <p class="lead">От тока в проводах — к счёту за свет, безопасности и батареям. Каждая глава — наглядные объяснения, калькуляторы и квиз в конце.</p>
  </div>
  <div class="ch-grid">
      {tiles}
      <a class="ch-tile final" href="/physics/final" style="--t:#3d9aa0;--tb:#5fbcc2;--trgb:61,154,160;animation-delay:.24s">
        <div class="ct-top"><span class="ct-n">&#9733;</span><span class="ct-tag">Финальный проект 6</span></div>
        <h3>Физика для жизни</h3>
        <p class="ct-topic">Энергоаудит квартиры: собрать мощности, посчитать счёт, проверить безопасность и оптимизировать. Финальный квиз и печатные материалы.</p>
        <div class="ct-foot"><span class="ct-form">итог курса</span><span class="ct-go">К проекту</span></div>
      </a>
  </div>
</section>

<section class="sect" id="approach">
  <div class="sect-head">
    <span class="kicker">Подход</span>
    <h2>Как устроен <span class="em">курс</span></h2>
    <p class="lead">Наглядно, интерактивно и с прицелом на реальную пользу — деньги и безопасность.</p>
  </div>
  <div class="pillars">
      {pillars}
  </div>
</section>

<section class="sect" id="project" style="border-bottom:none">
  <div class="sect-head">
    <span class="kicker">Финальный проект 6</span>
    <h2>«Физика <span class="em">для жизни</span>»</h2>
    <p class="lead">Курс завершается практическим проектом, который связывает все главы воедино.</p>
  </div>
  <div class="project-cta">
    <div>
      <h3>Энергоаудит <span class="em">вашей квартиры</span></h3>
      <p>Возьмите реальные приборы, соберите их мощности, посчитайте месячный расход в кВт·ч и рублях, проверьте нагрузку на сеть и безопасность — и найдите, где можно сэкономить без мифов.</p>
      <div class="pc-list">
        <span>Финальный квиз по всем главам</span>
        <span>Квиз после каждого модуля</span>
        <span>Таблица мощностей приборов</span>
        <span>Чек-лист безопасности</span>
        <span>Шпаргалка по формулам</span>
        <span>Материалы для печати</span>
      </div>
      <a href="/physics/final">Перейти к финальному проекту</a>
    </div>
  </div>
</section>

<div class="to-top"><a href="#top">↑ Наверх</a></div>

<footer class="footer">
  <div class="container">
    <div class="foot-mark">&#9889;</div>
    <p>Курс «Электричество и устройства: школьная физика дома»</p>
    <p>Часть программы <a href="/">jonnify</a> · школьная физика и математика как инструмент</p>
    <p class="foot-links">
      <a href="/">Все курсы</a>
      <a href="#chapters">Главы</a>
      <a href="/physics/final">Финальный проект</a>
    </p>
  </div>
</footer>

<script>
{style.NAV_JS}
</script>
</body>
</html>
"""

out_dir = os.path.join(BASE, 'site', 'physics')
os.makedirs(out_dir, exist_ok=True)
out = os.path.join(out_dir, 'index.html')
open(out, 'w', encoding='utf-8').write(html + body)
print('written:', out, '|', len(html + body), 'bytes')
