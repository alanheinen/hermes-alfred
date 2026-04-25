#!/usr/bin/env bash
set -euo pipefail
updated=no
pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || {
  status=$?
  if printf '%s' "$pull_output" | grep -Eiq 'Could not resolve host|Connection timed out|Operation timed out|Failed to connect|Connection reset|TLS|HTTP/[0-9.]+ 5[0-9][0-9]|The requested URL returned error: 5[0-9][0-9]|remote end hung up unexpectedly|Proxy Error|Temporary failure|network|timeout'; then
    sleep 5
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || { printf '%s\n' "$pull_output" >&2; exit 11; }
  else
    printf '%s\n' "$pull_output" >&2
    exit $status
  fi
}
printf '%s\n' "$pull_output"
if ! printf '%s' "$pull_output" | grep -q 'Already up to date.'; then
  updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  had_changes=no
  commit_hash=
else
  had_changes=yes
  commit_msg="chore: daily backup $(date +%F)"
  git commit -m "$commit_msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || {
    status=$?
    if printf '%s' "$push_output" | grep -Eiq 'Could not resolve host|Connection timed out|Operation timed out|Failed to connect|Connection reset|TLS|HTTP/[0-9.]+ 5[0-9][0-9]|The requested URL returned error: 5[0-9][0-9]|remote end hung up unexpectedly|Proxy Error|Temporary failure|network|timeout'; then
      sleep 5
      push_output=$(git push 2>&1) || { printf '%s\n' "$push_output" >&2; exit 12; }
    else
      printf '%s\n' "$push_output" >&2
      exit $status
    fi
  }
  printf '%s\n' "$push_output"
fi
printf 'UPDATED=%s\nREFRESHED=yes\nHAD_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$had_changes" "${commit_hash:-}"
