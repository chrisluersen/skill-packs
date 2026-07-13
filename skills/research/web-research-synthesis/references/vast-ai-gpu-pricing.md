# Vast.ai GPU Pricing Reference

Live market rates (updated 2026-07-02). Source: [vast.ai/pricing](https://vast.ai/pricing) via Jina AI reader.

## Flagship

| GPU | VRAM | Price/hr | Availability |
|-----|------|----------|-------------|
| B300 Blackwell Ultra | 288 GB | **$6.69** | Low |
| B200 Blackwell | 192 GB | **$4.95** | Med |
| H200 Hopper | 141 GB | **$3.82** | High |
| H200 NVL Hopper | 141 GB | **$3.07** | Low |
| H100 SXM Hopper | 80 GB | **$2.00** | Med |
| H100 NVL Hopper | 94 GB | **$1.99** | Low |
| RTX PRO 6000 S Blackwell | 96 GB | **$1.27** | Med |

## Flagship Consumer

| GPU | VRAM | Price/hr | Availability |
|-----|------|----------|-------------|
| RTX PRO 6000 WS Blackwell | 96 GB | **$1.07** | Med |
| RTX 5090 Blackwell | 32 GB | **$0.41** | High |
| RTX 4090 Ada Lovelace | 24 GB | **$0.35** | High |

## Blackwell

| GPU | VRAM | Price/hr | Availability |
|-----|------|----------|-------------|
| RTX 5080 | 16 GB | **$0.21** | Low |
| RTX PRO 4000 | 24 GB | **$0.21** | Low |
| RTX 5070 TI | 16 GB | **$0.14** | Med |
| RTX 5070 | 12 GB | **$0.13** | Med |
| RTX 5060 TI | 16 GB | **$0.09** | High |
| RTX 5060 | 8 GB | **$0.08** | Low |

## Ada Lovelace

| GPU | VRAM | Price/hr | Availability |
|-----|------|----------|-------------|
| L40S | 48 GB | **$0.47** | Low |
| L4 | 24 GB | **$0.31** | Low |
| RTX 4080S | 16 GB | **$0.21** | Low |
| RTX 4080 | 16 GB | **$0.19** | Low |
| RTX 4070S TI | 16 GB | **$0.13** | Low |
| RTX 4070S | 12 GB | **$0.12** | Low |
| RTX 4070 | 12 GB | **$0.10** | Low |
| RTX 4070 TI | 12 GB | **$0.09** | Med |
| RTX 4060 TI | 8 GB | **$0.09** | Med |
| RTX 4060 | 8 GB | **$0.06** | Low |

## Ampere (relevant)

| GPU | VRAM | Price/hr | Availability |
|-----|------|----------|-------------|
| A100 SXM4 | 80 GB | **$0.77** | Med |
| A100 PCIE | 80 GB | **$0.51** | Med |
| RTX A6000 | 48 GB | **$0.39** | Low |
| A40 | 48 GB | **$0.29** | Low |
| A10 | 24 GB | **$0.20** | Low |
| RTX A5000 | 24 GB | **$0.20** | Med |
| RTX 3090 TI | 24 GB | **$0.17** | Low |
| RTX 3090 | 24 GB | **$0.13** | High |
| RTX 3080 TI | 12 GB | **$0.11** | Low |
| RTX 3080 | 10 GB | **$0.09** | Low |
| RTX A4000 | 16 GB | **$0.09** | Med |
| RTX A2000 | 12 GB | **$0.03** | Low |

## Comparison: Vast.ai vs RunPod (consumer GPUs)

| GPU | VRAM | Vast.ai | RunPod | Vast advantage |
|-----|------|---------|--------|----------------|
| RTX 3080 Ti | 12 GB | $0.11 | $1.20 | **10.9×** |
| RTX 3090 | 24 GB | $0.13 | $1.80 | **13.8×** |
| RTX 4090 | 24 GB | $0.35 | $1.95 | **5.6×** |
| RTX A6000 | 48 GB | $0.39 | $2.25 | **5.8×** |
| A100 SXM4 | 80 GB | $0.77 | $2.70 | **3.5×** |
| H100 SXM | 80 GB | $2.00 | $3.50 | **1.75×** |

## Notes

- Vast.ai is a **marketplace** — prices fluctuate with supply/demand. Host quality varies.
- Three pricing tiers: **On-Demand** (guaranteed, per-second), **Interruptible** (~50% cheaper, preemptible), **Reserved** (1/3/6 month terms, up to 50% off).
- Consumer GPUs are 5–14× cheaper than RunPod. Datacenter GPUs (A100/H100) are 1.75–3.5× cheaper.
- DeepSeek-V4-Flash (113B params): 4-bit quant needs ≥12 GB VRAM, FP16 needs ≥24 GB. Best value on Vast: RTX 3090 24GB at $0.13/hr (FP16) or RTX 3080 Ti 12GB at $0.11/hr (4-bit).