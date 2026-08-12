"""Per-host AWX patch attribution, including guests patched by delegation."""

import datetime as dt
import importlib.util
import sys
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "daily_host_audit.py"


def load_module():
    spec = importlib.util.spec_from_file_location("daily_host_audit", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


audit = load_module()


def recent(days_ago=3):
    stamp = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=days_ago)
    return stamp.isoformat().replace("+00:00", "Z")


class FakeAwx:
    """Only the endpoints collect_awx_patch_data touches."""

    def __init__(self, jobs, summaries, job_detail=None):
        self.jobs = jobs
        self.summaries = summaries
        self.job_detail = job_detail or {}
        self.detail_calls = []

    def get(self, path):
        if path.startswith("/jobs/"):
            job_id = int(path.split("/")[2])
            self.detail_calls.append(job_id)
            return self.job_detail.get(job_id, {})
        raise AssertionError(f"unexpected get: {path}")

    def all(self, path, max_pages=20):
        if path.startswith("/unified_job_templates/") or path.startswith("/schedules/"):
            return []
        if "/groups/" in path or path.startswith("/inventories/"):
            return []
        if path.startswith("/unified_jobs/"):
            return self.jobs
        if path.startswith("/jobs/") and "job_host_summaries" in path:
            return self.summaries.get(int(path.split("/")[2]), [])
        raise AssertionError(f"unexpected all: {path}")


# The August 9 rolling workflow from finding #831: node A patched every
# hypervisor except four.lan, node B patched four.lan, and each hypervisor's
# play patched its own guests with delegate_to - so AWX recorded summaries for
# the hypervisors only.
AUGUST_9 = recent(3)

HOSTS = [
    {
        "name": "one.lan",
        "variables": {
            "hypervisor_guests": [
                {"hostname": "k8s1.lan", "vmid": 201, "guest_type": "vm", "patch": True},
                {"hostname": "pbs.lan", "vmid": 103, "guest_type": "vm", "patch": True},
            ]
        },
    },
    {
        "name": "vm01.lan",
        "variables": {
            "hypervisor_guests": [
                {"hostname": "k8s6.lan", "vmid": 206, "guest_type": "vm", "patch": True},
                {"hostname": "frigate.lan", "vmid": 105, "guest_type": "vm", "patch": True},
                {"hostname": "haos15.2", "vmid": 107, "guest_type": "vm", "patch": False},
            ]
        },
    },
    {"name": "executor.lan", "variables": {}},
]


class HypervisorGuestMapTests(unittest.TestCase):
    def test_only_patchable_guests_are_mapped(self):
        mapping = audit.hypervisor_guest_map(HOSTS)

        self.assertEqual(["k8s1.lan", "pbs.lan"], mapping["one.lan"])
        self.assertEqual(["frigate.lan", "k8s6.lan"], mapping["vm01.lan"])
        self.assertNotIn("executor.lan", mapping)

    def test_guests_that_only_reboot_are_never_credited(self):
        mapping = audit.hypervisor_guest_map(HOSTS)

        self.assertNotIn("haos15.2", mapping["vm01.lan"])

    def test_malformed_host_variables_are_ignored(self):
        mapping = audit.hypervisor_guest_map([
            {"name": "a.lan", "variables": {"hypervisor_guests": "not-a-list"}},
            {"name": "b.lan", "variables": {"hypervisor_guests": [{"patch": True}]}},
            {"name": "c.lan", "variables": {"hypervisor_guests": [{"hostname": "", "patch": True}]}},
            {"name": "d.lan", "variables": {"hypervisor_guests": [{"hostname": "e.lan", "patch": "true"}]}},
            {"name": "f.lan"},
        ])

        self.assertEqual({}, mapping)

    def test_variables_parse_from_the_string_form_awx_returns(self):
        mapping = audit.hypervisor_guest_map([{
            "name": "one.lan",
            "variables": "hypervisor_guests:\n  - hostname: k8s1.lan\n    patch: true\n",
        }])

        self.assertEqual({"one.lan": ["k8s1.lan"]}, mapping)


class DelegatedGuestAttributionTests(unittest.TestCase):
    def collect(self, jobs, summaries, job_detail=None, reachable=None, hosts=HOSTS):
        awx = FakeAwx(jobs, summaries, job_detail)
        reachable = reachable or {
            "one.lan", "vm01.lan", "k8s1.lan", "k8s6.lan", "pbs.lan", "frigate.lan",
        }
        return awx, audit.collect_awx_patch_data(awx, reachable, hosts)

    def test_august_9_workflow_credits_guests_patched_by_delegation(self):
        jobs = [{
            "id": 2673, "name": "Patch - Rolling Fleet Patch", "type": "job",
            "status": "successful", "finished": AUGUST_9,
            "playbook": "ansible/playbooks/operate/patch-rolling.yml",
        }]
        summaries = {2673: [
            {"host_name": "one.lan", "dark": 0, "failures": 0},
            {"host_name": "vm01.lan", "dark": 0, "failures": 0},
        ]}

        _, data = self.collect(jobs, summaries)
        credited = data["last_successful_host_run"]

        for name in ("one.lan", "vm01.lan", "k8s1.lan", "k8s6.lan", "pbs.lan", "frigate.lan"):
            self.assertEqual(AUGUST_9, credited.get(name), f"{name} was not credited")
        self.assertEqual([], data["guests_without_delegated_evidence"])

    def test_credit_records_the_evidence_it_was_derived_from(self):
        jobs = [{
            "id": 2673, "name": "Patch - Rolling Fleet Patch", "type": "job",
            "status": "successful", "finished": AUGUST_9,
            "playbook": "ansible/playbooks/operate/patch-rolling.yml",
        }]
        summaries = {2673: [{"host_name": "one.lan", "dark": 0, "failures": 0}]}

        _, data = self.collect(jobs, summaries)

        self.assertEqual(
            {
                "finished": AUGUST_9,
                "job": 2673,
                "job_name": "Patch - Rolling Fleet Patch",
                "hypervisor": "one.lan",
                "playbook": "ansible/playbooks/operate/patch-rolling.yml",
            },
            data["delegated_guest_evidence"]["k8s1.lan"],
        )

    def test_failed_hypervisor_run_credits_none_of_its_guests(self):
        jobs = [{
            "id": 2673, "name": "Patch - Rolling Fleet Patch", "type": "job",
            "status": "failed", "finished": AUGUST_9,
            "playbook": "ansible/playbooks/operate/patch-rolling.yml",
        }]
        summaries = {2673: [
            {"host_name": "one.lan", "dark": 0, "failures": 1},
            {"host_name": "vm01.lan", "dark": 0, "failures": 0},
        ]}

        _, data = self.collect(jobs, summaries)
        credited = data["last_successful_host_run"]

        self.assertNotIn("one.lan", credited)
        self.assertNotIn("k8s1.lan", credited)
        self.assertNotIn("pbs.lan", credited)
        self.assertEqual(AUGUST_9, credited["k8s6.lan"])
        self.assertEqual(
            ["k8s1.lan", "pbs.lan"], data["guests_without_delegated_evidence"]
        )

    def test_unreachable_hypervisor_still_credits_nothing_for_its_guests(self):
        jobs = [{
            "id": 2673, "name": "Patch - Rolling Fleet Patch", "type": "job",
            "status": "successful", "finished": AUGUST_9,
            "playbook": "ansible/playbooks/operate/patch-rolling.yml",
        }]
        summaries = {2673: [{"host_name": "one.lan", "dark": 1, "failures": 0}]}

        _, data = self.collect(jobs, summaries)

        self.assertNotIn("k8s1.lan", data["last_successful_host_run"])

    def test_other_patch_playbooks_never_credit_guests(self):
        jobs = [{
            "id": 2800, "name": "Weekly Executor Node Patch", "type": "job",
            "status": "successful", "finished": AUGUST_9,
            "playbook": "ansible/playbooks/operate/patch-hosts.yml",
        }]
        summaries = {2800: [{"host_name": "one.lan", "dark": 0, "failures": 0}]}

        _, data = self.collect(jobs, summaries)
        credited = data["last_successful_host_run"]

        self.assertEqual(AUGUST_9, credited["one.lan"])
        self.assertNotIn("k8s1.lan", credited)
        self.assertNotIn("pbs.lan", credited)

    def test_playbook_is_fetched_from_job_detail_when_the_list_omits_it(self):
        jobs = [{
            "id": 2673, "name": "Patch - Rolling Fleet Patch", "type": "job",
            "status": "successful", "finished": AUGUST_9,
        }]
        summaries = {2673: [{"host_name": "one.lan", "dark": 0, "failures": 0}]}
        detail = {2673: {"playbook": "ansible/playbooks/operate/patch-rolling.yml"}}

        awx, data = self.collect(jobs, summaries, detail)

        self.assertEqual([2673], awx.detail_calls)
        self.assertEqual(AUGUST_9, data["last_successful_host_run"]["k8s1.lan"])

    def test_job_detail_is_not_fetched_when_no_guests_are_involved(self):
        jobs = [{
            "id": 2900, "name": "Patch - something else", "type": "job",
            "status": "successful", "finished": AUGUST_9,
        }]
        summaries = {2900: [{"host_name": "executor.lan", "dark": 0, "failures": 0}]}

        awx, _ = self.collect(jobs, summaries, reachable={"executor.lan"})

        self.assertEqual([], awx.detail_calls)

    def test_zero_change_run_still_counts_as_evidence(self):
        """A run that installs no packages is still proof the host was covered."""
        jobs = [{
            "id": 2673, "name": "Patch - Rolling Fleet Patch", "type": "job",
            "status": "successful", "finished": AUGUST_9,
            "playbook": "ansible/playbooks/operate/patch-rolling.yml",
        }]
        summaries = {2673: [
            {"host_name": "one.lan", "dark": 0, "failures": 0, "changed": 0, "ok": 42},
        ]}

        _, data = self.collect(jobs, summaries)

        self.assertEqual(AUGUST_9, data["last_successful_host_run"]["k8s1.lan"])

    def test_newest_successful_run_wins(self):
        older = recent(10)
        jobs = [
            {
                "id": 2673, "name": "Patch - Rolling Fleet Patch", "type": "job",
                "status": "successful", "finished": AUGUST_9,
                "playbook": "ansible/playbooks/operate/patch-rolling.yml",
            },
            {
                "id": 2406, "name": "Patch - Rolling Fleet Patch", "type": "job",
                "status": "successful", "finished": older,
                "playbook": "ansible/playbooks/operate/patch-rolling.yml",
            },
        ]
        summaries = {
            2673: [{"host_name": "one.lan", "dark": 0, "failures": 0}],
            2406: [{"host_name": "one.lan", "dark": 0, "failures": 0}],
        }

        _, data = self.collect(jobs, summaries)

        self.assertEqual(AUGUST_9, data["last_successful_host_run"]["k8s1.lan"])
        self.assertEqual(2673, data["delegated_guest_evidence"]["k8s1.lan"]["job"])

    def test_workflow_rows_are_still_skipped_for_host_summaries(self):
        jobs = [{
            "id": 2668, "name": "Workflow - Rolling Fleet Patch",
            "type": "workflow_job", "status": "successful", "finished": AUGUST_9,
        }]

        awx, data = self.collect(jobs, {})

        self.assertEqual({}, data["last_successful_host_run"])
        self.assertEqual([], awx.detail_calls)
        self.assertEqual(
            ["frigate.lan", "k8s1.lan", "k8s6.lan", "pbs.lan"],
            data["guests_without_delegated_evidence"],
        )

    def test_absent_host_variables_leave_behaviour_unchanged(self):
        jobs = [{
            "id": 2673, "name": "Patch - Rolling Fleet Patch", "type": "job",
            "status": "successful", "finished": AUGUST_9,
            "playbook": "ansible/playbooks/operate/patch-rolling.yml",
        }]
        summaries = {2673: [{"host_name": "one.lan", "dark": 0, "failures": 0}]}

        _, data = self.collect(jobs, summaries, hosts=[])

        self.assertEqual({"one.lan": AUGUST_9}, data["last_successful_host_run"])
        self.assertEqual({}, data["delegated_guest_evidence"])
        self.assertEqual([], data["guests_without_delegated_evidence"])


class PlaybookMatchingTests(unittest.TestCase):
    def test_full_path_and_basename_both_match(self):
        self.assertTrue(
            audit.patches_delegated_guests("ansible/playbooks/operate/patch-rolling.yml")
        )
        self.assertTrue(audit.patches_delegated_guests("playbooks/operate/patch-rolling.yml"))

    def test_other_values_do_not_match(self):
        for value in (
            "ansible/playbooks/operate/patch-hosts.yml",
            "patch-rolling.yaml",
            "",
            None,
            123,
        ):
            self.assertFalse(audit.patches_delegated_guests(value), value)


if __name__ == "__main__":
    unittest.main()
