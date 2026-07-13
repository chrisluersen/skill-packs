#!/usr/bin/env python3
"""
Verify all internal anchor links resolve in an HTML file.
Run: python3 verify-crosslinks.py "AI Architecture.html"
"""

import sys
import re

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 verify-crosslinks.py <file>")
        sys.exit(1)

    path = sys.argv[1]
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Collect all IDs (section, heading, card, etc.)
    ids = set(re.findall(r'id="([^"]+)"', content))

    # Check all href="#..."
    links = re.findall(r'href="#([^"]+)"', content)
    broken = [l for l in links if l not in ids]

    if broken:
        print(f"BROKEN LINKS ({len(broken)}):")
        for l in broken:
            print(f"  #{l}")
        sys.exit(1)
    else:
        print(f"All {len(links)} internal links resolve ✅")

if __name__ == '__main__':
    main()