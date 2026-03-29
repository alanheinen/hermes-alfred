# MEMORY.md - Long-Term Memory

## Key Facts
- Al (Alan) is my human. CDT timezone. Prefers casual, dry wit, no corporate pleasantries.
- I'm Alfred. First session: 2026-02-13.
- Git backup: github.com/alanheinen/openclaw-alfred (daily 2 AM CST)

## Budget 💰
- **Total funded:** $125.08 across 5 deposits (Feb 13 – Mar 26)
- **Balance:** ~$12 (Mar 28 est). Warning at $5, critical at $2.
- **Burn rate:** ~$0.50-15/day. Quiet cron-only days ~$0.50. Active Opus investigation days can hit $10-15.
- **Tracking:** `memory/budget.md`

## Infrastructure
- **Crons (6):** git-backup, memory-review, daily-review, usage-report, quant-backtest-daily, quant-meeting-daily — all Sonnet, no fallbacks
- **ntfy-alert-listener:** systemd daemon on clawdbot.lan — streams ntfy alerts, flap filter, auto-restarts Frigate VM 105, auto-files RCAs. Source committed to k8s-2025/alfred/.
- **SSH access:** OPNsense (root@172.16.1.1) and vm01.lan (aheinen@172.16.1.141) — read-only, exception for Frigate VM 105 restart
- **Frigate:** Recurring OOM kills (~6 in 12 days through Mar 27). Auto-restart daemon deployed. **vm01 drive replacement** started Mar 27 evening — failing drive may have been causing I/O pressure contributing to OOM issues. Monitoring for improvement.
- **Report delivery:** Switched to announce mode Mar 27 after delivery failures.

## Quant Backtest (siloed-quant-repo)
- **Rotation strategy:** Weekly MA150 inflation guard, 1994–present. ~12.5% CAGR / 0.74 Sharpe / -55.2% MaxDD. Publication-ready paper: STRATEGY_PAPER.md.
- **Short-term strategy:** Phase 3 complete Mar 27 — REJECTED as standalone (7% vs SPY 14% in walk-forward). Potential tactical overlay only.
- **Daily crons:** backtest at 2 AM EST, team meeting at 8 AM EDT.

## Memory Housekeeping
- Daily logs in `memory/YYYY-MM-DD.md`. Reviewed/distilled into this file periodically. Purge at 30 days.
- Other tracking: `memory/budget.md`, `memory/error-log.md`, `memory/k8s-2025-overview.md`

## Recent Updates
- **Mar 27:** vm01 drive replacement started (may resolve Frigate OOM issues). Token optimization: 59% context reduction. ntfy-listener now auto-files RCAs for flap-filtered events. Listener source committed to k8s-2025/alfred/. Report delivery fully fixed (announce mode).
- **Mar 26:** Built ntfy-alert-listener systemd daemon with auto-restart, flap filtering, Telegram alerts. Investigated 3 outages, filed RCAs. Granted SSH access to OPNsense + vm01.lan. Budget corrected to $14.37.
- **Mar 20-23:** Quant STRATEGY_PAPER.md published (MA150 rotation, 12.5% CAGR). Locked all crons to Sonnet. Short-term strategy Phase 3 completed and rejected (underperformed SPY in walk-forward).
