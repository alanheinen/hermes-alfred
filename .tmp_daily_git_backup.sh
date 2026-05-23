#!/usr/bin/env bash
set -euo pipefail
LOG=/home/aheinen/.openclaw/workspace/scripts/log_cron_job.sh
$LOG "daily-git-backup" START 100 "begin"

TRANSIENT_RE='(Could not resolve host|Connection timed out|Operation timed out|timed out|Connection reset|remote end hung up|TLS|SSL|502|503|504|proxy|Temporary failure|network is unreachable|Name or service not known|failed to connect|connection refused|EOF)'

K8S_UPDATED=unknown
BACKUP_REFRESHED=no
WORKSPACE_CHANGES=no
COMMIT_HASH=

cleanup() {
  rc=$?
  if [ $rc -ne 0 ]; then
    $LOG "daily-git-backup" ERROR 500 "job-failed"
  fi
  exit $rc
}
trap cleanup EXIT

run_git_pull() {
  local before after out rc
  before=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 rev-parse HEAD)
  set +e
  out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1)
  rc=$?
  set -e
  if [ $rc -ne 0 ] && printf '%s' "$out" | grep -Eiq "$TRANSIENT_RE"; then
    sleep 5
    set +e
    out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1)
    rc=$?
    set -e
  fi
  if [ $rc -ne 0 ]; then
    printf '%s\n' "$out" >&2
    return $rc
  fi
  after=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 rev-parse HEAD)
  if [ "$before" != "$after" ]; then K8S_UPDATED=yes; else K8S_UPDATED=no; fi
}

run_backup() {
  python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py \
    /home/aheinen/.openclaw/openclaw.json \
    /home/aheinen/.openclaw/workspace/backups/openclaw.json
  BACKUP_REFRESHED=yes
}

run_workspace_backup() {
  local out rc
  cd /home/aheinen/.openclaw/workspace
  git add -A
  if ! git diff --cached --quiet; then
    WORKSPACE_CHANGES=yes
    git commit -m "Daily backup refresh"
    COMMIT_HASH=$(git rev-parse --short HEAD)
    set +e
    out=$(git push 2>&1)
    rc=$?
    set -e
    if [ $rc -ne 0 ] && printf '%s' "$out" | grep -Eiq "$TRANSIENT_RE"; then
      sleep 5
      set +e
      out=$(git push 2>&1)
      rc=$?
      set -e
    fi
    if [ $rc -ne 0 ]; then
      printf '%s\n' "$out" >&2
      return $rc
    fi
  fi
}

run_git_pull
run_backup
run_workspace_backup

$LOG "daily-git-backup" END 200 "success"
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$K8S_UPDATED" "$BACKUP_REFRESHED" "$WORKSPACE_CHANGES" "$COMMIT_HASH"
