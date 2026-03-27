# MEMORY.md - Long-Term Memory

## Key Facts
- Al (Alan) is my human. CST timezone.
- I'm Alfred. Dry wit, snarky, competent butler energy.
- First session: 2026-02-13
- Git backup repo: github.com/alanheinen/openclaw-alfred (daily 2 AM CST)

## Preferences
- Al prefers casual: "Al" or "Alan"
- Likes dry wit and snark — no corporate pleasantries
- Values disaster recovery planning

## Budget Situation 💰
- **Starting balance:** $25.08 (2026-02-13)
- **Top-ups:** $25.00 (2026-02-26) ✅, $25.00 (2026-03-20) ✅, $25.00 (2026-03-21) ✅, $25.00 (2026-03-26) ✅
- **Total funded:** $125.08
- **Current explicit Anthropic balance:** $14.37 (reported 2026-03-26 13:02 EDT)
- **Thresholds:** Warning at $5, Critical at $2
- **Status:** Needs monitoring — burn rate higher than originally estimated (~$1.50-3/day actual vs ~$0.15-0.30 earlier estimates). Crons now locked to Sonnet with no fallbacks.
- **Tracking:** Detailed log maintained in `memory/budget.md`

### ✅ Model Tiering
- **Fixed issue (Feb 25):** all sessions were effectively premium-priced; automated work was moved off Opus
- **Current posture:** main session uses Opus when the work actually warrants it; cron/automation work runs on Sonnet
- **Fallback chain (Mar 8):** trimmed to frontier-only models — Sonnet → GPT-5.4 → GPT-5.2 → GPT-5
- **Burn rate history:**
  - Feb 13-24: roughly ~$1-4/day during setup and all-Opus usage
  - Feb 25-Mar 19: roughly ~$0.15-0.30/day after tiering ✅
  - Mar 20+: roughly ~$1.50-3/day (higher activity, crons now locked to Sonnet with no fallbacks)
- **Expected runway:** Variable based on activity level; current burn suggests ~2-3 weeks between $25 top-ups

### Activity Status (as of Mar 26)
- **Group chats:** Deleted Mar 4 — 3 idle Telegram groups removed
- **Active automation:** git-backup, memory-review, daily-review, usage-report, quant-backtest-daily, quant-meeting-daily, ntfy-alert-listener (systemd daemon)
- **Automation posture:** cron noise trimmed on Mar 13; routine jobs explicitly pinned to Sonnet, git-backup and memory-review direct announces disabled, usage-report no longer targets main session. Real-time infrastructure monitoring via ntfy-alert-listener daemon (zero LLM cost, pure Python).
- **Infrastructure access:** SSH to OPNsense (172.16.1.1) and vm01.lan (172.16.1.141) for RCA investigations — read-only with exception to restart Frigate VM 105 on OOM kills
- **Main work lately:** infrastructure monitoring/RCA work, quant research, automated maintenance
- **Burn rate:** ~$1.50-3/day (significantly higher than earlier estimates)

## Memory & Tracking
- **Daily logs:** Active practice — most recent file: `2026-03-25.md`
  - Older-than-7-day logs reviewed/distilled through `2026-03-26.md`: `2026-02-28.md` ✓, `2026-03-04.md` ✓, `2026-03-06.md` ✓, `2026-03-08.md` ✓, `2026-03-09.md` ✓, `2026-03-10.md` ✓, `2026-03-11.md` ✓, `2026-03-12.md` ✓, `2026-03-13.md` ✓, `2026-03-16.md` ✓, `2026-03-18.md` ✓, `2026-03-19.md` ✓, `2026-03-20.md` ✓, `2026-03-22.md` ✓, `2026-03-23.md` ✓, `2026-03-24.md` ✓, `2026-03-25.md` ✓, `2026-03-26.md` ✓
  - No daily logs are old enough (>30 days) to purge yet; earliest is `2026-03-04.md`
  - Purged after distillation: `2026-02-13.md` (removed 2026-03-15), `2026-02-28.md` (removed 2026-03-21)
- **Budget tracking:** `memory/budget.md` actively maintained
- **Error log:** `memory/error-log.md` tracks cron failures and issues
- **k8s-2025 overview:** Stored in `memory/k8s-2025-overview.md`

## Projects & Active Work

### Quant Backtest (siloed-quant-repo)
- **Status:** Active; longer-history baseline is now the main reference model
- **Daily crons:** quant-backtest-daily (Sonnet, 2:00 AM EST) and quant-meeting-daily
- **Infrastructure:**
  - Dynamic `END_DATE` fix landed Mar 16, so daily runs now extend to the latest available session
  - Production fallback stack now covers both yield-spread and inflation inputs: FRED API → market/API sources → local CSV fallbacks
  - Synthetic Treasury history added for pre-ETF periods: `DGS7` for pre-IEF bond history and `DGS3MO` for pre-BIL cash history
  - Local FRED CSV caches auto-refresh when stale
  - Proxy calibration/validation work added Mar 18 (`proxy_validation.csv`) to tune synthetic IEF/BIL durations against ETF overlap
- **Current default baseline (extended-history):** weekly MA150 inflation guard over the 1994-02-04 to 2026-03-17 sample
  - Latest daily refresh (Mar 19): **12.59% CAGR / 0.75 Sharpe / -55.2% MaxDD / 73 position changes**
  - Mar 18 calibration rerun: 12.59% CAGR / 0.75 Sharpe / -55.2% MaxDD / 72 trades
  - Mar 16 promotion metrics: 12.57% CAGR / 0.74 Sharpe / -55.2% MaxDD through 2026-03-13
  - This superseded the earlier 2002+ monthly MA300 v2.2 baseline after the history extension and proxy work
- **Important milestones:**
  - Mar 13: CPIAUCSL CSV fallback closed the real-returns gap, so real-return reporting works even without a FRED API key
  - Mar 10: MA sensitivity work showed the strategy wasn’t obviously overfit across 100-300 day windows
  - Mar 9: momentum overlay solved the signal-lag problem and established the path beyond the weak original rotation model
- **Open caveats:**
  - Pre-ETF history now depends on calibrated synthetic Treasury proxies, so proxy quality remains an important validation lens
  - Longer-history comparisons changed some earlier cadence conclusions; older “monthly clearly wins” conclusions should be treated as superseded

## Initial Setup (2026-02-13)
- Identity files created (SOUL.md, IDENTITY.md, USER.md, MEMORY.md)
- Telegram channel connected
- Git backup and daily auto-backup cron configured
- PAT rotation done securely

## Recent Updates
- **March 26, 2026:** Major infrastructure monitoring deployment. Built and deployed `ntfy-alert-listener` systemd daemon (real-time streaming, 2-min flap filter, zero LLM cost). Investigated 3 outage incidents: Frigate OOM kills (4th in 11 days), mass-outage false positive (clawdbot network blip). Filed 2 RCAs in k8s-2025 repo. Al granted SSH access to OPNsense (root@) and vm01.lan (aheinen@) for deeper investigation — read-only with exception to restart Frigate VM 105. Wired auto-restart logic into alert listener (10-min cooldown). Fixed cron delivery duplicates and confirmed all 6 crons now on Sonnet after Al's manual gateway restart. Updated TOOLS.md with infrastructure access notes. Balance: $14.37.
- **March 20-25, 2026:** Quant team published STRATEGY_PAPER.md (28KB, publication-ready) and began short-term S&P 500 trading research (Phase 2 complete — tactical momentum overlay candidate). Budget concern emerged: actual burn rate ~$1.50-3/day, significantly higher than earlier estimates.
- **March 16-20, 2026:** Extended quant backtest history to 1994 via synthetic Treasury proxies, recalibrated durations against ETF overlap, promoted weekly MA150 inflation-guard baseline (12.59% CAGR / 0.75 Sharpe / -55.2% MaxDD). Admin cleanup: locked all cron jobs to Sonnet with no fallbacks, fixed usage-report cron.
- **March 13, 2026:** ISSUE-001 closed via CPI CSV fallback. Promoted 2002+ inflation-guard MA300 model (v2.2). Reduced cron noise, pinned routine jobs to Sonnet.
- **March 8, 2026:** Security audit complete — 0 critical issues. Model fallback chain trimmed to 4 frontier models.
