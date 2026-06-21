#!/usr/bin/env bash
set -euo pipefail
K8S_UPDATED=unknown
BACKUP_REFRESHED=no
WORKSPACE_CHANGED=no
COMMIT_HASH=
COMMIT_CREATED=no

pull_output_before=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 rev-parse HEAD)
if pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1); then
  :
else
  status=$?
  if printf '%s' "$pull_output" | grep -Eiq 'Could not resolve host|Failed to connect|Connection timed out|Connection reset|remote end hung up|TLS|502 Bad Gateway|503 Service Unavailable|504 Gateway Timeout|proxy|network|timeout'; then
    sleep 5
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || { printf '%s\n' "$pull_output"; exit 21; }
  else
    printf '%s\n' "$pull_output"
    exit $status
  fi
fi
pull_output_after=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 rev-parse HEAD)
if [ "$pull_output_before" != "$pull_output_after" ]; then K8S_UPDATED=yes; else K8S_UPDATED=no; fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
BACKUP_REFRESHED=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  WORKSPACE_CHANGED=yes
  COMMIT_MSG="backup: refresh repo state $(date +%F)"
  git commit -m "$COMMIT_MSG"
  COMMIT_CREATED=yes
  COMMIT_HASH=$(git rev-parse --short HEAD)
  if push_output=$(git push 2>&1); then
    :
  else
    if printf '%s' "$push_output" | grep -Eiq 'Could not resolve host|Failed to connect|Connection timed out|Connection reset|remote end hung up|TLS|502 Bad Gateway|503 Service Unavailable|504 Gateway Timeout|proxy|network|timeout'; then
      sleep 5
      push_output=$(git push 2>&1) || { printf '%s\n' "$push_output"; exit 22; }
    else
      printf '%s\n' "$push_output"
      exit 23
    fi
  fi
else
  WORKSPACE_CHANGED=no
fi

printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGED=%s\nCOMMIT_CREATED=%s\nCOMMIT_HASH=%s\n' "$K8S_UPDATED" "$BACKUP_REFRESHED" "$WORKSPACE_CHANGED" "$COMMIT_CREATED" "$COMMIT_HASH"
