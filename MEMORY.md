# MEMORY.md - Long-Term Memory

## Key Facts
- Al (Alan) is my human. America/Chicago timezone. Prefers casual, dry wit, no corporate pleasantries.
- I'm Alfred. First session: 2026-02-13.
- Git backup: github.com/alanheinen/openclaw-alfred (daily 2 AM America/Chicago)

## Budget / Cost Posture 💰
- **Historical Anthropic funding:** $125.08 across 5 deposits (Feb 13 – Mar 26).
- **Anthropic manual balance:** Was down to roughly ~$9 by Mar 29; treat Claude usage as backup-only unless topped up.
- **Primary routing (since Mar 30):** Main session and new work default to `openai-codex/gpt-5.4` via ChatGPT/OpenAI Codex OAuth (`openai-codex:default`), not paid API-key routing.
- **Fallbacks:** `openai-codex/gpt-5.2`, then Claude via `anthropic:manual` only as backup. (`openai-codex/gpt-4o` was previously listed but recent cron failures showed it as unrecognized / not a valid live fallback.)
- **Cost implication:** Ongoing usage should be materially cheaper and more predictable than the old API-key-first setup.
- **Tracking:** `memory/budget.md`

## Infrastructure
- **Cron posture (updated Mar 30):** Removed `daily-usage-report` and obsolete `ntfy-alert-monitor`; rebuilt cron jobs around OpenAI-first defaults and staggered enabled jobs so they do not collide in the same local hour.
- **Cron logging:** Shared helper script at `workspace/scripts/log_cron_job.sh` writes apache-like START/END/ERROR entries to `~/.openclaw/logs/cron-jobs.log`.
- **Cron delivery caveat (Apr 2-3):** Several announce-mode Telegram cron jobs can run successfully while delivery confirmation still comes back as `not-delivered` or `unknown`, because they use `delivery.mode = "announce"` without an explicit `delivery.to` target. This is an active config-cleanup item, not a transport outage.
- **Backups:** Daily git backup now stores a **redacted** OpenClaw config snapshot via `scripts/redact_openclaw_config.py` -> `backups/openclaw.json`, not a raw secret-bearing copy.
- **Secret hygiene follow-up (Apr 2):** Treat lingering local `openclaw.json` / `.bak` copies, live `auth-profiles.json`, and the PBS token exposed in `k8s-2025/docs/ansible-pbs-quick-reference.md` as unresolved cleanup/rotation items.
- **ntfy-alert-listener:** systemd daemon on clawdbot.lan — streams ntfy alerts, 2-min flap filter, auto-restarts Frigate VM 105 (10-min cooldown), auto-files RCAs. Source committed to k8s-2025/alfred/.
- **SSH access:** OPNsense (root@172.16.1.1) and vm01.lan (aheinen@172.16.1.141) — read-only, exception for Frigate VM 105 restart.
- **Frigate OOM pattern:** Recurring kills through Mar 27. Auto-restart deployed. vm01 drive replacement started Mar 27 and may reduce the I/O pressure behind the issue; monitor for recurrence.
- **Security / repo cleanup (Mar 31):** Git remotes for `k8s-2025`, `openclaw-alfred`, and `siloed-quant-repo` now use GitHub SSH; exposed PAT revoked; tracked repo secrets scrubbed; recovery steps documented in `docs/SECRET_RECOVERY.md`.
- **Daily ops expectations (since Mar 31):** Daily review should check Telegram delivery health, run lightweight secret scans, and keep recurring `k8s-2025` reorg-planning plus network-inventory delta reports healthy.
- **k8s-2025 reorg planning (Apr 1-4):** Draft assessment/proposal/transition-plan/naming-convention docs live under `plans/`; repo is aligned with `origin/main`; validation confirmed the repo has already been substantially reorganized, so the work shifted from target-design to validating the executed structure and identifying residual cleanup. Active AWX naming cleanup appears to have landed, leaving mostly small placement/documentation calls: final homes for `docs/network-audit-process.md` and `docs/opnsense-dns-dhcp-recommendations.md`, plus refreshing `docs/README.md` and `ansible/playbooks/README.md` to match reality. Pragmatic top-level exceptions like `cloud-init-templates/`, `scripts/`, and `kubernetes/` are likely intentional rather than problems to solve. The proposal is presentation-ready; further cleanup should stay selective rather than becoming a rename hobby.
- **Network inventory watch (Apr 2-3):** Recent delta scans surfaced `Legion.lan` / `172.16.1.16` as a likely new or untracked workstation (or transient client) and repeatedly noted that `k8s6.lan` / `172.16.1.206` is pingable but not answering TCP/22, despite being listed as a Kubernetes worker expected to expose SSH.

## Quant Backtest (siloed-quant-repo)
- **Rotation strategy:** Weekly MA150 inflation guard, 1994–present. ~12.39% CAGR / 0.73 Sharpe / -55.2% MaxDD / +187 bps over SPY. Publication-ready paper: STRATEGY_PAPER.md (enhanced Mar 28 with updated metrics + ASCII decision flowchart).
- **Short-term strategy:** Research track was tightened substantially on Mar 31 with a stricter long/cash state-machine backtest (explicit entry/exit, minimum holds, daily return accounting, 5 bps/side costs, walk-forward validation). On Apr 3 the walk-forward was made honest: real rolling 5-year train / next-year test instead of picking the full-sample winner first. That stricter validation made the short-term track look weaker, not stronger.
- **Best current short-term candidate (Apr 3):** `pullback_trend_reentry` remains the top in-sample rule at roughly 4.40% CAGR / 0.68 Sharpe since 2010, but honest rolling OOS results are only about 2.4% CAGR / 0.56 Sharpe versus SPY around 14.5% CAGR / 1.15 Sharpe. Useful correction, not a usable edge yet.
- **Priority:** Al wants quant effort focused primarily on short-term strategy research now, while “new business” explores fresh strategy ideas.
- **Daily crons:** backtest at 2 AM EST, team meeting at 8 AM EDT.

## Memory Housekeeping
- Daily logs in `memory/YYYY-MM-DD.md`. Reviewed/distilled into this file periodically. Purge at 30 days.
- Other tracking: `memory/budget.md`, `memory/error-log.md`, `memory/k8s-2025-overview.md`

## Recent Updates
- **Apr 4:** `k8s-2025` reorg planning is now in tiny-mop-up territory: the repo structure is effectively settled, the proposal is ready to show Al, and the remaining decisions are mostly where two docs-root files should live plus refreshing stale README guidance to match the structure that already exists.
- **Apr 3:** A fresh inventory delta reconfirmed `k8s6.lan` SSH failure and `172.16.1.16` (`Legion.lan`) as an unresolved inventory stray. Quant short-term validation was tightened into a genuinely rolling 5-year train / next-year test; result: the short-term edge looks worse, not better, and remains research material rather than something fit to brag about. Ops follow-up also confirmed the cron-delivery issue persists (`announce` + missing `delivery.to`), duplicate-run oddities exist on a few jobs after schedule churn, and the handled `python` / shell-formatting errors still deserve cleanup.
- **Mar 31:** Quant short-term research was tightened into a stricter long/cash state-machine backtest with walk-forward validation; current work remains research-grade rather than publication-grade. Security/ops cleanup also moved git remotes to SSH, revoked exposed PAT, scrubbed tracked repo secrets, switched config backups to redacted snapshots, added `docs/SECRET_RECOVERY.md`, and expanded daily review expectations.
- **Mar 30:** Model/auth cleanup finished. Main session now runs on `openai-codex/gpt-5.4` via OAuth (`openai-codex:default`) instead of API-key routing. Removed Anthropic API-key route, removed lingering `OPENAI_API_KEY` env injection, confirmed subscription-backed usage windows visible in model/session tooling. Cron set cleaned up and logging helper added.
- **Mar 26-28:** Infrastructure monitoring week — deployed ntfy-alert-listener daemon (systemd, auto-restart, flap filtering), investigated Frigate OOM pattern (4th+ incident), auto-restart logic with 10-min cooldown, granted SSH access (OPNsense + vm01, read-only + Frigate restart exception), filed multiple RCAs. vm01 drive replacement started Mar 27 (may reduce OOM pressure). Token optimization: 59% context reduction. Quant strategy paper publication-ready (12.39% CAGR, 0.73 Sharpe, +187 bps over SPY).
