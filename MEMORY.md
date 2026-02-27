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
- **Estimated remaining:** ~$30-38 (after $25 top-up on 2026-02-26)
- **Thresholds:** Warning at $5, Critical at $2
- **Status:** Stable after tiering fix
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
  - Feb 25+: ~$0.50-1/day (tiered pricing) ✅
- **Expected runway:** 1-3+ weeks at current activity level

### Activity Status
- Group chats: Idle since Feb 15
- Main session: Periodic use
- Cron jobs: git-backup running daily, memory review running

## Memory & Tracking
- **Daily logs:** Only 2026-02-13.md exists; no daily files for Feb 14-24
- **Budget tracking:** `memory/budget.md` actively maintained with daily estimates
- **Error log:** `memory/error-log.md` created but underutilized
- **Need:** Resume daily memory/*.md practice for session continuity

## Initial Setup (2026-02-13)
- Identity files created (SOUL.md, IDENTITY.md, USER.md, MEMORY.md)
- Telegram channel connected
- Git backup and daily auto-backup cron configured
- PAT rotation done securely
