import importlib.util
import sys
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).resolve().parents[1] / "scripts" / "local_ai_scout_issues.py"


def load_module():
    spec = importlib.util.spec_from_file_location("local_ai_scout_issues", MODULE_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load {MODULE_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def sample():
    return {
        "title": "Evaluate ExampleModel on GB10",
        "discovered_at": "2026-09-09T12:00:00Z",
        "announcement_date": "2026-09-08",
        "primary_source_url": "https://example.com/release/",
        "validation_urls": ["https://github.com/example/model"],
        "summary": "ExampleModel adds a serving path relevant to local inference.",
        "verified_claims": ["The release includes arm64 artifacts."],
        "novelty_check": "No equivalent model or open issue exists in the current baseline.",
        "spark_fit": "The artifacts target Linux arm64 and fit within 121 GiB.",
        "expected_benefit": "May improve tool-call reliability.",
        "caveats": "No GB10 benchmark has been published.",
        "proposed_experiment": "Serve one pinned build and run the existing BFCL subset.",
        "confidence": "medium",
    }


class FakeClient:
    def __init__(self, issues=None):
        self.issues = issues or []
        self.created = []

    def list_issues(self):
        return self.issues

    def create_issue(self, **fields):
        self.created.append(fields)
        return {"number": 900, "state": "open", **fields}


class Tests(unittest.TestCase):
    def test_validation_requires_independent_source(self):
        m = load_module()
        item = sample()
        item["validation_urls"] = [item["primary_source_url"]]
        with self.assertRaisesRegex(ValueError, "independent"):
            m.validate_candidate(item)

    def test_id_is_stable_across_url_trailing_slash(self):
        m = load_module()
        left = m.validate_candidate(sample())
        right_item = sample()
        right_item["primary_source_url"] = "https://example.com/release"
        right = m.validate_candidate(right_item)
        self.assertEqual(m.candidate_id(left), m.candidate_id(right))

    def test_new_candidate_is_filed_with_research_guardrail(self):
        m = load_module()
        client = FakeClient()
        result = m.reconcile(client, sample())
        self.assertEqual(result["action"], "created")
        self.assertEqual(client.created[0]["labels"], ["enhancement", "needs-remediation", "severity:info", "tool:hermes"])
        self.assertIn("not approval to alter", client.created[0]["body"])
        self.assertIn("<!-- reporter: hermes-local-ai-scout -->", client.created[0]["body"])

    def test_existing_open_or_closed_candidate_is_not_refiled(self):
        m = load_module()
        candidate = m.validate_candidate(sample())
        marker = m.marker_for(m.candidate_id(candidate))
        for state in ("open", "closed"):
            with self.subTest(state=state):
                client = FakeClient([{"number": 42, "state": state, "body": marker}])
                result = m.reconcile(client, candidate)
                self.assertEqual(result["action"], "exists")
                self.assertEqual(client.created, [])


if __name__ == "__main__":
    unittest.main()
