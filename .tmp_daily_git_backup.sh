#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=
pull_status=0
push_status=0

pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eqi 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|Failed to connect|remote end hung up|502|503|504|network'; then
    sleep 5
    pull_status=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  printf '%s\n' "$pull_output" >&2
  exit "$pull_status"
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
  msg="chore: daily backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily_git_backup_commit.txt 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eqi 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|Failed to connect|remote end hung up|502|503|504|network'; then
      sleep 5
      push_status=0
      push_output=$(git push 2>&1) || push_status=$?
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    printf '%s\n' "$push_output" >&2
    exit "$push_status"
  fi
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
