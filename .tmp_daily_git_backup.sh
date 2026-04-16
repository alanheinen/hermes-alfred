#!/usr/bin/env bash
set -euo pipefail

/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" START 100 "begin"

pull_status=0
pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_out" | grep -Eiq 'Could not resolve host|Connection timed out|Operation timed out|network is unreachable|Connection reset|TLS|HTTP/[0-9.]+ 5[0-9][0-9]|The requested URL returned error: 5[0-9][0-9]|remote end hung up unexpectedly|failed to connect|Temporary failure|server error|502|503|504'; then
    sleep 5
    pull_retry_status=0
    pull_out_retry=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || pull_retry_status=$?
    if [ "$pull_retry_status" -ne 0 ]; then
      /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "k8s pull retry failed"
      printf 'K8S_PULL_FAILED\n%s\nRETRY\n%s\n' "$pull_out" "$pull_out_retry"
      exit "$pull_retry_status"
    fi
    pull_out="$pull_out_retry"
  else
    /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "k8s pull failed"
    printf 'K8S_PULL_FAILED\n%s\n' "$pull_out"
    exit "$pull_status"
  fi
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  changed=no
  commit_hash=
else
  changed=yes
  msg="chore: refresh daily backup $(date +%F)"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_status=0
  push_out=$(git push 2>&1) || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_out" | grep -Eiq 'Could not resolve host|Connection timed out|Operation timed out|network is unreachable|Connection reset|TLS|HTTP/[0-9.]+ 5[0-9][0-9]|The requested URL returned error: 5[0-9][0-9]|remote end hung up unexpectedly|failed to connect|Temporary failure|server error|502|503|504'; then
      sleep 5
      push_retry_status=0
      push_out_retry=$(git push 2>&1) || push_retry_status=$?
      if [ "$push_retry_status" -ne 0 ]; then
        /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "workspace push retry failed"
        printf 'PUSH_FAILED\n%s\nRETRY\n%s\nCOMMIT=%s\n' "$push_out" "$push_out_retry" "$commit_hash"
        exit "$push_retry_status"
      fi
    else
      /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "workspace push failed"
      printf 'PUSH_FAILED\n%s\nCOMMIT=%s\n' "$push_out" "$commit_hash"
      exit "$push_status"
    fi
  fi
fi

printf 'K8S_RESULT<<EOF\n%s\nEOF\n' "$pull_out"
printf 'BACKUP_REFRESHED=yes\n'
printf 'WORKSPACE_CHANGED=%s\n' "$changed"
printf 'COMMIT_HASH=%s\n' "$commit_hash"

/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" END 200 "success"
