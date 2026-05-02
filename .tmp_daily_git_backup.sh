#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=
commit_made=no

pull_status=0
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eiq 'Could not resolve host|Connection timed out|Operation timed out|connection reset|TLS|HTTP 5[0-9][0-9]|remote end hung up|Failed to connect|Temporary failure|timeout|502|503|504'; then
    sleep 5
    pull_status=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  printf 'K8S_PULL_FAILED\n%s\n' "$pull_output"
  exit 21
fi
if printf '%s' "$pull_output" | grep -q 'Already up to date.'; then
  updated=no
else
  updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes=yes
  commit_msg="Daily backup $(date +%F)"
  git commit -m "$commit_msg" >/tmp/daily-git-backup-commit.out 2>/tmp/daily-git-backup-commit.err
  commit_hash=$(git rev-parse --short HEAD)
  commit_made=yes
  push_status=0
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eiq 'Could not resolve host|Connection timed out|Operation timed out|connection reset|TLS|HTTP 5[0-9][0-9]|remote end hung up|Failed to connect|Temporary failure|timeout|502|503|504'; then
      sleep 5
      push_status=0
      push_output=$(git push 2>&1) || push_status=$?
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    printf 'WORKSPACE_PUSH_FAILED\n%s\n' "$push_output"
    exit 22
  fi
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_MADE=%s\nCOMMIT_HASH=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_made" "$commit_hash"
