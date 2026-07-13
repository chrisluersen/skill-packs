# Research Sources — Web Page Extraction

Collected from session 2026-06-17. All stats and pricing verified at time of collection; model pricing changes frequently — re-verify with `web_search` when the numbers in the skill seem stale.

## Meta tag coverage

| Source | Stat | Citation |
|--------|------|----------|
| Open Graph tags | 70.5% of websites include OG tags | W3Techs, cited by Fast.io |
| Schema.org JSON-LD | 45+ million domains embed structured data | Schema.org / Google, cited by Fast.io |
| JSON-LD recommendation | Google recommends JSON-LD over microdata | Google Search Central docs |

## Firecrawl pricing (March 2026)

Credit multipliers (non-obvious):
- Scrape (single page): 1 credit
- Crawl (per page discovered): 2 credits
- Map (sitemap): 1 credit
- Extract (structured data): 5 credits ← the trap
- LLM Extract (AI parsing): 5+ credits
- Screenshot: 2 credits

Effective extraction costs per plan:
| Plan | Monthly | Raw credits | Effective extractions | Cost per extraction |
|------|---------|------------|----------------------|-------------------|
| Free | $0 | 500 | 100 | $0 |
| Hobby | $16 | 3,000 | 600 | $0.027 |
| Standard | $83 | 100,000 | 20,000 | $0.004 |
| Growth | $333 | 500,000 | 100,000 | $0.003 |
| Enterprise | Custom | Custom | Custom | ~$0.002 |

Failed requests still burn credits. Crawl overruns (no maxPages set) burn 2 credits per unexpected page.
No rollover. Tokens silently truncated on long pages.

Source: ScrapeGraphAI Firecrawl Pricing Breakdown (2026) — scrapegraphai.com/blog/firecrawl-pricing

## Model pricing (as of June 2026)

| Model | Provider | Input $/1M | Output $/1M | Context | Notes |
|-------|----------|-----------|------------|---------|-------|
| DeepSeek V3.2-Exp | DeepSeek/OpenRouter | $0.28 | $0.42 | 128K | Best price/quality ratio for bulk |
| Gemini 2.5 Flash | Google | $0.30 | $2.50 | 1M+ | 2M context, great for batching |
| Gemini 2.5 Pro | Google | $1.25 | $10.00 | 1M+ | Premium tier |
| Claude Haiku 4.5 | Anthropic | $1.00 | $5.00 | 200K | Very reliable, low hallucination |
| Claude Sonnet 4.6 | Anthropic | $3.00 | $15.00 | 200K | Gold standard extraction |
| Claude Opus 4.6 | Anthropic | $15.00 | $75.00 | 200K | Overkill for extraction |
| GPT-5 nano | OpenAI | $0.50 | $2.00 | 32K | Severely limited context |

Sources: IntuitionLabs AI pricing comparison 2025, Nebius blog DeepSeek V3 comparison, individual provider pricing pages.

## Extraction quality estimates (justified)

Scores are estimates based on published benchmarks and model behavior, not standardised test results:

| Model | Score | Rationale |
|-------|-------|-----------|
| Meta tags only | 65 | Missing author, tags, often generic descriptions |
| DeepSeek V3.2-Exp | 78 | Strong on clear pages, misses subtle fields, occasional hallucination on dates |
| Gemini 2.5 Flash | 82 | Good recall, some format inconsistency, cheap |
| Claude Haiku 4.5 | 85 | Reliable, rarely hallucinates, follows instructions well |
| Gemini 2.5 Pro | 90 | Excellent, near Sonnet-level |
| Claude Sonnet 4.6 | 92 | Gold standard, consistent JSON output |
| GPT-5.2 | 93 | Similar to Sonnet, slightly better on messy HTML |
| Claude Opus 4.6 | 95 | Overkill — marginal gain for 5× cost |

The 4-tier blended score of ~89 assumes Tier 0 (65) on 70%, Tier 1 (78) on 15%, Tier 2 (84) on 10%, Tier 3 (94) on 5% — weighted average = ~89.

## Key papers / tools referenced

- **AXE paper** (Feb 2026): DOM pruning reduces token count by 97.9%. A 0.6B model with pruning achieved F1 88.1% for extraction — comparable to models 10× its size. (Cited in session context, not independently verified.)
- **Crawl4AI** (unclecode, 62k+ stars): Free, local parallel crawler, clean markdown output, JS rendering. Dominant open alternative to Firecrawl. No API key needed.
- **Trafilatura** (15k+ stars): CLI + Python lib for web page to clean text/markdown. Lighter than Crawl4AI, no JS rendering.
- **Jina AI Reader**: Free tier, prefix `r.jina.ai` before any URL to get LLM-ready markdown.
- **open-graph-scraper** (npm): JS library that extracts OG + Twitter + standard meta in one call.
- **extruct** (Python): Extracts JSON-LD + microdata + RDFa in one call.
- **ScrapeGraphAI**: 1 credit = 1 API call regardless of feature. Competitor to Firecrawl with simpler pricing.
