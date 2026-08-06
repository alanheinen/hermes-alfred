from __future__ import annotations

import base64
import importlib.util
from pathlib import Path
import tempfile
import unittest


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "host_audit_remote.py"
DAILY_MODULE_PATH = Path(__file__).parents[1] / "scripts" / "daily_host_audit.py"


def load_path(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def load_module():
    if not MODULE_PATH.exists():
        raise AssertionError("scripts/host_audit_remote.py must provide the remote collector")
    return load_path("host_audit_remote", MODULE_PATH)


class FakeRunner:
    def __init__(self, responses):
        self.responses = {tuple(command): value for command, value in responses.items()}
        self.commands = []

    def __call__(self, command, limit=120, timeout=25):
        key = tuple(command)
        self.commands.append(key)
        return self.responses.get(key, {"rc": 0, "lines": []})


class DailyCollectorIntegrationTests(unittest.TestCase):
    def test_daily_collector_payload_is_the_versioned_remote_collector(self):
        daily = load_path("daily_host_audit", DAILY_MODULE_PATH)

        decoded = base64.b64decode(daily.REMOTE_PAYLOAD).decode()

        self.assertEqual(decoded, MODULE_PATH.read_text())

    def test_outer_ssh_timeout_exceeds_bounded_remote_collection(self):
        daily = load_path("daily_host_audit_timeout", DAILY_MODULE_PATH)
        remote = load_module()
        collection_budget = getattr(remote, "MAX_COLLECTION_SECONDS", 0)

        self.assertGreater(collection_budget, 0)
        self.assertGreaterEqual(daily.REMOTE_EXEC_TIMEOUT, collection_budget + 30)

    def test_daily_summary_exposes_opnsense_audit_without_false_systemd_failure(self):
        daily = load_path("daily_host_audit_summary", DAILY_MODULE_PATH)
        evidence = {
            "os": {"id": "freebsd", "pretty": "OPNsense 26.7"},
            "kernel": ["15.1-RELEASE-p1"],
            "boot": [],
            "package_manager": "pkg",
            "last_patch_epoch": 1234.0,
            "pending_updates": 0,
            "pending_sample": [],
            "reboot_required": False,
            "failed_units": {"rc": None, "status": "unavailable", "reason": "systemd is not available on FreeBSD", "lines": []},
            "journal_warnings": {"rc": None, "status": "unavailable", "reason": "journald is not available on FreeBSD", "lines": []},
            "auth_log": {"rc": 0, "lines": []},
            "kernel_warnings": {"rc": 0, "lines": []},
            "disk": {"rc": 0, "lines": []},
            "listeners": {"rc": 0, "lines": []},
            "package_audit": {"rc": 1, "lines": ["3 problem(s) in 2 package(s) found."]},
            "service_inventory": {"rc": 0, "lines": ["/etc/rc.d/sshd"]},
            "apt_history": [],
        }

        summary = daily.summarize_host("opnsense.lan", "172.16.1.1", "22", "root", True, evidence)

        self.assertEqual(summary["failed_units"], [])
        self.assertEqual(summary.get("package_vulnerability_count"), 3)
        self.assertEqual(summary.get("package_vulnerable_package_count"), 2)
        self.assertIn("failed_units", summary.get("unavailable_checks", []))
        self.assertEqual(summary.get("service_inventory_count"), 1)

    def test_daily_summary_does_not_report_redundant_linux_coverage_as_unavailable(self):
        daily = load_path("daily_host_audit_linux_summary", DAILY_MODULE_PATH)
        evidence = {
            "os": {"id": "ubuntu", "pretty": "Ubuntu"},
            "kernel": [],
            "boot": [],
            "package_manager": "apt",
            "last_patch_epoch": 1234.0,
            "pending_updates": 0,
            "pending_sample": [],
            "reboot_required": False,
            "failed_units": {"rc": 0, "lines": []},
            "journal_warnings": {"rc": 0, "lines": []},
            "auth_log": {"rc": 0, "lines": []},
            "kernel_warnings": {"rc": 0, "lines": []},
            "disk": {"rc": 0, "lines": []},
            "listeners": {"rc": 0, "lines": []},
            "package_audit": {"rc": None, "status": "unavailable", "reason": "not configured", "lines": []},
            "service_inventory": {"rc": None, "status": "unavailable", "reason": "represented by failed_units", "lines": []},
            "apt_history": [],
        }

        summary = daily.summarize_host("linux.lan", "192.0.2.1", "22", "root", True, evidence)

        self.assertEqual(summary.get("unavailable_checks"), [])
        self.assertIsNone(summary.get("package_vulnerability_count"))
        self.assertIsNone(summary.get("package_vulnerable_package_count"))

    def test_daily_summary_surfaces_freebsd_collection_errors_without_false_zeroes(self):
        daily = load_path("daily_host_audit_error_summary", DAILY_MODULE_PATH)
        evidence = {
            "os": {"id": "freebsd", "pretty": "FreeBSD (version unavailable)"},
            "kernel": [],
            "boot": [],
            "package_manager": "pkg",
            "last_patch_epoch": None,
            "pending_updates": None,
            "pending_sample": [],
            "reboot_required": None,
            "failed_units": {"rc": None, "status": "unavailable", "lines": []},
            "journal_warnings": {"rc": None, "status": "unavailable", "lines": []},
            "auth_log": {"rc": 0, "lines": []},
            "kernel_warnings": {"rc": None, "status": "unavailable", "lines": []},
            "disk": {"rc": 0, "lines": []},
            "listeners": {"rc": 1, "status": "error", "lines": ["sockstat failed"]},
            "package_audit": {"rc": 2, "status": "error", "lines": ["pkg failed"]},
            "service_inventory": {"rc": 1, "status": "error", "lines": ["service failed"]},
            "platform_versions": {
                "opnsense": {"rc": 127, "status": "error", "lines": ["not found"]},
                "freebsd": {"rc": 1, "status": "error", "lines": ["failed"]},
            },
            "apt_history": [],
        }

        summary = daily.summarize_host("freebsd.lan", "192.0.2.2", "22", "root", True, evidence)

        self.assertIsNone(summary.get("package_vulnerability_count"))
        self.assertIsNone(summary.get("service_inventory_count"))
        self.assertEqual(summary.get("listeners"), [])
        self.assertIsNone(summary.get("reboot_required"))
        self.assertEqual(
            summary.get("collection_errors"),
            [
                "listeners",
                "package_audit",
                "platform_versions.freebsd",
                "platform_versions.opnsense",
                "service_inventory",
            ],
        )

    def test_markdown_reports_package_audit_and_unavailable_coverage(self):
        daily = load_path("daily_host_audit_markdown", DAILY_MODULE_PATH)
        host = {
            "name": "opnsense.lan",
            "status": "reachable",
            "patch_age_days": 0.5,
            "reboot_required": False,
            "failed_units": [],
            "disk_high": [],
            "auth_failure_count": 0,
            "package_vulnerability_count": 3,
            "package_vulnerable_package_count": 2,
            "unavailable_checks": ["failed_units", "journal_warnings"],
            "collection_errors": ["package_audit"],
        }
        report = {
            "generated_at": "2026-08-06T00:00:00+00:00",
            "hosts": [host],
            "awx_patch": {"enabled_coverage": {"opnsense.lan": ["appliance schedule"]}},
        }
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "report.md"
            setattr(daily, "MD_OUTPUT", output)

            daily.write_markdown(report)

            markdown = output.read_text()
        self.assertIn("Package vulnerabilities: opnsense.lan=3 in 2 packages", markdown)
        self.assertIn("Unavailable platform-specific checks: opnsense.lan=failed_units,journal_warnings", markdown)
        self.assertIn("Collection errors: opnsense.lan=package_audit", markdown)
        self.assertIn("Failed systemd units: none", markdown)


class LinuxCollectionTests(unittest.TestCase):
    def test_truenas_does_not_invoke_disabled_package_manager(self):
        module = load_module()
        setattr(module, "read_os_release", lambda: {"ID": "truenas", "PRETTY_NAME": "TrueNAS"})
        runner = FakeRunner({})

        result = module.collect_linux(run_command=runner)

        self.assertIsNone(result["pending_updates"])
        self.assertEqual(result["update_check"]["status"], "unavailable")
        invoked = {command[0] for command in runner.commands}
        self.assertNotIn("apt", invoked)
        self.assertNotIn("dnf", invoked)

    def test_linux_command_failures_are_errors_not_zero_or_valid_evidence(self):
        module = load_module()
        journal_warning_command = (
            "journalctl", "--since", "24 hours ago", "-p", "0..4", "--no-pager",
            "-o", "short-iso", "-n", "160",
        )
        runner = FakeRunner({
            ("apt", "list", "--upgradable"): {"rc": 100, "lines": ["apt failed"]},
            ("systemctl", "--failed", "--no-legend", "--plain"): {"rc": 1, "lines": ["systemctl failed"]},
            journal_warning_command: {"rc": 1, "lines": ["journalctl failed"]},
            ("df", "-P", "-x", "tmpfs", "-x", "devtmpfs"): {"rc": 1, "lines": ["df failed"]},
            ("ss", "-lntupH"): {"rc": 1, "lines": ["ss failed"]},
        })

        result = module.collect_linux(run_command=runner)
        summary = module.summarize_evidence(result)

        self.assertIsNone(result["pending_updates"])
        self.assertEqual(result["update_check"]["status"], "error")
        self.assertEqual(result["failed_units"]["status"], "error")
        self.assertEqual(result["journal_warnings"]["status"], "error")
        self.assertEqual(result["disk"]["status"], "error")
        self.assertEqual(result["listeners"]["status"], "error")
        self.assertEqual(
            summary["collection_errors"],
            ["disk", "failed_units", "journal_warnings", "listeners", "update_check"],
        )


class FreeBsdCollectionTests(unittest.TestCase):
    def test_multiline_platform_output_is_recorded_as_malformed(self):
        module = load_module()
        runner = FakeRunner({
            ("uname", "-s"): {"rc": 0, "lines": ["Linux", "unexpected"]},
        })

        result = module.collect_evidence(run_command=runner)
        summary = module.summarize_evidence(result)

        self.assertEqual(result["os"]["id"], "unknown")
        self.assertIn("platform_detection", summary["collection_errors"])
        invoked = {command[0] for command in runner.commands}
        self.assertNotIn("apt", invoked)
        self.assertNotIn("systemctl", invoked)

    def test_unsupported_platform_is_recorded_without_running_linux_probes(self):
        module = load_module()
        runner = FakeRunner({
            ("uname", "-s"): {"rc": 0, "lines": ["Darwin"]},
        })

        result = module.collect_evidence(run_command=runner)
        summary = module.summarize_evidence(result)

        self.assertEqual(result["os"]["id"], "unknown")
        self.assertIn("platform_detection", summary["collection_errors"])
        invoked = {command[0] for command in runner.commands}
        self.assertNotIn("apt", invoked)
        self.assertNotIn("dnf", invoked)
        self.assertNotIn("systemctl", invoked)

    def test_platform_detection_failure_is_recorded_without_running_linux_probes(self):
        module = load_module()
        runner = FakeRunner({
            ("uname", "-s"): {"rc": 124, "status": "error", "lines": ["timed out"]},
        })

        result = module.collect_evidence(run_command=runner)
        summary = module.summarize_evidence(result)

        self.assertEqual(result["os"]["id"], "unknown")
        self.assertEqual(result["platform_detection"]["status"], "error")
        self.assertIn("platform_detection", summary["collection_errors"])
        invoked = {command[0] for command in runner.commands}
        self.assertNotIn("apt", invoked)
        self.assertNotIn("dnf", invoked)
        self.assertNotIn("systemctl", invoked)

    def test_freebsd_uses_opnsense_native_commands_without_linux_probes(self):
        module = load_module()
        runner = FakeRunner({
            ("uname", "-s"): {"rc": 0, "lines": ["FreeBSD"]},
            ("uname", "-r"): {"rc": 0, "lines": ["15.1-RELEASE-p1"]},
            ("opnsense-version", "-a"): {"rc": 0, "lines": ["26.7"]},
            ("freebsd-version", "-ku"): {"rc": 0, "lines": ["15.1-RELEASE-p1", "15.1-RELEASE-p1"]},
            ("pkg", "audit", "-F"): {"rc": 1, "lines": ["3 problem(s) in 2 installed package(s) found."]},
            ("opnsense-update", "-c"): {"rc": 1, "lines": []},
            ("service", "-e"): {"rc": 0, "lines": ["/etc/rc.d/sshd", "/usr/local/etc/rc.d/unbound"]},
            ("sockstat", "-46l"): {"rc": 0, "lines": ["unbound unbound 1 4 udp4 172.16.1.1:53 *:*"]},
            ("tail", "-n", "180", "/var/log/audit/latest.log"): {"rc": 0, "lines": ["Accepted publickey for root from 172.16.1.186"]},
        })

        result = module.collect_evidence(run_command=runner, file_mtime=lambda _path: 1234.0)

        self.assertEqual(result["os"]["id"], "freebsd")
        self.assertEqual(result["os"]["pretty"], "OPNsense 26.7")
        self.assertEqual(result["package_manager"], "pkg")
        self.assertIsNone(result["pending_updates"])
        self.assertEqual(result["update_check"].get("status"), "unavailable")
        self.assertEqual(result["package_audit"]["rc"], 1)
        self.assertEqual(result["service_inventory"]["lines"], ["/etc/rc.d/sshd", "/usr/local/etc/rc.d/unbound"])
        self.assertEqual(result["listeners"]["lines"], ["unbound unbound 1 4 udp4 172.16.1.1:53 *:*"])
        self.assertEqual(result["auth_log"]["lines"], ["Accepted publickey for root from 172.16.1.186"])
        self.assertEqual(result["failed_units"]["status"], "unavailable")
        self.assertEqual(result["failed_units"]["lines"], [])
        self.assertEqual(result["kernel_warnings"].get("status"), "unavailable")
        invoked = {command[0] for command in runner.commands}
        self.assertFalse({"systemctl", "journalctl", "ss", "dmesg"} & invoked)

    def test_freebsd_command_failures_are_not_reported_as_zero_or_success(self):
        module = load_module()
        runner = FakeRunner({
            ("uname", "-s"): {"rc": 0, "lines": ["FreeBSD"]},
            ("opnsense-version", "-a"): {"rc": 127, "lines": ["opnsense-version: not found"]},
            ("freebsd-version", "-ku"): {"rc": 1, "lines": ["freebsd-version failed"]},
            ("pkg", "audit", "-F"): {
                "rc": 2,
                "lines": ["pkg: repository unavailable", "3 problem(s) in 2 package(s) found."],
            },
            ("service", "-e"): {"rc": 1, "lines": ["service inventory failed"]},
            ("sockstat", "-46l"): {"rc": 1, "lines": ["sockstat failed"]},
            ("hostname", "-f"): {"rc": 1, "lines": ["hostname failed"]},
            ("uname", "-r"): {"rc": 1, "lines": ["kernel failed"]},
            ("sysctl", "-n", "kern.boottime"): {"rc": 1, "lines": ["boot failed"]},
        })

        result = module.collect_evidence(run_command=runner, file_mtime=lambda _path: 1234.0)
        summary = module.summarize_evidence(result)

        self.assertEqual(result["os"]["pretty"], "FreeBSD (version unavailable)")
        self.assertIsNone(result["os"]["version"])
        self.assertEqual(result["package_audit"].get("status"), "error")
        self.assertEqual(result["service_inventory"].get("status"), "error")
        self.assertEqual(result["listeners"].get("status"), "error")
        self.assertIsNone(summary["package_vulnerability_count"])
        self.assertIsNone(summary["service_inventory_count"])
        self.assertEqual(
            summary["collection_errors"],
            [
                "listeners",
                "package_audit",
                "platform_versions.freebsd",
                "platform_versions.opnsense",
                "service_inventory",
                "system_checks.boot",
                "system_checks.hostname",
                "system_checks.kernel",
            ],
        )

    def test_freebsd_package_audit_count_is_reported_without_false_failed_units(self):
        module = load_module()
        evidence = {
            "os": {"id": "freebsd", "pretty": "OPNsense 26.7"},
            "kernel": ["15.1-RELEASE-p1"],
            "boot": [],
            "package_manager": "pkg",
            "last_patch_epoch": 1234.0,
            "pending_updates": 0,
            "pending_sample": [],
            "reboot_required": False,
            "failed_units": {"rc": None, "status": "unavailable", "reason": "systemd is not available on FreeBSD", "lines": []},
            "journal_warnings": {"rc": None, "status": "unavailable", "reason": "journald is not available on FreeBSD", "lines": []},
            "auth_log": {"rc": 0, "lines": []},
            "kernel_warnings": {"rc": 0, "lines": []},
            "disk": {"rc": 0, "lines": []},
            "listeners": {"rc": 0, "lines": []},
            "package_audit": {"rc": 1, "lines": ["3 problem(s) in 2 package(s) found."]},
            "service_inventory": {"rc": 0, "lines": ["/etc/rc.d/sshd"]},
            "apt_history": [],
        }

        summary = module.summarize_evidence(evidence)

        self.assertEqual(summary["package_vulnerability_count"], 3)
        self.assertEqual(summary["package_vulnerable_package_count"], 2)
        self.assertEqual(summary["failed_units"], [])
        self.assertIn("failed_units", summary["unavailable_checks"])
        self.assertEqual(summary["service_inventory_count"], 1)


if __name__ == "__main__":
    unittest.main()
