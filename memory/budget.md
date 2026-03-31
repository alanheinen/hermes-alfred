# API Budget Tracker

## Balance
- Starting balance: $25.08 (2026-02-13)
- Top-up: $25.00 (2026-02-26)
- Top-up: $25.00 (2026-03-20)
- Top-up: $25.00 (2026-03-21)
- Top-up: $25.00 (2026-03-26)
- Current reported Anthropic balance: $14.37 (2026-03-26 reported by Al)
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
| 2026-03-22 | $1.39 | Sonnet + Opus crons |
| 2026-03-23 | $0.27 | Very quiet — crons only, all Sonnet |
| 2026-03-24 | $1.33 | Quiet day — Opus $0.43, Sonnet $0.90 |
| 2026-03-25 | ~$9.50 | 🟡 Main session Opus context $6.72 + crons ~$2.78 |
| 2026-03-26 | ~$11.50 | Heavy Opus main session — RCA investigation, ntfy listener, infra SSH work |
| 2026-03-27 | ~$2.00 | Moderate — cron fixes, RCA filing, token optimization, listener updates |
| 2026-03-28 | ~$3.00 | Quant meeting (strategy paper enhancement), crons |
| 2026-03-29 | ~$0.50 | Very quiet — no daily log, crons only |
| 2026-03-30 | — | (in progress) |

## Status (2026-03-30 09:00 EDT)

**Anthropic balance:** ~$8.50 (estimated: ~$9 on Mar 29 morning, minus ~$0.50 quiet day)
**Total top-ups to date:** $125.08 ($25.08 initial + 4× $25.00)
**Total spent to date:** ~$116.50

**Burn rates:**
- Mar 29: ~$0.50 (very quiet, crons only)
- Mar 28: ~$3.00 (quant meeting, strategy paper, crons)
- 7-day avg (Mar 24-30): ~$4.04/day
- All-time avg: ~$2.54/day

**Runway (from ~$8.50):**
- At 7-day avg ($4.04/day): ~0.9 days to warning ($5) ⚠️
- Quiet days (crons only): ~$0.50/day → 7 days to warning
- Active Opus day: hits warning immediately

**🔴 Status:** Balance critically low (~$8.50). One active Opus session will breach the $5 warning threshold. Top-up strongly recommended before any heavy work.

**⚠️ Note:** This daily-usage-report cron is running on Opus ($15/$75 per 1M tokens). Should be Sonnet. Al should override it.
