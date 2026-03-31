#!/usr/bin/env python3
"""Restore a redacted OpenClaw kit onto a host without reintroducing secrets.

This script copies a redacted OpenClaw config backup and optional cron job export into
place, but refuses to inject secrets. Human operators still need to re-provide tokens
afterward. How modern.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

REQUIRED_SECRET_PATHS = [
    ("channels", "telegram", "botToken"),
    ("gateway", "auth", "token"),
]


def load_json(path: Path):
    with path.open() as fh:
        return json.load(fh)


def get_path(data, path):
    cur = data
    for part in path:
        if not isinstance(cur, dict) or part not in cur:
            return None
        cur = cur[part]
    return cur


def ensure_redacted(config: dict) -> list[str]:
    problems = []
    for path in REQUIRED_SECRET_PATHS:
        value = get_path(config, path)
        if value not in ("REDACTED", None, ""):
            problems.append(".".join(path))
    return problems


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config-src", required=True)
    parser.add_argument("--config-dest", required=True)
    parser.add_argument("--cron-src")
    parser.add_argument("--cron-dest")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()

    config_src = Path(args.config_src).expanduser().resolve()
    config_dest = Path(args.config_dest).expanduser().resolve()
    cron_src = Path(args.cron_src).expanduser().resolve() if args.cron_src else None
    cron_dest = Path(args.cron_dest).expanduser().resolve() if args.cron_dest else None

    if not config_src.exists():
        print(f"Missing config source: {config_src}", file=sys.stderr)
        return 2

    config = load_json(config_src)
    problems = ensure_redacted(config)
    if problems:
        print("Refusing to restore a config that appears to contain live secrets:", file=sys.stderr)
        for problem in problems:
            print(f"- {problem}", file=sys.stderr)
        return 3

    config_dest.parent.mkdir(parents=True, exist_ok=True)
    if config_dest.exists() and not args.force:
        print(f"Refusing to overwrite existing config without --force: {config_dest}", file=sys.stderr)
        return 4
    shutil.copy2(config_src, config_dest)
    print(f"Restored redacted config to {config_dest}")

    if cron_src and cron_dest:
        if not cron_src.exists():
            print(f"Warning: cron source not found, skipping: {cron_src}", file=sys.stderr)
        else:
            cron_dest.parent.mkdir(parents=True, exist_ok=True)
            if cron_dest.exists() and not args.force:
                print(f"Refusing to overwrite existing cron file without --force: {cron_dest}", file=sys.stderr)
                return 5
            shutil.copy2(cron_src, cron_dest)
            print(f"Restored cron export to {cron_dest}")

    print("Next step: re-provide Telegram/gateway secrets before starting services.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
