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
| 2026-02-27 | ~$0.25 | 3 crons (Sonnet ~$0.05) + main session: budget report, k8s repo search (Opus ~$0.20) |
| 2026-02-28 | ~$0.10 | Crons (Sonnet) + main session memory resume (Opus) |
| 2026-03-01 | ~$0.10 | 3 crons (Sonnet) + main usage report (Opus). |
| 2026-03-02 | ~$0.15 | Daily report cron (Opus). Low activity. |
| 2026-03-03 | ~$0.15+ | Daily report cron (Opus). Day in progress. |
| 2026-03-04 | ~$0.20+ | Daily report cron + Al resumed daily logging (Opus). Crons (Sonnet). |
| 2026-03-05 | ~$1.15 | Main session heavy (PAT fix, GitHub repo setup, cron updates). Quant crons confirmed on Sonnet. |
| 2026-03-06 | ~$0.20 | Crons (Sonnet) + light main session. Normal day. |
| 2026-03-07 | ~$0.15 | 5 crons (Sonnet) + usage report (Opus). Quiet day. |
| 2026-03-08 | ~$0.40 | 5 crons (Sonnet ~$0.09) + main session security audit & config work (Opus ~$0.30). Heavier day. |
| 2026-03-09 | ~$0.10+ | 4 crons (Sonnet ~$0.08) + usage report (Opus ~$0.02). Day in progress. |

## Status (2026-03-09)
✅ Model tiering active: crons → Sonnet, main → Opus
✅ Fallback chain trimmed to frontier-only (Sonnet → GPT-5.4 → GPT-5.2 → GPT-5)
✅ Security audit clean: 0 critical findings
Estimated balance: ~$23-29 remaining
Burn rate (Mar 8): ~$0.40 (elevated — security audit session)
Burn rate (Mar 9 so far): ~$0.10
Expected burn rate going forward: ~$0.15-0.30/day
Runway: 3-5+ months at normal rate
