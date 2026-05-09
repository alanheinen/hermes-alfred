#!/usr/bin/env bash
set -euo pipefail

TRANSIENT_RE='(Could not resolve host|Connection timed out|Operation timed out|TLS handshake timeout|HTTP 5[0-9][0-9]|remote end hung up unexpectedly|Connection reset by peer|Failed to connect|Temporary failure in name resolution|502 Bad Gateway|503 Service Unavailable|504 Gateway Timeout|internal server error|RPC failed|The requested URL returned error: 5[0-9][0-9])'

k8s_updated=no
pull_out=''
if pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1); then
  :
else
  status=$?
  if printf '%s' "$pull_out" | grep -Eiq "$TRANSIENT_RE"; then
    sleep 5
    pull_out=$(git -C /home/aheinen/.openclaw/workspace/k8s-2025 pull --ff-only 2>&1) || { printf '%s\n' "$pull_out" >&2; exit $status; }
  else
    printf '%s\n' "$pull_out" >&2
    exit $status
  fi
fi
if ! printf '%s' "$pull_out" | grep -q 'Already up to date.'; then
  k8s_updated=yes
fi

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py \
  /home/aheinen/.openclaw/openclaw.json \
  /home/aheinen/.openclaw/workspace/backups/openclaw.json
backup_refreshed=yes

cd /home/aheinen/.openclaw/workspace
git add -A

if git diff --cached --name-only | grep -Eq '(^|/)(auth-profiles\.json|openclaw\.json|openclaw\.json\.bak)$'; then
  echo 'Refusing to commit live secret-bearing file(s).' >&2
  git diff --cached --name-only | grep -E '(^|/)(auth-profiles\.json|openclaw\.json|openclaw\.json\.bak)$' >&2 || true
  exit 1
fi

workspace_changes=no
commit_hash=
if ! git diff --cached --quiet; then
  workspace_changes=yes
  msg="Daily backup $(date +%F)"
  git commit -m "$msg" >/tmp/daily_git_backup_commit.txt 2>&1
  commit_hash=$(git rev-parse --short HEAD)
  push_out=''
  if push_out=$(git push 2>&1); then
    :
  else
    status=$?
    if printf '%s' "$push_out" | grep -Eiq "$TRANSIENT_RE"; then
      sleep 5
      push_out=$(git push 2>&1) || { printf '%s\n' "$push_out" >&2; exit $status; }
    else
      printf '%s\n' "$push_out" >&2
      exit $status
    fi
  fi
fi

printf 'K8S_UPDATED=%s\n' "$k8s_updated"
printf 'BACKUP_REFRESHED=%s\n' "$backup_refreshed"
printf 'WORKSPACE_CHANGES=%s\n' "$workspace_changes"
printf 'COMMIT_HASH=%s\n' "$commit_hash"
