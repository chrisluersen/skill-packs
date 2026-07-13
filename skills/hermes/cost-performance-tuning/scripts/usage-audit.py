#!/usr/bin/env python3
"""Cost estimation from Hermes session_registry.db.

Since Hermes has no native cost tracking, this script estimates usage
from session metadata (model, message_count) × known model pricing.

Usage:
    cd ~/.hermes
    python3 scripts/usage-audit.py

Output: Per-model session count, message count, estimated tokens, estimated cost.
"""

import sqlite3
import datetime

DB_PATH = r'~/AppData/Local/hermes\AppData\Local\hermes\session_registry.db'

PRICING = {
    'deepseek/deepseek-v4-flash': {'input': 0.15, 'output': 0.60, 'provider': 'Nous'},
    'deepseek-v4-flash': {'input': 0.15, 'output': 0.60, 'provider': 'Nous'},
    'google/gemini-2.5-flash': {'input': 0.15, 'output': 0.60, 'provider': 'OpenRouter'},
    'gemini-2.5-flash': {'input': 0.15, 'output': 0.60, 'provider': 'OpenRouter'},
    'anthropic/claude-sonnet-4': {'input': 3.00, 'output': 15.00, 'provider': 'OpenRouter'},
    'claude-sonnet-4': {'input': 3.00, 'output': 15.00, 'provider': 'OpenRouter'},
    'deepseek/deepseek-v4-pro': {'input': 2.00, 'output': 8.00, 'provider': 'Nous'},
    'stepfun/step-3.7-flash:free': {'input': 0, 'output': 0, 'provider': 'Free'},
    '': {'input': 0, 'output': 0, 'provider': 'Unknown'},
}

EST_OVERHEAD = 22000
EST_INPUT = 800
EST_OUTPUT = 2000


def main():
    db = sqlite3.connect(DB_PATH)
    c = db.cursor()
    c.execute("SELECT MIN(started_at), MAX(started_at), COUNT(*) FROM sessions")
    min_ts, max_ts, total = c.fetchone()
    min_dt = datetime.datetime.fromtimestamp(min_ts) if min_ts else None
    max_dt = datetime.datetime.fromtimestamp(max_ts) if max_ts else None
    print(f"Date range: {min_dt} to {max_dt} ({total} total sessions)")
    seven_days_ago = (datetime.datetime(2026, 7, 1) - datetime.datetime(1970, 1, 1)).total_seconds()
    c.execute("""
        SELECT COALESCE(NULLIF(model,''), '(unknown)') as m,
               COUNT(*) as sessions, SUM(message_count) as total_msgs
        FROM sessions WHERE started_at >= ?
        GROUP BY m ORDER BY sessions DESC
    """, (seven_days_ago,))
    models = c.fetchall()
    db.close()
    print(f"\n{'Model':50s} {'Sessions':^9s} {'Msgs':^8s} {'Est. Cost':^10s}")
    print("-" * 80)
    total_cost = 0.0
    for model, sessions, msgs in models:
        p = PRICING.get(model, {'input': 0.15, 'output': 0.60})
        est_in = sessions * EST_OVERHEAD + msgs * EST_INPUT
        est_out = msgs * EST_OUTPUT
        cost = (est_in / 1_000_000 * p['input'] + est_out / 1_000_000 * p['output'])
        total_cost += cost
        print(f"{model:50s} {sessions:^9d} {msgs:^8d} ${cost:>7.2f}")
    print("-" * 80)
    ts, tm = sum(r[1] for r in models), sum(r[2] for r in models)
    print(f"{'TOTAL':50s} {ts:^9d} {tm:^8d} ${total_cost:>7.2f}")
    print(f"Daily avg: ${total_cost/7:.2f}  |  Monthly: ${total_cost/7*30:.2f}")


if __name__ == '__main__':
    main()
