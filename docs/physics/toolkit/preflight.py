#!/usr/bin/env python3
"""Преполётная проверка HTML-страниц курса.
- запрещённые символы внутри $...$ / $$...$$ (KaTeX strict)
- вложенные <a> (anchor-in-anchor)
- базовая целостность (виден <body>, есть <footer>)
Запуск: python3 preflight.py site/physics/index.html [...]"""
import re, sys

BAD = set('№«»“”„₽…•—–·×÷≤≥≠')  # типографика/единицы — не должны быть внутри KaTeX
MATH = re.compile(r'\$\$[^$]+?\$\$|\$[^$\n]+?\$')

def nested_anchors(h):
    depth = 0; n = 0
    for m in re.finditer(r'<a\b[^>]*>|</a>', h):
        if m.group(0).startswith('</a'):
            depth = max(0, depth - 1)
        else:
            if depth >= 1: n += 1
            depth += 1
    return n

def check(path):
    h = open(path, encoding='utf-8').read()
    issues = []
    for m in MATH.finditer(h):
        bad = [c for c in m.group(0) if c in BAD]
        if bad:
            issues.append(f'KaTeX-символы {bad} в {m.group(0)[:40]!r}')
    na = nested_anchors(h)
    if na:
        issues.append(f'вложенных <a>: {na}')
    if '<body' not in h:
        issues.append('нет <body>')
    if '</footer>' not in h:
        issues.append('нет <footer>')
    return issues

def main(argv):
    total = 0
    for p in argv:
        iss = check(p)
        total += len(iss)
        if iss:
            print(f'  ✗ {p}:')
            for i in iss: print(f'      - {i}')
        else:
            print(f'  ✓ {p}: 0 проблем')
    print(f'\nИтого проблем: {total}')
    return 1 if total else 0

if __name__ == '__main__':
    raise SystemExit(main(sys.argv[1:]))
