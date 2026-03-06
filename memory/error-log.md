# Error Log

## 2026-03-06 02:00 - Backtest Data Fetch Failure
- **Job:** quant-backtest-daily (cron:ddd26695-28c6-45cc-a160-4fcdb617177e)
- **Script:** `/home/aheinen/.openclaw/workspace/siloed-quant-repo/strategy_backtest.py`
- **Error:** IndexError - yield curve spread DataFrame empty
- **Details:**
  - ^TWO (2Y Treasury) unavailable from yfinance (possibly delisted)
  - ^IRX (3M) fallback also failed to return data
  - No FRED_API_KEY configured for alternative data source
  - Script crashes when trying to access spread.index[0] on empty DataFrame
- **Impact:** Daily backtest skipped, no results committed
- **Fix needed:** 
  1. Set FRED_API_KEY in environment or config
  2. Add error handling for empty DataFrame case
  3. Consider cached fallback data or graceful skip

## 2026-02-28 02:00 - Memory Review Cron Skip
- **Job:** memory-review (cron:9a0c7868-67d9-4edc-8bc9-e2dcb58ba49b)
- **Status:** Skipped - no recent daily files to review
- **Note:** Normal behavior when no daily files exist

## 2026-02-26 Budget Top-Up Notification Sent ✅
- **Job:** usage-report (cron)
- **Action:** Al confirmed $25 top-up processed
- **Outcome:** Budget stabilized at ~$50 total
