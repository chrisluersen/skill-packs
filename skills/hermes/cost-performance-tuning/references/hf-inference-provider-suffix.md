# HF Inference Router — Provider Suffix Pattern

## The `:provider` Suffix

HuggingFace's Inference Router (`https://router.huggingface.co/v1`) supports multiple
inference providers (Zai, Groq, Novita, Cerebras, SambaNova, Together, Fireworks, etc.).
To route a request to a **specific provider**, append `:provider-name` to the model ID:

```
zai-org/GLM-5.2:zai-org        → routes through Zai's inference servers
zai-org/GLM-5.2                 → may fail or route to default HF Inference API
```

The suffix format is `<org>/<model>:<inference-provider>`. The provider name matches
the `inference_provider` field on the HF model page (e.g., `zai-org`, `groq`, `novita`).

## When the Suffix Matters

| Situation | Without suffix | With suffix |
|-----------|---------------|-------------|
| Model served by only one provider | May work (auto-routes) | Explicit, reliable |
| Model served by multiple providers | Routes to default/cheapest | Routes to desired provider |
| Free promotional windows | May not qualify | Required — promo is provider-specific |
| Provider-specific rate limits | Hits default limits | Hits chosen provider's limits |

## Free Promotional Windows

Providers like Z.ai occasionally announce time-limited free access to their models via
HF Inference Providers. These are announced on social media (X/Twitter) and are
**provider-suffix-gated** — the free tier only applies when routing through that
provider's suffix.

Example (2026-06-18): Z.ai announced 5 hours of free GLM-5.2 via HF Inference Providers.
The free access required `zai-org/GLM-5.2:zai-org` as the model name.

### Detecting free windows

- Follow the model publisher on X/Twitter (e.g., @Zai_org)
- Check the HF model page for pricing/provider info:
  `https://huggingface.co/<org>/<model>?inference_provider=<provider>`
- After the window expires, requests either fail (if the provider removed free access)
  or start billing against your HF account at the provider's normal rate

## Configuring in Hermes

```bash
# Set the model WITH the provider suffix
hermes config set model.default "zai-org/GLM-5.2:zai-org"
hermes config set model.provider "custom:hf-inference"

# The provider config (already set if hf-inference exists):
# providers:
#   hf-inference:
#     base_url: https://router.huggingface.co/v1

# Auth via HF_TOKEN env var
hermes config set model.api_key '${HF_TOKEN}'
```

The suffix is part of the model name string — Hermes passes it through to the HF
router as-is. No special config key needed.

## Verifying the Suffix Works

```bash
source "$HOME/AppData/Local/hermes/.env" 2>/dev/null
curl -s -w "\nHTTP:%{http_code}" \
  -H "Authorization: Bearer $HF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"zai-org/GLM-5.2:zai-org","messages":[{"role":"user","content":"hi"}],"max_tokens":10}' \
  https://router.huggingface.co/v1/chat/completions
```

- **HTTP 200** → suffix is correct, provider is serving the model
- **HTTP 401** → token invalid, or provider doesn't serve this model (check suffix spelling)
- **HTTP 404** → model or provider not found on the router

## Available Providers (as of 2026-06)

Check `https://huggingface.co/models?other=inference_provider` for the live list.
Common suffixes: `:zai-org`, `:groq`, `:novita`, `:cerebras`, `:sambanova`,
`:together`, `:fireworks-ai`, `:featherless-ai`, `:hyperbolic`, `:deepinfra`,
`:replicate`, `:cohere`, `:scaleway`, `:hf-inference` (the default HF API).
