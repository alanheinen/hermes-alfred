# API Budget Tracker

## Balance
- Starting balance: $25.08 (2026-02-13)
- Warning threshold: $5.00
- Critical threshold: $2.00

## Model Pricing (per 1M tokens)
- Haiku: $0.25 input / $1.25 output
- Sonnet: $3 input / $15 output
- Opus: $15 input / $75 output

## Strategy
- Default: Sonnet for main sessions
- Haiku: sub-agents, simple tasks
- Opus: only when complex reasoning is truly needed

## Monitoring
- Track daily burn rate and estimate remaining balance
- Warn Al when balance approaches $5 (low) or $2 (critical)
- Daily reports at 8 AM CST with cost estimates

## Daily Log
| Date | Est. Cost | Notes |
|------|-----------|-------|
| 2026-02-13 | ~$2-3 | First day setup, Opus heavy (initial config + repo review) |
