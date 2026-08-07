#!/usr/bin/env python3
"""Render and reconcile stable daily infrastructure findings as GitHub issues."""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import subprocess
import urllib.parse
import urllib.request
from pathlib import Path


REPORTER_MARKER = "<!-- reporter: hermes-daily-ops -->"
WORKFLOW_LABELS = {"needs-remediation", "awaiting-operator", "blocked"}
FINDING_ID_RE = re.compile(r"^[a-z0-9][a-z0-9.-]*:[a-z0-9][a-z0-9._-]*:[a-z0-9][a-z0-9._-]*$")
RUN_SPECIFIC_RE = re.compile(
    r"(?:^|[-_:])(?:20\d{6}|20\d{2}(?:[-_]\d{1,2})?|run[-_]?\d+)(?:$|[-_:])",
    re.IGNORECASE,
)


class GitHubClient:
    def __init__(self, token: str, repo: str, opener=urllib.request.urlopen):
        self.repo = repo
        self.opener = opener
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
            "User-Agent": "hermes-daily-findings",
            "X-GitHub-Api-Version": "2022-11-28",
        }

    def _request(self, path: str, method: str = "GET", payload: dict | None = None):
        data = None if payload is None else json.dumps(payload).encode()
        request = urllib.request.Request(
            f"https://api.github.com/repos/{self.repo}{path}",
            data=data,
            headers=self.headers,
            method=method,
        )
        with self.opener(request, timeout=60) as response:
            return json.loads(response.read())

    def list_issues(self) -> list[dict]:
        issues = []
        page = 1
        while True:
            query = urllib.parse.urlencode({"state": "all", "per_page": 100, "page": page})
            batch = self._request(f"/issues?{query}")
            issues.extend(issue for issue in batch if "pull_request" not in issue)
            if len(batch) < 100:
                return issues
            page += 1

    def update_issue(self, number: int, **fields):
        return self._request(f"/issues/{number}", method="PATCH", payload=fields)

    def create_issue(self, **fields):
        return self._request("/issues", method="POST", payload=fields)

    def comment_issue(self, number: int, body: str):
        return self._request(f"/issues/{number}/comments", method="POST", payload={"body": body})


def load_token() -> str:
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if token:
        return token
    kubectl = os.environ.get("KUBECTL", "/home/aheinen/.local/bin/kubectl")
    encoded = subprocess.run(
        [
            kubectl,
            "-n",
            "security-scanning",
            "get",
            "secret",
            "security-scan-github-token",
            "-o",
            "jsonpath={.data.GITHUB_TOKEN}",
        ],
        check=True,
        capture_output=True,
        text=True,
        timeout=30,
    ).stdout.strip()
    token = base64.b64decode(encoded).decode().strip()
    if not token:
        raise RuntimeError("GitHub token is empty")
    return token


def validate_finding(finding: dict) -> None:
    if not isinstance(finding, dict):
        raise ValueError("finding items must be objects")
    finding_id = finding.get("finding_id", "")
    if not FINDING_ID_RE.fullmatch(finding_id) or RUN_SPECIFIC_RE.search(finding_id):
        raise ValueError(f"stable finding_id required: {finding_id!r}")
    if finding.get("workflow_label") not in WORKFLOW_LABELS:
        raise ValueError("exactly one valid workflow_label is required")
    labels = finding.get("labels", [])
    if not isinstance(labels, list) or any(
        not isinstance(label, str) or not label.strip() for label in labels
    ):
        raise ValueError("labels must be a list of nonempty strings")
    extra_workflow_labels = WORKFLOW_LABELS.intersection(labels)
    if extra_workflow_labels:
        raise ValueError("exactly one workflow label is allowed")
    for field in (
        "title",
        "what",
        "collected_at",
        "why_it_matters",
        "suggested_remediation",
        "blast_radius",
    ):
        if not str(finding.get(field, "")).strip():
            raise ValueError(f"non-empty {field} is required")
    evidence = finding.get("evidence")
    if not isinstance(evidence, list) or not evidence:
        raise ValueError("reproducible evidence is required")
    for item in evidence:
        if not isinstance(item, dict):
            raise ValueError("evidence items must be objects")
        if not str(item.get("command", "")).strip() or not str(item.get("output", "")).strip():
            raise ValueError("every evidence item requires command and output")


def validate_resolution(resolution: dict) -> None:
    if not isinstance(resolution, dict):
        raise ValueError("resolution items must be objects")
    finding_id = resolution.get("finding_id", "")
    if not FINDING_ID_RE.fullmatch(finding_id) or RUN_SPECIFIC_RE.search(finding_id):
        raise ValueError(f"stable finding_id required: {finding_id!r}")
    if not str(resolution.get("collected_at", "")).strip() or not str(
        resolution.get("summary", "")
    ).strip():
        raise ValueError("resolution collected_at and summary are required")
    evidence = resolution.get("evidence")
    if not isinstance(evidence, list) or not evidence:
        raise ValueError("resolution evidence is required")
    for item in evidence:
        if not isinstance(item, dict):
            raise ValueError("resolution evidence items must be objects")
        if not str(item.get("command", "")).strip() or not str(item.get("output", "")).strip():
            raise ValueError("every resolution evidence item requires command and output")


def issue_marker(finding_id: str) -> str:
    return f"<!-- finding-id: {finding_id} -->"


def reconcile(client, payload: dict) -> dict[str, int]:
    validate_payload(payload)
    if payload.get("complete"):
        findings = payload.get("findings", [])
    else:
        failure = payload.get("collection_failure")
        if not isinstance(failure, dict):
            raise ValueError("incomplete collection requires a collection_failure finding")
        if failure.get("finding_id") != "pipeline:hermes-daily-ops:collection-incomplete":
            raise ValueError("collection_failure must use the stable pipeline finding_id")
        if failure.get("workflow_label") != "blocked":
            raise ValueError("collection_failure must be blocked")
        findings = [failure]

    counts = {"created": 0, "updated": 0, "reopened": 0, "closed": 0}
    issues = client.list_issues()
    for finding in findings:
        validate_finding(finding)
        marker = issue_marker(finding["finding_id"])
        marker_matches = [issue for issue in issues if marker in (issue.get("body") or "")]
        foreign_matches = [
            issue
            for issue in marker_matches
            if REPORTER_MARKER not in (issue.get("body") or "")
        ]
        if foreign_matches:
            raise ValueError(f"finding_id owned by another reporter: {finding['finding_id']}")
        matches = marker_matches
        if len(matches) > 1:
            raise ValueError(f"duplicate issues for {finding['finding_id']}")
        body = render_issue_body(finding)
        requested_labels = list(finding.get("labels", []))
        if matches:
            issue = matches[0]
            existing_labels = [
                label["name"] if isinstance(label, dict) else label for label in issue.get("labels", [])
            ]
            preserved_labels = [label for label in existing_labels if label not in WORKFLOW_LABELS]
            labels = list(
                dict.fromkeys([*preserved_labels, *requested_labels, finding["workflow_label"]])
            )
            fields = {"title": finding["title"], "body": body, "labels": labels}
            if issue.get("state") == "closed":
                client.update_issue(issue["number"], state="open", **fields)
                client.comment_issue(
                    issue["number"],
                    f"This finding recurred. Fresh evidence was collected {finding['collected_at']}; "
                    "the issue body now contains the current commands and output.",
                )
                counts["reopened"] += 1
            else:
                client.update_issue(issue["number"], **fields)
                counts["updated"] += 1
        else:
            labels = list(dict.fromkeys([*requested_labels, finding["workflow_label"]]))
            client.create_issue(title=finding["title"], body=body, labels=labels)
            counts["created"] += 1

    if payload.get("complete"):
        for resolution in payload.get("resolutions", []):
            validate_resolution(resolution)
            finding_id = resolution["finding_id"]
            evidence = resolution["evidence"]
            evidence_blocks = []
            for item in evidence:
                command = str(item.get("command", "")).strip()
                output = str(item.get("output", "")).strip()
                evidence_blocks.append(f"```text\n$ {command}\n{output}\n```")
            marker = issue_marker(finding_id)
            matches = [
                issue
                for issue in issues
                if issue.get("state") == "open"
                and marker in (issue.get("body") or "")
                and REPORTER_MARKER in (issue.get("body") or "")
            ]
            if len(matches) > 1:
                raise ValueError(f"duplicate issues for {finding_id}")
            if matches:
                issue = matches[0]
                comment = (
                    f"Resolved by Hermes from a complete collection at {resolution['collected_at']}.\n\n"
                    f"{resolution['summary']}\n\n" + "\n\n".join(evidence_blocks)
                )
                client.comment_issue(issue["number"], comment)
                client.update_issue(issue["number"], state="closed")
                counts["closed"] += 1
    return counts


def render_issue_body(finding: dict) -> str:
    validate_finding(finding)
    evidence_blocks = []
    for item in finding["evidence"]:
        evidence_blocks.append(f"```text\n$ {item['command']}\n{item['output']}\n```")

    return "\n\n".join(
        [
            f"<!-- finding-id: {finding['finding_id']} -->\n{REPORTER_MARKER}",
            f"**What:** {finding['what']}",
            f"**Evidence** (collected {finding['collected_at']}):\n\n" + "\n\n".join(evidence_blocks),
            f"**Why it matters:** {finding['why_it_matters']}",
            f"**Suggested remediation:** {finding['suggested_remediation']}",
            f"**Blast radius:** {finding['blast_radius']}",
        ]
    ) + "\n"


def validate_payload(payload: dict) -> dict[str, int]:
    if not isinstance(payload, dict):
        raise ValueError("payload must be an object")
    if not isinstance(payload.get("complete"), bool):
        raise ValueError("complete must be boolean")
    if payload.get("complete"):
        findings = payload.get("findings", [])
        resolutions = payload.get("resolutions", [])
        if not isinstance(findings, list):
            raise ValueError("findings must be a list")
        if not isinstance(resolutions, list):
            raise ValueError("resolutions must be a list")
        for finding in findings:
            validate_finding(finding)
        for resolution in resolutions:
            validate_resolution(resolution)
        finding_ids = [finding["finding_id"] for finding in findings]
        resolution_ids = [resolution["finding_id"] for resolution in resolutions]
        if len(finding_ids) != len(set(finding_ids)) or len(resolution_ids) != len(
            set(resolution_ids)
        ):
            raise ValueError("duplicate finding_id in payload")
        overlap = set(finding_ids).intersection(resolution_ids)
        if overlap:
            raise ValueError(f"finding_id cannot be active and resolved: {sorted(overlap)}")
        return {"validated_findings": len(findings), "validated_resolutions": len(resolutions)}

    failure = payload.get("collection_failure")
    if not isinstance(failure, dict):
        raise ValueError("incomplete collection requires a collection_failure finding")
    validate_finding(failure)
    if failure.get("finding_id") != "pipeline:hermes-daily-ops:collection-incomplete":
        raise ValueError("collection_failure must use the stable pipeline finding_id")
    if failure.get("workflow_label") != "blocked":
        raise ValueError("collection_failure must be blocked")
    return {"validated_findings": 1, "validated_resolutions": 0}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--repo", default="alanheinen/k8s-2025-security-findings")
    parser.add_argument("--validate-only", action="store_true")
    args = parser.parse_args()
    payload = json.loads(args.input.read_text(encoding="utf-8"))
    validation = validate_payload(payload)
    if args.validate_only:
        print(json.dumps(validation, sort_keys=True))
        return 0

    client = GitHubClient(load_token(), args.repo)
    result = reconcile(client, payload)
    print(json.dumps(result, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
