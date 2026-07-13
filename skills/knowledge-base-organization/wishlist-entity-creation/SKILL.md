---
name: wishlist-entity-creation
category: knowledge-base-organization
description: Create standardized entity pages for wishlist/to-buy items with provenance tracking
---

# Wishlist Entity Creation

## When to Use
When user wants to track items to purchase with full provenance and research linking capabilities.

## Standard Entity Template
```markdown
---
tags: [wishlist, to-buy]
relates_to: []
sources: []
---

# [Item Name]

## Status
- [ ] Research needed
- [ ] Comparison needed
- [ ] Ready to purchase

## Research

## Notes
```

## Workflow

1. **Create Entity Pages**: For each item, create a page in `pending/` with the standard template
2. **Tag Consistently**: Always use `wishlist` and `to-buy` tags
3. **Link Relationships**: Use `relates_to` to connect:
   - Items from the same brand (e.g., Lineage cologne → Lineage soap)
   - Items in the same category (e.g., headphones → peripherals)
   - Research pages to items
4. **Create Brand Entities**: When multiple items share a brand (e.g., Lineage), create a brand entity page that:
   - Lists all products from that brand in a `Products` section
   - Uses `relates_to` to link to all product entities
   - Is tagged with `[brand, <brand-name>]`
5. **Cross-Link Products**: Update each product entity's `relates_to` to include:
   - The brand entity
   - All other products from the same brand
6. **Reindex**: Always call `mcp_wiki_reindex_wiki` after batch creation
7. **Promote**: Move from `pending/` to `entities/` after review using `git mv`

## Git Promotion Pattern
```bash
cd /path/to/wiki
git mv pending/<page>.md entities/
```
**Note**: If `pending/` directory isn't tracked, add it first:
```bash
git add pending/
git commit -m "Add pending directory"
```

## Example Commands
```python
# Single item
mcp_wiki_file_synthesis(
    page_id="item-name",
    title="Item Name",
    content="---\ntags: [wishlist, to-buy]\n..."
)

# Batch creation (use parallel calls)
for item in items:
    mcp_wiki_file_synthesis(...)

# After creation
mcp_wiki_reindex_wiki()
```

## Provenance Rules
- **sources[]**: Link to original request or paste
- **relates_to**: Connect to brand pages, category pages, or research
- Always trace back to where the item was first mentioned

## Next Steps After Creation
1. Offer to add `relates_to` edges between related items
2. Suggest creating a brand entity (e.g., "Lineage") if multiple items from same brand
3. Ask if user wants to start research on any item immediately

## Pitfalls
- Don't create entities for trivial/one-off items
- Always use kebab-case for page_ids
- Remember to reindex after batch operations
- Pages go to `pending/` first, require human review before promotion