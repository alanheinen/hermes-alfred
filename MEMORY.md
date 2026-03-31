# MEMORY.md - Long-Term Memory

## Key Facts
- Al (Alan) is my human. CDT timezone. Prefers casual, dry wit, no corporate pleasantries.
- I'm Alfred. First session: 2026-02-13.
- Git backup: github.com/alanheinen/openclaw-alfred (daily 2 AM CST)

## Budget / Cost Posture 💰
- **Historical Anthropic funding:** $125.08 across 5 deposits (Feb 13 – Mar 26).
- **Anthropic manual balance:** Was down to roughly ~$9 by Mar 29; treat Claude usage as backup-only unless topped up.
- **Primary routing (since Mar 30):** Main session and new work default to `openai-codex/gpt-5.4` via ChatGPT/OpenAI Codex OAuth (`openai-codex:default`), not paid API-key routing.
- **Fallbacks:** `openai-codex/gpt-4o`, `openai-codex/gpt-5.2`, then Claude via `anthropic:manual` only as backup.
- **Cost implication:** Ongoing usage should be materially cheaper and more predictable than the old API-key-first setup.
- **Tracking:** `memory/budget.md`

## Infrastructure
- **Cron posture (updated Mar 30):** Removed `daily-usage-report` and obsolete `ntfy-alert-monitor`; rebuilt cron jobs around OpenAI-first defaults and staggered enabled jobs so they do not collide in the same local hour.
- **Cron logging:** Shared helper script at `workspace/scripts/log_cron_job.sh` writes apache-like START/END/ERROR entries to `~/.openclaw/logs/cron-jobs.log`.
- **Backups:** Daily git backup also copies live OpenClaw config from `~/.openclaw/openclaw.json` to `backups/openclaw.json` in the workspace repo.
- **ntfy-alert-listener:** systemd daemon on clawdbot.lan — streams ntfy alerts, 2-min flap filter, auto-restarts Frigate VM 105 (10-min cooldown), auto-files RCAs. Source committed to k8s-2025/alfred/.
- **SSH access:** OPNsense (root@172.16.1.1) and vm01.lan (aheinen@172.16.1.141) — read-only, exception for Frigate VM 105 restart.
- **Frigate OOM pattern:** Recurring kills through Mar 27. Auto-restart deployed. vm01 drive replacement started Mar 27 and may reduce the I/O pressure behind the issue; monitor for recurrence.
- **Report delivery:** Switched to announce mode Mar 27 after delivery failures.

## Quant Backtest (siloed-quant-repo)
- **Rotation strategy:** Weekly MA150 inflation guard, 1994–present. ~12.39% CAGR / 0.73 Sharpe / -55.2% MaxDD / +187 bps over SPY. Publication-ready paper: STRATEGY_PAPER.md (enhanced Mar 28 with updated metrics + ASCII decision flowchart).
- **Short-term strategy:** Framework ready (short_term_strategy.py). Signals implemented (momentum, RSI, BB, ATR, vol, gaps). Research phase — 5-7 sessions to publishable. Phase 3 walk-forward: 12.16% CAGR / 1.00 Sharpe OOS.
- **Daily crons:** backtest at 2 AM EST, team meeting at 8 AM EDT.

## Memory Housekeeping
- Daily logs in `memory/YYYY-MM-DD.md`. Reviewed/distilled into this file periodically. Purge at 30 days.
- Other tracking: `memory/budget.md`, `memory/error-log.md`, `memory/k8s-2025-overview.md`

## Recent Updates
- **Mar 30:** Model/auth cleanup finished. Main session now runs on `openai-codex/gpt-5.4` via OAuth (`openai-codex:default`) instead of API-key routing. Removed Anthropic API-key route, removed lingering `OPENAI_API_KEY` env injection, confirmed subscription-backed usage windows visible in model/session tooling. Cron set cleaned up, logging helper added, and backup now snapshots live `openclaw.json`.
- **Mar 26-28:** Infrastructure monitoring week — deployed ntfy-alert-listener daemon (systemd, auto-restart, flap filtering), investigated Frigate OOM pattern (4th+ incident), auto-restart logic with 10-min cooldown, granted SSH access (OPNsense + vm01, read-only + Frigate restart exception), filed multiple RCAs. vm01 drive replacement started Mar 27 (may reduce OOM pressure). k8s-2025 repo divergence: 21 local vs 13 remote — needs merge. Token optimization: 59% context reduction. Quant strategy paper publication-ready (12.39% CAGR, 0.73 Sharpe, +187 bps over SPY).
