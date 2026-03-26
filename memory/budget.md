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
| 2026-03-22 | $1.39 | Sonnet + Opus crons |
| 2026-03-23 | $0.27 | Very quiet — crons only, all Sonnet |
| 2026-03-24 | $1.33 | Quiet day — Opus $0.43, Sonnet $0.90 |
| 2026-03-25 | $7.82+ | 🟡 (9 AM) Main session Opus context = $6.72, crons $1.10 |

## Status (2026-03-25)

**Last known Anthropic balance:** $34.28 (Mar 22, 10:27 EDT)
**Estimated spend since:** ~$13.19 (Mar 22 post-check $4.04 + Mar 23 ~$0.27 + Mar 24 $1.33 + Mar 25 $7.82 so far)
**Estimated current balance:** ~$21.09
**Warning threshold:** $5.00

**Burn rates:**
- Last 3 days (Mar 23-25): ~$3.12/day ← Mar 25 spike pulling this up
- 7-day average (Mar 19-25): ~$1.59/day
- All-time average (41 days): ~$1.82/day

**⚠️ Concern: Main session Opus context bloat**
- Main session (c34a0c44) has grown to 164k tokens
- Each turn costs ~$1.03 just in cache writes at Opus rates
- Today's $6.72 for main session alone is unsustainable
- **Recommendation:** Switch main session to Sonnet, or trigger compaction/rotation
- This usage-report cron still runs on Opus ($0.38 today) — should be Sonnet

**Runway:**
- At current 7-day rate ($1.59/day): ~13 days
- If main session stays on Opus at this pace: could burn through balance in <7 days
