#!/usr/bin/env bash
# Runs one agent station and records its cost/token metrics.
#
# Usage: run_agent.sh <station> <prompt_file> <input_file> <output_file> <issue> [pr]
#
# Env:
#   ANTHROPIC_API_KEY     required (Claude Code CLI)
#   AGENT_ALLOWED_TOOLS   tool allowlist (default: read-only)
#   AGENT_MODEL           optional model override
#   AGENT_MAX_TURNS       optional turn cap (default 30)
#   METRIC_OUT            where the metrics entry is written (default $RUNNER_TEMP/metric-<station>.json)
#
# ---------------------------------------------------------------------------
# PLUG-IN POINT: this script is the single place that talks to an AI backend.
# To use another CLI/API (OpenAI Codex CLI, Instinct, a raw API call, ...)
# replace the `claude -p ...` call below. Contract to preserve:
#   1. write the agent's final text answer to <output_file>
#   2. write one JSON metrics line (see FACTORY_RULES.md §4) to $METRIC_OUT
#   3. exit non-zero if the agent run failed
# ---------------------------------------------------------------------------
set -euo pipefail

STATION="${1:?station}"; PROMPT="${2:?prompt file}"; INPUT="${3:?input file}"
OUT="${4:?output file}"; ISSUE="${5:?issue number}"; PR="${6:-}"

ALLOWED="${AGENT_ALLOWED_TOOLS:-Read,Grep,Glob}"
METRIC_OUT="${METRIC_OUT:-${RUNNER_TEMP:-/tmp}/metric-${STATION}.json}"
RAW="$(mktemp)"
MODEL_ARGS=()
[ -n "${AGENT_MODEL:-}" ] && MODEL_ARGS=(--model "$AGENT_MODEL")

START_MS=$(( $(date +%s) * 1000 ))

claude -p "$(cat "$INPUT")" \
  --append-system-prompt "$(cat "$PROMPT")" \
  --output-format json \
  --permission-mode acceptEdits \
  --allowedTools "$ALLOWED" \
  --max-turns "${AGENT_MAX_TURNS:-30}" \
  ${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"} > "$RAW"

END_MS=$(( $(date +%s) * 1000 ))

jq -r '.result // ""' "$RAW" > "$OUT"

jq -c \
  --arg run_id "${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}-${STATION}" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg station "$STATION" \
  --argjson issue "$ISSUE" \
  --arg pr "$PR" \
  --argjson dur "$(( END_MS - START_MS ))" \
  '{
    run_id: $run_id,
    timestamp: $ts,
    station: $station,
    issue: $issue,
    pr: (if $pr == "" then null else ($pr | tonumber) end),
    model: ((.modelUsage // {}) | keys | join(",")),
    input_tokens: (.usage.input_tokens // 0),
    output_tokens: (.usage.output_tokens // 0),
    cost_usd: (.total_cost_usd // 0),
    duration_ms: $dur,
    is_error: (.is_error // false),
    outcome: "completed"
  }' "$RAW" > "$METRIC_OUT"

if [ "$(jq -r '.is_error // false' "$RAW")" = "true" ] || [ ! -s "$OUT" ]; then
  echo "::error::Agent '$STATION' failed or returned no output" >&2
  exit 1
fi
