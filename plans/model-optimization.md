# Model Optimization Plan

## Current Spend: ~$9-10/day
## Target Spend: ~$2-3/day (70% reduction)

## Strategy

### 1. Default Model Priority
```
Primary: gpt-oss:20b (local, free) ✅ Already set
Fallback chain:
  1. openai/gpt-4o-mini (cheap API)
  2. anthropic/claude-sonnet-4-5 (mid-tier)
  3. anthropic/claude-opus-4-6 (premium, emergency only)
```

### 2. Cron Job Optimization
**Current state:**
- daily-git-backup: using Opus ($0.70/day)
- daily-review: using Opus ($0.90/day)
- daily-usage-report: using main session model

**Target state:**
- daily-git-backup: use local model (gpt-oss:20b)
- daily-review: use gpt-4o-mini
- daily-usage-report: use local model

**Savings:** ~$1.60/day

### 3. Session-Specific Models
**Main chat (you + me):**
- Default: gpt-oss:20b (local)
- Override to sonnet for complex work: `/model sonnet`
- Override to opus only when needed: `/model opus`

**Telegram groups:**
- Default: gpt-oss:20b (local)
- Fallback to gpt-4o-mini if local fails

**Sub-agents:**
- Simple tasks: gpt-oss:20b
- Complex tasks: gpt-4o-mini
- Critical tasks: sonnet (only when specified)

### 4. Context Management
**Problem:** Large context = more input tokens = higher cost
**Solutions:**
- Enable aggressive compaction
- Prune old messages more frequently
- Reduce workspace context files in system prompt
- Use memory files instead of full history

### 5. Rate Limit Relief
**Benefits of local-first:**
- Zero rate limits on local models
- Anthropic quota saved for when you really need it
- Can run parallel requests without hitting API limits

## Implementation Steps

### Step 1: Update Cron Jobs
```bash
# Update daily-git-backup to use local model
cron update daily-git-backup --model gpt-oss:20b

# Update daily-review to use cheap API
cron update daily-review-and-optimize --model gpt4o-mini
```

### Step 2: Adjust Fallback Chain
Update config to prioritize cheap models:
```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "custom-nas-lan-30068/gpt-oss:20b",
        "fallbacks": [
          "openai/gpt-4o-mini",
          "anthropic/claude-haiku-4-5",
          "anthropic/claude-sonnet-4-5",
          "openai/gpt-4o",
          "anthropic/claude-opus-4-6"
        ]
      }
    }
  }
}
```

### Step 3: Group Chat Models
Configure Telegram groups to use local model:
```json
{
  "channels": {
    "telegram": {
      "groups": {
        "*": {
          "model": "gpt-oss:20b"
        }
      }
    }
  }
}
```

### Step 4: Enable Context Pruning
```json
{
  "agents": {
    "defaults": {
      "compaction": {
        "mode": "aggressive",
        "target": 100000
      }
    }
  }
}
```

## Expected Results

### Cost Breakdown (Target)
| Task | Current | Target | Savings |
|------|---------|--------|---------|
| Main chat | $3-4/day | $0.50/day | $2.50-3.50 |
| Cron jobs | $1.60/day | $0.10/day | $1.50 |
| Groups | $3.50/day | $1/day | $2.50 |
| Sub-agents | $1-2/day | $0.20/day | $0.80-1.80 |
| **Total** | **$9-10/day** | **$2-3/day** | **$7-8/day** |

### Quality Trade-offs
- **Minimal impact** for routine tasks (health checks, logs, backups)
- **Slight impact** for casual conversation (local model is decent)
- **No impact** for complex work (still falls back to Sonnet/Opus when needed)

### Rate Limit Relief
- Anthropic quota usage drops by ~80%
- No more 429 errors on routine tasks
- Premium models available when you actually need them

## Monitoring
- Track daily spend in memory/budget.md
- Monitor local model quality (adjust if responses are poor)
- Alert if fallback to expensive models happens frequently

## Rollback Plan
If local model quality is insufficient:
1. Set primary back to gpt-4o-mini (cheap but reliable)
2. Keep local as first fallback
3. Cost would be ~$3-5/day (still 50% savings)
