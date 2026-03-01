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
- **Current estimate:** ~$29-36 (as of Feb 27)
- **Thresholds:** Warning at $5, Critical at $2
- **Status:** Stable — tiering effective
- **Tracking:** Detailed log maintained in `memory/budget.md`

### ✅ Model Tiering Implemented (Feb 25)
- **Previous issue:** All 7 sessions were on Opus (expensive!)
- **Fixed:** 6 sessions switched to Sonnet, only main stays on Opus
- **Current setup:** 
  - Main session: Opus (claude-opus-4-6)
  - 6 other sessions (crons + group chats): Sonnet (claude-sonnet-4-5)
- **Burn rate improvement:** 
  - Feb 13-14: ~$2-4/day (heavy setup, all Opus)
  - Feb 15-24: ~$1-2/day (low activity, all Opus)
  - Feb 25-27: ~$0.50/day (tiered pricing) ✅
- **Expected runway:** 2-4+ weeks at current activity level

### Activity Status (as of Feb 28)
- Group chats: Idle since Feb 15
- Main session: Sporadic use (budget checks, config)
- Cron jobs: git-backup daily, memory-review daily (both Sonnet)
- Overall activity: Low — system stable, monitoring active
- **Burn rate update:** Feb 28 shows ~$0.20-0.50/day (tiering very effective)

## Memory & Tracking
- **Daily logs:** 2026-02-13.md (initial setup), 2026-02-28.md (resumed logging)
- **Budget tracking:** `memory/budget.md` actively maintained
- **Error log:** `memory/error-log.md` exists but underutilized
- **k8s-2025 overview:** Stored in `memory/k8s-2025-overview.md` (repo not on this machine)
- **Gap note:** Two-week gap (Feb 14-27) due to low activity; daily logging practice resumed Feb 28

## Initial Setup (2026-02-13)
- Identity files created (SOUL.md, IDENTITY.md, USER.md, MEMORY.md)
- Telegram channel connected
- Git backup and daily auto-backup cron configured
- PAT rotation done securely
