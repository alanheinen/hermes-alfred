# MEMORY.md - Long-Term Memory

## Key Facts
- Al (Alan) is my human. CDT timezone. Prefers casual, dry wit, no corporate pleasantries.
- I'm Alfred. First session: 2026-02-13.
- Git backup: github.com/alanheinen/openclaw-alfred (daily 2 AM CST)

## Budget 💰
- **Total funded:** $125.08 across 5 deposits (Feb 13 – Mar 26)
- **Balance:** ~$19 est. (Mar 27). Warning at $5, critical at $2.
- **Burn rate:** ~$1.50-5/day depending on activity. Cron-only days ~$0.50. Interactive Opus sessions are the main driver.
- **Tracking:** `memory/budget.md`

## Infrastructure
- **Crons (6):** git-backup, memory-review, daily-review, usage-report, quant-backtest-daily, quant-meeting-daily — all Sonnet, no fallbacks
- **ntfy-alert-listener:** systemd daemon on clawdbot.lan — streams ntfy alerts, flap filter, auto-restarts Frigate VM 105, auto-files RCAs. Source in k8s-2025/alfred/.
- **SSH access:** OPNsense (root@172.16.1.1) and vm01.lan (aheinen@172.16.1.141) — read-only, exception for Frigate VM 105 restart
- **Frigate:** Recurring OOM kills (~6 in 12 days as of Mar 27). Auto-restart buys time but root cause (memory overcommit on vm01.lan) unresolved.
- **Report delivery:** Switched to announce mode Mar 27 after delivery failures.

## Quant Backtest (siloed-quant-repo)
- **Rotation strategy:** Weekly MA150 inflation guard, 1994–present. ~12.5% CAGR / 0.74 Sharpe / -55.2% MaxDD. Publication-ready paper: STRATEGY_PAPER.md.
- **Short-term strategy:** Phase 3 complete Mar 27 — REJECTED as standalone (7% vs SPY 14% in walk-forward). Potential tactical overlay only.
- **Daily crons:** backtest at 2 AM EST, team meeting at 8 AM EDT.

## Memory Housekeeping
- Daily logs in `memory/YYYY-MM-DD.md`. Reviewed/distilled into this file periodically. Purge at 30 days.
- Other tracking: `memory/budget.md`, `memory/error-log.md`, `memory/k8s-2025-overview.md`

## Recent Updates
- **Mar 27:** Fixed report delivery (announce mode), added auto-RCA for flap-filtered outages, filed Octopi DNS RCA, committed listener source to k8s-2025/alfred/.
- **Mar 26:** Built ntfy-alert-listener daemon. Investigated 3 outages. Got SSH access to OPNsense + vm01.lan.
- **Mar 20-25:** Quant STRATEGY_PAPER.md published. Short-term trading research Phases 1-2.
- **Mar 16-20:** Extended backtest to 1994, promoted MA150 baseline. Locked crons to Sonnet.
