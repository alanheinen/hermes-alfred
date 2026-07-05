#!/usr/bin/env bash
set -euo pipefail

pull_status=unchanged
pull_rc=0
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc=$?
if [ "$pull_rc" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eqi 'timed out|timeout|Temporary failure|Connection reset|Connection refused|Could not resolve host|TLS|HTTP 5[0-9][0-9]|remote end hung up|unexpected disconnect|proxy error|internal server error|service unavailable|network is unreachable'; then
    sleep 5
    pull_rc=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc=$?
  fi
fi
if [ "$pull_rc" -ne 0 ]; then
  printf 'PULL_FAILED\n%s\n' "$pull_output"
  exit "$pull_rc"
fi
if ! printf '%s' "$pull_output" | grep -q 'Already up to date.'; then
  pull_status=updated
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  workspace_changes=no
  commit_hash=
else
  workspace_changes=yes
  git commit -m "chore: refresh daily backup"
  commit_hash=$(git rev-parse --short HEAD)
  push_rc=0
  push_output=$(git push 2>&1) || push_rc=$?
  if [ "$push_rc" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eqi 'timed out|timeout|Temporary failure|Connection reset|Connection refused|Could not resolve host|TLS|HTTP 5[0-9][0-9]|remote end hung up|unexpected disconnect|proxy error|internal server error|service unavailable|network is unreachable'; then
      sleep 5
      push_rc=0
      push_output=$(git push 2>&1) || push_rc=$?
    fi
  fi
  if [ "$push_rc" -ne 0 ]; then
    printf 'PUSH_FAILED\n%s\nCOMMIT_HASH=%s\n' "$push_output" "$commit_hash"
    exit "$push_rc"
  fi
fi

printf 'PULL_STATUS=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$pull_status" "$workspace_changes" "$commit_hash"
