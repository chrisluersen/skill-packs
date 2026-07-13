# Stale Auxiliary Model IDs — Diagnostic & Bulk Fix

**Problem:** An auxiliary task (vision, compression, web_extract, skills_hub, approval, etc.) fails with a confusing "model not found" error:
```
google/gemini-3-flash-preview is not a valid model ID
```

**Root cause:** The provider deprecated/renamed the model. The pinned model name in `config.yaml` is stale.

**Critical insight:** The fix is NOT just the one section that errored. You must replace it across **every auxiliary section** plus any TTS/other provider references, because they all likely use the same stale model.

---

## Diagnostic

```bash
# 1. Find all occurrences in config.yaml
grep -n "stale-model-id" ~/.hermes/config.yaml
# e.g. grep -n "gemini-3-flash-preview" ~/.hermes/config.yaml

# 2. Check which aux sections use it
grep -B2 -A2 "stale-model-id" ~/.hermes/config.yaml

# 3. Verify OpenRouter key is active (if using OpenRouter for aux)
grep OPENROUTER ~/.hermes/.env
# If commented out or missing → aux tasks fail with model-not-found, NOT auth error
```

---

## Bulk Fix Procedure

```bash
# Replace across ALL auxiliary sections
for section in vision compression web_extract skills_hub approval \
               title_generation curator monitor triage_specifier \
               kanban_decomposer profile_describer mcp; do
  hermes config set "auxiliary.$section.model" "google/gemini-2.5-flash"
done

# Also check TTS if using gemini
# hermes config set tts.gemini.model "gemini-2.5-flash-tts"
```

---

## Prevention

- Prefer `auxiliary.*.provider: "auto"` (tries main provider first, falls back to OpenRouter) over hardcoded providers — fewer pins to rot.
- Pin `auxiliary.*.model` only when you need specific quality (e.g. vision OCR → Gemini 2.5 Flash). Otherwise leave empty to inherit provider default.
- Run `grep -n "preview" ~/.hermes/config.yaml` periodically — "preview" in model names is a strong signal of impending deprecation.
- When a provider announces model deprecations, bulk-update immediately using the loop above.

---

## Related Files

- `references/custom-provider-auth.md` — 401 auth vs model-not-found distinction
- `references/in-session-model-switching.md` — provider/model switch ordering