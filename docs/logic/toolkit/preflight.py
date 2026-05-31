#!/usr/bin/env python3
"""
preflight.py — pre-flight скан страниц курса «Логика и принятие решений».
Проверяет ПЕРЕД сдачей:
  1) KaTeX strict-чистоту: запрещённые символы и «голый» % внутри $...$ (HTML и JS-литералы, с учётом \\% и ${...});
  2) смешанные кириллица+латиница слова (ловит опечатки вида «обмen»);
  3) структурную целостность: один </html>, баланс <script>/</script>, баланс $.
Запуск:  python3 preflight.py [glob ...]   (по умолчанию logic/*.html logic/*/*.html)
JS-парс выполняется отдельно через node в toolkit-валидации.
"""
import re, sys, glob, os

BAD = set('№«»“”„…₽')                    # не-ASCII символы, ломающие KaTeX strict
DEFAULT_GLOBS = ['logic/*.html', 'logic/*/*.html']

def find_math_spans(text):
    """$$...$$ и $...$ после удаления JS-интерполяций ${...}."""
    probe = re.sub(r'\$\{[^}]*\}', '0', text)
    return [m.group(0) for m in re.finditer(r'\$\$[^$]+?\$\$|\$[^$\n]+?\$', probe)]

def scan_file(path):
    h = open(path, encoding='utf-8').read()
    issues = []
    nostyle = re.sub(r'<style>[\s\S]+?</style>', '', h)

    # 1) KaTeX в HTML (вне <script>)
    html_only = re.sub(r'<script>[\s\S]+?</script>', '', nostyle)
    for seg in find_math_spans(html_only):
        if any(c in BAD for c in seg):
            issues.append(('HTML-BAD', seg[:48]))
        if re.search(r'(?<!\\)%', seg):
            issues.append(('HTML-bare%', seg[:48]))

    # 1b) KaTeX в JS-литералах (симулируем \\%→% как делает рантайм)
    for sc in re.findall(r'<script>([\s\S]+?)</script>', h):
        for tpl in re.findall(r'`[^`]*`', sc):
            sim = tpl.replace('\\\\', '\x00').replace('\\%', '%').replace('\x00', '\\')
            sim = re.sub(r'\$\{[^}]*\}', '0', sim)
            for mm in re.finditer(r'(?<!\$)\$(?!\{)[^$\n]+?(?<!\$)\$(?!\{)', sim):
                if any(c in BAD for c in mm.group(0)):
                    issues.append(('JS-BAD', mm.group(0)[:48]))
                if re.search(r'(?<!\\)%', mm.group(0)):
                    issues.append(('JS-bare%', mm.group(0)[:48]))

    # 2) смешанные скрипты (кириллица+латиница в одном слове), длина > 2
    mixed = [m for m in set(re.findall(r'[а-яё]+[a-z]+|[a-z]+[а-яё]+', nostyle, re.I)) if len(m) > 2]
    for w in mixed:
        issues.append(('MIXED', w))

    # 3) структура
    if h.count('</html>') != 1:
        issues.append(('STRUCT', f'</html> x{h.count("</html>")}'))
    if h.count('<script') != h.count('</script>'):
        issues.append(('STRUCT', f'<script> {h.count("<script")} != </script> {h.count("</script>")}'))
    # баланс $ вне <script>/<style> и без \$ — грубая проверка
    plain = re.sub(r'<script>[\s\S]+?</script>', '', nostyle)
    plain = re.sub(r'\$\$', '', plain)               # display-доллары парные
    if plain.replace(r'\$', '').count('$') % 2 != 0:
        issues.append(('STRUCT', 'нечётное число $ в HTML'))
    return issues

def main():
    globs = sys.argv[1:] or DEFAULT_GLOBS
    files = sorted({f for g in globs for f in glob.glob(g)})
    if not files:
        print('Файлы не найдены по шаблону:', globs); return 1
    print(f'Pre-flight: {len(files)} файлов')
    total = 0
    for f in files:
        iss = scan_file(f)
        name = '/'.join(f.split('/')[-2:])
        print(f'  {"✓" if not iss else "❌"} {name}: {len(iss)} проблем')
        for kind, x in iss[:10]:
            print(f'       [{kind}] {x}')
        total += len(iss)
    print(f'\nИтого проблем: {total}')
    return 0 if total == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
