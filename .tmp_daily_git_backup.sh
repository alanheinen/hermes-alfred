#!/usr/bin/env bash
set -euo pipefail

k8s_updated="unknown"
backup_refreshed="no"
workspace_changes="no"
commit_hash=""
commit_made="no"

pull_rc=0
pull_out_1=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc=$?
if [ "$pull_rc" -ne 0 ]; then
  sleep 5
  pull_rc2=0
  pull_out_2=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_rc2=$?
  if [ "$pull_rc2" -ne 0 ]; then
    printf 'K8S_PULL_FAILED\n%s\n---RETRY---\n%s\n' "$pull_out_1" "$pull_out_2"
    exit 21
  else
    pull_out="$pull_out_2"
  fi
else
  pull_out="$pull_out_1"
fi
if printf '%s' "$pull_out" | grep -q 'Already up to date'; then
  k8s_updated="no"
else
  k8s_updated="yes"
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed="yes"

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  workspace_changes="no"
else
  workspace_changes="yes"
  commit_made="yes"
  msg="chore: daily backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily_git_backup_commit.txt 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_rc=0
  push_out_1=$(git push 2>&1) || push_rc=$?
  if [ "$push_rc" -ne 0 ]; then
    sleep 5
    push_rc2=0
    push_out_2=$(git push 2>&1) || push_rc2=$?
    if [ "$push_rc2" -ne 0 ]; then
      printf 'WORKSPACE_PUSH_FAILED\n%s\n---RETRY---\n%s\nCOMMIT_HASH=%s\n' "$push_out_1" "$push_out_2" "$commit_hash"
      exit 22
    fi
  fi
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_MADE=%s\nCOMMIT_HASH=%s\n' "$k8s_updated" "$backup_refreshed" "$workspace_changes" "$commit_made" "$commit_hash"
