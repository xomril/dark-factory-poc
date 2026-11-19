#!/usr/bin/env bash
# Human-escalation circuit breaker (FACTORY_RULES.md §2).
# Comments the reason, strips every other shift:* label, applies shift:human-required.
#
# Usage: escalate.sh "<reason>" <issue-or-pr-number> [<number> ...]
# Env:   GH_TOKEN, GH_REPO
set -euo pipefail

REASON="${1:?reason}"; shift
[ "$#" -ge 1 ] || { echo "need at least one issue/PR number" >&2; exit 2; }

for n in "$@"; do
  [ -n "$n" ] || continue
  gh issue comment "$n" --body "🛑 **Factory halted — human required.**

${REASON}

Automation will not touch this again until a human adjusts the labels."
  gh issue edit "$n" \
    --remove-label "shift:queued" \
    --remove-label "shift:in-production" \
    --remove-label "shift:qa-inspection" \
    --remove-label "shift:needs-fix" \
    --remove-label "shift:ready-for-human" \
    --add-label "shift:human-required" || true
done
