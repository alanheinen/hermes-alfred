# API Budget Tracker

## Balance
- Starting balance: $25.08 (2026-02-13)
- Top-up: $25.00 (2026-02-26)
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
| 2026-02-15 to 02-24 | ~$1-2/day | Low activity — group chats idle, only git-backup cron daily. All Opus. |
| 2026-02-25 | ~$0.50-1 | Switched 6 sessions to Sonnet. Only main stays Opus. |
| 2026-02-26 | ~$0.20 | 4 cron jobs (Sonnet ~$0.05) + main session budget report & commit (Opus ~$0.15) |
| 2026-02-27 | ~$0.05 so far | 3 overnight crons (Sonnet ~$0.05). Main: this report (Opus). |

## Status (2026-02-26)
✅ Model tiering active: 6 sessions → Sonnet, main → Opus
Estimated balance: ~$30.50-37.50 remaining (after $25 top-up)
Burn rate (Feb 25-26): ~$0.50/day (4 cron jobs on Sonnet + minimal main usage)
Runway: 1-3+ weeks at current rate
