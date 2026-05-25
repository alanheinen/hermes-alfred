#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=
commit_made=no

pull_out=$(mktemp)
pull_status=0
if ! git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_out" 2>&1; then
  pull_status=$?
  if grep -Eqi 'timed out|timeout|Could not resolve host|Connection reset|Connection timed out|network is unreachable|remote end hung up|TLS|502|503|504|temporar|try again|internal server error' "$pull_out"; then
    sleep 5
    pull_status=0
    git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_out" 2>&1 || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  cat "$pull_out"
  rm -f "$pull_out"
  exit "$pull_status"
fi
if ! grep -q 'Already up to date\.' "$pull_out"; then
  updated=yes
fi
rm -f "$pull_out"

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes=yes
  msg="Daily backup refresh $(date +%F)"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  commit_made=yes
  push_out=$(mktemp)
  push_status=0
  if ! git push >"$push_out" 2>&1; then
    push_status=$?
    if grep -Eqi 'timed out|timeout|Could not resolve host|Connection reset|Connection timed out|network is unreachable|remote end hung up|TLS|502|503|504|temporar|try again|internal server error' "$push_out"; then
      sleep 5
      push_status=0
      git push >"$push_out" 2>&1 || push_status=$?
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    cat "$push_out"
    rm -f "$push_out"
    exit "$push_status"
  fi
  rm -f "$push_out"
fi
printf 'k8s_updated=%s\nbackup_refreshed=%s\nworkspace_changes=%s\ncommit_made=%s\ncommit_hash=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_made" "$commit_hash"
