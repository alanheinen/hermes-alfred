#!/usr/bin/env bash
set -euo pipefail

# Required session context
for f in SOUL.md USER.md; do [ -f "$f" ] && cat "$f" >/dev/null; done
for d in "$(date +%F)" "$(date -d 'yesterday' +%F)"; do [ -f "memory/$d.md" ] && cat "memory/$d.md" >/dev/null; done
[ -f MEMORY.md ] && cat MEMORY.md >/dev/null

k8s_status="unchanged"
if out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1); then
  if printf '%s' "$out" | grep -q "Already up to date"; then
    k8s_status="already-up-to-date"
  else
    k8s_status="updated"
  fi
else
  if printf '%s' "$out" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|TLS|HTTP 5[0-9][0-9]|502|503|504|remote end hung up|failed to connect'; then
    sleep 5
    out2=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) && {
      if printf '%s' "$out2" | grep -q "Already up to date"; then
        k8s_status="already-up-to-date-after-retry"
      else
        k8s_status="updated-after-retry"
      fi
    } || {
      printf 'K8S_PULL_FAILED\n%s\nRETRY_OUTPUT\n%s\n' "$out" "$out2" >&2
      exit 21
    }
  else
    printf 'K8S_PULL_FAILED\n%s\n' "$out" >&2
    exit 20
  fi
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_status="refreshed"

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  ws_changes="no"
  commit_hash=""
else
  if git diff --cached --name-only | grep -Eq '(^|/)(\.env|.*secret.*|.*token.*|.*key.*|.*password.*)$'; then
    echo "Refusing to commit probable live secret material" >&2
    exit 30
  fi
  msg="daily backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily-git-backup-commit.txt 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  ws_changes="yes"
  if push_out=$(git push 2>&1); then
    :
  else
    if printf '%s' "$push_out" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|TLS|HTTP 5[0-9][0-9]|502|503|504|remote end hung up|failed to connect'; then
      sleep 5
      push_out2=$(git push 2>&1) || {
        printf 'PUSH_FAILED\n%s\nRETRY_OUTPUT\n%s\n' "$push_out" "$push_out2" >&2
        exit 41
      }
    else
      printf 'PUSH_FAILED\n%s\n' "$push_out" >&2
      exit 40
    fi
  fi
fi

printf 'K8S_STATUS=%s\nBACKUP_STATUS=%s\nWS_CHANGES=%s\nCOMMIT_HASH=%s\n' "$k8s_status" "$backup_status" "$ws_changes" "$commit_hash"
