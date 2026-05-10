#!/usr/bin/env bash
set -euo pipefail
LOG='/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh'
$LOG 'daily-git-backup' START 100 'begin'

k8s_updated='unknown'
backup_refreshed='no'
workspace_changes='no'
commit_hash=''

retry_pull() {
  local out rc
  set +e
  out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1)
  rc=$?
  set -e
  printf '%s' "$out"
  return $rc
}

pull_out=$(retry_pull) || {
  if printf '%s' "$pull_out" | grep -Eqi 'timed out|timeout|could not resolve host|temporary failure|connection reset|connection timed out|network is unreachable|remote end hung up|TLS|502|503|504|proxy error|Connection closed by remote host'; then
    sleep 5
    pull_out=$(retry_pull) || {
      "$LOG" 'daily-git-backup' ERROR 500 'k8s pull failed after retry'
      printf '%s\n' "$pull_out" >&2
      exit 1
    }
  else
    "$LOG" 'daily-git-backup' ERROR 500 'k8s pull failed'
    printf '%s\n' "$pull_out" >&2
    exit 1
  fi
}
if printf '%s' "$pull_out" | grep -q 'Already up to date.'; then
  k8s_updated='no'
else
  k8s_updated='yes'
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py \
  /home/aheinen/.openclaw/openclaw.json \
  /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed='yes'

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  workspace_changes='no'
else
  workspace_changes='yes'
  msg="Daily backup: $(date +%F)"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  retry_push() {
    local out rc
    set +e
    out=$(git push 2>&1)
    rc=$?
    set -e
    printf '%s' "$out"
    return $rc
  }
  push_out=$(retry_push) || {
    if printf '%s' "$push_out" | grep -Eqi 'timed out|timeout|could not resolve host|temporary failure|connection reset|connection timed out|network is unreachable|remote end hung up|TLS|502|503|504|proxy error|Connection closed by remote host'; then
      sleep 5
      push_out=$(retry_push) || {
        "$LOG" 'daily-git-backup' ERROR 500 'workspace push failed after retry'
        printf '%s\n' "$push_out" >&2
        exit 1
      }
    else
      "$LOG" 'daily-git-backup' ERROR 500 'workspace push failed'
      printf '%s\n' "$push_out" >&2
      exit 1
    fi
  }
fi

$LOG 'daily-git-backup' END 200 'success'
printf 'k8s_updated=%s\nbackup_refreshed=%s\nworkspace_changes=%s\ncommit_hash=%s\n' "$k8s_updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
