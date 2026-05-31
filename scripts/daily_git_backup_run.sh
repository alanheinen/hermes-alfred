#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=
commit_made=no
pull_status=0
push_status=0

pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eiq 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|network is unreachable|remote end hung up|502|503|504|TLS|proxy error|internal server error|service unavailable'; then
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

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py \
  /home/aheinen/.openclaw/openclaw.json \
  /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes=yes
  msg="chore: daily backup $(date -u +%Y-%m-%d)"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eiq 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|network is unreachable|remote end hung up|502|503|504|TLS|proxy error|internal server error|service unavailable'; then
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
printf 'k8s_updated=%s\nbackup_refreshed=%s\nworkspace_changes=%s\ncommit_hash=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
