#!/usr/bin/env bash
set -euo pipefail

updated=no
pull_status=0
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf "%s" "$pull_output" | grep -Eqi "timed out|timeout|temporary failure|could not resolve host|connection.*(reset|timed out|refused)|remote end hung up|proxy error|tls|ssl|http 5[0-9][0-9]|502|503|504|service unavailable|network is unreachable"; then
    sleep 5
    pull_status=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  printf "%s\n" "$pull_output" >&2
  exit "$pull_status"
fi
if printf "%s" "$pull_output" | grep -q "Already up to date."; then
  updated=no
else
  updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  changed=no
  commit_hash=
else
  changed=yes
  msg="daily backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily_git_backup_commit.txt 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_status=0
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf "%s" "$push_output" | grep -Eqi "timed out|timeout|temporary failure|could not resolve host|connection.*(reset|timed out|refused)|remote end hung up|proxy error|tls|ssl|http 5[0-9][0-9]|502|503|504|service unavailable|network is unreachable"; then
      sleep 5
      push_status=0
      push_output=$(git push 2>&1) || push_status=$?
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    printf "%s\n" "$push_output" >&2
    exit "$push_status"
  fi
fi

printf "UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGED=%s\nCOMMIT_HASH=%s\n" "$updated" "$changed" "${commit_hash:-}"
