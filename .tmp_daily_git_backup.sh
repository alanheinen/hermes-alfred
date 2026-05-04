#!/usr/bin/env bash
set -euo pipefail

pull_status=0
updated=no
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eiq 'timed out|timeout|temporar|connection reset|connection refused|could not resolve host|remote end hung up|http 5[0-9][0-9]|TLS|ssl|network is unreachable'; then
    sleep 5
    pull_status=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
printf 'PULL_STATUS=%s\n' "$pull_status"
printf '%s\n' "$pull_output"

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json

cd /home/aheinen/.openclaw/workspace
git add -A
changes=no
commit_hash=
push_status=0
push_output=
if ! git diff --cached --quiet; then
  changes=yes
  msg="Daily backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily-git-backup-commit.out 2>/tmp/daily-git-backup-commit.err
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eiq 'timed out|timeout|temporar|connection reset|connection refused|could not resolve host|remote end hung up|http 5[0-9][0-9]|TLS|ssl|network is unreachable'; then
      sleep 5
      push_status=0
      push_output=$(git push 2>&1) || push_status=$?
    fi
  fi
  printf 'PUSH_STATUS=%s\n' "$push_status"
  printf '%s\n' "$push_output"
fi
printf 'CHANGES=%s\nCOMMIT_HASH=%s\n' "$changes" "$commit_hash"
