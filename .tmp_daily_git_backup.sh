#!/usr/bin/env bash
set -euo pipefail
updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=

pull_status=0
pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_out" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|proxy error|TLS|HTTP 5[0-9][0-9]|502|503|504|remote end hung up|failed to connect'; then
    sleep 5
    git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only
  else
    printf '%s\n' "$pull_out" >&2
    exit 1
  fi
else
  if ! printf '%s' "$pull_out" | grep -q 'Already up to date.'; then
    updated=yes
  fi
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes=yes
  msg="backup: refresh redacted config and daily workspace updates"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_status=0
  push_out=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_out" | grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|proxy error|TLS|HTTP 5[0-9][0-9]|502|503|504|remote end hung up|failed to connect'; then
      sleep 5
      git push
    else
      printf '%s\n' "$push_out" >&2
      exit 1
    fi
  fi
fi

printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
