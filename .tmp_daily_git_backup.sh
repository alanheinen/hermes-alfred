#!/usr/bin/env bash
set -euo pipefail
status_k8s="unchanged"
backup_refreshed="no"
workspace_changes="no"
commit_hash=""

pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc=$?
pull_rc=${pull_rc:-0}
if [ "$pull_rc" -ne 0 ]; then
  sleep 5
  pull_output_retry=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc_retry=$?
  pull_rc_retry=${pull_rc_retry:-0}
  if [ "$pull_rc_retry" -ne 0 ]; then
    printf 'K8S_PULL_FAIL\n%s\n---RETRY---\n%s\n' "$pull_output" "$pull_output_retry" >&2
    exit 21
  fi
  pull_output="$pull_output_retry"
fi
if printf '%s' "$pull_output" | grep -Eq 'Updating |Fast-forward| files changed|changed,'; then
  status_k8s="updated"
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed="yes"

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes="yes"
  msg="daily backup $(date +%F)"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || push_rc=$?
  push_rc=${push_rc:-0}
  if [ "$push_rc" -ne 0 ]; then
    sleep 5
    push_output_retry=$(git push 2>&1) || push_rc_retry=$?
    push_rc_retry=${push_rc_retry:-0}
    if [ "$push_rc_retry" -ne 0 ]; then
      printf 'WORKSPACE_PUSH_FAIL\n%s\n---RETRY---\n%s\nCOMMIT=%s\n' "$push_output" "$push_output_retry" "$commit_hash" >&2
      exit 22
    fi
  fi
fi
printf 'K8S_STATUS=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$status_k8s" "$backup_refreshed" "$workspace_changes" "$commit_hash"
