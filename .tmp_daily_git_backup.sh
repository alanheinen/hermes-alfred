#!/usr/bin/env bash
set -euo pipefail
/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" START 100 "begin"

k8s_updated="no"
workspace_changes="no"
commit_hash=""

pull_status=0
pull_output_1="$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1)" || pull_status=$?
if [ "$pull_status" -ne 0 ]; then
  if printf '%s' "$pull_output_1" | grep -Eiq 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|remote end hung up|502|503|504|proxy|network|unable to access'; then
    sleep 5
    pull_status2=0
    pull_output_2="$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1)" || pull_status2=$?
    if [ "$pull_status2" -ne 0 ]; then
      /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "k8s pull retry failed"
      printf 'K8S_PULL_STATUS=error\nK8S_PULL_OUTPUT<<EOF\n%s\n--- RETRY ---\n%s\nEOF\n' "$pull_output_1" "$pull_output_2"
      exit 1
    fi
    pull_output="$pull_output_2"
  else
    /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "k8s pull failed"
    printf 'K8S_PULL_STATUS=error\nK8S_PULL_OUTPUT<<EOF\n%s\nEOF\n' "$pull_output_1"
    exit 1
  fi
else
  pull_output="$pull_output_1"
fi
if ! printf '%s' "$pull_output" | grep -q 'Already up to date.'; then
  k8s_updated="yes"
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes="yes"
  msg="chore: daily backup $(date +%F)"
  git commit -m "$msg"
  commit_hash="$(git rev-parse --short HEAD)"
  push_status=0
  push_output_1="$(git push 2>&1)" || push_status=$?
  if [ "$push_status" -ne 0 ]; then
    if printf '%s' "$push_output_1" | grep -Eiq 'timed out|timeout|temporar|TLS|Connection reset|Connection refused|Could not resolve host|remote end hung up|502|503|504|proxy|network|unable to access'; then
      sleep 5
      push_status2=0
      push_output_2="$(git push 2>&1)" || push_status2=$?
      if [ "$push_status2" -ne 0 ]; then
        /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "workspace push retry failed"
        printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\nPUSH_STATUS=error\nPUSH_OUTPUT<<EOF\n%s\n--- RETRY ---\n%s\nEOF\n' "$k8s_updated" "$workspace_changes" "$commit_hash" "$push_output_1" "$push_output_2"
        exit 1
      fi
    else
      /home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" ERROR 500 "workspace push failed"
      printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\nPUSH_STATUS=error\nPUSH_OUTPUT<<EOF\n%s\nEOF\n' "$k8s_updated" "$workspace_changes" "$commit_hash" "$push_output_1"
      exit 1
    fi
  fi
fi

/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh "daily-git-backup" END 200 "success"
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$k8s_updated" "$workspace_changes" "$commit_hash"
