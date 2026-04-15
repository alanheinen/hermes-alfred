#!/usr/bin/env bash
set -euo pipefail
updated=no
pull_out_before=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 rev-parse HEAD)
if ! pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1); then
  if printf '%s' "$pull_output" | grep -Eqi 'timed out|timeout|Temporary failure|Could not resolve host|Connection reset|Connection timed out|TLS|HTTP [45][0-9][0-9]|remote end hung up|proxy|server|network'; then
    sleep 5
    pull_output=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1)
  else
    printf '%s\n' "$pull_output" >&2
    exit 10
  fi
fi
pull_out_after=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 rev-parse HEAD)
[ "$pull_out_before" != "$pull_out_after" ] && updated=yes || true
python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py /home/aheinen/.openclaw/openclaw.json /home/aheinen/.openclaw/workspace/backups/openclaw.json
cd /home/aheinen/.openclaw/workspace
git add -A
if [ -n "$(git diff --cached --name-only)" ]; then
  changes=yes
  msg="chore: daily backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily-git-backup-commit.txt 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  if ! push_output=$(git push 2>&1); then
    if printf '%s' "$push_output" | grep -Eqi 'timed out|timeout|Temporary failure|Could not resolve host|Connection reset|Connection timed out|TLS|HTTP [45][0-9][0-9]|remote end hung up|proxy|server|network'; then
      sleep 5
      push_output=$(git push 2>&1)
    else
      printf '%s\n' "$push_output" >&2
      exit 20
    fi
  fi
else
  changes=no
  commit_hash=
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=yes\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$updated" "$changes" "$commit_hash"
