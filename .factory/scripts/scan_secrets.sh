#!/usr/bin/env bash
# Secret-leak tripwire. Fails (exit 1) if any given file contains a known secret
# pattern or the literal value of any SCAN_SECRET_* environment variable.
# Prints only file names, never the matching content.
#
# Usage: SCAN_SECRET_1=... scan_secrets.sh <file> [<file> ...]
set -euo pipefail

PATTERN='sk-ant-[A-Za-z0-9_-]{10,}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{32,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'

LITERALS="$(mktemp)"; trap 'rm -f "$LITERALS"' EXIT
while IFS='=' read -r name value; do
  case "$name" in SCAN_SECRET_*) [ "${#value}" -ge 8 ] && printf '%s\n' "$value" >> "$LITERALS";; esac
done < <(env)

hit=0
for f in "$@"; do
  [ -f "$f" ] || continue
  if grep -IqE "$PATTERN" "$f" || { [ -s "$LITERALS" ] && grep -IqFf "$LITERALS" "$f"; }; then
    echo "Secret-like content in: $f" >&2
    hit=1
  fi
done
exit "$hit"
