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
- **Top-ups:** $25.00 (2026-02-26) ✅, $25.00 (2026-03-20) ✅
- **Current explicit Anthropic balance:** $23.82 (reported 2026-03-20)
- **Thresholds:** Warning at $5, Critical at $2
- **Status:** Stable — Anthropic billing issue cleared, model tiering still keeps runway measured in months
- **Tracking:** Detailed log maintained in `memory/budget.md`

### ✅ Model Tiering
- **Fixed issue (Feb 25):** all sessions were effectively premium-priced; automated work was moved off Opus
- **Current posture:** main session uses Opus when the work actually warrants it; cron/automation work runs on Sonnet
- **Fallback chain (Mar 8):** trimmed to frontier-only models — Sonnet → GPT-5.4 → GPT-5.2 → GPT-5
- **Burn rate improvement:**
  - Feb 13-24: roughly ~$1-4/day during setup and all-Opus usage
  - Feb 25+: roughly ~$0.15-0.30/day after tiering ✅
- **Expected runway:** ~3-5+ months at current activity

### Activity Status (as of Mar 20)
- **Group chats:** Deleted Mar 4 — 3 idle Telegram groups removed
- **Active automation:** git-backup, memory-review, daily-review, usage-report, quant-backtest-daily, quant-meeting-daily
- **Automation posture:** cron noise trimmed on Mar 13; routine jobs explicitly pinned to Sonnet, git-backup and memory-review direct announces disabled, and usage-report no longer targets the main session
- **Main work lately:** quant research, security hardening, and memory maintenance
- **Burn rate:** holding around ~$0.15-0.30/day

## Memory & Tracking
- **Daily logs:** Active practice — most recent file: `2026-03-20.md`
  - Older-than-7-day logs reviewed/distilled through `2026-03-18.md`: `2026-02-28.md` ✓, `2026-03-04.md` ✓, `2026-03-06.md` ✓, `2026-03-08.md` ✓, `2026-03-09.md` ✓, `2026-03-10.md` ✓, `2026-03-11.md` ✓, `2026-03-12.md` ✓, `2026-03-13.md` ✓, `2026-03-16.md` ✓, `2026-03-18.md` ✓
  - Mar 19-20 quant/admin updates are distilled below
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
- **March 20, 2026:** Quant daily committed as `5bc374a` with metrics at 12.53% CAGR / 0.74 Sharpe / -55.2% MaxDD through 2026-03-19. Admin cleanup fixed daily-usage-report cron payload mismatch, locked all cron jobs to Sonnet with no fallbacks, added k8s-2025 daily fast-forward pull to git maintenance, cleared stale Telegram delivery failures, and refreshed k8s overview after repo pull. Al added $25 budget top-up, bringing Anthropic balance to $23.82.
- **March 19, 2026:** Daily quant refresh committed as `0a3fde4`; headline default metrics held steady at 12.59% CAGR / 0.75 Sharpe / -55.2% MaxDD through 2026-03-17, with 73 position changes after the latest rerun.
- **March 18, 2026:** Recalibrated synthetic IEF/BIL proxy durations against ETF overlap, added `proxy_validation.csv` diagnostics, reran the full backtest stack, and pushed commit `c2b0852`. Calibration rerun metrics: 12.59% CAGR / 0.75 Sharpe / -55.2% MaxDD / 72 trades over 1994-02-04 to 2026-03-17.
- **March 16, 2026:** Fixed stale hard-coded `END_DATE`, added synthetic Treasury proxies plus stale-CSV auto-refresh, extended the default sample back to 1994, and promoted the weekly MA150 inflation-guard baseline. Repo commits: `a9d4050` and `1927669`.
- **March 13, 2026:** Quant Day 10 promoted the 2002+ inflation-guard MA300 model to the then-current default (v2.2). ISSUE-001 was closed via CPI CSV fallback, enabling real-return reporting without FRED API access. Admin cleanup also reduced cron noise and pinned routine jobs to Sonnet.
- **March 8, 2026:** Security audit complete — 0 critical issues. Model fallback chain trimmed to 4 frontier models. Group policy lesson: empty allowlist is the correct posture when no groups are active.
- **March 4, 2026:** Session cleanup — deleted 3 idle Telegram group sessions. Daily logging resumed and overall system state stayed stable.
- **February 28, 2026:** Daily memory logging practice resumed after a 2-week gap.
- **February 26, 2026:** Budget top-up ($25.00) confirmed. Model tiering proved highly effective.
