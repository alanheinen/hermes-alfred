#!/usr/bin/env bash
set -euo pipefail

/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" START 100 "begin"

pull_out=$(mktemp)
pull_status=0
if ! git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_out" 2>&1; then
  pull_status=$?
  if grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|connection refused|TLS|remote end hung up|502|503|504|proxy error|network is unreachable|failed to connect|operation timed out|server unexpectedly closed|EOF' "$pull_out"; then
    sleep 5
    git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >>"$pull_out" 2>&1 || pull_status=$?
  fi
fi
if [ "$pull_status" -ne 0 ]; then
  err=$(tail -n 20 "$pull_out" | tr '\n' ' ' | sed "s/\"/'/g" | cut -c1-180)
  /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "k8s pull failed: $err"
  cat "$pull_out"
  exit "$pull_status"
fi
if grep -q 'Already up to date.' "$pull_out"; then
  k8s_status='no'
else
  k8s_status='yes'
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_status='yes'

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  workspace_changes='no'
  commit_hash=''
else
  workspace_changes='yes'
  commit_msg="daily backup: refresh redacted config"
  git commit -m "$commit_msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_out=$(mktemp)
  push_status=0
  if ! git push >"$push_out" 2>&1; then
    push_status=$?
    if grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|connection refused|TLS|remote end hung up|502|503|504|proxy error|network is unreachable|failed to connect|operation timed out|server unexpectedly closed|EOF' "$push_out"; then
      sleep 5
      git push >>"$push_out" 2>&1 || push_status=$?
    fi
  fi
  if [ "$push_status" -ne 0 ]; then
    err=$(tail -n 20 "$push_out" | tr '\n' ' ' | sed "s/\"/'/g" | cut -c1-180)
    /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "workspace push failed: $err"
    cat "$push_out"
    exit "$push_status"
  fi
fi

/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" END 200 "success"
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$k8s_status" "$backup_status" "$workspace_changes" "$commit_hash"
