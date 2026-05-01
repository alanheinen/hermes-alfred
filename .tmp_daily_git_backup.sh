#!/usr/bin/env bash
set -euo pipefail
updated_k8s=no
backup_refreshed=no
workspace_changes=no
commit_hash=
commit_created=no

pull_out=$(mktemp)
if git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_out" 2>&1; then
  :
else
  status=$?
  if grep -Eiq 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|remote end hung up|proxy error|502|503|504|TLS|ssh_exchange_identification|Connection reset by peer' "$pull_out"; then
    sleep 5
    git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >>"$pull_out" 2>&1
  else
    cat "$pull_out"
    exit $status
  fi
fi
if grep -q 'Already up to date.' "$pull_out"; then
  updated_k8s=no
else
  updated_k8s=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A
if ! git diff --cached --quiet; then
  workspace_changes=yes
  msg="backup: refresh redacted config and workspace updates"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_out=$(mktemp)
  if git push >"$push_out" 2>&1; then
    :
  else
    status=$?
    if grep -Eiq 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|remote end hung up|proxy error|502|503|504|TLS|ssh_exchange_identification|Connection reset by peer' "$push_out"; then
      sleep 5
      git push >>"$push_out" 2>&1
    else
      cat "$push_out"
      exit $status
    fi
  fi
  commit_created=yes
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_CREATED=%s\nCOMMIT_HASH=%s\n' "$updated_k8s" "$backup_refreshed" "$workspace_changes" "$commit_created" "$commit_hash"
