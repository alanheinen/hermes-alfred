#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=

pull_status=0
pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_out" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|proxy error|tls|ssl|http 5[0-9][0-9]|remote end hung up|connection refused|network is unreachable|service unavailable|internal server error|bad gateway|gateway timeout'; then
    sleep 5
    pull_status=0
    pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  printf '%s\n' "$pull_out" >&2
  exit "$pull_status"
fi
if ! printf '%s' "$pull_out" | grep -q 'Already up to date\.'; then
  updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes=yes
  git commit -m "chore: refresh backup $(date +%F)" >/tmp/daily-git-backup-commit.txt 2>&1
  commit_hash=$(git rev-parse --short HEAD)

  push_status=0
  push_out=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_out" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|proxy error|tls|ssl|http 5[0-9][0-9]|remote end hung up|connection refused|network is unreachable|service unavailable|internal server error|bad gateway|gateway timeout'; then
      sleep 5
      push_status=0
      push_out=$(git push 2>&1) || push_status=$?
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    printf '%s\n' "$push_out" >&2
    exit "$push_status"
  fi
fi

printf 'UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
