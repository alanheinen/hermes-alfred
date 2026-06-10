#!/usr/bin/env bash
set -euo pipefail
k8s_dir=/home/aheinen/.openclaw/workspace/k8s-2025
backup_src=/home/aheinen/.openclaw/openclaw.json
backup_dst=/home/aheinen/.openclaw/workspace/backups/openclaw.json
workspace_dir=/home/aheinen/.openclaw/workspace

k8s_before=$(git -C "$k8s_dir" rev-parse HEAD)
k8s_pull_output=$(git -C "$k8s_dir" pull --ff-only 2>&1) || {
  status=$?
  if printf '%s' "$k8s_pull_output" | grep -Eiq 'Could not resolve host|Failed to connect|Connection timed out|Connection reset|TLS|HTTP 5[0-9][0-9]|The requested URL returned error: 5[0-9][0-9]|remote end hung up unexpectedly|Operation timed out'; then
    sleep 5
    k8s_pull_output=$(git -C "$k8s_dir" pull --ff-only 2>&1) || { printf '%s\n' "$k8s_pull_output"; exit $?; }
  else
    printf '%s\n' "$k8s_pull_output"
    exit $status
  fi
}
k8s_after=$(git -C "$k8s_dir" rev-parse HEAD)
if [ "$k8s_before" = "$k8s_after" ]; then
  echo "K8S_UPDATED=no"
else
  echo "K8S_UPDATED=yes"
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py "$backup_src" "$backup_dst"
echo "BACKUP_REFRESHED=yes"

cd "$workspace_dir"
git add -A
if git diff --cached --quiet; then
  echo "WORKSPACE_CHANGES=no"
  echo "WORKSPACE_COMMIT="
else
  commit_msg="chore: daily backup $(date +%F)"
  git commit -m "$commit_msg" >/tmp/daily-git-backup-commit.log 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(git push 2>&1) || {
    status=$?
    if printf '%s' "$push_output" | grep -Eiq 'Could not resolve host|Failed to connect|Connection timed out|Connection reset|TLS|HTTP 5[0-9][0-9]|The requested URL returned error: 5[0-9][0-9]|remote end hung up unexpectedly|Operation timed out'; then
      sleep 5
      push_output=$(git push 2>&1) || { printf '%s\n' "$push_output"; exit $?; }
    else
      printf '%s\n' "$push_output"
      exit $status
    fi
  }
  echo "WORKSPACE_CHANGES=yes"
  echo "WORKSPACE_COMMIT=$commit_hash"
fi
