#!/usr/bin/env bash
set -euo pipefail
status_k8s="unchanged"
backup_refreshed="no"
workspace_changes="no"
commit_hash=""

pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || {
  rc=$?
  if printf "%s" "$pull_output" | grep -Eqi "(Could not resolve host|Connection timed out|Operation timed out|TLS|SSL|Connection reset|remote end hung up|502 Bad Gateway|503 Service Unavailable|504 Gateway Timeout|network is unreachable|Failed to connect|Proxy Error|fatal: unable to access)"; then
    sleep 5
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || {
      printf "K8S_PULL_FAILED\n%s\n" "$pull_output"
      exit 21
    }
  else
    printf "K8S_PULL_FAILED\n%s\n" "$pull_output"
    exit "$rc"
  fi
}
if printf "%s" "$pull_output" | grep -q "Already up to date."; then
  status_k8s="unchanged"
else
  status_k8s="updated"
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed="yes"

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes="yes"
  msg="chore: daily backup $(date +%F)"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || {
    rc=$?
    if printf "%s" "$push_output" | grep -Eqi "(Could not resolve host|Connection timed out|Operation timed out|TLS|SSL|Connection reset|remote end hung up|502 Bad Gateway|503 Service Unavailable|504 Gateway Timeout|network is unreachable|Failed to connect|Proxy Error|fatal: unable to access)"; then
      sleep 5
      push_output=$(git push 2>&1) || {
        printf "WORKSPACE_PUSH_FAILED\n%s\nCOMMIT_HASH=%s\n" "$push_output" "$commit_hash"
        exit 22
      }
    else
      printf "WORKSPACE_PUSH_FAILED\n%s\nCOMMIT_HASH=%s\n" "$push_output" "$commit_hash"
      exit "$rc"
    fi
  }
fi

printf "K8S_STATUS=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\n" "$status_k8s" "$backup_refreshed" "$workspace_changes"
if [ -n "$commit_hash" ]; then
  printf "COMMIT_HASH=%s\n" "$commit_hash"
fi
