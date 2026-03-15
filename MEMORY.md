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
- **Top-up:** $25.00 (2026-02-26) ✅ Confirmed
- **Current estimate:** ~$22-27 remaining (as of Mar 14)
- **Thresholds:** Warning at $5, Critical at $2
- **Status:** Stable — model tiering is working, runway still measured in months
- **Tracking:** Detailed log maintained in `memory/budget.md`

### ✅ Model Tiering
- **Fixed issue (Feb 25):** all sessions were effectively premium-priced; automated work was moved off Opus
- **Current posture:** main session uses Opus when the work actually warrants it; cron/automation work runs on Sonnet
- **Fallback chain (Mar 8):** trimmed to frontier-only models — Sonnet → GPT-5.4 → GPT-5.2 → GPT-5
- **Burn rate improvement:**
  - Feb 13-24: roughly ~$1-4/day during setup and all-Opus usage
  - Feb 25+: roughly ~$0.15-0.30/day after tiering ✅
- **Expected runway:** ~3-5+ months at current activity

### Activity Status (as of Mar 14)
- **Group chats:** Deleted Mar 4 — 3 idle Telegram groups removed
- **Active automation:** git-backup, memory-review, daily-review, usage-report, quant-backtest-daily, quant-meeting-daily
- **Automation posture:** cron noise trimmed on Mar 13 — git-backup and memory-review direct announces disabled; usage-report no longer targets the main session
- **Main work lately:** quant research, security hardening, and memory maintenance
- **Burn rate:** holding around ~$0.15-0.30/day

## Memory & Tracking
- **Daily logs:** Active practice — most recent: `2026-03-13.md`
  - Reviewed/distilled: `2026-02-13.md` ✓, `2026-02-28.md` ✓, `2026-03-04.md` ✓, `2026-03-06.md` ✓, `2026-03-08.md` ✓
- **Budget tracking:** `memory/budget.md` actively maintained
- **Error log:** `memory/error-log.md` tracks cron failures and issues
- **k8s-2025 overview:** Stored in `memory/k8s-2025-overview.md`

## Projects & Active Work

### Quant Backtest (siloed-quant-repo)
- **Status:** ✅ Production-ready v2.2 research baseline established
- **Daily cron:** quant-backtest-daily (Sonnet, 2:00 AM EST)
- **Infrastructure:** production-ready 3-layer fallback for T10Y2Y data (FRED API → yfinance → CSV)
  - CSV fallback is permanent infrastructure (6180 observations, 2002-2026)
  - FRED API key configured in `.env` (gitignored)
  - CPIAUCSL CSV fallback added, so real-return reporting now works even without the API key
- **Strategy v2.2 (Inflation-Guard MA300):** 10.93% CAGR / 0.58 Sharpe / -46.0% MaxDD
  - Default rule: when spread < 0.50% **and** SPY < MA300, use **BIL instead of IEF** if YoY CPI > 4%
  - Real-return snapshot: 8.40% CAGR / 0.45 Sharpe / -44.4% MaxDD
  - Mar 12 automated sweep picked MA300 as the strongest nominal baseline (11.93% CAGR / 0.61 Sharpe / -46.0% MaxDD), which led into the Mar 13 default promotion
  - Fewer defensive mistakes during inflation shocks; default output/docs now aligned with shipped strategy
  - MA sensitivity validated across 100-300 day windows (Day 7): not obviously overfit
  - Cadence remains under active review: monthly won under the earlier stack, but weekly no longer looks obviously worse after restoring the true T10Y2Y data path
- **Closed:** ISSUE-001 (real returns), ISSUE-002 (correlation regimes), ISSUE-004 (signal lag), ISSUE-005 (MA sensitivity), ISSUE-006 (weekly rebalance rejected under old stack), ISSUE-007 (default MA selection)
- **Open:** ISSUE-003 (pre-2002 bond proxy / inception bias), ISSUE-008 (re-validate cadence under corrected data stack)
- **Rejected:** 3-state SPY/IEF/BIL model (Day 5) — cash filter worsened returns

## Initial Setup (2026-02-13)
- Identity files created (SOUL.md, IDENTITY.md, USER.md, MEMORY.md)
- Telegram channel connected
- Git backup and daily auto-backup cron configured
- PAT rotation done securely

## Recent Updates
- **March 13, 2026:** Quant Day 10 promoted the inflation-guard MA300 model to the new default (v2.2). ISSUE-001 closed via CPI CSV fallback, so real-return reporting now works even without FRED API access. Admin cleanup also reduced cron noise by disabling direct announces for git-backup/memory-review and moving usage-report off the main-session target.
- **March 12, 2026:** Automated quant run showed MA300 as the strongest nominal baseline (11.93% CAGR / 0.61 Sharpe / -46.0% MaxDD), setting up the v2.2 promotion.
- **March 11, 2026:** Monthly rebalancing looked best under the earlier data stack, but that conclusion is now provisional after the true-T10Y2Y path was restored.
- **March 10, 2026:** FRED API key configured in siloed-quant-repo (`.env`, gitignored). Attribution added per FRED ToS. Quant Days 6-7 captured the momentum overlay breakthrough (+300 bps over v1.0) and closed MA sensitivity work.
- **March 8, 2026:** Security audit complete — 0 critical issues. Model fallback chain trimmed to 4 frontier models. Group policy lesson: empty allowlist is the correct posture when no groups are active.
- **March 6, 2026:** Quant backtest infrastructure hardened with production-ready 3-layer fallback (Day 3 complete). Strategy underperformed SPY by ~200 bps/year with no downside protection, which shifted focus to regime analysis.
- **March 4, 2026:** Session cleanup — deleted 3 idle Telegram group sessions. Daily logging resumed and overall system state stayed stable.
- **February 28, 2026:** Daily memory logging practice resumed after a 2-week gap.
- **February 26, 2026:** Budget top-up ($25.00) confirmed. Model tiering proved highly effective.
