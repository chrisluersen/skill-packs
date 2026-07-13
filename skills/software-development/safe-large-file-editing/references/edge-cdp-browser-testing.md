# Edge CDP Browser Testing

Launch Edge with remote debugging to test self-contained HTML files on Windows.

## Launch

```bash
"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" \
  --remote-debugging-port=9222 \
  --user-data-dir="~/AppData/Local/hermes\.edge-debug-test" \
  "file:///~/AppData/Local/hermes/AI%20Architecture.html"
```

- `--remote-debugging-port=9222`: Opens CDP endpoint at `http://localhost:9222/json`
- `--user-data-dir`: Use a **fresh profile dir** to avoid extension noise. Generate a new one each session with e.g. `...edge-debug-session-$(date +%s)`.
- Pass the file:// URL as the last arg.

## Connect

Once launched, `browser_cdp` tools become available. The CDP auto-connects — no manual `Target.getTargets` needed.

## Check Console

```python
browser_console()  # Returns console_messages and js_errors arrays
```

## Navigate to Tabs

List open tabs, then interact with the right one:

```python
# Target.getTargets lists all open tabs/background pages
browser_cdp(method='Target.getTargets')
# Find the 'page' type with your title, use its targetId
browser_cdp(method='Runtime.evaluate', params={'expression': '...'}, target_id='<tabId>')
```

## Limitations

- `file://` protocol pages may restrict some CDP domains (Runtime, Emulation may not be available). Use the `browser_console` (with `expression` parameter) and `browser_snapshot` tools instead — they work through the Hermes browser abstraction layer.
- `Emulation.setDeviceMetricsOverride` for mobile viewport emulation may be unavailable on file:// URLs in some Edge versions. Verify responsive behavior by resizing the window instead, or test in the Hermes browser tool directly.

## Verification Checklist

| Check | Tool |
|-------|------|
| JS console errors | `browser_console()` — expect 0 |
| Theme toggle | Click theme button, verify class changes |
| Sidebar toggle | Click menu-btn, verify sidebar visibility |
| Filter buttons | Click each filter-btn, verify card visibility |
| Code copy | Click cb-copy, verify 'Copied!' toast |
| Line numbers | Click cb-ln-toggle, verify line numbers appear |
| Section nav | Click next/previous, verify scroll to correct section |
