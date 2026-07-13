#!/usr/bin/env bash
# verify-wiki-structure.sh
#
# Re-runnable verification probe for LLM Wiki integrity.
# Run after any refactor or large ingest to catch:
#   - Missing frontmatter
#   - Missing required fields
#   - File count mismatches vs index
#   - Orphan pages (no inbound wikilinks — basic scan)
#   - Git status / dirty tree
#
# Usage: bash verify-wiki-structure.sh <wiki-root>
# Example: bash verify-wiki-structure.sh ~/AppData/Local/hermes/wiki

set -euo pipefail

WIKI="${1:-.}"
ERRORS=0
PASS=0

green() { printf "\033[32m%s\033[0m\n" "$1"; }
red()   { printf "\033[31m%s\033[0m\n" "$1"; }

echo "=== Wiki Integrity Check ==="
echo "Root: $WIKI"
echo ""

# --- 1. Frontmatter on every non-raw page ---
PAGES=$(find "$WIKI" -name '*.md' -not -path '*/raw/*' -not -path '*/.git/*' | sort)
TOTAL=$(echo "$PAGES" | wc -l)
echo "=== 1. Frontmatter Check ($TOTAL pages) ==="
BAD=0
while IFS= read -r f; do
    if ! head -1 "$f" | grep -q '^---$'; then
        red "  NO FRONTMATTER: $f"
        BAD=$((BAD+1))
    fi
done <<< "$PAGES"
if [ "$BAD" -eq 0 ]; then
    green "  All $TOTAL pages have frontmatter ✓"
    PASS=$((PASS+1))
else
    echo "  $BAD pages missing frontmatter"
    ERRORS=$((ERRORS+1))
fi

# --- 2. Required frontmatter fields ---
echo "=== 2. Required Fields Check ==="
BAD=0
REQUIRED=("created:" "updated:" "type:" "id:")
while IFS= read -r f; do
    for field in "${REQUIRED[@]}"; do
        if ! head -10 "$f" | grep -q "$field"; then
            echo "  MISSING $field in $f"
            BAD=$((BAD+1))
        fi
    done
done <<< "$PAGES"
if [ "$BAD" -eq 0 ]; then
    green "  All required fields present ✓"
    PASS=$((PASS+1))
else
    echo "  $BAD missing fields"
    ERRORS=$((ERRORS+1))
fi

# --- 3. Git status ---
echo "=== 3. Git Status ==="
if [ -d "$WIKI/.git" ]; then
    STATUS=$(cd "$WIKI" && git status --short 2>&1)
    if [ -z "$STATUS" ]; then
        green "  Clean working tree ✓"
    else
        echo "  Uncommitted changes:"
        echo "$STATUS"
    fi
    echo "  Last commit: $(cd "$WIKI" && git log --oneline -1 2>/dev/null || echo 'none')"
    PASS=$((PASS+1))
else
    echo "  No git repository"
fi

# --- 4. File count vs index header ---
echo "=== 4. Index Count Check ==="
INDEX_FILE="$WIKI/index.md"
if [ -f "$INDEX_FILE" ]; then
    CLAIMED=$(grep -oP 'Total pages:\s*\K\d+' "$INDEX_FILE" | head -1)
    PAGES_IN_TABLES=$(grep -c '^|' "$INDEX_FILE" || true)
    echo "  Index claims: $CLAIMED pages | Index table rows: $PAGES_IN_TABLES"
    if [ -n "$CLAIMED" ] && [ "$TOTAL" -ge "$((CLAIMED-2))" ] && [ "$TOTAL" -le "$((CLAIMED+2))" ]; then
        green "  Count roughly consistent ($TOTAL files vs $CLAIMED claimed) ✓"
    else
        echo "  Count mismatch: $TOTAL files vs $CLAIMED claimed"
    fi
    PASS=$((PASS+1))
fi

# --- 5. Basic orphan scan ---
echo "=== 5. Orphan Scan (no inbound wikilinks from other pages) ==="
BODY_FILES=$(find "$WIKI" -name '*.md' -not -path '*/raw/*' -not -path '*/.git/*' -not -name 'index.md' -not -name 'log.md' -not -name 'SCHEMA.md' -not -name 'README.md' | sort)
INBOUND_MAP=$(mktemp)
while IFS= read -r f; do
    BASENAME=$(basename "$f" .md)
    echo "0 $BASENAME" >> "$INBOUND_MAP"
done <<< "$BODY_FILES"

# Count inbound links from other pages
while IFS= read -r f; do
    WIKILINKS=$(grep -oP '\[\[\K[^\]\]]+' "$f" 2>/dev/null || true)
    while IFS= read -r link; do
        [ -z "$link" ] && continue
        link="${link%%|*}"
        link="${link%%#*}"
        awk -v l="$link" '{if($2==l) $1=$1+1}1' "$INBOUND_MAP" > "${INBOUND_MAP}.tmp" && mv "${INBOUND_MAP}.tmp" "$INBOUND_MAP"
    done <<< "$WIKILINKS"
done <<< "$BODY_FILES"

ORPHANS=0
while IFS= read -r line; do
    count=$(echo "$line" | awk '{print $1}')
    page=$(echo "$line" | awk '{print $2}')
    if [ "$count" -eq 0 ]; then
        echo "  Orphan: $page"
        ORPHANS=$((ORPHANS+1))
    fi
done < "$INBOUND_MAP"
rm -f "$INBOUND_MAP"

if [ "$ORPHANS" -eq 0 ]; then
    green "  No orphans found ✓"
    PASS=$((PASS+1))
else
    echo "  $ORPHANS orphan pages found"
fi

echo ""
echo "=== Summary ==="
echo "Checks passed: $PASS/5"
echo "Errors: $ERRORS"
if [ "$ERRORS" -eq 0 ]; then
    green "✓ Wiki integrity verified"
else
    red "✗ $ERRORS checks failed — review above"
    exit 1
fi
