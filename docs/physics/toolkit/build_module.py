#!/usr/bin/env python3
"""Генератор модуля курса /physics (дизайн-система style.py).
Модуль = материалы (разделы) + интерактив (калькулятор/чек-лист) + квиз модуля + навигация.
Каждый модуль ОБЯЗАН заканчиваться квизом (директива курса). В CFG — образец 1.4 «Закон Ома»
с интерактивным калькулятором закона Ома; остальные модули заполняются по аналогии."""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import style

BASE = os.path.dirname(os.path.abspath(__file__))

def sect(i, inner):
    return f'<section class="sect" id="s{i}">\n  <div class="container">\n{inner}\n  </div>\n</section>'
def secnav(items):
    return ''.join(f'\n    <a href="#s{i+1}"><span class="sn-n">{i+1}</span> {l}</a>' for i,l in enumerate(items))
def takeaway(items):
    return ''.join(f'\n        <div class="takeaway-item"><span class="ti-num">{i+1}</span><span class="ti-text">{t}</span></div>' for i,t in enumerate(items))
def refs(items):
    return ''.join(f'\n    <li>{r}</li>' for r in items)

# Интерактив-калькулятор закона Ома (HTML + JS) — образец интерактива
OHM_HTML = """    <div class="task-block">
      <div class="task-head"><span class="task-tag">Интерактив · калькулятор</span><h4>Калькулятор закона Ома</h4></div>
      <p class="task-intro">Введите любые две величины — калькулятор найдёт третью и заодно мощность.</p>
      <div class="calc-grid">
        <div class="calc-field"><label>Напряжение U, В</label><input id="om-u" type="number" inputmode="decimal" placeholder="например, 12"></div>
        <div class="calc-field"><label>Ток I, А</label><input id="om-i" type="number" inputmode="decimal" placeholder="например, 3"></div>
        <div class="calc-field"><label>Сопротивление R, Ом</label><input id="om-r" type="number" inputmode="decimal" placeholder="например, 4"></div>
      </div>
      <button class="calc-btn" id="om-btn">Рассчитать</button>
      <div class="calc-result" id="om-res"></div>
      <div class="disclaimer">Учебный калькулятор: значения нигде не сохраняются и не передаются.</div>
    </div>"""

OHM_JS = """function omFmt(x){ return (Math.round(x*1000)/1000).toString().replace('.',','); }
function omCalc(){
  var res=document.getElementById('om-res');
  var U=parseFloat(document.getElementById('om-u').value),
      I=parseFloat(document.getElementById('om-i').value),
      R=parseFloat(document.getElementById('om-r').value);
  var nU=!isNaN(U), nI=!isNaN(I), nR=!isNaN(R), cnt=(nU?1:0)+(nI?1:0)+(nR?1:0);
  function show(html){ res.innerHTML=html; res.classList.add('show'); }
  if(cnt<2){ show('<p class="cr-t">Введите хотя бы <b>две</b> величины — третью посчитаю.</p>'); return; }
  var big='', formula='';
  if(!nU){ U=I*R; big='U = '+omFmt(U)+' В'; formula='U = I &middot; R'; }
  else if(!nI){ if(R===0){ show('<p class="cr-t">Сопротивление не может быть нулём при делении.</p>'); return; } I=U/R; big='I = '+omFmt(I)+' А'; formula='I = U / R'; }
  else if(!nR){ if(I===0){ show('<p class="cr-t">Ток не может быть нулём при делении.</p>'); return; } R=U/I; big='R = '+omFmt(R)+' Ом'; formula='R = U / I'; }
  else { big='Все три заданы'; formula='проверка U = I &middot; R'; }
  var P=U*I;
  show('<div class="cr-big">'+big+'</div><p class="cr-t">Формула: <b>'+formula+'</b>. Мощность: <b>P = U &middot; I = '+omFmt(P)+' Вт</b>.</p>');
}
document.getElementById('om-btn').addEventListener('click', omCalc);"""

QUIZ_JS = """const QUIZ_KEY='@@QUIZ_KEY@@';
const QUIZ=@@QUIZ_JSON@@;
let qs={};
function qSave(){ try{localStorage.setItem(QUIZ_KEY,JSON.stringify(qs));}catch(e){} }
function qLoad(){ try{var r=localStorage.getItem(QUIZ_KEY); if(r) qs=JSON.parse(r);}catch(e){qs={};} }
function qBuild(){
  var root=document.getElementById('quiz-root'),h='';
  QUIZ.forEach(function(it,qi){
    h+='<div class="quiz-q" data-q="'+qi+'"><div class="q-text"><span class="q-num">'+(qi+1)+'</span><span>'+it.q+'</span></div><div class="q-options">';
    it.options.forEach(function(o,oi){ h+='<button class="q-opt" data-q="'+qi+'" data-o="'+oi+'">'+o+'</button>'; });
    h+='</div><div class="q-explain" id="qe-'+qi+'">'+it.explain+'</div></div>';
  });
  root.innerHTML=h;
  root.querySelectorAll('.q-opt').forEach(function(b){ b.addEventListener('click',qOpt); });
  Object.keys(qs).forEach(function(qi){ qApply(Number(qi)); });
}
function qApply(qi){
  var it=QUIZ[qi],st=qs[qi]; if(!st) return;
  var el=document.querySelector('.quiz-q[data-q="'+qi+'"]'); if(!el) return;
  el.querySelectorAll('.q-opt').forEach(function(b,oi){ b.classList.add('disabled'); if(oi===it.correct) b.classList.add('correct'); else if(oi===st.choice) b.classList.add('incorrect'); });
  document.getElementById('qe-'+qi).classList.add('show');
}
function qOpt(e){ var qi=Number(e.currentTarget.dataset.q),oi=Number(e.currentTarget.dataset.o); if(qs[qi]) return; qs[qi]={correct:oi===QUIZ[qi].correct,choice:oi}; qApply(qi); qSave(); qScore(); }
function qScore(){
  var N=QUIZ.length,ans=Object.keys(qs).length,ok=Object.values(qs).filter(function(s){return s.correct;}).length;
  var el=document.getElementById('quiz-score');
  if(ans===0){ el.textContent='0 / '+N; return; }
  var t=ok+' / '+N+' верно';
  if(ans===N) t+= ok===N?' — отлично!':(ok>=Math.ceil(N*0.6)?' — хорошо!':' — стоит перечитать');
  el.textContent=t;
}
qLoad(); qBuild(); qScore();
document.getElementById('quiz-reset').addEventListener('click',function(){ qs={}; try{localStorage.removeItem(QUIZ_KEY);}catch(e){} qBuild(); qScore(); });"""

# ---------- образец: модуль 1.4 «Закон Ома» ----------
CFG = dict(
    slug='zakon-oma', chapter='tok', pal='tok', num='1.4', name='Закон Ома',
    title='Модуль 1.4 · Закон Ома · Электричество дома',
    desc='Модуль 1.4: закон Ома U=IR — связь напряжения, тока и сопротивления, три формы формулы, интерактивный калькулятор и примеры из жизни. С квизом.',
    kicker='Глава 1 · Модуль 1.4',
    h1='Закон <span class="em">Ома</span>',
    formula='U = IR',
    lead='Одна формула связывает напряжение, ток и сопротивление — и из неё следует почти всё в этой главе. Разберём её в трёх формах и сразу посчитаем на калькуляторе.',
    secnav=['Что это','Три формы','Калькулятор','В жизни'],
    sections=[
        """    <div class="sect-head"><span class="kicker">Раздел 1 · Что это</span><h2>Что говорит <span class="em">закон Ома</span></h2><p class="lead">Чем больше «давление» (напряжение) и чем меньше «узость трубы» (сопротивление), тем сильнее поток (ток).</p></div>
    <div class="sect-block"><ul>
      <li><b>Напряжение $U$</b> (вольты) «толкает» ток.</li>
      <li><b>Сопротивление $R$</b> (омы) мешает току.</li>
      <li><b>Ток $I$</b> (амперы) — то, что в итоге течёт.</li>
    </ul>
    <div class="callout">Аналогия воды: напряжение — давление, сопротивление — узость трубы, ток — поток воды. Шире труба (меньше $R$) — больше поток (больше $I$).</div></div>""",
        """    <div class="sect-head"><span class="kicker">Раздел 2 · Три формы</span><h2>Три формы <span class="em">одной формулы</span></h2><p class="lead">Зная любые две величины, всегда найдёте третью.</p></div>
    <div class="formula-box"><div>
      <div class="fb-cap">Закон Ома</div>
      $$U = IR \\qquad I = \\frac{U}{R} \\qquad R = \\frac{U}{I}$$
    </div></div>
    <div class="sect-block"><ul>
      <li><b>$U = IR$</b> — найти напряжение по току и сопротивлению.</li>
      <li><b>$I = U/R$</b> — найти ток по напряжению и сопротивлению.</li>
      <li><b>$R = U/I$</b> — найти сопротивление по напряжению и току.</li>
    </ul></div>""",
        """    <div class="sect-head"><span class="kicker">Раздел 3 · Калькулятор</span><h2>Посчитайте <span class="em">сами</span></h2><p class="lead">Введите любые две величины — третья и мощность посчитаются автоматически.</p></div>
""" + OHM_HTML,
        """    <div class="sect-head"><span class="kicker">Раздел 4 · В жизни</span><h2>Где это <span class="em">в розетке</span></h2><p class="lead">Закон Ома объясняет повседневные вещи.</p></div>
    <div class="sect-block"><ul>
      <li><b>Нагреватель vs лампа:</b> меньше сопротивление — больше ток и больше тепла при том же напряжении.</li>
      <li><b>Толстый провод</b> имеет меньшее сопротивление, поэтому меньше греется при том же токе.</li>
      <li><b>Влажные руки</b> снижают сопротивление тела — ток через тело растёт (об этом подробно в главе о безопасности).</li>
    </ul>
    <div class="callout warn">Не проверяйте сопротивление тела на розетке: при $230$ В даже небольшое снижение сопротивления даёт опасный ток.</div></div>""",
    ],
    takeaway=[
        'Закон Ома: $U = IR$ — связь напряжения, тока и сопротивления.',
        'Три формы: $U=IR$, $I=U/R$, $R=U/I$ — зная любые две величины, найдёте третью.',
        'Больше сопротивление при том же напряжении — меньше ток.',
        'Калькулятор: введите две величины — получите третью и мощность $P=UI$.',
    ],
    quiz=[
        {"q":"Закон Ома связывает:","options":["напряжение, ток и сопротивление","массу и скорость","температуру и время","объём и давление газа"],"correct":0,
         "explain":"<b>U, I и R.</b> $U=IR$ — фундамент расчётов в цепях."},
        {"q":"Если $U=12$ В и $R=4$ Ом, то ток $I$ равен:","options":["3 А","48 А","0,33 А","16 А"],"correct":0,
         "explain":"<b>3 А.</b> $I=U/R=12/4=3$."},
        {"q":"Чтобы найти сопротивление, нужно:","options":["R = U / I","R = U · I","R = I / U","R = U + I"],"correct":0,
         "explain":"<b>$R=U/I$.</b> Третья форма закона Ома."},
        {"q":"Верно ли: «При том же напряжении большее сопротивление даёт меньший ток»?","options":["Верно","Неверно"],"correct":0,
         "explain":"<b>Верно.</b> $I=U/R$: при росте $R$ ток падает."},
        {"q":"Толстый провод по сравнению с тонким (тот же материал и длина):","options":["имеет меньшее сопротивление","имеет большее сопротивление","имеет такое же сопротивление","не проводит ток"],"correct":0,
         "explain":"<b>Меньшее сопротивление.</b> Поэтому толстый провод меньше греется при том же токе."},
    ],
    interactive_js=OHM_JS,
    quiz_key='phys-tok-zakon-oma-quiz',
    prev=('/physics/tok/soprotivlenie', 'Модуль 1.3', '<span class="em">Сопротивление</span>'),
    nxt=('/physics/tok/cepi', 'Модуль 1.5', '<span class="em">Цепи</span>: посл. и парал.'),
)

def build(c):
    sections = '\n\n'.join(sect(i+1, inner) for i, inner in enumerate(c['sections']))
    js = (c.get('interactive_js','') + "\n" +
          QUIZ_JS.replace('@@QUIZ_KEY@@', c['quiz_key']).replace('@@QUIZ_JSON@@', json.dumps(c['quiz'], ensure_ascii=False, indent=2))
          + "\n" + style.NAV_JS)
    html = style.head(c['title'], c['desc'], slug=c['pal'])
    ph, pl, pt = c['prev']; nh, nl, nt = c['nxt']
    body = f"""<body id="top">
<div class="progress-bar"></div>

<header class="topbar">
  <div class="topbar-inner">
    <a class="brand" href="/physics/{c['chapter']}">
      <div class="brand-mark">&#9889;</div>
      <div class="brand-text"><span class="brand-name">Электричество и устройства</span><span class="brand-sub">Модуль · Глава 1</span></div>
    </a>
    <nav class="breadcrumb"><a href="/physics">Физика</a><span class="sep">/</span><a href="/physics/{c['chapter']}">Гл. 1</a><span class="sep">/</span><span class="current">{c['num']}</span></nav>
    <a class="back-link" href="/physics/{c['chapter']}">К главе</a>
  </div>
</header>

<nav class="section-nav" aria-label="Навигация по разделам">
  <div class="section-nav-inner">{secnav(c['secnav'])}
  </div>
</nav>

<section class="hero">
  <div class="container">
    <div class="hero-mark">&#9889;</div>
    <span class="kicker">{c['kicker']}</span>
    <h1>{c['h1']}</h1>
    <div class="formula-row"><span class="formula-chip"><span class="fc-l">формула</span> $U = IR$</span></div>
    <p class="hero-lead">{c['lead']}</p>
  </div>
</section>

<div class="safety-banner"><div><p><b>Важно:</b> образовательный материал по школьной физике. Электричество опасно — не проверяйте формулы на бытовой сети под напряжением.</p></div></div>

{sections}

<section class="takeaway-section">
  <div class="takeaway">
    <h2>Главное <span class="em">коротко</span></h2>
    <div class="takeaway-grid">{takeaway(c['takeaway'])}
    </div>
  </div>
</section>

<section class="quiz" id="quiz">
  <div class="quiz-head"><span class="quiz-tag">Квиз модуля</span><span class="quiz-score" id="quiz-score">0 / {len(c['quiz'])}</span></div>
  <p class="quiz-intro">Несколько вопросов по модулю. Выберите ответ — сразу увидите верный вариант и пояснение. Прогресс сохраняется.</p>
  <div id="quiz-root"></div>
  <div class="quiz-foot"><button class="quiz-reset" id="quiz-reset">Сбросить квиз</button></div>
</section>

<nav class="nav-prev-next">
  <a class="nav-card prev" href="{ph}"><span class="nv-label">{pl}</span><span class="nv-title">{pt}</span></a>
  <a class="nav-card next" href="{nh}"><span class="nv-label">{nl}</span><span class="nv-title">{nt}</span></a>
</nav>
<div class="to-top"><a href="#top">↑ Наверх</a></div>

<footer class="footer"><div class="container">
  <div class="foot-mark">&#9889;</div>
  <p>Модуль {c['num']} · {c['name']}</p>
  <p>Курс <a href="/physics">«Электричество и устройства»</a></p>
  <p class="foot-links"><a href="/physics/{c['chapter']}">← К главе 1</a><a href="/physics/{c['chapter']}/kviz">Квиз главы</a></p>
</div></footer>

<script>
{js}
</script>
</body>
</html>
"""
    out_dir = os.path.join(BASE, 'site', 'physics', c['chapter'])
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, c['slug'] + '.html')
    open(out, 'w', encoding='utf-8').write(html + body)
    print('written:', out, '|', len(html + body), 'bytes')

if __name__ == '__main__':
    build(CFG)
