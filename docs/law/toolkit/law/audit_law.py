#!/usr/bin/env python3
"""
audit_law.py — аудит КОНСИСТЕНТНОСТИ курса «Право повседневной жизни» (право РФ).

preflight.py ловит KaTeX/структуру/смешанные скрипты; verify_numbers.py — арифметику.
ЭТОТ скрипт ловит то, что специфично для курса права и для site-конвенций jonnify:
честность (дисклеймер на каждой странице), кросс-курсовые «протечки» из курса логики,
тема главы (цвет), вложенные <a>, целостность внутренних ссылок, маркеры навигации
модулей, и ДРИФТ между law-status.md и реальным деревом law/.

Severity:
  ERROR — нарушает A+/честность/целостность (выход != 0).
  WARN  — стоит посмотреть (не валит прогон).

Запуск:  python3 audit_law.py [file.html ...]
Без аргументов — весь живой каталог law/ (путь резолвится от расположения скрипта,
поэтому работает из любой CWD, в т.ч. из вотчера).
"""
import re, sys, os, glob

_HERE = os.path.dirname(os.path.abspath(__file__))
_REPO_ROOT = os.path.abspath(os.path.join(_HERE, '..', '..', '..', '..'))
LAW = os.path.join(_REPO_ROOT, 'law')
STATUS_MD = os.path.join(_REPO_ROOT, 'docs', 'law', 'law-status.md')

# Карта тема-главы курса ПРАВА (своя, отличается от health-палитры в playbook §4.2).
# Гл.7 nesovershennoletnie добавлена позже (тема blue); финал /law/final — sage.
CHAPTER_COLOR = {
    'dogovor': 'slate', 'potrebitel': 'gold', 'trud': 'copper',
    'semya': 'burgundy', 'nasledstvo': 'plum', 'pretenziya': 'jade',
    'nesovershennoletnie': 'blue',
}
# Hex-значения акцентов (playbook §4.1). Страница главы задаёт alias --accent:#hex
# и использует var(--accent*) — проверяем, что hex совпадает с темой главы.
ACCENT_HEX = {
    'slate': '#5a8fa4', 'gold': '#d4a85a', 'copper': '#b8804a',
    'burgundy': '#c4504c', 'plum': '#9b6fa0', 'jade': '#3d8a8e',
    'blue': '#5a87c4', 'sage': '#7ba387',
}

def discover_chapters():
    """Глава = каталог под law/ с index.html. Открытие списка ДИНАМИЧЕСКИ —
    курс растёт (6→7 глав + финал), хардкод устарел бы молча."""
    if not os.path.isdir(LAW):
        return []
    return sorted(d for d in os.listdir(LAW)
                  if os.path.isdir(os.path.join(LAW, d))
                  and os.path.exists(os.path.join(LAW, d, 'index.html')))

CHAPTERS = discover_chapters()

# Маркеры обязательного дисклеймера (хотя бы один на странице).
DISCLAIMER_MARKERS = ('не юридическая консультация', 'образовательн', 'class="disclaimer"', 'law-banner')

issues = []   # (severity, relpath, code, detail)
def add(sev, rel, code, detail):
    issues.append((sev, rel, code, detail))

def strip_scripts_styles(h):
    h = re.sub(r'<script[\s\S]*?</script>', '', h, flags=re.I)
    h = re.sub(r'<style[\s\S]*?</style>', '', h, flags=re.I)
    return h

# ---- внутренние ссылки -> файл в дереве law/ ---------------------------------
def url_to_file(url):
    """/law(/x(/y)) -> возможные файлы. None для внешних/якорей."""
    url = url.split('#')[0].split('?')[0]
    if not url.startswith('/law'):
        return None
    rest = url[len('/law'):].strip('/')        # '', 'dogovor', 'dogovor/sila'
    base = LAW if not rest else os.path.join(LAW, *rest.split('/'))
    if not rest:
        return [os.path.join(LAW, 'index.html')]
    return [base + '.html', os.path.join(base, 'index.html')]

def check_links(h, rel):
    # Law не имеет манифеста (в отличие от elixir/cms), поэтому «битую» ссылку
    # нельзя отличить от «forward-link на ещё не построенную страницу». Тайлы глав
    # ВЕДУТ на будущие модули по дизайну (playbook: «страницы строятся позже»).
    # Поэтому мёртвые /law-ссылки = WARN (forward-links), агрегируем по файлу;
    # реальную несостыковку ловит DRIFT-STATUS на курс-уровне.
    dead = []
    for m in re.finditer(r'href="(/law[^"#?]*)"', h):
        cands = url_to_file(m.group(1))
        if cands and not any(os.path.exists(c) for c in cands):
            if m.group(1) not in dead:
                dead.append(m.group(1))
    if dead:
        add('WARN', rel, 'FWD-LINK', f'{len(dead)} ссылок на непостроенные страницы: {dead}')

def check_nested_a(h, rel):
    plain = strip_scripts_styles(h)
    depth = 0
    for tok in re.finditer(r'<a\b|</a\s*>', plain, re.I):
        if tok.group(0).lower().startswith('<a'):
            depth += 1
            if depth > 1:
                add('ERROR', rel, 'NESTED-A', 'вложенный <a> (браузер удвоит DOM)')
                depth = 1   # сообщаем один раз на цепочку
        else:
            depth = max(0, depth - 1)

def scan_file(path):
    rel = os.path.relpath(path, _REPO_ROOT)
    h = open(path, encoding='utf-8').read()
    parts = rel.split(os.sep)                  # ['law', '<chapter>', '<name>.html'] | ['law','index.html']
    fname = parts[-1]
    # «Глава» — только известный слаг-каталог; топ-уровневые страницы (index.html,
    # nesovershennoletnie.html — сквозная памятка) не относятся к главе.
    chapter = parts[1] if (len(parts) == 3 and parts[1] in CHAPTER_COLOR) else None
    is_course_home = (rel == os.path.join('law', 'index.html'))
    is_landing = (chapter is not None and fname == 'index.html')
    is_kviz = (fname == 'kviz.html')
    is_module = (chapter is not None and not is_landing and not is_kviz)

    # 1) ЧЕСТНОСТЬ: дисклеймер обязателен на каждой странице.
    if not any(mk in h for mk in DISCLAIMER_MARKERS):
        add('ERROR', rel, 'NO-DISCLAIMER', 'нет правового дисклеймера на странице')

    # 2) кросс-курсовые протечки (URL/прогресс/хлебные крошки), НЕ прозаические упоминания.
    if re.search(r'href="/(logic|health)/', h):
        add('ERROR', rel, 'XCOURSE-URL', 'ссылка на /logic/ или /health/')
    if re.search(r'\blg-c\d', h):
        add('ERROR', rel, 'XCOURSE-LS', "localStorage-ключ курса логики (lg-c…) — должно быть law-c…")
    if re.search(r'Курс\s*(?:&nbsp;|\s)*·\s*(?:&nbsp;|\s)*Логика', h):
        add('ERROR', rel, 'XCOURSE-CRUMB', 'хлебная крошка «Курс · Логика»')

    # 3) тема главы (цвет) — alias --accent:#hex должен совпадать с темой главы.
    if chapter:
        want = ACCENT_HEX[CHAPTER_COLOR[chapter]]
        m = re.search(r'--accent\s*:\s*(#[0-9a-fA-F]{6})', h)
        if not m:
            add('WARN', rel, 'THEME', f'не задан alias --accent (ожидался {CHAPTER_COLOR[chapter]} {want})')
        elif m.group(1).lower() != want:
            add('WARN', rel, 'THEME', f'--accent {m.group(1)} ≠ тема «{chapter}» ({CHAPTER_COLOR[chapter]} {want})')

    # 4) вложенные <a> + целостность ссылок.
    check_nested_a(h, rel)
    check_links(h, rel)

    # 5) лендинг главы: ровно 6 модулей-тайлов (ссылки /law/<ch>/<mod>, кроме kviz).
    if is_landing:
        mods = set(re.findall(rf'href="/law/{chapter}/([a-z0-9-]+)"', h)) - {'kviz', ''}
        if len(mods) != 6:
            add('WARN', rel, 'TILES', f'{len(mods)} модулей-ссылок (ожидалось 6): {sorted(mods)}')

    # 6) маркеры навигации модуля (дидактический модуль = липкая нав + prev/next + наверх).
    if is_module:
        for marker, code in (('id="top"', 'NAV-TOP'), ('section-nav', 'NAV-SECTIONS'), ('nav-prev-next', 'NAV-PREVNEXT')):
            if marker not in h:
                add('ERROR', rel, code, f'модуль без маркера навигации: {marker}')
        # дидактический модуль обычно несёт квиз + источники
        if 'class="quiz"' not in h:
            add('WARN', rel, 'NO-QUIZ', 'в модуле нет блока .quiz')
        if 'references' not in h.lower():
            add('WARN', rel, 'NO-REFS', 'в модуле нет блока «Источники»')

    # 7) десктоп-шрифт (site-конвенция).
    if 'min-width:1024px' not in h:
        add('WARN', rel, 'DESKTOP-FONT', 'нет медиазапроса min-width:1024px')

# ---- курс-уровневый дрифт (filesystem vs law-status.md) ----------------------
def course_level():
    have_landing = [c for c in CHAPTERS if os.path.exists(os.path.join(LAW, c, 'index.html'))]
    have_kviz = [c for c in CHAPTERS if os.path.exists(os.path.join(LAW, c, 'kviz.html'))]
    missing_kviz = [c for c in have_landing if c not in have_kviz]

    # модули = html под law/<ch>/ кроме index.html и kviz.html
    modules = []
    for c in CHAPTERS:
        d = os.path.join(LAW, c)
        if os.path.isdir(d):
            modules += [f for f in os.listdir(d) if f.endswith('.html') and f not in ('index.html', 'kviz.html')]

    print('\n── курс-уровень ──')
    print(f'  лендингов глав: {len(have_landing)}/6   квизов глав: {len(have_kviz)}/6   модулей: {len(modules)}/36')
    if missing_kviz:
        add('WARN', 'law/', 'DRIFT-KVIZ', f'нет kviz.html в главах: {missing_kviz}')

    # сверка с заявленным в law-status.md (если файл на месте)
    if os.path.exists(STATUS_MD):
        st = open(STATUS_MD, encoding='utf-8').read()
        claims_6_quiz = re.search(r'Квиз[^\n|]*\|\s*\$?6\s*/\s*6', st) or 'Квиз главы` готовы' in st or '6 / 6$ ✓ — сгенерированы' in st
        if claims_6_quiz and len(have_kviz) < 6:
            add('ERROR', 'docs/law/law-status.md', 'DRIFT-STATUS',
                f'статус заявляет 6/6 «Квиз главы», в дереве law/ их {len(have_kviz)} '
                f'(нет: {missing_kviz}) — статус расходится с файловой системой')

def main():
    args = sys.argv[1:]
    per_file = bool(args)   # явный список файлов -> ПОСТРАНИЧНЫЙ режим
    files = sorted(args) if args else sorted(glob.glob(os.path.join(LAW, '*.html')) +
                                              glob.glob(os.path.join(LAW, '*', '*.html')))
    if not files:
        print('Нет файлов law/*.html — проверь путь:', LAW); return 1
    print(f'Аудит консистентности: {len(files)} файлов из {LAW}')
    for f in files:
        scan_file(f)
    # Курс-уровневый дрифт (status↔fs) — это находка КУРСА, а не конкретной страницы.
    # В постраничном режиме (вотчер проверяет затронутую страницу) НЕ примешиваем его,
    # иначе любая правка «провалит» здоровую страницу из-за глобального дрифта.
    if not per_file:
        course_level()

    errs = [i for i in issues if i[0] == 'ERROR']
    warns = [i for i in issues if i[0] == 'WARN']
    print('\n── находки ──')
    for sev, rel, code, detail in sorted(issues, key=lambda x: (x[0] != 'ERROR', x[1])):
        mark = '❌' if sev == 'ERROR' else '⚠️ '
        print(f'  {mark} [{code}] {rel}: {detail}')
    if not issues:
        print('  ✓ чисто')
    print(f'\nИтого: {len(errs)} ERROR, {len(warns)} WARN')
    return 1 if errs else 0

if __name__ == '__main__':
    sys.exit(main())
