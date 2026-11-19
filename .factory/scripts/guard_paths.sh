#!/usr/bin/env bash
# Circuit breaker: fail if the working tree or branch touches critical paths.
# (FACTORY_RULES.md §2.) `.factory/metrics.json` is the one allowed exception.
#
# Usage: guard_paths.sh <base-branch>      exit 0 = clean, exit 1 = forbidden paths
set -euo pipefail

BASE="${1:?base branch}"

changed="$(
  {
    git diff --name-only "origin/${BASE}...HEAD" 2>/dev/null || true
    git diff --name-only HEAD 2>/dev/null || true
    git ls-files --others --exclude-standard
  } | sort -u
)"

forbidden="$(printf '%s\n' "$changed" | grep -E '^(\.github/|\.factory/)' | grep -vxF '.factory/metrics.json' || true)"

if [ -n "$forbidden" ]; then
  echo "Forbidden paths touched:" >&2
  printf '%s\n' "$forbidden" >&2
  exit 1
fi
