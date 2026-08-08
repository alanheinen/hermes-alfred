#!/usr/bin/env python3
"""Bounded remote evidence collector for Linux and OPNsense/FreeBSD hosts.

This file is sent to managed hosts and executed with their Python interpreter.
It therefore uses only the standard library and invokes commands directly,
without relying on the remote account's shell syntax.
"""

from __future__ import annotations

import datetime as dt
import glob
import gzip
import json
import os
import pathlib
import re
import subprocess
from collections.abc import Callable
from typing import Any

CommandResult = dict[str, Any]
CommandRunner = Callable[..., CommandResult]

DEFAULT_COMMAND_TIMEOUT = 25
LONG_COMMAND_TIMEOUT = 90
# FreeBSD worst case: OS detection plus nine native probes at the default
# timeout, and the package-audit/update checks at the long timeout.
MAX_COLLECTION_SECONDS = 10 * DEFAULT_COMMAND_TIMEOUT + 2 * LONG_COMMAND_TIMEOUT


def run(command: list[str], limit: int = 120, timeout: int = DEFAULT_COMMAND_TIMEOUT) -> CommandResult:
    try:
        process = subprocess.run(command, text=True, capture_output=True, timeout=timeout)
        lines = (process.stdout + ("\n" + process.stderr if process.stderr else "")).splitlines()
        return {"rc": process.returncode, "lines": lines[-limit:]}
    except Exception as exc:
        return {"rc": 255, "lines": [f"collector error: {type(exc).__name__}: {exc}"]}


def unavailable(reason: str) -> CommandResult:
    return {"rc": None, "status": "unavailable", "reason": reason, "lines": []}


def command_error(command: str, result: CommandResult) -> CommandResult:
    return {
        "rc": result.get("rc"),
        "status": "error",
        "reason": f"{command} failed",
        "lines": result.get("lines", []),
    }


def require_success(command: str, result: CommandResult) -> CommandResult:
    return result if result.get("rc") == 0 else command_error(command, result)


def first_line(result: CommandResult) -> str | None:
    return next((line.strip() for line in result.get("lines", []) if line.strip()), None)


def parse_json_command(command: str, result: CommandResult, expected_type: type) -> tuple[Any, CommandResult | None]:
    checked = require_success(command, result)
    if checked.get("status") == "error":
        return None, checked
    payload_lines = [line.strip() for line in result.get("lines", []) if line.strip()]
    if len(payload_lines) != 1:
        return None, command_error(command, {"rc": result.get("rc"), "lines": ["expected exactly one JSON value"]})
    try:
        value = json.loads(payload_lines[0])
    except (json.JSONDecodeError, TypeError):
        return None, command_error(command, {"rc": result.get("rc"), "lines": ["invalid JSON response"]})
    if not isinstance(value, expected_type):
        return None, command_error(command, {"rc": result.get("rc"), "lines": [f"expected JSON {expected_type.__name__}"]})
    return value, None


def truenas_update_schema_error(
    system_info: dict[str, Any],
    update_status: dict[str, Any],
    available_versions: list[Any],
) -> str | None:
    if not isinstance(system_info.get("version"), str) or not system_info["version"].strip():
        return "system.info omitted current version"
    if update_status.get("code") != "NORMAL" or update_status.get("error") is not None:
        return "update.status reported an error"
    status = update_status.get("status")
    if not isinstance(status, dict):
        return "update.status omitted status object"
    current = status.get("current_version")
    if not isinstance(current, dict):
        return "update.status omitted current version metadata"
    if not isinstance(current.get("train"), str) or not current["train"].strip():
        return "update.status omitted current train"
    if not isinstance(current.get("profile"), str) or not current["profile"].strip():
        return "update.status omitted current profile"
    if not isinstance(current.get("matches_profile"), bool):
        return "update.status omitted profile-match state"
    new = status.get("new_version")
    if new is not None and (
        not isinstance(new, dict)
        or not isinstance(new.get("version"), str)
        or not new["version"].strip()
    ):
        return "update.status returned malformed new-version metadata"
    for row in available_versions:
        if not isinstance(row, dict) or not isinstance(row.get("train"), str):
            return "update.available_versions returned malformed train metadata"
        version = row.get("version")
        if (
            not isinstance(version, dict)
            or not isinstance(version.get("version"), str)
            or not version["version"].strip()
        ):
            return "update.available_versions returned malformed version metadata"
    return None


def read_apt_history() -> tuple[list[str], float | None]:
    rows: list[str] = []
    mtimes: list[float] = []
    for name in glob.glob("/var/log/apt/history.log*"):
        try:
            mtimes.append(os.path.getmtime(name))
            opener = gzip.open if name.endswith(".gz") else open
            with opener(name, "rt", errors="replace") as handle:
                rows.extend(
                    line.rstrip()
                    for line in handle
                    if line.startswith(("Start-Date:", "End-Date:", "Commandline:", "Upgrade:", "Install:"))
                )
        except OSError:
            pass
    return rows[-100:], max(mtimes, default=None)


def read_os_release() -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        for line in pathlib.Path("/etc/os-release").read_text(errors="replace").splitlines():
            if "=" in line:
                key, value = line.split("=", 1)
                values[key] = value.strip().strip('"')
    except OSError:
        pass
    return values


def collect_linux(run_command: CommandRunner) -> dict[str, Any]:
    os_release = read_os_release()
    package_manager = (
        "truenas"
        if os_release.get("ID", "").lower() == "truenas"
        else "apt"
        if pathlib.Path("/usr/bin/apt").exists()
        else "dnf"
        if pathlib.Path("/usr/bin/dnf").exists()
        else "unknown"
    )
    apt_history, apt_history_mtime = (
        ([], None) if package_manager == "truenas" else read_apt_history()
    )
    appliance_update: dict[str, Any] | None = None
    reboot_required: bool | None = pathlib.Path("/var/run/reboot-required").exists()

    hostname_raw = run_command(["hostname", "-f"], limit=3)
    kernel_raw = run_command(["uname", "-r"], limit=3)
    boot_raw = run_command(["uptime", "-s"], limit=3)

    if package_manager == "apt":
        pending_raw = run_command(["apt", "list", "--upgradable"], limit=220)
        update_check = require_success("apt list --upgradable", pending_raw)
        if update_check.get("status") == "error":
            pending_count: int | None = None
            pending_sample: list[str] = []
        else:
            pending_lines = [
                line
                for line in pending_raw.get("lines", [])
                if "/" in line and not line.startswith("Listing")
            ]
            pending_count = len(pending_lines)
            pending_sample = pending_lines[:20]
    elif package_manager == "dnf":
        pending_raw = run_command(["dnf", "-q", "check-update"], limit=220)
        update_check = (
            pending_raw
            if pending_raw.get("rc") in {0, 100}
            else command_error("dnf -q check-update", pending_raw)
        )
        if update_check.get("status") == "error":
            pending_count = None
            pending_sample = []
        else:
            pending_lines = [
                line
                for line in pending_raw.get("lines", [])
                if line and not line.startswith(("Last metadata", "Obsoleting"))
            ]
            pending_count = len(pending_lines)
            pending_sample = pending_lines[:20]
    elif package_manager == "truenas":
        reboot_required = None
        system_info_raw = run_command(["midclt", "call", "system.info"], limit=20)
        update_status_raw = run_command(["midclt", "call", "update.status"], limit=40)
        available_versions_raw = run_command(
            ["midclt", "call", "update.available_versions"], limit=80
        )
        system_info, system_error = parse_json_command("midclt call system.info", system_info_raw, dict)
        update_status, status_error = parse_json_command("midclt call update.status", update_status_raw, dict)
        available_versions, versions_error = parse_json_command(
            "midclt call update.available_versions", available_versions_raw, list
        )
        update_error = system_error or status_error or versions_error
        if not update_error:
            assert isinstance(system_info, dict)
            assert isinstance(update_status, dict)
            assert isinstance(available_versions, list)
            schema_error = truenas_update_schema_error(system_info, update_status, available_versions)
            if schema_error:
                update_error = command_error(
                    "TrueNAS update evidence validation",
                    {"rc": 0, "lines": [schema_error]},
                )
        if update_error:
            update_check = update_error
            pending_count = None
            pending_sample = []
        else:
            assert isinstance(system_info, dict)
            assert isinstance(update_status, dict)
            assert isinstance(available_versions, list)
            status_value = update_status.get("status")
            status = status_value if isinstance(status_value, dict) else {}
            current_value = status.get("current_version")
            current = current_value if isinstance(current_value, dict) else {}
            new_value = status.get("new_version")
            new = new_value if isinstance(new_value, dict) else {}
            current_version = system_info.get("version")
            new_version = new.get("version")
            normalized_versions = [
                {
                    "train": row.get("train"),
                    "version": (row.get("version") or {}).get("version")
                    if isinstance(row.get("version"), dict)
                    else None,
                }
                for row in available_versions[:20]
                if isinstance(row, dict)
            ]
            appliance_update = {
                "current_version": current_version,
                "current_train": current.get("train"),
                "profile": current.get("profile"),
                "matches_profile": current.get("matches_profile"),
                "code": update_status.get("code"),
                "new_version": new_version,
                "available_versions": normalized_versions,
            }
            pending_count = int(bool(new_version and new_version != current_version))
            pending_sample = (
                [f"{current_version or 'unknown'} -> {new_version} ({current.get('train') or 'unknown train'})"]
                if pending_count
                else []
            )
            update_check = {"rc": 0, "status": "success", "lines": pending_sample}
    else:
        update_check = unavailable("apt and dnf are not available")
        pending_count = None
        pending_sample = []

    failed_units = require_success(
        "systemctl --failed",
        run_command(["systemctl", "--failed", "--no-legend", "--plain"], limit=50),
    )
    journal_warnings = require_success(
        "journalctl warning query",
        run_command(
            [
                "journalctl", "--since", "24 hours ago", "-p", "0..4", "--no-pager",
                "-o", "short-iso", "-n", "160",
            ],
            limit=160,
        ),
    )
    auth_log = require_success(
        "journalctl SSH authentication query",
        run_command(
            [
                "journalctl", "--since", "24 hours ago", "-u", "ssh", "-u", "sshd",
                "--no-pager", "-o", "short-iso", "-n", "180",
            ],
            limit=180,
        ),
    )
    kernel_warnings = require_success(
        "journalctl kernel warning query",
        run_command(
            [
                "journalctl", "-k", "--since", "24 hours ago", "-p", "0..4",
                "--no-pager", "-o", "short-iso", "-n", "100",
            ],
            limit=100,
        ),
    )
    disk = require_success(
        "df filesystem query",
        run_command(["df", "-P", "-x", "tmpfs", "-x", "devtmpfs"], limit=80),
    )
    listeners = require_success(
        "ss listener query", run_command(["ss", "-lntupH"], limit=120)
    )
    system_checks = {
        "hostname": require_success("hostname -f", hostname_raw),
        "kernel": require_success("uname -r", kernel_raw),
        "boot": require_success("uptime -s", boot_raw),
    }

    return {
        "collected_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "hostname": hostname_raw.get("lines", []) if hostname_raw.get("rc") == 0 else [],
        "os": {
            "id": os_release.get("ID"),
            "version": os_release.get("VERSION_ID"),
            "pretty": os_release.get("PRETTY_NAME"),
        },
        "kernel": kernel_raw.get("lines", []) if kernel_raw.get("rc") == 0 else [],
        "boot": boot_raw.get("lines", []) if boot_raw.get("rc") == 0 else [],
        "package_manager": package_manager,
        "apt_history": apt_history,
        "last_patch_epoch": apt_history_mtime,
        "pending_updates": pending_count,
        "pending_sample": pending_sample,
        "reboot_required": reboot_required,
        "failed_units": failed_units,
        "journal_warnings": journal_warnings,
        "auth_log": auth_log,
        "kernel_warnings": kernel_warnings,
        "disk": disk,
        "listeners": listeners,
        "package_audit": unavailable("native package-vulnerability audit is not configured"),
        "service_inventory": unavailable("systemd service inventory is represented by failed_units"),
        "update_check": update_check,
        "appliance_update": appliance_update,
        "system_checks": system_checks,
    }


def collect_freebsd(
    run_command: CommandRunner,
    file_mtime: Callable[[str], float] = os.path.getmtime,
) -> dict[str, Any]:
    opnsense_raw = run_command(["opnsense-version", "-a"], limit=20)
    freebsd_raw = run_command(["freebsd-version", "-ku"], limit=10)
    package_audit_raw = run_command(
        ["pkg", "audit", "-F"], limit=220, timeout=LONG_COMMAND_TIMEOUT
    )
    update_check_raw = run_command(
        ["opnsense-update", "-c"], limit=60, timeout=LONG_COMMAND_TIMEOUT
    )
    services_raw = run_command(["service", "-e"], limit=120)
    listeners_raw = run_command(["sockstat", "-46l"], limit=120)
    auth_log = require_success(
        "tail /var/log/audit/latest.log",
        run_command(["tail", "-n", "180", "/var/log/audit/latest.log"], limit=180),
    )
    disk = require_success("df -P", run_command(["df", "-P"], limit=80))
    try:
        patch_epoch: float | None = file_mtime("/var/db/pkg/local.sqlite")
    except OSError:
        patch_epoch = None

    package_lines = [line for line in package_audit_raw.get("lines", []) if line.strip()]
    package_summary_present = any(
        re.search(r"\d+ problem\(s\) in \d+ (?:installed )?package\(s\) found", line)
        for line in package_lines
    )
    package_audit = (
        package_audit_raw
        if package_audit_raw.get("rc") == 0
        or (package_audit_raw.get("rc") == 1 and package_summary_present)
        else command_error("pkg audit -F", package_audit_raw)
    )
    services = require_success("service -e", services_raw)
    listeners = require_success("sockstat -46l", listeners_raw)

    update_lines = [line for line in update_check_raw.get("lines", []) if line.strip()]
    update_check = (
        update_check_raw
        if update_check_raw.get("rc") == 0
        else {
            "rc": update_check_raw.get("rc"),
            "status": "unavailable" if update_check_raw.get("rc") == 1 else "error",
            "reason": (
                "opnsense-update -c does not distinguish no candidate from an error"
                if update_check_raw.get("rc") == 1
                else "opnsense-update -c failed"
            ),
            "lines": update_check_raw.get("lines", []),
        }
    )
    pending_updates = None

    opnsense_lines = (
        [line for line in opnsense_raw.get("lines", []) if line.strip()]
        if opnsense_raw.get("rc") == 0
        else []
    )
    freebsd_versions = (
        [line for line in freebsd_raw.get("lines", []) if line.strip()]
        if freebsd_raw.get("rc") == 0
        else []
    )
    opnsense_version = opnsense_lines[0] if opnsense_lines else None
    if opnsense_version:
        platform_pretty = (
            opnsense_version
            if opnsense_version.lower().startswith("opnsense")
            else f"OPNsense {opnsense_version}"
        )
    elif freebsd_versions:
        platform_pretty = f"FreeBSD {freebsd_versions[0]}"
    else:
        platform_pretty = "FreeBSD (version unavailable)"

    hostname_raw = run_command(["hostname", "-f"], limit=3)
    kernel_raw = run_command(["uname", "-r"], limit=3)
    boot_raw = run_command(["sysctl", "-n", "kern.boottime"], limit=3)
    system_checks = {
        "hostname": require_success("hostname -f", hostname_raw),
        "kernel": require_success("uname -r", kernel_raw),
        "boot": require_success("sysctl -n kern.boottime", boot_raw),
    }

    return {
        "collected_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "hostname": hostname_raw.get("lines", []) if hostname_raw.get("rc") == 0 else [],
        "os": {
            "id": "freebsd",
            "version": freebsd_versions[0] if freebsd_versions else None,
            "pretty": platform_pretty,
        },
        "kernel": kernel_raw.get("lines", []) if kernel_raw.get("rc") == 0 else [],
        "boot": boot_raw.get("lines", []) if boot_raw.get("rc") == 0 else [],
        "package_manager": "pkg",
        "apt_history": [],
        "last_patch_epoch": patch_epoch,
        "pending_updates": pending_updates,
        "pending_sample": update_lines[:20],
        "reboot_required": None,
        "failed_units": unavailable("systemd is not available on FreeBSD"),
        "journal_warnings": unavailable("journald is not available on FreeBSD"),
        "auth_log": auth_log,
        "kernel_warnings": unavailable(
            "bounded severity-filtered kernel warnings are not implemented on FreeBSD"
        ),
        "disk": disk,
        "listeners": listeners,
        "package_audit": package_audit,
        "service_inventory": services,
        "update_check": update_check,
        "platform_versions": {
            "opnsense": require_success("opnsense-version -a", opnsense_raw),
            "freebsd": require_success("freebsd-version -ku", freebsd_raw),
        },
        "system_checks": system_checks,
    }


def collect_unknown(platform_detection: CommandResult) -> dict[str, Any]:
    coverage_reason = "platform could not be detected safely"
    return {
        "collected_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "hostname": [],
        "os": {"id": "unknown", "version": None, "pretty": "Unknown platform"},
        "kernel": [],
        "boot": [],
        "package_manager": "unknown",
        "apt_history": [],
        "last_patch_epoch": None,
        "pending_updates": None,
        "pending_sample": [],
        "reboot_required": None,
        "failed_units": unavailable(coverage_reason),
        "journal_warnings": unavailable(coverage_reason),
        "auth_log": unavailable(coverage_reason),
        "kernel_warnings": unavailable(coverage_reason),
        "disk": unavailable(coverage_reason),
        "listeners": unavailable(coverage_reason),
        "package_audit": unavailable(coverage_reason),
        "service_inventory": unavailable(coverage_reason),
        "platform_detection": platform_detection,
    }


def collect_evidence(
    run_command: CommandRunner = run,
    file_mtime: Callable[[str], float] = os.path.getmtime,
) -> dict[str, Any]:
    detection = run_command(["uname", "-s"], limit=3)
    platform_lines = [
        line.strip() for line in detection.get("lines", []) if line.strip()
    ]
    if detection.get("rc") != 0 or len(platform_lines) != 1:
        failure = command_error("uname -s", detection)
        if detection.get("rc") == 0:
            failure["reason"] = "uname -s returned malformed platform output"
        return collect_unknown(failure)
    system = platform_lines[0]
    if system.lower() == "freebsd":
        return collect_freebsd(run_command, file_mtime=file_mtime)
    if system.lower() == "linux":
        return collect_linux(run_command)
    failure = command_error("uname -s", detection)
    failure["reason"] = f"unsupported platform reported by uname -s: {system}"
    return collect_unknown(failure)


def summarize_evidence(evidence: dict[str, Any]) -> dict[str, Any]:
    def command_lines(key: str) -> list[str]:
        value = evidence.get(key, {})
        if not isinstance(value, dict) or value.get("status") in {"error", "unavailable"}:
            return []
        return [line for line in value.get("lines", []) if line.strip()]

    package_result = evidence.get("package_audit", {})
    package_unknown = (
        isinstance(package_result, dict)
        and package_result.get("status") in {"error", "unavailable"}
    )
    package_lines = command_lines("package_audit")
    vulnerability_count: int | None = None if package_unknown else 0
    vulnerable_package_count: int | None = None if package_unknown else 0
    for line in package_lines:
        match = re.search(r"(\d+) problem\(s\) in (\d+) (?:installed )?package\(s\) found", line)
        if match:
            vulnerability_count = int(match.group(1))
            vulnerable_package_count = int(match.group(2))

    unavailable_checks = sorted(
        key
        for key, value in evidence.items()
        if isinstance(value, dict) and value.get("status") == "unavailable"
    )
    def error_paths(value: Any, prefix: str = "") -> list[str]:
        if not isinstance(value, dict):
            return []
        if value.get("status") == "error":
            return [prefix]
        paths: list[str] = []
        for key, nested in value.items():
            nested_prefix = f"{prefix}.{key}" if prefix else key
            paths.extend(error_paths(nested, nested_prefix))
        return paths

    collection_errors = sorted(error_paths(evidence))
    service_result = evidence.get("service_inventory", {})
    service_inventory_count = (
        None
        if isinstance(service_result, dict) and service_result.get("status") == "error"
        else len(command_lines("service_inventory"))
    )
    return {
        "failed_units": command_lines("failed_units"),
        "package_audit_sample": package_lines[-40:],
        "package_vulnerability_count": vulnerability_count,
        "package_vulnerable_package_count": vulnerable_package_count,
        "service_inventory_count": service_inventory_count,
        "unavailable_checks": unavailable_checks,
        "collection_errors": collection_errors,
    }


def main() -> int:
    print(json.dumps(collect_evidence()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
