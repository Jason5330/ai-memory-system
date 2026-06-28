#!/usr/bin/env python3
"""recall.py - zero-dependency fuzzy memory search over the markdown knowledge pages.

Adapted from Open LeftBrain's search.py (difflib fuzzy + token-overlap, CJK-aware) but kept TRUE to
this framework: it searches the **plain-markdown** store (knowledge/*.md + MEMORY.md), never a binary
DB. Pure Python standard library only — Python is OPTIONAL here: it just makes recall *semantic-ish*
(synonyms / paraphrase) instead of exact-keyword. If Python isn't installed, the /recall operation
falls back to scanning MEMORY.md by keyword.

Usage:
  python recall.py "<query>" [--personal <dir>] [--project <dir>] [--limit 8] [--json]
Defaults: --personal ~/.ai-memory ; --project ./.claude/memory (if it exists).
Exit 0 always (read-only).
"""
import argparse, difflib, json, os, re, sys
from pathlib import Path

# Force UTF-8 stdout so Chinese summaries aren't mangled by the Windows console codepage (cp950).
try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

TOKEN_RE = re.compile(r'[\w一-鿿]+', re.UNICODE)

def tokens(text):
    return {t.lower() for t in TOKEN_RE.findall(text or '')}

def score(query, content):
    q = query.lower().strip()
    c = (content or '').lower()
    if not q:
        return 0.0
    if q in c:
        return 80.0 + min(10.0, len(q) / max(len(c), 1) * 10.0)
    qt, ct = tokens(q), tokens(c)
    overlap = len(qt & ct) / max(len(qt), 1)
    fuzzy = difflib.SequenceMatcher(None, q, c).ratio()
    return overlap * 60.0 + fuzzy * 40.0

def summary_line(text):
    """The '> Summary' / first meaningful line, for a one-line preview."""
    for line in text.splitlines():
        s = line.strip()
        if s.startswith('>'):
            return s.lstrip('> ').strip()
    for line in text.splitlines():
        s = line.strip()
        if s and not s.startswith(('---', '#', 'name:', 'type:', 'kind:', 'layer:', 'first_seen:', 'last_updated:')):
            return s
    return ''

def gather(root, layer):
    items = []
    kdir = Path(root) / 'knowledge'
    if kdir.is_dir():
        for f in kdir.glob('*.md'):
            try:
                text = f.read_text(encoding='utf-8')
            except Exception:
                continue
            items.append({'path': str(f), 'name': f.stem, 'layer': layer, 'text': text})
    return items

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('query')
    ap.add_argument('--personal', default=str(Path(os.path.expanduser('~')) / '.ai-memory'))
    ap.add_argument('--project', default=str(Path.cwd() / '.claude' / 'memory'))
    ap.add_argument('--limit', type=int, default=8)
    ap.add_argument('--json', action='store_true')
    a = ap.parse_args()

    items = gather(a.personal, 'personal')
    if Path(a.project).is_dir():
        items += gather(a.project, 'project')

    ranked = []
    for it in items:
        sc = max(score(a.query, it['text']), score(a.query, it['name']))
        if sc > 0:
            ranked.append({'name': it['name'], 'layer': it['layer'], 'path': it['path'],
                           'score': round(sc, 1), 'summary': summary_line(it['text'])})
    ranked.sort(key=lambda x: x['score'], reverse=True)
    ranked = ranked[:a.limit]

    if a.json:
        print(json.dumps(ranked, ensure_ascii=False)); return
    if not ranked:
        print(f'RECALL: no knowledge page matches "{a.query}".'); return
    print(f'RECALL: top {len(ranked)} for "{a.query}" (fuzzy, both layers) -')
    for r in ranked:
        print(f"  [{r['score']:5.1f}] ({r['layer']}) {r['name']} -- {r['summary']}")
        print(f"          {r['path']}")

if __name__ == '__main__':
    main()
