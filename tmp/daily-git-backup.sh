#!/usr/bin/env bash
set -euo pipefail

updated=no
k8s_out_1=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
pull_status=${pull_status:-0}
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$k8s_out_1" | grep -Eqi 'timed out|timeout|Temporary failure|Connection reset|Connection refused|Could not resolve host|TLS|HTTP 5[0-9]{2}|remote end hung up|Operation timed out|network|server error|RPC failed'; then
    sleep 5
    k8s_out_2=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status2=$?
    pull_status2=${pull_status2:-0}
    if [ "$pull_status2" -ne 0 ]; then
      printf 'K8S_PULL_FAILED\n%s\n--- RETRY ---\n%s\n' "$k8s_out_1" "$k8s_out_2"
      exit 21
    fi
    k8s_out="$k8s_out_2"
  else
    printf 'K8S_PULL_FAILED\n%s\n' "$k8s_out_1"
    exit 21
  fi
else
  k8s_out="$k8s_out_1"
fi
if printf '%s' "$k8s_out" | grep -q 'Already up to date.'; then
  updated=no
else
  updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  workspace_changes=no
  commit_hash=
else
  workspace_changes=yes
  commit_msg="Daily backup: $(date +%F)"
  git commit -m "$commit_msg" >/tmp/daily-git-backup-commit.log 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_out_1=$(git push 2>&1) || push_status=$?
  push_status=${push_status:-0}
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_out_1" | grep -Eqi 'timed out|timeout|Temporary failure|Connection reset|Connection refused|Could not resolve host|TLS|HTTP 5[0-9]{2}|remote end hung up|Operation timed out|network|server error|RPC failed'; then
      sleep 5
      push_out_2=$(git push 2>&1) || push_status2=$?
      push_status2=${push_status2:-0}
      if [ "$push_status2" -ne 0 ]; then
        printf 'PUSH_FAILED\n%s\n--- RETRY ---\n%s\n' "$push_out_1" "$push_out_2"
        exit 31
      fi
    else
      printf 'PUSH_FAILED\n%s\n' "$push_out_1"
      exit 31
    fi
  fi
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
