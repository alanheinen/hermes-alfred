#!/usr/bin/env bash
set -euo pipefail
TRANSIENT_RE='Could not resolve host|Connection timed out|Operation timed out|TLS|SSL|502 Bad Gateway|503 Service Unavailable|504 Gateway Time-out|Connection reset|remote end hung up unexpectedly|Failed to connect|network is unreachable|Temporary failure|proxy error|HTTP 5[0-9][0-9]'

k8s_updated=no
backup_refreshed=no
workspace_changes=no
commit_hash=

pull_output_file=$(mktemp)
if git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_output_file" 2>&1; then
  :
else
  if grep -Eiq "$TRANSIENT_RE" "$pull_output_file"; then
    sleep 5
    git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >>"$pull_output_file" 2>&1
  else
    cat "$pull_output_file"
    exit 1
  fi
fi
if grep -q 'Already up to date\.' "$pull_output_file"; then
  k8s_updated=no
else
  k8s_updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  workspace_changes=no
else
  workspace_changes=yes
  git commit -m "chore: refresh backup $(date +%F)"
  commit_hash=$(git rev-parse --short HEAD)
  push_output_file=$(mktemp)
  if git push >"$push_output_file" 2>&1; then
    :
  else
    if grep -Eiq "$TRANSIENT_RE" "$push_output_file"; then
      sleep 5
      git push >>"$push_output_file" 2>&1
    else
      cat "$push_output_file"
      exit 1
    fi
  fi
fi

printf 'K8S_UPDATED=%s\n' "$k8s_updated"
printf 'BACKUP_REFRESHED=%s\n' "$backup_refreshed"
printf 'WORKSPACE_CHANGES=%s\n' "$workspace_changes"
printf 'COMMIT_HASH=%s\n' "$commit_hash"
