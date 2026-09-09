#!/usr/bin/env python3
"""Validate and file deduplicated Spark local-AI research candidates."""

from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit

DEFAULT_REPO = "alanheinen/k8s-2025-security-findings"
REPORTER_MARKER = "<!-- reporter: hermes-local-ai-scout -->"
REQUIRED_TEXT = (
    "title",
    "discovered_at",
    "announcement_date",
    "summary",
    "novelty_check",
    "spark_fit",
    "expected_benefit",
    "caveats",
    "proposed_experiment",
    "confidence",
)


def canonical_url(value: str) -> str:
    parts = urlsplit(value.strip())
    if parts.scheme != "https" or not parts.netloc:
        raise ValueError(f"source URLs must be absolute HTTPS URLs: {value!r}")
    path = parts.path.rstrip("/") or "/"
    return urlunsplit((parts.scheme.lower(), parts.netloc.lower(), path, parts.query, ""))


def validate_candidate(candidate: dict) -> dict:
    if not isinstance(candidate, dict):
        raise ValueError("candidate must be a JSON object")
    for field in REQUIRED_TEXT:
        if not isinstance(candidate.get(field), str) or not candidate[field].strip():
            raise ValueError(f"non-empty {field} is required")
    primary = canonical_url(candidate.get("primary_source_url", ""))
    validation = candidate.get("validation_urls")
    if not isinstance(validation, list) or not validation:
        raise ValueError("at least one independent validation URL is required")
    validation = list(dict.fromkeys(canonical_url(url) for url in validation))
    if primary in validation:
        raise ValueError("validation must be independent of the primary source")
    claims = candidate.get("verified_claims")
    if not isinstance(claims, list) or not claims or any(
        not isinstance(item, str) or not item.strip() for item in claims
    ):
        raise ValueError("verified_claims must contain at least one non-empty claim")
    candidate = dict(candidate)
    candidate["primary_source_url"] = primary
    candidate["validation_urls"] = validation
    candidate["verified_claims"] = [item.strip() for item in claims]
    return candidate


def candidate_id(candidate: dict) -> str:
    identity = candidate.get("event_key") or candidate["primary_source_url"]
    if not isinstance(identity, str) or not identity.strip():
        raise ValueError("event_key must be a non-empty string when supplied")
    digest = hashlib.sha256(identity.strip().lower().encode()).hexdigest()[:20]
    return f"local-ai:spark:{digest}"


def marker_for(cid: str) -> str:
    return f"<!-- finding-id: {cid} -->"


def render_body(candidate: dict, cid: str) -> str:
    sources = [candidate["primary_source_url"], *candidate["validation_urls"]]
    source_lines = "\n".join(f"- {url}" for url in sources)
    claim_lines = "\n".join(f"- {claim}" for claim in candidate["verified_claims"])
    return f"""{marker_for(cid)}
{REPORTER_MARKER}

**What:** {candidate['summary'].strip()}

**Discovered:** {candidate['discovered_at'].strip()}  
**Announcement date:** {candidate['announcement_date'].strip()}  
**Confidence:** {candidate['confidence'].strip()}

**Verified claims:**
{claim_lines}

**Why this is actually new:** {candidate['novelty_check'].strip()}

**Fit for spark.lan:** {candidate['spark_fit'].strip()}

**Expected benefit:** {candidate['expected_benefit'].strip()}

**Caveats / incompatibilities:** {candidate['caveats'].strip()}

**Proposed bounded experiment:** {candidate['proposed_experiment'].strip()}

**Sources:**
{source_lines}

This is a research lead, not approval to alter the production inference stack. Reproduce the claim on the DGX Spark, compare against the current baseline, and record negative results as readily as positive ones.
"""


def load_github_module():
    path = Path(__file__).with_name("daily_findings_issues.py")
    spec = importlib.util.spec_from_file_location("daily_findings_issues", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load GitHub helper: {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def reconcile(client, candidate: dict) -> dict:
    candidate = validate_candidate(candidate)
    cid = candidate_id(candidate)
    marker = marker_for(cid)
    matches = [issue for issue in client.list_issues() if marker in (issue.get("body") or "")]
    if len(matches) > 1:
        raise ValueError(f"duplicate issues already exist for {cid}")
    if matches:
        issue = matches[0]
        return {"action": "exists", "issue": issue["number"], "state": issue["state"], "candidate_id": cid}
    issue = client.create_issue(
        title=f"[Spark research] {candidate['title'].strip()}",
        body=render_body(candidate, cid),
        labels=["enhancement", "needs-remediation", "severity:info", "tool:hermes"],
    )
    return {"action": "created", "issue": issue["number"], "state": issue.get("state", "open"), "candidate_id": cid}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--repo", default=DEFAULT_REPO)
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    candidate = validate_candidate(json.loads(args.input.read_text()))
    cid = candidate_id(candidate)
    if args.validate_only:
        print(json.dumps({"valid": True, "candidate_id": cid}, sort_keys=True))
        return 0
    module = load_github_module()
    client = module.GitHubClient(module.load_token(), args.repo)
    result = reconcile(client, candidate)
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
