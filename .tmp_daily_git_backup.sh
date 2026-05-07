#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=
commit_created=no

pull_out=$(mktemp)
pull_status=0
if ! git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_out" 2>&1; then
  pull_status=$?
  if grep -Eqi 'timed out|timeout|temporar|TLS|connection reset|connection refused|remote end hung up|Could not resolve host|503|502|504|network|proxy|server' "$pull_out"; then
    sleep 5
    if ! git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >>"$pull_out" 2>&1; then
      cat "$pull_out"
      exit 21
    fi
  else
    cat "$pull_out"
    exit "$pull_status"
  fi
fi
if grep -q 'Already up to date.' "$pull_out"; then
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
  msg="chore: refresh backup $(date +%F)"
  git commit -m "$msg"
  commit_created=yes
  commit_hash=$(git rev-parse --short HEAD)
  push_out=$(mktemp)
  if ! git push >"$push_out" 2>&1; then
    if grep -Eqi 'timed out|timeout|temporar|TLS|connection reset|connection refused|remote end hung up|Could not resolve host|503|502|504|network|proxy|server' "$push_out"; then
      sleep 5
      if ! git push >>"$push_out" 2>&1; then
        cat "$push_out"
        exit 31
      fi
    else
      cat "$push_out"
      exit 32
    fi
  fi
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_CREATED=%s\nCOMMIT_HASH=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_created" "$commit_hash"
