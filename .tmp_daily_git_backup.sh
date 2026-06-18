#!/usr/bin/env bash
set -euo pipefail
updated=no
before_head=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 rev-parse HEAD)
pull_status=0
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|connection refused|remote end hung up|TLS|HTTP 5[0-9][0-9]|proxy error|internal server error|service unavailable|bad gateway'; then
    sleep 5
    pull_status=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  printf '%s\n' "$pull_output" >&2
  exit "$pull_status"
fi
after_head=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 rev-parse HEAD)
if [ "$before_head" != "$after_head" ]; then updated=yes; fi
python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  changed=no
  commit_hash=
else
  changed=yes
  git commit -m "Refresh backup and workspace maintenance"
  commit_hash=$(git rev-parse --short HEAD)
  push_status=0
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|connection refused|remote end hung up|TLS|HTTP 5[0-9][0-9]|proxy error|internal server error|service unavailable|bad gateway'; then
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
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGED=%s\nCOMMIT_HASH=%s\n' "$updated" "$changed" "${commit_hash:-}"
