#!/usr/bin/env bash
set -euo pipefail
K8S_REPO=/home/aheinen/.openclaw/workspace/k8s-2025
WS_REPO=/home/aheinen/.openclaw/workspace
SRC_CFG=/home/aheinen/.openclaw/openclaw.json
DST_CFG=/home/aheinen/.openclaw/workspace/backups/openclaw.json

k8s_before=$(git -C "$K8S_REPO" rev-parse HEAD)
k8s_updated=no
pull_rc=0
pull_output=$(git -C "$K8S_REPO" pull --ff-only 2>&1) || pull_rc=$?
if [ "$pull_rc" -ne 0 ]; then
  case "$pull_output" in
    *"Could not resolve host"*|*"Connection timed out"*|*"Operation timed out"*|*"Failed to connect"*|*"Connection reset"*|*"TLS handshake timeout"*|*"The requested URL returned error: 5"*|*"remote end hung up unexpectedly"*|*"HTTP code = 5"*|*"server error"*)
      sleep 5
      git -C "$K8S_REPO" pull --ff-only
      ;;
    *)
      printf '%s\n' "$pull_output" >&2
      exit "$pull_rc"
      ;;
  esac
fi
k8s_after=$(git -C "$K8S_REPO" rev-parse HEAD)
[ "$k8s_before" != "$k8s_after" ] && k8s_updated=yes || true

python3 /home/aheinen/.openclaw/workspace/scripts/redact_openclaw_config.py "$SRC_CFG" "$DST_CFG"
backup_refreshed=yes

cd "$WS_REPO"
git add -A
post_status=$(git status --porcelain)
workspace_changes=no
commit_hash=
if [ -n "$post_status" ]; then
  workspace_changes=yes
  msg="backup: refresh redacted config and daily maintenance"
  git commit -m "$msg"
  commit_hash=$(git rev-parse --short HEAD)
  push_rc=0
  push_output=$(git push 2>&1) || push_rc=$?
  if [ "$push_rc" -ne 0 ]; then
    case "$push_output" in
      *"Could not resolve host"*|*"Connection timed out"*|*"Operation timed out"*|*"Failed to connect"*|*"Connection reset"*|*"TLS handshake timeout"*|*"The requested URL returned error: 5"*|*"remote end hung up unexpectedly"*|*"HTTP code = 5"*|*"server error"*)
        sleep 5
        git push
        ;;
      *)
        printf '%s\n' "$push_output" >&2
        exit "$push_rc"
        ;;
    esac
  fi
fi
printf 'K8S_UPDATED=%s\nBACKUP_REFRESHED=%s\nWORKSPACE_CHANGES=%s\nCOMMIT_HASH=%s\n' "$k8s_updated" "$backup_refreshed" "$workspace_changes" "$commit_hash"
