import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
from pathlib import Path


MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "daily_findings_issues.py"


class FakeClient:
    def __init__(self, issues=None):
        self.issues = list(issues or [])
        self.actions = []

    def list_issues(self):
        return list(self.issues)

    def update_issue(self, number, **fields):
        self.actions.append(("update", number, fields))

    def create_issue(self, **fields):
        self.actions.append(("create", fields))
        return {"number": 999, **fields}

    def comment_issue(self, number, body):
        self.actions.append(("comment", number, body))


class FakeResponse:
    def __init__(self, payload):
        self.payload = json.dumps(payload).encode()

    def __enter__(self):
        return self

    def __exit__(self, *_args):
        return False

    def read(self):
        return self.payload


class FakeOpener:
    def __init__(self, pages):
        self.pages = list(pages)
        self.requests = []

    def __call__(self, request, timeout):
        self.requests.append((request, timeout))
        return FakeResponse(self.pages.pop(0))


def sample_finding():
    return {
        "finding_id": "host:frigate.lan:pending-reboot",
        "workflow_label": "needs-remediation",
        "title": "Frigate requires a reboot",
        "what": "frigate.lan is running an older kernel than the installed reboot marker names.",
        "collected_at": "2026-08-07 07:12 CDT",
        "evidence": [
            {
                "command": "ssh frigate.lan 'cat /var/run/reboot-required.pkgs'",
                "output": "linux-image-6.8.0-137-generic",
            }
        ],
        "why_it_matters": "The installed kernel fix is inactive until reboot.",
        "suggested_remediation": "Use the scheduled rolling-maintenance workflow.",
        "blast_radius": "A failed reboot interrupts Frigate recording.",
    }


def load_module():
    spec = importlib.util.spec_from_file_location("daily_findings_issues", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class DailyFindingsIssuesTests(unittest.TestCase):
    def test_rendered_issue_begins_with_stable_finding_marker_and_reproducible_evidence(self):
        module = load_module()
        finding = sample_finding()

        body = module.render_issue_body(finding)

        self.assertTrue(body.startswith("<!-- finding-id: host:frigate.lan:pending-reboot -->\n"))
        self.assertIn("<!-- reporter: hermes-daily-ops -->", body)
        self.assertIn("**Evidence** (collected 2026-08-07 07:12 CDT):", body)
        self.assertIn("$ ssh frigate.lan 'cat /var/run/reboot-required.pkgs'", body)
        self.assertIn("linux-image-6.8.0-137-generic", body)

    def test_validation_rejects_run_specific_ids_and_missing_reproducible_commands(self):
        module = load_module()
        for finding_id in (
            "host:frigate.lan:pending-reboot-2026-08-07",
            "host:frigate.lan:pending-reboot-20260807",
        ):
            bad = {
                "finding_id": finding_id,
                "workflow_label": "needs-remediation",
                "title": "Frigate requires a reboot",
                "what": "Reboot required.",
                "collected_at": "2026-08-07 07:12 CDT",
                "evidence": [{"command": "", "output": "yes"}],
                "why_it_matters": "Kernel fixes are inactive.",
                "suggested_remediation": "Reboot through AWX.",
                "blast_radius": "Recording interruption.",
            }

            with self.subTest(finding_id=finding_id):
                with self.assertRaisesRegex(ValueError, "stable finding_id"):
                    module.validate_finding(bad)

    def test_open_issue_with_same_id_is_updated_in_place_without_commenting_still_present(self):
        module = load_module()
        client = FakeClient(
            [
                {
                    "number": 41,
                    "state": "open",
                    "title": "Old title",
                    "body": "<!-- finding-id: host:frigate.lan:pending-reboot -->\n<!-- reporter: hermes-daily-ops -->\nold",
                    "labels": [{"name": "blocked"}, {"name": "severity:medium"}],
                }
            ]
        )

        result = module.reconcile(client, {"complete": True, "findings": [sample_finding()], "resolutions": []})

        self.assertEqual(result, {"created": 0, "updated": 1, "reopened": 0, "closed": 0})
        self.assertEqual(client.actions[0][0:2], ("update", 41))
        self.assertEqual(client.actions[0][2]["labels"], ["severity:medium", "needs-remediation"])
        self.assertFalse(any(action[0] == "comment" for action in client.actions))

    def test_closed_issue_with_same_id_is_reopened_and_recurrence_is_commented(self):
        module = load_module()
        client = FakeClient(
            [
                {
                    "number": 42,
                    "state": "closed",
                    "title": "Frigate reboot cleared",
                    "body": "<!-- finding-id: host:frigate.lan:pending-reboot -->\n<!-- reporter: hermes-daily-ops -->\nold",
                    "labels": [{"name": "needs-remediation"}],
                }
            ]
        )

        result = module.reconcile(client, {"complete": True, "findings": [sample_finding()], "resolutions": []})

        self.assertEqual(result, {"created": 0, "updated": 0, "reopened": 1, "closed": 0})
        self.assertEqual(client.actions[0][0:2], ("update", 42))
        self.assertEqual(client.actions[0][2]["state"], "open")
        self.assertEqual(client.actions[1][0:2], ("comment", 42))
        self.assertIn("recurred", client.actions[1][2].lower())
        self.assertIn("2026-08-07 07:12 CDT", client.actions[1][2])

    def test_incomplete_collection_only_reconciles_one_blocked_pipeline_issue(self):
        module = load_module()
        failure = sample_finding()
        failure.update(
            {
                "finding_id": "pipeline:hermes-daily-ops:collection-incomplete",
                "workflow_label": "blocked",
                "title": "Daily findings collection incomplete",
                "what": "The daily collector did not complete every required evidence source.",
            }
        )
        client = FakeClient(
            [
                {
                    "number": 41,
                    "state": "open",
                    "body": "<!-- finding-id: host:frigate.lan:pending-reboot -->\n<!-- reporter: hermes-daily-ops -->",
                    "labels": [{"name": "needs-remediation"}],
                }
            ]
        )

        result = module.reconcile(
            client,
            {
                "complete": False,
                "collection_failure": failure,
                "findings": [sample_finding()],
                "resolutions": [],
            },
        )

        self.assertEqual(result, {"created": 1, "updated": 0, "reopened": 0, "closed": 0})
        self.assertEqual([action[0] for action in client.actions], ["create"])
        self.assertIn("pipeline:hermes-daily-ops:collection-incomplete", client.actions[0][1]["body"])

    def test_resolution_closes_only_matching_hermes_issue_with_evidence_comment(self):
        module = load_module()
        client = FakeClient(
            [
                {
                    "number": 43,
                    "state": "open",
                    "body": "<!-- finding-id: host:frigate.lan:pending-reboot -->\n<!-- reporter: hermes-daily-ops -->",
                    "labels": [{"name": "needs-remediation"}],
                },
                {
                    "number": 44,
                    "state": "open",
                    "body": "<!-- finding-id: host:other.lan:pending-reboot -->\n<!-- reporter: another-tool -->",
                    "labels": [{"name": "needs-remediation"}],
                },
            ]
        )
        resolution = {
            "finding_id": "host:frigate.lan:pending-reboot",
            "collected_at": "2026-08-08 07:12 CDT",
            "summary": "The reboot marker is absent after successful rolling maintenance.",
            "evidence": [
                {
                    "command": "ssh frigate.lan 'test ! -e /var/run/reboot-required && echo clear'",
                    "output": "clear",
                }
            ],
        }

        result = module.reconcile(client, {"complete": True, "findings": [], "resolutions": [resolution]})

        self.assertEqual(result, {"created": 0, "updated": 0, "reopened": 0, "closed": 1})
        self.assertEqual(client.actions[0][0:2], ("comment", 43))
        self.assertIn("$ ssh frigate.lan", client.actions[0][2])
        self.assertEqual(client.actions[1], ("update", 43, {"state": "closed"}))
        self.assertFalse(any(action[1] == 44 for action in client.actions))

    def test_validate_only_cli_accepts_complete_payload_without_github_credentials(self):
        payload = {"complete": True, "findings": [sample_finding()], "resolutions": []}
        with tempfile.NamedTemporaryFile("w", suffix=".json") as handle:
            json.dump(payload, handle)
            handle.flush()
            result = subprocess.run(
                [sys.executable, str(MODULE_PATH), "--input", handle.name, "--validate-only"],
                check=False,
                capture_output=True,
                text=True,
            )

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {"validated_findings": 1, "validated_resolutions": 0})

    def test_github_client_reads_open_and_closed_issues_across_pages(self):
        module = load_module()
        first_page = [{"number": number, "body": ""} for number in range(1, 101)]
        second_page = [{"number": 101, "body": "<!-- finding-id: host:x:check -->"}]
        opener = FakeOpener([first_page, second_page])
        client = module.GitHubClient("secret", "owner/repo", opener=opener)

        issues = client.list_issues()

        self.assertEqual(len(issues), 101)
        self.assertEqual(issues[-1]["number"], 101)
        self.assertEqual(len(opener.requests), 2)
        self.assertIn("state=all", opener.requests[0][0].full_url)
        self.assertIn("page=2", opener.requests[1][0].full_url)

    def test_github_mutations_send_json_content_type_and_payload(self):
        module = load_module()
        opener = FakeOpener([{"number": 41}])
        client = module.GitHubClient("secret", "owner/repo", opener=opener)

        client.update_issue(41, state="closed")

        request = opener.requests[0][0]
        self.assertEqual(request.method, "PATCH")
        self.assertEqual(request.get_header("Content-type"), "application/json")
        self.assertEqual(json.loads(request.data), {"state": "closed"})

    def test_token_loader_prefers_environment_without_invoking_kubectl(self):
        module = load_module()
        with mock.patch.dict(os.environ, {"GITHUB_TOKEN": "environment-secret"}, clear=False):
            with mock.patch.object(subprocess, "run") as run:
                token = module.load_token()

        self.assertEqual(token, "environment-secret")
        run.assert_not_called()

    def test_validation_rejects_more_than_one_workflow_label(self):
        module = load_module()
        finding = sample_finding()
        finding["labels"] = ["severity:medium", "blocked"]

        with self.assertRaisesRegex(ValueError, "exactly one workflow"):
            module.validate_finding(finding)

    def test_payload_validation_rejects_duplicate_or_conflicting_ids(self):
        module = load_module()
        finding = sample_finding()
        resolution = {
            "finding_id": finding["finding_id"],
            "collected_at": "2026-08-07 07:12 CDT",
            "summary": "Resolved.",
            "evidence": [{"command": "uname -r", "output": "6.8.0-137-generic"}],
        }

        with self.assertRaisesRegex(ValueError, "duplicate finding_id"):
            module.validate_payload({"complete": True, "findings": [finding, finding], "resolutions": []})
        with self.assertRaisesRegex(ValueError, "active and resolved"):
            module.validate_payload(
                {"complete": True, "findings": [finding], "resolutions": [resolution]}
            )

    def test_validation_rejects_non_boolean_complete_and_non_list_labels(self):
        module = load_module()
        finding = sample_finding()
        finding["labels"] = "severity:medium"

        with self.assertRaisesRegex(ValueError, "complete must be boolean"):
            module.validate_payload({"complete": "false", "collection_failure": finding})
        with self.assertRaisesRegex(ValueError, "labels must be a list"):
            module.validate_finding(finding)

    def test_reconcile_refuses_to_adopt_another_reporters_marker(self):
        module = load_module()
        finding = sample_finding()
        client = FakeClient(
            [
                {
                    "number": 77,
                    "state": "open",
                    "title": "Scanner-owned finding",
                    "body": "<!-- finding-id: host:frigate.lan:pending-reboot -->\n",
                    "labels": [{"name": "tool:nmap"}],
                }
            ]
        )

        with self.assertRaisesRegex(ValueError, "owned by another reporter"):
            module.reconcile(client, {"complete": True, "findings": [finding], "resolutions": []})
        self.assertEqual(client.actions, [])


if __name__ == "__main__":
    unittest.main()
