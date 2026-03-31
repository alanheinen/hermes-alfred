#!/usr/bin/env bash
set -euo pipefail

job_name="${1:-unknown-job}"
event="${2:-EVENT}"
status="${3:--}"
detail="${4:--}"
log_dir="/home/aheinen/.openclaw/logs"
log_file="$log_dir/cron-jobs.log"
hostname_value="$(hostname -s 2>/dev/null || hostname || echo localhost)"
timestamp="$(date '+%d/%b/%Y:%H:%M:%S %z')"
mkdir -p "$log_dir"
printf '%s - cron [%s] "JOB %s %s" %s - "%s"\n' "$hostname_value" "$timestamp" "$job_name" "$event" "$status" "$detail" >> "$log_file"
