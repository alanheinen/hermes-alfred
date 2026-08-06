#!/usr/bin/env python3
"""Collect bounded, read-only log, security, and patch evidence from AWX hosts."""

from __future__ import annotations

import base64
import concurrent.futures
import datetime as dt
import json
import os
import re
import shlex
import subprocess
import tempfile
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path
from typing import Any

import yaml

AWX_BASE = "https://awx.heinenshome.com/api/v2"
AWX_INVENTORY_ID = 2
SSH_KEY = Path.home() / ".ssh/id_ed25519_alfred_infrastructure"
ENV_FILE = Path.home() / ".hermes/.env"
OUTPUT_DIR = Path.home() / ".hermes/cron"
JSON_OUTPUT = OUTPUT_DIR / "host-audit-latest.json"
MD_OUTPUT = OUTPUT_DIR / "host-audit-latest.md"
STALE_DAYS = 14
MAX_WORKERS = 8

EXPECTED_DENIED = {
    "homeassistant.lan",
    "kvm-vm01.lan",
    "OPNsense.lan",
    "slate1.lan",
    "slate2.lan",
}
EXPECTED_NO_SSH = {
    "k8s.lan",
    "Legion.lan",
    "m920q01.lan",
    "oob-five.lan",
    "oob-four.lan",
    "oob-m920q01.lan",
    "oob-one.lan",
    "oob-three.lan",
    "oob-two.lan",
}
EXPECTED_EXCLUSIONS = EXPECTED_DENIED | EXPECTED_NO_SSH

REMOTE_CODE = r'''
import datetime as dt
import glob
import gzip
import json
import os
import pathlib
import subprocess


def run(argv, limit=120, timeout=25):
    try:
        p = subprocess.run(argv, text=True, capture_output=True, timeout=timeout)
        lines = (p.stdout + ("\n" + p.stderr if p.stderr else "")).splitlines()
        return {"rc": p.returncode, "lines": lines[-limit:]}
    except Exception as exc:
        return {"rc": 255, "lines": [f"collector error: {type(exc).__name__}: {exc}"]}


def read_apt_history():
    rows = []
    mtimes = []
    for name in glob.glob("/var/log/apt/history.log*"):
        try:
            mtimes.append(os.path.getmtime(name))
            opener = gzip.open if name.endswith(".gz") else open
            with opener(name, "rt", errors="replace") as handle:
                rows.extend(
                    line.rstrip() for line in handle
                    if line.startswith(("Start-Date:", "End-Date:", "Commandline:", "Upgrade:", "Install:"))
                )
        except OSError:
            pass
    return rows[-100:], max(mtimes, default=None)

os_release = {}
try:
    for line in pathlib.Path("/etc/os-release").read_text(errors="replace").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            os_release[key] = value.strip().strip('"')
except OSError:
    pass

apt_history, apt_history_mtime = read_apt_history()
package_manager = "apt" if pathlib.Path("/usr/bin/apt").exists() else "dnf" if pathlib.Path("/usr/bin/dnf").exists() else "unknown"
if package_manager == "apt":
    pending = run(["apt", "list", "--upgradable"], limit=220)
    pending_lines = [line for line in pending["lines"] if "/" in line and not line.startswith("Listing")]
    pending_count = len(pending_lines)
    pending_sample = pending_lines[:20]
elif package_manager == "dnf":
    pending = run(["dnf", "-q", "check-update"], limit=220)
    pending_lines = [line for line in pending["lines"] if line and not line.startswith(("Last metadata", "Obsoleting"))]
    pending_count = len(pending_lines)
    pending_sample = pending_lines[:20]
else:
    pending_count = None
    pending_sample = []

result = {
    "collected_at": dt.datetime.now(dt.timezone.utc).isoformat(),
    "hostname": run(["hostname", "-f"], limit=3)["lines"],
    "os": {"id": os_release.get("ID"), "version": os_release.get("VERSION_ID"), "pretty": os_release.get("PRETTY_NAME")},
    "kernel": run(["uname", "-r"], limit=3)["lines"],
    "boot": run(["uptime", "-s"], limit=3)["lines"],
    "package_manager": package_manager,
    "apt_history": apt_history,
    "last_patch_epoch": apt_history_mtime,
    "pending_updates": pending_count,
    "pending_sample": pending_sample,
    "reboot_required": pathlib.Path("/var/run/reboot-required").exists(),
    "failed_units": run(["systemctl", "--failed", "--no-legend", "--plain"], limit=50),
    "journal_warnings": run(["journalctl", "--since", "24 hours ago", "-p", "0..4", "--no-pager", "-o", "short-iso", "-n", "160"], limit=160),
    "auth_log": run(["journalctl", "--since", "24 hours ago", "-u", "ssh", "-u", "sshd", "--no-pager", "-o", "short-iso", "-n", "180"], limit=180),
    "kernel_warnings": run(["journalctl", "-k", "--since", "24 hours ago", "-p", "0..4", "--no-pager", "-o", "short-iso", "-n", "100"], limit=100),
    "disk": run(["df", "-P", "-x", "tmpfs", "-x", "devtmpfs"], limit=80),
    "listeners": run(["ss", "-lntupH"], limit=120),
}
print(json.dumps(result))
'''
REMOTE_PAYLOAD = base64.b64encode(REMOTE_CODE.encode()).decode()

SECRET_RE = re.compile(
    r"(?i)(password|passwd|token|authorization|secret|api[_-]?key)(\s*[:=]\s*)(\S+)"
)
IP_RE = re.compile(r"\b(?:from|rhost=)(?:\s*)(([0-9]{1,3}\.){3}[0-9]{1,3})\b", re.I)
AUTH_FAILURE_RE = re.compile(r"failed password|invalid user|authentication failure|maximum authentication attempts", re.I)
AUTH_SUCCESS_RE = re.compile(r"accepted (publickey|password)", re.I)


def redact_line(line: str) -> str:
    return SECRET_RE.sub(r"\1\2[REDACTED]", line)[:1000]


def load_token() -> str:
    for raw in ENV_FILE.read_text().splitlines():
        if raw.startswith("AWX_TOKEN="):
            return raw.split("=", 1)[1].strip().strip('"').strip("'")
    raise RuntimeError("AWX_TOKEN is missing")


class Awx:
    def __init__(self, token: str) -> None:
        self.token = token

    def get(self, path: str) -> dict[str, Any]:
        if path.startswith("http"):
            url = path
        elif path.startswith("/api/"):
            url = "https://awx.heinenshome.com" + path
        else:
            url = AWX_BASE + path
        request = urllib.request.Request(
            url,
            headers={"Authorization": f"Bearer {self.token}", "Accept": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)

    def all(self, path: str, max_pages: int = 20) -> list[dict[str, Any]]:
        rows: list[dict[str, Any]] = []
        for _ in range(max_pages):
            data = self.get(path)
            rows.extend(data.get("results", []))
            path = data.get("next")
            if not path:
                break
        return rows


def parse_vars(raw: Any) -> dict[str, Any]:
    if not raw:
        return {}
    if isinstance(raw, dict):
        return raw
    try:
        return json.loads(raw)
    except (TypeError, json.JSONDecodeError):
        return yaml.safe_load(raw) or {}


def ssh_base(target: str, port: str, user: str, known_hosts: str) -> list[str]:
    return [
        "ssh", "-i", str(SSH_KEY), "-p", port,
        "-o", "IdentitiesOnly=yes", "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=7", "-o", "ConnectionAttempts=1",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", f"UserKnownHostsFile={known_hosts}", f"{user}@{target}",
    ]


def audit_host(host: dict[str, Any], known_hosts: str) -> dict[str, Any]:
    name = host["name"]
    if name in EXPECTED_EXCLUSIONS:
        return {
            "name": name,
            "status": "expected_excluded",
            "reason": "denied_by_design" if name in EXPECTED_DENIED else "no_ssh_by_design",
        }

    variables = parse_vars(host.get("variables"))
    target = str(variables.get("ansible_host") or name)
    port = str(variables.get("ansible_port") or variables.get("ssh_port") or 22)
    users: list[str] = []
    for user in (variables.get("ansible_user"), "root", "aheinen"):
        if user and str(user) not in users:
            users.append(str(user))

    failures: list[str] = []
    for user in users:
        base = ssh_base(target, port, user, known_hosts)
        probe = subprocess.run(base + ["true"], text=True, capture_output=True, timeout=12)
        if probe.returncode:
            failures.append(redact_line(probe.stderr.strip().splitlines()[-1] if probe.stderr.strip() else "SSH failed"))
            continue
        remote_python = f"import base64;exec(base64.b64decode('{REMOTE_PAYLOAD}'))"
        commands = []
        if user != "root":
            commands.append(["sudo", "-n", "python3", "-c", remote_python])
        commands.append(["python3", "-c", remote_python])
        for remote_command in commands:
            run = subprocess.run(
                base + [shlex.join(remote_command)], text=True, capture_output=True, timeout=75
            )
            if run.returncode:
                failures.append(redact_line(run.stderr.strip().splitlines()[-1] if run.stderr.strip() else "audit command failed"))
                continue
            try:
                evidence = json.loads(run.stdout.strip().splitlines()[-1])
            except (json.JSONDecodeError, IndexError):
                failures.append("remote audit returned invalid JSON")
                continue
            privileged = remote_command[0] == "sudo" or user == "root"
            return summarize_host(name, target, port, user, privileged, evidence)
    return {"name": name, "target": target, "status": "unexpected_unreachable", "errors": failures[-3:]}


def summarize_host(
    name: str, target: str, port: str, user: str, privileged: bool, evidence: dict[str, Any]
) -> dict[str, Any]:
    def lines(key: str) -> list[str]:
        return [redact_line(line) for line in evidence.get(key, {}).get("lines", []) if line.strip()]

    auth = lines("auth_log")
    failures = [line for line in auth if AUTH_FAILURE_RE.search(line)]
    successes = [line for line in auth if AUTH_SUCCESS_RE.search(line)]
    source_ips = Counter(match.group(1) for line in failures if (match := IP_RE.search(line)))
    warnings = lines("journal_warnings")
    kernel = lines("kernel_warnings")
    failed_units = [
        line for line in lines("failed_units")
        if "0 loaded units listed" not in line and "UNIT LOAD ACTIVE SUB DESCRIPTION" not in line
    ]
    disk_high: list[str] = []
    for line in lines("disk"):
        fields = line.split()
        if len(fields) >= 5 and fields[4].endswith("%"):
            try:
                if int(fields[4][:-1]) >= 90:
                    disk_high.append(line)
            except ValueError:
                pass
    patch_epoch = evidence.get("last_patch_epoch")
    patch_age_days = None
    if patch_epoch:
        patch_age_days = round((dt.datetime.now(dt.timezone.utc).timestamp() - float(patch_epoch)) / 86400, 1)
    return {
        "name": name,
        "target": target,
        "port": int(port),
        "user": user,
        "status": "reachable",
        "privileged_logs": privileged,
        "os": evidence.get("os", {}),
        "kernel": evidence.get("kernel", []),
        "boot": evidence.get("boot", []),
        "package_manager": evidence.get("package_manager"),
        "last_patch_epoch": patch_epoch,
        "patch_age_days": patch_age_days,
        "pending_updates": evidence.get("pending_updates"),
        "pending_sample": [redact_line(x) for x in evidence.get("pending_sample", [])[:10]],
        "reboot_required": bool(evidence.get("reboot_required")),
        "failed_units": failed_units[:20],
        "disk_high": disk_high[:20],
        "journal_warning_count": len(warnings),
        "journal_warning_sample": warnings[-30:],
        "kernel_warning_count": len(kernel),
        "kernel_warning_sample": kernel[-20:],
        "auth_failure_count": len(failures),
        "auth_failure_sources": source_ips.most_common(10),
        "auth_failure_sample": failures[-20:],
        "accepted_login_count": len(successes),
        "accepted_login_sample": successes[-15:],
        "listeners": lines("listeners")[:80],
        "apt_history_tail": [redact_line(x) for x in evidence.get("apt_history", [])[-30:]],
    }


def collect_awx_patch_data(awx: Awx, reachable_names: set[str]) -> dict[str, Any]:
    templates = awx.all("/unified_job_templates/?page_size=200")
    patch_templates = {
        row["id"]: row for row in templates
        if "patch" in row.get("name", "").lower() or "upgrade apps" in row.get("name", "").lower()
    }
    schedules = awx.all("/schedules/?page_size=200")
    patch_schedules = [row for row in schedules if row.get("unified_job_template") in patch_templates]

    groups: dict[str, list[str]] = {}
    for group in awx.all(f"/inventories/{AWX_INVENTORY_ID}/groups/?page_size=200"):
        if group["name"].startswith("patch_") or group["name"] in {"proxmox", "kubernetes"}:
            members = awx.all(f"/groups/{group['id']}/all_hosts/?page_size=200")
            groups[group["name"]] = sorted(member["name"] for member in members)

    enabled_coverage: dict[str, list[str]] = {name: [] for name in reachable_names}
    schedule_rows: list[dict[str, Any]] = []
    for schedule in patch_schedules:
        template = patch_templates[schedule["unified_job_template"]]
        try:
            template_detail = awx.get(f"/job_templates/{template['id']}/") if template["type"] == "job_template" else template
        except Exception:
            template_detail = template
        extra = parse_vars(template_detail.get("extra_vars"))
        extra.update(parse_vars(schedule.get("extra_data")))
        target = str(extra.get("target_hosts") or template_detail.get("limit") or "")
        covered = set(groups.get(target, [])) if target in groups else ({target} if target in reachable_names else set())
        if schedule.get("enabled"):
            for name in reachable_names & covered:
                enabled_coverage[name].append(schedule["name"])
        schedule_rows.append({
            "name": schedule["name"],
            "enabled": schedule["enabled"],
            "next_run": schedule.get("next_run"),
            "template": template["name"],
            "target": target,
            "reachable_covered": sorted(reachable_names & covered),
        })

    cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=45)
    recent_jobs = awx.all("/unified_jobs/?name__icontains=patch&page_size=200&order_by=-finished", max_pages=5)
    recent_patch_jobs: list[dict[str, Any]] = []
    host_last_awx_patch: dict[str, str] = {}
    for job in recent_jobs:
        finished = job.get("finished")
        if not finished:
            continue
        finished_dt = dt.datetime.fromisoformat(finished.replace("Z", "+00:00"))
        if finished_dt < cutoff:
            continue
        job_row = {
            "id": job["id"], "name": job["name"], "status": job["status"], "finished": finished,
            "host_failures": [],
        }
        recent_patch_jobs.append(job_row)
        if job.get("type") != "job":
            continue
        try:
            summaries = awx.all(f"/jobs/{job['id']}/job_host_summaries/?page_size=200")
        except Exception:
            continue
        job_row["host_failures"] = [
            {
                "host": summary.get("host_name"),
                "dark": summary.get("dark", 0),
                "failures": summary.get("failures", 0),
            }
            for summary in summaries
            if summary.get("dark") or summary.get("failures")
        ]
        for summary in summaries:
            name = summary.get("host_name")
            if name in reachable_names and not summary.get("dark") and not summary.get("failures"):
                if finished > host_last_awx_patch.get(name, ""):
                    host_last_awx_patch[name] = finished

    return {
        "groups": groups,
        "schedules": sorted(schedule_rows, key=lambda row: row["name"]),
        "recent_jobs": recent_patch_jobs,
        "enabled_coverage": enabled_coverage,
        "last_successful_host_run": host_last_awx_patch,
    }


def write_markdown(report: dict[str, Any]) -> None:
    reachable = [host for host in report["hosts"] if host["status"] == "reachable"]
    unexpected = [host for host in report["hosts"] if host["status"] == "unexpected_unreachable"]
    excluded = [host for host in report["hosts"] if host["status"] == "expected_excluded"]
    stale = [host["name"] for host in reachable if host.get("patch_age_days") is None or host["patch_age_days"] > STALE_DAYS]
    uncovered = [name for name, schedules in report["awx_patch"]["enabled_coverage"].items() if not schedules]
    auth = [f"{host['name']}={host['auth_failure_count']}" for host in reachable if host["auth_failure_count"]]
    units = [host["name"] for host in reachable if host["failed_units"]]
    disks = [host["name"] for host in reachable if host["disk_high"]]
    reboots = [host["name"] for host in reachable if host["reboot_required"]]

    lines = [
        "# Daily Reachable-Host Audit",
        "",
        f"- Generated: {report['generated_at']}",
        f"- Reachable reviewed: {len(reachable)}",
        f"- Expected non-SSH/denied excluded: {len(excluded)}",
        f"- Unexpected unreachable: {', '.join(host['name'] for host in unexpected) or 'none'}",
        f"- Patch evidence older than {STALE_DAYS} days or unavailable: {', '.join(stale) or 'none'}",
        f"- No enabled AWX patch schedule coverage: {', '.join(sorted(uncovered)) or 'none'}",
        f"- Reboot required: {', '.join(reboots) or 'none'}",
        f"- Failed systemd units: {', '.join(units) or 'none'}",
        f"- Filesystems at least 90% full: {', '.join(disks) or 'none'}",
        f"- SSH authentication failures in 24h: {', '.join(auth) or 'none'}",
        "",
        "Detailed bounded evidence is stored locally in `host-audit-latest.json`; do not send raw logs externally.",
    ]
    MD_OUTPUT.write_text("\n".join(lines) + "\n")


def main() -> int:
    if not SSH_KEY.exists():
        raise RuntimeError(f"missing SSH identity: {SSH_KEY}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    awx = Awx(load_token())
    hosts = awx.all(f"/inventories/{AWX_INVENTORY_ID}/hosts/?page_size=200&order_by=name")
    with tempfile.NamedTemporaryFile(prefix="hermes-host-audit-known-hosts-") as known_hosts:
        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
            audited = list(pool.map(lambda host: audit_host(host, known_hosts.name), hosts))
    audited.sort(key=lambda row: row["name"].lower())
    reachable_names = {host["name"] for host in audited if host["status"] == "reachable"}
    report = {
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "policy": {
            "log_window_hours": 24,
            "patch_stale_days": STALE_DAYS,
            "expected_denied": sorted(EXPECTED_DENIED),
            "expected_no_ssh": sorted(EXPECTED_NO_SSH),
        },
        "hosts": audited,
        "awx_patch": collect_awx_patch_data(awx, reachable_names),
    }
    JSON_OUTPUT.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    os.chmod(JSON_OUTPUT, 0o600)
    write_markdown(report)
    os.chmod(MD_OUTPUT, 0o600)
    reachable = sum(host["status"] == "reachable" for host in audited)
    expected = sum(host["status"] == "expected_excluded" for host in audited)
    unexpected = sum(host["status"] == "unexpected_unreachable" for host in audited)
    print(f"HOST_AUDIT_REACHABLE={reachable} EXPECTED_EXCLUDED={expected} UNEXPECTED_UNREACHABLE={unexpected}")
    return 1 if unexpected else 0


if __name__ == "__main__":
    raise SystemExit(main())
