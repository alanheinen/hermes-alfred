#!/usr/bin/env bash
set -euo pipefail

updated_k8s=no
pull_out=$(mktemp)
if git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_out" 2>&1; then
  :
else
  if grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|remote end hung up|502|503|504|TLS|network|Connection closed by remote host' "$pull_out"; then
    sleep 5
    git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >>"$pull_out" 2>&1
  else
    cat "$pull_out"
    exit 1
  fi
fi
if grep -q 'Already up to date\.' "$pull_out"; then
  updated_k8s=no
else
  updated_k8s=yes
fi
printf 'K8S_UPDATED=%s\n' "$updated_k8s"
cat "$pull_out"

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
printf 'BACKUP_REFRESHED=yes\n'

cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  printf 'WORKSPACE_CHANGED=no\n'
else
  printf 'WORKSPACE_CHANGED=yes\n'
  msg="Daily backup $(date +%F)"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  printf 'COMMIT_HASH=%s\n' "$commit_hash"
  push_out=$(mktemp)
  if git push >"$push_out" 2>&1; then
    :
  else
    if grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection reset|connection timed out|remote end hung up|502|503|504|TLS|network|Connection closed by remote host' "$push_out"; then
      sleep 5
      git push >>"$push_out" 2>&1
    else
      cat "$push_out"
      exit 1
    fi
  fi
  cat "$push_out"
fi
