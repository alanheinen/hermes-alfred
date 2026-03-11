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
- **Current estimate:** ~$24-30 (as of Mar 8)
- **Thresholds:** Warning at $5, Critical at $2
- **Status:** Stable — tiering highly effective, 3-6+ month runway
- **Tracking:** Detailed log maintained in `memory/budget.md`

### ✅ Model Tiering Implemented (Feb 25)
- **Fixed issue:** All 7 sessions were on Opus → now 6 switched to Sonnet
- **Current setup (updated Mar 4):** 
  - Main session: Opus (claude-opus-4-6)
  - 3 cron sessions: Sonnet (claude-sonnet-4-5)
- **Burn rate improvement:** 
  - Feb 13-24: ~$1-4/day (setup + all Opus)
  - Feb 25+: ~$0.15-0.30/day (tiered pricing) ✅
- **Expected runway:** 3-6+ months at current activity level

### Activity Status (as of Mar 8)
- **Session count:** 4 total (1 Opus main + 3 Sonnet crons)
- **Group chats:** Deleted Mar 4 — 3 idle Telegram groups removed
- Main session: Light use (quant meetings, security audit, memory maintenance)
- Active cron jobs: git-backup, memory-review, daily-review, usage-report, quant-backtest-daily (all Sonnet)
- **Recent work:** Security audit complete (0 critical issues), quant backtest Days 3-5
- **Burn rate:** Consistently ~$0.15-0.30/day (tiering very effective)

## Memory & Tracking
- **Daily logs:** Active practice — most recent: 2026-03-08.md
  - Reviewed: 2026-02-13.md ✓, 2026-02-28.md ✓, 2026-03-04.md ✓, 2026-03-06.md ✓, 2026-03-08.md ✓
- **Budget tracking:** `memory/budget.md` actively maintained
- **Error log:** `memory/error-log.md` tracks cron failures and issues
- **k8s-2025 overview:** Stored in `memory/k8s-2025-overview.md`

## Projects & Active Work

### Quant Backtest (siloed-quant-repo)
- **Status:** ✅ Operational (as of Mar 6)
- **Daily cron:** quant-backtest-daily (Sonnet, 2:00 AM EST)
- **Infrastructure:** Production-ready 3-layer fallback for T10Y2Y data (FRED API → yfinance → CSV)
  - CSV fallback is permanent infrastructure (6180 observations, 2002-2026)
  - Survives ticker delistings and API outages
- **Current findings:** Rotation strategy underperforms SPY by ~200 bps/year (8.25% vs 10.35% CAGR)
  - Only 4 rotations in 19 years (73% equities, 26% bonds)
  - Max drawdown: -55.2% (same as SPY) — no downside protection
  - **Day 5 (Mar 8):** 3-state model (SPY/IEF/BIL) tested and rejected — underperforms 2-state by 72 bps
- **Active focus:** ISSUE-002 (correlation regime analysis), Day 6 momentum overlay upcoming
- **Deferred:** ISSUE-001 (real returns) — medium priority, ISSUE-003 (survivorship bias) — low priority

## Initial Setup (2026-02-13)
- Identity files created (SOUL.md, IDENTITY.md, USER.md, MEMORY.md)
- Telegram channel connected
- Git backup and daily auto-backup cron configured
- PAT rotation done securely

## Recent Updates
- **March 8, 2026:** Security audit complete — 0 critical issues. Model fallback chain trimmed to 4 frontier models (Sonnet→GPT-5.4→GPT-5.2→GPT-5). Quant Day 5: 3-state model rejected (-72 bps vs 2-state). GroupPolicy lesson learned: empty allowlist is correct posture when no active groups.
- **March 6, 2026:** Quant backtest infrastructure hardened with production-ready 3-layer fallback (Day 3 complete). Strategy underperforms SPY by 200 bps/year with no downside protection. Focus shifted to correlation regime analysis (ISSUE-002).
- **March 4, 2026:** Session cleanup — reduced from 7→4 sessions (deleted 3 idle Telegram groups). Daily logging resumed. System stable.
- **February 28, 2026:** Daily memory logging practice resumed after 2-week gap.
- **February 26, 2026:** Budget top-up ($25.00) confirmed. Model tiering highly effective.