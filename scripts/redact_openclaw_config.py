#!/usr/bin/env python3
import json
import sys
from pathlib import Path

REDACTED = "REDACTED"

SENSITIVE_KEYS = {
    ("channels", "telegram", "botToken"),
    ("gateway", "auth", "token"),
}


def redact(obj, path=()):
    if isinstance(obj, dict):
        out = {}
        for k, v in obj.items():
            key_path = path + (k,)
            if key_path in SENSITIVE_KEYS:
                out[k] = REDACTED
            else:
                out[k] = redact(v, key_path)
        return out
    if isinstance(obj, list):
        return [redact(v, path) for v in obj]
    return obj


def main():
    if len(sys.argv) != 3:
        print("usage: redact_openclaw_config.py <input-json> <output-json>", file=sys.stderr)
        return 2
    src = Path(sys.argv[1])
    dst = Path(sys.argv[2])
    data = json.loads(src.read_text())
    redacted = redact(data)
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(json.dumps(redacted, indent=2) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
