#!/usr/bin/env bash
set -euo pipefail

JOB_NAME="host-audit-collector"
LOGGER="/home/aheinen/.hermes/scripts/log_cron_job.sh"
COLLECTOR="/home/aheinen/.hermes/scripts/daily_host_audit.py"

"$LOGGER" "$JOB_NAME" START
if output=$(python3 "$COLLECTOR" 2>&1); then
  printf '%s\n' "$output"
  "$LOGGER" "$JOB_NAME" END
else
  status=$?
  printf '%s\n' "$output" >&2
  "$LOGGER" "$JOB_NAME" ERROR "exit=$status"
  exit "$status"
fi
