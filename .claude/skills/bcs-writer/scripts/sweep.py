#!/usr/bin/env python3
"""BCS article gate: voice, punctuation, references, links, figures.

Usage:
  python3 sweep.py ARTICLE.md [--figures "tok1,tok2,..."] [--outs out1,out2,...]

Exit 0 = all gates pass. Nonzero = failures printed.
Figure tokens are exact substrings that must appear in the committed .out
files (use the numbers exactly as the article prints them).
"""
import argparse, os, re, sys

FORBIDDEN = (r'\b(just|simply|obviously|effortless\w*|magical\w*|revolutionary|'
             r'blazing|actually|genuinely|honestly|easy|seamless\w*|powerful|'
             r'honest|honesty)\b')

def main():
    p = argparse.ArgumentParser()
    p.add_argument('article')
    p.add_argument('--figures', default='')
    p.add_argument('--outs', default='')
    a = p.parse_args()
    src = open(a.article, encoding='utf-8').read()
    base = os.path.dirname(os.path.abspath(a.article))
    fails = []

    prose = re.sub(r'```.*?```', '', src, flags=re.S)
    prose = re.sub(r'`[^`]*`', '', prose)
    prose_no_tables = re.sub(r'^\|.*$', '', prose, flags=re.M)
    prose_no_tables = re.sub(r'<[^>]+>', '', prose_no_tables)
    bad = re.findall(FORBIDDEN, prose_no_tables, re.I)
    if bad:
        fails.append(f"forbidden words: {sorted(set(w.lower() for w in bad))}")
    if '!' in prose_no_tables:
        fails.append(f"exclamation marks: {prose_no_tables.count('!')}")

    cited = set(re.findall(r'\[(\d+)\]', prose_no_tables))
    listed = set(re.findall(r'^(\d+)\. ', src, re.M))
    if cited != listed:
        fails.append(f"refs cited {sorted(cited)} != listed {sorted(listed)}")

    for link in re.findall(r'\]\(([^)#]+)\)', src):
        if link.startswith(('http://', 'https://')):
            continue
        if not os.path.exists(os.path.join(base, link)):
            fails.append(f"unresolved link: {link}")

    quotes = re.findall(r'[“"]([^”"\n]{20,})[”"]', prose_no_tables)
    long_q = [q[:50] for q in quotes if len(q.split()) >= 15]
    if long_q:
        fails.append(f"quotes >=15 words: {long_q}")

    if a.figures:
        outs = ''.join(open(f, encoding='utf-8').read()
                       for f in a.outs.split(',') if f)
        missing = [t for t in a.figures.split(',') if t and t not in outs]
        if missing:
            fails.append(f"figures missing from outs: {missing}")

    if fails:
        print('SWEEP FAIL')
        for f in fails:
            print(' -', f)
        sys.exit(1)
    print('SWEEP PASS: voice, punctuation, refs, links, quotes'
          + (', figures' if a.figures else ''))

if __name__ == '__main__':
    main()
