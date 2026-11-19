#!/usr/bin/env python3
"""Maintain .factory/metrics.json (FACTORY_RULES.md section 4).

Commands:
  append FILE [FILE ...]   append JSON entries (one object per line) from files
  ingest                   read text on stdin, extract hidden
                           `<!-- factory:metric {...} -->` markers, append them
  summarize                recompute the summary only

Entries are de-duplicated by `run_id`, so re-ingesting is safe.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

# FACTORY_METRICS lets workflows run a trusted copy of this script against the checked-out file.
METRICS_PATH = Path(os.environ.get("FACTORY_METRICS") or Path(__file__).resolve().parents[1] / "metrics.json")
MARKER = re.compile(r"<!-- factory:metric (\{.*?\}) -->")


def load() -> dict:
    if METRICS_PATH.exists():
        return json.loads(METRICS_PATH.read_text())
    return {"runs": [], "summary": {}}


def summarize(runs: list[dict]) -> dict:
    by_issue: dict[int, list[dict]] = {}
    for run in runs:
        by_issue.setdefault(run["issue"], []).append(run)

    first_pass = judged = 0
    for entries in by_issue.values():
        qa = sorted((r for r in entries if r["station"] == "qa"), key=lambda r: r["timestamp"])
        if qa:
            judged += 1
            first_pass += qa[0].get("outcome") == "approved"

    total_cost = sum(r.get("cost_usd", 0) for r in runs)
    issues = len(by_issue)
    return {
        "total_issues_processed": issues,
        "first_pass_approval_rate": round(first_pass / judged, 4) if judged else 0,
        "avg_cost_usd": round(total_cost / issues, 6) if issues else 0,
    }


def add(entries: list[dict]) -> int:
    data = load()
    seen = {r["run_id"] for r in data["runs"]}
    added = 0
    for entry in entries:
        if entry["run_id"] not in seen:
            data["runs"].append(entry)
            seen.add(entry["run_id"])
            added += 1
    data["summary"] = summarize(data["runs"])
    METRICS_PATH.write_text(json.dumps(data, indent=2) + "\n")
    return added


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    p_append = sub.add_parser("append")
    p_append.add_argument("files", nargs="+", type=Path)
    sub.add_parser("ingest")
    sub.add_parser("summarize")
    args = parser.parse_args()

    if args.cmd == "append":
        entries = [json.loads(line) for f in args.files if f.exists() for line in f.read_text().splitlines() if line.strip()]
    elif args.cmd == "ingest":
        entries = [json.loads(m) for m in MARKER.findall(sys.stdin.read())]
    else:
        entries = []

    print(f"metrics: {add(entries)} new entries")
    return 0


if __name__ == "__main__":
    sys.exit(main())
