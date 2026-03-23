# API Budget Tracker

## Balance
- Starting balance: $25.08 (2026-02-13)
- Top-up: $25.00 (2026-02-26)
- Top-up: $25.00 (2026-03-20)
- Top-up: $25.00 (2026-03-21)
- Current reported Anthropic balance: $34.28 (2026-03-22 10:27 EDT)
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
| 2026-03-21 | $12.91 | 🔴 Heaviest day yet — Opus $10.90, Sonnet $2.00 |
| 2026-03-22 | $1.39+ | (so far, 9 AM) Sonnet $1.00, Opus $0.39 |

## Status (2026-03-22)

**Last known Anthropic balance:** $37.08 (Mar 21, post $25 top-up)
**Estimated spend since:** ~$14.30 (Mar 21 $12.91 + Mar 22 $1.39 so far)
**Estimated current balance:** ~$22.78
**Warning threshold:** $5.00

**Burn rates:**
- Quiet days (Mar 14-18): ~$0.37/day → months of runway
- 7-day average (Mar 16-22): $2.36/day → ~10 day runway
- Heavy days (Mar 21): $12.91/day → 1-2 days 🔴
- All-time average (38 days): ~$1.88/day

**Cost drivers:**
- Mar 21 was the single most expensive day. Opus main session burned $10.90 alone.
- This daily-usage-report cron still runs on Opus — should be Sonnet.
- Sonnet crons are cheap (~$0.08-0.20/run)
- Opus cache writes are the silent killer ($18.75/M tokens)

**Recommendations:**
1. **Switch this daily-usage-report cron to Sonnet** (still on Opus ⚠️)
2. Keep main session on Sonnet unless complex reasoning needed
3. Mar 21 spike needs investigation — was there an unusually long Opus session?
4. At 7-day avg ($2.36/day), balance lasts ~10 days before warning threshold
