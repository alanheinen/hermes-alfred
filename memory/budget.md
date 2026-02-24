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
| 2026-02-14 | ~$2-4 | 3 cron jobs + main + 3 group chats, ALL on Opus ⚠️ |

## ⚠️ Issue (2026-02-15)
All 7 sessions are running claude-opus-4-6 — including cron jobs (git backup, memory review, daily-review) and group chats. This directly contradicts the cost strategy. Cron jobs and group chats should be Sonnet or Haiku.

Estimated balance: ~$19-21 remaining (from $25.08 start)
At current Opus-everywhere burn rate: ~$2-4/day → runs out in ~5-10 days
At proper tiered rate (Sonnet default): ~$0.50-1.50/day → lasts 2-4 weeks
