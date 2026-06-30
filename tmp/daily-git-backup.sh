#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=

pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
pull_status=${pull_status:-0}
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|TLS|remote end hung up|502|503|504|proxy error|network'; then
    sleep 5
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1)
  else
    printf '%s\n' "$pull_output" >&2
    exit "$pull_status"
  fi
fi
printf '%s\n' "$pull_output"
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
  commit_msg="chore: refresh daily backup $(date +%F)"
  git commit -m "$commit_msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || push_status=$?
  push_status=${push_status:-0}
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|TLS|remote end hung up|502|503|504|proxy error|network'; then
      sleep 5
      push_output=$(git push 2>&1)
    else
      printf '%s\n' "$push_output" >&2
      exit "$push_status"
    fi
  fi
  printf '%s\n' "$push_output"
fi

printf 'SUMMARY updated=%s backup_refreshed=%s workspace_changes=%s commit_hash=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
