#!/usr/bin/env bash
set -euo pipefail
K8S_UPDATED=no
WORKSPACE_CHANGED=no
COMMIT_HASH=

pull_status=0
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eqi 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|remote end hung up|502|503|504|proxy|network|server'; then
    sleep 5
    pull_status=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  printf '%s\n' "$pull_output" >&2
  exit "$pull_status"
fi
if ! printf '%s' "$pull_output" | grep -q 'Already up to date.'; then
  K8S_UPDATED=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  WORKSPACE_CHANGED=yes
  msg="backup: refresh workspace $(date +%F)"
  git commit -m "$msg"
  COMMIT_HASH=$(git rev-parse --short HEAD)
  push_status=0
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eqi 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|remote end hung up|502|503|504|proxy|network|server'; then
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

printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGED=%s\nCOMMIT_HASH=%s\n' "$K8S_UPDATED" "$WORKSPACE_CHANGED" "$COMMIT_HASH"
