# API Budget Tracker

## Balance
- Starting balance: $25.08 (2026-02-13)
- Top-up: $25.00 (2026-02-26)
- Top-up: $25.00 (2026-03-20)
- Top-up: $25.00 (2026-03-21)
- Current reported Anthropic balance: $37.08 (2026-03-21)
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

## Daily Log (from transcript usage data)
| Date | Actual Cost | Notes |
|------|------------|-------|
| 2026-02-13 | $2.97 | First day setup, Opus heavy |
| 2026-02-14 | $9.80 | 3 cron jobs + main + group chats, ALL on Opus ⚠️ |
| 2026-02-15 | $2.34 | Opus everywhere |
| 2026-02-24 | $0.76 | |
| 2026-02-25 | $1.12 | Switched 6 sessions to Sonnet |
| 2026-02-26 | $1.13 | |
| 2026-02-27 | $1.47 | |
| 2026-02-28 | $1.42 | |
| 2026-03-01 | $1.04 | |
| 2026-03-02 | $0.76 | |
| 2026-03-03 | $0.38 | |
| 2026-03-04 | $0.71 | |
| 2026-03-05 | $4.96 | PAT fix, GitHub, cron updates — heavy main session |
| 2026-03-06 | $3.19 | |
| 2026-03-07 | $1.99 | |
| 2026-03-08 | $0.68 | Security audit |
| 2026-03-09 | $4.75 | |
| 2026-03-10 | $2.98 | |
| 2026-03-11 | $2.75 | |
| 2026-03-12 | $0.93 | |
| 2026-03-13 | $0.82 | |
| 2026-03-14 | $0.55 | |
| 2026-03-15 | $0.39 | |
| 2026-03-16 | $0.64 | |
| 2026-03-17 | $0.02 | |
| 2026-03-18 | $0.25 | |
| 2026-03-19 | — | No activity recorded |
| 2026-03-20 | $1.34 | Memory review, quant cron, admin cleanup, credits top-up |
| 2026-03-21 | $8.60+ | ⚠️ Heavy day — main session Opus ($5.89), quant Sonnet ($1.51), this report ($0.66+) |

## Status (2026-03-21)

⚠️ **Previous estimates were wildly low.** Switched to actual transcript-derived costs.

**Reported Anthropic balance:** $23.82 (Mar 20, post $25 top-up)
**Estimated spend since:** ~$9.94 (Mar 20 + Mar 21 so far)
**Estimated current balance:** ~$13.88
**Warning threshold:** $5.00

**Burn rates:**
- Quiet days (Mar 14-18): ~$0.37/day → 37 day runway
- 7-day average (Mar 14-21): ~$1.68/day → 8 day runway ⚠️
- Heavy days (today, Mar 5/9): $5-9/day → 1-2 days 🔴
- All-time average (36 days): ~$1.63/day

**Cost drivers:**
- Main session on Opus is the #1 cost. Growing context + $15/$75 per M tokens.
- Crons on Sonnet are cheap (~$0.08-0.15/run)
- This usage report cron runs on Opus — should be Sonnet.
- Cache writes on Opus are expensive ($18.75/M tokens)

**Recommendations:**
1. Switch this daily-usage-report cron to Sonnet (it's currently Opus ⚠️)
2. Consider switching main session to Sonnet for routine work
3. Heavy interactive sessions can spike to $5-9/day on Opus
4. At current trajectory, balance could hit warning threshold in ~5-8 days
