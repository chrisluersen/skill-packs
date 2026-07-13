#!/usr/bin/env python3
"""
Content deduplication audit for large HTML/Markdown files.
Run: python3 dedupe-audit.py "AI Architecture.html"

Outputs: Duplicate headings, code blocks, command patterns, and table similarities.
"""

import sys
import re
import hashlib
from collections import Counter

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 dedupe-audit.py <file>")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    print(f"Auditing {path} ({len(content):,} bytes)\n")

    # 1. Duplicate H2/H3 headings
    h2s = re.findall(r'<h2[^>]*>([^<]+)</h2>', content)
    h3s = re.findall(r'<h3[^>]*>([^<]+)</h3>', content)
    for label, heads in [('H2', h2s), ('H3', h3s)]:
        dupes = {h: c for h, c in Counter(heads).items() if c > 1}
        if dupes:
            print(f"Duplicate {label}s:")
            for h, c in dupes.items():
                print(f"  {c}x: {h}")
            print()

    # 2. Duplicate code blocks (exact HTML match)
    blocks = re.findall(r'<div class="code-block">[\s\S]*?</div>', content)
    hashes = [hashlib.md5(b.encode()).hexdigest()[:8] for b in blocks]
    dupes = {h: c for h, c in Counter(hashes).items() if c > 1}
    if dupes:
        print(f"Duplicate code blocks: {len(dupes)}")
        for h, c in dupes.items():
            print(f"  {c}x: hash={h}")
        print()

    # 3. Common command patterns
    patterns = [
        ('winget install', r'winget install [^\n<]+'),
        ('zellij --layout', r'zellij --layout [^\n<]+'),
        ('hermes config set', r'hermes config set [^\n<]+'),
    ]
    for label, pat in patterns:
        matches = re.findall(pat, content)
        dupes = {m: c for m, c in Counter(matches).items() if c > 1}
        if dupes:
            print(f"Duplicate {label}:")
            for m, c in dupes.items():
                print(f"  {c}x: {m}")
            print()

    # 4. Concept keyword occurrences
    keywords = ['zellij', 'hermes', 'tmux', 'ollama', 'acp', 'mcp', 'skill', 'profile']
    print("Concept keyword counts:")
    for kw in keywords:
        count = len(re.findall(kw, content, re.IGNORECASE))
        if count > 0:
            print(f"  {kw}: {count}x")
    print()

    print("Done.")

if __name__ == '__main__':
    main()