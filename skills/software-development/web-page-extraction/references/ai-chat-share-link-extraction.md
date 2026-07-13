# Extracting Content from AI Chat Share Links

Many AI conversation share links (Gemini, ChatGPT, Claude) show a **sign-in wall** when accessed from a script or non-authenticated browser. The actual conversation text IS captured by `web_extract` — it's embedded as escaped JSON in the result, even though the rendered output truncates to just the login page.

## The technique

1. **Call `web_extract(url)`** on the share link. The result will look like a sign-in page, but the full HTML (160K+) was saved to a cache file.

2. **Find the cache file** — check `web_extract`'s tool result. If the output was truncated, a path like `call_00_XXXXXXXXXXXX.txt` will be mentioned under "Full output saved to:"

3. **Parse the escaped JSON content** — the conversation text lives inside the `content` field of the extracted JSON with escaped `\n` sequences:

```python
import json, re

# Read the cached result file
with open('call_00_XXXXXXXXXXXX.txt') as f:
    data = json.load(f)

content = data['results'][0]['content']

# Replace literal \n sequences with real newlines
text = content.replace('\\n', '\n')

# Strip markdown-style links (keep label, drop URL)
text = re.sub(r'\[([^\]]+)\]\(https?://[^\)]+\)', r'\1', text)

# Split into lines
lines = text.split('\n')
```

4. **Find the conversation** — search for the user's first message text to find where the actual conversation begins:

```python
for i, line in enumerate(lines):
    if 'Your first question' in line:
        conversation = '\n'.join(lines[i:])
        break
```

## Works for these share link patterns

| Platform | URL pattern | Notes |
|----------|------------|-------|
| Gemini | `gemini.google.com/share/*` | Uses `3.1 Flash-Lite` label in page title |
| ChatGPT | `chat.openai.com/share/*` | Similar pattern — sign-in wall rendered, content in cache |
| Claude | `claude.ai/share/*` | Same approach |

## Edge cases

- **Very long conversations** (>200K chars) may be capped by web_extract's 2M char limit. The cache file will still contain the full page HTML.
- **Multiple `\\n`** — some platforms use `\\n\\n` for paragraph breaks. The `replace('\\n', '\n')` handles these correctly.
- **The web_extract call itself doesn't need authentication** — shared links are public-by-design, the sign-in wall is just a JS-rendered gating layer that web_extract's static fetch bypasses.
