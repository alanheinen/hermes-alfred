#!/usr/bin/env bash
set -euo pipefail
updated=no
pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || {
  status=$?
  if printf "%s" "$pull_out" | grep -Eqi "Could not resolve host|Connection timed out|Operation timed out|Connection reset|TLS|502|503|504|remote end hung up unexpectedly|failed to connect|network is unreachable|temporary failure"; then
    sleep 5
    pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || { printf "%s\n" "$pull_out"; exit 21; }
  else
    printf "%s\n" "$pull_out"
    exit $status
  fi
}
printf "%s\n" "$pull_out"
if printf "%s" "$pull_out" | grep -qv "Already up to date."; then updated=yes; fi
python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
cd /home/aheinen/.openclaw/workspace
git add -A
if git diff --cached --quiet; then
  changes=no
  commit_hash=
else
  changes=yes
  msg="chore: refresh backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily_git_backup_commit.txt 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_out=$(git push 2>&1) || {
    status=$?
    if printf "%s" "$push_out" | grep -Eqi "Could not resolve host|Connection timed out|Operation timed out|Connection reset|TLS|502|503|504|remote end hung up unexpectedly|failed to connect|network is unreachable|temporary failure"; then
      sleep 5
      push_out=$(git push 2>&1) || { printf "%s\n" "$push_out"; exit 22; }
    else
      printf "%s\n" "$push_out"
      exit $status
    fi
  }
  printf "%s\n" "$push_out"
fi
printf "UPDATED=%s\nBACKUP=yes\nCHANGES=%s\nCOMMIT=%s\n" "$updated" "$changes" "$commit_hash"
