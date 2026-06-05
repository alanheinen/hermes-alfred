#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=
commit_made=no

pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc=$?
pull_rc=${pull_rc:-0}
if [ "$pull_rc" -ne 0 ]; then
  if printf '%s' "$pull_out" | grep -Eiq 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|502|503|504|remote end hung up|Operation timed out|network'; then
    sleep 5
    pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || { printf '%s\n' "$pull_out"; exit 11; }
  else
    printf '%s\n' "$pull_out"
    exit "$pull_rc"
  fi
fi
printf '%s\n' "$pull_out"
if ! printf '%s' "$pull_out" | grep -q 'Already up to date.'; then
  updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes=yes
  msg="daily backup $(date +%F)"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  commit_made=yes
  push_out=$(git push 2>&1) || push_rc=$?
  push_rc=${push_rc:-0}
  if [ "$push_rc" -ne 0 ]; then
    if printf '%s' "$push_out" | grep -Eiq 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|502|503|504|remote end hung up|Operation timed out|network'; then
      sleep 5
      push_out=$(git push 2>&1) || { printf '%s\n' "$push_out"; exit 12; }
    else
      printf '%s\n' "$push_out"
      exit "$push_rc"
    fi
  fi
  printf '%s\n' "$push_out"
fi

echo "__SUMMARY__ updated=$updated backup_refreshed=$backup_refreshed workspace_changes=$workspace_changes commit_made=$commit_made commit_hash=${commit_hash:-}"
