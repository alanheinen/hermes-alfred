#!/usr/bin/env bash
set -euo pipefail
K8S_STATUS="unchanged"
BACKUP_STATUS="not-run"
WORKTREE_STATUS="no-changes"
COMMIT_HASH=""
COMMIT_MADE=0

pull_rc=0
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc=$?
if [ "$pull_rc" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eqi 'Could not resolve host|Connection timed out|Operation timed out|TLS|SSL|Connection reset|502|503|504|remote end hung up|Failed to connect|Temporary failure|network|proxy|server unexpectedly closed'; then
    sleep 5
    pull_rc=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc=$?
  fi
fi
if [ "$pull_rc" -ne 0 ]; then
  printf 'K8S_PULL_FAILED\n%s\n' "$pull_output"
  exit 21
fi
if printf '%s' "$pull_output" | grep -q 'Already up to date.'; then
  K8S_STATUS="unchanged"
else
  K8S_STATUS="updated"
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
BACKUP_STATUS="refreshed"

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  WORKTREE_STATUS="changed"
  msg="chore: refresh backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily_git_backup_commit.txt 2>&1
  COMMIT_HASH=$(git rev-parse --short HEAD)
  COMMIT_MADE=1

  push_rc=0
  push_output=$(git push 2>&1) || push_rc=$?
  if [ "$push_rc" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eqi 'Could not resolve host|Connection timed out|Operation timed out|TLS|SSL|Connection reset|502|503|504|remote end hung up|Failed to connect|Temporary failure|network|proxy|server unexpectedly closed'; then
      sleep 5
      push_rc=0
      push_output=$(git push 2>&1) || push_rc=$?
    fi
  fi
  if [ "$push_rc" -ne 0 ]; then
    printf 'WORKSPACE_PUSH_FAILED\n%s\nCOMMIT_HASH=%s\n' "$push_output" "$COMMIT_HASH"
    exit 22
  fi
else
  WORKTREE_STATUS="no-changes"
fi

printf 'K8S_STATUS=%s\nBACKUP_STATUS=%s\nWORKTREE_STATUS=%s\nCOMMIT_MADE=%s\nCOMMIT_HASH=%s\n' "$K8S_STATUS" "$BACKUP_STATUS" "$WORKTREE_STATUS" "$COMMIT_MADE" "$COMMIT_HASH"
