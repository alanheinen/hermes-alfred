#!/usr/bin/env bash
set -euo pipefail

/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" START 100 "begin"

updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=
pull_status=0
push_status=0

pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output" | grep -Eiq 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|network|remote end hung up|502|503|504|server error|proxy'; then
    sleep 5
    pull_status=0
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "k8s-2025 pull failed"
  printf '%s\n' "$pull_output"
  exit "$pull_status"
fi
if ! printf '%s' "$pull_output" | grep -q 'Already up to date.'; then
  updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes=yes
  commit_msg="backup: refresh workspace state $(date +%F)"
  git commit -m "$commit_msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output" | grep -Eiq 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|network|remote end hung up|502|503|504|server error|proxy'; then
      sleep 5
      push_status=0
      push_output=$(git push 2>&1) || push_status=$?
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "workspace push failed"
    printf '%s\n' "$push_output"
    exit "$push_status"
  fi
fi

/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" END 200 "success"
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
