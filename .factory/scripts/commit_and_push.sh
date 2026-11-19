#!/usr/bin/env bash
# Commit everything and push to a factory branch. Refuses anything else
# (FACTORY_RULES.md §3: no direct main push, no force push).
#
# Usage: commit_and_push.sh <branch> "<commit message>"
set -euo pipefail

BRANCH="${1:?branch}"; MESSAGE="${2:?message}"

if ! [[ "$BRANCH" =~ ^factory/issue-[0-9]+$ ]]; then
  echo "Refusing to push to '$BRANCH': only factory/issue-<number> is allowed." >&2
  exit 1
fi

git config user.name  "dark-factory[bot]"
git config user.email "dark-factory@users.noreply.github.com"

git add -A
if git diff --cached --quiet; then
  echo "Nothing to commit."
else
  git commit -m "$MESSAGE"
fi
git push origin "HEAD:refs/heads/${BRANCH}"
