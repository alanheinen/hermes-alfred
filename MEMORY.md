# MEMORY.md - Long-Term Memory

## Key Facts
- Al (Alan) is my human. CDT timezone. Prefers casual, dry wit, no corporate pleasantries.
- I'm Alfred. First session: 2026-02-13.
- Git backup: github.com/alanheinen/openclaw-alfred (daily 2 AM CST)

## Budget 💰
- **Total funded:** $125.08 across 5 deposits (Feb 13 – Mar 26)
- **Balance:** ~$9 (Mar 29 est). Warning at $5, critical at $2. 🔴 **Critically low** — ~1 day to warning at avg burn.
- **Burn rate:** ~$0.50-15/day. Quiet cron-only days ~$0.50. Active Opus investigation days can hit $10-15. 7-day avg: ~$4.28/day.
- **Status:** All 6 crons confirmed on Sonnet (no Opus fallbacks). One active Opus session will breach $5 warning. Top-up recommended.
- **Tracking:** `memory/budget.md`

## Infrastructure
- **Crons (6):** git-backup, memory-review, daily-review, usage-report, quant-backtest-daily, quant-meeting-daily — all Sonnet, no fallbacks (verified Mar 26)
- **ntfy-alert-listener:** systemd daemon on clawdbot.lan — streams ntfy alerts, 2-min flap filter, auto-restarts Frigate VM 105 (10-min cooldown), auto-files RCAs. Source committed to k8s-2025/alfred/.
- **SSH access:** OPNsense (root@172.16.1.1) and vm01.lan (aheinen@172.16.1.141) — read-only, exception for Frigate VM 105 restart
- **Frigate OOM pattern:** Recurring kills (~6 in 12 days through Mar 27). Auto-restart deployed. **vm01 drive replacement** started Mar 27 — failing drive may have caused I/O pressure. Monitoring for improvement post-replacement.
- **Report delivery:** Switched to announce mode Mar 27 after delivery failures.

## Quant Backtest (siloed-quant-repo)
- **Rotation strategy:** Weekly MA150 inflation guard, 1994–present. ~12.39% CAGR / 0.73 Sharpe / -55.2% MaxDD / +187 bps over SPY. Publication-ready paper: STRATEGY_PAPER.md (enhanced Mar 28 with updated metrics + ASCII decision flowchart).
- **Short-term strategy:** Framework ready (short_term_strategy.py). Signals implemented (momentum, RSI, BB, ATR, vol, gaps). Research phase — 5-7 sessions to publishable. Phase 3 walk-forward: 12.16% CAGR / 1.00 Sharpe OOS.
- **Daily crons:** backtest at 2 AM EST, team meeting at 8 AM EDT.

## Memory Housekeeping
- Daily logs in `memory/YYYY-MM-DD.md`. Reviewed/distilled into this file periodically. Purge at 30 days.
- Other tracking: `memory/budget.md`, `memory/error-log.md`, `memory/k8s-2025-overview.md`

## Recent Updates
- **Mar 26-28:** Infrastructure monitoring week — deployed ntfy-alert-listener daemon (systemd, auto-restart, flap filtering), investigated Frigate OOM pattern (4th+ incident), auto-restart logic with 10-min cooldown, granted SSH access (OPNsense + vm01, read-only + Frigate restart exception), filed multiple RCAs. vm01 drive replacement started Mar 27 (may reduce OOM pressure). k8s-2025 repo divergence: 21 local vs 13 remote — needs merge. Token optimization: 59% context reduction. Quant strategy paper publication-ready (12.39% CAGR, 0.73 Sharpe, +187 bps over SPY). Budget thin (~$12-14).
