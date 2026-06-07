#!/usr/bin/env bash
set -euo pipefail
updated=no
pull_output=$(mktemp)
if git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_output" 2>&1; then
  :
else
  if grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection.*reset|connection.*refused|tls|http 5[0-9][0-9]|remote end hung up|proxy error|network is unreachable|service unavailable|internal server error' "$pull_output"; then
    sleep 5
    git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only >"$pull_output" 2>&1
  else
    cat "$pull_output"
    exit 1
  fi
fi
if ! grep -q 'Already up to date\.' "$pull_output"; then
  updated=yes
fi
python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  had_changes=no
  commit_hash=
else
  had_changes=yes
  git commit -m "chore: refresh backup and workspace updates" >/tmp/daily-git-backup-commit.log 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_output=$(mktemp)
  if git push >"$push_output" 2>&1; then
    :
  else
    if grep -Eqi 'timed out|timeout|temporary failure|could not resolve host|connection.*reset|connection.*refused|tls|http 5[0-9][0-9]|remote end hung up|proxy error|network is unreachable|service unavailable|internal server error' "$push_output"; then
      sleep 5
      git push >"$push_output" 2>&1
    else
      cat "$push_output"
      exit 1
    fi
  fi
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$had_changes" "$commit_hash"
