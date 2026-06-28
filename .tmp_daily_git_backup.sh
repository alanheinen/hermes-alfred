#!/usr/bin/env bash
set -euo pipefail
updated=no
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
pull_status=${pull_status:-0}
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eiq 'timed out|timeout|temporary failure|could not resolve host|connection.*(reset|refused)|TLS|HTTP 5[0-9][0-9]|remote end hung up|proxy error|network is unreachable'; then
    sleep 5
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
    pull_status=${pull_status:-0}
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  printf 'K8S_PULL_STATUS=%s\n' "$pull_status"
  printf 'K8S_PULL_OUTPUT<<EOF\n%s\nEOF\n' "$pull_output"
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
if git diff --cached --quiet; then
  workspace_changes=no
  commit_hash=
else
  workspace_changes=yes
  msg="backup: refresh $(date +%F)"
  git commit -m "$msg" >/tmp/daily-git-backup-commit.log 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || push_status=$?
  push_status=${push_status:-0}
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eiq 'timed out|timeout|temporary failure|could not resolve host|connection.*(reset|refused)|TLS|HTTP 5[0-9][0-9]|remote end hung up|proxy error|network is unreachable'; then
      sleep 5
      push_output=$(git push 2>&1) || push_status=$?
      push_status=${push_status:-0}
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    printf 'PUSH_STATUS=%s\n' "$push_status"
    printf 'PUSH_OUTPUT<<EOF\n%s\nEOF\n' "$push_output"
    exit "$push_status"
  fi
fi
printf 'K8S_UPDATED=%s\n' "$updated"
printf 'BACKUP_REFRESHED=%s\n' "$backup_refreshed"
printf 'WORKSPACE_CHANGES=%s\n' "$workspace_changes"
printf 'COMMIT_HASH=%s\n' "$commit_hash"
