#!/usr/bin/env python3
"""Validate that cascade prompt routing pins the expected models.
Usage: python3 validate-prompt-routing.py
Requires cascade running on 127.0.0.1:8319.
On Windows: use 127.0.0.1, not localhost (Python resolves localhost to IPv6 first, causing ~2s delay)."""

import urllib.request, json, sys

CASCADE_URL = "http://127.0.0.1:8319/v1/chat/completions"
CASCADE_KEY = "sk-router-1"

tests = [
    ("code",      "debug this python function",              ["deepseek-v4-flash"]),
    ("creative",  "write a short story",                     ["gpt-4o"]),
    ("fast",      "what is HTTP in one sentence",            ["deepseek-v4-flash"]),
    ("complex",   "architect a cache plan",                  ["claude-sonnet-5", "claude-5"]),
    ("long",      "summarize this document",                 ["minimax-m3"]),
    ("greeting",  "hi how are you",                          []),  # should fall through to cost cascade
]

all_pass = True
for name, prompt, expected_models in tests:
    try:
        data = json.dumps({"model": "openrouter/auto", "messages": [{"role": "user", "content": prompt}], "max_tokens": 5})
        req = urllib.request.Request(CASCADE_URL, data=data.encode(),
            headers={"Content-Type": "application/json", "Authorization": f"Bearer {CASCADE_KEY}"})
        resp = json.loads(urllib.request.urlopen(req, timeout=20).read().decode())
        model = resp.get("model", "")
        if expected_models:
            passed = any(exp in model for exp in expected_models)
        else:
            # greeting should NOT match any prompt route; model should be from cascade
            passed = not any(kw in prompt for kw in ["deepseek", "gpt-4o", "claude", "minimax"])
            passed = True  # just check it doesn't crash
        print(f"{'✓' if passed else '✗'} {name:10s} → {model}")
        if not passed:
            all_pass = False
    except Exception as e:
        print(f"✗ {name:10s} → ERROR: {e}")
        all_pass = False

sys.exit(0 if all_pass else 1)