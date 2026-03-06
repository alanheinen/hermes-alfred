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
- **Current estimate:** ~$28-35 (as of Mar 3)
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

### Activity Status (as of Mar 6)
- **Session count:** 4 total (1 Opus main + 3 Sonnet crons)
- **Group chats:** Deleted Mar 4 — 3 idle Telegram groups removed (passive-income, automated-ops, network-performance)
- Main session: Sporadic use (budget checks, memory maintenance)
- Cron jobs: git-backup, memory-review, daily-review, usage-report, quant-backtest-daily (all Sonnet)
- Overall activity: Low — system stable, backtest cron has data fetch issues
- **Burn rate:** Consistently ~$0.15-0.30/day (tiering very effective)

## Memory & Tracking
- **Daily logs:** 2026-02-13.md (initial setup), 2026-02-28.md, 2026-03-04.md, 2026-03-06.md (latest)
- **Budget tracking:** `memory/budget.md` actively maintained through Mar 3
- **Error log:** `memory/error-log.md` tracks cron failures and issues
- **k8s-2025 overview:** Stored in `memory/k8s-2025-overview.md` (repo not on this machine)
- **Note:** Daily logging resumed Mar 4 per Al's request. Error logging active for cron failures.

## Projects & Active Work

### Quant Backtest (siloed-quant-repo)
- **Status:** Active but failing (as of Mar 6)
- **Daily cron:** quant-backtest-daily (Sonnet, 2:00 AM EST)
- **Issue:** Yield curve data fetch broken
  - ^TWO (2Y Treasury) delisted/unavailable on yfinance
  - ^IRX (3M) fallback also failing
  - No FRED_API_KEY configured for alternative source
  - Script crashes on empty DataFrame → daily backtest skipped
- **Fix needed:** Set FRED_API_KEY or improve error handling with cached fallback

## Initial Setup (2026-02-13)
- Identity files created (SOUL.md, IDENTITY.md, USER.md, MEMORY.md)
- Telegram channel connected
- Git backup and daily auto-backup cron configured
- PAT rotation done securely

## Updates
- **March 6, 2026:** quant-backtest-daily cron failing since Mar 6 due to Treasury data fetch issues (^TWO delisted, no FRED key). Error logged, needs fix.
- **March 5, 2026:** Session cleanup completed Mar 4 — deleted 3 idle Telegram group sessions. Session count reduced from 7→4 (1 main + 3 crons). Al requested daily logging resume again on Mar 4. System continues stable operation with low burn rate.