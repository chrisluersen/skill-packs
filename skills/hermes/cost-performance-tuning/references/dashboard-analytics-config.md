# Dashboard Analytics Visibility Config

The Hermes WebUI dashboard has two analytics toggles that control cost and token visibility:

## Toggles

```
dashboard.show_token_analytics    # default: false — token usage per session in Sessions tab
display.show_cost                 # default: false — per-turn cost in status bar
```

Both are off by default. Turn them on to see real-time cost and token data.

## Setting Them

**On Linux/macOS (and when `hermes config set` works):**
```bash
hermes config set dashboard.show_token_analytics true
hermes config set display.show_cost true
```

**On Windows (when `hermes config set` fails with PermissionError):**
```bash
sed -i 's/show_token_analytics: false/show_token_analytics: true/' ~/AppData/Local/hermes/AppData/Local/hermes/config.yaml
sed -i 's/show_cost: false/show_cost: true/' ~/AppData/Local/hermes/AppData/Local/hermes/config.yaml
```

Verify with:
```bash
grep "show_token_analytics\|show_cost" ~/AppData/Local/hermes/AppData/Local/hermes/config.yaml
```

## What They Show

- `show_token_analytics` — in the dashboard Sessions tab, each session shows total tokens used. Useful for identifying which sessions burn the most context.
- `show_cost` — in the TUI status bar (bottom), shows the estimated cost of the current session. Only meaningful when your provider reports per-token pricing.

## When to Turn On

- **Always, if cost-aware.** The token overhead is negligible (a few characters in the status bar).
- **During tuning sessions.** Turn both on, make a change, run a few tasks, check if cost changed as expected.

## When to Leave Off

- **Tight budget scenarios where every character matters.** The cost display adds ~50-100 tokens to the session prefix (status bar rendering instructions).
- **Free models only.** If you never pay for inference, these stats are meaningless.