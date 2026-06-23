# MEMORY.md - Long-Term Memory

## Key Facts
- Al (Alan) is my human. America/Chicago timezone. Prefers casual, dry wit, no corporate pleasantries.
- I'm Alfred. First session: 2026-02-13.
- Git backup: github.com/alanheinen/openclaw-alfred (daily 2 AM America/Chicago)

## Budget / Cost Posture 💰
- **Historical Anthropic funding:** $125.08 across 5 deposits (Feb 13 – Mar 26).
- **Anthropic manual balance:** Was down to roughly ~$9 by Mar 29; treat Claude usage as backup-only unless topped up.
- **Primary routing (since Mar 30):** Main session and new work default to `openai-codex/gpt-5.4` via ChatGPT/OpenAI Codex OAuth (`openai-codex:default`), not paid API-key routing.
- **Fallbacks:** `openai-codex/gpt-5.2` only. (`openai-codex/gpt-4o` was previously listed but recent cron failures showed it as unrecognized / not a valid live fallback.)
- **Cost implication:** Ongoing usage should be materially cheaper and more predictable than the old API-key-first setup.
- **Tracking:** `memory/budget.md`

## Infrastructure
- **Cron posture (updated Mar 30):** Removed `daily-usage-report` and obsolete `ntfy-alert-monitor`; rebuilt cron jobs around OpenAI-first defaults and staggered enabled jobs so they do not collide in the same local hour.
- **Cron logging:** Shared helper script at `workspace/scripts/log_cron_job.sh` writes apache-like START/END/ERROR entries to `~/.openclaw/logs/cron-jobs.log`.
- **Backups:** Daily git backup now stores a **redacted** OpenClaw config snapshot via `scripts/redact_openclaw_config.py` -> `backups/openclaw.json`, not a raw secret-bearing copy.
- **Secret hygiene follow-up (Apr 2):** Treat lingering local `openclaw.json` / `.bak` copies, live `auth-profiles.json`, and the PBS token exposed in `k8s-2025/docs/ansible-pbs-quick-reference.md` as unresolved cleanup/rotation items.
- **ntfy-alert-listener:** systemd daemon on clawdbot.lan — streams ntfy alerts, 2-min flap filter, auto-restarts Frigate VM 105 (10-min cooldown), auto-files RCAs. Source committed to k8s-2025/alfred/.
- **SSH access:** OPNsense (root@172.16.1.1) and vm01.lan (aheinen@172.16.1.141) — read-only, exception for Frigate VM 105 restart.
- **Frigate OOM pattern:** Recurring kills through Mar 27. Auto-restart deployed. vm01 drive replacement started Mar 27 and may reduce the I/O pressure behind the issue; monitor for recurrence.
- **Security / repo cleanup (Mar 31):** Git remotes for `k8s-2025`, `openclaw-alfred`, and `siloed-quant-repo` now use GitHub SSH; exposed PAT revoked; tracked repo secrets scrubbed; recovery steps documented in `docs/SECRET_RECOVERY.md`.
- **Daily ops expectations (since Mar 31, updated Apr 9):** Daily review should check Telegram delivery health, run lightweight secret scans, and keep recurring network-inventory delta reports healthy. The former daily `k8s-2025` reorg-planning cron is now disabled because that planning work is effectively complete.
- **k8s-2025 reorg + docs remediation (Apr 1-5):** Draft assessment/proposal/transition-plan/naming-convention docs under `plans/` matured from greenfield redesign into validation of a repo that had already been substantially reorganized. On Apr 5 that work turned into an approved execution pass: seven commits landed on `main`, broken Markdown links dropped from 19 to 0, Ansible/docs flow was clarified, directory indexes and a service map were added, recovery docs were reframed as honest runbooks, and archive/history material was labeled more clearly. The old “remaining work is mostly README/doc placement” note is now stale; the current residual cleanup is narrower: an actual Terraform target mismatch in `scripts/deploy-homeassistant-pxe.sh`, several stale Terraform target references in docs/README content, and the fact that live `ansible-playbook` / `terraform` validation was not available in the review environment.
- **Network inventory watch (Apr 2-3):** Recent delta scans surfaced `Legion.lan` / `172.16.1.16` as a likely new or untracked workstation (or transient client) and repeatedly noted that `k8s6.lan` / `172.16.1.206` is pingable but not answering TCP/22, despite being listed as a Kubernetes worker expected to expose SSH.
- **OpenClaw memory search repair (Apr 23):** `memory_search` on clawdbot.lan had silently broken because embeddings auto-selected Bedrock without a working AWS credential chain. Switched embeddings to the local provider, let the local model download, forced a full reindex, and verified semantic memory search was healthy again.
- **OpenClaw TUI watchdog regression (Apr 23):** The `streaming watchdog: no stream updates for 30s` warning appears to be a TUI-side bug. It likely refreshes only on visible chat deltas instead of any active-run progress signal (tool events, lifecycle events, quiet deltas). Preferred first move is update/restart OpenClaw before carrying a local patch.
- **dsp01 kiosk monitor fix (Apr 23):** Fixed PIR/X11 monitor state detection in the live script and in `k8s-2025/ansible/roles/dsp01/files/monitor_control.py`; committed in `k8s-2025` as `2edacd9` (`Fix dsp01 PIR monitor state detection on X11`).

## Quant Backtest (siloed-quant-repo)
- **Rotation strategy:** Weekly MA150 inflation guard, 1994–present. ~12.39% CAGR / 0.73 Sharpe / -55.2% MaxDD / +187 bps over SPY. Publication-ready paper: STRATEGY_PAPER.md (enhanced Mar 28 with updated metrics + ASCII decision flowchart).
- **Short-term strategy:** Research track was tightened substantially on Mar 31 with a stricter long/cash state-machine backtest (explicit entry/exit, minimum holds, daily return accounting, 5 bps/side costs, walk-forward validation). On Apr 3 the walk-forward was made honest: real rolling 5-year train / next-year test instead of picking the full-sample winner first. That stricter validation made the short-term track look weaker, not stronger.
- **Best current short-term candidate (Apr 3):** `pullback_trend_reentry` remains the top in-sample rule at roughly 4.40% CAGR / 0.68 Sharpe since 2010, but honest rolling OOS results are only about 2.4% CAGR / 0.56 Sharpe versus SPY around 14.5% CAGR / 1.15 Sharpe. Useful correction, not a usable edge yet.
- **Priority:** Al wants quant effort focused primarily on short-term strategy research now, while “new business” explores fresh strategy ideas.
- **Daily crons:** backtest at 2 AM EST, team meeting at 8 AM EDT.

## Memory Housekeeping
- Daily logs in `memory/YYYY-MM-DD.md`. Reviewed/distilled into this file periodically. Purge at 30 days.
- Review status (as of 2026-06-23): newest daily logs reviewed are `2026-06-22`, `2026-06-21`, and `2026-06-20`; those re-checks added no new durable project, infrastructure, or quant facts beyond the Apr 23 items already captured above.
- Older-than-7-days status: remaining dated logs through `2026-06-15` have already been reviewed/distilled or are themselves memory-review summaries. There is no `2026-06-03.md` file on disk, and the older dated range still does not appear to be hiding any neglected durable facts.
- Purge status: `memory/2026-05-23.md` was re-checked and deleted on 2026-06-23 because it was older than 30 days and already fully distilled; `memory/2026-05-24.md` is now the oldest remaining dated file on disk.
- Other tracking: `memory/budget.md`, `memory/error-log.md`, `memory/k8s-2025-overview.md`
