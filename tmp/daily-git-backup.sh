#!/usr/bin/env bash
set -euo pipefail

K8S_UPDATED=no
BACKUP_REFRESHED=no
WORKSPACE_CHANGED=no
COMMIT_HASH=

PULL_STATUS=0
PULL_OUTPUT_1=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || PULL_STATUS=$?
if [ "$PULL_STATUS" -ne 0 ]; then
  if printf '%s' "$PULL_OUTPUT_1" | grep -Eiq 'Could not resolve host|Connection timed out|Operation timed out|TLS|SSL|temporarily unavailable|connection reset|remote end hung up|502|503|504|proxy|network is unreachable|failed to connect'; then
    sleep 5
    PULL_STATUS2=0
    PULL_OUTPUT_2=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || PULL_STATUS2=$?
    if [ "$PULL_STATUS2" -ne 0 ]; then
      printf 'PULL_FAILED\n%s\n' "$PULL_OUTPUT_2"
      exit 21
    fi
    PULL_OUTPUT="$PULL_OUTPUT_2"
  else
    printf 'PULL_FAILED\n%s\n' "$PULL_OUTPUT_1"
    exit 22
  fi
else
  PULL_OUTPUT="$PULL_OUTPUT_1"
fi

if printf '%s' "$PULL_OUTPUT" | grep -q 'Updating '; then
  K8S_UPDATED=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
BACKUP_REFRESHED=yes

cd /home/aheinen/.openclaw/workspace
git add -A
git reset -q HEAD -- .openclaw/openclaw.json .openclaw/openclaw.json.bak auth-profiles.json openclaw.json openclaw.json.bak 2>/dev/null || true

if ! git diff --cached --quiet; then
  WORKSPACE_CHANGED=yes
  git commit -m "daily backup: refresh redacted config and workspace state" >/tmp/daily_git_backup_commit.txt 2>&1
  COMMIT_HASH=$(git rev-parse --short HEAD)

  PUSH_STATUS=0
  PUSH_OUTPUT_1=$(git push 2>&1) || PUSH_STATUS=$?
  if [ "$PUSH_STATUS" -ne 0 ]; then
    if printf '%s' "$PUSH_OUTPUT_1" | grep -Eiq 'Could not resolve host|Connection timed out|Operation timed out|TLS|SSL|temporarily unavailable|connection reset|remote end hung up|502|503|504|proxy|network is unreachable|failed to connect'; then
      sleep 5
      PUSH_STATUS2=0
      PUSH_OUTPUT_2=$(git push 2>&1) || PUSH_STATUS2=$?
      if [ "$PUSH_STATUS2" -ne 0 ]; then
        printf 'PUSH_FAILED\n%s\nCOMMIT_HASH=%s\n' "$PUSH_OUTPUT_2" "$COMMIT_HASH"
        exit 23
      fi
    else
      printf 'PUSH_FAILED\n%s\nCOMMIT_HASH=%s\n' "$PUSH_OUTPUT_1" "$COMMIT_HASH"
      exit 24
    fi
  fi
fi

printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGED=%s\nCOMMIT_HASH=%s\n' "$K8S_UPDATED" "$BACKUP_REFRESHED" "$WORKSPACE_CHANGED" "$COMMIT_HASH"
