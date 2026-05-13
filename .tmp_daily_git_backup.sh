#!/usr/bin/env bash
set -euo pipefail

K8S_UPDATED=unknown
BACKUP_REFRESHED=no
WORKSPACE_CHANGES=no
COMMIT_HASH=

retry_pull() {
  local out rc
  set +e
  out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1)
  rc=$?
  set -e
  printf '%s' "$out"
  return $rc
}

PULL_RC=0
PULL1=$(retry_pull) || PULL_RC=$?
if [ "$PULL_RC" -ne 0 ]; then
  if printf '%s' "$PULL1" | grep -Eiq 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|remote end hung up|TLS|HTTP 5[0-9][0-9]|502|503|504|network|proxy'; then
    sleep 5
    PULL_RC=0
    PULL2=$(retry_pull) || PULL_RC=$?
    if [ "$PULL_RC" -ne 0 ]; then
      printf 'K8S_PULL_OUTPUT<<EOF\n%s\nEOF\n' "$PULL2"
      exit 21
    fi
    PULL_OUT="$PULL2"
  else
    printf 'K8S_PULL_OUTPUT<<EOF\n%s\nEOF\n' "$PULL1"
    exit 22
  fi
else
  PULL_OUT="$PULL1"
fi

if printf '%s' "$PULL_OUT" | grep -q 'Already up to date.'; then
  K8S_UPDATED=no
else
  K8S_UPDATED=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
BACKUP_REFRESHED=yes

cd /home/aheinen/.openclaw/workspace
git add -A

if ! git diff --cached --quiet; then
  WORKSPACE_CHANGES=yes
  MSG="chore: refresh backup and daily maintenance"
  git commit -m "$MSG"
  COMMIT_HASH=$(git rev-parse --short HEAD)

  retry_push() {
    local out rc
    set +e
    out=$(git push 2>&1)
    rc=$?
    set -e
    printf '%s' "$out"
    return $rc
  }

  PUSH_RC=0
  PUSH1=$(retry_push) || PUSH_RC=$?
  if [ "$PUSH_RC" -ne 0 ]; then
    if printf '%s' "$PUSH1" | grep -Eiq 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|remote end hung up|TLS|HTTP 5[0-9][0-9]|502|503|504|network|proxy'; then
      sleep 5
      PUSH_RC=0
      PUSH2=$(retry_push) || PUSH_RC=$?
      if [ "$PUSH_RC" -ne 0 ]; then
        printf 'PUSH_OUTPUT<<EOF\n%s\nEOF\n' "$PUSH2"
        exit 23
      fi
    else
      printf 'PUSH_OUTPUT<<EOF\n%s\nEOF\n' "$PUSH1"
      exit 24
    fi
  fi
fi

printf 'K8S_UPDATED=%s\n' "$K8S_UPDATED"
printf 'BACKUP_REFRESHED=%s\n' "$BACKUP_REFRESHED"
printf 'WORKSPACE_CHANGES=%s\n' "$WORKSPACE_CHANGES"
printf 'COMMIT_HASH=%s\n' "$COMMIT_HASH"
