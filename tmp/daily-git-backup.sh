#!/usr/bin/env bash
set -euo pipefail

updated=no
pull_status=0
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eqi 'Could not resolve host|Temporary failure|Connection timed out|Operation timed out|TLS|HTTP/[0-9.]+ 5[0-9][0-9]|502|503|504|remote end hung up|Connection reset|Failed to connect|network'; then
    sleep 5
    pull_status=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  printf 'K8S_PULL_FAILED\n%s\n' "$pull_output"
  exit "$pull_status"
fi
if printf '%s' "$pull_output" | grep -q 'Already up to date.'; then
  updated=no
else
  updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  changes=no
  commit_hash=
else
  changes=yes
  msg="chore: refresh workspace backup $(date -u +%F)"
  git commit -m "$msg" >/tmp/daily-git-backup-commit.log 2>&1
  commit_hash=$(git rev-parse HEAD)
  push_status=0
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eqi 'Could not resolve host|Temporary failure|Connection timed out|Operation timed out|TLS|HTTP/[0-9.]+ 5[0-9][0-9]|502|503|504|remote end hung up|Connection reset|Failed to connect|network'; then
      sleep 5
      push_status=0
      push_output=$(git push 2>&1) || push_status=$?
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    printf 'WORKSPACE_PUSH_FAILED\n%s\nCOMMIT=%s\n' "$push_output" "$commit_hash"
    exit "$push_status"
  fi
fi

printf 'UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$changes" "${commit_hash:-}"
